package com.controller.Admissions;


import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashMap;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;	
import javax.servlet.http.HttpServletResponse;
import com.bean.DBUtil3;

@WebServlet("/UpdateAdmissionStatus")
public class UpdateAdmissionStatusServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String enquiryId = request.getParameter("enquiry_id");
        String status = request.getParameter("status"); 

        try (Connection con = DBUtil3.getConnection()) {
            String sql = "UPDATE admission_enquiry SET Admission_status = ? WHERE enquiry_id = ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, status);
                ps.setInt(2, Integer.parseInt(enquiryId));
                int rowsUpdated = ps.executeUpdate();
                response.getWriter().write(rowsUpdated > 0 ? "Success" : "Error");
            }
        } catch (Exception e) {
            response.setStatus(500);
            response.getWriter().write(e.getMessage());
        }
    }

 // ... [Keep imports and doPost as they are] ...

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        String classIdRaw = request.getParameter("class_id");
        String examDate = request.getParameter("exam_date");

        if (classIdRaw == null) return;

        try (Connection con = DBUtil3.getConnection()) {
            int classId = Integer.parseInt(classIdRaw);
            boolean isAllDates = "All".equalsIgnoreCase(examDate);

            // Fetch Exams
            StringBuilder examsJson = new StringBuilder("[");
            String examQuery = "SELECT exam_id, exam_name, max_marks FROM class_exams WHERE class_id=?";
            try (PreparedStatement ps = con.prepareStatement(examQuery)) {
                ps.setInt(1, classId);
                ResultSet rs = ps.executeQuery();
                while(rs.next()) {
                    examsJson.append(String.format("{\"id\":%d,\"name\":\"%s\",\"max\":%d},", 
                        rs.getInt("exam_id"), rs.getString("exam_name"), rs.getInt("max_marks")));
                }
            }
            if(examsJson.length() > 1) examsJson.setLength(examsJson.length() - 1);
            examsJson.append("]");

            // Fetch Marks into Map
            HashMap<String, Integer> marksMap = new HashMap<>();
            String mQuery = "SELECT enquiry_id, exam_id, marks_obtained FROM student_exam_marks";
            try (PreparedStatement ps = con.prepareStatement(mQuery)) {
                ResultSet rs = ps.executeQuery();
                while(rs.next()) {
                    marksMap.put(rs.getInt("enquiry_id") + "_" + rs.getInt("exam_id"), rs.getInt("marks_obtained"));
                }
            }

            // Fetch Students - Query updated to use proper schema names
            StringBuilder studentsJson = new StringBuilder("[");
            String sQuery = "SELECT ae.* FROM admission_enquiry ae " +
                           "JOIN classes c ON TRIM(ae.class_of_admission) = TRIM(c.class_name) " +
                           "WHERE c.class_id=? AND ae.approved='Approved' " + 
                           "AND ae.application_no IS NOT NULL AND ae.application_no != '' " + 
                           (isAllDates ? "" : "AND ae.exam_date=? ") + 
                           "ORDER BY ae.enquiry_id";
            
            try (PreparedStatement ps = con.prepareStatement(sQuery)) {
                ps.setInt(1, classId);
                if (!isAllDates) ps.setString(2, examDate);
                ResultSet rs = ps.executeQuery();
                while(rs.next()) {
                    int enqId = rs.getInt("enquiry_id");
                    studentsJson.append("{");
                    studentsJson.append("\"id\":").append(enqId).append(",");
                    studentsJson.append("\"appNo\":\"").append(rs.getString("application_no")).append("\",");
                    studentsJson.append("\"name\":\"").append(rs.getString("student_name")).append("\",");
                    
                    // CORRECTED COLUMN NAME HERE
                    studentsJson.append("\"dob\":\"").append(rs.getString("date_of_birth") != null ? rs.getString("date_of_birth") : "").append("\",");
                    
                    studentsJson.append("\"status\":\"").append(rs.getString("Admission_status") != null ? rs.getString("Admission_status") : "").append("\",");
                    studentsJson.append("\"father\":\"").append(rs.getString("father_name")).append("\",");
                    studentsJson.append("\"fMobile\":\"").append(rs.getString("father_mobile_no")).append("\",");
                    studentsJson.append("\"fOcc\":\"").append(rs.getString("father_occupation") != null ? rs.getString("father_occupation") : "N/A").append("\",");
                    studentsJson.append("\"fOrg\":\"").append(rs.getString("father_organization") != null ? rs.getString("father_organization") : "N/A").append("\",");
                    studentsJson.append("\"mother\":\"").append(rs.getString("mother_name")).append("\",");
                    studentsJson.append("\"mMobile\":\"").append(rs.getString("mother_mobile_no") != null ? rs.getString("mother_mobile_no") : "N/A").append("\",");
                    studentsJson.append("\"mOcc\":\"").append(rs.getString("mother_occupation") != null ? rs.getString("mother_occupation") : "N/A").append("\",");
                    studentsJson.append("\"mOrg\":\"").append(rs.getString("mother_organization") != null ? rs.getString("mother_organization") : "N/A").append("\",");
                    studentsJson.append("\"admission_type\":\"").append(rs.getString("admission_type") != null ? rs.getString("admission_type") : "Regular").append("\",");
                    studentsJson.append("\"segment\":\"").append(rs.getString("segment") != null ? rs.getString("segment") : "N/A").append("\",");
                    studentsJson.append("\"place\":\"").append(rs.getString("place_from") != null ? rs.getString("place_from") : "N/A").append("\",");
                    
                    studentsJson.append("\"marks\":{");
                    final boolean[] first = {true};
                    marksMap.forEach((key, val) -> {
                        if(key.startsWith(enqId + "_")) {
                            if(!first[0]) studentsJson.append(",");
                            studentsJson.append("\"").append(key.split("_")[1]).append("\":").append(val);
                            first[0] = false;
                        }
                    });
                    studentsJson.append("}},");
                }
            }
            if(studentsJson.length() > 1) studentsJson.setLength(studentsJson.length() - 1);
            studentsJson.append("]");

            out.print("{\"exams\":" + examsJson + ", \"students\":" + studentsJson + "}");
        } catch (Exception e) {
            e.printStackTrace(); // Always print stack trace for debugging!
            response.setStatus(500);
        }
    }

}