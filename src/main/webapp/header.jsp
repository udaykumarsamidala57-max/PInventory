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
    body {
        font-family: 'Poppins', sans-serif;
        margin: 0;
        padding: 0;
    }

    header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        background: #fff;
        padding: 10px 20px;
        border-bottom: 2px solid #007bff;
    }

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

    /* Sidebar */
    .sidebar {
        width: 260px;
        background: #f8f9fa;
        padding: 15px;
        height: 100vh;
        overflow-y: auto;
        position: fixed;
        top: 0;
        left: 0;
        border-right: 2px solid #007bff;
    }

    .sidebar h2 {
        color: #007bff;
        text-align: center;
        margin-bottom: 20px;
    }

    .sidebar a,
    .sidebar button {
        display: block;
        color: #000;
        text-decoration: none;
        padding: 10px 15px;
        font-size: 16px;
        border-radius: 6px;
        transition: background 0.3s, color 0.3s;
        width: 100%;
        text-align: left;
        border: none;
        background: none;
        cursor: pointer;
        font-family: 'Poppins', sans-serif;
    }

    .sidebar a:hover,
    .sidebar button:hover {
        background: #007bff;
        color: white;
    }

    .dropdown-content {
        display: none;
        background: #ffffff;
        padding-left: 10px;
        border-left: 3px solid #007bff;
        border-radius: 4px;
        margin-top: 5px;
    }

    .dropdown-content a {
        font-size: 14px;
        padding: 8px 15px;
        display: block;
        border-radius: 4px;
    }

    .dropdown.active .dropdown-content {
        display: block;
    }

    /* Colorful icons */
    .text-primary { color:#007bff; }
    .text-success { color:#28a745; }
    .text-danger { color:#dc3545; }
    .text-warning { color:#ffc107; }
    .text-info { color:#17a2b8; }
    .text-secondary { color:#6c757d; }
    .text-purple { color:#6f42c1; }
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
<br>
<br><br><br><br>
<br>
<div class="sidebar">
    <h2><i class="fas fa-compass text-primary"></i> Navigation</h2>
    <a href="Home"><i class="fas fa-home text-success"></i> Home</a>

    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-file-alt text-primary"></i> Indent <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <a href="IndentServlet"><i class="fas fa-plus-circle text-success"></i> Item Requisition Form</a>
            <a href="IndentlistServlet"><i class="fas fa-list text-info"></i> Indent Report</a>
            <% if ("Global".equalsIgnoreCase(roles) || "Incharge".equalsIgnoreCase(roles) || "Admin".equalsIgnoreCase(roles)) { %>
                <a href="AIndentListServlet"><i class="fas fa-check-circle text-warning"></i> Approve Indent</a>
            <% } %>
        </div>
    </div>

    <% if ("Global".equalsIgnoreCase(roles)) { %>
    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-box-open text-warning"></i> Issue <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <a href="IssueApprove"><i class="fas fa-thumbs-up text-success"></i> Approve Issue</a>
            <a href="IssueServlet"><i class="fas fa-dolly text-info"></i> Issue Items</a>
            <a href="Issuereport.jsp"><i class="fas fa-file-invoice text-danger"></i> Issue Report</a>
        </div>
    </div>
    <% } %>

    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-shopping-cart text-danger"></i> Purchase / PO <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts)) { %>
                <a href="IndentPO"><i class="fas fa-file-signature text-primary"></i> Create Purchase Order</a>
                <a href="GRNServlet"><i class="fas fa-clipboard-check text-success"></i> GRN Entry</a>
                <a href="VendorMaster.jsp"><i class="fas fa-user-tie text-info"></i> Vendor Master</a>
            <% } %>
            <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts) || "Store".equalsIgnoreCase(depts)) { %>
                <a href="POListServlet"><i class="fas fa-check-double text-success"></i> Approve PO</a>
                <a href="ListPO.jsp"><i class="fas fa-clipboard-list text-warning"></i> PO Report</a>
            <% } %>
        </div>
    </div>

    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-chart-line text-purple"></i> Reports <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <a href="Stock.jsp"><i class="fas fa-boxes text-info"></i> Stock Report</a>
            <a href="stockReport.jsp"><i class="fas fa-book text-primary"></i> Stock Ledger Report</a>
            <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts)) { %>
                <a href="IssueValueReport.jsp"><i class="fas fa-chart-pie text-danger"></i> Consumption Dash Board</a>
            <% } %>
        </div>
    </div>

    <% if ("Global".equalsIgnoreCase(roles)) { %>
    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-cog text-secondary"></i> Masters <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <a href="ItemsMaster.jsp"><i class="fas fa-tags text-primary"></i> Item Master</a>
            <a href="AddStock"><i class="fas fa-plus-square text-success"></i> Add Stock</a>
        </div>
    </div>

    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-tools text-warning"></i> Asset Management <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <a href="#"><i class="fas fa-desktop text-info"></i> Fixed Assets</a>
            <a href="#"><i class="fas fa-barcode text-danger"></i> BarCode Generator</a>
        </div>
    </div>
    <% } %>

    <a href="Logout.jsp"><i class="fas fa-sign-out-alt text-danger"></i> Logout</a>
</div>

<script>
document.querySelectorAll(".dropdown-btn").forEach(btn => {
  btn.addEventListener("click", function() {
    this.parentElement.classList.toggle("active");
  });
});
</script>
