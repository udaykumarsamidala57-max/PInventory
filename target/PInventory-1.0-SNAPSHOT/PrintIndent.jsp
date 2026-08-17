<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String indentNumber = request.getParameter("IndentNumber");
    String branch = (String) sess.getAttribute("branch");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Indent Details - Sandur Residential School</title>

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
* {
    box-sizing: border-box;
}

body {
    font-family: 'Poppins', 'Segoe UI', sans-serif;
    background-color: #f3f3f3;
    margin: 0;
    padding: 20px 0;
    color: #181818;
    -webkit-tap-highlight-color: transparent;
}

/* Container optimized for standard A4 portrait width */
.container {
    width: 100%;
    max-width: 210mm;
    margin: 0 auto;
    background: #ffffff;
    padding: 25px 30px;
    border-radius: 6px;
    border: 1px solid #c9c9c9;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
}

/* Header Banner */
.header {
    text-align: center;
    margin-bottom: 12px;
}

.header img {
    max-height: 85px;
    width: auto;
    display: block;
    margin: 0 auto 8px auto;
}

.document-title {
    text-align: center;
    color: #0176d3;
    margin: 12px 0 16px 0;
    font-size: 16px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.8px;
    border-top: 2px solid #0176d3;
    border-bottom: 2px solid #0176d3;
    padding: 6px 0;
}

/* Metadata Grid */
.indent-info {
    margin: 12px 0 20px 0;
    background: #fafaf9;
    border-radius: 4px;
    padding: 12px 16px;
    border: 1px solid #e5e5e5;
    border-left: 4px solid #0176d3;
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 8px 20px;
}

.indent-info .info-item {
    display: flex;
    font-size: 12.5px;
    line-height: 1.4;
}

.indent-info .info-label {
    font-weight: 700;
    color: #514f4d;
    min-width: 110px;
    text-transform: uppercase;
    font-size: 11px;
    letter-spacing: 0.4px;
}

.indent-info .info-value {
    color: #181818;
    font-weight: 500;
}

.indent-info .full-width {
    grid-column: 1 / -1;
}

/* Type Status Badges */
.badge-type {
    display: inline-block;
    padding: 2px 8px;
    font-size: 10.5px;
    font-weight: 700;
    border-radius: 12px;
    text-transform: uppercase;
    letter-spacing: 0.4px;
}

.badge-type-purchase {
    background-color: #eef4fe;
    color: #0176d3;
    border: 1px solid #aacbfa;
}

.badge-type-issue {
    background-color: #eaf5ea;
    color: #2e844a;
    border: 1px solid #a3d9b1;
}

/* Report Table */
.table-container {
    width: 100%;
    margin-top: 15px;
}

table {
    width: 100%;
    border-collapse: collapse;
    background: #fff;
    font-size: 12px;
}

th {
    background: #fafaf9;
    color: #514f4d;
    padding: 8px 6px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.3px;
    border-top: 1px solid #c9c9c9;
    border-bottom: 2px solid #c9c9c9;
    border-left: 1px solid #e5e5e5;
    border-right: 1px solid #e5e5e5;
    font-size: 11px;
    text-align: center;
}

td {
    border: 1px solid #e5e5e5;
    padding: 8px 6px;
    text-align: center;
    color: #181818;
    vertical-align: middle;
}

tr:nth-child(even) {
    background-color: #fafaf9;
}

/* Footer & Signature Structure */
.signature-section {
    margin-top: 40px;
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
}

.stamp-box {
    min-width: 120px;
}

.stamp {
    display: inline-block;
    padding: 6px 14px;
    border: 2px dashed #2e844a;
    color: #2e844a;
    font-weight: 700;
    font-size: 14px;
    text-transform: uppercase;
    border-radius: 4px;
    transform: rotate(-5deg);
    letter-spacing: 1px;
}

.sign-box {
    text-align: right;
    color: #181818;
}

.sign-box .company-name {
    font-weight: 700;
    font-size: 12px;
    color: #514f4d;
    margin-bottom: 45px;
}

.sign-box .sign-title {
    font-weight: 600;
    font-size: 12px;
    border-top: 1px solid #181818;
    padding-top: 4px;
    display: inline-block;
}

/* Action Controls */
.action-bar {
    margin-top: 25px;
    display: flex;
    justify-content: center;
    gap: 12px;
}

.btn {
    height: 36px;
    padding: 0 20px;
    border: 1px solid #0176d3;
    background: #0176d3;
    color: white;
    border-radius: 4px;
    cursor: pointer;
    font-size: 12px;
    font-weight: 600;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    transition: background-color 0.15s ease;
}

.btn:hover {
    background: #015a9e;
    border-color: #015a9e;
}

/* Strict A4 Portrait Print Styles */
@page {
    size: A4 portrait;
    margin: 12mm;
}

@media print {
    html, body {
        width: 210mm;
        height: 297mm;
        background-color: #ffffff;
        padding: 0;
        margin: 0;
    }
    .container {
        width: 100%;
        max-width: 100%;
        border: none;
        box-shadow: none;
        padding: 0;
        margin: 0;
    }
    .action-bar {
        display: none !important;
    }
    .header img {
        max-height: 75px;
    }
    th {
        background-color: #f3f3f3 !important;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }
}
</style>
</head>
<body>

<div class="container">
    <div class="header">
        <img src="Header.png" alt="School Logo">
    </div>

    <div class="document-title">Indent Details</div>

<%
if (indentNumber != null && !indentNumber.trim().isEmpty()) {
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DBUtil.getConnection(branch);

        PreparedStatement pst = con.prepareStatement(
            "SELECT i.indent_no, i.PurchaseorIssue, i.indent_date, i.item_name, i.qty, i.department, i.requested_by, " +
            "i.status, i.purpose, i.Indentnext, COALESCE(s.balance_qty, 0) AS balance_qty, " +
            "m.UOM " +
            "FROM indent i " +
            "LEFT JOIN stock s ON i.item_id = s.item_id " +
            "LEFT JOIN item_master m ON i.item_id = m.Item_id " +
            "WHERE i.indent_no = ?"
        );
        pst.setString(1, indentNumber);
        ResultSet rs = pst.executeQuery();

        boolean hasRecords = false;
        String indentDate = "", department = "", requestedBy = "", purpose = "", indentNext = "", PurchaseorIssue = "";
        boolean allApproved = true;
        int count = 1;

        if (rs.next()) {
            hasRecords = true;
            indentDate = rs.getString("indent_date");
            department = rs.getString("department");
            requestedBy = rs.getString("requested_by");
            purpose = rs.getString("purpose");
            indentNext = rs.getString("Indentnext");
            PurchaseorIssue = rs.getString("PurchaseorIssue");

            if (indentNext != null && indentNext.trim().equalsIgnoreCase("PO")) {
                allApproved = true;
            }

            String formattedDate = "-";
            if (indentDate != null && !indentDate.trim().isEmpty()) {
                try {
                    formattedDate = LocalDate.parse(indentDate)
                                    .format(DateTimeFormatter.ofPattern("dd MMMM yyyy"));
                } catch (Exception parseEx) {
                    formattedDate = indentDate; 
                }
            }

            String badgeClass = "badge-type-purchase";
            if ("Issue".equalsIgnoreCase(PurchaseorIssue)) {
                badgeClass = "badge-type-issue";
            }
%>

    <div class="indent-info">
        <div class="info-item">
            <span class="info-label">Indent No:</span>
            <span class="info-value"><%= indentNumber %></span>
        </div>
        <div class="info-item">
            <span class="info-label">Indent Date:</span>
            <span class="info-value"><%= formattedDate %></span>
        </div>
        <div class="info-item">
            <span class="info-label">Department:</span>
            <span class="info-value"><%= (department != null && !department.isEmpty()) ? department : "-" %></span>
        </div>
        <div class="info-item">
            <span class="info-label">Requested By:</span>
            <span class="info-value"><%= (requestedBy != null && !requestedBy.isEmpty()) ? requestedBy : "-" %></span>
        </div>
       
        <div class="info-item">
            <span class="info-label">Type:</span>
            <span class="info-value">
                <span class="badge-type <%= badgeClass %>">
                    <%= (PurchaseorIssue != null && !PurchaseorIssue.isEmpty()) ? PurchaseorIssue : "-" %>
                </span>
            </span>
        </div>
        
        <div class="info-item full-width">
            <span class="info-label">Purpose:</span>
            <span class="info-value"><%= (purpose != null && !purpose.isEmpty()) ? purpose : "-" %></span>
        </div>
    </div>

    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th style="width: 6%;">S.No</th>
                    <th style="width: 40%;">Item Name</th>
                    <th style="width: 10%;">UOM</th>
                    <% if ("Issue".equalsIgnoreCase(PurchaseorIssue)) { %>
                    <th style="width: 14%;">Bal Qty</th>
                    <% } %>
                    <th style="width: 14%;">Req Qty</th>
                    <th style="width: 16%;">Status</th>
                </tr>
            </thead>
            <tbody>
<%
            do {
                String itemStatus = rs.getString("status");
                if ((itemStatus == null || !"Approved".equalsIgnoreCase(itemStatus.trim()))
                        && (indentNext == null || !indentNext.equalsIgnoreCase("PO"))) {
                    allApproved = false;
                }

                String displayStatus = (indentNext != null && indentNext.equalsIgnoreCase("PO")) ? "Approved" : (itemStatus != null ? itemStatus : "Pending");
                String statusStyle = "Approved".equalsIgnoreCase(displayStatus) ? "color:#2e844a; font-weight:700;" : "color:#c23934; font-weight:700;";
%>
                <tr>
                    <td><%= count++ %></td>
                    <td style="text-align: left;"><%= rs.getString("item_name") %></td>
                    <td><%= rs.getString("UOM") != null ? rs.getString("UOM") : "-" %></td>
                      <% if ("Issue".equalsIgnoreCase(PurchaseorIssue)) { %>
                      <td style="color:#FA6D16; font-weight:bold;">
                      <%= rs.getBigDecimal("balance_qty") %>
                      </td>
                      <% } %>
                    <td style="font-weight: 600;"><%= rs.getString("qty") %></td>
                    <td style="<%= statusStyle %>"><%= displayStatus %></td>
                </tr>
<%
            } while (rs.next());
%>
            </tbody>
        </table>
    </div>

    <div class="signature-section">
        <div class="stamp-box">
<%
        if (allApproved) {
%>
            <div class="stamp">Approved</div>
<%
        }
%>
        </div>
        <div class="sign-box">
            <div class="company-name">For SANDUR RESIDENTIAL SCHOOL</div>
            <div class="sign-title">Authorized Signatory</div>
        </div>
    </div>

    <div class="action-bar">
        <button class="btn" onclick="window.print()">
            <i class="fa fa-print"></i> Print Indent
        </button>
    </div>

<%
        } else {
            out.println("<div style='text-align:center; padding:20px 0; color:#c23934; font-weight:600; font-size:12px;'>No record found for this indent number.</div>");
        }

        rs.close();
        pst.close();
        con.close();

    } catch (Exception e) {
        out.println("<div style='text-align:center; padding:15px; color:#c23934; font-size:12px;'>Error rendering report: " + e.getMessage() + "</div>");
        e.printStackTrace();
    }
} else {
    out.println("<div style='text-align:center; padding:20px 0; color:#c23934; font-weight:600; font-size:12px;'>Invalid or missing Indent Number parameter.</div>");
}
%>

</div>

</body>
</html>