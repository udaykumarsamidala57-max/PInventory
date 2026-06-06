package com.Service;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil5;

@WebServlet("/RequestBookingServlet")
public class RequestBookingServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

 

    @Override
    public void init() throws ServletException {
       
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        if (action != null && action.equals("loadComplaintTypes")) {
            loadComplaintTypes(request, response);
        } else {
            loadDepartments(request, response);
        }
    }

    private void loadDepartments(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        ArrayList<HashMap<String, Object>> list = new ArrayList<HashMap<String, Object>>();
        String sql = "SELECT * FROM departments ORDER BY department_name";

        // Connection is requested and closed automatically here
        try (Connection con = DBUtil5.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                HashMap<String, Object> map = new HashMap<String, Object>();
                map.put("id", rs.getInt("id"));
                map.put("department_name", rs.getString("department_name"));
                list.add(map);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        request.setAttribute("departments", list);
        request.getRequestDispatcher("/Service/request_booking.jsp").forward(request, response);
    }

    private void loadComplaintTypes(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();

        String deptId = request.getParameter("department_id");
        if (deptId == null || deptId.equals("")) {
            out.println("<option value=''>Select Complaint Type</option>");
            return;
        }

        int departmentId = Integer.parseInt(deptId);
        String sql = "SELECT * FROM complaint_types WHERE department_id=? ORDER BY complaint_name";

        // Connection is requested and closed automatically here
        try (Connection con = DBUtil5.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, departmentId);
            try (ResultSet rs = ps.executeQuery()) {
                out.println("<option value=''>Select Complaint Type</option>");
                while (rs.next()) {
                    out.println("<option value='" + rs.getInt("id") + "'>" 
                                + rs.getString("complaint_name") + "</option>");
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            out.println("<option value=''>Unable To Load</option>");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("username") == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }

            String requestedBy = ((String) session.getAttribute("username")).toUpperCase();
            int departmentId = Integer.parseInt(request.getParameter("department_id"));
            int complaintTypeId = Integer.parseInt(request.getParameter("complaint_type_id"));
            String location = request.getParameter("location");
            String description = request.getParameter("description");
            String priority = request.getParameter("priority");

            String year = new SimpleDateFormat("yyyy").format(new Date());
            String countSql = "SELECT COUNT(*) AS total FROM service_requests WHERE YEAR(request_date)=YEAR(NOW())";
            int nextNo = 1;

            // Connection is requested and closed automatically here
            try (Connection con = DBUtil5.getConnection();
                 PreparedStatement countPs = con.prepareStatement(countSql);
                 ResultSet countRs = countPs.executeQuery()) {

                if (countRs.next()) {
                    nextNo = countRs.getInt("total") + 1;
                }
                
                String serialNo = String.format("%03d", nextNo);
                String requestNo = "SR/" + year + "/" + serialNo;

                String insertSql = "INSERT INTO service_requests(request_no, request_date, requested_by, "
                        + "department_id, complaint_type_id, location, description, priority, assigned_to, status) "
                        + "VALUES(?, NOW(), ?, ?, ?, ?, ?, ?, ?, ?)";

                try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                    ps.setString(1, requestNo);
                    ps.setString(2, requestedBy);
                    ps.setInt(3, departmentId);
                    ps.setInt(4, complaintTypeId);
                    ps.setString(5, location);
                    ps.setString(6, description);
                    ps.setString(7, priority);
                    ps.setNull(8, java.sql.Types.INTEGER);
                    ps.setString(9, "OPEN");

                    int i = ps.executeUpdate();

                    if (i > 0) {
                        session.setAttribute("msg", "Service Request Submitted Successfully : " + requestNo);
                    } else {
                        session.setAttribute("msg", "Failed To Submit Request");
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("msg", "Error : " + e.getMessage());
        }

        response.sendRedirect(request.getContextPath() + "/RequestBookingServlet");
    }

    @Override
    public void destroy() {
        // REMOVED: Clean up handled locally inside methods now
    }
}