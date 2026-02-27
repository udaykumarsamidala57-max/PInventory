package com.controller.Admissions;

import com.bean.DBUtil3;
import java.io.IOException;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.WebServlet;
import javax.sql.rowset.CachedRowSet;
import javax.sql.rowset.RowSetProvider;

@WebServlet("/admission")
public class AdmissionEnquiryServlet extends HttpServlet {

    // ================= NULL SAFE HELPER =================
    private String nullIfEmpty(HttpServletRequest req, String name) {
        String v = req.getParameter(name);
        if (v == null || v.trim().isEmpty()) return null;
        return v.trim();
    }

    // ================= DATE HELPER =================
    private java.sql.Date getSqlDate(HttpServletRequest req, String name) {
        String v = req.getParameter(name);
        if (v == null || v.trim().isEmpty()) return null;
        return java.sql.Date.valueOf(v); // yyyy-MM-dd
    }

    // ============================ GET ============================
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // ================= SESSION CHECK =================
        HttpSession sess = req.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");

        if (!"Global".equalsIgnoreCase(role)
                && !"Incharge".equalsIgnoreCase(role)
                && !"Admin".equalsIgnoreCase(role)) {
            resp.setContentType("text/html");
            resp.getWriter().println("<h3 style='color:red;'>Access Denied</h3>");
            return;
        }

        String action = req.getParameter("action");

        try (Connection con = DBUtil3.getConnection()) {

            con.setAutoCommit(false); // 🔥 TRANSACTION START

            // ================= APPROVE =================
            if ("approve".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(req.getParameter("id"));

                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE admission_enquiry SET approved='Approved' " +
                        "WHERE enquiry_id=? AND (approved IS NULL OR approved <> 'Approved')")) {

                    ps.setInt(1, id);
                    ps.executeUpdate();
                }
                con.commit();
            }

            // ================= DELETE =================
            if ("delete".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(req.getParameter("id"));

                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM admission_enquiry WHERE enquiry_id=?")) {

                    ps.setInt(1, id);
                    ps.executeUpdate();
                }
                con.commit();
            }

            // ================= LIST =================
            try (Statement st = con.createStatement();
                 ResultSet rs = st.executeQuery(
                    "SELECT * FROM admission_enquiry ORDER BY enquiry_id DESC")) {

                CachedRowSet list = RowSetProvider.newFactory().createCachedRowSet();
                list.populate(rs);
                req.setAttribute("list", list);
            }

            // ================= FORWARD =================
            req.getRequestDispatcher("admission_enquirys.jsp").forward(req, resp);

        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    // ============================ POST ============================
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        System.out.println("==== Admission POST Called ====");
        req.getParameterMap().forEach((k,v) ->
            System.out.println(k + " = " + java.util.Arrays.toString(v))
        );

        String id = req.getParameter("enquiry_id");

        String student = req.getParameter("student_name");
        if (student == null || student.trim().isEmpty()) {
            resp.sendError(400, "Student name required");
            return;
        }

        boolean isInsert = (id == null || id.trim().isEmpty());

        try (Connection con = DBUtil3.getConnection()) {

            con.setAutoCommit(false);  // 🔥 VERY IMPORTANT

            String sql;

            if (isInsert) {
                sql =
                    "INSERT INTO admission_enquiry " +
                    "(student_name, gender, date_of_birth, class_of_admission, admission_type, " +
                    "father_name, father_occupation, father_organization, father_mobile_no, " +
                    "mother_name, mother_occupation, mother_organization, mother_mobile_no, " +
                    "place_from, segment, exam_date, general_remarks, entrance_remarks, application_no) " +
                    "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
            } else {
                sql =
                    "UPDATE admission_enquiry SET " +
                    "student_name=?, gender=?, date_of_birth=?, class_of_admission=?, admission_type=?, " +
                    "father_name=?, father_occupation=?, father_organization=?, father_mobile_no=?, " +
                    "mother_name=?, mother_occupation=?, mother_organization=?, mother_mobile_no=?, " +
                    "place_from=?, segment=?, exam_date=?, general_remarks=?, entrance_remarks=?, application_no=? " +
                    "WHERE enquiry_id=?";
            }

            try (PreparedStatement ps = con.prepareStatement(sql)) {

                int i = 1;

                ps.setString(i++, nullIfEmpty(req,"student_name"));
                ps.setString(i++, nullIfEmpty(req,"gender"));

                java.sql.Date dob = getSqlDate(req,"date_of_birth");
                if(dob == null) ps.setNull(i++, Types.DATE);
                else ps.setDate(i++, dob);

                ps.setString(i++, nullIfEmpty(req,"class_of_admission"));
                ps.setString(i++, nullIfEmpty(req,"admission_type"));
                ps.setString(i++, nullIfEmpty(req,"father_name"));
                ps.setString(i++, nullIfEmpty(req,"father_occupation"));
                ps.setString(i++, nullIfEmpty(req,"father_organization"));
                ps.setString(i++, nullIfEmpty(req,"father_mobile_no"));
                ps.setString(i++, nullIfEmpty(req,"mother_name"));
                ps.setString(i++, nullIfEmpty(req,"mother_occupation"));
                ps.setString(i++, nullIfEmpty(req,"mother_organization"));
                ps.setString(i++, nullIfEmpty(req,"mother_mobile_no"));
                ps.setString(i++, nullIfEmpty(req,"place_from"));
                ps.setString(i++, nullIfEmpty(req,"segment"));
                ps.setString(i++, nullIfEmpty(req,"exam_date"));   // VARCHAR in DB
                ps.setString(i++, nullIfEmpty(req,"general_remarks"));
                ps.setString(i++, nullIfEmpty(req,"entrance_remarks"));
                ps.setString(i++, nullIfEmpty(req,"application_no"));

                if (!isInsert) {
                    ps.setInt(i++, Integer.parseInt(id));
                }

                int rows = ps.executeUpdate();
                System.out.println("DB rows affected = " + rows);

                con.commit();   // ✅ 🔥 THIS WAS YOUR MISSING PIECE
                System.out.println("=== COMMIT DONE ===");
            }

            resp.setContentType("text/plain");
            resp.getWriter().print("OK");

        } catch (Exception e) {
            e.printStackTrace();
            resp.sendError(500, e.getMessage());
        }
    }
}
