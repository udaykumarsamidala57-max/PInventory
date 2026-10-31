package com.mobile;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import com.officecentral.common.db.InventoryDB;

/**
 * Role + department based switches for the Android app (table mobile_app_access in the login database).
 *
 * A rule is (role, department, feature) -> enabled. "*" means "all roles" / "all departments".
 * The most specific rule wins: role+department, then role+all, then all+department, then all+all.
 * With no rule at all, a feature is ON (so existing users keep working until an admin changes it).
 */
public final class MobileAccessDAO {

    public static final String ANY = "*";

    /** Feature key -> label shown on the admin page. Order = column order. */
    public static final Map<String, String> FEATURES = new LinkedHashMap<>();
    static {
        FEATURES.put("app.login", "App Login");
        FEATURES.put("indent.view", "My Indents");
        FEATURES.put("indent.create", "New Indent");
        FEATURES.put("indent.approve", "Approve Indents");
        FEATURES.put("stock.view", "Stock Reports");
        FEATURES.put("service.view", "Service Requests");
        FEATURES.put("service.create", "Raise Request");
        FEATURES.put("service.update", "Update Request Status");
    }

    private static volatile boolean tableReady = false;

    public static final class Rule {
        public final String role, department, feature;
        public final Boolean enabled; // null = inherit (delete rule)

        public Rule(String role, String department, String feature, Boolean enabled) {
            this.role = role;
            this.department = department;
            this.feature = feature;
            this.enabled = enabled;
        }
    }

    private static void ensureTable(Connection con) throws SQLException {
        if (tableReady) return;
        try (Statement st = con.createStatement()) {
            st.executeUpdate("CREATE TABLE IF NOT EXISTS mobile_app_access ("
                    + " id INT AUTO_INCREMENT PRIMARY KEY,"
                    + " role VARCHAR(50) NOT NULL,"
                    + " department VARCHAR(100) NOT NULL,"
                    + " feature VARCHAR(40) NOT NULL,"
                    + " enabled TINYINT(1) NOT NULL DEFAULT 1,"
                    + " updated_by VARCHAR(100) NULL,"
                    + " updated_on DATETIME NULL,"
                    + " UNIQUE KEY uq_mobile_access (role, department, feature))");
        }
        tableReady = true;
    }

    private static String key(String role, String dept, String feature) {
        return norm(role) + "|" + norm(dept) + "|" + feature;
    }

    private static String norm(String s) {
        return s == null ? "" : s.trim().toLowerCase(Locale.ROOT);
    }

    /** All rules as key(role|dept|feature) -> enabled. */
    public Map<String, Boolean> loadRules() throws SQLException {
        Map<String, Boolean> rules = new HashMap<>();
        try (Connection con = InventoryDB.getAuthConnection()) {
            ensureTable(con);
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT role, department, feature, enabled FROM mobile_app_access");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rules.put(key(rs.getString(1), rs.getString(2), rs.getString(3)), rs.getBoolean(4));
                }
            }
        }
        return rules;
    }

    /** Explicit rule for exactly this role/department/feature, or null. */
    public static Boolean explicit(Map<String, Boolean> rules, String role, String dept, String feature) {
        return rules.get(key(role, dept, feature));
    }

    /** Effective value using the most specific rule (default ON). */
    public static boolean effective(Map<String, Boolean> rules, String role, String dept, String feature) {
        String[][] order = {{role, dept}, {role, ANY}, {ANY, dept}, {ANY, ANY}};
        for (String[] o : order) {
            if (o[0] == null || o[1] == null) continue;
            Boolean v = rules.get(key(o[0], o[1], feature));
            if (v != null) return v;
        }
        return true;
    }

    /** Value a cell would get if its own rule were removed (shown as "Inherit (On/Off)"). */
    public static boolean inherited(Map<String, Boolean> rules, String role, String dept, String feature) {
        List<String[]> order = new ArrayList<>();
        boolean anyRole = ANY.equals(role), anyDept = ANY.equals(dept);
        if (!anyRole && !anyDept) { order.add(new String[]{role, ANY}); order.add(new String[]{ANY, dept}); }
        if (!(anyRole && anyDept)) order.add(new String[]{ANY, ANY});
        for (String[] o : order) {
            Boolean v = rules.get(key(o[0], o[1], feature));
            if (v != null) return v;
        }
        return true;
    }

    /** Features this user may use in the Android app. */
    public Set<String> featuresFor(String role, String department) throws SQLException {
        Set<String> out = new LinkedHashSet<>();
        // Receptionists use only Visitor Management: app login, no indent / stock / service options.
        if (com.officecentral.common.web.VisitorOnlyFilter.isReceptionist(role)) {
            out.add("app.login");
            return out;
        }
        Map<String, Boolean> rules = loadRules();
        for (String f : FEATURES.keySet()) {
            if (effective(rules, role, department, f)) out.add(f);
        }
        return out;
    }

    /** Distinct role/department pairs from the users table (for the admin grid). */
    public List<String[]> roleDepartments() throws SQLException {
        List<String[]> list = new ArrayList<>();
        try (Connection con = InventoryDB.getAuthConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT DISTINCT TRIM(role), TRIM(department) FROM users "
                     + "WHERE role IS NOT NULL AND TRIM(role) <> '' ORDER BY 1, 2");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new String[]{rs.getString(1), rs.getString(2) == null ? "" : rs.getString(2)});
            }
        }
        return list;
    }

    /** Saves the given cells in one transaction (null enabled = remove rule, i.e. inherit). */
    public void save(List<Rule> rules, String user) throws SQLException {
        try (Connection con = InventoryDB.getAuthConnection()) {
            ensureTable(con);
            con.setAutoCommit(false);
            try (PreparedStatement del = con.prepareStatement(
                         "DELETE FROM mobile_app_access WHERE role=? AND department=? AND feature=?");
                 PreparedStatement up = con.prepareStatement(
                         "INSERT INTO mobile_app_access (role, department, feature, enabled, updated_by, updated_on) "
                         + "VALUES (?,?,?,?,?,?) ON DUPLICATE KEY UPDATE enabled=VALUES(enabled), "
                         + "updated_by=VALUES(updated_by), updated_on=VALUES(updated_on)")) {
                Timestamp now = new Timestamp(System.currentTimeMillis());
                for (Rule r : rules) {
                    if (r.enabled == null) {
                        del.setString(1, r.role);
                        del.setString(2, r.department);
                        del.setString(3, r.feature);
                        del.addBatch();
                    } else {
                        up.setString(1, r.role);
                        up.setString(2, r.department);
                        up.setString(3, r.feature);
                        up.setBoolean(4, r.enabled);
                        up.setString(5, user);
                        up.setTimestamp(6, now);
                        up.addBatch();
                    }
                }
                del.executeBatch();
                up.executeBatch();
                con.commit();
            } catch (SQLException | RuntimeException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }
}
