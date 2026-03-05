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
    
    // Safety check for initials
    String initial = (users != null && !users.isEmpty()) ? users.substring(0,1).toUpperCase() : "?";
    
    // Extract year for the footer specifically
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
/* ... (Existing CSS) ... */
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Inter', 'Poppins', sans-serif; background-color: #f6f8fa; color: #333; transition: margin-left 0.3s ease; overflow-x: hidden; min-height: 100vh; position: relative; padding-bottom: 60px; }
.sidebar { position: fixed; top: 0; left: 0; height: 100vh; width: 250px; background: linear-gradient(180deg, #0f172a, #1e293b); color: #fff; display: flex; flex-direction: column; padding-top: 20px; box-shadow: 2px 0 10px rgba(0,0,0,0.2); z-index: 1001; transition: transform 0.3s ease; overflow-y: auto; }
.sidebar h2 { text-align: center; font-weight: 600; font-size: 20px; margin-bottom: 25px; color: #f1f5f9; }

/* Sidebar Label Separator */
.sidebar-label {
    font-size: 11px;
    font-weight: 700;
    color: #64748b;
    text-transform: uppercase;
    letter-spacing: 1.2px;
    padding: 20px 20px 10px;
    border-top: 1px solid rgba(255,255,255,0.05);
    margin-top: 5px;
}

.sidebar a, .sidebar .dropdown-btn { display: flex; align-items: center; gap: 12px; color: #d1d5db; text-decoration: none; padding: 12px 20px; font-size: 15px; border-radius: 8px; transition: all 0.25s ease; background: none; border: none; width: 100%; cursor: pointer; text-align: left; }
.sidebar a:hover, .sidebar .dropdown-btn:hover { background: linear-gradient(90deg, #2563eb, #3b82f6); color: #fff; transform: translateX(5px); }

/* Admission-specific Visual Difference */
.admission-menu {
    background: rgba(14, 165, 233, 0.1); 
    border-left: 4px solid #0ea5e9 !important;
    margin: 5px 10px;
    border-radius: 8px;
}
.admission-menu .dropdown-btn { color: #7dd3fc; font-weight: 600; }

/* Recruitment-specific Visual Difference */
.recruitment-menu {
    background: rgba(139, 92, 246, 0.1); 
    border-left: 4px solid #8b5cf6 !important;
    margin: 5px 10px;
    border-radius: 8px;
}
.recruitment-menu .dropdown-btn { color: #c4b5fd; font-weight: 600; }

.dropdown-content { display: none; flex-direction: column; background: #1e293b; border-left: 3px solid #2563eb; margin-left: 10px; border-radius: 8px; }
.dropdown-content a { font-size: 14px; padding: 8px 20px; color: #cbd5e1; }
.dropdown.active .dropdown-content { display: flex; }

header { position: fixed; top: 0; left: 250px; right: 0; height: 75px; background: #ffffff; color: #333; display: flex; align-items: center; justify-content: space-between; padding: 0 30px; border-bottom: 1px solid #e2e8f0; z-index: 1000; box-shadow: 0 2px 15px rgba(0,0,0,0.05); transition: left 0.3s ease; }
.header-brand-title { text-align: left; color: #0f2a4d; font-weight: 800; font-size: 28px; text-transform: uppercase; letter-spacing: 0.5px; border-left: 5px solid #fbbf24; padding-left: 15px; font-family: 'Inter', sans-serif; white-space: nowrap; }
.toggle-btn { background: #f1f5f9; border: none; color: #0f2a4d; font-size: 20px; cursor: pointer; width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; margin-right: 15px; }
.user-info-card { display: flex; align-items: center; padding: 8px 15px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 14px; transition: all 0.3s ease; margin-left: 15px; }
.user-initials { width: 38px; height: 38px; border-radius: 10px; background: linear-gradient(135deg, #0f2a4d, #1e40af); color: white; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 16px; margin-right: 10px; }
.user-meta .u-name { font-size: 13px; font-weight: 700; color: #0f2a4d; }
.user-meta .u-role { font-size: 10px; font-weight: 600; color: #3b82f6; }

main { margin-left: 250px; padding: 110px 30px 40px; transition: margin-left 0.3s ease; }
footer { position: fixed; bottom: 0; left: 250px; right: 0; background: #ffffff; color: #64748b; text-align: center; padding: 12px 10px; font-size: 13px; border-top: 1px solid #e2e8f0; transition: left 0.3s ease; z-index: 1000; }
body.sidebar-collapsed header { left: 0; }
body.sidebar-collapsed main { margin-left: 0; }
body.sidebar-collapsed footer { left: 0; }
body.sidebar-collapsed .sidebar { transform: translateX(-100%); }

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

<div class="sidebar" id="sidebar">
  <h2><i class="fas fa-box text-primary"></i> Sandur Residential School</h2>

  <div class="sidebar-label">Inventory</div>
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

  <%
if ("Global".equalsIgnoreCase(roles.trim()) ||
   ("Incharge".equalsIgnoreCase(roles.trim()) 
     && "Finance".equalsIgnoreCase(depts.trim()))) {
%>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-cog text-secondary"></i> Masters <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="ItemsMaster.jsp"><i class="fas fa-tags text-primary"></i> Item Master</a>
      <a href="AddStock"><i class="fas fa-plus-square text-success"></i> Add Stock</a>
    </div>
  </div>
  <% } %>

  <div class="sidebar-label">Academic & Students</div>
  
  <div class="dropdown admission-menu">
    <button class="dropdown-btn"><i class="fas fa-graduation-cap text-info"></i> Admissions <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
     <% if ("Global".equalsIgnoreCase(roles)|| "Finance".equalsIgnoreCase(depts)||"Academics".equalsIgnoreCase(depts)){ %>
      <a href="dashboard"><i class="fas fa-home"></i> Home</a>
      <a href="admission"><i class="fas fa-search"></i> Enquiries</a>
      <a href="admission_report.jsp"><i class="fas fa-chart-line"></i> Dashboard</a>
       <% } %>
      <% if ("Academics".equalsIgnoreCase(depts)||"Global".equalsIgnoreCase(roles)){ %>
        <a href="enter_marks.jsp"><i class="fas fa-pen"></i> Marks Entry</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles)|| "Tejkumar".equalsIgnoreCase(users)||"Academics".equalsIgnoreCase(depts)){ %>
        <a href="marks_report.jsp"><i class="fas fa-file-invoice"></i> Tabulation</a>
        <a href="ApproveAdmission.jsp"><i class="fas fa-user-check"></i> Approval</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles)){ %>
        <a href="Capcity.jsp"><i class="fas fa-door-open"></i> Vacancy</a>
      <% } %>
      <% if ("Tejkumar".equalsIgnoreCase(users)){ %>
        <a href="student_tc_update.jsp"><i class="fas fa-user-minus"></i> TC Update</a>
      <% } %>
    </div>
  </div>

  <div class="sidebar-label">HR & Recruitment</div>

   <div class="dropdown recruitment-menu">
     <button class="dropdown-btn"><i class="fas fa-user-tie text-purple"></i> Recruitment <i class="fas fa-caret-down"></i></button>
     <div class="dropdown-content">
       <a href="candidateForm.jsp"><i class="fas fa-file-signature"></i> Recruitment Form</a>
       <a href="resume"><i class="fas fa-users-viewfinder"></i> Applications</a>
     </div>
   </div>
  
  <a href="Logout.jsp" style="margin-top: auto;"><i class="fas fa-sign-out-alt text-danger"></i> Logout</a>
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
  <p>© <%= currentYear %> | SRS | Office Central |  
  <i class="fas fa-leaf" style="color:green;"></i> Developed by
  <i class="fas fa-leaf" style="color:green;"></i> School IT Department</p>
</footer>

<script>
document.querySelectorAll('.dropdown-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.dropdown').forEach(drop => {
      if (drop !== btn.parentElement) drop.classList.remove('active');
    });
    btn.parentElement.classList.toggle('active');
  });
});

const toggleBtn = document.getElementById('menu-toggle');
toggleBtn.addEventListener('click', () => {
  document.body.classList.toggle('sidebar-collapsed');
});
</script>

</body>
</html>