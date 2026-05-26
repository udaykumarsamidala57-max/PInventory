package com.Service;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.HashMap;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil5;

@WebServlet("/Assign_ServiceRequestServlet")
public class Assign_ServiceRequestServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        ArrayList<HashMap<String,Object>> requestList =
        new ArrayList<HashMap<String,Object>>();

        Connection con = null;

        try {
            con = DBUtil5.getConnection();

            String sql =
            "SELECT sr.*, di.incharge_name AS assigned_name " +
            "FROM service_requests sr " +
            "LEFT JOIN department_incharge di " +
            "ON sr.assigned_to = di.id " +
            "WHERE COALESCE(TRIM(UPPER(sr.status)),'') <> 'CLOSED' " +
            "ORDER BY sr.id DESC";

            PreparedStatement ps = con.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();

            while(rs.next()) {
                HashMap<String,Object> map = new HashMap<String,Object>();
                int requestId = rs.getInt("id");

                map.put("id", requestId);
                map.put("request_no", rs.getString("request_no"));
                map.put("request_date", rs.getString("request_date"));
                map.put("requested_by", rs.getString("requested_by"));
                map.put("location", rs.getString("location"));
                map.put("description", rs.getString("description"));
                map.put("priority", rs.getString("priority"));
                map.put("status", rs.getString("status"));
                map.put("department_id", rs.getInt("department_id"));
                map.put("assigned_name", rs.getString("assigned_name"));

                /*
                 * INCHARGE LIST
                 */
                ArrayList<HashMap<String,Object>> inchargeList = new ArrayList<HashMap<String,Object>>();
                PreparedStatement ps2 = con.prepareStatement(
                    "SELECT * FROM department_incharge " +
                    "WHERE department_id=? " +
                    "AND status='ACTIVE'"
                );
                ps2.setInt(1, rs.getInt("department_id"));
                ResultSet rs2 = ps2.executeQuery();

                while(rs2.next()) {
                    HashMap<String,Object> inc = new HashMap<String,Object>();
                    inc.put("id", rs2.getInt("id"));
                    inc.put("incharge_name", rs2.getString("incharge_name"));
                    inc.put("designation", rs2.getString("designation"));
                    inchargeList.add(inc);
                }
                rs2.close();
                ps2.close();
                map.put("inchargeList", inchargeList);

                /*
                 * FOLLOWUP LIST
                 */
                ArrayList<HashMap<String,Object>> followupList = new ArrayList<HashMap<String,Object>>();
                PreparedStatement ps3 = con.prepareStatement(
                    "SELECT * FROM followups " +
                    "WHERE request_id=? " +
                    "ORDER BY updated_on DESC " +
                    "LIMIT 50"
                );
                ps3.setInt(1, requestId);
                ResultSet rs3 = ps3.executeQuery();

                while(rs3.next()) {
                    HashMap<String,Object> f = new HashMap<String,Object>();
                    f.put("remarks", rs3.getString("remarks"));
                    f.put("status", rs3.getString("status"));
                    f.put("updated_by", rs3.getString("updated_by"));

                    Timestamp ts = rs3.getTimestamp("updated_on");
                    String formattedDate = "";
                    if(ts != null){
                        formattedDate = new SimpleDateFormat("dd MMM yyyy hh:mm a").format(ts);
                    }
                    f.put("updated_on", formattedDate);
                    followupList.add(f);
                }
                rs3.close();
                ps3.close();
                map.put("followupList", followupList);

                requestList.add(map);
            }
            rs.close();
            ps.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        request.setAttribute("requestList", requestList);
        RequestDispatcher rd = request.getRequestDispatcher("/Service/AssignService.jsp");
        rd.forward(request, response);
    }

    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Connection con = null;
        HttpSession session = request.getSession(false);
        String userSessionName = (session != null && session.getAttribute("username") != null) 
                ? (String) session.getAttribute("username") : "SYSTEM";

        try {
            int requestId = Integer.parseInt(request.getParameter("request_id"));
            String actionType = request.getParameter("action_type");
            con = DBUtil5.getConnection();
            con.setAutoCommit(false); // Enable transactional integrity

            int updatedRows = 0;

            if ("ASSIGN".equalsIgnoreCase(actionType)) {
                int assignedTo = Integer.parseInt(request.getParameter("assigned_to"));

                // 1. Update Core Service Request Status
                String updateSql = "UPDATE service_requests SET assigned_to=?, status='ASSIGNED' WHERE id=?";
                PreparedStatement ps = con.prepareStatement(updateSql);
                ps.setInt(1, assignedTo);
                ps.setInt(2, requestId);
                updatedRows = ps.executeUpdate();
                ps.close();

                // 2. Fetch Assigned Name for Audit Logging Details
                String nameSql = "SELECT incharge_name FROM department_incharge WHERE id=?";
                PreparedStatement psName = con.prepareStatement(nameSql);
                psName.setInt(1, assignedTo);
                ResultSet rsName = psName.executeQuery();
                String staffName = rsName.next() ? rsName.getString("incharge_name") : "Staff ID: " + assignedTo;
                rsName.close();
                psName.close();

                // 3. Write System Follow-up Record entry
                if (updatedRows > 0) {
                    String logSql = "INSERT INTO followups (request_id, remarks, status, updated_by, updated_on) VALUES (?, ?, 'ASSIGNED', ?, NOW())";
                    PreparedStatement psLog = con.prepareStatement(logSql);
                    psLog.setInt(1, requestId);
                    psLog.setString(2, "Ticket assigned to " + staffName);
                    psLog.setString(3, userSessionName);
                    psLog.executeUpdate();
                    psLog.close();
                }

            } else if ("CLOSE".equalsIgnoreCase(actionType)) {
                String resolution = request.getParameter("resolution");

                // 1. Complete Core Data Updates
                String closeSql = "UPDATE service_requests SET status='CLOSED', resolution=?, closed_date=NOW() WHERE id=?";
                PreparedStatement ps = con.prepareStatement(closeSql);
                ps.setString(1, resolution);
                ps.setInt(2, requestId);
                updatedRows = ps.executeUpdate();
                ps.close();

                // 2. Write System Closure Log entry
                if (updatedRows > 0) {
                    String logSql = "INSERT INTO followups (request_id, remarks, status, updated_by, updated_on) VALUES (?, ?, 'CLOSED', ?, NOW())";
                    PreparedStatement psLog = con.prepareStatement(logSql);
                    psLog.setInt(1, requestId);
                    psLog.setString(2, "Resolution notes: " + resolution);
                    psLog.setString(3, userSessionName);
                    psLog.executeUpdate();
                    psLog.close();
                }
            }

            if (updatedRows > 0) {
                con.commit();
                response.sendRedirect(request.getContextPath() + "/Assign_ServiceRequestServlet?msg=success");
            } else {
                con.rollback();
                response.sendRedirect(request.getContextPath() + "/Assign_ServiceRequestServlet?msg=error");
            }

        } catch (Exception e) {
            e.printStackTrace();
            if (con != null) {
                try { con.rollback(); } catch (Exception ex) { ex.printStackTrace(); }
            }
            response.sendRedirect(request.getContextPath() + "/Assign_ServiceRequestServlet?msg=error");
        } finally {
            if (con != null) {
                try { con.setAutoCommit(true); } catch (Exception ex) { ex.printStackTrace(); }
            }
        }
    }
}