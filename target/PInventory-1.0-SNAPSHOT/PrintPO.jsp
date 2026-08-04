<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String poNumber = request.getParameter("poNumber");
    String branch = (String) sess.getAttribute("branch");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Purchase Order - Sandur Residential School</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            font-family: 'Poppins', 'Segoe UI', sans-serif;
            margin: 0;
            padding: 30px 0;
            background-color: #f3f3f3;
            color: #181818;
            line-height: 1.5;
            -webkit-tap-highlight-color: transparent;
        }

        .container {
            width: 100%;
            max-width: 210mm;
            margin: 0 auto;
            background: #ffffff;
            padding: 30px 35px;
            border-radius: 6px;
            border: 1px solid #c9c9c9;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }

        /* Header Banner */
        header {
            text-align: center;
            margin-bottom: 10px;
        }

        header img {
            max-height: 80px;
            width: auto;
            display: block;
            margin: 0 auto 8px auto;
        }

        .contact-line {
            text-align: center;
            font-size: 11px;
            color: #514f4d;
            border-bottom: 1px solid #e5e5e5;
            padding-bottom: 8px;
            margin-bottom: 16px;
            font-weight: 500;
        }

        .document-title {
            text-align: center;
            color: #0176d3;
            margin: 10px 0 20px 0;
            font-size: 18px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
            border-top: 2px solid #0176d3;
            border-bottom: 2px solid #0176d3;
            padding: 6px 0;
        }

        /* Metadata & Vendor Grid */
        .details-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-bottom: 18px;
        }

        .info-card {
            background: #fafaf9;
            border: 1px solid #e5e5e5;
            border-radius: 4px;
            padding: 12px 16px;
            font-size: 12px;
        }

        .info-card-header {
            font-weight: 700;
            color: #0176d3;
            text-transform: uppercase;
            font-size: 11px;
            letter-spacing: 0.5px;
            margin-bottom: 8px;
            border-bottom: 1px solid #e5e5e5;
            padding-bottom: 4px;
        }

        .info-row {
            display: flex;
            margin-bottom: 4px;
        }

        .info-label {
            font-weight: 700;
            color: #514f4d;
            min-width: 100px;
        }

        .info-value {
            color: #181818;
            font-weight: 500;
        }

        .intro-text {
            font-size: 12px;
            color: #514f4d;
            margin-bottom: 15px;
            font-style: italic;
        }

        /* Items Table */
        .table-container {
            width: 100%;
            margin-top: 10px;
            overflow-x: auto;
        }

        table.items-table {
            width: 100%;
            border-collapse: collapse;
            background: #fff;
            font-size: 11.5px;
        }

        table.items-table th {
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
            font-size: 10px;
            text-align: center;
        }

        table.items-table td {
            border: 1px solid #e5e5e5;
            padding: 7px 6px;
            color: #181818;
            vertical-align: middle;
        }

        table.items-table tr:nth-child(even) {
            background-color: #fafaf9;
        }

        /* Summary Panel */
        .summary-wrapper {
            display: flex;
            justify-content: flex-end;
            margin-top: 15px;
        }

        .summary-card {
            width: 280px;
            background: #fafaf9;
            border: 1px solid #e5e5e5;
            border-radius: 4px;
            padding: 8px 12px;
        }

        .summary-row {
            display: flex;
            justify-content: space-between;
            font-size: 12px;
            padding: 4px 0;
            color: #514f4d;
        }

        .summary-row.grand-total {
            border-top: 2px solid #0176d3;
            margin-top: 4px;
            padding-top: 6px;
            font-size: 13px;
            font-weight: 700;
            color: #0176d3;
        }

        /* Conditions Sections */
        .section-title {
            margin-top: 25px;
            font-size: 12px;
            font-weight: 700;
            color: #0176d3;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 1px solid #0176d3;
            padding-bottom: 3px;
            display: inline-block;
        }

        .condition-text {
            font-size: 11.5px;
            color: #181818;
            margin: 6px 0 0 0;
            white-space: pre-wrap;
        }

        /* Signature Section */
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
            background: #eaf5ea;
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

        /* Controls */
        .action-bar {
            margin-top: 30px;
            display: flex;
            justify-content: center;
        }

        .btn {
            height: 38px;
            padding: 0 24px;
            border: 1px solid #0176d3;
            background: #0176d3;
            color: white;
            border-radius: 4px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: background-color 0.15s ease;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .btn:hover {
            background: #015a9e;
            border-color: #015a9e;
        }

        /* Strict Printable Layout Setup */
        @page {
            size: A4 portrait;
            margin: 12mm;
        }

        @media print {
            body {
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
            header img {
                max-height: 75px;
            }
            th {
                background-color: #fafaf9 !important;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
            .stamp {
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
        }
    </style>
</head>
<body>

<div class="container">

<%
if (poNumber != null && !poNumber.trim().isEmpty()) {
    try (Connection con = DBUtil.getConnection(branch)) {

        PreparedStatement pst = con.prepareStatement(
            "SELECT po_number, PO_date AS po_date, vendor_name, vendor_address, vendor_gstin, " +
            "total_gst, total_dis, total_amount, terms_conditions, general_conditions, " +
            "Servicecharge, Approval " +
            "FROM po_master WHERE po_number=?"
        );
        pst.setString(1, poNumber);
        ResultSet rsPO = pst.executeQuery();

        if (rsPO.next()) {
            String serviceCharge = rsPO.getString("Servicecharge");
            String approvalStatus = rsPO.getString("Approval");

            PreparedStatement updateIndent = con.prepareStatement(
                "UPDATE indent SET status = 'Approved' WHERE Indentnext = 'PO' AND status <> 'Approved'"
            );
            updateIndent.executeUpdate();
%>

<header>
    <img src="Header.png" alt="School Logo">
</header>

<div class="contact-line">
    Website: <strong>www.sandurschool.edu.in</strong> &nbsp;|&nbsp; Email: <strong>srsadmin@sandurschool.com</strong> &nbsp;|&nbsp; Ph: <strong>08395-260246</strong>
</div>

<div class="document-title">Purchase Order</div>

<div class="details-grid">
    <div class="info-card">
        <div class="info-card-header">Order Reference</div>
        <%
            String poDate = rsPO.getString("po_date");
            String formattedDate = "-";
            if(poDate != null && !poDate.trim().isEmpty()){
                try {
                    formattedDate = LocalDate.parse(poDate)
                                    .format(DateTimeFormatter.ofPattern("dd MMMM yyyy"));
                } catch(Exception ex) {
                    formattedDate = poDate;
                }
            }
        %>
        <div class="info-row">
            <span class="info-label">PO Number:</span>
            <span class="info-value"><%= rsPO.getString("po_number") %></span>
        </div>
        <div class="info-row">
            <span class="info-label">Date:</span>
            <span class="info-value"><%= formattedDate %></span>
        </div>
    </div>

    <div class="info-card">
        <div class="info-card-header">Vendor Details</div>
        <div class="info-row">
            <span class="info-label">Vendor Name:</span>
            <span class="info-value"><%= rsPO.getString("vendor_name") %></span>
        </div>
        <div class="info-row">
            <span class="info-label">GSTIN:</span>
            <span class="info-value"><%= rsPO.getString("vendor_gstin") != null ? rsPO.getString("vendor_gstin") : "-" %></span>
        </div>
        <div class="info-row">
            <span class="info-label">Address:</span>
            <span class="info-value"><%= rsPO.getString("vendor_address") %></span>
        </div>
    </div>
</div>

<p class="intro-text">We are pleased to place our order for the supply of the below items on the terms and conditions mentioned below:</p>

<%
    PreparedStatement pstItems = con.prepareStatement(
        "SELECT i.description, i.qty, i.rate, i.amount, i.discount_percent, i.discount_value, " +
        "i.gst_percent, i.gst_value, i.net_amount, m.UOM " +
        "FROM po_items i LEFT JOIN item_master m ON i.item_id = m.Item_id WHERE i.po_no=?"
    );
    pstItems.setString(1, poNumber);
    ResultSet rsItems = pstItems.executeQuery();
%>

<div class="table-container">
    <table class="items-table">
        <thead>
            <tr>
                <th style="width: 5%;">Sl.No</th>
                <th style="width: 25%;">Item Description</th>
                <th style="width: 8%;">UOM</th>
                <th style="width: 8%;">Qty</th>
                <th style="width: 9%;">Rate</th>
                <th style="width: 9%;">Amount</th>
                <th style="width: 7%;">Disc %</th>
                <th style="width: 9%;">Disc Val</th>
                <th style="width: 6%;">GST %</th>
                <th style="width: 8%;">GST Val</th>
                <th style="width: 10%;">Net Amt</th>
            </tr>
        </thead>
        <tbody>
        <%
            int sl = 1;
            while (rsItems.next()) {
        %>
            <tr>
                <td style="text-align:center;"><%= sl++ %></td>
                <td style="text-align:left;"><%= rsItems.getString("description") %></td>
                <td style="text-align:center;"><%= rsItems.getString("UOM") != null ? rsItems.getString("UOM") : "-" %></td>
                <td style="text-align:right;"><%= String.format("%.2f", rsItems.getDouble("qty")) %></td>
                <td style="text-align:right;"><%= String.format("%.2f", rsItems.getDouble("rate")) %></td>
                <td style="text-align:right;"><%= String.format("%.2f", rsItems.getDouble("amount")) %></td>
                <td style="text-align:right;"><%= String.format("%.2f", rsItems.getDouble("discount_percent")) %></td>
                <td style="text-align:right;"><%= String.format("%.2f", rsItems.getDouble("discount_value")) %></td>
                <td style="text-align:right;"><%= String.format("%.2f", rsItems.getDouble("gst_percent")) %></td>
                <td style="text-align:right;"><%= String.format("%.2f", rsItems.getDouble("gst_value")) %></td>
                <td style="text-align:right; font-weight:600;"><%= String.format("%.2f", rsItems.getDouble("net_amount")) %></td>
            </tr>
        <%
            }
            rsItems.close();
            pstItems.close();
        %>
        </tbody>
    </table>
</div>

<div class="summary-wrapper">
    <div class="summary-card">
        <div class="summary-row">
            <span>Total Discount:</span>
            <span><%= rsPO.getString("total_dis") %></span>
        </div>
        <div class="summary-row">
            <span>Total GST:</span>
            <span><%= rsPO.getString("total_gst") %></span>
        </div>
        <% if (serviceCharge != null && !serviceCharge.trim().equals("") && !serviceCharge.trim().equals("0")) { %>
        <div class="summary-row">
            <span>Service Charges:</span>
            <span><%= serviceCharge %></span>
        </div>
        <% } %>
        <div class="summary-row grand-total">
            <span>Grand Total:</span>
            <span><%= rsPO.getString("total_amount") %></span>
        </div>
    </div>
</div>

<div class="section-title">Terms and Conditions</div>
<p class="condition-text"><%= rsPO.getString("terms_conditions") %></p>

<div class="section-title">General Conditions</div>
<p class="condition-text"><%= rsPO.getString("general_conditions") %></p>

<div class="signature-section">
    <div class="stamp-box">
        <% if ("Approved".equalsIgnoreCase(approvalStatus)) { %>
            <div class="stamp">Approved</div>
        <% } %>
    </div>
    <div class="sign-box">
        <div class="company-name">For SANDUR RESIDENTIAL SCHOOL</div>
        <div class="sign-title">Authorized Signatory</div>
    </div>
</div>

<div class="action-bar">
    <button class="btn" onclick="window.print()">
        <i class="fa fa-print"></i> Print / Save as PDF
    </button>
</div>

<%
        } else {
            out.println("<p style='color:#c23934; text-align:center; font-weight:600; padding:30px 0;'>No Purchase Order Found!</p>");
        }
    } catch (Exception e) {
        out.println("<p style='color:#c23934; font-size:12px; padding:15px;'>Error rendering document: " + e.getMessage() + "</p>");
    }
}
%>

</div>

</body>
</html>