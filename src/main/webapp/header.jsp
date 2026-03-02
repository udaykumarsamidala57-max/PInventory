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
    
    String initial = (users != null && !users.isEmpty()) ? users.substring(0,1).toUpperCase() : "?";
    int currentYear = Calendar.getInstance().get(Calendar.YEAR);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Office Central</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
/* ... (Standard CSS preserved) ... */
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Inter', 'Poppins', sans-serif; background-color: #f6f8fa; color: #333; transition: margin-left 0.3s ease; overflow-x: hidden; min-height: 100vh; position: relative; padding-bottom: 60px; }
.sidebar { position: fixed; top: 0; left: 0; height: 100vh; width: 250px; background: linear-gradient(180deg, #0f172a, #1e293b); color: #fff; display: flex; flex-direction: column; padding-top: 20px; box-shadow: 2px 0 10px rgba(0,0,0,0.2); z-index: 1001; transition: transform 0.3s ease; overflow-y: auto; }
.sidebar h2 { text-align: center; font-weight: 600; font-size: 20px; margin-bottom: 25px; color: #f1f5f9; padding: 0 10px; }

/* Section Separator */
.sidebar-label {
    font-size: 10px;
    font-weight: 800;
    color: #64748b;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    padding: 20px 20px 10px;
    border-top: 1px solid rgba(255,255,255,0.05);
    margin-top: 10px;
}

.sidebar a, .sidebar .dropdown-btn { display: flex; align-items: center; gap: 12px; color: #d1d5db; text-decoration: none; padding: 12px 20px; font-size: 14px; border-radius: 8px; transition: all 0.25s ease; background: none; border: none; width: 100%; cursor: pointer; text-align: left; }
.sidebar a:hover, .sidebar .dropdown-btn:hover { background: rgba(255,255,255,0.05); color: #fff; transform: translateX(5px); }

/* Admissions Specific Styling */
.admission-section {
    background: rgba(6, 182, 212, 0.08); /* Subtle cyan tint */
    border-left: 4px solid #06b6d4;
    margin: 5px 10px;
    border-radius: 8px;
}
.admission-section .dropdown-btn { color: #06b6d4; font-weight: 700; }

.dropdown-content { display: none; flex-direction: column; background: rgba(0,0,0,0.2); margin: 0 10px; border-radius: 8px; }
.dropdown-content a { font-size: 13px; padding: 8px 35px; color: #cbd5e1; }
.dropdown.active .dropdown-content { display: flex; }
.dropdown.active .dropdown-btn { color: #fff; }

header { position: fixed; top: 0; left: 250px; right: 0; height: 75px; background: #ffffff; display: flex; align-items: center; justify-content: space-between; padding: 0 30px; border-bottom: 1px solid #e2e8f0; z-index: 1000; box-shadow: 0 2px 15px rgba(0,0,0,0.05); transition: left 0.3s ease; }
.header-brand-title { color: #0f2a4d; font-weight: 800; font-size: 24px; text-transform: uppercase; border-left: 5px solid #fbbf24; padding-left: 15px; }
.toggle-btn { background: #f1f5f9; border: none; color: #0f2a4d; font-size: 20px; cursor: pointer; width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; margin-right: 15px; }
.user-info-card { display: flex; align-items: center; padding: 8px 15px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 14px; }
.user-initials { width: 38px; height: 38px; border-radius: 10px; background: linear-gradient(135deg, #0f2a4d, #1e40af); color: white; display: flex; align-items: center; justify-content: center; font-weight: 800; }
.user-meta { margin-left: 10px; }
.u-name { display: block; font-size: 13px; font-weight: 700; color: #0f2a4d; }
.u-role { font-size: 10px; color: #3b82f6; font-weight: 600; }

main { margin-left: 250px; padding: 110px 30px 40px; transition: margin-left 0.3s ease; }
footer { position: fixed; bottom: 0; left: 250px; right: 0; background: #ffffff; color: #64748b; text-align: center; padding: 12px 10px; font-size: 13px; border-top: 1px solid #e2e8f0; transition: left 0.3s ease; }

body.sidebar-collapsed header, body.sidebar-collapsed footer { left: 0; }
body.sidebar-collapsed main { margin-left: 0; }
body.sidebar-collapsed .sidebar { transform: translateX(-100%); }

.text-primary { color:#3b82f6; }
.text-success { color:#22c55e; }
.text-warning { color:#facc15; }
.text-danger { color:#ef4444; }
.text-info { color:#06b6d4; }
</style>
</head>

<body class="sidebar-collapsed">

<div class="sidebar" id="sidebar">
  <h2><i class="fas fa-university text-warning"></i> SRS Office</h2>

  <div class="sidebar-label">Operations</div>
  <a href="Home"><i class="fas fa-home text-success"></i> Dashboard</a>

  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-file-alt text-primary"></i> Indent <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="IndentServlet">Requisition Form</a>
      <a href="IndentlistServlet">Indent Report</a>
      <% if ("Global".equalsIgnoreCase(roles) || "Incharge".equalsIgnoreCase(roles) || "Admin".equalsIgnoreCase(roles)) { %>
        <a href="AIndentListServlet">Approve Indent</a>
      <% } %>
    </div>
  </div>

  <% if ("Global".equalsIgnoreCase(roles)|| "Store".equalsIgnoreCase(depts)) { %>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-box-open text-warning"></i> Inventory <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="IssueServlet">Issue Items</a>
      <a href="Issuereport.jsp">Issue Report</a>
      <a href="Stock.jsp">Stock Status</a>
    </div>
  </div>
  <% } %>

  <div class="sidebar-label">Academic Module</div>
  <div class="dropdown admission-section">
    <button class="dropdown-btn"><i class="fas fa-graduation-cap"></i> Admissions <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="dashboard"><i class="fas fa-th-large"></i> Overview</a>
      <a href="admission"><i class="fas fa-user-plus"></i> Enquiries</a>
      <a href="admission_report.jsp"><i class="fas fa-chart-bar"></i> Analysis</a>
      <% if ("Academics".equalsIgnoreCase(depts)||"Global".equalsIgnoreCase(roles)){ %>
        <a href="enter_marks.jsp"><i class="fas fa-edit"></i> Marks Entry</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles)|| "Tejkumar".equalsIgnoreCase(users)||"Academics".equalsIgnoreCase(depts)){ %>
        <a href="marks_report.jsp"><i class="fas fa-file-alt"></i> Tabulation</a>
        <a href="ApproveAdmission.jsp"><i class="fas fa-check-double"></i> Merit Approval</a>
      <% } %>
    </div>
  </div>

  <div class="sidebar-label">System</div>
  <a href="Logout.jsp" style="color: #ef4444;"><i class="fas fa-sign-out-alt"></i> Logout</a>
</div>

<header>
  <div style="display: flex; align-items: center;">
    <button class="toggle-btn" id="menu-toggle"><i class="fas fa-bars"></i></button>
    <div class="header-brand-title">SRS | Office Central </div>
  </div>

  <div class="user-info-card">
    <div class="user-initials"><%= initial %></div>
    <div class="user-meta">
      <span class="u-name"><%= users.toLowerCase() %></span>
      <span class="u-role"><i class="fas fa-shield-alt"></i> <%= roles %></span>
    </div>
  </div>
</header>

<main>
  <h2>Welcome back, <%= users.toUpperCase() %></h2>
  <p style="color: #64748b; font-size: 14px;">Current Session: <%= todayDate %></p>
</main>

<footer>
  <p>© <%= currentYear %> | SRS | Office Central | Developed by School IT Department</p>
</footer>

<script>
document.querySelectorAll('.dropdown-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const parent = btn.parentElement;
    parent.classList.toggle('active');
  });
});

const toggleBtn = document.getElementById('menu-toggle');
toggleBtn.addEventListener('click', () => {
  document.body.classList.toggle('sidebar-collapsed');
});
</script>

</body>
</html>