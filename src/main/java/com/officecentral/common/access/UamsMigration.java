package com.officecentral.common.access;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;

import com.officecentral.common.db.InventoryDB;

/**
 * One-time move from the old rules (users.role, department and user grants) to UAMS roles, without anyone
 * gaining or losing access.
 *
 * For every role + department combination in use, the pages and actions it can use today (each project's own
 * current rule) become one starter role, e.g. "Indenter - Dining Hall", and its users get that role. Access a
 * user has only by name (user grants) becomes a "Personal - username" role. Global users need no role.
 *
 * preview() changes nothing and compares, per user and project, today's access with the access the user
 * would have in UAMS mode. apply() creates the roles and assignments that do not exist yet; it never changes
 * a role that already exists, so it is safe to run again.
 */
public final class UamsMigration {

    private UamsMigration() { }

    static final class User {
        int id; String username, role, department;
        Set<String> legacyRoles = new HashSet<>();               // old access_user_role rows (HR reads them today)
        Set<String> assigned = new HashSet<>();                  // UAMS roles already assigned
    }

    static final class PlannedRole {
        String key, name, description;
        final Set<String> keys = new TreeSet<>();
        final List<Integer> users = new ArrayList<>();
        boolean exists;
    }

    public static Map<String, Object> preview() throws SQLException { return run(false, null); }

    public static Map<String, Object> apply(String by) throws SQLException {
        if (AccessControl.uamsMode()) throw new UamsService.Refused("PInventory already uses UAMS roles. Switch back to the old rules first.");
        return run(true, by);
    }

    private static Map<String, Object> run(boolean apply, String by) throws SQLException {
        List<AccessControl.Permission> catalogue = AccessControl.permissions();
        List<AccessControl.Permission> controlled = new ArrayList<>();
        for (AccessControl.Permission p : catalogue) {
            if (AccessControl.PAGE.equals(p.kind) || AccessControl.ACTION.equals(p.kind)) controlled.add(p);
        }
        Map<String, AccessControl.Permission> byKey = new HashMap<>();
        for (AccessControl.Permission p : catalogue) byKey.put(p.key, p);

        try (Connection c = InventoryDB.getAuthConnection()) {
            List<User> users = loadUsers(c);
            Set<String> existingRoles = UamsService.roleKeys(c);
            Map<String, PlannedRole> plan = new LinkedHashMap<>();
            Map<Integer, Set<String>> legacy = new HashMap<>();

            for (User u : users) {
                if (UamsService.isGlobal(u.role)) continue;
                Set<String> combo = legacySet(controlled, u, "");        // what the role + department gives
                Set<String> mine = legacySet(controlled, u, u.username); // plus grants by user name
                legacy.put(u.id, mine);

                String roleText = blank(u.role) ? "No role" : u.role.trim();
                String deptText = blank(u.department) ? "No department" : u.department.trim();
                String key = cut(UamsService.ROLE_PREFIX + AccessControl.normalize(roleText) + "__" + AccessControl.normalize(deptText));
                PlannedRole pr = plan.computeIfAbsent(key, k -> {
                    PlannedRole r = new PlannedRole();
                    r.key = k; r.name = cutName(roleText + " - " + deptText);
                    r.description = "Starter role from the old rules: role " + roleText + ", department " + deptText + ".";
                    r.keys.addAll(withLevels(combo, byKey));
                    return r;
                });
                pr.users.add(u.id);

                Set<String> extra = new TreeSet<>(mine);
                extra.removeAll(combo);
                if (!extra.isEmpty()) {
                    String pk = cut(UamsService.ROLE_PREFIX + "USER__" + AccessControl.normalize(u.username));
                    PlannedRole personal = plan.computeIfAbsent(pk, k -> {
                        PlannedRole r = new PlannedRole();
                        r.key = k; r.name = cutName("Personal - " + u.username);
                        r.description = "Access " + u.username + " had by name under the old rules.";
                        return r;
                    });
                    personal.keys.addAll(withLevels(extra, byKey));
                    personal.users.add(u.id);
                }
            }
            for (PlannedRole r : plan.values()) r.exists = existingRoles.contains(r.key);

            // Grants each role will have: existing roles keep what they have now, new roles get the plan.
            Map<String, Set<String>> grants = new HashMap<>();
            for (String r : existingRoles) grants.put(r, UamsService.roleGrants(c, r));
            for (PlannedRole r : plan.values()) if (!r.exists) grants.put(r.key, r.keys);

            int createdRoles = 0, assignments = 0;
            if (apply) {
                final Map<String, PlannedRole> fplan = plan;
                int[] counts = UamsService.tx(c, () -> {
                    int roles = 0, assigned = 0;
                    Map<Integer, String> names = new HashMap<>();
                    for (User u : users) names.put(u.id, u.username);
                    for (PlannedRole r : fplan.values()) {
                        if (!r.exists) {
                            try (PreparedStatement ps = c.prepareStatement("INSERT INTO access_role (role_key, role_name, description, "
                                    + "created_by) VALUES (?,?,?,?)")) {
                                ps.setString(1, r.key); ps.setString(2, uniqueName(c, r.name)); ps.setString(3, r.description);
                                ps.setString(4, by); ps.executeUpdate();
                            }
                            UamsService.writeRoleGrants(c, r.key, new HashSet<>(), r.keys, by);
                            UamsService.audit(c, "MIGRATION", r.key, "ROLE CREATED", r.name + " (" + r.keys.size() + " entries)", by);
                            roles++;
                        }
                        for (int id : r.users) {
                            String username = UamsService.lockUser(c, id);
                            try (PreparedStatement ps = c.prepareStatement("SELECT 1 FROM access_user_role WHERE user_id=? AND role_key=?")) {
                                ps.setInt(1, id); ps.setString(2, r.key);
                                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) continue; }
                            }
                            UamsService.assign(c, id, username, r.key, by);
                            assigned++;
                        }
                    }
                    UamsService.audit(c, "MIGRATION", "-", "APPLIED", roles + " role(s) created, " + assigned + " assignment(s)", by);
                    return new int[] { roles, assigned };
                });
                createdRoles = counts[0]; assignments = counts[1];
                AccessControl.invalidate();
                for (User u : users) {                                    // reflect what was just written
                    for (PlannedRole r : plan.values()) if (r.users.contains(u.id)) u.assigned.add(r.key);
                }
                for (PlannedRole r : plan.values()) r.exists = true;
            }

            // Compare, per user and project: today's access vs. UAMS access (assigned roles + planned roles).
            Map<String, String> appName = new LinkedHashMap<>();
            for (AccessControl.Permission p : catalogue) if (AccessControl.PROJECT.equals(p.kind)) appName.put(p.app, p.label);
            List<Map<String, Object>> rows = new ArrayList<>();
            int same = 0, different = 0;
            for (User u : users) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("id", u.id); row.put("username", u.username); row.put("oldRole", u.role); row.put("department", u.department);
                if (UamsService.isGlobal(u.role)) {
                    row.put("global", true); row.put("same", true); rows.add(row); same++; continue;
                }
                Set<String> roles = new HashSet<>(u.assigned);
                List<String> roleNames = new ArrayList<>();
                for (PlannedRole r : plan.values()) if (r.users.contains(u.id)) { roles.add(r.key); roleNames.add(r.name); }
                Set<String> before = legacy.get(u.id);
                List<String> lost = new ArrayList<>(), gained = new ArrayList<>();
                Map<String, int[]> perApp = new TreeMap<>();
                for (AccessControl.Permission p : controlled) {
                    boolean b = before.contains(p.key);
                    boolean a = AccessControl.uamsAllowed(roles, grants, p.key);
                    int[] n = perApp.computeIfAbsent(p.app, x -> new int[2]);
                    if (b) n[0]++;
                    if (a) n[1]++;
                    if (b && !a) lost.add(describe(p, byKey));
                    if (a && !b) gained.add(describe(p, byKey));
                }
                List<Map<String, Object>> apps = new ArrayList<>();
                for (Map.Entry<String, int[]> e : perApp.entrySet()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("project", appName.getOrDefault(e.getKey(), e.getKey())); m.put("before", e.getValue()[0]); m.put("after", e.getValue()[1]);
                    apps.add(m);
                }
                boolean ok = lost.isEmpty() && gained.isEmpty();
                if (ok) same++; else different++;
                row.put("global", false); row.put("same", ok); row.put("roles", roleNames); row.put("projects", apps);
                row.put("lost", lost); row.put("gained", gained);
                rows.add(row);
            }

            List<Map<String, Object>> roleList = new ArrayList<>();
            for (PlannedRole r : plan.values()) {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("key", r.key); m.put("name", r.name); m.put("users", r.users.size()); m.put("entries", r.keys.size());
                m.put("exists", r.exists);
                roleList.add(m);
            }
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("roles", roleList);
            out.put("users", rows);
            out.put("same", same);
            out.put("different", different);
            out.put("toCreate", plan.values().stream().filter(r -> !r.exists).count());
            out.put("applied", apply);
            out.put("createdRoles", createdRoles);
            out.put("assignments", assignments);
            out.put("mode", AccessControl.uamsMode() ? AccessControl.MODE_ROLES : AccessControl.MODE_LEGACY);
            return out;
        }
    }

    /** Pages and actions the user can use today, by each project's own current rule. */
    private static Set<String> legacySet(List<AccessControl.Permission> controlled, User u, String username) {
        Set<String> assigned = new HashSet<>(u.legacyRoles);
        String primary = AccessControl.normalize(u.role);
        if (!primary.isEmpty()) assigned.add(primary);
        Set<String> out = new HashSet<>();
        for (AccessControl.Permission p : controlled) {
            if (AccessControl.legacyAllowed(p.app, p.key, u.role, u.department, username, assigned, AccessControl.grantsOf(p.key))) {
                out.add(p.key);
            }
        }
        return out;
    }

    /** Adds the module and project of each page (and the target project of a project link). */
    private static Set<String> withLevels(Set<String> keys, Map<String, AccessControl.Permission> byKey) {
        Set<String> out = new TreeSet<>(keys);
        for (String k : keys) {
            AccessControl.Permission p = byKey.get(k);
            if (p == null || !AccessControl.PAGE.equals(p.kind)) continue;
            String mod = AccessControl.parentOf(k);
            if (mod != null) {
                out.add(mod);
                String proj = AccessControl.parentOf(mod);
                if (proj != null) out.add(proj);
            }
            if ("so.link".equals(k)) out.add("proj.SCHOOLOPS");
            if ("phrms.link".equals(k)) out.add("proj.PHRMS");
        }
        return out;
    }

    private static List<User> loadUsers(Connection c) throws SQLException {
        Map<Integer, User> users = new LinkedHashMap<>();
        try (PreparedStatement ps = c.prepareStatement("SELECT id, username, role, department FROM users ORDER BY username");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                User u = new User();
                u.id = rs.getInt(1); u.username = rs.getString(2); u.role = rs.getString(3); u.department = rs.getString(4);
                users.put(u.id, u);
            }
        }
        try (PreparedStatement ps = c.prepareStatement("SELECT user_id, role_key FROM access_user_role"); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                User u = users.get(rs.getInt(1));
                if (u == null) continue;
                String r = rs.getString(2);
                if (r.startsWith(UamsService.ROLE_PREFIX)) u.assigned.add(r); else u.legacyRoles.add(AccessControl.normalize(r));
            }
        }
        return new ArrayList<>(users.values());
    }

    private static String uniqueName(Connection c, String name) throws SQLException {
        String n = name;
        for (int i = 2; ; i++) {
            try (PreparedStatement ps = c.prepareStatement("SELECT 1 FROM access_role WHERE LOWER(role_name)=LOWER(?)")) {
                ps.setString(1, n);
                try (ResultSet rs = ps.executeQuery()) { if (!rs.next()) return n; }
            }
            n = cutName(name + " (" + i + ")");
        }
    }

    private static String describe(AccessControl.Permission p, Map<String, AccessControl.Permission> byKey) {
        if (AccessControl.ACTION.equals(p.kind)) {
            AccessControl.Permission page = byKey.get(p.parentKey);
            return (page == null ? "" : page.label + " > ") + p.label;
        }
        return p.module + " > " + p.label;
    }

    private static boolean blank(String s) { return s == null || s.trim().isEmpty(); }
    private static String cut(String k) { return k.length() > 80 ? k.substring(0, 80) : k; }
    private static String cutName(String n) { return n.length() > 100 ? n.substring(0, 100) : n; }
}
