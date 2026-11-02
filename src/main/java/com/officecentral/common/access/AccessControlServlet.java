package com.officecentral.common.access;

import java.io.BufferedReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.officecentral.common.db.InventoryDB;
import com.officecentral.common.web.Csrf;

/**
 * Access Control settings page (Global role only, fixed in code so nobody can lock Global out).
 *
 *   GET  /access-control            the page
 *   GET  /access-control/data       catalogue, grants, roles, departments and users (JSON)
 *   POST /access-control/save       {subjectType, subject, changes:[{key, effect: "ALLOW"|"DENY"|null}]}
 *   GET  /access-control/effective  ?username=... what one user can open
 *   GET  /access-control/audit      latest changes
 */
@WebServlet(urlPatterns = {"/access-control", "/access-control/*"})
public class AccessControlServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(AccessControlServlet.class.getName());
    private static final Pattern SUBJECT = Pattern.compile("[A-Z0-9_]{1,80}");
    private static final Set<String> TYPES = new HashSet<>(java.util.Arrays.asList("ALL", "ROLE", "DEPT", "USER"));
    private static final int MAX_BODY = 256 * 1024;
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession s = req.getSession(false);
        if (!signedIn(s)) { resp.sendRedirect(req.getContextPath() + "/login.jsp"); return; }
        if (!isGlobal(s)) { resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Control is available only to Global users."); return; }
        String sub = req.getPathInfo() == null ? "" : req.getPathInfo();
        try {
            switch (sub) {
                case "":
                case "/":
                    req.setAttribute("pageTitle", "Access Control");
                    req.getRequestDispatcher("/WEB-INF/views/common/access-control.jsp").forward(req, resp);
                    return;
                case "/data": json(resp, data()); return;
                case "/effective": json(resp, effective(req.getParameter("username"))); return;
                case "/audit": json(resp, audit()); return;
                default: resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "[access] access-control read failed", e);
            error(resp, 503, "The access tables are not available. Run src/main/resources/sql/access_control.sql on the inventory database.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession s = req.getSession(false);
        if (!signedIn(s)) { error(resp, 401, "Please sign in again."); return; }
        if (!isGlobal(s)) { error(resp, 403, "Access Control is available only to Global users."); return; }
        if (!Csrf.valid(req, s)) { error(resp, 403, "This page has expired. Please reload it and try again."); return; }
        if (!"/save".equals(req.getPathInfo())) { resp.sendError(HttpServletResponse.SC_NOT_FOUND); return; }
        if (req.getContentLength() > MAX_BODY) { error(resp, 413, "Too many changes at once."); return; }
        JsonObject body;
        try {
            body = JsonParser.parseString(read(req)).getAsJsonObject();
        } catch (RuntimeException e) {
            error(resp, 400, "The request could not be read."); return;
        }
        String type = text(body, "subjectType");
        String subject = "ALL".equals(type) ? "*" : AccessControl.normalize(text(body, "subject"));
        if (type == null || !TYPES.contains(type) || (!"*".equals(subject) && !SUBJECT.matcher(subject).matches())) {
            error(resp, 400, "Choose who the access is for."); return;
        }
        JsonArray changes = body.has("changes") && body.get("changes").isJsonArray() ? body.getAsJsonArray("changes") : new JsonArray();
        if (changes.size() == 0) { error(resp, 400, "There are no changes to save."); return; }
        if (changes.size() > 500) { error(resp, 400, "Too many changes at once."); return; }
        Map<String, String> wanted = new LinkedHashMap<>();
        for (JsonElement el : changes) {
            if (!el.isJsonObject()) { error(resp, 400, "The request could not be read."); return; }
            JsonObject c = el.getAsJsonObject();
            String key = text(c, "key");
            String effect = text(c, "effect");
            if (key == null || key.length() > 80) { error(resp, 400, "Unknown page or button."); return; }
            if (effect != null && !"ALLOW".equals(effect) && !"DENY".equals(effect)) { error(resp, 400, "Choose Allow, Deny or not set."); return; }
            if ("ALL".equals(type) && "DENY".equals(effect)) { error(resp, 400, "\"All users\" can only be allowed; remove the access instead."); return; }
            wanted.put(key, effect);
        }
        String by = String.valueOf(s.getAttribute("username"));
        try {
            int saved = save(type, subject, wanted, by);
            AccessControl.invalidate();
            LOG.info("[access] " + by + " changed " + saved + " access setting(s) for " + type + " " + subject);
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("saved", saved);
            json(resp, out);
        } catch (IllegalArgumentException e) {
            error(resp, 400, e.getMessage());
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "[access] access-control save failed", e);
            error(resp, 500, "Could not save the access settings. Nothing was changed.");
        }
    }

    // ------------------------------------------------------------------ data

    private Map<String, Object> data() throws SQLException {
        Map<String, Object> out = new LinkedHashMap<>();
        List<Map<String, Object>> perms = new ArrayList<>();
        List<Map<String, Object>> grants = new ArrayList<>();
        Map<String, Integer> roles = new TreeMap<>(), depts = new TreeMap<>();
        Map<String, String> roleNames = new TreeMap<>(), deptNames = new TreeMap<>();
        List<Map<String, Object>> users = new ArrayList<>();
        try (Connection c = InventoryDB.getAuthConnection()) {
            try (PreparedStatement ps = c.prepareStatement("SELECT perm_key, app, module, kind, parent_key, label, description, "
                    + "paths FROM access_permission ORDER BY sort_order, perm_key"); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> p = new LinkedHashMap<>();
                    p.put("key", rs.getString(1)); p.put("app", rs.getString(2)); p.put("module", rs.getString(3));
                    p.put("kind", rs.getString(4)); p.put("parent", rs.getString(5)); p.put("label", rs.getString(6));
                    p.put("description", rs.getString(7)); p.put("paths", rs.getString(8));
                    perms.add(p);
                }
            }
            try (PreparedStatement ps = c.prepareStatement("SELECT perm_key, subject_type, subject, effect, granted_by, "
                    + "granted_at FROM access_grant"); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> g = new LinkedHashMap<>();
                    g.put("key", rs.getString(1)); g.put("type", rs.getString(2)); g.put("subject", rs.getString(3));
                    g.put("effect", rs.getString(4)); g.put("by", rs.getString(5));
                    g.put("at", rs.getTimestamp(6) == null ? null : rs.getTimestamp(6).toString());
                    grants.add(g);
                }
            }
            try (PreparedStatement ps = c.prepareStatement("SELECT username, role, department FROM users ORDER BY username");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String u = rs.getString(1), r = rs.getString(2), d = rs.getString(3);
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("username", u); m.put("role", r); m.put("department", d);
                    users.add(m);
                    count(roles, roleNames, r);
                    count(depts, deptNames, d);
                }
            }
        }
        out.put("permissions", perms);
        out.put("grants", grants);
        out.put("roles", subjects(roles, roleNames));
        out.put("departments", subjects(depts, deptNames));
        out.put("users", users);
        return out;
    }

    private static void count(Map<String, Integer> counts, Map<String, String> names, String raw) {
        String n = AccessControl.normalize(raw);
        if (n.isEmpty()) return;
        counts.merge(n, 1, Integer::sum);
        names.putIfAbsent(n, raw.trim());
    }

    private static List<Map<String, Object>> subjects(Map<String, Integer> counts, Map<String, String> names) {
        List<Map<String, Object>> out = new ArrayList<>();
        for (Map.Entry<String, Integer> e : counts.entrySet()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("subject", e.getKey()); m.put("name", names.get(e.getKey())); m.put("users", e.getValue());
            out.add(m);
        }
        return out;
    }

    private Map<String, Object> effective(String username) throws SQLException {
        Map<String, Object> out = new LinkedHashMap<>();
        if (username == null || username.trim().isEmpty()) return out;
        String role = null, dept = null;
        boolean found = false;
        try (Connection c = InventoryDB.getAuthConnection();
             PreparedStatement ps = c.prepareStatement("SELECT role, department FROM users WHERE username=?")) {
            ps.setString(1, username.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) { found = true; role = rs.getString(1); dept = rs.getString(2); }
            }
        }
        out.put("found", found);
        if (!found) return out;
        out.put("username", username.trim()); out.put("role", role); out.put("department", dept);
        Map<String, List<AccessControl.Grant>> byKey = new LinkedHashMap<>();
        for (AccessControl.Grant g : AccessControl.grants()) byKey.computeIfAbsent(g.key, k -> new ArrayList<>()).add(g);
        List<String> allowed = new ArrayList<>();
        for (AccessControl.Permission p : AccessControl.permissions()) {
            if (AccessControl.evaluate(role, dept, username, byKey.get(p.key))) allowed.add(p.key);
        }
        out.put("allowed", allowed);
        return out;
    }

    private List<Map<String, Object>> audit() throws SQLException {
        List<Map<String, Object>> out = new ArrayList<>();
        try (Connection c = InventoryDB.getAuthConnection();
             PreparedStatement ps = c.prepareStatement("SELECT a.changed_at, a.changed_by, a.subject_type, a.subject, a.perm_key, "
                     + "p.label, a.old_effect, a.new_effect FROM access_grant_audit a LEFT JOIN access_permission p "
                     + "ON p.perm_key=a.perm_key ORDER BY a.id DESC LIMIT 200");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("at", rs.getTimestamp(1) == null ? null : rs.getTimestamp(1).toString());
                m.put("by", rs.getString(2)); m.put("type", rs.getString(3)); m.put("subject", rs.getString(4));
                m.put("key", rs.getString(5)); m.put("label", rs.getString(6));
                m.put("old", rs.getString(7)); m.put("new", rs.getString(8));
                out.add(m);
            }
        }
        return out;
    }

    /** All changes for one subject in one transaction, each written to the audit table. */
    private int save(String type, String subject, Map<String, String> wanted, String by) throws SQLException {
        try (Connection c = InventoryDB.getAuthConnection()) {
            boolean auto = c.getAutoCommit();
            c.setAutoCommit(false);
            try {
                Set<String> known = new HashSet<>();
                try (PreparedStatement ps = c.prepareStatement("SELECT perm_key FROM access_permission");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) known.add(rs.getString(1));
                }
                int n = 0;
                try (PreparedStatement get = c.prepareStatement("SELECT effect FROM access_grant WHERE perm_key=? AND "
                        + "subject_type=? AND subject=? FOR UPDATE");
                     PreparedStatement del = c.prepareStatement("DELETE FROM access_grant WHERE perm_key=? AND subject_type=? AND subject=?");
                     PreparedStatement put = c.prepareStatement("INSERT INTO access_grant (perm_key, subject_type, subject, effect, "
                             + "granted_by) VALUES (?,?,?,?,?) ON DUPLICATE KEY UPDATE effect=VALUES(effect), "
                             + "granted_by=VALUES(granted_by), granted_at=CURRENT_TIMESTAMP");
                     PreparedStatement log = c.prepareStatement("INSERT INTO access_grant_audit (perm_key, subject_type, subject, "
                             + "old_effect, new_effect, changed_by) VALUES (?,?,?,?,?,?)")) {
                    for (Map.Entry<String, String> e : wanted.entrySet()) {
                        String key = e.getKey(), effect = e.getValue();
                        if (!known.contains(key)) throw new IllegalArgumentException("Unknown page or button: " + key);
                        String old = null;
                        get.setString(1, key); get.setString(2, type); get.setString(3, subject);
                        try (ResultSet rs = get.executeQuery()) { if (rs.next()) old = rs.getString(1); }
                        if (old == null ? effect == null : old.equals(effect)) continue;
                        if (effect == null) {
                            del.setString(1, key); del.setString(2, type); del.setString(3, subject); del.executeUpdate();
                        } else {
                            put.setString(1, key); put.setString(2, type); put.setString(3, subject); put.setString(4, effect);
                            put.setString(5, by); put.executeUpdate();
                        }
                        log.setString(1, key); log.setString(2, type); log.setString(3, subject); log.setString(4, old);
                        log.setString(5, effect); log.setString(6, by); log.executeUpdate();
                        n++;
                    }
                }
                c.commit();
                return n;
            } catch (SQLException | RuntimeException ex) {
                c.rollback();
                throw ex;
            } finally {
                c.setAutoCommit(auto);
            }
        }
    }

    // ------------------------------------------------------------------ helpers

    static boolean isGlobal(HttpSession s) {
        Object r = s.getAttribute("role");
        return r != null && "Global".equalsIgnoreCase(String.valueOf(r).trim());
    }

    private static boolean signedIn(HttpSession s) { return s != null && s.getAttribute("username") != null; }

    private static String text(JsonObject o, String name) {
        JsonElement e = o.get(name);
        return e == null || e.isJsonNull() || !e.isJsonPrimitive() ? null : e.getAsString().trim();
    }

    private static String read(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        req.setCharacterEncoding("UTF-8");
        try (BufferedReader r = req.getReader()) {
            char[] buf = new char[4096];
            int n;
            while ((n = r.read(buf)) > 0) {
                sb.append(buf, 0, n);
                if (sb.length() > MAX_BODY) throw new IllegalArgumentException("too large");
            }
        }
        return sb.toString();
    }

    private void json(HttpServletResponse resp, Object o) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        resp.getWriter().write(gson.toJson(o));
    }

    private void error(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("error", message);
        json(resp, m);
    }
}
