package com.controller.Admissions;


import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.bean.DBUtil3;

@WebServlet("/SaveEnquiryServlet")
public class SaveEnquiryServlet extends HttpServlet {

    // =======================
    // ✅ AJAX MOBILE CHECK
    // =======================
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String mobile = request.getParameter("mobile");

        response.setContentType("text/plain");
        PrintWriter out = response.getWriter();

        if (mobile == null || mobile.trim().isEmpty()) {
            out.print("0");
            return;
        }

        int count = 0;

        try (Connection con = DBUtil3.getConnection()) {

            String sql = "SELECT COUNT(*) FROM admission_enquiry WHERE father_mobile_no = ? OR mother_mobile_no = ?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, mobile);
            ps.setString(2, mobile);

            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                count = rs.getInt(1);
            }

        } catch (Exception e) {
            e.printStackTrace();
            out.print("0");
            return;
        }

        if (count >= 2) {
            out.print("BLOCK");
        } else {
            out.print(count); // 0 or 1
        }
    }

    // =======================
    // ✅ FORM SUBMIT
    // =======================
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Read form data
        String studentName = request.getParameter("student_name");
        String gender = request.getParameter("gender");
        String dob = request.getParameter("date_of_birth");
        String classOfAdmission = request.getParameter("class_of_admission");
        String admissionType = request.getParameter("admission_type");

        String fatherName = request.getParameter("father_name");
        String fatherOccupation = request.getParameter("father_occupation");
        String fatherOrganization = request.getParameter("father_organization");
        String fatherMobile = request.getParameter("father_mobile_no");

        String motherName = request.getParameter("mother_name");
        String motherOccupation = request.getParameter("mother_occupation");
        String motherOrganization = request.getParameter("mother_organization");
        String motherMobile = request.getParameter("mother_mobile_no");

        String segment = request.getParameter("segment");
        String placeFrom = request.getParameter("place_from");

        if (segment == null) segment = "";

        Connection con = null;
        PreparedStatement ps = null;

        try {
            // 2. Get DB connection
            con = DBUtil3.getConnection();

            // ===============================
            // 🛡️ SERVER-SIDE MOBILE LIMIT CHECK
            // ===============================
            String checkSql = "SELECT COUNT(*) FROM admission_enquiry WHERE father_mobile_no = ? OR mother_mobile_no = ?";
            PreparedStatement checkPs = con.prepareStatement(checkSql);
            checkPs.setString(1, fatherMobile);
            checkPs.setString(2, fatherMobile);

            ResultSet rs = checkPs.executeQuery();
            int count = 0;
            if (rs.next()) {
                count = rs.getInt(1);
            }

            if (count >= 2) {
                response.setContentType("text/html;charset=UTF-8");
                PrintWriter out = response.getWriter();
                out.println("<script>");
                out.println("alert('❌ This mobile number already used 2 times. Further submissions are blocked!');");
                out.println("window.history.back();");
                out.println("</script>");
                return; // ⛔ STOP INSERT
            }

            // ===============================
            // ✅ INSERT DATA
            // ===============================
            String sql = "INSERT INTO admission_enquiry ("
                    + "student_name, gender, date_of_birth, class_of_admission, admission_type, "
                    + "father_name, father_occupation, father_organization, father_mobile_no, "
                    + "mother_name, mother_occupation, mother_organization, mother_mobile_no, "
                    + "segment, place_from"
                    + ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

            ps = con.prepareStatement(sql);

            ps.setString(1, studentName);
            ps.setString(2, gender);
            ps.setString(3, dob);
            ps.setString(4, classOfAdmission);
            ps.setString(5, admissionType);

            ps.setString(6, fatherName);
            ps.setString(7, fatherOccupation);
            ps.setString(8, fatherOrganization);
            ps.setString(9, fatherMobile);

            ps.setString(10, motherName);
            ps.setString(11, motherOccupation);
            ps.setString(12, motherOrganization);
            ps.setString(13, motherMobile);

            ps.setString(14, segment);
            ps.setString(15, placeFrom);

            int result = ps.executeUpdate();

            if (result > 0) {
                response.sendRedirect("enquiry_success.jsp");
            } else {
                response.setContentType("text/html;charset=UTF-8");
                PrintWriter out = response.getWriter();
                out.println("<script>");
                out.println("alert('❌ Failed to submit enquiry. Please try again!');");
                out.println("window.history.back();");
                out.println("</script>");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("text/html;charset=UTF-8");
            PrintWriter out = response.getWriter();
            out.println("<script>");
            out.println("alert('❌ Server error! Please try again later.');");
            out.println("window.history.back();");
            out.println("</script>");

        } finally {
            try {
                if (ps != null) ps.close();
                if (con != null) con.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
