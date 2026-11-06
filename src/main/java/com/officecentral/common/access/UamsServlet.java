package com.officecentral.common.access;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

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
import com.officecentral.common.web.Csrf;

/**
 * UAMS - Unified Access Management System (Global users only; fixed in code so nobody can lock Global out).
 *
 *   GET  /uams                          the UAMS screen (dashboard, users, roles, catalogue, migration, audit)
 *   GET  /uams/api/dashboard | users | roles | role-permissions?role= | catalogue | migration | audit
 *   POST /uams/api/user-roles           {userId, roles:[...]}            replace a user's roles
 *   POST /uams/api/bulk-role            {role, userIds:[...], add:true}  give / remove one role for many users
 *   POST /uams/api/employee             {userId, employeeId, employeeName}
 *   POST /uams/api/role                 {key?, name, description}        create or rename a role
 *   POST /uams/api/role-delete          {key}
 *   POST /uams/api/role-permissions     {role, keys:[...]}               replace a role's permissions
 *   POST /uams/api/catalogue            {create, kind, ...}              add or edit a project/module/page/action
 *   POST /uams/api/catalogue-delete     {key}
 *   POST /uams/api/catalogue-repair     {}
 *   POST /uams/api/migration-apply      {}
 *   POST /uams/api/mode                 {mode: ROLES | LEGACY, force}
 *
 * Every POST needs the session CSRF token (header X-CSRF-Token, added by header.jsp).
 */
@WebServlet(urlPatterns = {"/uams", "/uams/*"})
public class UamsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(UamsServlet.class.getName());
    private static final int MAX_BODY = 256 * 1024;
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession s = req.getSession(false);
        if (!signedIn(s)) { resp.sendRedirect(req.getContextPath() + "/login.jsp"); return; }
        if (!AccessControlServlet.isGlobal(s)) { resp.sendError(HttpServletResponse.SC_FORBIDDEN, "UAMS is available only to Global users."); return; }
        String path = req.getPathInfo() == null ? "" : req.getPathInfo();
        if (path.isEmpty() || "/".equals(path)) {
            resp.setHeader("Cache-Control", "no-store");
            req.setAttribute("pageTitle", "Access Management (UAMS)");
            req.getRequestDispatcher("/WEB-INF/views/common/uams.jsp").forward(req, resp);
            return;
        }
        try {
            switch (path) {
                case "/api/dashboard":        json(resp, UamsService.dashboard()); break;
                case "/api/users":            json(resp, UamsService.users()); break;
                case "/api/roles":            json(resp, UamsService.roles()); break;
                case "/api/role-permissions": json(resp, UamsService.rolePermissions(req.getParameter("role"))); break;
                case "/api/catalogue":        json(resp, catalogue()); break;
                case "/api/migration":        json(resp, UamsMigration.preview()); break;
                case "/api/audit":            json(resp, UamsService.audit(200)); break;
                default:                      resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (UamsService.Refused e) {
            error(resp, 400, e.getMessage());
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "[uams] read failed: " + path, e);
            error(resp, 503, "The UAMS tables are not ready. Run src/main/resources/sql/uams.sql on the inventory database.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession s = req.getSession(false);
        if (!signedIn(s)) { error(resp, 401, "Please sign in again."); return; }
        if (!AccessControlServlet.isGlobal(s)) { error(resp, 403, "UAMS is available only to Global users."); return; }
        if (!Csrf.valid(req, s)) { error(resp, 403, "This page has expired. Please reload it and try again."); return; }
        String path = req.getPathInfo() == null ? "" : req.getPathInfo();
        String by = String.valueOf(s.getAttribute("username"));
        JsonObject b;
        try {
            JsonElement e = JsonParser.parseString(read(req));
            b = e.isJsonObject() ? e.getAsJsonObject() : new JsonObject();
        } catch (IOException e) {
            error(resp, 413, "The request is too large."); return;
        } catch (RuntimeException e) {
            error(resp, 400, "The request could not be read."); return;
        }
        try {
            Map<String, Object> out = new LinkedHashMap<>();
            switch (path) {
                case "/api/user-roles":
                    out.put("changed", UamsService.setUserRoles(integer(b, "userId"), strings(b, "roles", 200), by)); break;
                case "/api/bulk-role":
                    out.put("changed", UamsService.bulkRole(text(b, "role"), integers(b, "userIds", 1000), bool(b, "add"), by)); break;
                case "/api/employee":
                    UamsService.setEmployee(integer(b, "userId"), text(b, "employeeId"), text(b, "employeeName"), by); break;
                case "/api/role":
                    out.put("key", UamsService.saveRole(text(b, "key"), text(b, "name"), text(b, "description"), by)); break;
                case "/api/role-delete":
                    UamsService.deleteRole(text(b, "key"), by); break;
                case "/api/role-permissions":
                    out.put("changed", UamsService.setRolePermissions(text(b, "role"), strings(b, "keys", 5000), by)); break;
                case "/api/catalogue": {
                    Map<String, String> f = new LinkedHashMap<>();
                    for (String k : new String[] {"kind", "key", "app", "parent", "label", "description", "paths", "actionCode", "sort"}) {
                        f.put(k, text(b, k));
                    }
                    out.put("key", UamsService.saveCatalogue(f, bool(b, "create"), by));
                    break;
                }
                case "/api/catalogue-delete":
                    UamsService.deleteCatalogue(text(b, "key"), by); break;
                case "/api/catalogue-repair":
                    out.put("added", UamsService.repairHierarchy(by)); break;
                case "/api/migration-apply":
                    out.putAll(UamsMigration.apply(by)); break;
                case "/api/mode": {
                    String mode = text(b, "mode");
                    if (AccessControl.MODE_ROLES.equals(mode) && !bool(b, "force")) {
                        Map<String, Object> d = UamsService.dashboard();
                        long without = ((Number) d.get("usersWithoutRoles")).longValue();
                        if (without > 0) {
                            Map<String, Object> warn = new LinkedHashMap<>();
                            warn.put("message", without + " non-Global user(s) have no UAMS role and will lose access to every page in all projects.");
                            warn.put("needsConfirm", true);
                            json(resp, 409, warn);
                            return;
                        }
                    }
                    UamsService.setMode(mode, by);
                    break;
                }
                default:
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND); return;
            }
            AccessControl.invalidate();
            out.put("ok", true);
            json(resp, out);
        } catch (UamsService.Refused e) {
            error(resp, 400, e.getMessage());
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "[uams] save failed: " + path, e);
            error(resp, 500, "Could not save. Nothing was changed. (" + safe(e.getSQLState()) + ")");
        }
    }

    private Map<String, Object> catalogue() {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("projects", UamsService.catalogue());
        out.put("actions", AccessControl.ACTION_CODES);
        out.put("mode", AccessControl.uamsMode() ? AccessControl.MODE_ROLES : AccessControl.MODE_LEGACY);
        return out;
    }

    // ------------------------------------------------------------------ request helpers

    private static boolean signedIn(HttpSession s) { return s != null && s.getAttribute("username") != null; }

    private static String read(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        char[] buf = new char[4096];
        req.setCharacterEncoding(StandardCharsets.UTF_8.name());
        try (BufferedReader r = req.getReader()) {
            int n;
            while ((n = r.read(buf)) > 0) {
                sb.append(buf, 0, n);
                if (sb.length() > MAX_BODY) throw new IOException("too large");
            }
        }
        return sb.length() == 0 ? "{}" : sb.toString();
    }

    private static String text(JsonObject o, String name) {
        JsonElement e = o.get(name);
        if (e == null || e.isJsonNull()) return null;
        if (!e.isJsonPrimitive()) throw new UamsService.Refused("The field " + name + " could not be read.");
        String v = e.getAsString();
        if (v.length() > 4000) throw new UamsService.Refused("The field " + name + " is too long.");
        return v;
    }

    private static boolean bool(JsonObject o, String name) {
        JsonElement e = o.get(name);
        return e != null && e.isJsonPrimitive() && e.getAsJsonPrimitive().isBoolean() && e.getAsBoolean();
    }

    private static int integer(JsonObject o, String name) {
        try { return o.get(name).getAsInt(); }
        catch (RuntimeException e) { throw new UamsService.Refused("Choose a valid user."); }
    }

    private static List<String> strings(JsonObject o, String name, int max) {
        List<String> out = new ArrayList<>();
        JsonElement e = o.get(name);
        if (e == null || e.isJsonNull()) return out;
        if (!e.isJsonArray()) throw new UamsService.Refused("The list " + name + " could not be read.");
        JsonArray a = e.getAsJsonArray();
        if (a.size() > max) throw new UamsService.Refused("Too many items were selected.");
        for (JsonElement i : a) {
            if (!i.isJsonPrimitive()) throw new UamsService.Refused("The list " + name + " could not be read.");
            String v = i.getAsString().trim();
            if (v.length() > 80) throw new UamsService.Refused("The list " + name + " has an invalid item.");
            out.add(v);
        }
        return out;
    }

    private static List<Integer> integers(JsonObject o, String name, int max) {
        List<Integer> out = new ArrayList<>();
        for (String v : strings(o, name, max)) {
            try { out.add(Integer.parseInt(v)); }
            catch (NumberFormatException e) { throw new UamsService.Refused("Choose valid users."); }
        }
        return out;
    }

    private static String safe(String v) { return v == null ? "-" : v.replaceAll("[^A-Za-z0-9]", ""); }

    private void json(HttpServletResponse resp, Object o) throws IOException { json(resp, 200, o); }

    private void json(HttpServletResponse resp, int status, Object o) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        resp.setHeader("X-Content-Type-Options", "nosniff");
        resp.getWriter().write(gson.toJson(o));
    }

    private void error(HttpServletResponse resp, int status, String message) throws IOException {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("message", message);
        json(resp, status, m);
    }
}
