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
<head>
    <meta charset="UTF-8">
    <title>SRS System - Indent List</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <style>
    .user-info {
        display: inline-block;
        background: #007bff !important;
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

    .user-info:hover .user-role,
    .user-info:focus .user-role {
        max-height: 100px;
        opacity: 1;
    }

    /* Sidebar Dropdown Styling */
    .sidebar .dropdown {
        position: relative;
    }

    .sidebar .dropdown-btn {
        display: block;
        width: 100%;
        text-align: left;
        background: none;
        border: none;
        color: black;
        font-size: 16px;
        padding: 10px 15px;
        cursor: pointer;
        font-family: 'Poppins', sans-serif;
        transition: background 0.3s, color 0.3s;
    }

    .sidebar .dropdown-btn:hover {
        background: #007bff;
        color: white;
    }

    .sidebar .dropdown-btn i {
        margin-right: 8px;
    }

    /* Submenu Styling - Clean, White & Professional */
    .sidebar .dropdown-content {
        display: none;
        background: #ffffff; /* white background */
        padding-left: 10px;
        border-left: 3px solid #007bff; /* subtle blue border */
    }

    .sidebar .dropdown-content a {
        display: block;
        color: #000; /* black text */
        text-decoration: none;
        padding: 8px 15px;
        font-size: 14px;
        border-radius: 4px;
        transition: background 0.3s, color 0.3s;
    }

    .sidebar .dropdown-content a:hover {
        background: #007bff;
        color: white;
    }

    /* Active dropdown (open state) */
    .sidebar .dropdown.active .dropdown-content {
        display: block;
    }
    </style>
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

    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-file-alt"></i> Indent <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <a href="IndentServlet">Item Requisition Form</a>
            <a href="IndentlistServlet">Indent Report</a>
            <% if ("Global".equalsIgnoreCase(roles) || "Incharge".equalsIgnoreCase(roles) || "Admin".equalsIgnoreCase(roles)) { %>
                <a href="AIndentListServlet">Approve Indent</a>
            <% } %>
        </div>
    </div>

    <% if ("Global".equalsIgnoreCase(roles)) { %>
    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-box-open"></i> Issue <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <a href="IssueApprove">Approve Issue</a>
            <a href="IssueServlet">Issue Items</a>
            <a href="Issuereport.jsp">Issue Report</a>
        </div>
    </div>
    <% } %>

    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-shopping-cart"></i> Purchase / PO <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts)) { %>
                <a href="IndentPO">Create Purchase Order</a>
                <a href="GRNServlet">GRN Entry</a>
                <a href="VendorMaster.jsp">Vendor Master</a>
            <% } %>
            <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts) || "Store".equalsIgnoreCase(depts)) { %>
                <a href="POListServlet">Approve PO</a>
                <a href="ListPO.jsp">PO Report</a>
            <% } %>
        </div>
    </div>

    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-chart-line"></i> Reports <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <a href="Stock.jsp">Stock Report</a>
            <a href="stockReport.jsp">Stock Ledger Report</a>
            <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts)) { %>
                <a href="IssueValueReport.jsp">Consumption Dash Board</a>
            <% } %>
        </div>
    </div>

    <% if ("Global".equalsIgnoreCase(roles)) { %>
    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-cog"></i> Masters <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <a href="ItemsMaster.jsp">Item Master</a>
            <a href="AddStock">Add Stock</a>
        </div>
    </div>
    <% } %>

    <% if ("Global".equalsIgnoreCase(roles)) { %>
    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-cog"></i> Asset Management <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <a href="">Fixed Assets</a>
            <a href="">BarCode Generator</a>
        </div>
    </div>
    <% } %>

    <a href="Logout.jsp"><i class="fas fa-sign-out-alt"></i> Logout</a>
</div>

<script>
document.querySelectorAll(".dropdown-btn").forEach(btn => {
  btn.addEventListener("click", function() {
    this.parentElement.classList.toggle("active");
  });
});
</script>
