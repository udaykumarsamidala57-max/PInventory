package com.officecentral.common.access;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
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
import com.officecentral.common.db.InventoryDB;

/**
 * Old Global-only page for assigning access roles. Replaced by UAMS (/uams): the page now redirects there and
 * saving here is refused, so roles have one place to be managed.
 */
@WebServlet(urlPatterns = {"/user-roles", "/user-roles/*"})
public class UserRoleServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(UserRoleServlet.class.getName());
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null) { resp.sendRedirect(req.getContextPath() + "/login.jsp"); return; }
        if (!AccessControlServlet.isGlobal(s)) { resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Only Global users can assign access roles."); return; }
        String path = req.getPathInfo() == null ? "" : req.getPathInfo();
        if (path.isEmpty() || "/".equals(path)) {           // replaced by UAMS > Users & Roles
            resp.sendRedirect(req.getContextPath() + "/uams#users");
            return;
        }
        try {
            if (path.isEmpty() || "/".equals(path)) {
                req.setAttribute("pageTitle", "User Role Assignments");
                req.getRequestDispatcher("/WEB-INF/views/common/user-roles.jsp").forward(req, resp);
            } else if ("/data".equals(path)) {
                json(resp, data());
            } else {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "[access] user role assignment read failed", e);
            error(resp, 503, "The role assignment tables are not ready. Run src/main/resources/sql/access_control.sql on the inventory database.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null) { error(resp, 401, "Please sign in again."); return; }
        error(resp, 410, "Role assignments are now managed in UAMS (Access Management).");
    }

    private Map<String, Object> data() throws SQLException {
        Map<String, Object> out = new LinkedHashMap<>();
        List<Map<String, Object>> roles = new ArrayList<>();
        Map<Integer, Map<String, Object>> users = new LinkedHashMap<>();
        try (Connection c = InventoryDB.getAuthConnection()) {
            try (PreparedStatement ps = c.prepareStatement("SELECT role_key, role_name FROM access_role WHERE role_key <> 'GLOBAL' ORDER BY role_name, role_key");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> role = new LinkedHashMap<>();
                    role.put("key", rs.getString(1)); role.put("name", rs.getString(2)); roles.add(role);
                }
            }
            try (PreparedStatement ps = c.prepareStatement("SELECT id, username, role, department FROM users ORDER BY username");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> user = new LinkedHashMap<>();
                    int id = rs.getInt("id"); String primary = AccessControl.normalize(rs.getString("role"));
                    user.put("id", id); user.put("username", rs.getString("username")); user.put("primary", primary);
                    user.put("department", rs.getString("department")); user.put("roles", new ArrayList<String>());
                    users.put(id, user);
                }
            }
            try (PreparedStatement ps = c.prepareStatement("SELECT ur.user_id, ur.role_key FROM access_user_role ur JOIN users u ON u.id=ur.user_id WHERE ur.role_key <> 'GLOBAL' ORDER BY ur.role_key");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    @SuppressWarnings("unchecked") List<String> assigned = (List<String>) users.get(rs.getInt(1)).get("roles");
                    if (assigned != null) assigned.add(rs.getString(2));
                }
            }
            // Ensure the legacy primary role stays visible even before the migration has seeded mappings.
            for (Map<String, Object> user : users.values()) {
                @SuppressWarnings("unchecked") List<String> assigned = (List<String>) user.get("roles");
                String primary = (String) user.get("primary");
                if (primary != null && !primary.isEmpty() && !"GLOBAL".equals(primary) && !assigned.contains(primary)) assigned.add(primary);
            }
        }
        out.put("roles", roles); out.put("users", new ArrayList<>(users.values()));
        return out;
    }



    private void json(HttpServletResponse resp, Object value) throws IOException {
        resp.setContentType("application/json;charset=UTF-8"); resp.setHeader("Cache-Control", "no-store"); resp.getWriter().write(gson.toJson(value));
    }

    private void error(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status); Map<String, Object> out = new LinkedHashMap<>(); out.put("error", message); json(resp, out);
    }
}
