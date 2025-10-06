<%@ page import="com.bean.GRNItem, java.util.*" %>
<%
    String poNumber = (String) request.getAttribute("poNumber");
    String vendorName = (String) request.getAttribute("vendorName");
    List<GRNItem> items = (List<GRNItem>) request.getAttribute("items");
    String message = (String) request.getAttribute("message");
    String error   = (String) request.getAttribute("error");
%>
<html>
<head>
<title>Create GRN</title>
<meta charset="UTF-8">
    <title>SRS System - Indent List</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/Form.css">
</head>
<body>
<%@ include file="header.jsp" %>
<center></br></br></br>

<% if(message != null) { %>
    <p style="color:green;"><%= message %></p>
<% } %>
<% if(error != null) { %>
    <p style="color:red;"><%= error %></p>
<% } %>
<div class="main-content">
        <div class="card">
<form method="get" action="GRNServlet">
    Enter PO Number: <input name="po_number" required>
    <input type="submit" class="btn btn-info" value="Fetch PO">
</form>

<% if(poNumber != null) { %>
<h2>Create GRN for PO: <%= poNumber %></h2>
<p>Vendor: <%= vendorName %></p>

<form method="post" action="GRNServlet">
<input type="hidden" name="po_number" value="<%= poNumber %>">

<table class="main-table">
<tr><td>Invoice No:</td><td><input name="invoice_no" required></td></tr>
<tr><td>Invoice Date:</td><td><input type="date" name="invoice_date" required></td></tr>
<tr><td>Received By:</td><td><input name="received_by" required></td></tr>
</table>

<table class="main-table">
<tr>
<thead>
<th>Sl No</th><th>Description</th><th>Ordered</th>
<th>Already Received</th><th>Qty Received</th>
<th>Qty Accepted</th><th>Qty Rejected</th><th>Remarks</th>
</thead>
</tr>
<%
    int i=0;
    for(GRNItem item: items){
%>
<tr>
    <td><%= i+1 %></td>
    <td><%= item.getDescription() %></td>
    <td><%= item.getOrderedQty() %></td>
    <td><%= item.getAlreadyReceived() %></td>
    <td><input type="number" step="any" name="qty_received_<%=i%>" required min="0"></td>
<td><input type="number" step="any" name="qty_accepted_<%=i%>" required min="0"></td>
<td><input type="number" step="any" name="qty_rejected_<%=i%>" required min="0"></td>
    <td><input name="remarks_<%=i%>"></td>
<input type="hidden" name="description_<%=i%>" value="<%= item.getDescription() %>">

    <input type="hidden" name="po_item_id<%=i%>" value="<%= item.getPoItemId() %>">
    <input type="hidden" name="item_id<%=i%>" value="<%= item.getItemId() %>">
</tr>
<%
    i++;
%>
<% } %>
<input type="hidden" name="totalItems" value="<%= i %>">
<tr><td colspan="8"><input type="submit" class="btn btn-green" value="Save GRN"></td></tr>
</table>
</form>
<% } %>

</div>
<jsp:include page="Footer.jsp" />
</body>
</html>
