package com.officecentral.common.access;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.HashSet;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Logger;

import javax.servlet.http.HttpSession;

import com.officecentral.common.db.InventoryDB;

/**
 * Project, module, page and action access for PInventory, set by Global users in UAMS
 * (tables access_permission, access_grant, access_role and access_user_role in the inventory database).
 *
 * Two modes, chosen by the setting uams.mode (UAMS > Migration):
 *
 *  LEGACY (until the switch) - the old rules: the Global role may do everything; a grant for the user by name
 *    decides; otherwise a DENY for their role or department wins over an ALLOW for their role, department or
 *    "all users"; nothing matching = no access.
 *
 *  ROLES (UAMS) - only the UAMS roles assigned to the user count, and their permissions are combined (any
 *    role that allows it is enough). Something is allowed only when it AND every level above it is allowed:
 *    action -> its page -> its module -> its project. Links to another project (School Operations, HR) also
 *    need that project. The Global role still may do everything (it cannot be locked out).
 *
 * Addresses that are not in the catalogue are not checked here. When the tables do not exist yet (SQL not
 * run) access control is inactive and the old fixed rules apply.
 */
public final class AccessControl {

    private static final Logger LOG = Logger.getLogger(AccessControl.class.getName());
    static final long CACHE_MILLIS = 30_000;
    private static final Map<String, RoleCache> USER_ROLES = new ConcurrentHashMap<>();
    private static final Map<String, RoleCache> UAMS_ROLES = new ConcurrentHashMap<>();

    public static final String MODE_LEGACY = "LEGACY";
    public static final String MODE_ROLES = "ROLES";

    /** Catalogue levels. */
    public static final String PROJECT = "PROJECT", MODULE = "MODULE", PAGE = "PAGE", ACTION = "ACTION";

    /** The eight standard actions, in display order. */
    public static final List<String> ACTION_CODES = Collections.unmodifiableList(java.util.Arrays.asList(
            "VIEW", "ADD", "EDIT", "DELETE", "APPROVE", "REJECT", "PRINT", "EXPORT"));

    /** PInventory pages that open another project: in UAMS mode they also need that project. */
    private static final Map<String, String> LINK_PROJECT = Map.of(
            "so.link", "proj.SCHOOLOPS",
            "phrms.link", "proj.PHRMS",
            "dir.link", "proj.DIRECTOR");

    private static final class RoleCache {
        final Set<String> roles;
        final long loadedAt;
        RoleCache(Set<String> roles, long loadedAt) { this.roles = roles; this.loadedAt = loadedAt; }
    }

    /** One project, module, page or action from the catalogue. */
    public static final class Permission {
        public final String key, app, module, kind, actionCode, parentKey, label, description;
        public final List<String> paths;
        public final int sortOrder;

        Permission(String key, String app, String module, String kind, String parentKey, String label,
                   String description, List<String> paths, int sortOrder) {
            this(key, app, module, kind, null, parentKey, label, description, paths, sortOrder);
        }

        Permission(String key, String app, String module, String kind, String actionCode, String parentKey, String label,
                   String description, List<String> paths, int sortOrder) {
            this.key = key; this.app = app; this.module = module == null ? "" : module; this.kind = kind;
            this.actionCode = actionCode; this.parentKey = parentKey;
            this.label = label; this.description = description; this.paths = paths; this.sortOrder = sortOrder;
        }
    }

    /** One grant: subject type ALL / ROLE / DEPT / USER, subject (normalised) and ALLOW or DENY. */
    public static final class Grant {
        public final String key, type, subject;
        public final boolean allow;
        Grant(String key, String type, String subject, boolean allow) {
            this.key = key; this.type = type; this.subject = subject; this.allow = allow;
        }
    }

    static final class Snapshot {
        final boolean active;
        final String mode;                                  // LEGACY or ROLES
        final List<Permission> permissions;                 // sort order
        final Map<String, Permission> byKey;
        final Map<String, List<String>> keysByPath;         // address -> page keys (any of them allows it)
        final Map<String, List<Grant>> grants;
        final Map<String, Set<String>> roleGrants;          // role key -> keys it ALLOWs (UAMS mode)
        final Map<String, String> moduleKey;                // app + NUL + module text -> MODULE key
        final Map<String, String> projectKey;               // app -> PROJECT key
        final long loadedAt;

        Snapshot(boolean active, List<Permission> permissions, List<Grant> grantList, long loadedAt) {
            this(active, MODE_LEGACY, permissions, grantList, loadedAt);
        }

        Snapshot(boolean active, String mode, List<Permission> permissions, List<Grant> grantList, long loadedAt) {
            this.active = active;
            this.mode = MODE_ROLES.equals(mode) ? MODE_ROLES : MODE_LEGACY;
            this.permissions = Collections.unmodifiableList(permissions);
            this.loadedAt = loadedAt;
            Map<String, Permission> k = new HashMap<>();
            Map<String, List<String>> p = new HashMap<>();
            Map<String, String> mod = new HashMap<>(), proj = new HashMap<>();
            for (Permission perm : permissions) {
                k.put(perm.key, perm);
                if (("PINVENTORY".equals(perm.app) || "phrms.link".equals(perm.key)) && PAGE.equals(perm.kind)) {
                    for (String path : perm.paths) p.computeIfAbsent(path, x -> new ArrayList<>()).add(perm.key);
                }
                if (MODULE.equals(perm.kind)) mod.putIfAbsent(perm.app + '\u0000' + perm.module, perm.key);
                if (PROJECT.equals(perm.kind)) proj.putIfAbsent(perm.app, perm.key);
            }
            Map<String, List<Grant>> g = new HashMap<>();
            Map<String, Set<String>> rg = new HashMap<>();
            for (Grant gr : grantList) {
                g.computeIfAbsent(gr.key, x -> new ArrayList<>()).add(gr);
                if ("ROLE".equals(gr.type) && gr.allow) rg.computeIfAbsent(gr.subject, x -> new HashSet<>()).add(gr.key);
            }
            this.byKey = k;
            this.keysByPath = p;
            this.grants = g;
            this.roleGrants = rg;
            this.moduleKey = mod;
            this.projectKey = proj;
        }

        /** The level directly above (action -> page -> module -> project), or null at the top / when missing. */
        String parentOf(Permission perm) {
            switch (perm.kind) {
                case ACTION: return perm.parentKey;
                case PAGE:   return moduleKey.get(perm.app + '\u0000' + perm.module);
                case MODULE: return projectKey.get(perm.app);
                default:     return null;
            }
        }
    }

    private static volatile Snapshot snapshot;

    private AccessControl() { }

    // ------------------------------------------------------------------ checks

    /** True once the access tables exist; until then the old fixed rules apply everywhere. */
    public static boolean isActive() { return current().active; }

    /** True when PInventory uses UAMS roles only (after the switch on UAMS > Migration). */
    public static boolean uamsMode() { Snapshot s = current(); return s.active && MODE_ROLES.equals(s.mode); }

    /** May this signed-in user use the page or button? */
    public static boolean can(HttpSession s, String key) {
        if (s == null || s.getAttribute("username") == null) return false;
        return canUser(str(s, "username"), str(s, "role"), str(s, "department"), key);
    }

    /**
     * Same rule as can(session, key) for a user who is not signed in here (server-to-server calls, e.g. the
     * Director Portal): username, role and department as stored in the users table.
     */
    public static boolean canUser(String username, String role, String department, String key) {
        if (username == null) return false;
        Snapshot snap = current();
        if (snap.active && MODE_ROLES.equals(snap.mode)) {
            if ("GLOBAL".equals(normalize(role))) return true;
            return uamsAllowed(snap, uamsRolesFor(username), snap.roleGrants, key);
        }
        Permission permission = snap.byKey.get(key);
        if (isRoleOnly(permission)) {
            return evaluateRoles(role, rolesForUser(username, role), snap.grants.get(key));
        }
        return evaluate(role, department, username, snap.grants.get(key));
    }

    /** show(session, key, oldRule) for a user who is not signed in here. */
    public static boolean showUser(String username, String role, String department, String key, boolean oldRule) {
        Snapshot snap = current();
        if (!snap.active || !snap.byKey.containsKey(key)) return oldRule;
        return canUser(username, role, department, key);
    }

    /**
     * May this signed-in user open the address? Addresses not in the catalogue (and everything while the
     * tables are missing) return true, so the page's own checks decide as before.
     */
    public static boolean canPath(HttpSession s, String path) {
        Snapshot snap = current();
        if (!snap.active) return true;
        List<String> keys = snap.keysByPath.get(path);
        if (keys == null) return true;
        if (s == null || s.getAttribute("username") == null) return false;
        if (MODE_ROLES.equals(snap.mode)) {
            for (String k : keys) if (can(s, k)) return true;
            return false;
        }
        for (String k : keys) {
            Permission permission = snap.byKey.get(k);
            boolean allowed = evaluateFor(permission, str(s, "role"), str(s, "department"), str(s, "username"),
                    rolesForUser(str(s, "username"), str(s, "role")), snap.grants.get(k));
            if (allowed) return true;
        }
        return false;
    }

    /** For menus: show the link when access control allows it (or, while inactive, when the old rule does). */
    public static boolean show(HttpSession s, String key, boolean oldRule) {
        Snapshot snap = current();
        if (!snap.active || !snap.byKey.containsKey(key)) return oldRule;
        return can(s, key);
    }

    /**
     * May this user use a standard action (VIEW, ADD, EDIT, DELETE, APPROVE, REJECT, PRINT, EXPORT) on a page?
     * When the catalogue has no such action for the page, the action is not controlled separately and page
     * access decides. Servlets must call this before doing the action, not only hide the button.
     */
    public static boolean canAction(HttpSession s, String pageKey, String actionCode) {
        String key = actionKey(pageKey, actionCode);
        return can(s, key == null ? pageKey : key);
    }

    /** The catalogue key of a page's standard action, or null when the page has none with that code. */
    public static String actionKey(String pageKey, String actionCode) {
        if (pageKey == null || actionCode == null) return null;
        String code = actionCode.trim().toUpperCase(Locale.ROOT);
        for (Permission p : current().permissions) {
            if (ACTION.equals(p.kind) && pageKey.equals(p.parentKey) && code.equals(p.actionCode)) return p.key;
        }
        return null;
    }

    /**
     * UAMS rule: allowed when one of the roles allows the key and every level above it, and (for links into
     * another project) that project. Unknown keys and missing levels are refused (fail closed).
     */
    static boolean uamsAllowed(Snapshot snap, Set<String> roles, Map<String, Set<String>> roleGrants, String key) {
        if (key == null || roles == null || roles.isEmpty()) return false;
        Set<String> seen = new HashSet<>();
        String k = key;
        while (k != null) {
            if (!seen.add(k)) return false;                       // a loop in the catalogue: refuse
            Permission p = snap.byKey.get(k);
            if (p == null || !anyRoleAllows(roles, roleGrants, k)) return false;
            if (PROJECT.equals(p.kind)) break;
            String parent = snap.parentOf(p);
            if (parent == null) return false;                     // level above is missing from the catalogue
            k = parent;
        }
        String target = LINK_PROJECT.get(key);
        return target == null || uamsAllowed(snap, roles, roleGrants, target);
    }

    private static boolean anyRoleAllows(Set<String> roles, Map<String, Set<String>> roleGrants, String key) {
        for (String r : roles) {
            Set<String> keys = roleGrants.get(r);
            if (keys != null && keys.contains(key)) return true;
        }
        return false;
    }

    /** UAMS roles assigned to the user (only these count in UAMS mode). */
    public static Set<String> uamsRolesFor(String username) {
        String key = normalize(username);
        if (key.isEmpty()) return Collections.emptySet();
        long now = System.currentTimeMillis();
        RoleCache cached = UAMS_ROLES.get(key);
        if (cached != null && now - cached.loadedAt <= CACHE_MILLIS) return cached.roles;
        Set<String> roles = new HashSet<>();
        try (Connection c = InventoryDB.getAuthConnection();
             PreparedStatement ps = c.prepareStatement("SELECT ur.role_key FROM access_user_role ur "
                     + "JOIN access_role ar ON ar.role_key=ur.role_key JOIN users u ON u.id=ur.user_id "
                     + "WHERE u.username=? AND ur.role_key LIKE 'R\\_%'")) {            // UAMS roles only, never old role names
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String role = rs.getString(1);
                    if (role != null && !"GLOBAL".equals(role)) roles.add(role);
                }
            }
        } catch (SQLException e) {
            LOG.warning("[access] UAMS roles not available for " + username + ": " + e.getMessage());
            return Collections.emptySet();                        // fail closed, do not cache the failure
        }
        Set<String> fixed = Collections.unmodifiableSet(roles);
        UAMS_ROLES.put(key, new RoleCache(fixed, now));
        return fixed;
    }

    /** True when the address is in the catalogue. */
    public static boolean isMapped(String path) {
        return current().keysByPath.containsKey(path);
    }

    /** The first page this user may open (catalogue order, skipping the dashboard), or null. */
    public static String firstAllowedPage(HttpSession s) {
        for (Permission p : current().permissions) {
            if (!"PINVENTORY".equals(p.app) || !"PAGE".equals(p.kind) || p.paths.isEmpty()) continue;
            if ("inv.home".equals(p.key) || "so.link".equals(p.key) || "phrms.link".equals(p.key)) continue;
            if (can(s, p.key)) return p.paths.get(0);
        }
        return null;
    }

    static boolean evaluate(String roleRaw, String deptRaw, String userRaw, List<Grant> grants) {
        String role = normalize(roleRaw);
        if ("GLOBAL".equals(role)) return true;
        if (grants == null || grants.isEmpty()) return false;
        String dept = normalize(deptRaw);
        String user = normalize(userRaw);
        boolean userAllow = false, otherAllow = false, otherDeny = false;
        for (Grant g : grants) {
            boolean match;
            switch (g.type) {
                case "USER":
                    if (!g.subject.equals(user)) continue;
                    if (!g.allow) return false;
                    userAllow = true;
                    continue;
                case "ALL": match = true; break;
                case "ROLE": match = g.subject.equals(role); break;
                case "DEPT": match = !dept.isEmpty() && g.subject.equals(dept); break;
                default: match = false;
            }
            if (!match) continue;
            if (g.allow) otherAllow = true; else otherDeny = true;
        }
        return userAllow || (otherAllow && !otherDeny);
    }

    private static boolean isRoleOnly(Permission permission) {
        return permission != null && ("PHRMS".equals(permission.app) || "phrms.link".equals(permission.key));
    }

    static boolean evaluateFor(Permission permission, String role, String department, String username,
                               Set<String> roles, List<Grant> grants) {
        return isRoleOnly(permission) ? evaluateRoles(role, roles, grants) : evaluate(role, department, username, grants);
    }

    /** Role-only permissions use every access role assigned to the user; user and department grants do not apply. */
    private static boolean evaluateRoles(String primaryRole, Set<String> roles, List<Grant> grants) {
        if ("GLOBAL".equals(normalize(primaryRole))) return true;
        if (roles == null || roles.isEmpty() || grants == null || grants.isEmpty()) return false;
        boolean allow = false, deny = false;
        for (Grant g : grants) {
            if (!"ROLE".equals(g.type) || "GLOBAL".equals(g.subject) || !roles.contains(g.subject)) continue;
            if (g.allow) allow = true; else deny = true;
        }
        return allow && !deny;
    }

    static Set<String> rolesForUser(String username, String primaryRole) {
        String key = normalize(username);
        if (key.isEmpty()) return Collections.emptySet();
        long now = System.currentTimeMillis();
        RoleCache cached = USER_ROLES.get(key);
        if (cached != null && now - cached.loadedAt <= CACHE_MILLIS) return cached.roles;
        Set<String> roles = new HashSet<>();
        String primary = normalize(primaryRole);
        if (!primary.isEmpty()) roles.add(primary);
        try (Connection c = InventoryDB.getAuthConnection();
             PreparedStatement ps = c.prepareStatement("SELECT ar.role_key FROM access_user_role ur "
                     + "JOIN access_role ar ON ar.role_key=ur.role_key JOIN users u ON u.id=ur.user_id WHERE u.username=?")) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String role = normalize(rs.getString(1));
                    if (!role.isEmpty() && !"GLOBAL".equals(role)) roles.add(role);
                }
            }
        } catch (SQLException e) {
            LOG.fine("[access] role assignments not available for " + username + ": " + e.getMessage());
        }
        Set<String> fixed = Collections.unmodifiableSet(roles);
        USER_ROLES.put(key, new RoleCache(fixed, now));
        return fixed;
    }

    /** Upper case; anything other than A-Z, 0-9 and _ becomes _ ("Dining Hall" -> DINING_HALL). */
    public static String normalize(String v) {
        return v == null ? "" : v.trim().toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9_]", "_");
    }

    // ------------------------------------------------------------------ data

    public static List<Permission> permissions() { return current().permissions; }

    public static Permission permission(String key) { return current().byKey.get(key); }

    public static List<Grant> grants() {
        List<Grant> all = new ArrayList<>();
        for (List<Grant> l : current().grants.values()) all.addAll(l);
        return all;
    }

    /** Reload on the next check (after a save). */
    public static void invalidate() { snapshot = null; USER_ROLES.clear(); UAMS_ROLES.clear(); }

    /** The parent level of a catalogue entry (for UAMS screens). */
    public static String parentOf(String key) {
        Snapshot s = current();
        Permission p = s.byKey.get(key);
        return p == null ? null : s.parentOf(p);
    }

    /** The UAMS rule for a set of roles and their grants (used by UAMS previews; same rule as can()). */
    public static boolean uamsAllowed(Set<String> roles, Map<String, Set<String>> roleGrants, String key) {
        return uamsAllowed(current(), roles, roleGrants, key);
    }

    /** Legacy rule for one user, exactly as each project applies it today (used by the UAMS migration preview). */
    public static boolean legacyAllowed(String app, String key, String role, String department, String username,
                                        Set<String> assignedRoles, List<Grant> grants) {
        if ("PHRMS".equals(app) || "phrms.link".equals(key)) return evaluateRoles(role, assignedRoles, grants);
        return evaluate(role, department, username, grants);       // PInventory and SchoolOperations use the same rule
    }

    /** Grants of one key (all subject types). */
    public static List<Grant> grantsOf(String key) {
        List<Grant> l = current().grants.get(key);
        return l == null ? Collections.emptyList() : l;
    }

    static Snapshot current() {
        Snapshot s = snapshot;
        long now = System.currentTimeMillis();
        if (s == null || now - s.loadedAt > CACHE_MILLIS) {
            synchronized (AccessControl.class) {
                s = snapshot;
                if (s == null || now - s.loadedAt > CACHE_MILLIS) {
                    s = load(now, s);
                    snapshot = s;
                }
            }
        }
        return s;
    }

    private static Snapshot load(long now, Snapshot previous) {
        List<Permission> perms = new ArrayList<>();
        List<Grant> grants = new ArrayList<>();
        String mode = MODE_LEGACY;
        try (Connection c = InventoryDB.getAuthConnection()) {
            boolean withCode = true;
            try {
                readPermissions(c, perms, true);
            } catch (SQLException noColumn) {                     // uams.sql not run yet: no action_code column
                perms.clear();
                withCode = false;
                readPermissions(c, perms, false);
            }
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT setting_value FROM access_setting WHERE setting_key='uams.mode'");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next() && withCode) mode = rs.getString(1);
            } catch (SQLException noSettings) {
                mode = MODE_LEGACY;                               // uams.sql not run yet
            }
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT perm_key, subject_type, subject, effect FROM access_grant");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    grants.add(new Grant(rs.getString(1), rs.getString(2), rs.getString(3), "ALLOW".equals(rs.getString(4))));
                }
            }
            if (previous == null || !previous.active || !String.valueOf(previous.mode).equals(MODE_ROLES.equals(mode) ? MODE_ROLES : MODE_LEGACY)) {
                LOG.info("[access] access control active: " + perms.size() + " entries, mode " + mode);
            }
            return new Snapshot(!perms.isEmpty(), mode, perms, grants, now);
        } catch (SQLException e) {
            if (previous != null && previous.active) {
                LOG.warning("[access] could not reload access settings (" + e.getMessage() + "); keeping the last ones");
                return new Snapshot(true, previous.mode, new ArrayList<>(previous.permissions), flatten(previous), now);
            }
            if (previous == null) LOG.info("[access] access tables not available (" + e.getMessage()
                    + "); old fixed rules apply. Run src/main/resources/sql/access_control.sql to enable.");
            return new Snapshot(false, new ArrayList<>(), new ArrayList<>(), now);
        }
    }

    private static void readPermissions(Connection c, List<Permission> perms, boolean withCode) throws SQLException {
        String sql = "SELECT perm_key, app, module, kind, " + (withCode ? "action_code, " : "NULL AS action_code, ")
                + "parent_key, label, description, paths, sort_order FROM access_permission ORDER BY sort_order, perm_key";
        try (PreparedStatement ps = c.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                List<String> paths = new ArrayList<>();
                String raw = rs.getString("paths");
                if (raw != null) for (String p : raw.split(",")) if (!p.trim().isEmpty()) paths.add(p.trim());
                perms.add(new Permission(rs.getString("perm_key"), rs.getString("app"), rs.getString("module"),
                        rs.getString("kind"), rs.getString("action_code"), rs.getString("parent_key"), rs.getString("label"),
                        rs.getString("description"), Collections.unmodifiableList(paths), rs.getInt("sort_order")));
            }
        }
    }

    private static List<Grant> flatten(Snapshot s) {
        List<Grant> all = new ArrayList<>();
        for (List<Grant> l : s.grants.values()) all.addAll(l);
        return all;
    }

    private static String str(HttpSession s, String name) {
        Object v = s.getAttribute(name);
        return v == null ? null : String.valueOf(v);
    }

    // for tests
    static void use(Snapshot s) { snapshot = s; }
    static Snapshot snapshotOf(List<Permission> p, List<Grant> g) { return new Snapshot(true, p, g, Long.MAX_VALUE / 2); }
    static Snapshot snapshotOf(String mode, List<Permission> p, List<Grant> g) { return new Snapshot(true, mode, p, g, Long.MAX_VALUE / 2); }
    static Permission perm(String key, String app, String kind, String... paths) {
        List<String> l = new ArrayList<>();
        Collections.addAll(l, paths);
        return new Permission(key, app, "M", kind, null, key, null, l, 0);
    }
    static Grant grant(String key, String type, String subject, boolean allow) { return new Grant(key, type, subject, allow); }
}
