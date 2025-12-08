<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>
<%@ page import="java.util.Calendar, java.text.SimpleDateFormat" %>
<%
    HttpSession sesso = request.getSession(false);
    if (sesso == null || sesso.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String users = (String) sesso.getAttribute("username");
    String roles = (String) sesso.getAttribute("role");
    String depts = (String) sesso.getAttribute("department");

    SimpleDateFormat sdf = new SimpleDateFormat("dd MMMM yyyy");
    String todayDate = sdf.format(Calendar.getInstance().getTime());
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Inventory System</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
/* RESET */
* { margin: 0; padding: 0; box-sizing: border-box; }

/* GLOBAL */
body {
  font-family: 'Poppins', sans-serif;
  background-color: #f6f8fa;
  color: #333;
  transition: margin-left 0.3s ease;
  overflow-x: hidden;
  min-height: 100vh;
  position: relative;
  padding-bottom: 60px; /* space for footer */
}

/* SIDEBAR */
.sidebar {
  position: fixed;
  top: 0;
  left: 0;
  height: 100vh;
  width: 250px;
  background: linear-gradient(180deg, #0f172a, #1e293b);
  color: #fff;
  display: flex;
  flex-direction: column;
  padding-top: 20px;
  box-shadow: 2px 0 10px rgba(0,0,0,0.2);
  z-index: 999;
  transition: transform 0.3s ease, width 0.3s ease;
}
.sidebar.hidden { transform: translateX(-100%); }
.sidebar h2 {
  text-align: center;
  font-weight: 600;
  font-size: 20px;
  margin-bottom: 25px;
  color: #f1f5f9;
}
.sidebar a, .sidebar .dropdown-btn {
  display: flex;
  align-items: center;
  gap: 12px;
  color: #d1d5db;
  text-decoration: none;
  padding: 12px 20px;
  font-size: 15px;
  border-radius: 8px;
  transition: all 0.25s ease;
  background: none;
  border: none;
  width: 100%;
  cursor: pointer;
  text-align: left;
}
.sidebar a:hover, .sidebar .dropdown-btn:hover {
  background: linear-gradient(90deg, #2563eb, #3b82f6);
  color: #fff;
  transform: translateX(5px);
  box-shadow: 0 0 10px rgba(37,99,235,0.4);
}
.sidebar i { font-size: 16px; min-width: 20px; }
.dropdown-content {
  display: none;
  flex-direction: column;
  background: #1e293b;
  border-left: 3px solid #2563eb;
  margin-left: 10px;
  border-radius: 8px;
}
.dropdown-content a {
  font-size: 14px;
  padding: 8px 20px;
  color: #cbd5e1;
}
.dropdown-content a:hover {
  background: #334155;
  color: #fff;
}
.dropdown.active .dropdown-content { display: flex; }
.fa-caret-down { margin-left: auto; }
.sidebar .dropdown, .sidebar > a { margin-bottom: 10px; }

/* HEADER */
header {
  position: fixed;
  top: 0;
  left: 250px;
  right: 0;
  height: 70px;
  background: linear-gradient(90deg, #1e293b, #334155);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 25px;
  border-bottom: 1px solid #2d3748;
  z-index: 1000;
  box-shadow: 0 2px 10px rgba(0,0,0,0.3);
  transition: left 0.3s ease;
}
header img { height: 45px; }

.toggle-btn {
  background: none;
  border: none;
  color: #fff;
  font-size: 24px;
  cursor: pointer;
  margin-right: 10px;
}

/* ===== NEW PROFESSIONAL USER CARD ===== */
header .user-info {
  display: flex;
  align-items: center;
  background: rgba(255,255,255,0.08);
  border: 1px solid rgba(255,255,255,0.15);
  border-radius: 12px;
  padding: 10px 18px;
  backdrop-filter: blur(8px);
  box-shadow: 0 0 10px rgba(0,0,0,0.25);
  transition: all 0.3s ease;
  cursor: default;
}
header .user-info:hover {
  background: rgba(255,255,255,0.12);
  box-shadow: 0 0 18px rgba(37,99,235,0.5);
  transform: translateY(-1px);
}
header .user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  background: linear-gradient(145deg, #3b82f6, #2563eb);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 17px;
  font-weight: 700;
  color: #fff;
  box-shadow: 0 0 10px rgba(37,99,235,0.6);
  margin-right: 12px;
  text-transform: uppercase;
}
header .user-details {
  display: flex;
  flex-direction: column;
  line-height: 1.2;
}
header .user-details strong {
  font-size: 15px;
  font-weight: 600;
  color: #f8fafc;
  letter-spacing: 0.4px;
}
header .user-details strong i {
  color: #93c5fd;
  margin-right: 6px;
}
header .user-details span {
  font-size: 12.5px;
  color: #cbd5e1;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-top: 4px;
  display: flex;
  align-items: center;
  gap: 5px;
  background: rgba(59,130,246,0.15);
  padding: 3px 8px;
  border-radius: 6px;
}
header .user-details span i {
  color: #60a5fa;
}

/* MAIN */
main {
  margin-left: 250px;
  padding: 100px 30px 40px;
  transition: margin-left 0.3s ease;
}

/* FOOTER */
footer {
  position: fixed;
  bottom: 0;
  left: 250px;
  right: 0;
  background: linear-gradient(90deg, #1e293b, #334155);
  color: #cbd5e1;
  text-align: center;
  padding: 12px 10px;
  font-size: 14px;
  box-shadow: 0 -2px 10px rgba(0,0,0,0.3);
  transition: left 0.3s ease;
}
footer i { margin: 0 3px; }

/* COLLAPSE STATE */
body.sidebar-collapsed header { left: 0; }
body.sidebar-collapsed main { margin-left: 0; }
body.sidebar-collapsed footer { left: 0; }
body.sidebar-collapsed .sidebar { transform: translateX(-100%); }

/* RESPONSIVE */
@media (max-width: 992px) {
  header { left: 0; }
  main { margin-left: 0; padding-top: 100px; }
  footer { left: 0; font-size: 13px; }
  .sidebar { transform: translateX(-100%); }
  .sidebar.show { transform: translateX(0); }
}

/* COLORS */
.text-primary { color:#3b82f6; }
.text-success { color:#22c55e; }
.text-danger { color:#ef4444; }
.text-warning { color:#facc15; }
.text-info { color:#06b6d4; }
.text-purple { color:#8b5cf6; }
.text-secondary { color:#9ca3af; }
</style>
</head>

<body class="sidebar-collapsed">

<!-- SIDEBAR -->
<div class="sidebar" id="sidebar">
  <h2><i class="fas fa-box text-primary"></i> Navigation</h2>

  <a href="Home"><i class="fas fa-home text-success"></i> Dashboard</a>

  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-file-alt text-primary"></i> Indent <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="IndentServlet"><i class="fas fa-plus-circle text-success"></i> Item Requisition Form</a>
      <a href="IndentlistServlet"><i class="fas fa-list text-info"></i> Indent Report</a>
      <% if ("Global".equalsIgnoreCase(roles) || "Incharge".equalsIgnoreCase(roles) || "Admin".equalsIgnoreCase(roles)) { %>
        <a href="AIndentListServlet"><i class="fas fa-check-circle text-warning"></i> Approve Indent</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles) || "A_Veeresh".equalsIgnoreCase(users)) { %>
        <a href="DIndentListServlet"><i class="fas fa-check-circle text-warning"></i> Approve Dining Hall Indent</a>
      <% } %>
      
    </div>
  </div>

  <% if ("Global".equalsIgnoreCase(roles)|| "Store".equalsIgnoreCase(depts)) { %>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-box-open text-warning"></i> Issue <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      
      <a href="IssueServlet"><i class="fas fa-dolly text-info"></i> Issue Items</a>
      <a href="Issuereport.jsp"><i class="fas fa-file-invoice text-danger"></i> Issue Report</a>
    </div>
  </div>
  <% } %>

  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-shopping-cart text-danger"></i> Purchase / PO <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
    <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts) || "Store".equalsIgnoreCase(depts)) { %>
        <a href="POListServlet"><i class="fas fa-check-double text-success"></i> Approve PO</a>
        <a href="ListPO.jsp"><i class="fas fa-clipboard-list text-warning"></i> PO Report</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts)) { %>
        <a href="IndentPO"><i class="fas fa-file-signature text-primary"></i> Create Purchase Order</a>
        <a href="GRNServlet"><i class="fas fa-clipboard-check text-success"></i> GRN Entry</a>
        <a href="viewGRN"><i class="fas fa-clipboard-check text-success"></i> GRN Report</a>
        <a href="VendorMaster.jsp"><i class="fas fa-user-tie text-info"></i> Vendor Master</a>
      <% } %>
      
    </div>
  </div>
  
  
  <% if ("Global".equalsIgnoreCase(roles)|| "Finance".equalsIgnoreCase(depts)|| "Store".equalsIgnoreCase(depts)) { %>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-utensils text-warning"></i> Dining Hall <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="DiningHallServlet"><i class="fas fa-receipt text-primary"></i> DH Consumption Entry</a>
      <a href="dining_dashboard.jsp"><i class="fas fa-chart-pie text-success"></i> Dashboard</a>
    </div>
  </div>
  <% } %>

  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-chart-line text-purple"></i> Reports <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="Stock.jsp"><i class="fas fa-boxes text-info"></i> Stock Report</a>
      <a href="stockReport.jsp"><i class="fas fa-book text-primary"></i> Stock Ledger Report</a>
      <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts)) { %>
        <a href="IssueValueReport.jsp"><i class="fas fa-chart-pie text-danger"></i> Consumption Dashboard</a>
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



  <% if ("Global".equalsIgnoreCase(roles)|| "Finance".equalsIgnoreCase(depts)) { %>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-tools text-warning"></i> Asset Management <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="#"><i class="fas fa-desktop text-info"></i> Fixed Assets</a>
      <a href="#"><i class="fas fa-barcode text-danger"></i> Barcode Generator</a>
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

<!-- HEADER -->
<header>
  <button class="toggle-btn" id="menu-toggle"><i class="fas fa-bars"></i></button>
  <img src="logo.png" alt="Logo">
  <div class="user-info">
    <div class="user-avatar"><%= users.substring(0,1).toUpperCase() %></div>
    <div class="user-details">
      <strong><i class="fas fa-user"></i> <%= users.toUpperCase() %></strong>
      <span><i class="fas fa-user-shield"></i> <%= roles.toUpperCase() %></span>
    </div>
  </div>
</header>

<!-- MAIN CONTENT -->
<main>
  <h2>Inventory Management System</h2>
</main>

<!-- FOOTER -->
<footer>
  <p>© <%= todayDate %> | SRS Inventory System |
  <i class="fas fa-leaf" style="color:green;"></i> Developed by
  <i class="fas fa-leaf" style="color:green;"></i> School IT Department</p>
</footer>

<script>
/* Dropdown functionality */
document.querySelectorAll('.dropdown-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.dropdown').forEach(drop => {
      if (drop !== btn.parentElement) drop.classList.remove('active');
    });
    btn.parentElement.classList.toggle('active');
  });
});

/* Sidebar toggle */
const toggleBtn = document.getElementById('menu-toggle');
toggleBtn.addEventListener('click', () => {
  document.body.classList.toggle('sidebar-collapsed');
});
</script>

</body>
</html>
