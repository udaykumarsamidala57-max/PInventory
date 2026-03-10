package com.controller.HRA;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil2;

@WebServlet("/resume")
public class resume extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // ---------- GET : Load Dashboard ----------
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        List<Map<String, String>> resumeList = new ArrayList<>();
        String sql = "SELECT * FROM candidate_recruitment ORDER BY sl_no DESC";

        try (Connection con = DBUtil2.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            ResultSetMetaData metaData = rs.getMetaData();
            int columnCount = metaData.getColumnCount();

            while (rs.next()) {
                Map<String, String> row = new HashMap<>();
                for (int i = 1; i <= columnCount; i++) {
                    String colName = metaData.getColumnName(i);
                    String value = rs.getString(colName);
                    row.put(colName, value != null ? value : "");
                }
                resumeList.add(row);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        request.setAttribute("resumeList", resumeList);
        request.getRequestDispatcher("hr/RecruitmentDashboard.jsp").forward(request, response);
    }

    // ---------- POST : Update Candidate ----------
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // The query must strictly match the count and order of ps.setXXX calls below
        String sql = "UPDATE candidate_recruitment SET " +
                "name=?, mobile_no=?, address=?, post_applied_for=?, " +        // 1-4
                "gender=?, date_of_birth=?, marital_status=?, qualification=?, specialization=?, " + // 5-9
                "percentage_marks=?, year_of_passing=?, reference_by=?, other_skills_certifications=?, " + // 10-13
                "experience=?, relevant_experience=?, total_experience=?, " +   // 14-16
                "present_salary=?, expected_salary=?, " +                       // 17-18
                "remarks=?, shortlisted=?, call_status=?, demo_status=?, interview_status=?, " + // 19-23
                "interview_taken_by=?, demo_taken_by=?, resume_no=?, " +        // 24-26
                "attending_date=?, demo_date=?, interview_date=?, demo_remarks=?, Hired_status=? " + // 27-31
                "WHERE sl_no=?";                                                // 32

        try (Connection con = DBUtil2.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, getParam(request, "name"));
            ps.setString(2, getParam(request, "mobile_no"));
            ps.setString(3, getParam(request, "address"));
            ps.setString(4, getParam(request, "post_applied_for"));
            ps.setString(5, getParam(request, "gender"));
            ps.setString(6, getParam(request, "date_of_birth"));
            ps.setString(7, getParam(request, "marital_status"));
            ps.setString(8, getParam(request, "qualification"));
            ps.setString(9, getParam(request, "specialization"));
            ps.setString(10, getParam(request, "percentage_marks"));
            ps.setString(11, getParam(request, "year_of_passing"));
            ps.setString(12, getParam(request, "reference_by"));
            ps.setString(13, getParam(request, "other_skills_certifications"));
            ps.setString(14, getParam(request, "experience"));
            ps.setString(15, getParam(request, "relevant_experience"));
            ps.setString(16, getParam(request, "total_experience"));
            ps.setString(17, getParam(request, "present_salary"));
            ps.setString(18, getParam(request, "expected_salary"));
            ps.setString(19, getParam(request, "remarks"));
            ps.setString(20, getParam(request, "shortlisted"));
            ps.setString(21, getParam(request, "call_status"));
            ps.setString(22, getParam(request, "demo_status"));
            ps.setString(23, getParam(request, "interview_status"));
            ps.setString(24, getParam(request, "interview_taken_by"));
            ps.setString(25, getParam(request, "demo_taken_by"));
            ps.setString(26, getParam(request, "resume_no"));
            
            // For actual DATE columns in MySQL, empty strings must be set as NULL
            ps.setString(27, getParamDate(request, "attending_date"));
            ps.setString(28, getParamDate(request, "demo_date"));
            ps.setString(29, getParamDate(request, "interview_date"));
            
            ps.setString(30, getParam(request, "demo_remarks"));
            ps.setString(31, getParam(request, "Hired_status")); 

            ps.setInt(32, Integer.parseInt(request.getParameter("sl_no")));

            int rowsUpdated = ps.executeUpdate();
            if(rowsUpdated > 0) {
                System.out.println("Update Successful for sl_no: " + request.getParameter("sl_no"));
            }

        } catch (Exception e) {
            System.err.println("Error updating candidate recruitment:");
            e.printStackTrace();
        }

        response.sendRedirect(request.getContextPath() + "/resume");
    }

    // ---------- Utility Methods ----------
    
    private String getParam(HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        return (value != null) ? value.trim() : "";
    }

    /**
     * Ensures empty date strings from HTML are sent as NULL to SQL
     * to prevent "Incorrect date value" errors.
     */
    private String getParamDate(HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        if (value == null || value.trim().isEmpty()) {
            return null; 
        }
        return value.trim();
    }
}