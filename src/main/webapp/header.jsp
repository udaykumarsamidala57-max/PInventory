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
    String branches = (String) sesso.getAttribute("branch");

    // Formats date with full day name in the header (e.g., Tuesday, 04 August 2026)
    SimpleDateFormat sdf = new SimpleDateFormat("EEEE, dd MMMM yyyy");
    String todayDate = sdf.format(Calendar.getInstance().getTime());
    
    String initial = (users != null && !users.isEmpty()) ? users.substring(0,1).toUpperCase() : "?";
    int currentYear = Calendar.getInstance().get(Calendar.YEAR);
%>
<%
    String pageTitle = (String) request.getAttribute("pageTitle");
    if(pageTitle == null || pageTitle.trim().isEmpty()){
        pageTitle = "Dashboard";
    }

    String breadcrumb = (String) request.getAttribute("breadcrumb");
    if(breadcrumb == null){
        breadcrumb = "Admissions";
    }
%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.bean.DBUtil5" %>

<%
int urgentCount = 0;
List<String[]> urgentList = new ArrayList<>();

Connection consa = null;
PreparedStatement psaa = null;
ResultSet rsaa = null;

try{
    consa = DBUtil5.getConnection();

    String sql =
    	    "SELECT request_no, location, description, requested_by " +
    	    "FROM service_requests " +
    	    "WHERE (status IS NULL OR UPPER(status) NOT IN ('CLOSED','COMPLETED','SATISFIED')) " +
    	    "ORDER BY id DESC";

    psaa = consa.prepareStatement(sql);
    rsaa = psaa.executeQuery();

    while(rsaa.next()){
        urgentCount++;
        String reqNo = rsaa.getString("request_no");
        String location = rsaa.getString("location");
        String description = rsaa.getString("description");
        String requested_by = rsaa.getString("requested_by");

        urgentList.add(new String[]{
            reqNo, location, description, requested_by
        });
    }
}catch(Exception e){
    e.printStackTrace();
}finally{
    try{ if(rsaa != null) rsaa.close(); }catch(Exception e){}
    try{ if(psaa != null) psaa.close(); }catch(Exception e){}
    try{ if(consa != null) consa.close(); }catch(Exception e){}
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Office Central ERP</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://fonts.googleapis.com/css2?family=Salesforce+Sans:wght@300;400;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
* { margin: 0; padding: 0; box-sizing: border-box; }

:root {
    /* Salesforce Lighting Design System Blue Palette */
    --bg-page: #f3f3f3;
    --bg-sidebar: #1b2a47;
    --bg-sidebar-hover: #223559;
    --bg-sidebar-active: #0176d3;
    --accent-primary: #0176d3;
    --accent-gradient: linear-gradient(180deg, #018ed3, #0176d3);
    
    --text-main: #181818;
    --text-muted: #5e5e5e;
    --border-color: #dddbda;
    --bg-card: #ffffff;
    
    /* System Utility Semantic Colors */
    --color-success: #2e844a;
    --color-danger: #ea001e;
    --color-warning: #b78103;
    --color-info: #0176d3;
    --color-purple: #7f86e1;
    
    --radius-sm: 4px;
    --radius-md: 8px;
    --radius-lg: 12px;
    
    --shadow-sm: 0 2px 2px 0 rgba(0, 0, 0, 0.05);
    --shadow-md: 0 4px 12px 0 rgba(0, 0, 0, 0.08);
    --shadow-lg: 0 12px 28px 0 rgba(0, 0, 0, 0.15);
}

body { 
    font-family: 'Salesforce Sans', 'Inter', sans-serif; 
    background-color: var(--bg-page); 
    color: var(--text-main); 
    transition: padding-left 0.25s cubic-bezier(0.4, 0, 0.2, 1); 
    overflow-x: hidden; 
    min-height: 100vh; 
    position: relative; 
    padding-bottom: 60px;
    padding-left: 260px;
    -webkit-font-smoothing: antialiased;
}

body.sidebar-collapsed {
    padding-left: 0;
}

/* --- Salesforce Modernized Sidebar --- */
.sidebar { 
    position: fixed; 
    top: 0; 
    left: 0; 
    height: 100vh; 
    width: 260px; 
    background: var(--bg-sidebar); 
    color: #ffffff; 
    display: flex; 
    flex-direction: column; 
    padding: 24px 12px; 
    box-shadow: 2px 0 8px rgba(0, 0, 0, 0.1); 
    z-index: 1001; 
    transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1); 
    overflow-y: auto; 
    border-right: 1px solid rgba(255, 255, 255, 0.1);
}

.sidebar h2 { 
    font-weight: 700; 
    font-size: 18px; 
    margin-bottom: 24px; 
    color: #ffffff; 
    padding: 0 12px;
    display: flex;
    align-items: center;
    gap: 10px;
    letter-spacing: 0.5px;
}

.sidebar-label {
    font-size: 11px;
    font-weight: 700;
    color: #919191;
    text-transform: uppercase;
    letter-spacing: 1.2px;
    padding: 20px 12px 6px;
}

.sidebar a, .sidebar .dropdown-btn { 
    display: flex; 
    align-items: center; 
    gap: 10px; 
    color: #e0e0e0; 
    text-decoration: none; 
    padding: 10px 12px; 
    font-size: 13.5px; 
    font-weight: 400;
    border-radius: var(--radius-sm);
    transition: all 0.15s ease; 
    background: none; 
    border: none; 
    width: 100%; 
    cursor: pointer; 
    text-align: left; 
    margin-bottom: 2px;
    position: relative;
}

.sidebar a:hover, .sidebar .dropdown-btn:hover { 
    background: var(--bg-sidebar-hover); 
    color: #ffffff; 
}

.sidebar .dropdown.active .dropdown-btn {
    background: rgba(255, 255, 255, 0.08);
    color: #ffffff;
    font-weight: 600;
}

.sidebar .dropdown-btn i.fa-caret-down {
    margin-left: auto;
    font-size: 11px;
    transition: transform 0.2s ease;
    color: #919191;
}
.dropdown.active .dropdown-btn i.fa-caret-down {
    transform: rotate(180deg);
    color: #ffffff;
}

.dropdown-content { 
    display: none; 
    flex-direction: column; 
    background: rgba(0, 0, 0, 0.12);
    padding: 4px 0;
    margin: 2px 0 6px 0;
    border-radius: var(--radius-sm);
}

.dropdown-content a { 
    font-size: 13px; 
    padding: 8px 14px 8px 34px; 
    color: #c9c9c9; 
    margin-bottom: 0;
}

.dropdown-content a:hover {
    color: #ffffff;
    background: var(--bg-sidebar-active);
}

.dropdown.active .dropdown-content { display: flex; }

/* --- Global Utilities Canvas Header Bar --- */
header { 
    position: fixed; 
    top: 0; 
    left: 260px; 
    right: 0; 
    height: 70px; 
    background: #ffffff; 
    color: var(--text-main); 
    display: flex; 
    align-items: center; 
    justify-content: space-between; 
    padding: 0 24px; 
    border-bottom: 1px solid var(--border-color); 
    z-index: 1000; 
    box-shadow: var(--shadow-sm); 
    transition: left 0.25s cubic-bezier(0.4, 0, 0.2, 1); 
    gap: 16px;
}

.header-left-group {
    display: flex;
    align-items: center;
    gap: 16px;
}

.header-brand-title { 
    color:#FC5005 ; 
    font-weight: 800; 
    font-size: 18px; 
    border-right: 1px solid var(--border-color);
    padding-right: 16px;
    line-height: 1;
}
.header-brand-title span {
    color: #090136;
    font-weight: 800;
    margin-left: 4px;
}

.header-title-wrapper {
    display: flex;
    flex-direction: column;
}

.header-title-wrapper h6 {
    font-size: 10px;
    color: var(--text-muted);
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    line-height: 1;
    margin-bottom: 3px;
}

.header-title-wrapper .adm-title {
    font-size: 16px;
    font-weight: 700;
    color: #080707;
    line-height: 1;
}

.header-center-group {
    display: flex;
    align-items: center;
    gap: 12px;
}

.header-right-group {
    display: flex;
    align-items: center;
    gap: 16px;
}

.toggle-btn { 
    background: #ffffff; 
    border: 1px solid var(--border-color); 
    color: #747474; 
    font-size: 14px; 
    cursor: pointer; 
    width: 34px; 
    height: 34px; 
    border-radius: var(--radius-sm); 
    display: flex; 
    align-items: center; 
    justify-content: center; 
    transition: all 0.15s ease;
}
.toggle-btn:hover {
    background: #f3f3f3;
    color: var(--text-main);
}

.user-info-card { 
    display: flex; 
    align-items: center; 
    gap: 10px;
    border-left: 1px solid var(--border-color);
    padding-left: 16px;
}

.user-initials { 
    width: 34px; 
    height: 34px; 
    border-radius: 50%; 
    background: #5a6e85; 
    color: white; 
    display: flex; 
    align-items: center; 
    justify-content: center; 
    font-weight: 700; 
    font-size: 13px; 
}

.user-meta { display: flex; flex-direction: column; }
.user-meta .u-name { font-size: 13px; font-weight: 600; color: #080707; text-transform: capitalize; }
.user-meta .u-role { font-size: 11px; color: var(--text-muted); text-transform: uppercase;}

/* --- Modern Main Workspace Area --- */
main { padding: 94px 24px 24px; transition: margin-left 0.25s cubic-bezier(0.4, 0, 0.2, 1); }

/* Dynamic Live IST Clock Styling */
.live-clock-badge {
    color: var(--text-main);
    font-size: 12px;
    font-weight: 600;
    background: #eef4f9;
    padding: 6px 12px;
    border-radius: var(--radius-sm);
    border: 1px solid #c9deee;
    display: flex;
    align-items: center;
    gap: 6px;
    font-variant-numeric: tabular-nums;
    margin: 0;
}
.live-clock-badge .clock-time {
    color: var(--accent-primary);
    font-weight: 700;
    padding-left: 6px;
    border-left: 1px solid #c9deee;
}

/* --- Salesforce Classic Style Exceptions System --- */
.urgent-wrapper { position: relative; display: inline-block; }
.urgent-header {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    cursor: pointer;
    padding: 6px 12px;
    border-radius: var(--radius-sm);
    background: #fff0f0;
    border: 1px solid #fac7c7;
    color: var(--color-danger);
    font-size: 12px;
    font-weight: 600;
    transition: background 0.15s ease;
}
.urgent-header:hover {
    background: #ffe5e5;
}

.urgent-popup {
    display: none;
    position: absolute;
    top: 45px;
    right: 0;
    width: 360px;
    max-height: 400px;
    overflow-y: auto;
    background: #ffffff;
    border-radius: var(--radius-sm);
    box-shadow: var(--shadow-lg);
    border: 1px solid var(--border-color);
    z-index: 9999;
    padding: 16px;
}
.popup-title {
    font-size: 12px;
    font-weight: 700;
    color: #080707;
    margin-bottom: 12px;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 8px;
    text-transform: uppercase;
}
.urgent-item {
    padding: 12px;
    border-radius: var(--radius-sm);
    background: #f9f9f9;
    margin-bottom: 10px;
    border: 1px solid var(--border-color);
    border-left: 3px solid var(--color-danger);
}
.urgent-item:last-child { margin-bottom: 0; }
.req-no { font-size: 12.5px; font-weight: 600; color: #080707; }
.req-location { font-size: 11.5px; color: var(--text-muted); margin-top: 4px; }
.req-desc { font-size: 12px; color: #3e3e3e; margin-top: 6px; line-height: 1.5; }

/* --- Minimal Fluid Layout System Footer --- */
footer { 
    position: fixed; 
    bottom: 0; 
    left: 260px; 
    right: 0; 
    background: #ffffff; 
    color: var(--text-muted); 
    text-align: center; 
    padding: 14px 24px; 
    font-size: 12px; 
    border-top: 1px solid var(--border-color); 
    transition: left 0.25s cubic-bezier(0.4, 0, 0.2, 1); 
    z-index: 1000; 
}
.footer-badge { display: flex; align-items: center; justify-content: center; gap: 10px; flex-wrap: wrap; }
.footer-badge .brand { font-weight: 600; color: #080707; }
.footer-badge .dot { width: 4px; height: 4px; background: var(--border-color); border-radius: 50%; }

body.sidebar-collapsed header { left: 0; }
body.sidebar-collapsed main { margin-left: 0; }
body.sidebar-collapsed footer { left: 0; }
body.sidebar-collapsed .sidebar { transform: translateX(-100%); }

/* Global Color Utility Systems */
.text-primary { color: var(--accent-primary) !important; }
.text-success { color: var(--color-success) !important; }
.text-danger { color: var(--color-danger) !important; }
.text-warning { color: var(--color-warning) !important; }
.text-info { color: var(--color-info) !important; }
.text-purple { color: var(--color-purple) !important; }
.text-secondary { color: var(--text-muted) !important; }

@media (max-width: 1024px) {
    body { padding-left: 0; }
    header { left: 0; }
    footer { left: 0; }
    .sidebar { transform: translateX(-100%); }
    body:not(.sidebar-collapsed) .sidebar { transform: translateX(0); }
    main { padding-left: 16px; padding-right: 16px; }
}
</style>
</head>

<body class="sidebar-collapsed">

<div class="sidebar" id="sidebar">
  <h2><i class="fa-solid fa-layer-group"></i> <%= branches.toUpperCase() %> Workspace</h2>
<% if (!"HOSTEL".equalsIgnoreCase(depts)){ %>
  <div class="sidebar-label">Inventory Platform</div>
  <a href="Home"><i class="fa-solid fa-chart-pie text-success"></i> Dashboard</a>

  <div class="dropdown">
    <button class="dropdown-btn"><i class="fa-solid fa-file-invoice text-primary"></i> Indent Records <i class="fa-solid fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="IndentServlet"><i class="fa-solid fa-square-plus text-success"></i> Item Requisition Form</a>
      <a href="IndentlistServlet"><i class="fa-solid fa-list-check text-info"></i> Indent Report</a>
      <a href="InventoryItems.jsp"><i class="fa-solid fa-box text-primary"></i> Item Master</a>
      <% if ("Global".equalsIgnoreCase(roles) || "Incharge".equalsIgnoreCase(roles) || "Admin".equalsIgnoreCase(roles)) { %>
        <a href="AIndentListServlet"><i class="fa-solid fa-clipboard-check text-warning"></i> Approve Indent</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles) || "A_Veeresh".equalsIgnoreCase(users)) { %>
        <a href="DIndentListServlet"><i class="fa-solid fa-utensils text-warning"></i> Approve Dining Indent</a>
      <% } %>
    </div>
  </div>

  <% if ("Global".equalsIgnoreCase(roles) ||
       "Store".equalsIgnoreCase(depts) ||
       "finance".equalsIgnoreCase(depts)) { %>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fa-solid fa-truck-ramp-box text-warning"></i> Stock Dispersal <i class="fa-solid fa-caret-down"></i></button>
    <div class="dropdown-content">
       <% if ("Global".equalsIgnoreCase(roles)|| "Store".equalsIgnoreCase(depts)) { %>
      <a href="IssueServlet"><i class="fa-solid fa-dolly text-info"></i> Issue Items</a>
       <% } %>
      <a href="Issuereport.jsp"><i class="fa-solid fa-receipt text-danger"></i> Issue Report</a>
    </div>
  </div>
   <% } %>

  <div class="dropdown">
    <button class="dropdown-btn"><i class="fa-solid fa-cart-shopping text-danger"></i> Purchase Execution <i class="fa-solid fa-caret-down"></i></button>
    <div class="dropdown-content">
      <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts) || "Store".equalsIgnoreCase(depts)) { %>
        <a href="POListServlet"><i class="fa-solid fa-file-circle-check text-success"></i> Approve PO</a>
        <a href="ListPO.jsp"><i class="fa-solid fa-clipboard-list text-warning"></i> PO Report</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts)) { %>
        <a href="IndentPO"><i class="fa-solid fa-file-circle-plus text-primary"></i> Create Purchase Order</a>
        <a href="GRNServlet"><i class="fa-solid fa-warehouse text-success"></i> GRN Entry</a>
        <a href="viewGRN"><i class="fa-solid fa-chart-simple text-success"></i> GRN Report</a>
        <a href="VendorMaster.jsp"><i class="fa-solid fa-address-book text-info"></i> Vendor Master</a>
      <% } %>
    </div>
  </div>

  <% if ("Global".equalsIgnoreCase(roles)|| "Finance".equalsIgnoreCase(depts)|| "Store".equalsIgnoreCase(depts)||"Admin".equalsIgnoreCase(roles)||"Dining Hall".equalsIgnoreCase(depts)) { %>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fa-solid fa-bowl-food text-warning"></i> Dining Hall Operations <i class="fa-solid fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="DiningHallServlet"><i class="fa-solid fa-kitchen-set text-primary"></i> DH Consumption Entry</a>
      
      <a href="DiningHallConsumptionReportServlet"><i class="fa-solid fa-chart-line text-success"></i> Dashboard</a>
      <% if ("Global".equalsIgnoreCase(roles)||"Dining Hall".equalsIgnoreCase(depts)){ %>
       <a href="editConsumption.jsp"><i class="fa-solid fa-chart-line text-success"></i>Edit Consumption</a>
       <% } %>
    </div>
  </div>
  <% } %>

  <div class="dropdown">
    <button class="dropdown-btn"><i class="fa-solid fa-chart-gantt text-purple"></i> Analytics Hub <i class="fa-solid fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="Stock.jsp"><i class="fa-solid fa-boxes-stacked text-info"></i> Stock Report</a>
      <a href="stockReport.jsp"><i class="fa-solid fa-book-open text-primary"></i> Stock Ledger Report</a>
      <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts)) { %>
        <a href="IssueValueReport.jsp"><i class="fa-solid fa-pie-chart text-danger"></i> Consumption Dashboard</a>
      <% } %>
    </div>
  </div>

  <% if ("Global".equalsIgnoreCase(roles.trim()) ||  "Finance".equalsIgnoreCase(depts.trim())){ %>
  <div class="dropdown">
    <button class="dropdown-btn"><i class="fa-solid fa-sliders text-secondary"></i> System Masters <i class="fa-solid fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="ItemsMaster.jsp"><i class="fa-solid fa-box text-primary"></i> Item Master</a>
      <a href="AddStock"><i class="fa-solid fa-square-plus text-success"></i> Add Stock</a>
      <a href="StockVerificationServlet">
        <i class="fas fa-clipboard-check text-success"></i> New Audit
      </a>
      <a href="StockAuditReportServlet">
        <i class="fas fa-chart-bar text-info"></i> Audit Report
      </a>
    </div>
  </div>
  <% } %>

  <% if ("Global".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts)) { %>
  <div class="sidebar-label">Asset Tracking</div>
  <div class="dropdown asset-menu">
    <button class="dropdown-btn"><i class="fa-solid fa-building text-warning"></i> Fixed Assets <i class="fa-solid fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="LocationController"><i class="fa-solid fa-map-location-dot"></i> Locations</a>
      <a href="Staff"><i class="fa-solid fa-users-gear"></i> Employee Matrix</a>
      <a href="CategoryController"><i class="fa-solid fa-tags"></i> Categories</a>
      <a href="AssetServlet"><i class="fa-solid fa-cubes"></i> Asset Creation</a>
      <a href="AssetLocationController"><i class="fa-solid fa-route"></i> Asset Relocation</a>
      <a href="StaffIssued"><i class="fa-solid fa-route"></i> Staff Issued Items</a>
    </div>
  </div>
  <% } %>
<% } %>  

<div class="sidebar-label">Core Operations Desk</div>
<div class="dropdown Service-menu">
    <button class="dropdown-btn">
        <i class="fa-solid fa-headset text-info"></i>
        <span>Service Request</span>
        <i class="fa-solid fa-caret-down"></i>
    </button>
    <div class="dropdown-content">
      <% if ("Global".equalsIgnoreCase(roles) ) { %>
        <a href="<%=request.getContextPath()%>/MasterServlet"><i class="fa-solid fa-network-wired text-danger"></i> Departments</a>
      <% } %>
      <a href="<%=request.getContextPath()%>/RequestBookingServlet"><i class="fa-solid fa-calendar-plus text-success"></i> Book a Request</a>
      <% if ("Global".equalsIgnoreCase(roles) || "A_Veeresh".equalsIgnoreCase(users) || "Admin".equalsIgnoreCase(roles)) { %>
        <a href="<%=request.getContextPath()%>/Assign_ServiceRequestServlet"><i class="fa-solid fa-user-plus text-info"></i> Assign Incharge</a>
      <% } %>
      <a href="<%=request.getContextPath()%>/Incharge"><i class="fa-solid fa-user-check text-info"></i> Assigned to Me</a>
      <a href="<%=request.getContextPath()%>/TrackRequestServlet"><i class="fa-solid fa-magnifying-glass-location text-info"></i> Track Your Request</a>
      <a href="<%=request.getContextPath()%>/Service/Closed.jsp"><i class="fa-solid fa-circle-check text-success"></i> Closed Requests</a>
      <a href="<%=request.getContextPath()%>/RequestReport"><i class="fas fa-chart-bar text-info"></i> Report	</a>
    </div>
</div>

<div class="sidebar-label">Academic Admissions</div>
<div class="dropdown admission-menu">
  <button class="dropdown-btn"><i class="fa-solid fa-user-graduate text-info"></i> Admissions Desk <i class="fa-solid fa-caret-down"></i></button>
  <div class="dropdown-content">
   <% if ("Global".equalsIgnoreCase(roles)|| "Finance".equalsIgnoreCase(depts)||"Academics".equalsIgnoreCase(depts)){ %>
    <a href="dashboard"><i class="fa-solid fa-house"></i> Home</a>
    <a href="admission"><i class="fa-solid fa-magnifying-glass"></i> Enquiries</a>
    <a href="admission_report.jsp"><i class="fa-solid fa-chart-line"></i> Dashboard</a>
   <% } %>
   <% if ("Academics".equalsIgnoreCase(depts)||"Global".equalsIgnoreCase(roles)){ %>
      <a href="enter_marks.jsp"><i class="fa-solid fa-pen-to-square"></i> Marks Entry</a>
   <% } %>
   <% if ("Global".equalsIgnoreCase(roles)|| "Tejkumar".equalsIgnoreCase(users)||"Academics".equalsIgnoreCase(depts)){ %>
      <a href="marks_report.jsp"><i class="fa-solid fa-print"></i> Tabulation</a>
      <a href="ApproveAdmission.jsp"><i class="fa-solid fa-clipboard-check"></i> Approval Desk</a>
   <% } %>
   <% if ("Global".equalsIgnoreCase(roles)){ %>
      <a href="Capcity.jsp"><i class="fa-solid fa-door-open"></i> Vacancy View</a>
   <% } %>
   <% if ("Tejkumar".equalsIgnoreCase(users)){ %>
      <a href="student_tc_update.jsp"><i class="fa-solid fa-user-minus"></i> TC Update</a>
   <% } %>
  </div>
</div>

<% if ("karthik".equalsIgnoreCase(users) || "Principal".equalsIgnoreCase(roles) || "Global".equalsIgnoreCase(roles)) { %>
<div class="sidebar-label">Talent Management</div>
<div class="dropdown recruitment-menu">
  <button class="dropdown-btn"><i class="fa-solid fa-briefcase text-purple"></i> Recruitment <i class="fa-solid fa-caret-down"></i></button>
  <div class="dropdown-content">
    <a href="candidateForm.jsp"><i class="fa-solid fa-file-invoice-dollar"></i> Recruitment Form</a>
    <a href="resume"><i class="fa-solid fa-id-card"></i> Applications View</a>
  </div>
</div>
<% } %>
   
<a href="Logout.jsp" style="margin-top: auto; border-top:1px solid rgba(255,255,255,0.1); background: rgba(234, 0, 30, 0.08); color: #ff5f73;"><i class="fa-solid fa-arrow-right-from-bracket"></i> Sign Out</a>
</div>

<header>
  <!-- Left Side: Toggle, Branding, and Page Title -->
  <div class="header-left-group">
    <button class="toggle-btn" id="menu-toggle"><i class="fa-solid fa-bars"></i></button>
    <div class="header-brand-title"><%= branches.toUpperCase() %><span>|OFFICE CENTRAL ERP</span></div>
    <div class="header-title-wrapper">
      <h6>Overview</h6>
      <div class="adm-title" id="admPageTitle">Dashboard</div>
    </div>
  </div>

  <!-- Center/Right Side: Live Clock, Urgent Alerts, User Profile -->
  <div class="header-right-group">
    <p class="live-clock-badge">
        <span><i class="fa-regular fa-calendar text-primary" style="margin-right: 4px;"></i> <%= todayDate %></span>
        <span class="clock-time"><i class="fa-regular fa-clock text-primary" style="margin-right: 4px;"></i> <span id="istClock">--:--:-- -- IST</span></span>
    </p>

    <% if ("Admin".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts) || "Global".equalsIgnoreCase(roles)) { %>    
       <% if(urgentCount > 0){ %>
        <div class="urgent-wrapper">
            <span class="urgent-header" onclick="toggleUrgentPopup()">
                <i class="fa-solid fa-circle-exclamation text-danger"></i> <%= urgentCount %> Open Service Requests
            </span>

            <div class="urgent-popup" id="urgentPopup">
                <div class="popup-title">Open Service Requests</div>
                <% for(String[] row : urgentList){ %>
                    <div class="urgent-item">
                        <div class="req-no">Ticket ID: <%= row[0] %></div>
                        <div class="req-location"><i class="fa-solid fa-location-dot"></i> Zone: <%= row[1] %></div>
                        <div class="req-desc"><%= row[2] %></div>
                        <div class="req-location" style="margin-top:8px; color:var(--color-danger); font-weight: 600;"><i class="fa-solid fa-circle-user"></i> Requestor: <%= row[3] %></div>
                    </div>
                <% } %>
            </div>
        </div>
        <% } %>
    <% } %>

    <div class="user-info-card">
      <div class="user-initials"><%= initial %></div>
      <div class="user-meta">
        <span class="u-name"><%= users.toLowerCase() %></span>
        <span class="u-role"><i class="fa-solid fa-shield-halved text-primary"></i> <%= roles %></span>
      </div>
    </div>
  </div>
</header>

<main>
  <!-- Content area reserved for specific page forms/tables -->
</main>

<footer>
    <div class="footer-badge">
        <i class="fa-solid fa-code-branch text-primary"></i>
        <span class="brand"><%= branches.toUpperCase() %></span>
        <span class="dot"></span>
        <span class="tagline">OFFICE CENTRAL ERP</span>
        <span class="dot"></span>
        <span class="developer">BY SSS IT</span>
        <span class="dot"></span>
        <span class="year">© 2026</span>
    </div>
</footer>

<script>
// --- Real-time IST Dynamic Moving Clock ---
function updateISTClock() {
    const clockElement = document.getElementById("istClock");
    if (!clockElement) return;

    const options = {
        timeZone: 'Asia/Kolkata',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: true
    };

    const formatter = new Intl.DateTimeFormat('en-IN', options);
    clockElement.innerText = formatter.format(new Date()).toUpperCase() + " IST";
}

document.addEventListener("DOMContentLoaded", function () {
    // Initial call & ticking interval setup
    updateISTClock();
    setInterval(updateISTClock, 1000);

    let title = document.title;
    title = title.replace(" - SANPOLY", "").trim();
    if(document.getElementById("admPageTitle")) {
        document.getElementById("admPageTitle").innerText = title;
    }

    let path = window.location.pathname;
    let parts = path.split("/").filter(p => p !== "");

    if(parts.length > 0){
        parts.shift();
    }

    let formatted = parts.map(p => {
        return p.replace(".jsp", "").replace(/([A-Z])/g, " $1").trim();
    });

    let breadcrumb = "Home";
    formatted.forEach(p => { breadcrumb += " / " + p; });

    if(document.getElementById("admBreadcrumb")) {
        document.getElementById("admBreadcrumb").innerText = breadcrumb;
    }
});

document.querySelectorAll('.dropdown-btn').forEach(btn => {
  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    const currentDropdown = btn.parentElement;
    document.querySelectorAll('.dropdown').forEach(drop => {
      if (drop !== currentDropdown) drop.classList.remove('active');
    });
    currentDropdown.classList.toggle('active');
  });
});

const toggleBtn = document.getElementById('menu-toggle');
toggleBtn.addEventListener('click', (e) => {
  e.stopPropagation();
  document.body.classList.toggle('sidebar-collapsed');
});

function toggleUrgentPopup(){
    let popup = document.getElementById("urgentPopup");
    popup.style.display = (popup.style.display === "block") ? "none" : "block";
}

document.addEventListener("click", function(event){
    let wrapper = document.querySelector(".urgent-wrapper");
    if (wrapper && !wrapper.contains(event.target)){
        let popup = document.getElementById("urgentPopup");
        if(popup) popup.style.display = "none";
    }
});
</script>
</body>
</html>