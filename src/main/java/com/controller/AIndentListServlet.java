package com.controller;

import java.io.*;
import java.net.*;
import java.sql.*;
import java.util.*;
import java.util.List;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import com.itextpdf.text.*;
import com.itextpdf.text.pdf.*;
import com.bean.DBUtil;

@WebServlet("/SendPendingIndentPDF")
public class SendPendingIndentPDF extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("text/html;charset=UTF-8");

        // -------------------- SESSION VALIDATION --------------------
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");
        String dept = (String) sess.getAttribute("department");

        // Only Global role can access this feature
        if (!"Global".equalsIgnoreCase(role)) {
            response.setContentType("text/html");
            response.getWriter().println("""
                <div style='font-family:Arial; margin:50px; text-align:center;'>
                    <h2 style='color:#dc2626;'>❌ Access Denied</h2>
                    <p style='color:#555;'>Only <b>Global Admin</b> role can send the Pending Indent Report.</p>
                    <a href='home.jsp' style='color:#2563eb; text-decoration:none;'>⬅ Go Back</a>
                </div>
            """);
            return;
        }

        // -------------------- MAIN LOGIC --------------------
        String toEmail = request.getParameter("email");
        try {
            if (toEmail == null || toEmail.isBlank()) {
                response.getWriter().println("<h3 style='color:red;'>❌ Please enter a valid email address.</h3>");
                return;
            }

            sendPendingIndentReport(toEmail);
            response.getWriter().println("<h3 style='color:green;'>✅ Email sent successfully to " + toEmail + "</h3>");
        } catch (Exception e) {
            response.getWriter().println("<h3 style='color:red;'>❌ Error: " + e.getMessage() + "</h3>");
            e.printStackTrace();
        }
    }

    // -------------------- FETCH & PROCESS DATA --------------------
    public static void sendPendingIndentReport(String toEmail) {
        List<Map<String, Object>> pendingIndents = new ArrayList<>();

        String sql = """
                SELECT indent_no, indent_date, item_name, qty, department, requested_by, purpose
                FROM indent
                WHERE TRIM(status)='Pending' AND TRIM(Indentnext)='PO'
                ORDER BY indent_id DESC
                """;

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("indent_no", rs.getString("indent_no"));
                row.put("indent_date", rs.getString("indent_date"));
                row.put("item_name", rs.getString("item_name"));
                row.put("qty", rs.getDouble("qty"));
                row.put("department", rs.getString("department"));
                row.put("requested_by", rs.getString("requested_by"));
                row.put("purpose", rs.getString("purpose"));
                pendingIndents.add(row);
            }

        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage());
        }

        if (pendingIndents.isEmpty()) {
            throw new RuntimeException("No pending indents found for PO.");
        }

        String pdfPath = System.getProperty("java.io.tmpdir") + File.separator + "PendingIndentsReport.pdf";
        generatePDF(pendingIndents, pdfPath);
        sendBrevoEmailWithAttachment(toEmail, pdfPath);
    }

    // -------------------- PDF CREATION --------------------
    private static void generatePDF(List<Map<String, Object>> data, String filePath) {
        try {
            Document document = new Document(PageSize.A4, 36, 36, 50, 50);
            PdfWriter.getInstance(document, new FileOutputStream(filePath));
            document.open();

            Font schoolFont = new Font(Font.FontFamily.HELVETICA, 20, Font.BOLD, new BaseColor(0, 102, 204));
            Font titleFont = new Font(Font.FontFamily.HELVETICA, 14, Font.BOLD, new BaseColor(33, 97, 140));
            Font headerFont = new Font(Font.FontFamily.HELVETICA, 12, Font.BOLD, BaseColor.WHITE);
            Font textFont = new Font(Font.FontFamily.HELVETICA, 11, Font.NORMAL, BaseColor.BLACK);

            Paragraph schoolName = new Paragraph("SANDUR RESIDENTIAL SCHOOL", schoolFont);
            schoolName.setAlignment(Element.ALIGN_CENTER);
            document.add(schoolName);

            Paragraph title = new Paragraph("Pending Indents for Purchase Order", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(15f);
            document.add(title);

            PdfPTable table = new PdfPTable(7);
            table.setWidthPercentage(100);
            table.setSpacingBefore(10f);
            table.setWidths(new int[]{1, 2, 2, 3, 1, 2, 3});

            String[] headers = {"S.No", "Indent No", "Date", "Item", "Qty", "Department", "Requested By"};
            for (String h : headers) {
                PdfPCell cell = new PdfPCell(new Phrase(h, headerFont));
                cell.setBackgroundColor(new BaseColor(52, 152, 219));
                cell.setHorizontalAlignment(Element.ALIGN_CENTER);
                cell.setPadding(6);
                table.addCell(cell);
            }

            int serial = 1;
            for (Map<String, Object> row : data) {
                table.addCell(new Phrase(String.valueOf(serial++), textFont));
                table.addCell(new Phrase(row.get("indent_no").toString(), textFont));
                table.addCell(new Phrase(row.get("indent_date").toString(), textFont));
                table.addCell(new Phrase(row.get("item_name").toString(), textFont));
                table.addCell(new Phrase(row.get("qty").toString(), textFont));
                table.addCell(new Phrase(row.get("department").toString(), textFont));
                table.addCell(new Phrase(row.get("requested_by").toString(), textFont));
            }

            document.add(table);

            Paragraph note = new Paragraph(
                    "\n📄 Management Note:\nThese indents are pending and require purchase order action.\n" +
                    "Please review and process them at the earliest.",
                    new Font(Font.FontFamily.HELVETICA, 11, Font.ITALIC, new BaseColor(90, 90, 90))
            );
            note.setSpacingBefore(15f);
            document.add(note);

            document.close();

        } catch (Exception e) {
            throw new RuntimeException("PDF generation failed: " + e.getMessage());
        }
    }

    // -------------------- BREVO EMAIL API --------------------
    private static void sendBrevoEmailWithAttachment(String to, String pdfPath) {
        try {
            String apiKey = System.getenv("BREVO_API_KEY");
            if (apiKey == null || apiKey.isEmpty()) {
                throw new RuntimeException("⚠️ Brevo API key not found in environment variables!");
            }

            File pdfFile = new File(pdfPath);
            byte[] pdfBytes = java.nio.file.Files.readAllBytes(pdfFile.toPath());
            String base64Pdf = Base64.getEncoder().encodeToString(pdfBytes);

            String json = """
            {
              "sender": {"name":"SRS Central Admin","email":"udaykumarsamidala57@gmail.com"},
              "to":[{"email":"%s"}],
              "subject":"📦 Pending Indents Report - Purchase Order Required",
              "htmlContent":"<div style='font-family:Poppins,Arial,sans-serif;color:#333;line-height:1.6;'><h2 style='color:#2563eb;'>Pending Indents Report</h2><p>Dear Management,</p><p>Please find attached the latest <b>Pending Indents Report</b> awaiting PO approval.</p><p>Generated by <b>Inventory Automation System</b> - Sandur Residential School.</p><br><p style='font-size:14px;color:#555;'>Regards,<br><b>SRS Central Admin</b></p></div>",
              "attachment":[{"content":"%s","name":"PendingIndentsReport.pdf"}]
            }
            """.formatted(to, base64Pdf);

            URL url = new URL("https://api.brevo.com/v3/smtp/email");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("accept", "application/json");
            conn.setRequestProperty("api-key", apiKey);
            conn.setRequestProperty("content-type", "application/json");
            conn.setDoOutput(true);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(json.getBytes("UTF-8"));
            }

            int responseCode = conn.getResponseCode();
            if (responseCode != 201 && responseCode != 200) {
                String error = new String(conn.getErrorStream().readAllBytes());
                throw new RuntimeException("Brevo API error (" + responseCode + "): " + error);
            }

            System.out.println("[Manual Trigger] Brevo email sent successfully to: " + to);

        } catch (Exception e) {
            throw new RuntimeException("Brevo email send failed: " + e.getMessage());
        }
    }
}
