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
        background: #f8f9fa;
        display: flex;
    }

    header {
        position: fixed;
        top: 0;
        left: 240px;
        width: calc(100% - 240px);
        height: 70px;
        background: #ffffff;
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0 25px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        z-index: 10;
    }

    header img {
        max-height: 50px;
    }

    .user-info {
        background: #007bff;
        color: white;
        padding: 10px 20px;
        border-radius: 8px;
        cursor: pointer;
        font-size: 18px;
        font-weight: 600;
        transition: all 0.3s ease;
    }

    .user-info:hover {
        background: #0056b3;
    }

    /* Sidebar */
    .sidebar {
        position: fixed;
        top: 0;
        left: 0;
        width: 240px;
        height: 100vh;
        background: #ffffff;
        box-shadow: 2px 0 8px rgba(0,0,0,0.1);
        overflow-y: auto;
        transition: width 0.3s;
    }

    .sidebar h2 {
        text-align: center;
        padding: 15px;
        margin: 0;
        font-size: 20px;
        color: #007bff;
        border-bottom: 1px solid #dee2e6;
    }

    .sidebar a, .sidebar .dropdown-btn {
        display: block;
        width: 100%;
        text-align: left;
        background: none;
        border: none;
        color: #343a40;
        font-size: 15px;
        padding: 12px 20px;
        cursor: pointer;
        font-family: 'Poppins', sans-serif;
        transition: all 0.3s ease;
    }

    .sidebar a i, .sidebar .dropdown-btn i {
        margin-right: 10px;
    }

    .sidebar a:hover, .sidebar .dropdown-btn:hover {
        background: #007bff;
        color: white;
    }

    /* Dropdown Content */
    .sidebar .dropdown-content {
        display: none;
        background: #f1f3f5;
        border-left: 3px solid #007bff;
        margin-left: 5px;
        border-radius: 0 4px 4px 0;
    }

    .sidebar .dropdown-content a {
        padding: 8px 30px;
        font-size: 14px;
        color: #212529;
        transition: all 0.3s ease;
    }

    .sidebar .dropdown-content a:hover {
        background: #007bff;
        color: #fff;
    }

    /* Active Dropdown */
    .sidebar .dropdown.active > .dropdown-content {
        display: block;
        animation: slideDown 0.3s ease;
    }

    @keyframes slideDown {
        from { opacity: 0; transform: translateY(-10px); }
        to { opacity: 1; transform: translateY(0); }
    }

    /* Scrollbar */
    .sidebar::-webkit-scrollbar {
        width: 6px;
    }

    .sidebar::-webkit-scrollbar-thumb {
        background-color: #ccc;
        border-radius: 3px;
    }

    .sidebar a.logout {
        color: #dc3545;
        font-weight: 600;
    }
    </style>
</head>

<header>
    <img src="logo.png" alt="Logo">
    <div class="user-info">
        <strong><%= users.toUpperCase() %></strong><br>
        Role: <%= roles.toUpperCase() %>
    </div>
</header>

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

    <div class="dropdown">
        <button class="dropdown-btn"><i class="fas fa-laptop-house"></i> Asset Management <i class="fas fa-caret-down" style="float:right;"></i></button>
        <div class="dropdown-content">
            <a href="#">Fixed Assets</a>
            <a href="#">BarCode Generator</a>
        </div>
    </div>
    <% } %>

    <a href="Logout.jsp" class="logout"><i class="fas fa-sign-out-alt"></i> Logout</a>
</div>

<script>
document.querySelectorAll(".dropdown-btn").forEach(btn => {
  btn.addEventListener("click", function() {
    const parent = this.parentElement;
    const allDropdowns = document.querySelectorAll(".sidebar .dropdown");
    allDropdowns.forEach(d => {
      if (d !== parent) d.classList.remove("active");
    });
    parent.classList.toggle("active");
  });
});
</script>
