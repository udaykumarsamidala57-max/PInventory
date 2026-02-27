<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>
<%@ page import="java.util.Calendar, java.text.SimpleDateFormat" %>
<%
    // --- UNIFIED AUTHENTICATION (Inventory Based) ---
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
<title>SRS | Unified Management System</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
/* --- INVENTORY SYSTEM STYLES (Existing) --- */
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: 'Inter', 'Poppins', sans-serif;
  background-color: #f6f8fa;
  color: #333;
  transition: margin-left 0.3s ease;
  overflow-x: hidden;
  min-height: 100vh;
  position: relative;
  padding-bottom: 60px;
}
.sidebar {
  position: fixed; top: 0; left: 0; height: 100vh; width: 250px;
  background: linear-gradient(180deg, #0f172a, #1e293b);
  color: #fff; display: flex; flex-direction: column; padding-top: 20px;
  box-shadow: 2px 0 10px rgba(0,0,0,0.2); z-index: 1001; transition: transform 0.3s ease;
}
.sidebar a, .sidebar .dropdown-btn {
  display: flex; align-items: center; gap: 12px; color: #d1d5db;
  text-decoration: none; padding: 12px 20px; font-size: 15px; border-radius: 8px;
  transition: all 0.25s ease; background: none; border: none; width: 100%; cursor: pointer; text-align: left;
}
.sidebar a:hover, .sidebar .dropdown-btn:hover { background: linear-gradient(90deg, #2563eb, #3b82f6); color: #fff; transform: translateX(5px); }
.dropdown-content { display: none; flex-direction: column; background: #1e293b; border-left: 3px solid #2563eb; margin-left: 10px; border-radius: 8px; }
.dropdown.active .dropdown-content { display: flex; }

/* Adjusted Header to make room for AMS bar below it if needed */
header.inventory-header {
  position: fixed; top: 0; left: 250px; right: 0; height: 75px;
  background: #ffffff; color: #333; display: flex; align-items: center;
  justify-content: space-between; padding: 0 30px; border-bottom: 1px solid #e2e8f0;
  z-index: 1000; box-shadow: 0 2px 15px rgba(0,0,0,0.05); transition: left 0.3s ease;
}

/* --- AMS SYSTEM STYLES (Existing) --- */
header.ams-header {
    background: #0f2a4d !important;
    border-bottom: 3px solid #38bdf8 !important;
    margin: 0 !important;
    width: 100% !important;
    display: block !important;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    position: relative;
    z-index: 999;
}
.ams-header .nav-container {
    max-width: 1400px; margin: 0 auto !important; padding: 12px 25px !important;
    display: flex !important; align-items: center !important; justify-content: space-between !important; min-height: 70px !important;
}
.ams-header .brand-box { border-left: 4px solid #fbbf24 !important; padding-left: 15px !important; }
.ams-header .school-name { color: #fbbf24 !important; font-size: 1.3rem !important; font-weight: 800 !important; text-transform: uppercase !important; }
.ams-header nav.ams-nav ul { list-style: none !important; display: flex !important; gap: 8px !important; }
.ams-header nav.ams-nav ul li a { text-decoration: none !important; color: #e5e7eb !important; font-size: 14px !important; font-weight: 600 !important; padding: 8px 14px !important; border-radius: 6px !important; }
.ams-header nav.ams-nav ul li a:hover { background: rgba(255,255,255,0.15) !important; color: #38bdf8 !important; }

/* Layout adjustments */
main { margin-left: 250px; padding: 20px; transition: margin-left 0.3s ease; }
body.sidebar-collapsed .inventory-header { left: 0; }
body.sidebar-collapsed main { margin-left: 0; }
body.sidebar-collapsed .sidebar { transform: translateX(-100%); }

.content-wrapper { padding-top: 85px; } /* Offset for fixed inventory header */
</style>
</head>

<body class="sidebar-collapsed">

<div class="sidebar" id="sidebar">
  <h2 style="padding: 10px;"><i class="fas fa-box text-primary"></i> SRS Inventory</h2>
  <a href="Home"><i class="fas fa-home text-success"></i> Dashboard</a>
  
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-file-alt text-primary"></i> Indent <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="IndentServlet">Item Requisition</a>
      <a href="IndentlistServlet">Indent Report</a>
    </div>
  </div>

  <% if ("Global".equalsIgnoreCase(roles) || "Store".equalsIgnoreCase(depts)) { %>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-box-open text-warning"></i> Issue <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="IssueServlet">Issue Items</a>
      <a href="Issuereport.jsp">Issue Report</a>
    </div>
  </div>
  <% } %>

  <a href="Logout.jsp"><i class="fas fa-sign-out-alt text-danger"></i> Logout</a>
</div>

<header class="inventory-header">
  <div style="display: flex; align-items: center;">
    <button class="toggle-btn" id="menu-toggle" style="background:#f1f5f9; border:none; padding:10px; cursor:pointer; border-radius:8px; margin-right:15px;"><i class="fas fa-bars"></i></button>
    <div style="font-weight:800; font-size:18px; color:#0f2a4d; border-left:4px solid #fbbf24; padding-left:15px;">INVENTORY SYSTEM</div>
  </div>

  <div style="display:flex; align-items:center; background:#f8fafc; padding:8px 15px; border-radius:12px; border:1px solid #e2e8f0;">
    <div style="width:35px; height:35px; background:#0f2a4d; color:white; border-radius:8px; display:flex; align-items:center; justify-content:center; margin-right:10px; font-weight:bold;"><%= users.substring(0,1).toUpperCase() %></div>
    <div style="display:flex; flex-direction:column;">
      <span style="font-size:12px; font-weight:700;"><%= users.toLowerCase() %></span>
      <span style="font-size:10px; color:#3b82f6; text-transform:uppercase;"><%= roles %></span>
    </div>
  </div>
</header>

<div class="content-wrapper">
    <header class="ams-header">
        <div class="nav-container">
            <div class="brand-box">
                <span class="school-name" style="display:block;">Sandur Residential School</span>
                <span class="system-name" style="color:white; font-size:12px; opacity:0.8;">Admissions Management System</span>
            </div>
            <nav class="ams-nav">
                <ul>
                    <li><a href="admission">Enquiries</a></li>
                    <li><a href="admission_report.jsp">Dashboard</a></li>
                    <li><a href="enter_marks.jsp">Exam</a></li>
                    <li><a href="ApproveAdmission.jsp">Approval</a></li>
                    <li><a href="Home">Inventory Home</a></li>
                </ul>
            </nav>
        </div>
    </header>

    <main>
      <div style="background: white; padding: 30px; border-radius: 15px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
          <h2>Welcome to the Unified Portal, <%= users.toUpperCase() %></h2>
          <p style="color: #64748b; margin-top: 10px;">Authenticated via Inventory System | Date: <%= todayDate %></p>
          <hr style="margin: 20px 0; border: 0; border-top: 1px solid #eee;">
          
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
              <div style="border: 1px solid #e2e8f0; padding: 20px; border-radius: 10px;">
                  <h4 style="color:#2563eb;"><i class="fas fa-boxes"></i> Inventory Quick Actions</h4>
                  <ul style="list-style:none; margin-top:10px;">
                      <li><a href="IndentServlet" style="color:#64748b; text-decoration:none;">• Create New Indent</a></li>
                      <li><a href="Stock.jsp" style="color:#64748b; text-decoration:none;">• View Stock Report</a></li>
                  </ul>
              </div>
              <div style="border: 1px solid #e2e8f0; padding: 20px; border-radius: 10px;">
                  <h4 style="color:#0f2a4d;"><i class="fas fa-user-grad"></i> Admission Quick Actions</h4>
                  <ul style="list-style:none; margin-top:10px;">
                      <li><a href="admission" style="color:#64748b; text-decoration:none;">• Student Enquiries</a></li>
                      <li><a href="Capcity.jsp" style="color:#64748b; text-decoration:none;">• Check Vacancy</a></li>
                  </ul>
              </div>
          </div>
      </div>
    </main>
</div>

<footer style="text-align:center; padding:20px; color:#64748b; font-size:13px; border-top:1px solid #e2e8f0;">
  © <%= Calendar.getInstance().get(Calendar.YEAR) %> | SRS Unified Systems | School IT Department
</footer>

<script>
// Sidebar Toggle
document.getElementById('menu-toggle').addEventListener('click', () => {
  document.body.classList.toggle('sidebar-collapsed');
});

// Dropdown Logic
document.querySelectorAll('.dropdown-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    btn.parentElement.classList.toggle('active');
  });
});
</script>

</body>
</html>