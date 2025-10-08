<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%
    String poNumber = request.getParameter("poNumber");
%>
<html>
<head>
    <title>Purchase Order - Sandur Residential School</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            margin: 30px 50px;
            color: #000;
            background: #fff;
        }
        h2, h3, h5, h6 {
            text-align: center;
            margin: 5px 0;
        }
        h2 {
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            font-size: 14px;
        }
        th, td {
            border: 1px solid #000;
            padding: 6px 8px;
        }
        th {
            background: #f1f1f1;
            text-align: center;
        }
        td {
            text-align: left;
        }
        .print-btn {
            display: block;
            margin: 30px auto;
            padding: 10px 25px;
            background: #007BFF;
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 15px;
            cursor: pointer;
        }
        .print-btn:hover {
            background: #0056b3;
        }
        .tab {
            display: inline-block;
            margin-left: 280px;
        }
        .summary td {
            font-weight: bold;
        }
        .signature {
            text-align: right;
            margin-top: 60px;
        }
        @media print {
            .print-btn { display: none; }
            body { margin: 10mm; }
        }
    </style>
</head>
<body>

<%
if (poNumber != null) {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = DBUtil.getConnection();

    PreparedStatement pst = con.prepareStatement(
        "SELECT po_number, po_date, vendor_name, vendor_address, total_gst, total_dis, total_amount, terms_conditions, general_conditions " +
        "FROM po_master WHERE po_number=?");
    pst.setString(1, poNumber);
    ResultSet rsPO = pst.executeQuery();

    if (rsPO.next()) {
%>
<img src="Header.png" alt="School Logo">
   
    <h6>Website: www.sandurschool.edu.in</h6>
    <h6>Email: srsadmin@sandurschool.com <span class="tab"></span> Ph: 08395-260246</h6>

    <h3>Purchase Order</h3>

    <table>
        <tr>
            <td><b>PO Number:</b> <%= rsPO.getString("po_number") %></td>
            <td><b>Date:</b> <%= rsPO.getString("po_date") %></td>
        </tr>
        <tr>
            <td><b>Vendor:</b> <%= rsPO.getString("vendor_name") %></td>
            <td><b>Address:</b> <%= rsPO.getString("vendor_address") %></td>
        </tr>
    </table>

    <%
        PreparedStatement pstItems = con.prepareStatement(
            "SELECT description, qty, rate, amount, discount_percent, discount_value, gst_percent, gst_value, net_amount " +
            "FROM po_items WHERE po_no=?");
        pstItems.setString(1, poNumber);
        ResultSet rsItems = pstItems.executeQuery();
    %>

    <table>
        <tr>
            <th>Sl.No</th>
            <th>Item Description</th>
            <th>Qty</th>
            <th>Rate</th>
            <th>Amount</th>
            <th>Disc %</th>
            <th>Disc Value</th>
            <th>GST %</th>
            <th>GST Value</th>
            <th>Net Amount</th>
        </tr>
        <%
            int sl = 1;
            while (rsItems.next()) {
        %>
        <tr>
            <td style="text-align:center;"><%= sl++ %></td>
            <td><%= rsItems.getString("description") %></td>
            <td style="text-align:right;"><%= rsItems.getInt("qty") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("rate") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("amount") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("discount_percent") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("discount_value") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("gst_percent") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("gst_value") %></td>
            <td style="text-align:right;"><%= rsItems.getDouble("net_amount") %></td>
        </tr>
        <% } %>
    </table>

    <table class="summary">
        <tr>
            <td style="width:70%; text-align:right;">Total Discount:</td>
            <td style="text-align:right;"><%= rsPO.getString("total_dis") %></td>
        </tr>
        <tr>
            <td style="text-align:right;">Total GST:</td>
            <td style="text-align:right;"><%= rsPO.getString("total_gst") %></td>
        </tr>
        <tr>
            <td style="text-align:right;">Grand Total:</td>
            <td style="text-align:right;"><%= rsPO.getString("total_amount") %></td>
        </tr>
    </table>

    <h4>Terms and Conditions</h4>
    <p><%= rsPO.getString("terms_conditions") %></p>

    <h4>General Conditions</h4>
    <p><%= rsPO.getString("general_conditions") %></p>

    <div class="signature">
        <p><b>for SANDUR RESIDENTIAL SCHOOL</b></p>
        <br><br><br>
        <p><b>Authorised Signatory</b></p>
    </div>

<%
    } else {
        out.println("<p style='color:red;text-align:center;'>No Purchase Order Found!</p>");
    }
    con.close();
}
%>

    <button class="print-btn" onclick="window.print()">Print / Save as PDF</button>
</body>
</html>
