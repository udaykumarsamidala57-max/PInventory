<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>
<%@ page import="java.util.Calendar, java.text.SimpleDateFormat" %>
<%
    String ctx = request.getContextPath(); // Get the application root context
    HttpSession sesso = request.getSession(false);
    if (sesso == null || sesso.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String users = (String) sesso.getAttribute("username");
    String roles = (String) sesso.getAttribute("role");
    String depts = (String) sesso.getAttribute("department");

    // Defensive trimming to prevent "Global " vs "Global" issues
    roles = (roles != null) ? roles.trim() : "";
    depts = (depts != null) ? depts.trim() : "";

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
</head>
<body class="sidebar-collapsed">

<div class="sidebar" id="sidebar">
  <h2><i class="fas fa-box text-primary"></i> Sandur Residential School</h2>

  <div class="sidebar-label">Inventory</div>
  <a href="<%= ctx %>/Home"><i class="fas fa-home text-success"></i> Dashboard</a>

  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-file-alt text-primary"></i> Indent <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="<%= ctx %>/IndentServlet"><i class="fas fa-plus-circle text-success"></i> Item Requisition Form</a>
      <a href="<%= ctx %>/IndentlistServlet"><i class="fas fa-list text-info"></i> Indent Report</a>
      <% if ("Global".equalsIgnoreCase(roles) || "Incharge".equalsIgnoreCase(roles) || "Admin".equalsIgnoreCase(roles)) { %>
        <a href="<%= ctx %>/AIndentListServlet"><i class="fas fa-check-circle text-warning"></i> Approve Indent</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles) || "A_Veeresh".equalsIgnoreCase(users)) { %>
        <a href="<%= ctx %>/DIndentListServlet"><i class="fas fa-check-circle text-warning"></i> Approve Dining Hall Indent</a>
      <% } %>
    </div>
  </div>

  <% if ("Global".equalsIgnoreCase(roles)|| "Store".equalsIgnoreCase(depts)) { %>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-box-open text-warning"></i> Issue <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="<%= ctx %>/IssueServlet"><i class="fas fa-dolly text-info"></i> Issue Items</a>
      <a href="<%= ctx %>/Issuereport.jsp"><i class="fas fa-file-invoice text-danger"></i> Issue Report</a>
    </div>
  </div>
  <% } %>

  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-shopping-cart text-danger"></i> Purchase / PO <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts) || "Store".equalsIgnoreCase(depts)) { %>
        <a href="<%= ctx %>/POListServlet"><i class="fas fa-check-double text-success"></i> Approve PO</a>
        <a href="<%= ctx %>/ListPO.jsp"><i class="fas fa-clipboard-list text-warning"></i> PO Report</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts)) { %>
        <a href="<%= ctx %>/IndentPO"><i class="fas fa-file-signature text-primary"></i> Create Purchase Order</a>
        <a href="<%= ctx %>/GRNServlet"><i class="fas fa-clipboard-check text-success"></i> GRN Entry</a>
        <a href="<%= ctx %>/viewGRN"><i class="fas fa-clipboard-check text-success"></i> GRN Report</a>
        <a href="<%= ctx %>/VendorMaster.jsp"><i class="fas fa-user-tie text-info"></i> Vendor Master</a>
      <% } %>
    </div>
  </div>

  <% if ("Global".equalsIgnoreCase(roles)|| "Finance".equalsIgnoreCase(depts)|| "Store".equalsIgnoreCase(depts)) { %>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-utensils text-warning"></i> Dining Hall <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="<%= ctx %>/DiningHallServlet"><i class="fas fa-receipt text-primary"></i> DH Consumption Entry</a>
      <a href="<%= ctx %>/dining_dashboard.jsp"><i class="fas fa-chart-pie text-success"></i> Dashboard</a>
    </div>
  </div>
  <% } %>

  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-chart-line text-purple"></i> Reports <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="<%= ctx %>/Stock.jsp"><i class="fas fa-boxes text-info"></i> Stock Report</a>
      <a href="<%= ctx %>/stockReport.jsp"><i class="fas fa-book text-primary"></i> Stock Ledger Report</a>
      <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts)) { %>
        <a href="<%= ctx %>/IssueValueReport.jsp"><i class="fas fa-chart-pie text-danger"></i> Consumption Dashboard</a>
      <% } %>
    </div>
  </div>

  <%-- FIXED: "Global" should see Masters regardless of Department --%>
  <% if ("Global".equalsIgnoreCase(roles) || ( "Incharge".equalsIgnoreCase(roles) && "Finance".equalsIgnoreCase(depts) )) { %>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fas fa-cog text-secondary"></i> Masters <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="<%= ctx %>/ItemsMaster.jsp"><i class="fas fa-tags text-primary"></i> Item Master</a>
      <a href="<%= ctx %>/AddStock"><i class="fas fa-plus-square text-success"></i> Add Stock</a>
    </div>
  </div>
  <% } %>

  <div class="sidebar-label">Academic & Students</div>
  
  <div class="dropdown admission-menu">
    <button class="dropdown-btn"><i class="fas fa-graduation-cap text-info"></i> Admissions <i class="fas fa-caret-down"></i></button>
    <div class="dropdown-content">
     <% if ("Global".equalsIgnoreCase(roles)|| "Finance".equalsIgnoreCase(depts)||"Academics".equalsIgnoreCase(depts)){ %>
      <a href="<%= ctx %>/dashboard"><i class="fas fa-home"></i> Home</a>
      <a href="<%= ctx %>/admission"><i class="fas fa-search"></i> Enquiries</a>
      <a href="<%= ctx %>/admission_report.jsp"><i class="fas fa-chart-line"></i> Dashboard</a>
       <% } %>
      <% if ("Academics".equalsIgnoreCase(depts)||"Global".equalsIgnoreCase(roles)){ %>
        <a href="<%= ctx %>/enter_marks.jsp"><i class="fas fa-pen"></i> Marks Entry</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles)|| "Tejkumar".equalsIgnoreCase(users)||"Academics".equalsIgnoreCase(depts)){ %>
        <a href="<%= ctx %>/marks_report.jsp"><i class="fas fa-file-invoice"></i> Tabulation</a>
        <a href="<%= ctx %>/ApproveAdmission.jsp"><i class="fas fa-user-check"></i> Approval</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles)){ %>
        <a href="<%= ctx %>/Capcity.jsp"><i class="fas fa-door-open"></i> Vacancy</a>
      <% } %>
    </div>
  </div>
  
  <a href="<%= ctx %>/Logout.jsp" style="margin-top: auto;"><i class="fas fa-sign-out-alt text-danger"></i> Logout</a>
</div>