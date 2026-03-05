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

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
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
        } catch (Exception e) { e.printStackTrace(); }

        request.setAttribute("resumeList", resumeList);
        request.getRequestDispatcher("hr/RecruitmentDashboard.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Full SQL parameter mapping based on your DB schema
        String sql = "UPDATE candidate_recruitment SET name=?, mobile_no=?, address=?, post_applied_for=?, " +
                     "gender=?, date_of_birth=?, marital_status=?, qualification=?, specialization=?, " +
                     "percentage_marks=?, year_of_passing=?, reference_by=?, other_skills_certifications=?, " +
                     "experience=?, relevant_experience=?, total_experience=?, present_salary=?, expected_salary=?, " +
                     "remarks=?, shortlisted=?, call_status=?, demo_status=?, interview_status=?, " +
                     "interview_taken_by=?, demo_taken_by=?, remarks=? WHERE sl_no=?";

        try (Connection con = DBUtil2.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setString(1, request.getParameter("name"));
            ps.setString(2, request.getParameter("mobile_no"));
            ps.setString(3, request.getParameter("address"));
            ps.setString(4, request.getParameter("post_applied_for"));
            ps.setString(5, request.getParameter("gender"));
            ps.setString(6, request.getParameter("date_of_birth"));
            ps.setString(7, request.getParameter("marital_status"));
            ps.setString(8, request.getParameter("qualification"));
            ps.setString(9, request.getParameter("specialization"));
            ps.setString(10, request.getParameter("percentage_marks"));
            ps.setString(11, request.getParameter("year_of_passing"));
            ps.setString(12, request.getParameter("reference_by"));
            ps.setString(13, request.getParameter("other_skills_certifications"));
            ps.setString(14, request.getParameter("experience"));
            ps.setString(15, request.getParameter("relevant_experience"));
            ps.setString(16, request.getParameter("total_experience"));
            ps.setString(17, request.getParameter("present_salary"));
            ps.setString(18, request.getParameter("expected_salary"));
            ps.setString(19, request.getParameter("remarks"));
            ps.setString(20, request.getParameter("shortlisted"));
            ps.setString(21, request.getParameter("call_status"));
            ps.setString(22, request.getParameter("demo_status"));
            ps.setString(23, request.getParameter("interview_status"));
            ps.setString(24, request.getParameter("interview_taken_by"));
            ps.setString(25, request.getParameter("demo_taken_by"));
            ps.setString(26, request.getParameter("remarks"));
            ps.setInt(27, Integer.parseInt(request.getParameter("sl_no")));

            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }

        response.sendRedirect(request.getContextPath() + "/resume");
    }
}