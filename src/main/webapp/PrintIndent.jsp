<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, com.bean.DBUtil" %>
<%@ page import="java.time.LocalDate, java.time.format.DateTimeFormatter" %>
<%!
    /** Up to this many items the indent is printed on A5; more items go on A4. */
    private static final int A5_MAX_ITEMS = 12;

    private static String h(Object o) {
        if (o == null) return "";
        return String.valueOf(o).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
    private static String dash(String s) { return (s == null || s.trim().isEmpty()) ? "-" : s.trim(); }
%>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) { response.sendRedirect("login.jsp"); return; }

    String indentNumber = request.getParameter("IndentNumber");
    String branch = (String) sess.getAttribute("branch");

    // ---- Load the indent first, so the paper size can be chosen from the number of items
    List<Map<String, Object>> rows = new ArrayList<>();
    String error = null;
    if (indentNumber == null || indentNumber.trim().isEmpty()) {
        error = "Invalid or missing Indent Number parameter.";
    } else {
        try (Connection con = DBUtil.getConnection(branch);
             PreparedStatement pst = con.prepareStatement(
                 "SELECT i.indent_no, i.PurchaseorIssue, i.indent_date, i.item_name, i.qty, i.department, i.requested_by, " +
                 "i.status, i.purpose, i.Indentnext, COALESCE(s.balance_qty, 0) AS balance_qty, m.UOM " +
                 "FROM indent i LEFT JOIN stock s ON i.item_id = s.item_id " +
                 "LEFT JOIN item_master m ON i.item_id = m.Item_id WHERE i.indent_no = ?")) {
            pst.setString(1, indentNumber.trim());
            try (ResultSet rs = pst.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> r = new HashMap<>();
                    for (String c : new String[] { "PurchaseorIssue", "indent_date", "item_name", "qty", "department",
                                                   "requested_by", "status", "purpose", "Indentnext", "UOM" })
                        r.put(c, rs.getString(c));
                    r.put("balance_qty", rs.getBigDecimal("balance_qty"));
                    rows.add(r);
                }
            }
            if (rows.isEmpty()) error = "No record found for this indent number.";
        } catch (Exception e) {
            e.printStackTrace();
            error = "Error rendering report: " + e.getMessage();
        }
    }

    // ---- Paper: automatic by item count, or forced with ?paper=A4 / ?paper=A5
    String autoPaper = rows.size() <= A5_MAX_ITEMS ? "A5" : "A4";
    String paper = request.getParameter("paper");
    paper = ("A4".equalsIgnoreCase(paper) || "A5".equalsIgnoreCase(paper)) ? paper.toUpperCase() : autoPaper;
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Indent <%= h(indentNumber) %> - Sandur Residential School</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
* { box-sizing: border-box; }
body { font-family: 'Poppins', 'Segoe UI', sans-serif; background: #f3f3f3; margin: 0; padding: 20px 0; color: #181818; }

/* ---------- Sheet (A4 default) ---------- */
.container { width: 100%; max-width: 210mm; margin: 0 auto; background: #fff; padding: 25px 30px;
             border-radius: 6px; border: 1px solid #c9c9c9; box-shadow: 0 2px 6px rgba(0,0,0,.05); }
.header { text-align: center; margin-bottom: 12px; }
.header img { max-height: 85px; width: auto; display: block; margin: 0 auto 8px; }
.document-title { text-align: center; color: #0176d3; margin: 12px 0 16px; font-size: 16px; font-weight: 700;
                  text-transform: uppercase; letter-spacing: .8px; border-top: 2px solid #0176d3; border-bottom: 2px solid #0176d3; padding: 6px 0; }

.indent-info { margin: 12px 0 20px; background: #fafaf9; border-radius: 4px; padding: 12px 16px; border: 1px solid #e5e5e5;
               border-left: 4px solid #0176d3; display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px 20px; }
.info-item { display: flex; font-size: 12.5px; line-height: 1.4; }
.info-label { font-weight: 700; color: #514f4d; min-width: 110px; text-transform: uppercase; font-size: 11px; letter-spacing: .4px; }
.info-value { color: #181818; font-weight: 500; }
.full-width { grid-column: 1 / -1; }

.badge-type { display: inline-block; padding: 2px 8px; font-size: 10.5px; font-weight: 700; border-radius: 12px; text-transform: uppercase; letter-spacing: .4px; }
.badge-type-purchase { background: #eef4fe; color: #0176d3; border: 1px solid #aacbfa; }
.badge-type-issue    { background: #eaf5ea; color: #2e844a; border: 1px solid #a3d9b1; }

table { width: 100%; border-collapse: collapse; font-size: 12px; margin-top: 15px; }
th { background: #fafaf9; color: #514f4d; padding: 8px 6px; font-weight: 700; text-transform: uppercase; letter-spacing: .3px;
     border: 1px solid #e5e5e5; border-top-color: #c9c9c9; border-bottom: 2px solid #c9c9c9; font-size: 11px; text-align: center; }
td { border: 1px solid #e5e5e5; padding: 8px 6px; text-align: center; vertical-align: middle; }
td.item { text-align: left; }
tr:nth-child(even) td { background: #fafaf9; }
thead { display: table-header-group; }          /* repeat column headings on every printed page */
tr { page-break-inside: avoid; break-inside: avoid; }

.signature-section { margin-top: 40px; display: flex; justify-content: space-between; align-items: flex-end; page-break-inside: avoid; break-inside: avoid; }
.stamp-box { min-width: 120px; }
.stamp { display: inline-block; padding: 6px 14px; border: 2px dashed #2e844a; color: #2e844a; font-weight: 700; font-size: 14px;
         text-transform: uppercase; border-radius: 4px; transform: rotate(-5deg); letter-spacing: 1px; }
.sign-box { text-align: right; }
.company-name { font-weight: 700; font-size: 12px; color: #514f4d; margin-bottom: 45px; }
.sign-title { font-weight: 600; font-size: 12px; border-top: 1px solid #181818; padding-top: 4px; display: inline-block; }

/* ---------- A5: same layout, compact so a full indent fits one A5 sheet ---------- */
body.paper-a5 .container { max-width: 148mm; padding: 14px 16px; }
body.paper-a5 .header { margin-bottom: 6px; }
body.paper-a5 .header img { max-height: 52px; margin-bottom: 4px; }
body.paper-a5 .document-title { font-size: 12.5px; margin: 6px 0 8px; padding: 3px 0; border-width: 1.5px; }
body.paper-a5 .indent-info { margin: 6px 0 8px; padding: 6px 10px; gap: 3px 12px; border-left-width: 3px; }
body.paper-a5 .info-item { font-size: 10.5px; line-height: 1.35; }
body.paper-a5 .info-label { font-size: 9px; min-width: 82px; }
body.paper-a5 .badge-type { font-size: 9px; padding: 1px 6px; }
body.paper-a5 table { font-size: 10.5px; margin-top: 6px; }
body.paper-a5 th { font-size: 9px; padding: 4px 4px; }
body.paper-a5 td { padding: 4px 4px; }
body.paper-a5 .signature-section { margin-top: 18px; }
body.paper-a5 .stamp { font-size: 11px; padding: 4px 10px; }
body.paper-a5 .company-name { font-size: 10px; margin-bottom: 28px; }
body.paper-a5 .sign-title { font-size: 10px; }

/* ---------- Buttons (screen only) ---------- */
.action-bar { margin-top: 25px; display: flex; justify-content: center; align-items: center; gap: 10px; flex-wrap: wrap; }
.paper-note { font-size: 12px; color: #5e5e5e; width: 100%; text-align: center; }
.btn { height: 36px; padding: 0 18px; border: 1px solid #0176d3; background: #fff; color: #0176d3; border-radius: 4px; cursor: pointer;
       font: inherit; font-size: 12px; font-weight: 600; display: inline-flex; align-items: center; gap: 6px; }
.btn:hover { background: #eef4fe; }
.btn.primary { background: #0176d3; color: #fff; }
.btn.primary:hover { background: #015a9e; border-color: #015a9e; }

/* ---------- Print ---------- */
@media print {
    html, body { background: #fff; padding: 0; margin: 0; }
    .container { width: 100%; max-width: 100% !important; border: none; box-shadow: none; padding: 0 !important; margin: 0; border-radius: 0; }
    .action-bar { display: none !important; }
    th, tr:nth-child(even) td, .indent-info, .badge-type { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
}
</style>
<!-- Page size for the printer; swapped by the A4/A5 buttons -->
<style id="pageSize">@page { size: <%= paper %> portrait; margin: <%= "A5".equals(paper) ? "8mm" : "12mm" %>; }</style>
</head>
<body class="<%= "A5".equals(paper) ? "paper-a5" : "paper-a4" %>">

<div class="container">
    <div class="header"><img src="Header.png" alt="School Logo"></div>
    <div class="document-title">Indent Details</div>

<% if (error != null) { %>
    <div style="text-align:center; padding:20px 0; color:#c23934; font-weight:600; font-size:12px;"><%= h(error) %></div>
<% } else {
       Map<String, Object> first = rows.get(0);
       String type       = (String) first.get("PurchaseorIssue");
       String indentNext = (String) first.get("Indentnext");
       boolean isIssue   = "Issue".equalsIgnoreCase(type);
       boolean viaPO     = indentNext != null && "PO".equalsIgnoreCase(indentNext.trim());

       String indentDate = (String) first.get("indent_date"), shownDate = dash(indentDate);
       try { shownDate = LocalDate.parse(indentDate.trim()).format(DateTimeFormatter.ofPattern("dd MMMM yyyy")); } catch (Exception ignore) { }

       boolean allApproved = true;
       for (Map<String, Object> r : rows) {
           String st = (String) r.get("status");
           if (!viaPO && (st == null || !"Approved".equalsIgnoreCase(st.trim()))) allApproved = false;
       }
%>
    <div class="indent-info">
        <div class="info-item"><span class="info-label">Indent No:</span><span class="info-value"><%= h(indentNumber) %></span></div>
        <div class="info-item"><span class="info-label">Indent Date:</span><span class="info-value"><%= h(shownDate) %></span></div>
        <div class="info-item"><span class="info-label">Department:</span><span class="info-value"><%= h(dash((String) first.get("department"))) %></span></div>
        <div class="info-item"><span class="info-label">Requested By:</span><span class="info-value"><%= h(dash((String) first.get("requested_by"))) %></span></div>
        <div class="info-item"><span class="info-label">Type:</span>
            <span class="info-value"><span class="badge-type <%= isIssue ? "badge-type-issue" : "badge-type-purchase" %>"><%= h(dash(type)) %></span></span></div>
        <div class="info-item"><span class="info-label">Items:</span><span class="info-value"><%= rows.size() %></span></div>
        <div class="info-item full-width"><span class="info-label">Purpose:</span><span class="info-value"><%= h(dash((String) first.get("purpose"))) %></span></div>
    </div>

    <table>
        <thead>
            <tr>
                <th style="width:6%">S.No</th>
                <th style="width:<%= isIssue ? "40" : "54" %>%">Item Name</th>
                <th style="width:10%">UOM</th>
                <% if (isIssue) { %><th style="width:14%">Bal Qty</th><% } %>
                <th style="width:14%">Req Qty</th>
                <th style="width:16%">Status</th>
            </tr>
        </thead>
        <tbody>
        <% int n = 1;
           for (Map<String, Object> r : rows) {
               String st = (String) r.get("status");
               String shown = viaPO ? "Approved" : (st != null ? st : "Pending");
               boolean ok = "Approved".equalsIgnoreCase(shown);
        %>
            <tr>
                <td><%= n++ %></td>
                <td class="item"><%= h(r.get("item_name")) %></td>
                <td><%= h(dash((String) r.get("UOM"))) %></td>
                <% if (isIssue) { %><td style="color:#FA6D16; font-weight:bold;"><%= r.get("balance_qty") %></td><% } %>
                <td style="font-weight:600"><%= h(r.get("qty")) %></td>
                <td style="color:<%= ok ? "#2e844a" : "#c23934" %>; font-weight:700"><%= h(shown) %></td>
            </tr>
        <% } %>
        </tbody>
    </table>

    <div class="signature-section">
        <div class="stamp-box"><% if (allApproved) { %><div class="stamp">Approved</div><% } %></div>
        <div class="sign-box">
            <div class="company-name">For SANDUR RESIDENTIAL SCHOOL</div>
            <div class="sign-title">Authorized Signatory</div>
        </div>
    </div>

    <div class="action-bar">
        
        <button class="btn <%= "A5".equals(paper) ? "primary" : "" %>" id="btnA5" onclick="printOn('A5')"><i class="fa fa-print"></i> Print A5</button>
        <button class="btn <%= "A4".equals(paper) ? "primary" : "" %>" id="btnA4" onclick="printOn('A4')"><i class="fa fa-print"></i> Print A4</button>
    </div>
<% } %>
</div>

<script>
// Switch the sheet + printer page size, then open the print dialog.
function setPaper(p) {
    document.body.classList.toggle('paper-a5', p === 'A5');
    document.body.classList.toggle('paper-a4', p === 'A4');
    document.getElementById('pageSize').textContent =
        '@page { size: ' + p + ' portrait; margin: ' + (p === 'A5' ? '8mm' : '12mm') + '; }';
    document.getElementById('btnA5').classList.toggle('primary', p === 'A5');
    document.getElementById('btnA4').classList.toggle('primary', p === 'A4');
}
function printOn(p) {
    setPaper(p);
    setTimeout(function () { window.print(); }, 50);
}
</script>
</body>
</html>
