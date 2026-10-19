package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

/**
 * Events master: add, edit and switch events Active / Inactive.
 * Table `events` lives in each store's inventory database and is created automatically if missing,
 * together with the `indent.event_id` column used to tag Issue indents with an event.
 * Access: Global / Admin role or Finance department.
 */
@WebServlet("/EventsServlet")
public class EventsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final String CREATE_SQL =
        "CREATE TABLE IF NOT EXISTS `events` (" +
        " `event_id` int NOT NULL AUTO_INCREMENT," +
        " `event_name` varchar(150) NOT NULL," +
        " `event_date` date DEFAULT NULL," +
        " `description` varchar(500) DEFAULT NULL," +
        " `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active'," +
        " `created_by` varchar(50) DEFAULT NULL," +
        " `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP," +
        " `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
        " PRIMARY KEY (`event_id`)," +
        " UNIQUE KEY `uq_events_name` (`event_name`)," +
        " KEY `idx_events_status` (`status`)" +
        ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

    /** Branches whose table has already been checked in this run of the app. */
    private static final Set<String> READY = Collections.synchronizedSet(new HashSet<>());

    // ============================================================ GET: list + form
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession sess = request.getSession(false);
        if (!allowed(sess, response)) return;
        String branch = (String) sess.getAttribute("branch");
        String filter = trim(request.getParameter("show"));          // "", "Active", "Inactive"

        List<Map<String, Object>> events = new ArrayList<>();
        int active = 0, inactive = 0;
        try (Connection con = connect(branch)) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT event_id, event_name, event_date, description, status, created_by, created_at " +
                    "FROM events ORDER BY (status = 'Active') DESC, COALESCE(event_date, DATE(created_at)) DESC, event_name");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String st = rs.getString("status");
                    if ("Active".equals(st)) active++; else inactive++;
                    if (!filter.isEmpty() && !filter.equalsIgnoreCase(st)) continue;
                    Map<String, Object> e = new HashMap<>();
                    e.put("id", rs.getInt("event_id"));
                    e.put("name", rs.getString("event_name"));
                    e.put("date", rs.getDate("event_date"));
                    e.put("description", rs.getString("description"));
                    e.put("status", st);
                    e.put("createdBy", rs.getString("created_by"));
                    e.put("createdAt", rs.getTimestamp("created_at"));
                    events.add(e);
                }
            }
        } catch (SQLException e) {
            throw new ServletException("Database Error: " + e.getMessage(), e);
        }

        request.setAttribute("events", events);
        request.setAttribute("activeCount", active);
        request.setAttribute("inactiveCount", inactive);
        request.setAttribute("show", filter);
        request.getRequestDispatcher("events.jsp").forward(request, response);
    }

    // ============================================================ POST: add / update / toggle
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession sess = request.getSession(false);
        if (!allowed(sess, response)) return;
        request.setCharacterEncoding("UTF-8");

        String branch = (String) sess.getAttribute("branch");
        String user   = (String) sess.getAttribute("username");
        String action = trim(request.getParameter("action"));
        String name   = trim(request.getParameter("event_name")).replaceAll("\\s+", " ");
        String date   = trim(request.getParameter("event_date"));
        String desc   = trim(request.getParameter("description"));
        String idText = trim(request.getParameter("event_id"));

        String ok = null, err = null;
        try (Connection con = connect(branch)) {
            switch (action) {
                case "add":
                case "update": {
                    if (name.isEmpty())        throw new IllegalArgumentException("Event name is required.");
                    if (name.length() > 150)   throw new IllegalArgumentException("Event name must be 150 characters or less.");
                    if (desc.length() > 500)   throw new IllegalArgumentException("Description must be 500 characters or less.");
                    java.sql.Date d = date.isEmpty() ? null : java.sql.Date.valueOf(date);   // yyyy-MM-dd from the date field
                    boolean add = "add".equals(action);
                    try (PreparedStatement ps = con.prepareStatement(add
                            ? "INSERT INTO events (event_name, event_date, description, status, created_by) VALUES (?, ?, ?, 'Active', ?)"
                            : "UPDATE events SET event_name = ?, event_date = ?, description = ? WHERE event_id = ?")) {
                        ps.setString(1, name);
                        ps.setDate(2, d);
                        ps.setString(3, desc.isEmpty() ? null : desc);
                        if (add) ps.setString(4, user); else ps.setInt(4, Integer.parseInt(idText));
                        if (ps.executeUpdate() != 1) throw new IllegalArgumentException("Event not found.");
                    }
                    ok = add ? "Event \"" + name + "\" added." : "Event \"" + name + "\" updated.";
                    break;
                }
                case "toggle": {
                    int id = Integer.parseInt(idText);
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE events SET status = IF(status = 'Active', 'Inactive', 'Active') WHERE event_id = ?")) {
                        ps.setInt(1, id);
                        if (ps.executeUpdate() != 1) throw new IllegalArgumentException("Event not found.");
                    }
                    try (PreparedStatement ps = con.prepareStatement("SELECT event_name, status FROM events WHERE event_id = ?")) {
                        ps.setInt(1, id);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) ok = "\"" + rs.getString(1) + "\" is now " + rs.getString(2) + ".";
                        }
                    }
                    break;
                }
                default:
                    err = "Unknown action.";
            }
        } catch (SQLIntegrityConstraintViolationException e) {
            err = "An event named \"" + name + "\" already exists.";
        } catch (IllegalArgumentException e) {                 // includes NumberFormatException
            err = e.getMessage() != null && !e.getMessage().startsWith("For input") ? e.getMessage() : "Invalid input.";
        } catch (SQLException e) {
            e.printStackTrace();
            err = "Database error: " + e.getMessage();
        }

        sess.setAttribute(err == null ? "eventOk" : "eventErr", err == null ? ok : err);
        response.sendRedirect("EventsServlet");
    }

    // ============================================================ helpers

    /** Logged in, and Global / Admin role or Finance department. */
    private static boolean allowed(HttpSession sess, HttpServletResponse response) throws IOException {
        if (sess == null || sess.getAttribute("username") == null) { response.sendRedirect("login.jsp"); return false; }
        String role = trim((String) sess.getAttribute("role"));
        String dept = trim((String) sess.getAttribute("department"));
        if ("Global".equalsIgnoreCase(role) || "Admin".equalsIgnoreCase(role) || "Finance".equalsIgnoreCase(dept)) return true;
        response.sendRedirect("Home");
        return false;
    }

    /** Opens the store's database and makes sure the events schema exists. */
    private static Connection connect(String branch) throws SQLException {
        Connection con = DBUtil.getConnection(branch);
        if (con == null) throw new SQLException("Unable to connect to the database.");
        ensureSchema(con, branch);
        return con;
    }

    /**
     * Makes sure the `events` table and the `indent.event_id` column exist (checked once per branch).
     * Uses DDL, so call it BEFORE starting a transaction (DDL commits implicitly in MySQL).
     */
    public static void ensureSchema(Connection con, String branch) throws SQLException {
        String key = branch == null ? "" : branch;
        if (READY.contains(key)) return;
        try (Statement st = con.createStatement()) {
            st.execute(CREATE_SQL);
            try (ResultSet rs = st.executeQuery(
                    "SELECT COUNT(*) FROM information_schema.COLUMNS " +
                    "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'indent' AND COLUMN_NAME = 'event_id'")) {
                rs.next();
                if (rs.getInt(1) == 0) {
                    rs.close();
                    st.execute("ALTER TABLE indent ADD COLUMN event_id int DEFAULT NULL, ADD KEY idx_indent_event (event_id)");
                }
            }
        }
        READY.add(key);
    }

    /** Active events for drop-downs: list of { id, name, date } (nearest / newest first). */
    public static List<Map<String, String>> activeEvents(Connection con) throws SQLException {
        List<Map<String, String>> out = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT event_id, event_name, DATE_FORMAT(event_date, '%d %b %Y') AS d FROM events " +
                "WHERE status = 'Active' ORDER BY COALESCE(event_date, DATE(created_at)) DESC, event_name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, String> m = new HashMap<>();
                m.put("id", rs.getString("event_id"));
                m.put("name", rs.getString("event_name"));
                m.put("date", rs.getString("d") == null ? "" : rs.getString("d"));
                out.add(m);
            }
        }
        return out;
    }

    /** True if the event exists and is Active. */
    public static boolean isActiveEvent(Connection con, int eventId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT 1 FROM events WHERE event_id = ? AND status = 'Active'")) {
            ps.setInt(1, eventId);
            try (ResultSet rs = ps.executeQuery()) { return rs.next(); }
        }
    }

    private static String trim(String v) { return v == null ? "" : v.trim(); }
}
