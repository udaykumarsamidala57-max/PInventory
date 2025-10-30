<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%@ page session="true" %>
<%
    HttpSession sesso = request.getSession(false);
    if (sesso == null || sesso.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String users = (String) sesso.getAttribute("username");
    String roles = (String) sesso.getAttribute("role");
    String depts = (String) sesso.getAttribute("department");
%>

<!-- HEADER -->

<style>

.user-info {
    display: inline-block;
    background:  #007bff !important;;  /* heading background */
      
    
    color: white !important;
    padding: 10px 20px;
    border-radius: 8px;
    cursor: pointer;
    font-size: 20px;
    font-weight: bold;
    overflow: hidden;
    transition: all 0.3s ease;
    position: relative;
}

/* Role is hidden initially */
.user-role {
   color: white;
    max-height: 0;
    opacity: 0;
    overflow: hidden;
    transition: max-height 0.4s ease, opacity 0.4s ease;
    font-size: 16px;
    font-weight: normal;
    margin-top: 8px;
}

/* On hover/touch, expand */
.user-info:hover .user-role,
.user-info:focus .user-role {
    max-height: 100px; /* enough to show role */
    opacity: 1;
}
</style>
<head>
    <meta charset="UTF-8">
    <title>SRS System - Indent List</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
</head>

<header>

    <img src="logo.png" alt="Logo" style="max-height:60px;">
    <div class="user-info">
        <strong><%= users.toUpperCase() %></strong><br>
        Role: <%= roles.toUpperCase() %>
    </div>
</header>

<!-- SIDEBAR -->
<div class="sidebar">
    <h2>Navigation</h2>
    <a href="Home"><i class="fas fa-home"></i> Home</a>

    <a href="IndentServlet"><i class="fas fa-file-alt"></i> Item Requisition Form</a>
   <% if ("Global".equalsIgnoreCase(roles)||"Incharge".equalsIgnoreCase(roles)||"Admin".equalsIgnoreCase(roles)) { %>
    <a href="AIndentListServlet"><i class="fas fa-check-circle"></i> Approve Indent</a>
    <%} %>
    <a href="IndentlistServlet"><i class="fas fa-list"></i> Indent Report</a>
     <% if ("Global".equalsIgnoreCase(roles)||"Finance".equalsIgnoreCase(depts) ) {%>
    <a href="IndentPO"><i class="fas fa-shopping-cart"></i>Create Purchase Order</a>
    <%} %>
    <% if ("Global".equalsIgnoreCase(roles)||"Finance".equalsIgnoreCase(depts) ) {%>
    <a href="POListServlet"><i class="fas fa-check-circle"></i> Approve PO</a>
    <%} %>
    <% if ("Global".equalsIgnoreCase(roles)||"Finance".equalsIgnoreCase(depts) ) {%>
    <a href="GRNServlet"><i class="fas fa-shopping-cart"></i> GRN Entry</a>
     <%} %>
      <% if ("Global".equalsIgnoreCase(roles)||"Store".equalsIgnoreCase(depts) ) {%>
    <a href="IssueServlet"><i class="fas fa-box"></i> Issue Items</a>
    <%} %>
    <a href="Issuereport.jsp"><i class="fas fa-chart-line"></i> Issue Report</a>
    <a href="Stock.jsp"><i class="fas fa-chart-line"></i> Stock Report</a>
    <a href="stockReport.jsp"><i class="fas fa-chart-line"></i> Stock Ledger Report</a>
    <% if ("Global".equalsIgnoreCase(roles)||"Finance".equalsIgnoreCase(depts) ) {%>
      <a href="IssueValueReport.jsp"><i class="fas fa-chart-line"></i>Consumption Dash Board</a>
       <%} %>
    <% if ("Global".equalsIgnoreCase(roles)) {%>
    <a href="ItemsMaster.jsp"><i class="fas fa-file-alt"></i> Item Master</a>
    <%} %>
    <% if ("Global".equalsIgnoreCase(roles)) {%>
    <a href="AddStock"><i class="fas fa-file-alt"></i> Add Stock</a>
   <%} %>
    <% if ("Global".equalsIgnoreCase(roles)||"Finance".equalsIgnoreCase(depts)) {%>
    <a href="VendorMaster.jsp"><i class="fas fa-file-alt"></i> Vendor Master</a>
   <%} %>
   
    <a href="Logout.jsp"><i class="fas fa-sign-out-alt"></i> Logout</a>
</div>


</body>
</html>