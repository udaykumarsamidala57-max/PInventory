package com.controller.Admissions;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.*;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.bean.DBUtil3;

@WebServlet("/SaveMarksServlet")
public class SaveMarksServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {

        String examDate = request.getParameter("exam_date_hidden");

        Connection con = null;
        PreparedStatement psUpsertMarks = null;
        PreparedStatement psUpdateStudent = null;

        try {
            con = DBUtil3.getConnection();
            con.setAutoCommit(false);

            /* ================= UPSERT MARKS ================= */
            psUpsertMarks = con.prepareStatement(
                "INSERT INTO student_exam_marks(enquiry_id, exam_id, exam_date, marks_obtained) " +
                "VALUES(?,?,?,?) " +
                "ON DUPLICATE KEY UPDATE marks_obtained=VALUES(marks_obtained)"
            );

            /* ================= UPDATE STUDENT TABLE ================= */
            psUpdateStudent = con.prepareStatement(
                "UPDATE admission_enquiry SET exam_date=?, entrance_remarks=? WHERE enquiry_id=?"
            );

            Set<Integer> studentIds = new HashSet<>();

            Enumeration<String> params = request.getParameterNames();
            while (params.hasMoreElements()) {
                String param = params.nextElement();

                if (param.startsWith("marks_")) {
                    String[] parts = param.split("_");

                    int enquiryId = Integer.parseInt(parts[1]);
                    int examId = Integer.parseInt(parts[2]);

                    int marks = 0;
                    try {
                        marks = Integer.parseInt(request.getParameter(param));
                    } catch (Exception e) {}

                    psUpsertMarks.setInt(1, enquiryId);
                    psUpsertMarks.setInt(2, examId);
                    psUpsertMarks.setString(3, examDate);
                    psUpsertMarks.setInt(4, marks);
                    psUpsertMarks.addBatch();

                    studentIds.add(enquiryId);
                }
            }

            psUpsertMarks.executeBatch();

            /* ================= SAVE DATE + REMARKS ================= */
            for (int enquiryId : studentIds) {

                String remarks = request.getParameter("remarks_" + enquiryId);
                if (remarks == null) remarks = "";

                psUpdateStudent.setString(1, examDate);
                psUpdateStudent.setString(2, remarks);
                psUpdateStudent.setInt(3, enquiryId);
                psUpdateStudent.addBatch();
            }

            psUpdateStudent.executeBatch();

            con.commit();
            response.sendRedirect("enter_marks.jsp?msg=success");

        } catch (Exception e) {
            try { if (con != null) con.rollback(); } catch (Exception ex) {}
            e.printStackTrace();
            response.sendRedirect("Admissions/enter_marks.jsp?msg=error");

        } finally {
            try { if (psUpsertMarks != null) psUpsertMarks.close(); } catch (Exception e) {}
            try { if (psUpdateStudent != null) psUpdateStudent.close(); } catch (Exception e) {}
            try { if (con != null) con.close(); } catch (Exception e) {}
        }
    }
}
