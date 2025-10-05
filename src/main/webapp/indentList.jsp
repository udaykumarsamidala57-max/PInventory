<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.bean.Indentlist" %>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Indent Records</title>
<head>
    <meta charset="UTF-8">
    <title>SRS System - Indent List</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">
</head>

<body>

<%@ include file="header.jsp" %>

    <!-- Main Content -->
   <div class="main-content">
        <div class="card">
<h2 style="text-align:center;">Indent Records</h2>

<table id="dataTable" class="main-table">
    <tr>
     <thead>
        <th>ID</th>
        <th onclick="sortTable(0)">Indent No</th>
        <th onclick="sortTable(1)">Date</th>
        <th onclick="sortTable(2)">Item</th>
        <th onclick="sortTable(3)">Quantity</th>
        <th onclick="sortTable(4)">UOM</th>
        <th onclick="sortTable(5)">Department</th>
        <th onclick="sortTable(6)">Requested By</th>
        <th onclick="sortTable(7)">Purpose</th>
        <th onclick="sortTable(8)">Final Approval</th>
        <th>View / Print</th>
        </thead>
    </tr>

    <%
        List<Indentlist> indents = (List<Indentlist>) request.getAttribute("indents");
        if (indents != null && !indents.isEmpty()) {
            for (Indentlist ind : indents) {
    %>
        <tr>
            <td><%= ind.getIndentId() %></td>
            <td><%= ind.getIndentNo() %></td>
            <td><%= ind.getIndentDate() %></td>
            <td><%= ind.getItemName() %></td>
            <td><%= ind.getQty() %></td>
            <td><%= ind.getUom() %></td>
            <td><%= ind.getDepartment() %></td>
            <td><%= ind.getRequestedBy() %></td>
            <td><%= ind.getPurpose() %></td>
            <td><%= ind.getStatus() %></td>
            <td>
                <form action="PrintIndent.jsp" method="get">
                    <input type="hidden" name="IndentNumber" value="<%= ind.getIndentNo() %>">
                    <input class="btn btn-info" type="submit" value="View / Print">
                </form>
            </td>
        </tr>
    <%
            }
        } else {
    %>
        <tr>
            <td colspan="11" style="text-align:center;color:red;">No records found</td>
        </tr>
    <%
        }
    %>
</table>

</div>
<jsp:include page="Footer.jsp" />
</body>
</html>
