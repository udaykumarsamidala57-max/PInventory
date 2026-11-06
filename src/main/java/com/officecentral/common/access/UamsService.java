package com.officecentral.common.access;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.regex.Pattern;

import com.officecentral.common.db.InventoryDB;

/**
 * Database work for UAMS (Unified Access Management System): users and their roles, roles and their
 * permissions, the project / module / page / action catalogue, the dashboard and the audit trail.
 *
 * UAMS roles are the access_role rows whose key starts with R_. Other rows (old role names) belong to the
 * old rules that School Operations and HR still read until they are updated, so UAMS never edits them.
 * Every change runs in one transaction and is written to an audit table.
 */
public final class UamsService {

    public static final String ROLE_PREFIX = "R_";
    static final Pattern ROLE_NAME = Pattern.compile("[\\p{L}0-9 &()./,'-]{2,100}");
    static final Pattern EMPLOYEE_ID = Pattern.compile("[A-Za-z0-9/_-]{1,30}");
    static final Pattern EMPLOYEE_NAME = Pattern.compile("[\\p{L} .'-]{1,120}");
    static final Pattern PERM_KEY = Pattern.compile("[a-z0-9][a-z0-9._-]{1,79}");
    static final Pattern APP_CODE = Pattern.compile("[A-Z][A-Z0-9_]{1,19}");
    static final Pattern PATH = Pattern.compile("/[A-Za-z0-9_./-]{0,150}");
    /** Addresses that must always open (sign in / out, store choice, UAMS itself), so no page may claim them. */
    static final Set<String> RESERVED_PATHS = Set.of("/", "/login", "/LoginServlet", "/login.jsp", "/Logout.jsp", "/index.jsp",
            "/send-otp", "/SendOTPServlet", "/verify-otp", "/VerifyOtpServlet", "/select-store", "/uams", "/access-control",
            "/school-operations/sso", "/phrms/sso", "/api/mobile");
    private static final DateTimeFormatter IST = DateTimeFormatter.ofPattern("dd-MM-yyyy hh:mm a", Locale.ENGLISH)
            .withZone(ZoneId.of("Asia/Kolkata"));

    private UamsService() { }

    /** A user's change that was refused (shown to the admin as is). */
    public static final class Refused extends RuntimeException {
        private static final long serialVersionUID = 1L;
        public Refused(String message) { super(message); }
    }

    // ================================================================== users

    public static Map<String, Object> users() throws SQLException {
        Map<String, Object> out = new LinkedHashMap<>();
        Map<Integer, Map<String, Object>> users = new LinkedHashMap<>();
        try (Connection c = InventoryDB.getAuthConnection()) {
            try (PreparedStatement ps = c.prepareStatement("SELECT id, username, employee_id, employee_name, role, department, "
                    + "branch FROM users ORDER BY username"); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> u = new LinkedHashMap<>();
                    int id = rs.getInt("id");
                    u.put("id", id);
                    u.put("username", rs.getString("username"));
                    u.put("employeeId", rs.getString("employee_id"));
                    u.put("employeeName", rs.getString("employee_name"));
                    u.put("department", rs.getString("department"));
                    u.put("branch", rs.getString("branch"));
                    u.put("oldRole", rs.getString("role"));
                    u.put("global", isGlobal(rs.getString("role")));
                    u.put("roles", new ArrayList<String>());
                    users.put(id, u);
                }
            }
            try (PreparedStatement ps = c.prepareStatement("SELECT user_id, role_key FROM access_user_role WHERE role_key LIKE 'R\\_%' "
                    + "ORDER BY role_key"); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> u = users.get(rs.getInt(1));
                    if (u != null) roleList(u).add(rs.getString(2));
                }
            }
            out.put("roles", roleRows(c));
        }
        out.put("users", new ArrayList<>(users.values()));
        return out;
    }

    /** Replaces the user's UAMS roles with the given set (each addition and removal is audited). */
    public static int setUserRoles(int userId, Collection<String> wanted, String by) throws SQLException {
        Set<String> desired = new LinkedHashSet<>();
        for (String r : wanted) desired.add(checkRoleKey(r));
        try (Connection c = InventoryDB.getAuthConnection()) {
            return tx(c, () -> {
                String username = lockUser(c, userId);
                Set<String> known = roleKeys(c);
                for (String r : desired) if (!known.contains(r)) throw new Refused("The role " + r + " no longer exists. Reload the page.");
                Set<String> current = new HashSet<>();
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT role_key FROM access_user_role WHERE user_id=? AND role_key LIKE 'R\\_%' FOR UPDATE")) {
                    ps.setInt(1, userId);
                    try (ResultSet rs = ps.executeQuery()) { while (rs.next()) current.add(rs.getString(1)); }
                }
                int n = 0;
                for (String r : desired) if (!current.contains(r)) { assign(c, userId, username, r, by); n++; }
                for (String r : current) if (!desired.contains(r)) { unassign(c, userId, username, r, by); n++; }
                return n;
            });
        }
    }

    /** Adds or removes one role for many users at once. */
    public static int bulkRole(String roleKey, Collection<Integer> userIds, boolean add, String by) throws SQLException {
        String role = checkRoleKey(roleKey);
        if (userIds.isEmpty()) throw new Refused("Select at least one user.");
        if (userIds.size() > 1000) throw new Refused("Too many users were selected.");
        try (Connection c = InventoryDB.getAuthConnection()) {
            return tx(c, () -> {
                if (!roleKeys(c).contains(role)) throw new Refused("That role no longer exists. Reload the page.");
                int n = 0;
                for (int id : new LinkedHashSet<>(userIds)) {
                    String username = lockUser(c, id);
                    boolean has;
                    try (PreparedStatement ps = c.prepareStatement("SELECT 1 FROM access_user_role WHERE user_id=? AND role_key=? FOR UPDATE")) {
                        ps.setInt(1, id); ps.setString(2, role);
                        try (ResultSet rs = ps.executeQuery()) { has = rs.next(); }
                    }
                    if (add && !has) { assign(c, id, username, role, by); n++; }
                    if (!add && has) { unassign(c, id, username, role, by); n++; }
                }
                return n;
            });
        }
    }

    public static void setEmployee(int userId, String employeeId, String employeeName, String by) throws SQLException {
        String eid = blankToNull(employeeId), ename = blankToNull(employeeName);
        if (eid != null && !EMPLOYEE_ID.matcher(eid).matches())
            throw new Refused("Employee ID may use letters, digits, / _ - (up to 30 characters).");
        if (ename != null && !EMPLOYEE_NAME.matcher(ename).matches())
            throw new Refused("Employee name may use letters, spaces and . ' - (up to 120 characters).");
        try (Connection c = InventoryDB.getAuthConnection()) {
            tx(c, () -> {
                String username = lockUser(c, userId);
                if (eid != null) {
                    try (PreparedStatement ps = c.prepareStatement("SELECT username FROM users WHERE employee_id=? AND id<>?")) {
                        ps.setString(1, eid); ps.setInt(2, userId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) throw new Refused("Employee ID " + eid + " is already linked to user " + rs.getString(1) + ".");
                        }
                    }
                }
                try (PreparedStatement ps = c.prepareStatement("UPDATE users SET employee_id=?, employee_name=? WHERE id=?")) {
                    ps.setString(1, eid); ps.setString(2, ename); ps.setInt(3, userId); ps.executeUpdate();
                }
                audit(c, "USER", username, "EMPLOYEE", "Employee ID " + (eid == null ? "-" : eid) + ", name "
                        + (ename == null ? "-" : ename), by);
                return 1;
            });
        }
    }

    // ================================================================== roles

    public static List<Map<String, Object>> roles() throws SQLException {
        try (Connection c = InventoryDB.getAuthConnection()) { return roleRows(c); }
    }

    private static List<Map<String, Object>> roleRows(Connection c) throws SQLException {
        List<Map<String, Object>> out = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement("SELECT r.role_key, r.role_name, r.description, "
                + "(SELECT COUNT(*) FROM access_user_role ur WHERE ur.role_key=r.role_key) AS users, "
                + "(SELECT COUNT(*) FROM access_grant g WHERE g.subject_type='ROLE' AND g.subject=r.role_key AND g.effect='ALLOW') AS perms "
                + "FROM access_role r WHERE r.role_key LIKE 'R\\_%' ORDER BY r.role_name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> r = new LinkedHashMap<>();
                r.put("key", rs.getString(1)); r.put("name", rs.getString(2)); r.put("description", rs.getString(3));
                r.put("users", rs.getInt(4)); r.put("permissions", rs.getInt(5));
                out.add(r);
            }
        }
        return out;
    }

    /** Creates a role (key == null) or renames / re-describes it. Returns the role key. */
    public static String saveRole(String key, String name, String description, String by) throws SQLException {
        String n = name == null ? "" : name.trim().replaceAll("\\s+", " ");
        if (!ROLE_NAME.matcher(n).matches())
            throw new Refused("Role name must be 2 to 100 characters (letters, digits, spaces and & ( ) . / , ' -).");
        String d = blankToNull(description);
        if (d != null && d.length() > 255) throw new Refused("Description can be up to 255 characters.");
        try (Connection c = InventoryDB.getAuthConnection()) {
            return tx(c, () -> {
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT role_key FROM access_role WHERE LOWER(role_name)=LOWER(?) AND role_key LIKE 'R\\_%'")) {
                    ps.setString(1, n);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && !rs.getString(1).equals(key)) throw new Refused("A role named \"" + n + "\" already exists.");
                    }
                }
                if (key == null || key.isEmpty()) {
                    String base = ROLE_PREFIX + AccessControl.normalize(n).replaceAll("_+", "_");
                    if (base.length() > 76) base = base.substring(0, 76);
                    String k = base;
                    Set<String> taken = allRoleKeys(c);
                    for (int i = 2; taken.contains(k); i++) k = base + "_" + i;
                    try (PreparedStatement ps = c.prepareStatement(
                            "INSERT INTO access_role (role_key, role_name, description, created_by) VALUES (?,?,?,?)")) {
                        ps.setString(1, k); ps.setString(2, n); ps.setString(3, d); ps.setString(4, by); ps.executeUpdate();
                    }
                    audit(c, "ROLE", k, "CREATED", n, by);
                    return k;
                }
                String k = checkRoleKey(key);
                String old;
                try (PreparedStatement ps = c.prepareStatement("SELECT role_name FROM access_role WHERE role_key=? FOR UPDATE")) {
                    ps.setString(1, k);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new Refused("That role no longer exists.");
                        old = rs.getString(1);
                    }
                }
                try (PreparedStatement ps = c.prepareStatement("UPDATE access_role SET role_name=?, description=? WHERE role_key=?")) {
                    ps.setString(1, n); ps.setString(2, d); ps.setString(3, k); ps.executeUpdate();
                }
                audit(c, "ROLE", k, "UPDATED", old.equals(n) ? "Description changed" : "Renamed from " + old + " to " + n, by);
                return k;
            });
        }
    }

    /** Deletes a role that no user holds, with its permissions. */
    public static void deleteRole(String key, String by) throws SQLException {
        String k = checkRoleKey(key);
        try (Connection c = InventoryDB.getAuthConnection()) {
            tx(c, () -> {
                String name;
                try (PreparedStatement ps = c.prepareStatement("SELECT role_name FROM access_role WHERE role_key=? FOR UPDATE")) {
                    ps.setString(1, k);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new Refused("That role no longer exists.");
                        name = rs.getString(1);
                    }
                }
                try (PreparedStatement ps = c.prepareStatement("SELECT COUNT(*) FROM access_user_role WHERE role_key=?")) {
                    ps.setString(1, k);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        int n = rs.getInt(1);
                        if (n > 0) throw new Refused(n + " user(s) still hold this role. Remove it from them first.");
                    }
                }
                Set<String> granted = roleGrants(c, k);
                writeRoleGrants(c, k, granted, new HashSet<>(), by);
                try (PreparedStatement ps = c.prepareStatement("DELETE FROM access_role WHERE role_key=?")) {
                    ps.setString(1, k); ps.executeUpdate();
                }
                audit(c, "ROLE", k, "DELETED", name, by);
                return 1;
            });
        }
    }

    /** The catalogue keys this role allows. */
    public static Set<String> rolePermissions(String key) throws SQLException {
        String k = checkRoleKey(key);
        try (Connection c = InventoryDB.getAuthConnection()) { return roleGrants(c, k); }
    }

    /** Replaces the role's permissions with the given keys. */
    public static int setRolePermissions(String key, Collection<String> keys, String by) throws SQLException {
        String k = checkRoleKey(key);
        Set<String> wanted = new LinkedHashSet<>(keys);
        try (Connection c = InventoryDB.getAuthConnection()) {
            return tx(c, () -> {
                try (PreparedStatement ps = c.prepareStatement("SELECT 1 FROM access_role WHERE role_key=? FOR UPDATE")) {
                    ps.setString(1, k);
                    try (ResultSet rs = ps.executeQuery()) { if (!rs.next()) throw new Refused("That role no longer exists."); }
                }
                Set<String> known = new HashSet<>();
                try (PreparedStatement ps = c.prepareStatement("SELECT perm_key FROM access_permission"); ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) known.add(rs.getString(1));
                }
                for (String p : wanted) if (!known.contains(p)) throw new Refused("Unknown catalogue entry: " + p + ". Reload the page.");
                return writeRoleGrants(c, k, roleGrants(c, k), wanted, by);
            });
        }
    }

    /** Writes the difference between two ROLE ALLOW grant sets (used by role edits and the migration). */
    static int writeRoleGrants(Connection c, String role, Set<String> current, Set<String> wanted, String by) throws SQLException {
        int n = 0;
        try (PreparedStatement put = c.prepareStatement("INSERT INTO access_grant (perm_key, subject_type, subject, effect, granted_by) "
                + "VALUES (?, 'ROLE', ?, 'ALLOW', ?) ON DUPLICATE KEY UPDATE effect='ALLOW', granted_by=VALUES(granted_by), granted_at=CURRENT_TIMESTAMP");
             PreparedStatement del = c.prepareStatement("DELETE FROM access_grant WHERE perm_key=? AND subject_type='ROLE' AND subject=?");
             PreparedStatement log = c.prepareStatement("INSERT INTO access_grant_audit (perm_key, subject_type, subject, old_effect, "
                     + "new_effect, changed_by) VALUES (?, 'ROLE', ?, ?, ?, ?)")) {
            for (String p : wanted) {
                if (current.contains(p)) continue;
                put.setString(1, p); put.setString(2, role); put.setString(3, by); put.executeUpdate();
                log.setString(1, p); log.setString(2, role); log.setString(3, null); log.setString(4, "ALLOW"); log.setString(5, by);
                log.executeUpdate();
                n++;
            }
            for (String p : current) {
                if (wanted.contains(p)) continue;
                del.setString(1, p); del.setString(2, role); del.executeUpdate();
                log.setString(1, p); log.setString(2, role); log.setString(3, "ALLOW"); log.setString(4, null); log.setString(5, by);
                log.executeUpdate();
                n++;
            }
        }
        return n;
    }

    static Set<String> roleGrants(Connection c, String role) throws SQLException {
        Set<String> out = new HashSet<>();
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT perm_key FROM access_grant WHERE subject_type='ROLE' AND subject=? AND effect='ALLOW'")) {
            ps.setString(1, role);
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) out.add(rs.getString(1)); }
        }
        return out;
    }

    // ================================================================== catalogue

    /** Projects -> modules -> pages -> actions, in display order. */
    public static List<Map<String, Object>> catalogue() {
        List<AccessControl.Permission> perms = AccessControl.permissions();
        Map<String, Map<String, Object>> nodes = new LinkedHashMap<>();
        List<Map<String, Object>> projects = new ArrayList<>();
        for (AccessControl.Permission p : perms) {
            Map<String, Object> n = new LinkedHashMap<>();
            n.put("key", p.key); n.put("kind", p.kind); n.put("app", p.app); n.put("module", p.module);
            n.put("label", p.label); n.put("description", p.description); n.put("actionCode", p.actionCode);
            n.put("paths", String.join(", ", p.paths)); n.put("sort", p.sortOrder);
            n.put("children", new ArrayList<Map<String, Object>>());
            nodes.put(p.key, n);
        }
        List<Map<String, Object>> orphans = new ArrayList<>();
        for (AccessControl.Permission p : perms) {
            Map<String, Object> n = nodes.get(p.key);
            if (AccessControl.PROJECT.equals(p.kind)) { projects.add(n); continue; }
            String parent = AccessControl.parentOf(p.key);
            Map<String, Object> pn = parent == null ? null : nodes.get(parent);
            if (pn == null) orphans.add(n); else children(pn).add(n);
        }
        if (!orphans.isEmpty()) {
            Map<String, Object> o = new LinkedHashMap<>();
            o.put("key", ""); o.put("kind", "ORPHANS"); o.put("label", "Not linked to a project or module");
            o.put("children", orphans);
            projects.add(o);
        }
        return projects;
    }

    /** Adds a catalogue entry (key == existing key updates label, description, paths, order and action code). */
    public static String saveCatalogue(Map<String, String> f, boolean create, String by) throws SQLException {
        String kind = up(f.get("kind"));
        String label = trim(f.get("label"));
        String description = blankToNull(f.get("description"));
        if (label.length() < 2 || label.length() > 120) throw new Refused("Name must be 2 to 120 characters.");
        if (description != null && description.length() > 255) throw new Refused("Description can be up to 255 characters.");
        int sort;
        try { sort = f.get("sort") == null || f.get("sort").trim().isEmpty() ? 0 : Integer.parseInt(f.get("sort").trim()); }
        catch (NumberFormatException e) { throw new Refused("Display order must be a whole number."); }
        String paths = cleanPaths(f.get("paths"));
        String code = blankToNull(up(f.get("actionCode")));
        if (code != null && !AccessControl.ACTION_CODES.contains(code)) throw new Refused("Choose a valid action.");

        try (Connection c = InventoryDB.getAuthConnection()) {
            return tx(c, () -> {
                if (!create) {
                    String key = trim(f.get("key"));
                    String existingKind;
                    try (PreparedStatement ps = c.prepareStatement("SELECT kind FROM access_permission WHERE perm_key=? FOR UPDATE")) {
                        ps.setString(1, key);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) throw new Refused("That entry no longer exists.");
                            existingKind = rs.getString(1);
                        }
                    }
                    try (PreparedStatement ps = c.prepareStatement("UPDATE access_permission SET label=?, description=?, sort_order=?, "
                            + "paths=IF(kind='PAGE', ?, paths), action_code=IF(kind='ACTION', ?, action_code) WHERE perm_key=?")) {
                        ps.setString(1, label); ps.setString(2, description); ps.setInt(3, sort); ps.setString(4, paths);
                        ps.setString(5, code); ps.setString(6, key); ps.executeUpdate();
                    }
                    if (AccessControl.ACTION.equals(existingKind) && code != null) checkActionCodeFree(c, key, code);
                    audit(c, "CATALOGUE", key, "UPDATED", label, by);
                    return key;
                }
                String key, app, module, parent = null;
                switch (kind) {
                    case AccessControl.PROJECT:
                        app = up(f.get("app"));
                        if (!APP_CODE.matcher(app).matches()) throw new Refused("Project code: 2 to 20 capital letters, digits or _ (e.g. LIBRARY).");
                        key = "proj." + app; module = "";
                        break;
                    case AccessControl.MODULE:
                        app = existingApp(c, f.get("app"));
                        module = label;
                        if (module.length() > 60) throw new Refused("Module name can be up to 60 characters.");
                        key = "mod." + app + "." + module.toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9]+", "_");
                        if (key.length() > 80) key = key.substring(0, 80);
                        parent = "proj." + app;
                        try (PreparedStatement ps = c.prepareStatement("SELECT 1 FROM access_permission WHERE kind='MODULE' AND app=? AND module=?")) {
                            ps.setString(1, app); ps.setString(2, module);
                            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) throw new Refused("This project already has that module."); }
                        }
                        break;
                    case AccessControl.PAGE:
                        String moduleKey = trim(f.get("parent"));
                        String[] am = moduleOf(c, moduleKey);
                        app = am[0]; module = am[1];
                        key = trim(f.get("key")).toLowerCase(Locale.ROOT);
                        if (!PERM_KEY.matcher(key).matches()) throw new Refused("Page code: 2 to 80 small letters, digits, . _ - (e.g. lib.issue-book).");
                        break;
                    case AccessControl.ACTION:
                        parent = trim(f.get("parent"));
                        String[] pa = pageOf(c, parent);
                        app = pa[0]; module = pa[1];
                        if (code == null) {
                            key = trim(f.get("key")).toLowerCase(Locale.ROOT);
                            if (!PERM_KEY.matcher(key).matches()) throw new Refused("Option code: 2 to 80 small letters, digits, . _ -.");
                        } else {
                            key = (parent + "." + code.toLowerCase(Locale.ROOT));
                            if (key.length() > 80) throw new Refused("The page code is too long for an action.");
                        }
                        break;
                    default:
                        throw new Refused("Choose what to add: project, module, page or action.");
                }
                try (PreparedStatement ps = c.prepareStatement("SELECT 1 FROM access_permission WHERE perm_key=?")) {
                    ps.setString(1, key);
                    try (ResultSet rs = ps.executeQuery()) { if (rs.next()) throw new Refused("The code " + key + " is already used."); }
                }
                if (AccessControl.ACTION.equals(kind) && code != null) checkActionCodeFree(c, key, code, parent);
                try (PreparedStatement ps = c.prepareStatement("INSERT INTO access_permission (perm_key, app, module, kind, action_code, "
                        + "parent_key, label, description, paths, sort_order, defaults_applied) VALUES (?,?,?,?,?,?,?,?,?,?,1)")) {
                    ps.setString(1, key); ps.setString(2, app); ps.setString(3, module); ps.setString(4, kind);
                    ps.setString(5, AccessControl.ACTION.equals(kind) ? code : null); ps.setString(6, parent);
                    ps.setString(7, label); ps.setString(8, description);
                    ps.setString(9, AccessControl.PAGE.equals(kind) ? paths : null); ps.setInt(10, sort);
                    ps.executeUpdate();
                }
                audit(c, "CATALOGUE", key, "CREATED", kind + ": " + label, by);
                return key;
            });
        }
    }

    /** Deletes an entry that nothing depends on (no roles allow it, nothing under it). */
    public static void deleteCatalogue(String key, String by) throws SQLException {
        String k = trim(key);
        try (Connection c = InventoryDB.getAuthConnection()) {
            tx(c, () -> {
                String kind, app, module, label;
                try (PreparedStatement ps = c.prepareStatement("SELECT kind, app, module, label FROM access_permission WHERE perm_key=? FOR UPDATE")) {
                    ps.setString(1, k);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new Refused("That entry no longer exists.");
                        kind = rs.getString(1); app = rs.getString(2); module = rs.getString(3); label = rs.getString(4);
                    }
                }
                try (PreparedStatement ps = c.prepareStatement("SELECT COUNT(*) FROM access_grant WHERE perm_key=?")) {
                    ps.setString(1, k);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        if (rs.getInt(1) > 0) throw new Refused("Roles or old rules still use this entry. Remove it from every role first.");
                    }
                }
                String childSql;
                switch (kind) {
                    case AccessControl.PROJECT: childSql = "SELECT COUNT(*) FROM access_permission WHERE app=? AND kind<>'PROJECT' AND ''<>?"; break;
                    case AccessControl.MODULE:  childSql = "SELECT COUNT(*) FROM access_permission WHERE app=? AND module=? AND kind IN ('PAGE','ACTION')"; break;
                    case AccessControl.PAGE:    childSql = "SELECT COUNT(*) FROM access_permission WHERE parent_key=? AND kind='ACTION' AND ''<>?"; break;
                    default:                    childSql = null;
                }
                if (childSql != null) {
                    try (PreparedStatement ps = c.prepareStatement(childSql)) {
                        ps.setString(1, AccessControl.PAGE.equals(kind) ? k : app);
                        ps.setString(2, AccessControl.MODULE.equals(kind) ? module : "x");
                        try (ResultSet rs = ps.executeQuery()) {
                            rs.next();
                            if (rs.getInt(1) > 0) throw new Refused("Remove what is under \"" + label + "\" first.");
                        }
                    }
                }
                try (PreparedStatement ps = c.prepareStatement("DELETE FROM access_permission WHERE perm_key=?")) {
                    ps.setString(1, k); ps.executeUpdate();
                }
                audit(c, "CATALOGUE", k, "DELETED", kind + ": " + label, by);
                return 1;
            });
        }
    }

    /** Creates MODULE rows for pages whose module has none yet (pages added later by access_control.sql). */
    public static int repairHierarchy(String by) throws SQLException {
        try (Connection c = InventoryDB.getAuthConnection()) {
            return tx(c, () -> {
                int n;
                try (PreparedStatement ps = c.prepareStatement("INSERT IGNORE INTO access_permission (perm_key, app, module, kind, "
                        + "parent_key, label, sort_order, defaults_applied) "
                        + "SELECT LEFT(CONCAT('mod.', p.app, '.', REGEXP_REPLACE(UPPER(TRIM(p.module)), '[^A-Z0-9]+', '_')), 80), "
                        + "p.app, p.module, 'MODULE', CONCAT('proj.', p.app), p.module, MIN(p.sort_order), 1 "
                        + "FROM access_permission p WHERE p.kind IN ('PAGE','ACTION') AND TRIM(p.module) <> '' "
                        + "AND NOT EXISTS (SELECT 1 FROM access_permission m WHERE m.kind='MODULE' AND m.app=p.app AND m.module=p.module) "
                        + "GROUP BY p.app, p.module")) {
                    n = ps.executeUpdate();
                }
                if (n > 0) audit(c, "CATALOGUE", "-", "REPAIRED", n + " module(s) added for new pages", by);
                return n;
            });
        }
    }

    private static void checkActionCodeFree(Connection c, String key, String code) throws SQLException {
        String parent;
        try (PreparedStatement ps = c.prepareStatement("SELECT parent_key FROM access_permission WHERE perm_key=?")) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) { rs.next(); parent = rs.getString(1); }
        }
        checkActionCodeFree(c, key, code, parent);
    }

    private static void checkActionCodeFree(Connection c, String key, String code, String parent) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT label FROM access_permission WHERE kind='ACTION' AND parent_key=? AND action_code=? AND perm_key<>?")) {
            ps.setString(1, parent); ps.setString(2, code); ps.setString(3, key);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) throw new Refused("This page already has the " + code + " action (" + rs.getString(1) + ").");
            }
        }
    }

    private static String existingApp(Connection c, String raw) throws SQLException {
        String app = up(raw);
        try (PreparedStatement ps = c.prepareStatement("SELECT 1 FROM access_permission WHERE kind='PROJECT' AND app=?")) {
            ps.setString(1, app);
            try (ResultSet rs = ps.executeQuery()) { if (!rs.next()) throw new Refused("Choose a project."); }
        }
        return app;
    }

    private static String[] moduleOf(Connection c, String key) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT app, module FROM access_permission WHERE perm_key=? AND kind='MODULE'")) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new Refused("Choose the module the page belongs to.");
                return new String[] { rs.getString(1), rs.getString(2) };
            }
        }
    }

    private static String[] pageOf(Connection c, String key) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT app, module FROM access_permission WHERE perm_key=? AND kind='PAGE'")) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new Refused("Choose the page the action belongs to.");
                return new String[] { rs.getString(1), rs.getString(2) };
            }
        }
    }

    private static String cleanPaths(String raw) {
        if (raw == null || raw.trim().isEmpty()) return null;
        List<String> out = new ArrayList<>();
        for (String p : raw.split("[,\\s]+")) {
            if (p.isEmpty()) continue;
            if (!PATH.matcher(p).matches() || p.contains("..")) throw new Refused("Address " + p + " is not valid (it must start with /).");
            if (RESERVED_PATHS.contains(p) || p.startsWith("/uams/") || p.startsWith("/api/mobile/"))
                throw new Refused("Address " + p + " is reserved (sign-in, store choice or UAMS) and cannot belong to a page.");
            if (!out.contains(p)) out.add(p);
        }
        String s = String.join(",", out);
        if (s.length() > 2000) throw new Refused("Too many addresses.");
        return s;
    }

    // ================================================================== dashboard and audit

    public static Map<String, Object> dashboard() throws SQLException {
        Map<String, Object> out = new LinkedHashMap<>();
        try (Connection c = InventoryDB.getAuthConnection()) {
            Map<Integer, Boolean> global = new HashMap<>();
            try (PreparedStatement ps = c.prepareStatement("SELECT id, role FROM users"); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) global.put(rs.getInt(1), isGlobal(rs.getString(2)));
            }
            Map<Integer, Set<String>> rolesOf = new HashMap<>();
            try (PreparedStatement ps = c.prepareStatement("SELECT user_id, role_key FROM access_user_role WHERE role_key LIKE 'R\\_%'");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) rolesOf.computeIfAbsent(rs.getInt(1), x -> new HashSet<>()).add(rs.getString(2));
            }
            List<Map<String, Object>> roles = roleRows(c);
            Map<String, Set<String>> grants = new HashMap<>();
            for (Map<String, Object> r : roles) grants.put((String) r.get("key"), roleGrants(c, (String) r.get("key")));

            long globals = global.values().stream().filter(b -> b).count();
            long without = global.entrySet().stream().filter(e -> !e.getValue() && rolesOf.getOrDefault(e.getKey(), Set.of()).isEmpty()).count();
            out.put("totalUsers", global.size());
            out.put("globalUsers", globals);
            out.put("totalRoles", roles.size());
            out.put("usersWithoutRoles", without);

            List<Map<String, Object>> projects = new ArrayList<>();
            for (AccessControl.Permission p : AccessControl.permissions()) {
                if (!AccessControl.PROJECT.equals(p.kind)) continue;
                long n = 0;
                for (Map.Entry<Integer, Boolean> e : global.entrySet()) {
                    if (e.getValue() || AccessControl.uamsAllowed(rolesOf.getOrDefault(e.getKey(), Set.of()), grants, p.key)) n++;
                }
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("key", p.key); m.put("app", p.app); m.put("name", p.label); m.put("users", n);
                m.put("pages", AccessControl.permissions().stream().filter(x -> AccessControl.PAGE.equals(x.kind) && p.app.equals(x.app)).count());
                m.put("enforcedByUams", "PINVENTORY".equals(p.app) && AccessControl.uamsMode());
                projects.add(m);
            }
            out.put("totalProjects", projects.size());
            out.put("projects", projects);
            out.put("roles", roles);
            out.put("mode", AccessControl.uamsMode() ? AccessControl.MODE_ROLES : AccessControl.MODE_LEGACY);
        }
        return out;
    }

    public static List<Map<String, Object>> audit(int limit) throws SQLException {
        List<Map<String, Object>> out = new ArrayList<>();
        String sql = "SELECT * FROM ("
                + "SELECT changed_at AS at, changed_by AS who, 'USER ROLE' AS what, username AS item, "
                + "CONCAT(IF(change_type='ASSIGNED','Given ','Removed '), COALESCE((SELECT role_name FROM access_role r WHERE r.role_key=a.role_key), a.role_key)) AS detail "
                + "FROM access_user_role_audit a WHERE role_key LIKE 'R\\_%' "
                + "UNION ALL SELECT changed_at, changed_by, 'ROLE PERMISSION', COALESCE((SELECT role_name FROM access_role r WHERE r.role_key=g.subject), g.subject), "
                + "CONCAT(IF(new_effect='ALLOW','Allowed ','Removed '), COALESCE((SELECT label FROM access_permission p WHERE p.perm_key=g.perm_key), g.perm_key)) "
                + "FROM access_grant_audit g WHERE subject_type='ROLE' AND subject LIKE 'R\\_%' "
                + "UNION ALL SELECT changed_at, changed_by, entity, entity_key, CONCAT(change_type, ': ', COALESCE(detail,'')) FROM uams_audit"
                + ") x ORDER BY at DESC LIMIT ?";
        try (Connection c = InventoryDB.getAuthConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, Math.max(1, Math.min(limit, 500)));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    Timestamp t = rs.getTimestamp(1);
                    m.put("at", t == null ? "" : IST.format(t.toInstant()));
                    m.put("by", rs.getString(2)); m.put("what", rs.getString(3)); m.put("item", rs.getString(4)); m.put("detail", rs.getString(5));
                    out.add(m);
                }
            }
        }
        return out;
    }

    // ================================================================== mode

    public static void setMode(String mode, String by) throws SQLException {
        String m = AccessControl.MODE_ROLES.equals(mode) ? AccessControl.MODE_ROLES : AccessControl.MODE_LEGACY;
        try (Connection c = InventoryDB.getAuthConnection()) {
            tx(c, () -> {
                try (PreparedStatement ps = c.prepareStatement("INSERT INTO access_setting (setting_key, setting_value, updated_by) "
                        + "VALUES ('uams.mode', ?, ?) ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value), updated_by=VALUES(updated_by)")) {
                    ps.setString(1, m); ps.setString(2, by); ps.executeUpdate();
                }
                audit(c, "SETTING", "uams.mode", "CHANGED", AccessControl.MODE_ROLES.equals(m)
                        ? "All projects now use UAMS roles only" : "All projects back on the old rules", by);
                return 1;
            });
        }
    }

    // ================================================================== helpers

    interface Work<T> { T run() throws SQLException; }

    static <T> T tx(Connection c, Work<T> w) throws SQLException {
        boolean auto = c.getAutoCommit();
        c.setAutoCommit(false);
        try {
            T r = w.run();
            c.commit();
            return r;
        } catch (SQLException | RuntimeException e) {
            c.rollback();
            throw e;
        } finally {
            c.setAutoCommit(auto);
        }
    }

    static String lockUser(Connection c, int userId) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT username FROM users WHERE id=? FOR UPDATE")) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new Refused("That user no longer exists. Reload the page.");
                return rs.getString(1);
            }
        }
    }

    static void assign(Connection c, int userId, String username, String role, String by) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT IGNORE INTO access_user_role (user_id, role_key, is_primary, assigned_by) VALUES (?,?,0,?)")) {
            ps.setInt(1, userId); ps.setString(2, role); ps.setString(3, by);
            if (ps.executeUpdate() > 0) userRoleAudit(c, userId, username, role, "ASSIGNED", by);
        }
    }

    static void unassign(Connection c, int userId, String username, String role, String by) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("DELETE FROM access_user_role WHERE user_id=? AND role_key=?")) {
            ps.setInt(1, userId); ps.setString(2, role);
            if (ps.executeUpdate() > 0) userRoleAudit(c, userId, username, role, "REMOVED", by);
        }
    }

    private static void userRoleAudit(Connection c, int userId, String username, String role, String type, String by) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("INSERT INTO access_user_role_audit (user_id, username, role_key, change_type, "
                + "changed_by) VALUES (?,?,?,?,?)")) {
            ps.setInt(1, userId); ps.setString(2, username); ps.setString(3, role); ps.setString(4, type); ps.setString(5, by);
            ps.executeUpdate();
        }
    }

    static void audit(Connection c, String entity, String key, String type, String detail, String by) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("INSERT INTO uams_audit (entity, entity_key, change_type, detail, changed_by) "
                + "VALUES (?,?,?,?,?)")) {
            ps.setString(1, entity); ps.setString(2, key.length() > 80 ? key.substring(0, 80) : key); ps.setString(3, type);
            ps.setString(4, detail == null ? null : (detail.length() > 500 ? detail.substring(0, 500) : detail)); ps.setString(5, by);
            ps.executeUpdate();
        }
    }

    static Set<String> roleKeys(Connection c) throws SQLException {
        Set<String> out = new HashSet<>();
        try (PreparedStatement ps = c.prepareStatement("SELECT role_key FROM access_role WHERE role_key LIKE 'R\\_%'");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) out.add(rs.getString(1));
        }
        return out;
    }

    private static Set<String> allRoleKeys(Connection c) throws SQLException {
        Set<String> out = new HashSet<>();
        try (PreparedStatement ps = c.prepareStatement("SELECT role_key FROM access_role"); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) out.add(rs.getString(1));
        }
        return out;
    }

    static String checkRoleKey(String key) {
        String k = key == null ? "" : key.trim();
        if (!k.startsWith(ROLE_PREFIX) || !k.matches("[A-Z0-9_]{3,80}")) throw new Refused("Choose a valid role.");
        return k;
    }

    static boolean isGlobal(String role) { return "GLOBAL".equals(AccessControl.normalize(role)); }

    @SuppressWarnings("unchecked")
    private static List<String> roleList(Map<String, Object> u) { return (List<String>) u.get("roles"); }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> children(Map<String, Object> n) { return (List<Map<String, Object>>) n.get("children"); }

    static String blankToNull(String s) { return s == null || s.trim().isEmpty() ? null : s.trim(); }
    private static String trim(String s) { return s == null ? "" : s.trim(); }
    private static String up(String s) { return s == null ? "" : s.trim().toUpperCase(Locale.ROOT); }

    /** Counts per value, sorted by name (for small summaries). */
    static Map<String, Integer> countBy(Collection<String> values) {
        Map<String, Integer> m = new TreeMap<>();
        for (String v : values) m.merge(v, 1, Integer::sum);
        return m;
    }
}
