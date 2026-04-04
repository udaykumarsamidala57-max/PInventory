package com.controller.HRA;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.io.IOException;
import java.io.InputStream;
import java.sql.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import com.bean.DBUtil2;

@WebServlet("/resume")
@MultipartConfig(maxFileSize = 1024 * 1024 * 10) // 10MB
public class resume extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // ================== GET ==================
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        String user = (String) sess.getAttribute("username");
        String role = (String) sess.getAttribute("role");
        if (!"Global".equalsIgnoreCase(role)&& !"karthik".equalsIgnoreCase(user)) {
            response.setContentType("text/html");
            response.getWriter().println("<h3 style='color:red;'>Access Denied</h3>");
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
        request.getRequestDispatcher("hr/RecruitmentDashboard.jsp")
               .forward(request, response);
    }

    // ================== POST ==================
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        Part filePart = request.getPart("resumeFile");
        boolean hasNewFile = (filePart != null && filePart.getSize() > 0);

        // ✅ FIXED column name
        String sql = "UPDATE candidate_recruitment SET " +
                "name=?, mobile_no=?, address=?, post_applied_for=?, " +
                "gender=?, date_of_birth=?, marital_status=?, qualification=?, specialization=?, " +
                "percentage_marks=?, year_of_passing=?, reference_by=?, other_skills_certifications=?, " +
                "experience=?, relevant_experience=?, total_experience=?, " +
                "present_salary=?, expected_salary=?, " +
                "remarks=?, shortlisted=?, call_status=?, demo_status=?, interview_status=?, " +
                "interview_taken_by=?, demo_taken_by=?, resume_no=?, " +
                "attending_date=?, demo_date=?, interview_date=?, demo_remarks=?, Hired_status=? " +
                (hasNewFile ? ", resume=? " : "") +
                "WHERE sl_no=?";

        try (Connection con = DBUtil2.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            int i = 1;

            ps.setString(i++, getParam(request, "name"));
            ps.setString(i++, getParam(request, "mobile_no"));
            ps.setString(i++, getParam(request, "address"));
            ps.setString(i++, getParam(request, "post_applied_for"));
            ps.setString(i++, getParam(request, "gender"));

            setDate(ps, i++, request, "date_of_birth");
            ps.setString(i++, getParam(request, "marital_status"));
            ps.setString(i++, getParam(request, "qualification"));
            ps.setString(i++, getParam(request, "specialization"));
            ps.setString(i++, getParam(request, "percentage_marks"));
            ps.setString(i++, getParam(request, "year_of_passing"));
            ps.setString(i++, getParam(request, "reference_by"));
            ps.setString(i++, getParam(request, "other_skills_certifications"));
            ps.setString(i++, getParam(request, "experience"));
            ps.setString(i++, getParam(request, "relevant_experience"));
            ps.setString(i++, getParam(request, "total_experience"));
            ps.setString(i++, getParam(request, "present_salary"));
            ps.setString(i++, getParam(request, "expected_salary"));
            ps.setString(i++, getParam(request, "remarks"));
            ps.setString(i++, getParam(request, "shortlisted"));
            ps.setString(i++, getParam(request, "call_status"));
            ps.setString(i++, getParam(request, "demo_status"));
            ps.setString(i++, getParam(request, "interview_status"));
            ps.setString(i++, getParam(request, "interview_taken_by"));
            ps.setString(i++, getParam(request, "demo_taken_by"));
            ps.setString(i++, getParam(request, "resume_no"));

            setDate(ps, i++, request, "attending_date");
            setDate(ps, i++, request, "demo_date");
            setDate(ps, i++, request, "interview_date");

            ps.setString(i++, getParam(request, "demo_remarks"));
            ps.setString(i++, getParam(request, "Hired_status"));

            // ✅ File handling
            if (hasNewFile) {
                InputStream inputStream = filePart.getInputStream();
                ps.setBlob(i++, inputStream);
            }

            // ✅ WHERE condition
            int slNo = Integer.parseInt(request.getParameter("sl_no"));
            ps.setInt(i++, slNo);

            ps.executeUpdate();

        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(request.getContextPath() + "/resume");
    }

    // ================== HELPERS ==================

    private String getParam(HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        return (value != null) ? value.trim() : "";
    }

    // ✅ Proper DATE handling
    private void setDate(PreparedStatement ps, int index,
                         HttpServletRequest request, String name) throws SQLException {

        String value = request.getParameter(name);

        if (value == null || value.trim().isEmpty()) {
            ps.setNull(index, Types.DATE);
        } else {
            ps.setDate(index, Date.valueOf(value));
        }
    }
}