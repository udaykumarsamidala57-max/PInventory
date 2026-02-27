package com.controller.Admissions;

import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import com.bean.DBUtil3;

@MultipartConfig
@WebServlet("/UploadCSVServlet")
public class UploadCSVServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ================= SESSION CHECK =================
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");
        if (!"Global".equalsIgnoreCase(role)
                && !"Incharge".equalsIgnoreCase(role)
                && !"Admin".equalsIgnoreCase(role)) {
            response.setContentType("text/html");
            response.getWriter().println("<h3 style='color:red;'>Access Denied</h3>");
            return;
        }

        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();

        Part filePart = request.getPart("csvFile"); 

        // Handle null or empty file
        if (filePart == null || filePart.getSize() == 0) {
            out.println("<h3 style='color:red;'>Error: No file uploaded or file is empty!</h3>");
            return;
        }

        // Ensure file is CSV
        String fileName = filePart.getSubmittedFileName();
        if (!fileName.toLowerCase().endsWith(".csv")) {
            out.println("<h3 style='color:red;'>Error: Only CSV files are allowed!</h3>");
            return;
        }

        BufferedReader br = new BufferedReader(new InputStreamReader(filePart.getInputStream(), "UTF-8"));
        String line;
        int successCount = 0;
        int failCount = 0;

        try (Connection con = DBUtil3.getConnection()) {

            String sql = "INSERT INTO student_master "
                    + "(admission_no, student_name, gender, class, section, "
                    + "father_name, father_mobile_no, mother_name, mother_mobile_no, "
                    + "category, student_segment) "
                    + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            PreparedStatement ps = con.prepareStatement(sql);

            // Read header
            line = br.readLine();
            if (line == null || line.trim().isEmpty()) {
                out.println("<h3 style='color:red;'>Error: Uploaded CSV is empty!</h3>");
                return;
            }

            while ((line = br.readLine()) != null) {
                if (line.trim().isEmpty()) continue; // Skip blank lines

                String[] data = parseCSV(line);

                if (data.length != 11) { 
                    failCount++;
                    out.println("<span style='color:orange;'>Skipped (wrong column count): " + line + "</span><br/>");
                    continue;
                }

                // Trim & remove quotes
                for (int i = 0; i < data.length; i++) {
                    data[i] = data[i] != null ? data[i].trim().replaceAll("^\"|\"$", "") : "";
                }

                // Skip if admission_no empty
                if (data[0].isEmpty()) {
                    failCount++;
                    out.println("<span style='color:orange;'>Skipped (empty admission_no): " + line + "</span><br/>");
                    continue;
                }

                // Check duplicate
                PreparedStatement check = con.prepareStatement(
                        "SELECT 1 FROM student_master WHERE admission_no=?");
                check.setString(1, data[0]);
                ResultSet rs = check.executeQuery();
                if (rs.next()) {
                    failCount++;
                    out.println("<span style='color:orange;'>Skipped (duplicate admission_no): " + line + "</span><br/>");
                    continue;
                }

                try {
                    for (int i = 0; i < 11; i++) ps.setString(i + 1, data[i]);
                    ps.executeUpdate();
                    successCount++;
                } catch (Exception e) {
                    failCount++;
                    out.println("<span style='color:red;'>Failed row: " + line + "</span><br/>");
                    e.printStackTrace(out);
                }
            }

            out.println("<h3 style='color:green;'>Upload Completed!</h3>");
            out.println("Success: " + successCount + "<br/>");
            out.println("Failed: " + failCount + "<br/>");

        } catch (Exception e) {
            out.println("<h3 style='color:red;'>Error processing file!</h3>");
            e.printStackTrace(out);
        } finally {
            if (br != null) br.close();
        }
    }

    // CSV parser (handles quoted commas)
    private String[] parseCSV(String line) {
        return line.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", -1);
    }
}
