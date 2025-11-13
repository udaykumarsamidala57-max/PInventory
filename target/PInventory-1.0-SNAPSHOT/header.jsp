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
        background: #f4f6f9;
    }

    header {
        background: #ffffff;
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 10px 25px;
        box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    }

    .user-info {
        display: inline-block;
        background: #03489C;
        color: #fff !important;
        padding: 10px 20px;
        border-radius: 8px;
        font-size: 18px;
        font-weight: 600;
        transition: all 0.3s ease;
    }

    .user-info:hover {
        background: #0056b3;
    }

    /* SIDEBAR */
    .sidebar {
        width: 250px;
        height: 100vh;
        background: #ffffff;
        position: fixed;
        top: 0;
        left: 0;
        overflow-y: auto;
        box-shadow: 2px 0 10px rgba(0,0,0,0.1);
        padding-top: 80px;
        transition: all 0.3s ease;
        border-right: 5px solid transparent;
    }

    /* Decorative gradient strip */
    .sidebar::after {
        content: "";
        position: absolute;
        top: 0;
        right: -6px;
        width: 6px;
        height: 100%;
        background: linear-gradient(135deg, #ff8c00, #8e2de2);
        border-radius: 10px 0 0 10px;
    }

    .sidebar h2 {
        font-size: 20px;
        color: #333;
        text-align: center;
        margin-bottom: 25px;
        font-weight: 600;
    }

    .sidebar a,
    .sidebar .dropdown-btn {
        display: flex;
        align-items: center;
        gap: 10px;
        width: 100%;
        text-align: left;
        background: none;
        border: none;
        color: #333;
        font-size: 18px;
        padding: 16px 25px;
        cursor: pointer;
        font-family: 'Poppins', sans-serif;
        text-decoration: none;
        transition: all 0.3s ease;
    }

    .sidebar a i,
    .sidebar .dropdown-btn i {
        min-width: 20px;
        text-align: center;
        font-size: 18px;
    }

    .sidebar a:hover,
    .sidebar .dropdown-btn:hover {
        background: #007bff;
        color: white;
        border-radius: 6px;
        transform: translateX(5px);
    }

    .sidebar .dropdown-content {
        display: none;
        padding-left: 20px;
        border-left: 2px solid #007bff;
        background: #f9f9f9;
    }

    .sidebar .dropdown-content a {
        display: block;
        padding: 8px 15px;
        color: #333;
        font-size: 14px;
        text-decoration: none;
        border-radius: 6px;
        transition: all 0.3s ease;
    }

    .sidebar .dropdown-content a:hover {
        background: #03489C;
        color: white;
        transform: translateX(5px);
    }

    .sidebar .dropdown.active .dropdown-content {
        display: block;
    }

    .sidebar .fa-caret-down {
        margin-left: auto;
    }

    /* Icon colors */
    .text-primary { color:#007bff; }
    .text-success { color:#28a745; }
    .text-danger { color:#dc3545; }
    .text-warning { color:#ffc107; }
    .text-info { color:#17a2b8; }
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
<div class="sidebar">
    <h2><i class="fas fa-compass text-primary"></i> Navigation</h2>
    <a href="Home"><i class="fas fa-home text-success"></i> Home</a>

    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-file-alt text-primary"></i> Indent <i class="fas fa-caret-down"></i></button>
        <div class="dropdown-content">
            <a href="IndentServlet"><i class="fas fa-plus-circle text-success"></i> Item Requisition Form</a>
            <a href="IndentlistServlet"><i class="fas fa-list text-info"></i> Indent Report</a>
            <% if ("Global".equalsIgnoreCase(roles) || "Incharge".equalsIgnoreCase(roles) || "Admin".equalsIgnoreCase(roles)) { %>
                <a href="AIndentListServlet"><i class="fas fa-check-circle text-warning"></i> Approve Indent</a>
            <% } %>
        </div>
    </div>

    <% if ("Global".equalsIgnoreCase(roles)|| "Store".equalsIgnoreCase(depts)) { %>
    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-box-open text-warning"></i> Issue <i class="fas fa-caret-down"></i></button>
        <div class="dropdown-content">
            <a href="IssueApprove"><i class="fas fa-thumbs-up text-success"></i> Approve Issue</a>
            <a href="IssueServlet"><i class="fas fa-dolly text-info"></i> Issue Items</a>
            <a href="Issuereport.jsp"><i class="fas fa-file-invoice text-danger"></i> Issue Report</a>
        </div>
    </div>
    <% } %>

    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-shopping-cart text-danger"></i> Purchase / PO <i class="fas fa-caret-down"></i></button>
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
        <button class="dropdown-btn"><i class="fas fa-chart-line text-purple"></i> Reports <i class="fas fa-caret-down"></i></button>
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
        <button class="dropdown-btn"><i class="fas fa-cog text-secondary"></i> Masters <i class="fas fa-caret-down"></i></button>
        <div class="dropdown-content">
            <a href="ItemsMaster.jsp"><i class="fas fa-tags text-primary"></i> Item Master</a>
            <a href="AddStock"><i class="fas fa-plus-square text-success"></i> Add Stock</a>
        </div>
    </div>
    <% } %>
    
    <% if ("Global".equalsIgnoreCase(roles)|| "Finance".equalsIgnoreCase(depts)|| "Store".equalsIgnoreCase(depts)) { %>
    <div class="dropdown">
        <button class="dropdown-btn">
            <i class="fas fa-utensils text-warning"></i> Dining Hall 
            <i class="fas fa-caret-down"></i>
        </button>
        <div class="dropdown-content">
            <a href="DiningHallServlet"><i class="fas fa-receipt text-primary"></i> DH Consumption Entry</a>
            <a href="dining_dashboard.jsp"><i class="fas fa-chart-pie text-success"></i> Dashboard</a>
        </div>
    </div>
    <% } %>

    <% if ("Global".equalsIgnoreCase(roles)|| "Finance".equalsIgnoreCase(depts)) { %>
    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-tools text-warning"></i> Asset Management <i class="fas fa-caret-down"></i></button>
        <div class="dropdown-content">
            <a href="#"><i class="fas fa-desktop text-info"></i> Fixed Assets</a>
            <a href="#"><i class="fas fa-barcode text-danger"></i> BarCode Generator</a>
        </div>
    </div>
    <% } %>

    <% if ("Global".equalsIgnoreCase(roles)|| "Finance".equalsIgnoreCase(depts)) { %>
    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-lightbulb text-warning"></i> Documentation <i class="fas fa-caret-down"></i></button>
        <div class="dropdown-content">
            <a href="#"><i class="fas fa-info-circle text-primary"></i> About Software</a>
            <a href="#"><i class="fas fa-bolt text-success"></i> New Updates</a>
        </div>
    </div>
    <% } %>

    <a href="Logout.jsp"><i class="fas fa-sign-out-alt text-danger"></i> Logout</a>
</div>

<script>
document.querySelectorAll(".dropdown-btn").forEach(btn => {
  btn.addEventListener("click", function() {
    const allDropdowns = document.querySelectorAll(".dropdown");
    allDropdowns.forEach(d => {
      if (d !== this.parentElement) d.classList.remove("active");
    });
    this.parentElement.classList.toggle("active");
  });
});
</script>
