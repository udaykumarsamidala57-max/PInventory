<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.bean.IndentItems" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SRS System - Indent List</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">
</head>
<body>
<%@ include file="header.jsp" %>
<div class="main-content">
        <div class="card">
<h2 style="text-align:center;">Indent Records</h2>

<form method="get" action="<%=request.getContextPath()%>/PurchaseOrderServlet">
<table class="main-table">
<tr>
<thead>
    <th>Select</th>
    <th>ID</th>
    <th>Indent No</th>
    <th>Date</th>
    <th>Item</th>
    <th>Quantity</th>
    <th>Department</th>
    <th>Requested By</th>
    <th>Purpose</th>
    <th>Istatus</th>
    <th>Approved By</th>
    <th>Status</th>
  </thead>  
    
</tr>

<%
List<IndentItems> indentList = (List<IndentItems>) request.getAttribute("indentList");
if (indentList != null && !indentList.isEmpty()) {
    for (IndentItems ind : indentList) {
%>
<tr>
    <td><input type="checkbox" name="selectedIds" value="<%= ind.getId() %>"></td>
    <td><%= ind.getId() %></td>
    <td><%= ind.getIndentNo() %></td>
    <td><%= ind.getIndentDate() %></td>
    <td><%= ind.getItemName() %></td>
    <td><%= ind.getQty() %></td>
    <td><%= ind.getDepartment() %></td>
    <td><%= ind.getRequestedBy() %></td>
    <td><%= ind.getPurpose() %></td>
    <td><%= ind.getIstatus() %></td>
    <td><%= ind.getIstatusApprove() %></td>
    <td><%= ind.getStatus() %></td>
</tr>
<%
    }
} else {
%>
<tr>
    <td colspan="13" style="color:red; text-align:center;">No records found</td>
</tr>
<%
}
%>

<tr>
<td colspan="13" style="text-align:center;">
    <input type="submit" class="btn btn-info" value="Process Selected Indents">
</td>
</tr>
</table>
</form>
</div>

<jsp:include page="Footer.jsp" />
</body>
</html>
