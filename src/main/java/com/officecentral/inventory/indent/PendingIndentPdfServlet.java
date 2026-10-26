package com.officecentral.inventory.indent;

import java.io.*;
import java.net.*;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.*;
import java.util.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.officecentral.common.db.InventoryDB;

// ✅ Explicit iText imports
import com.itextpdf.text.BaseColor;
import com.itextpdf.text.Document;
import com.itextpdf.text.Element;
import com.itextpdf.text.Font;
import com.itextpdf.text.Image;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.Phrase;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfWriter;

@WebServlet(urlPatterns = {"/pending-indent-pdf", "/SendPendingIndentPDF"})   // second one = old address, kept so old links still work
public class PendingIndentPdfServlet extends HttpServlet {
	String branch;
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
    	
    	HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");
        String dept = (String) sess.getAttribute("department");
        String branch = (String) sess.getAttribute("branch");

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
        
        

      String branch ="SRS";

        String sql = """
        	    SELECT indent_no, indent_date, item_name, qty, department, requested_by, purpose
        	    FROM indent
        	    WHERE TRIM(status) = 'Pending'
        	      AND TRIM(Indentnext) = 'PO'
        	    ORDER BY indent_id DESC
        	    """;

        try (Connection con = InventoryDB.getConnection(branch);
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

        // ✅ Generate PDF file
        String pdfPath = System.getProperty("java.io.tmpdir") + File.separator + "PendingIndentsReport.pdf";
        generatePDF(pendingIndents, pdfPath);

        // ✅ Send Email
        sendBrevoEmailWithAttachment(toEmail, pdfPath);
    }

    // -------------------- PDF CREATION --------------------
    private static void generatePDF(java.util.List<Map<String, Object>> data, String filePath) {
        try {
            Document document = new Document(PageSize.A4, 36, 36, 50, 50);
            PdfWriter.getInstance(document, new FileOutputStream(filePath));
            document.open();

            // Fonts
            Font schoolFont = new Font(Font.FontFamily.HELVETICA, 20, Font.BOLD, new BaseColor(0, 102, 204));
            Font titleFont = new Font(Font.FontFamily.HELVETICA, 14, Font.BOLD, new BaseColor(33, 97, 140));
            Font headerFont = new Font(Font.FontFamily.HELVETICA, 12, Font.BOLD, BaseColor.WHITE);
            Font textFont = new Font(Font.FontFamily.HELVETICA, 11, Font.NORMAL, BaseColor.BLACK);

            // ---- Add branding header (PO and Indent Header.png)
            byte[] brandingHeader = loadBrandingHeaderImage();
            if (brandingHeader != null) {
                try {
                    Image brandImg = Image.getInstance(brandingHeader);
                    brandImg.scaleToFit(document.getPageSize().getWidth() - 72, 80f);  // max-height ~80px
                    brandImg.setAlignment(Element.ALIGN_CENTER);
                    brandImg.setSpacingAfter(8f);
                    document.add(brandImg);
                } catch (Exception e) {
                    System.err.println("[PDF] Failed to add branding header: " + e.getMessage());
                }
            }

            // Header
            Paragraph schoolName = new Paragraph("SANDUR RESIDENTIAL SCHOOL", schoolFont);
            schoolName.setAlignment(Element.ALIGN_CENTER);
            document.add(schoolName);

            Paragraph title = new Paragraph("Pending Indents for Purchase Order", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(15f);
            document.add(title);

            // Table
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

            // Rows
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

            // Footer Note
            Paragraph note = new Paragraph(
                    "\n📄 Management Note:\nThese indents are pending and require purchase order action.\n" +
                            "Please review and process them at the earliest.",
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

    // -------------------- BRANDING HEADER LOADER --------------------
    private static byte[] loadBrandingHeaderImage() {
        try {
            String catalinaBase = System.getProperty("catalina.base");
            String basePath = catalinaBase != null ? catalinaBase : System.getProperty("user.dir");

            // Try multiple possible paths
            String[] possiblePaths = {
                basePath + File.separator + "webapps" + File.separator + "PInventory" + File.separator + "assets" + File.separator + "branding" + File.separator + "PO and Indent Header.png",
                basePath + "/webapps/PInventory/assets/branding/PO and Indent Header.png",
                "webapps/PInventory/assets/branding/PO and Indent Header.png",
                "assets/branding/PO and Indent Header.png"
            };

            for (String headerPath : possiblePaths) {
                java.nio.file.Path path = Paths.get(headerPath);
                if (Files.exists(path)) {
                    byte[] data = Files.readAllBytes(path);
                    System.out.println("[PDF] Branding header loaded from: " + path.toAbsolutePath());
                    return data;
                }
            }

            System.err.println("[PDF] Branding header not found in any expected location");
            return null;
        } catch (Exception e) {
            System.err.println("[PDF] Could not load branding header: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    // -------------------- BREVO EMAIL --------------------
    private static void sendBrevoEmailWithAttachment(String to, String pdfPath) {
        try {
            // Read PDF file and convert to Base64
            File pdfFile = new File(pdfPath);
            byte[] pdfBytes = java.nio.file.Files.readAllBytes(pdfFile.toPath());

            // ✅ Build HTML content (fully escaped)
            String html = """
            <div style='font-family:Poppins,Arial,sans-serif;background:#f8fafc;color:#1f2937;border-radius:8px;overflow:hidden;'>
              <div style='background:linear-gradient(90deg,#2563eb,#1d4ed8);padding:15px;text-align:center;color:white;'>
                <h2 style='margin:0;font-weight:700;'>Sandur Residential School</h2>
                <p style='margin:0;font-size:13px;opacity:0.9;'>Inventory Automation System</p>
              </div>
              <div style='padding:20px;'>
                <h3 style='color:#2563eb;margin-top:0;'>📊 Pending Indents Report</h3>
                <p>Dear Sir/Madam,</p>
                <p>The attached <b>Pending Indents Report</b> lists items awaiting Purchase Order action. Kindly review and approve them promptly to ensure uninterrupted operations.</p>
                <blockquote style='border-left:4px solid #2563eb;padding-left:10px;margin:15px 0;color:#374151;font-style:italic;'>
                  “Great systems don’t wait — they evolve with action.”
                </blockquote>
                <p style='font-size:14px;color:#4b5563;'>This report was generated automatically by the <b>Inventory Automation System</b> – Sandur Residential School.</p>
                <p style='margin-top:20px;color:#2563eb;font-weight:bold;'>— SRS Central Admin</p>
              </div>
              <div style='background:#1e3a8a;color:white;text-align:center;padding:10px;font-size:12px;'>
                © 2025 Sandur Residential School | Central Office Automation
              </div>
            </div>
            """;

            com.officecentral.common.mail.Mailer.send(to, "📦 Pending Indents Report – Sandur Residential School",
                    html, "PendingIndentsReport.pdf", pdfBytes);


        } catch (Exception e) {
            throw new RuntimeException("E-mail send failed: " + e.getMessage());
        }
    }
}
