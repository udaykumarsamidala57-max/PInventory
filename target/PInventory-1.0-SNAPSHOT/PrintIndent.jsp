<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String indentNumber = request.getParameter("IndentNumber");
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Indent Details - Sandur Residential School</title>

<style>
    body {
        font-family: 'Segoe UI', Arial, sans-serif;
        background-color: #f7f9fb;
        margin: 0;
        padding: 0;
    }
    .container {
        width: 85%;
        margin: 30px auto;
        background: #fff;
        padding: 30px;
        border-radius: 12px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }
    .header {
        text-align: center;
        margin-bottom: 10px;
    }
    .header img {
        height: 200px;
        display: block;
        margin: 0 auto 10px;
    }
    h2 {
        text-align: center;
        color: #222;
        margin: 4px 0;
    }
    hr {
        border: none;
        border-top: 2px solid #007BFF;
        margin: 20px 0;
    }
    .indent-info {
        margin: 20px auto;
        width: 90%;
        background: #f1f7ff;
        border-radius: 8px;
        padding: 20px 25px;
        border-left: 4px solid #007BFF;
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 8px 40px;
    }
    .indent-info p {
        font-size: 15px;
        color: #333;
        margin: 5px 0;
    }
    table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 20px;
    }
    th, td {
        border: 1px solid #ddd;
        padding: 10px;
        text-align: center;
    }
    th {
        background: #007BFF;
        color: #fff;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
    tr:nth-child(even) {
        background: #f9f9f9;
    }
    .footer {
        margin-top: 40px;
        text-align: right;
        font-weight: bold;
        color: #444;
    }
    .sign {
        margin-top: 60px;
        text-align: right;
        font-weight: 500;
        color: #333;
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
    }
    @media print {
        .container { box-shadow: none; border: none; }
        button { display: none; }
        .header img { height: 70px; }
    }
    .print-btn {
        display: block;
        margin: 20px auto;
        background: #007BFF;
        color: #fff;
        border: none;
        padding: 10px 20px;
        border-radius: 6px;
        cursor: pointer;
        font-size: 15px;
    }
    .print-btn:hover {
        background: #0056b3;
    }
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <img src="Header.png" alt="School Logo">
    </div>
    <hr>
    <h2>Indent Details</h2>

<%
if (indentNumber != null && !indentNumber.trim().isEmpty()) {
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DBUtil.getConnection();

        PreparedStatement pst = con.prepareStatement(
            "SELECT i.indent_no, i.indent_date, i.item_name, i.qty, i.department, i.requested_by, " +
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
        String indentDate = "", department = "", requestedBy = "", purpose = "", indentNext = "";
        boolean allApproved = true;
        int count = 1;

        if (rs.next()) {
            hasRecords = true;
            indentDate = rs.getString("indent_date");
            department = rs.getString("department");
            requestedBy = rs.getString("requested_by");
            purpose = rs.getString("purpose");
            indentNext = rs.getString("Indentnext");

            // Treat as approved if Indentnext = 'PO'
            if (indentNext != null && indentNext.trim().equalsIgnoreCase("PO")) {
                allApproved = true;
            }
%>

    <div class="indent-info">
        <p><b>Indent No:</b> <%= indentNumber %></p>
        <p><b>Indent Date:</b> <%= indentDate %></p>
        <p><b>Department:</b> <%= department %></p>
        <p><b>Requested By:</b> <%= requestedBy %></p>
        <p style="grid-column: 1 / span 2;"><b>Purpose:</b> <%= purpose %></p>
    </div>

    <table>
        <tr>
            <th>S.No</th>
            <th>Item Name</th>
            <th>UOM</th>
            <th>Balance Qty</th>
            <th>Req. Quantity</th>
            <th>Status</th>
        </tr>

<%
            do {
                String itemStatus = rs.getString("status");
                if ((itemStatus == null || !"Approved".equalsIgnoreCase(itemStatus.trim()))
                        && (indentNext == null || !indentNext.equalsIgnoreCase("PO"))) {
                    allApproved = false;
                }
%>
        <tr>
            <td><%= count++ %></td>
            <td><%= rs.getString("item_name") %></td>
            <td><%= rs.getString("UOM") != null ? rs.getString("UOM") : "-" %></td>
            <td><%= rs.getBigDecimal("balance_qty") %></td>
            <td><%= rs.getString("qty") %></td>
            <td><%= (indentNext != null && indentNext.equalsIgnoreCase("PO")) ? "Approved" : (itemStatus != null ? itemStatus : "Pending") %></td>
        </tr>
<%
            } while (rs.next());
%>
    </table>

    <div class="footer">
        <p>For SANDUR RESIDENTIAL SCHOOL</p>
    </div>

    <div class="sign">
        <p><b>Authorized Signatory</b></p>
<%
        if (allApproved) {
%>
            <p class="stamp">Approved</p>
<%
        }
%>
    </div>

    <button class="print-btn" onclick="window.print()">Print Indent</button>

<%
        } else {
            out.println("<p style='text-align:center;color:red;font-size:16px;'>No Indent Found!</p>");
        }

        rs.close();
        pst.close();
        con.close();

    } catch (Exception e) {
        out.println("<p style='color:red;text-align:center;'>Error: " + e.getMessage() + "</p>");
        e.printStackTrace();
    }
} else {
    out.println("<p style='text-align:center;color:red;font-size:16px;'>Invalid Indent Number!</p>");
}
%>

</div>
</body>
</html>
