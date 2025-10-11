<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
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
        width: auto;
        height: 200px;
        display: block;
        margin: 0 auto 10px;
    }

    h1, h2, h3, h4 {
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

    .not-approved {
        color: red;
        text-align: center;
        font-weight: bold;
        font-size: 22px;
        margin-top: 20px;
        text-transform: uppercase;
    }

    @media print {
        .container {
            box-shadow: none;
            border: none;
        }
        button {
            display: none;
        }
        .header img {
            height: 70px;
        }
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
if (indentNumber != null) {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = DBUtil.getConnection();

    PreparedStatement pst = con.prepareStatement(
        "SELECT indent_no, indent_date, item_name, qty, department, requested_by, status, purpose " +
        "FROM indent WHERE indent_no=?");
    pst.setString(1, indentNumber);
    ResultSet rs = pst.executeQuery();

    boolean hasRecords = false;
    String indentDate = "", department = "", requestedBy = "", status = "", purpose = "",Indentnext="";

    if (rs.next()) {
        hasRecords = true;
        indentDate = rs.getString("indent_date");
        department = rs.getString("department");
        requestedBy = rs.getString("requested_by");
        purpose = rs.getString("purpose");
        status = rs.getString("status");
        
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
            <th>Quantity</th>
            <th>Status</th>
        </tr>
<%
        int count = 1;
        do {
%>
        <tr>
            <td><%= count++ %></td>
            <td><%= rs.getString("item_name") %></td>
            <td><%= rs.getString("qty") %></td>
            <td><%= rs.getString("status") %></td>
        </tr>
<%
        } while (rs.next());
%>
    </table>

<%
    if ("Approved".equalsIgnoreCase(status)) {
%>
        <div class="footer">
            <p>For SANDUR RESIDENTIAL SCHOOL</p>
        </div>

        <div class="sign">
            <p><b>Ashiya Banu</b></p>
            <p>Authorised Signatory</p>
        </div>
<%
    } else {
%>
         <div class="footer">
            <p>For SANDUR RESIDENTIAL SCHOOL</p>
        </div>

        <div class="sign">
            
            <p>Authorised Signatory</p>
        </div>
<%
    }
%>

    <button class="print-btn" onclick="window.print()">Print Indent</button>

<%
    } else {
        out.println("<p style='text-align:center;color:red;font-size:16px;'>No Indent Found!</p>");
    }
    con.close();
}
%>

</div>
</body>
</html>
