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

    /*
     * =========================
     * GET METHOD
     * =========================
     */
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        String branch = (String) sess.getAttribute("branch");
        String role = (String) sess.getAttribute("role");
        String dept = (String) sess.getAttribute("department");

        ArrayList<HashMap<String,Object>> requestList =
            new ArrayList<HashMap<String,Object>>();

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBUtil5.getConnection(branch);

            String sql =
                "SELECT sr.*, " +
                "di.incharge_name AS assigned_name " +
                "FROM service_requests sr " +
                "LEFT JOIN department_incharge di " +
                "ON sr.assigned_to = di.id " +
                "WHERE sr.status IS NULL " +
                "OR UPPER(sr.status) <> 'CLOSED' " +
                "ORDER BY sr.id DESC";

            ps = con.prepareStatement(sql);
            rs = ps.executeQuery();

            while(rs.next()) {
                HashMap<String,Object> map = new HashMap<String,Object>();

                int requestId = rs.getInt("id");
                int departmentId = rs.getInt("department_id");

                map.put("id", requestId);
                map.put("request_no", rs.getString("request_no"));
                map.put("request_date", rs.getString("request_date"));
                map.put("requested_by", rs.getString("requested_by"));
                map.put("location", rs.getString("location"));
                map.put("description", rs.getString("description"));
                map.put("priority", rs.getString("priority"));
                map.put("status", rs.getString("status"));
                map.put("department_id", departmentId);
                map.put("assigned_name", rs.getString("assigned_name"));

                /* LOAD INCHARGE LIST */
                map.put("inchargeList", getInchargeList(branch, departmentId));

                /* LOAD FOLLOWUP LIST */
                map.put("followupList", getFollowupList(branch, requestId));

                requestList.add(map);
            }

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if(rs != null) rs.close();
                if(ps != null) ps.close();
                if(con != null) con.close();
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }

        request.setAttribute("requestList", requestList);

        RequestDispatcher rd = request.getRequestDispatcher("/Service/AssignService.jsp");
        rd.forward(request, response);
    }

    /*
     * =========================
     * LOAD INCHARGES
     * =========================
     */
    private ArrayList<HashMap<String,Object>> getInchargeList(String branch, int departmentId) {
        ArrayList<HashMap<String,Object>> list = new ArrayList<HashMap<String,Object>>();

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBUtil5.getConnection(branch);

            String sql =
                "SELECT * " +
                "FROM department_incharge " +
                "WHERE department_id=? " +
                "AND status='ACTIVE'";

            ps = con.prepareStatement(sql);
            ps.setInt(1, departmentId);

            rs = ps.executeQuery();

            while(rs.next()) {
                HashMap<String,Object> map = new HashMap<String,Object>();

                map.put("id", rs.getInt("id"));
                map.put("incharge_name", rs.getString("incharge_name"));
                map.put("designation", rs.getString("designation"));

                list.add(map);
            }

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if(rs != null) rs.close();
                if(ps != null) ps.close();
                if(con != null) con.close();
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }

        return list;
    }

    /*
     * =========================
     * LOAD FOLLOWUPS
     * =========================
     */
    private ArrayList<HashMap<String,Object>> getFollowupList(String branch, int requestId) {
        ArrayList<HashMap<String,Object>> list = new ArrayList<HashMap<String,Object>>();

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBUtil5.getConnection(branch);

            String sql =
                "SELECT * " +
                "FROM followups " +
                "WHERE request_id=? " +
                "ORDER BY updated_on DESC " +
                "LIMIT 50";

            ps = con.prepareStatement(sql);
            ps.setInt(1, requestId);

            rs = ps.executeQuery();

            while(rs.next()) {
                HashMap<String,Object> map = new HashMap<String,Object>();

                map.put("remarks", rs.getString("remarks"));
                map.put("status", rs.getString("status"));
                map.put("updated_by", rs.getString("updated_by"));

                Timestamp ts = rs.getTimestamp("updated_on");
                String formattedDate = "";

                if(ts != null){
                    formattedDate = new SimpleDateFormat("dd MMM yyyy hh:mm a").format(ts);
                }

                map.put("updated_on", formattedDate);

                list.add(map);
            }

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if(rs != null) rs.close();
                if(ps != null) ps.close();
                if(con != null) con.close();
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }

        return list;
    }

    /*
     * =========================
     * POST METHOD
     * =========================
     */
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String branch = (String) session.getAttribute("branch");
        Connection con = null;

        String userSessionName = (session.getAttribute("username") != null) 
            ? (String) session.getAttribute("username") 
            : "SYSTEM";

        try {
            int requestId = Integer.parseInt(request.getParameter("request_id"));
            String actionType = request.getParameter("action_type");

            con = DBUtil5.getConnection(branch);
            con.setAutoCommit(false);

            int updatedRows = 0;

            /*
             * ASSIGN
             */
            if("ASSIGN".equalsIgnoreCase(actionType)) {
                int assignedTo = Integer.parseInt(request.getParameter("assigned_to"));

                String updateSql =
                    "UPDATE service_requests " +
                    "SET assigned_to=?, " +
                    "status='ASSIGNED' " +
                    "WHERE id=?";

                PreparedStatement ps = con.prepareStatement(updateSql);
                ps.setInt(1, assignedTo);
                ps.setInt(2, requestId);

                updatedRows = ps.executeUpdate();
                ps.close();

                String staffName = "";
                String nameSql =
                    "SELECT incharge_name " +
                    "FROM department_incharge " +
                    "WHERE id=?";

                PreparedStatement ps2 = con.prepareStatement(nameSql);
                ps2.setInt(1, assignedTo);

                ResultSet rs = ps2.executeQuery();
                if(rs.next()){
                    staffName = rs.getString("incharge_name");
                }

                rs.close();
                ps2.close();

                if(updatedRows > 0){
                    insertFollowup(
                        con,
                        requestId,
                        "Ticket assigned to " + staffName,
                        "ASSIGNED",
                        userSessionName
                    );
                }
            }

            /*
             * FOLLOWUP
             */
            else if("FOLLOWUP".equalsIgnoreCase(actionType)) {
                String followupStatus = request.getParameter("followup_status");
                String followupRemarks = request.getParameter("followup_remarks");

                String updateSql =
                    "UPDATE service_requests " +
                    "SET status=? " +
                    "WHERE id=?";

                PreparedStatement ps = con.prepareStatement(updateSql);
                ps.setString(1, followupStatus);
                ps.setInt(2, requestId);

                updatedRows = ps.executeUpdate();
                ps.close();

                if(updatedRows > 0){
                    insertFollowup(
                        con,
                        requestId,
                        followupRemarks,
                        followupStatus,
                        userSessionName
                    );
                }
            }

            /*
             * CLOSE
             */
            else if("CLOSE".equalsIgnoreCase(actionType)) {
                String resolution = request.getParameter("resolution");

                String closeSql =
                    "UPDATE service_requests " +
                    "SET status='CLOSED', " +
                    "resolution=?, " +
                    "closed_date=NOW() " +
                    "WHERE id=?";

                PreparedStatement ps = con.prepareStatement(closeSql);
                ps.setString(1, resolution);
                ps.setInt(2, requestId);

                updatedRows = ps.executeUpdate();
                ps.close();

                if(updatedRows > 0){
                    insertFollowup(
                        con,
                        requestId,
                        "Resolution notes : " + resolution,
                        "CLOSED",
                        userSessionName
                    );
                }
            }

            /*
             * COMMIT
             */
            if(updatedRows > 0){
                con.commit();
                response.sendRedirect(
                    request.getContextPath()
                    + "/Assign_ServiceRequestServlet?msg=success"
                );
            } else {
                con.rollback();
                response.sendRedirect(
                    request.getContextPath()
                    + "/Assign_ServiceRequestServlet?msg=error"
                );
            }

        } catch (Exception e) {
            e.printStackTrace();
            try {
                if(con != null){
                    con.rollback();
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            response.sendRedirect(
                request.getContextPath()
                + "/Assign_ServiceRequestServlet?msg=error"
            );

        } finally {
            try {
                if(con != null){
                    con.setAutoCommit(true);
                    con.close();
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }
    }

    /*
     * =========================
     * INSERT FOLLOWUP
     * =========================
     */
    private void insertFollowup(
            Connection con,
            int requestId,
            String remarks,
            String status,
            String updatedBy) throws Exception {

        String sql =
            "INSERT INTO followups(" +
            "request_id," +
            "remarks," +
            "status," +
            "updated_by," +
            "updated_on" +
            ") VALUES (?,?,?,?,NOW())";

        PreparedStatement ps = con.prepareStatement(sql);

        ps.setInt(1, requestId);
        ps.setString(2, remarks);
        ps.setString(3, status);
        ps.setString(4, updatedBy);

        ps.executeUpdate();
        ps.close();
    }
}