package com.controller;

import java.io.*;
import java.net.*;
import java.sql.*;
import java.util.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

// ✅ Explicit iText imports
import com.itextpdf.text.BaseColor;
import com.itextpdf.text.Document;
import com.itextpdf.text.Element;
import com.itextpdf.text.Font;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.Phrase;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfWriter;

@WebServlet("/SendPendingIndentPDF")
public class SendPendingIndentPDF extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        response.setContentType("text/html;charset=UTF-8");
        String toEmail = request.getParameter("email");

        try (PrintWriter out = response.getWriter()) {
            if (toEmail == null || toEmail.isBlank()) {
                out.println("<h3 style='color:red;'>❌ Please enter a valid email address.</h3>");
                return;
            }

            sendPendingIndentReport(toEmail);
            out.println("<h3 style='color:green;'>✅ Email sent successfully to " + toEmail + "</h3>");
        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().println("<h3 style='color:red;'>❌ Error: " + e.getMessage() + "</h3>");
        }
    }

    // -------------------- MAIN LOGIC --------------------
    public static void sendPendingIndentReport(String toEmail) {
        java.util.List<Map<String, Object>> pendingIndents = new ArrayList<>();

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

        // Generate PDF
        String pdfPath = System.getProperty("java.io.tmpdir") + File.separator + "PendingIndentsReport.pdf";
        generatePDF(pendingIndents, pdfPath);

        // Send Email
        sendBrevoEmailWithAttachment(toEmail, pdfPath);
    }

    // -------------------- PDF CREATION --------------------
    private static void generatePDF(java.util.List<Map<String, Object>> data, String filePath) {
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
                    "\n📄 Management Note:\nThese indents are pending and require purchase order action.\nPlease review and process them at the earliest.",
                    new Font(Font.FontFamily.HELVETICA, 11, Font.ITALIC, new BaseColor(90, 90, 90))
            );
            note.setSpacingBefore(15f);
            document.add(note);

            document.close();
            System.out.println("✅ PDF generated successfully: " + filePath);

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

            // Read PDF file
            File pdfFile = new File(pdfPath);
            byte[] pdfBytes = java.nio.file.Files.readAllBytes(pdfFile.toPath());
            String base64Pdf = Base64.getEncoder().encodeToString(pdfBytes);

            // ✅ Build HTML content
            StringBuilder html = new StringBuilder();
            html.append("<div style='background:linear-gradient(90deg,#2563eb,#1d4ed8);color:white;padding:15px;border-radius:8px 8px 0 0;text-align:center;'>")
                .append("<h2 style='margin:0;font-family:Poppins,sans-serif;'>Sandur Residential School</h2>")
                .append("<p style='margin:0;font-size:13px;'>Inventory Automation System</p>")
                .append("</div>")
                .append("<div style='background:#f9fafb;padding:20px;color:#1f2937;font-family:Poppins,Arial,sans-serif;'>")
                .append("<h3 style='color:#2563eb;'>📊 Pending Indents Report</h3>")
                .append("<p>Dear Management,</p>")
                .append("<p>The latest <b>Pending Indents Report</b> is attached. Please review and approve the pending items for Purchase Orders to ensure smooth departmental operations.</p>")
                .append("<blockquote style='border-left:4px solid #2563eb;padding-left:10px;color:#374151;font-style:italic;'>“Great systems don’t wait — they evolve with action.”</blockquote>")
                .append("<p style='font-size:14px;color:#4b5563;'>Generated automatically by <b>Inventory Automation System</b> – Sandur Residential School.</p>")
                .append("<p style='margin-top:20px;color:#2563eb;font-weight:bold;'>SRS Central Admin</p>")
                .append("</div>");

            String json = """
            		{
            		  "sender": {"name": "SRS Central Admin", "email": "udaykumarsamidala57@gmail.com"},
            		  "to": [{"email": "%s"}],
            		  "subject": "📦 Pending Indents Report – Sandur Residential School",
            		  "htmlContent": "%s",
            		  "attachment": [{"content": "%s", "name": "PendingIndentsReport.pdf"}]
            		}
            		""".formatted(to, html.toString().replace("\"", "\\\""), base64Pdf);

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

            System.out.println("✅ Brevo email sent successfully to: " + to);

        } catch (Exception e) {
            throw new RuntimeException("Brevo email send failed: " + e.getMessage());
        }
    }
}
