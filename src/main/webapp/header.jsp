<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>
<%@ page import="java.util.Calendar, java.text.SimpleDateFormat" %>

<%
/* ========= INVENTORY AUTH (ONLY) ========= */
HttpSession sessionObj = request.getSession(false);
if (sessionObj == null || sessionObj.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String users = (String) sessionObj.getAttribute("username");
String roles = (String) sessionObj.getAttribute("role");
String depts = (String) sessionObj.getAttribute("department");

/* ========= MODULE SWITCH ========= */
/* CHANGE THIS VALUE */
String MODULE = "INVENTORY";  // INVENTORY | ADMISSIONS

SimpleDateFormat sdf = new SimpleDateFormat("dd MMMM yyyy");
String todayDate = sdf.format(Calendar.getInstance().getTime());
%>

<!DOCTYPE html>
<html>
<head>
<title>SRS | <%= MODULE %></title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:Inter,Segoe UI,sans-serif}
body{background:#f6f8fa}

/* ===== SIDEBAR ===== */
.sidebar{
 position:fixed;left:0;top:0;height:100vh;width:250px;
 background:linear-gradient(180deg,#0f172a,#1e293b);
 color:#fff;padding:20px;z-index:1000
}
.sidebar h2{text-align:center;margin-bottom:25px}
.sidebar a,.dropdown-btn{
 display:flex;align-items:center;gap:12px;
 color:#d1d5db;text-decoration:none;
 padding:12px;border-radius:8px;
 background:none;border:none;width:100%;
 cursor:pointer
}
.sidebar a:hover,.dropdown-btn:hover{
 background:#2563eb;color:#fff
}
.dropdown-content{
 display:none;flex-direction:column;margin-left:15px
}
.dropdown.active .dropdown-content{display:flex}

/* ===== HEADER ===== */
header{
 position:fixed;left:250px;right:0;top:0;height:70px;
 background:#fff;display:flex;align-items:center;
 justify-content:space-between;padding:0 25px;
 border-bottom:1px solid #e5e7eb
}
.brand{
 font-weight:800;color:#0f2a4d;
 border-left:5px solid #fbbf24;padding-left:12px
}
.user{
 display:flex;align-items:center;gap:12px
}
.avatar{
 width:40px;height:40px;border-radius:10px;
 background:#1e40af;color:#fff;
 display:flex;align-items:center;justify-content:center;
 font-weight:800
}

/* ===== MAIN ===== */
main{margin-left:250px;padding:100px 30px}
</style>
</head>

<body>

<!-- ========== SIDEBAR ========== -->
<div class="sidebar">
<h2>SRS</h2>

<% if ("INVENTORY".equals(MODULE)) { %>

<a href="Home"><i class="fas fa-home"></i> Dashboard</a>

<div class="dropdown">
<button class="dropdown-btn"><i class="fas fa-file-alt"></i> Indent</button>
<div class="dropdown-content">
  <a href="IndentServlet">Create Indent</a>
  <a href="IndentlistServlet">Indent Report</a>
  <% if ("Global".equalsIgnoreCase(roles) || "Incharge".equalsIgnoreCase(roles)) { %>
    <a href="AIndentListServlet">Approve Indent</a>
  <% } %>
</div>
</div>

<% if ("Store".equalsIgnoreCase(depts) || "Global".equalsIgnoreCase(roles)) { %>
<div class="dropdown">
<button class="dropdown-btn"><i class="fas fa-box"></i> Store</button>
<div class="dropdown-content">
  <a href="IssueServlet">Issue Items</a>
  <a href="Stock.jsp">Stock</a>
</div>
</div>
<% } %>

<% } %>


<% if ("ADMISSIONS".equals(MODULE)) { %>

<a href="dashboard"><i class="fas fa-home"></i> Home</a>
<a href="admission"><i class="fas fa-file"></i> Enquiries</a>
<a href="enter_marks.jsp"><i class="fas fa-pen"></i> Exams</a>
<a href="marks_report.jsp"><i class="fas fa-table"></i> Tabulation</a>

<% if ("Admin".equalsIgnoreCase(roles) || "Global".equalsIgnoreCase(roles)) { %>
<a href="ApproveAdmission.jsp"><i class="fas fa-check"></i> Approval</a>
<a href="Capcity.jsp"><i class="fas fa-chair"></i> Vacancy</a>
<% } %>

<a href="student_tc_update.jsp"><i class="fas fa-id-card"></i> TC Update</a>

<% } %>

<a href="Logout.jsp"><i class="fas fa-sign-out-alt"></i> Logout</a>
</div>

<!-- ========== HEADER ========== -->
<header>
<div class="brand">Sandur Residential School – <%= MODULE %></div>
<div class="user">
 <div class="avatar"><%= users.substring(0,1).toUpperCase() %></div>
 <div>
   <div><%= users %></div>
   <small><%= roles %></small>
 </div>
</div>
</header>

<!-- ========== MAIN CONTENT ========== -->
<main>
<h2>Welcome, <%= users.toUpperCase() %></h2>
<p>Date: <%= todayDate %></p>
</main>

<script>
document.querySelectorAll('.dropdown-btn').forEach(btn=>{
 btn.onclick=()=>btn.parentElement.classList.toggle('active')
})
</script>

</body>
</html>