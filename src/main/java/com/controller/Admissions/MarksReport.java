package com.controller.Admissions;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.time.Period;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.bean.DBUtil3;

@WebServlet("/MarksReport")
public class MarksReport extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final LocalDate TARGET_DATE = LocalDate.of(2026, 5, 31);

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {

        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();

        String classIdRaw = request.getParameter("class_id");
        String examDate = request.getParameter("exam_date");

        boolean isAllDates = (examDate == null || examDate.trim().isEmpty() || examDate.equalsIgnoreCase("ALL"));

        if (classIdRaw == null) {
            out.println("<p style='color:red;'>Please provide a Class ID.</p>");
            return;
        }

        try {
            int classId = Integer.parseInt(classIdRaw);
            String className = "Unknown Class"; // Placeholder

            try (Connection con = DBUtil3.getConnection()) {

                // 1. LOAD EXAMS, BASE MAX MARKS, AND CLASS NAME
                ArrayList<Integer> examIds = new ArrayList<>();
                ArrayList<String> examNames = new ArrayList<>();
                ArrayList<Integer> maxMarksArray = new ArrayList<>();
                int baseGrandTotalMax = 0;

                // Join with classes table to get the name
                String examQuery = "SELECT ce.exam_id, ce.exam_name, ce.max_marks, c.class_name " +
                                 "FROM class_exams ce " +
                                 "JOIN classes c ON ce.class_id = c.class_id " +
                                 "WHERE ce.class_id=?";
                
                try (PreparedStatement psExams = con.prepareStatement(examQuery)) {
                    psExams.setInt(1, classId);
                    try (ResultSet rsExams = psExams.executeQuery()) {
                        while (rsExams.next()) {
                            className = rsExams.getString("class_name"); // Set the class name
                            int maxM = rsExams.getInt("max_marks");
                            examIds.add(rsExams.getInt("exam_id"));
                            examNames.add(rsExams.getString("exam_name"));
                            maxMarksArray.add(maxM);
                            baseGrandTotalMax += maxM;
                        }
                    }
                }

                // Fallback if no exams found but class exists
                if (examIds.isEmpty()) {
                    String nameFallback = "SELECT class_name FROM classes WHERE class_id=?";
                    try (PreparedStatement psN = con.prepareStatement(nameFallback)) {
                        psN.setInt(1, classId);
                        try (ResultSet rsN = psN.executeQuery()) {
                            if (rsN.next()) className = rsN.getString("class_name");
                        }
                    }
                    out.println("<p style='color:red;'>No exams defined for " + className + ".</p>");
                    return;
                }

                // 2. LOAD MARKS AND CALCULATE MULTIPLIER
                HashMap<String, Integer> marksMap = new HashMap<>();
                int dateCount = 1;

                if (isAllDates) {
                    String countDatesQuery = "SELECT COUNT(DISTINCT sem.exam_date) as d_count " +
                                            "FROM student_exam_marks sem " +
                                            "JOIN admission_enquiry ae ON sem.enquiry_id = ae.enquiry_id " +
                                            "JOIN classes c ON TRIM(ae.class_of_admission) = TRIM(c.class_name) " +
                                            "WHERE c.class_id=?";
                    try (PreparedStatement psCount = con.prepareStatement(countDatesQuery)) {
                        psCount.setInt(1, classId);
                        try (ResultSet rsCount = psCount.executeQuery()) {
                            if (rsCount.next()) {
                                int found = rsCount.getInt("d_count");
                                if (found > 0) dateCount = found;
                            }
                        }
                    }

                    String marksQuery = "SELECT sem.enquiry_id, sem.exam_id, SUM(sem.marks_obtained) as marks_obtained " +
                                        "FROM student_exam_marks sem " +
                                        "JOIN admission_enquiry ae ON sem.enquiry_id = ae.enquiry_id " +
                                        "JOIN classes c ON TRIM(ae.class_of_admission) = TRIM(c.class_name) " +
                                        "WHERE c.class_id=? " +
                                        "GROUP BY sem.enquiry_id, sem.exam_id";
                    try (PreparedStatement psAllMarks = con.prepareStatement(marksQuery)) {
                        psAllMarks.setInt(1, classId);
                        try (ResultSet rsAllMarks = psAllMarks.executeQuery()) {
                            while (rsAllMarks.next()) {
                                String key = rsAllMarks.getInt("enquiry_id") + "_" + rsAllMarks.getInt("exam_id");
                                marksMap.put(key, rsAllMarks.getInt("marks_obtained"));
                            }
                        }
                    }
                } else {
                    String marksQuery = "SELECT enquiry_id, exam_id, marks_obtained FROM student_exam_marks WHERE exam_date=?";
                    try (PreparedStatement psAllMarks = con.prepareStatement(marksQuery)) {
                        psAllMarks.setString(1, examDate);
                        try (ResultSet rsAllMarks = psAllMarks.executeQuery()) {
                            while (rsAllMarks.next()) {
                                String key = rsAllMarks.getInt("enquiry_id") + "_" + rsAllMarks.getInt("exam_id");
                                marksMap.put(key, rsAllMarks.getInt("marks_obtained"));
                            }
                        }
                    }
                }

                int finalGrandTotalMax = baseGrandTotalMax * dateCount;

                // 3. LOAD STUDENTS
                ArrayList<Map<String, Object>> studentList = new ArrayList<>();
                StringBuilder studentQuery = new StringBuilder(
                    "SELECT ae.*, IFNULL(ae.application_no, '') AS app_no, " +
                    "COALESCE(ae.student_name, ae.entrance_remarks) AS s_name " +
                    "FROM admission_enquiry ae " +
                    "JOIN classes c ON TRIM(ae.class_of_admission) = TRIM(c.class_name) " +
                    "WHERE c.class_id=? AND ae.approved='Approved' "
                );

                if (!isAllDates) {
                    studentQuery.append("AND ae.exam_date=? ");
                }

                try (PreparedStatement psStudents = con.prepareStatement(studentQuery.toString())) {
                    psStudents.setInt(1, classId);
                    if (!isAllDates) {
                        psStudents.setString(2, examDate);
                    }

                    try (ResultSet rs = psStudents.executeQuery()) {
                        while (rs.next()) {
                            Map<String, Object> s = new HashMap<>();
                            int enqId = rs.getInt("enquiry_id");
                            s.put("enquiry_id", enqId);
                            s.put("app_no", rs.getString("app_no"));
                            s.put("student_name", rs.getString("s_name"));
                            s.put("dob", rs.getDate("date_of_birth"));
                            s.put("admission_type", rs.getString("admission_type"));
                            s.put("segment", rs.getString("segment"));
                            s.put("father_name", rs.getString("father_name"));
                            s.put("father_occ", rs.getString("father_occupation"));
                            s.put("father_org", rs.getString("father_organization"));
                            s.put("father_mob", rs.getString("father_mobile_no"));
                            s.put("mother_name", rs.getString("mother_name"));
                            s.put("mother_occ", rs.getString("mother_occupation"));
                            s.put("mother_org", rs.getString("mother_organization"));
                            s.put("mother_mob", rs.getString("mother_mobile_no"));
                            s.put("place", rs.getString("place_from"));
                            s.put("remarks", rs.getString("entrance_remarks"));

                            int studentTotal = 0;
                            for (int exId : examIds) {
                                Integer m = marksMap.get(enqId + "_" + exId);
                                studentTotal += (m == null) ? 0 : m;
                            }
                            
                            double perc = (finalGrandTotalMax > 0) ? ((double) studentTotal / finalGrandTotalMax) * 100 : 0;
                            
                            s.put("total_marks", studentTotal);
                            s.put("percentage", perc);
                            studentList.add(s);
                        }
                    }
                }

                // 4. SORT
                Collections.sort(studentList, (a, b) -> Double.compare((double) b.get("percentage"), (double) a.get("percentage")));

                // 5. OUTPUT TABLE - Using className instead of classId
                out.println("<h3>Report for Class: " + className + " (" + (isAllDates ? "All Dates [Aggregated x" + dateCount + "]" : "Date: " + examDate) + ")</h3>");
                out.println("<table class='marksTable' border='1' style='border-collapse:collapse; text-align:center; font-size:11px;'>");
                out.println("<thead><tr style='background:#0f2a4d; color:white;'>");
                out.println("<th>Rank</th><th>Enq ID</th><th>App No</th><th>Student Name</th><th>DOB</th><th>Age (31-May-26)</th><th>Type</th><th>Segment</th>");
                out.println("<th>Father Name</th><th>Father Occ</th><th>Father Org</th><th>Father Mob</th>");
                out.println("<th>Mother Name</th><th>Mother Occ</th><th>Mother Org</th><th>Mother Mob</th>");
                out.println("<th>Place</th><th>Remarks</th>");
                
                for (int i = 0; i < examNames.size(); i++) { 
                    int displayMax = maxMarksArray.get(i) * dateCount;
                    out.println("<th>" + examNames.get(i) + "<br>(Max: " + displayMax + ")</th>"); 
                }
                
                out.println("<th>Total Marks<br>(Max: " + finalGrandTotalMax + ")</th>");
                out.println("<th>%</th></tr></thead><tbody>");

                int rank = 1;
                for (Map<String, Object> s : studentList) {
                    java.sql.Date dob = (java.sql.Date) s.get("dob");
                    String ageStr = "N/A";
                    if (dob != null) {
                        Period p = Period.between(dob.toLocalDate(), TARGET_DATE);
                        ageStr = p.getYears() + "y " + p.getMonths() + "m " + p.getDays() + "d";
                    }

                    out.println("<tr>");
                    out.println("<td>" + (rank++) + "</td>");
                    out.println("<td>" + s.get("enquiry_id") + "</td>");
                    out.println("<td>" + s.get("app_no") + "</td>");
                    out.println("<td align='left'><b>" + s.get("student_name") + "</b></td>");
                    out.println("<td>" + (dob != null ? dob : "N/A") + "</td>");
                    out.println("<td>" + ageStr + "</td>");
                    out.println("<td>" + s.get("admission_type") + "</td>");
                    out.println("<td>" + s.get("segment") + "</td>");
                    out.println("<td>" + s.get("father_name") + "</td>");
                    out.println("<td>" + s.get("father_occ") + "</td>");
                    out.println("<td>" + s.get("father_org") + "</td>");
                    out.println("<td>" + s.get("father_mob") + "</td>");
                    out.println("<td>" + s.get("mother_name") + "</td>");
                    out.println("<td>" + s.get("mother_occ") + "</td>");
                    out.println("<td>" + s.get("mother_org") + "</td>");
                    out.println("<td>" + s.get("mother_mob") + "</td>");
                    out.println("<td>" + s.get("place") + "</td>");
                    out.println("<td>" + (s.get("remarks") == null ? "" : s.get("remarks")) + "</td>");

                    for (int exId : examIds) {
                        Integer m = marksMap.get(s.get("enquiry_id") + "_" + exId);
                        out.println("<td>" + (m == null ? 0 : m) + "</td>");
                    }

                    out.println("<td><b>" + s.get("total_marks") + "</b></td>");
                    out.println("<td><b>" + String.format("%.2f", (double)s.get("percentage")) + "%</b></td>");
                    out.println("</tr>");
                }
                out.println("</tbody></table>");
            }
        } catch (Exception e) {
            e.printStackTrace();
            out.println("<p style='color:red;'>Error: " + e.getMessage() + "</p>");
        }
    }
}