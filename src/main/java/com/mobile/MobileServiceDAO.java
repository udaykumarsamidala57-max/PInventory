package com.mobile;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.http.HttpServletRequest;

import com.officecentral.common.db.ServiceDB;

/**
 * Service requests for the mobile app. Same tables and visibility rules as the website
 * (RequestBookingServlet, TrackRequestServlet), plus a server-side check that the user
 * may see a request before adding a follow-up.
 */
final class MobileServiceDAO {

    private static final Logger LOG = Logger.getLogger(MobileServiceDAO.class.getName());
    private static final List<String> PRIORITIES = List.of("Low", "Medium", "High", "Urgent");

    private static Connection connect(MobileApiServlet.Ctx c) {
        try {
            return ServiceDB.getConnection(c.branch);
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Service DB not available for store " + c.branch, e);
            throw new ApiException(409, "Service requests are not available for store " + c.branch + ".");
        }
    }

    // ------------------------------------------------------------------ visibility (same as TrackRequestServlet)

    private static boolean isSecretary(MobileApiServlet.Ctx c) {
        return "Global12".equalsIgnoreCase(c.role);
    }

    private static boolean isMaintenanceAdmin(MobileApiServlet.Ctx c) {
        return "Admin12".equalsIgnoreCase(c.role) || "A_Veeresh12".equalsIgnoreCase(c.username);
    }

    /** WHERE clause (without "WHERE") for the requests this user may see. */
    private static String visibleSql(MobileApiServlet.Ctx c, List<String> params) {
        if (isSecretary(c)) return "1=1";
        if (isMaintenanceAdmin(c)) {
            return "UPPER(d.department_name) IN ('ELECTRICAL','PLUMBING','HOUSEKEEPING') "
                    + "AND COALESCE(TRIM(UPPER(sr.status)),'') <> 'SATISFIED'";
        }
        params.add(c.username.toUpperCase());
        return "UPPER(sr.requested_by)=? AND COALESCE(TRIM(UPPER(sr.status)),'') NOT IN ('SATISFIED','CLOSED')";
    }

    private static final String SELECT =
            "SELECT sr.id, sr.request_no, sr.request_date, sr.requested_by, sr.location, sr.description, "
            + "sr.priority, sr.status, di.incharge_name AS assigned_name, d.department_name, c.complaint_name "
            + "FROM service_requests sr "
            + "LEFT JOIN department_incharge di ON sr.assigned_to = di.id "
            + "LEFT JOIN departments d ON sr.department_id = d.id "
            + "LEFT JOIN complaint_types c ON sr.complaint_type_id = c.id ";

    private static List<String> allowedStatuses(MobileApiServlet.Ctx c, String requestedBy) {
        List<String> s = new ArrayList<>(List.of("OPEN", "IN PROGRESS"));
        if (c.username.equalsIgnoreCase(MobileApiServlet.trim(requestedBy))) s.add("SATISFIED");
        return s;
    }

    // ------------------------------------------------------------------ endpoints

    Map<String, Object> categories(MobileApiServlet.Ctx c) throws SQLException {
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection con = connect(c);
             PreparedStatement ps = con.prepareStatement(
                     "SELECT d.id AS dept_id, d.department_name, ct.id AS type_id, ct.complaint_name "
                     + "FROM complaint_types ct JOIN departments d ON ct.department_id = d.id "
                     + "ORDER BY d.department_name, ct.complaint_name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("deptId", rs.getInt("dept_id"));
                m.put("dept", rs.getString("department_name"));
                m.put("typeId", rs.getInt("type_id"));
                m.put("type", rs.getString("complaint_name"));
                list.add(m);
            }
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("categories", list);
        res.put("priorities", PRIORITIES);
        return res;
    }

    Map<String, Object> list(MobileApiServlet.Ctx c) throws SQLException {
        List<String> params = new ArrayList<>();
        String sql = SELECT + "WHERE " + visibleSql(c, params) + " ORDER BY sr.id DESC LIMIT 300";
        List<Map<String, Object>> rows = new ArrayList<>();
        Map<Integer, Map<String, Object>> byId = new LinkedHashMap<>();
        try (Connection con = connect(c)) {
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> m = new LinkedHashMap<>();
                        int id = rs.getInt("id");
                        String by = rs.getString("requested_by");
                        m.put("id", id);
                        m.put("requestNo", rs.getString("request_no"));
                        m.put("requestDate", ts(rs.getTimestamp("request_date")));
                        m.put("requestedBy", by);
                        m.put("department", rs.getString("department_name"));
                        m.put("complaintType", rs.getString("complaint_name"));
                        m.put("location", rs.getString("location"));
                        m.put("description", rs.getString("description"));
                        m.put("priority", rs.getString("priority"));
                        m.put("status", rs.getString("status"));
                        m.put("assignedName", rs.getString("assigned_name"));
                        m.put("canUpdate", true);
                        m.put("allowedStatuses", allowedStatuses(c, by));
                        m.put("followups", new ArrayList<Map<String, Object>>());
                        rows.add(m);
                        byId.put(id, m);
                    }
                }
            }
            loadFollowups(c, con, byId);
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("requests", rows);
        return res;
    }

    @SuppressWarnings("unchecked")
    private static void loadFollowups(MobileApiServlet.Ctx c, Connection con, Map<Integer, Map<String, Object>> byId)
            throws SQLException {
        if (byId.isEmpty()) return;
        StringBuilder in = new StringBuilder();
        for (int i = 0; i < byId.size(); i++) in.append(i == 0 ? "?" : ",?");
        String sql = "SELECT request_id, remarks, status, updated_by, updated_on FROM followups WHERE request_id IN ("
                + in + ")"
                + (isSecretary(c) ? "" : " AND COALESCE(TRIM(UPPER(status)),'') <> 'SATISFIED'")
                + " ORDER BY updated_on DESC";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            int i = 1;
            for (Integer id : byId.keySet()) ps.setInt(i++, id);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> req = byId.get(rs.getInt("request_id"));
                    if (req == null) continue;
                    List<Map<String, Object>> f = (List<Map<String, Object>>) req.get("followups");
                    if (f.size() >= 200) continue;
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("remarks", rs.getString("remarks"));
                    m.put("status", rs.getString("status"));
                    m.put("updatedBy", rs.getString("updated_by"));
                    m.put("updatedOn", ts(rs.getTimestamp("updated_on")));
                    f.add(m);
                }
            }
        }
    }

    Map<String, Object> create(MobileApiServlet.Ctx c, HttpServletRequest req) throws SQLException {
        int deptId = posInt(req.getParameter("department_id"), "department");
        int typeId = posInt(req.getParameter("complaint_type_id"), "complaint type");
        String priority = MobileApiServlet.trim(req.getParameter("priority"));
        String location = text(req.getParameter("location"), "Location", 150, true);
        String subject = text(req.getParameter("subject"), "Subject", 150, false);
        String description = text(req.getParameter("description"), "Description", 1000, true);
        String match = null;
        for (String p : PRIORITIES) if (p.equalsIgnoreCase(priority)) match = p;
        if (match == null) throw new ApiException(400, "Choose a priority.");
        if (!subject.isEmpty()) description = subject + " - " + description; // same as the website

        String requestNo;
        try (Connection con = connect(c)) {
            con.setAutoCommit(false);
            try {
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT 1 FROM complaint_types WHERE id=? AND department_id=?")) {
                    ps.setInt(1, typeId);
                    ps.setInt(2, deptId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new ApiException(400, "Complaint type does not belong to that department.");
                    }
                }
                // Request number: same format as the website (SR/<year>/<serial>).
                int next = 1;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT COUNT(*) FROM service_requests WHERE YEAR(request_date)=YEAR(NOW()) FOR UPDATE");
                     ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) next = rs.getInt(1) + 1;
                }
                requestNo = "SR/" + java.time.Year.now().getValue() + "/" + String.format("%03d", next);
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO service_requests(request_no, request_date, requested_by, department_id, "
                        + "complaint_type_id, location, description, priority, assigned_to, status) "
                        + "VALUES(?, NOW(), ?, ?, ?, ?, ?, ?, ?, 'OPEN')")) {
                    ps.setString(1, requestNo);
                    ps.setString(2, c.username.toUpperCase());
                    ps.setInt(3, deptId);
                    ps.setInt(4, typeId);
                    ps.setString(5, location);
                    ps.setString(6, description);
                    ps.setString(7, match);
                    ps.setNull(8, java.sql.Types.INTEGER);
                    ps.executeUpdate();
                }
                con.commit();
            } catch (SQLException | RuntimeException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("requestNo", requestNo);
        return res;
    }

    Map<String, Object> followup(MobileApiServlet.Ctx c, int requestId, String status, String remarks) throws SQLException {
        String note = text(remarks, "Remarks", 500, true);
        String st = MobileApiServlet.trim(status).toUpperCase();

        try (Connection con = connect(c)) {
            con.setAutoCommit(false);
            try {
                // The user must be able to see this request (same rules as the list).
                List<String> params = new ArrayList<>();
                String sql = SELECT + "WHERE sr.id=? AND " + visibleSql(c, params) + " FOR UPDATE";
                String requestedBy;
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, requestId);
                    for (int i = 0; i < params.size(); i++) ps.setString(i + 2, params.get(i));
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new ApiException(404, "Request not found.");
                        requestedBy = rs.getString("requested_by");
                    }
                }
                if (!allowedStatuses(c, requestedBy).contains(st)) {
                    throw new ApiException(403, "You cannot set status " + st + " on this request.");
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO followups (request_id, remarks, status, updated_by, updated_on) VALUES (?,?,?,?,?)")) {
                    ps.setInt(1, requestId);
                    ps.setString(2, note);
                    ps.setString(3, st);
                    ps.setString(4, c.username);
                    ps.setTimestamp(5, new Timestamp(System.currentTimeMillis()));
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement("UPDATE service_requests SET status=? WHERE id=?")) {
                    ps.setString(1, st);
                    ps.setInt(2, requestId);
                    ps.executeUpdate();
                }
                con.commit();
            } catch (SQLException | RuntimeException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("message", "Status updated to " + st + ".");
        return res;
    }

    // ------------------------------------------------------------------ helpers

    private static String ts(Timestamp t) {
        return t == null ? null : new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(t);
    }

    private static int posInt(String v, String what) {
        try {
            int i = Integer.parseInt(MobileApiServlet.trim(v));
            if (i > 0) return i;
        } catch (NumberFormatException ignored) {
            // fall through
        }
        throw new ApiException(400, "Choose a " + what + ".");
    }

    private static String text(String v, String label, int max, boolean required) {
        String s = MobileApiServlet.trim(v);
        if (required && s.isEmpty()) throw new ApiException(400, "Enter " + label.toLowerCase() + ".");
        if (s.length() > max) throw new ApiException(400, label + " is too long (max " + max + " characters).");
        return s;
    }
}
