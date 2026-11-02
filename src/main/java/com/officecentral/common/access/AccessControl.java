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
import java.util.logging.Logger;

import javax.servlet.http.HttpSession;

import com.officecentral.common.db.InventoryDB;

/**
 * Page and button access for PInventory and SchoolOperations, set by Global users on the Access Control
 * page (tables access_permission and access_grant in the inventory database).
 *
 * Rules, in order: the Global role may do everything; a grant for the user by name decides; otherwise a
 * DENY for their role or department wins over an ALLOW for their role, department or "all users"; nothing
 * matching = no access. Addresses that are not in the catalogue are not checked here.
 *
 * When the tables do not exist yet (SQL not run) access control is inactive and the old fixed rules apply.
 */
public final class AccessControl {

    private static final Logger LOG = Logger.getLogger(AccessControl.class.getName());
    static final long CACHE_MILLIS = 30_000;

    /** One page or button from the catalogue. */
    public static final class Permission {
        public final String key, app, module, kind, parentKey, label, description;
        public final List<String> paths;
        public final int sortOrder;

        Permission(String key, String app, String module, String kind, String parentKey, String label,
                   String description, List<String> paths, int sortOrder) {
            this.key = key; this.app = app; this.module = module; this.kind = kind; this.parentKey = parentKey;
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
        final List<Permission> permissions;                 // sort order
        final Map<String, Permission> byKey;
        final Map<String, List<String>> keysByPath;         // address -> page keys (any of them allows it)
        final Map<String, List<Grant>> grants;
        final long loadedAt;

        Snapshot(boolean active, List<Permission> permissions, List<Grant> grantList, long loadedAt) {
            this.active = active;
            this.permissions = Collections.unmodifiableList(permissions);
            this.loadedAt = loadedAt;
            Map<String, Permission> k = new HashMap<>();
            Map<String, List<String>> p = new HashMap<>();
            for (Permission perm : permissions) {
                k.put(perm.key, perm);
                if ("PINVENTORY".equals(perm.app) && "PAGE".equals(perm.kind)) {
                    for (String path : perm.paths) p.computeIfAbsent(path, x -> new ArrayList<>()).add(perm.key);
                }
            }
            Map<String, List<Grant>> g = new HashMap<>();
            for (Grant gr : grantList) g.computeIfAbsent(gr.key, x -> new ArrayList<>()).add(gr);
            this.byKey = k;
            this.keysByPath = p;
            this.grants = g;
        }
    }

    private static volatile Snapshot snapshot;

    private AccessControl() { }

    // ------------------------------------------------------------------ checks

    /** True once the access tables exist; until then the old fixed rules apply everywhere. */
    public static boolean isActive() { return current().active; }

    /** May this signed-in user use the page or button? */
    public static boolean can(HttpSession s, String key) {
        if (s == null || s.getAttribute("username") == null) return false;
        return evaluate(str(s, "role"), str(s, "department"), str(s, "username"), current().grants.get(key));
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
        for (String k : keys) {
            if (evaluate(str(s, "role"), str(s, "department"), str(s, "username"), snap.grants.get(k))) return true;
        }
        return false;
    }

    /** For menus: show the link when access control allows it (or, while inactive, when the old rule does). */
    public static boolean show(HttpSession s, String key, boolean oldRule) {
        Snapshot snap = current();
        if (!snap.active || !snap.byKey.containsKey(key)) return oldRule;
        return can(s, key);
    }

    /** True when the address is in the catalogue. */
    public static boolean isMapped(String path) {
        return current().keysByPath.containsKey(path);
    }

    /** The first page this user may open (catalogue order, skipping the dashboard), or null. */
    public static String firstAllowedPage(HttpSession s) {
        for (Permission p : current().permissions) {
            if (!"PINVENTORY".equals(p.app) || !"PAGE".equals(p.kind) || p.paths.isEmpty()) continue;
            if ("inv.home".equals(p.key) || "so.link".equals(p.key)) continue;
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
    public static void invalidate() { snapshot = null; }

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
        try (Connection c = InventoryDB.getAuthConnection()) {
            try (PreparedStatement ps = c.prepareStatement("SELECT perm_key, app, module, kind, parent_key, label, "
                    + "description, paths, sort_order FROM access_permission ORDER BY sort_order, perm_key");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    List<String> paths = new ArrayList<>();
                    String raw = rs.getString("paths");
                    if (raw != null) for (String p : raw.split(",")) if (!p.trim().isEmpty()) paths.add(p.trim());
                    perms.add(new Permission(rs.getString("perm_key"), rs.getString("app"), rs.getString("module"),
                            rs.getString("kind"), rs.getString("parent_key"), rs.getString("label"),
                            rs.getString("description"), Collections.unmodifiableList(paths), rs.getInt("sort_order")));
                }
            }
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT perm_key, subject_type, subject, effect FROM access_grant");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    grants.add(new Grant(rs.getString(1), rs.getString(2), rs.getString(3), "ALLOW".equals(rs.getString(4))));
                }
            }
            if (previous == null || !previous.active) LOG.info("[access] access control active: " + perms.size() + " pages/buttons");
            return new Snapshot(!perms.isEmpty(), perms, grants, now);
        } catch (SQLException e) {
            if (previous != null && previous.active) {
                LOG.warning("[access] could not reload access settings (" + e.getMessage() + "); keeping the last ones");
                return new Snapshot(true, new ArrayList<>(previous.permissions), flatten(previous), now);
            }
            if (previous == null) LOG.info("[access] access tables not available (" + e.getMessage()
                    + "); old fixed rules apply. Run src/main/resources/sql/access_control.sql to enable.");
            return new Snapshot(false, new ArrayList<>(), new ArrayList<>(), now);
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
    static Permission perm(String key, String app, String kind, String... paths) {
        List<String> l = new ArrayList<>();
        Collections.addAll(l, paths);
        return new Permission(key, app, "M", kind, null, key, null, l, 0);
    }
    static Grant grant(String key, String type, String subject, boolean allow) { return new Grant(key, type, subject, allow); }
}
