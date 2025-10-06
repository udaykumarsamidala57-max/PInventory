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
<style>
.user-info {
    display: inline-block;
    background: #4a90e2;   /* heading background */
    color: #fff;
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
</head>

<header>

    <img src="logo.png" alt="Logo" style="max-height:90px;">
    <div class="user-info">
        <strong><%= users.toUpperCase() %></strong><br>
        Role: <%= roles.toUpperCase() %>
    </div>
</header>

<!-- SIDEBAR -->
<div class="sidebar">
    <h2>Quick Links</h2>
    <a href="home.jsp"><i class="fas fa-home"></i> Home</a>
    <a href="IndentServlet"><i class="fas fa-file-alt"></i> Indent Form</a>
    <a href="AIndentListServlet"><i class="fas fa-check-circle"></i> Approve Indent</a>
    <a href="IndentlistServlet"><i class="fas fa-list"></i> Indent Report</a>
    <a href="IndentPO"><i class="fas fa-shopping-cart"></i> Purchase Order</a>
    <a href="POListServlet"><i class="fas fa-shopping-cart"></i> Approve PO</a>
    <a href="GRNServlet"><i class="fas fa-shopping-cart"></i> GRN Entry</a>
    <a href="IssueServlet"><i class="fas fa-box"></i> Issue Items</a>
    <a href="Vendor.jsp"><i class="fas fa-truck"></i> Vendor Master</a>
    <a href="Reports.jsp"><i class="fas fa-chart-line"></i> Reports</a>
    <a href="Logout.jsp"><i class="fas fa-sign-out-alt"></i> Logout</a>
</div>


</body>
</html>