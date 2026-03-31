<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String poNumber = request.getParameter("poNumber");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Purchase Order - Sandur Residential School</title>
    <style>
        body {
            font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
            margin: 30px 60px;
            background-color: #f9fbfd;
            color: #1a1a1a;
            line-height: 1.6;
        }
        header {
            text-align: center;
            border-bottom: 3px solid #003366;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        header img { height: 100px; }
        header h6 { font-weight: normal; margin: 2px 0; color: #444; }
        .contact-line {
            text-align: center;
            font-size: 13px;
            color: #555;
            border-bottom: 1px dashed #aaa;
            margin-bottom: 20px;
            padding-bottom: 5px;
        }
        h3 {
            text-align: center;
            color: #003366;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-top: 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            font-size: 14px;
            background: white;
            box-shadow: 0 2px 6px rgba(0,0,0,0.08);
        }
        th, td { border: 1px solid #ccc; padding: 8px 10px; }
        thead {
            background: linear-gradient(90deg, #003366, #00509e);
            color: #fff;
            text-align: center;
            font-weight: 600;
        }
        td { text-align: left; }
        .summary {
            margin-top: 20px;
            width: 40%;
            float: right;
            border: 1px solid #ccc;
            background: #fff;
            box-shadow: 0 1px 4px rgba(0,0,0,0.1);
        }
        .summary td { font-weight: 600; border: none; padding: 6px 10px; }
        .summary tr td:first-child {
            text-align: right;
            width: 70%;
            color: #003366;
        }
        .section-title {
            margin-top: 40px;
            font-weight: bold;
            color: #003366;
            text-decoration: underline;
        }
        .signature {
            clear: both;
            text-align: right;
            margin-top: 80px;
            color: #000;
            position: relative;
        }
        .stamp {
            display: inline-block;
            margin-top: 15px;
            padding: 6px 14px;
            border: 2px solid #28a745;
            color: #28a745;
            font-weight: bold;
            font-size: 20px;
            text-transform: uppercase;
            border-radius: 6px;
            transform: rotate(-8deg);
            box-shadow: 2px 2px 6px rgba(0,0,0,0.2);
            background: rgba(40,167,69,0.1);
        }
        .print-btn {
            display: block;
            margin: 40px auto 20px;
            padding: 10px 30px;
            background: linear-gradient(90deg, #003366, #00509e);
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 15px;
            cursor: pointer;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
        }
        .print-btn:hover { background: #001f4d; }
        @media print { .print-btn { display: none !important; } }
    </style>
</head>
<body>

<%
if (poNumber != null && !poNumber.trim().isEmpty()) {
    try (Connection con = DBUtil.getConnection()) {

       
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
    <h6>Website: <strong>www.sandurschool.edu.in</strong> | Email: <strong>srsadmin@sandurschool.com</strong> | Ph: 08395-260246</h6>
</header>

<div class="contact-line"></div>
<h3>Purchase Order</h3>

<table>
    <tr>
        <td><b>PO Number:</b> <%= rsPO.getString("po_number") %><br>
        <b>Date:</b> <%= rsPO.getString("po_date") %></td>
    </tr>
    <tr>
        <td>
            <b>Vendor Name:</b> <%= rsPO.getString("vendor_name") %><br>
            <b>GSTIN:</b> <%= rsPO.getString("vendor_gstin") %><br>
            <b>Vendor Address:</b> <%= rsPO.getString("vendor_address") %>
        </td>
    </tr>
</table>

<p>We are pleased to place our order for the supply of the below items on the terms and conditions mentioned below:</p>

<%
    
    PreparedStatement pstItems = con.prepareStatement(
        "SELECT i.description, i.qty, i.rate, i.amount, i.discount_percent, i.discount_value, " +
        "i.gst_percent, i.gst_value, i.net_amount, m.UOM " +
        "FROM po_items i LEFT JOIN item_master m ON i.item_id = m.Item_id WHERE i.po_no=?"
    );
    pstItems.setString(1, poNumber);
    ResultSet rsItems = pstItems.executeQuery();
%>

<table>
    <thead>
        <tr>
            <th>Sl.No</th>
            <th>Item Description</th>
            <th>UOM</th>
            <th>Qty</th>
            <th>Rate</th>
            <th>Amount</th>
            <th>Disc %</th>
            <th>Disc Value</th>
            <th>GST %</th>
            <th>GST Value</th>
            <th>Net Amount</th>
        </tr>
    </thead>
    <tbody>
    <%
        int sl = 1;
        while (rsItems.next()) {
    %>
        <tr>
            <td style="text-align:center;"><%= sl++ %></td>
            <td><%= rsItems.getString("description") %></td>
            <td style="text-align:center;"><%= rsItems.getString("UOM") != null ? rsItems.getString("UOM") : "-" %></td>
            <td style="text-align:right;"><%= rsItems.getInt("qty") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("rate") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("amount") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("discount_percent") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("discount_value") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("gst_percent") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("gst_value") %></td>
            <td style="text-align:right;"><%= String.format("%.2f", rsItems.getDouble("net_amount")) %></td>
        </tr>
    <%
        }
        rsItems.close();
        pstItems.close();
    %>
    </tbody>
</table>

<table class="summary">
    <tr>
        <td>Total Discount:</td>
        <td style="text-align:right;"><%= rsPO.getString("total_dis") %></td>
    </tr>
    <tr>
        <td>Total GST:</td>
        <td style="text-align:right;"><%= rsPO.getString("total_gst") %></td>
    </tr>
    <% if (serviceCharge != null && !serviceCharge.trim().equals("") && !serviceCharge.trim().equals("0")) { %>
    <tr>
        <td>Service Charges:</td>
        <td style="text-align:right;"><%= serviceCharge %></td>
    </tr>
    <% } %>
    <tr>
        <td><b>Grand Total:</b></td>
        <td style="text-align:right;"><b><%= rsPO.getString("total_amount") %></b></td>
    </tr>
</table>

<div style="clear:both;"></div>

<h4 class="section-title">Terms and Conditions</h4>
<p><%= rsPO.getString("terms_conditions") %></p>

<h4 class="section-title">General Conditions</h4>
<p><%= rsPO.getString("general_conditions") %></p>

<div class="signature">
    <p><b>For Sandur Residential School</b></p>
    <br><br><br>
    <p><b>Authorized Signatory</b></p>

    <% if ("Approved".equalsIgnoreCase(approvalStatus)) { %>
        <p class="stamp">Approved</p>
    <% } %>
</div>



<%
        } else {
            out.println("<p style='color:red;text-align:center;'>No Purchase Order Found!</p>");
        }
    } catch (Exception e) {
        out.println("<p style='color:red;'>Error: " + e.getMessage() + "</p>");
    }
}
%>

<button class="print-btn" onclick="window.print()">🖨 Print / Save as PDF</button>

</body>
</html>
