package com.controller.Admissions;


import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.bean.DBUtil3;

@WebServlet("/LoadStudentsAndExamsServlet")
public class LoadStudentsAndExamsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {

        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();

        String classParam = request.getParameter("class_id");
        String examDate = request.getParameter("exam_date");

        if (classParam == null || classParam.isEmpty() || examDate == null || examDate.isEmpty()) {
            out.println("<p style='color:red;'>Missing class or exam date.</p>");
            return;
        }

        int classId = Integer.parseInt(classParam);
        Connection con = null;

        try {
            con = DBUtil3.getConnection();

            /* =========================
               1. LOAD EXAMS (SUBJECTS)
               ========================= */
            PreparedStatement psExams = con.prepareStatement(
                "SELECT exam_id, exam_name, IFNULL(max_marks, 100) AS max_marks " +
                "FROM class_exams WHERE class_id=?"
            );
            psExams.setInt(1, classId);
            ResultSet rsExams = psExams.executeQuery();

            ArrayList<Integer> examIds = new ArrayList<>();
            ArrayList<String> examNames = new ArrayList<>();
            ArrayList<Integer> maxMarks = new ArrayList<>();

            while (rsExams.next()) {
                examIds.add(rsExams.getInt("exam_id"));
                examNames.add(rsExams.getString("exam_name"));
                maxMarks.add(rsExams.getInt("max_marks"));
            }
            rsExams.close();
            psExams.close();

            if (examIds.isEmpty()) {
                out.println("<p style='color:orange;font-weight:bold;'>⚠️ No exams found for this class.</p>");
                return;
            }

            /* =========================
               2. LOAD EXISTING MARKS
               ========================= */
            PreparedStatement psMarks = con.prepareStatement(
                "SELECT enquiry_id, exam_id, marks_obtained " +
                "FROM student_exam_marks " +
                "WHERE REPLACE(REPLACE(exam_date,'/','-'),' ','') = ?"
            );
            psMarks.setString(1, examDate);
            ResultSet rsMarks = psMarks.executeQuery();

            HashMap<String, Integer> marksMap = new HashMap<>();
            while (rsMarks.next()) {
                String key = rsMarks.getInt("enquiry_id") + "_" + rsMarks.getInt("exam_id");
                marksMap.put(key, rsMarks.getInt("marks_obtained"));
            }
            rsMarks.close();
            psMarks.close();

            /* =========================
               3. LOAD STUDENTS
               ========================= */
            PreparedStatement psStudents = con.prepareStatement(
                "SELECT ae.enquiry_id, IFNULL(ae.application_no,'') AS application_no, " +
                "COALESCE(ae.student_name, ae.entrance_remarks) AS student_name, " +
                "ae.entrance_remarks " +
                "FROM admission_enquiry ae " +
                "JOIN classes c ON TRIM(LOWER(ae.class_of_admission)) = TRIM(LOWER(c.class_name)) " +
                "WHERE c.class_id=? " +
                "AND ae.approved='Approved' " +
                "AND REPLACE(REPLACE(ae.exam_date,'/','-'),' ','') = ?"
            );

            psStudents.setInt(1, classId);
            psStudents.setString(2, examDate);

            ResultSet rsStudents = psStudents.executeQuery();

            /* =========================
               4. GENERATE TABLE
               ========================= */
            out.println("<table class='marksTable'>");
            out.println("<thead><tr>");
            out.println("<th>S.No</th><th>Enquiry ID</th><th>App No</th><th>Student Name</th><th>Remarks</th>");

            for (int i = 0; i < examNames.size(); i++) {
                out.println("<th>" + examNames.get(i) + " (" + maxMarks.get(i) + ")</th>");
            }

            out.println("<th>Total</th>");
            out.println("</tr></thead><tbody>");

            int sno = 1;
            boolean found = false;

            while (rsStudents.next()) {
                found = true;

                int enqId = rsStudents.getInt("enquiry_id");
                String appNo = rsStudents.getString("application_no");
                String name = rsStudents.getString("student_name");
                String remarks = rsStudents.getString("entrance_remarks");

                out.println("<tr>");
                out.println("<td>" + sno++ + "</td>");
                out.println("<td>" + enqId + "</td>");
                out.println("<td>" + appNo + "</td>");
                out.println("<td style='text-align:left'>" + (name == null ? "" : name) + "</td>");
                out.println("<td><input type='text' class='remarksBox' name='remarks_" + enqId +
                            "' value='" + (remarks == null ? "" : remarks) + "'></td>");

                int total = 0;

                for (int i = 0; i < examIds.size(); i++) {
                    int examId = examIds.get(i);
                    Integer mark = marksMap.get(enqId + "_" + examId);
                    int value = (mark == null) ? 0 : mark;
                    total += value;

                    out.println("<td><input type='number' class='markInput' min='0' max='" +
                                maxMarks.get(i) + "' name='marks_" + enqId + "_" + examId +
                                "' value='" + value + "'></td>");
                }

                out.println("<td><input type='text' class='totalBox' readonly value='" + total + "'></td>");
                out.println("</tr>");
            }

            out.println("</tbody></table>");

            if (!found) {
                out.println("<div style='color:red;font-weight:bold;padding:15px;'>");
                out.println("❌ No approved students found for this class and exam date.");
                out.println("</div>");
            }

            rsStudents.close();
            psStudents.close();

        } catch (Exception e) {
            e.printStackTrace();
            out.println("<p style='color:red;'>Error: " + e.getMessage() + "</p>");
        } finally {
            try { if (con != null) con.close(); } catch (Exception e) {}
        }
    }
}
