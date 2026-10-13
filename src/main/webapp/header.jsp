<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>
<%@ page import="java.util.Calendar, java.text.SimpleDateFormat" %>
<%
    HttpSession sesso = request.getSession(false);

    if (sesso == null || sesso.getAttribute("username") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String users = (String) sesso.getAttribute("username");
    String roles = (String) sesso.getAttribute("role");
    String depts = (String) sesso.getAttribute("department");
    String branchess = (String) sesso.getAttribute("branch");

    if (users == null) users = "";
    if (roles == null) roles = "";
    if (depts == null) depts = "";
    if (branchess == null || branchess.trim().isEmpty()) branchess = "SRS";

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
Map<String, List<String[]>> urgentGroupedMap = new LinkedHashMap<>();

Connection consa = null;
PreparedStatement psaa = null;
ResultSet rsaa = null;

try {
    consa = DBUtil5.getConnection(branchess);

    String sql =
        "SELECT sr.request_no, " +
        "       COALESCE(d.department_name, 'General / Unassigned') AS department_name, " +
        "       sr.location, " +
        "       sr.description, " +
        "       sr.requested_by " +
        "FROM service_requests sr " +
        "LEFT JOIN departments d ON sr.department_id = d.id " +
        "WHERE (sr.status IS NULL OR UPPER(sr.status) NOT IN ('CLOSED','COMPLETED','SATISFIED')) " +
        "ORDER BY d.department_name ASC, sr.id DESC";

    psaa = consa.prepareStatement(sql);
    rsaa = psaa.executeQuery();

    while (rsaa.next()) {
        urgentCount++;

        String requestNo   = rsaa.getString("request_no");
        String department  = rsaa.getString("department_name");
        String location    = rsaa.getString("location");
        String description = rsaa.getString("description");
        String requestedBy = rsaa.getString("requested_by");

        String[] requestData = new String[] {
            requestNo,
            department,
            location,
            description,
            requestedBy
        };

        if (!urgentGroupedMap.containsKey(department)) {
            urgentGroupedMap.put(department, new ArrayList<String[]>());
        }
        urgentGroupedMap.get(department).add(requestData);
    }

} catch (Exception e) {
    e.printStackTrace();
} finally {
    try {
        if (rsaa != null) rsaa.close();
    } catch (Exception e) {
        e.printStackTrace();
    }

    try {
        if (psaa != null) psaa.close();
    } catch (Exception e) {
        e.printStackTrace();
    }

    try {
        if (consa != null) consa.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
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

<link rel="stylesheet" href="<%= request.getContextPath() %>/CSS/header.css?v=20261013e">
</head>

<body class="sidebar-collapsed">

<!-- Mobile Sidebar Backdrop Overlay -->
<div class="sidebar-overlay" id="sidebarOverlay"></div>

<div class="sidebar" id="sidebar">
  <h2><i class="fa-solid fa-layer-group"></i> <%= branchess.toUpperCase() %> Workspace</h2>
<% if (!"HOSTEL".equalsIgnoreCase(depts)){ %>
  <div class="sidebar-label">Inventory Platform</div>
  <a href="Home"><i class="fa-solid fa-chart-pie text-success"></i> Dashboard</a>

  <div class="dropdown">
    <button class="dropdown-btn"><i class="fa-solid fa-file-invoice text-primary"></i> Indent Records <i class="fa-solid fa-caret-down"></i></button>
    <div class="dropdown-content">
      <a href="<%= request.getContextPath() %>/IndentServlet"><i class="fa-solid fa-square-plus text-success"></i> Item Requisition Form</a>
      <a href="<%= request.getContextPath() %>/IndentlistServlet"><i class="fa-solid fa-list-check text-info"></i> Indent Report</a>
      <a href="InventoryItems.jsp"><i class="fa-solid fa-box text-primary"></i> Item Master</a>
      <% if ("Global".equalsIgnoreCase(roles) || "Incharge".equalsIgnoreCase(roles) || "Admin".equalsIgnoreCase(roles)) { %>
        <a href="<%= request.getContextPath() %>/AIndentListServlet"><i class="fa-solid fa-clipboard-check text-warning"></i> Approve Indent</a>
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
        <a href="VendorMaster.jsp"><i class="fa-solid fa-address-book text-info"></i> Vendor Master</a>
      <% } %>
      <% if ("Global".equalsIgnoreCase(roles)|| "Finance".equalsIgnoreCase(roles) || "Store".equalsIgnoreCase(depts)){ %>
      <a href="viewGRN"><i class="fa-solid fa-chart-simple text-success"></i> GRN Report</a>
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
      <a href="MenuItemsServlet"><i class="fa-solid fa-square-plus text-success"></i>Dining Hall Menu Config</a>
      <a href="StockVerificationServlet"><i class="fas fa-clipboard-check text-success"></i> New Audit</a>
      <a href="StockAuditReportServlet"><i class="fas fa-chart-bar text-info"></i> Audit Report</a>
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
      <a href="<%=request.getContextPath()%>/RequestReport"><i class="fas fa-chart-bar text-info"></i> Report</a>
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
   
<% if ("Global".equalsIgnoreCase(roles)) { %>
<a href="<%= request.getContextPath() %>/StoreAccessAdminServlet"><i class="fa-solid fa-user-lock"></i> Assign Stores</a>
<% } %>
<a href="<%= request.getContextPath() %>/SelectStoreServlet"><i class="fa-solid fa-code-branch"></i> Change Store</a>
<a href="<%= request.getContextPath() %>/Logout.jsp" style="margin-top: auto; border-top:1px solid rgba(255,255,255,0.1); background: rgba(234, 0, 30, 0.08); color: #ff5f73;"><i class="fa-solid fa-arrow-right-from-bracket"></i> Sign Out</a>
</div>

<header>
  <div class="header-left-group">
    <button class="toggle-btn" id="menu-toggle"><i class="fa-solid fa-bars"></i></button>
    <div class="header-brand-title"><%= branchess.toUpperCase() %><span>|OFFICE CENTRAL ERP</span></div>
    <div class="header-title-wrapper">
      <h6>Overview</h6>
      <div class="adm-title" id="admPageTitle">Dashboard</div>
    </div>
  </div>

  <div class="header-right-group">
    <p class="live-clock-badge">
        <span><i class="fa-regular fa-calendar text-primary" style="margin-right: 4px;"></i> <%= todayDate %></span>
        <span class="clock-time"><i class="fa-regular fa-clock text-primary" style="margin-right: 4px;"></i> <span id="istClock">--:--:-- -- IST</span></span>
    </p>

    <% if ("Admin".equalsIgnoreCase(roles) || "Finance".equalsIgnoreCase(depts) || "Global".equalsIgnoreCase(roles)) { %>    
       <% if(urgentCount > 0){ %>
        <div class="urgent-wrapper">
            <button type="button" class="urgent-header" onclick="toggleUrgentPopup(event)" aria-haspopup="true" aria-controls="urgentPopup">
                <span class="urgent-dot"></span>
                <span class="urgent-count"><%= urgentCount %></span>
                <span class="urgent-label">Open Service Requests</span>
                <i class="fa-solid fa-chevron-down urgent-caret"></i>
            </button>

            <div class="urgent-popup" id="urgentPopup" role="dialog" aria-label="Open service requests">
                <div class="sr-pop-head">
                    <div class="sr-icon-tile"><i class="fa-solid fa-screwdriver-wrench"></i></div>
                    <div class="sr-pop-titles">
                        <span class="sr-eyebrow">Service Requests</span>
                        <span class="sr-pop-title">Open Requests</span>
                    </div>
                    <div class="sr-pop-stat">
                        <span class="sr-pop-stat-num"><%= urgentCount %></span>
                        <span class="sr-pop-stat-lbl"><%= urgentGroupedMap.size() %> dept<%= urgentGroupedMap.size() == 1 ? "" : "s" %></span>
                    </div>
                    <button type="button" class="sr-expand-icon" onclick="openUrgentModal()" title="Expand to full view" aria-label="Expand to full view">
                        <i class="fa-solid fa-up-right-and-down-left-from-center"></i>
                    </button>
                </div>

                <div class="popup-body">
                    <% for(Map.Entry<String, List<String[]>> entry : urgentGroupedMap.entrySet()){
                         String deptName = entry.getKey();
                         List<String[]> deptRequests = entry.getValue();
                    %>
                        <div class="sr-group">
                            <div class="dept-group-header">
                                <span class="sr-group-name"><%= deptName %></span>
                                <span class="dept-badge-count"><%= deptRequests.size() %></span>
                            </div>
                            <% for(String[] row : deptRequests){ %>
                                <div class="urgent-item">
                                    <div class="urgent-item-header">
                                        <span class="req-no"><%= row[0] %></span>
                                        <span class="req-location"><i class="fa-solid fa-location-dot"></i><%= row[2] != null ? row[2] : "N/A" %></span>
                                    </div>
                                    <div class="req-desc"><%= row[3] %></div>
                                    <div class="req-user"><i class="fa-regular fa-user"></i><%= row[4] %></div>
                                </div>
                            <% } %>
                        </div>
                    <% } %>
                </div>

                <div class="sr-pop-foot">
                    <button type="button" class="popup-expand-btn" onclick="openUrgentModal()">
                        <i class="fa-solid fa-up-right-and-down-left-from-center"></i> Expand &middot; View all <%= urgentCount %> requests
                    </button>
                </div>
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

<div class="urgent-modal-overlay" id="urgentModal" onclick="if(event.target===this) closeUrgentModal()">
    <div class="urgent-modal-content" role="dialog" aria-modal="true" aria-labelledby="srModalTitle">
        <div class="modal-header">
            <div class="sr-head-left">
                <div class="sr-icon-tile sr-icon-tile-lg"><i class="fa-solid fa-screwdriver-wrench"></i></div>
                <div>
                    <span class="sr-eyebrow">Service Requests</span>
                    <h3 id="srModalTitle">Open Requests Monitor</h3>
                </div>
            </div>
            <div class="sr-head-stats">
                <div class="sr-kpi">
                    <span class="sr-kpi-lbl">Open</span>
                    <span class="sr-kpi-val sr-kpi-alert"><%= urgentCount %></span>
                </div>
                <div class="sr-kpi">
                    <span class="sr-kpi-lbl">Departments</span>
                    <span class="sr-kpi-val"><%= urgentGroupedMap.size() %></span>
                </div>
                <button type="button" class="modal-close-btn" onclick="closeUrgentModal()" aria-label="Close"><i class="fa-solid fa-xmark"></i></button>
            </div>
        </div>

        <div class="modal-toolbar">
            <div class="modal-search-wrapper">
                <i class="fa-solid fa-magnifying-glass"></i>
                <input type="text" id="modalSearchInput" class="modal-search-input" placeholder="Search ticket, location, description or requestor" oninput="filterModalTable()">
            </div>
            <select id="modalDeptFilter" class="sr-select" onchange="filterModalTable()">
                <option value="">All departments</option>
                <% for(String dn : urgentGroupedMap.keySet()){ %>
                    <option value="<%= dn %>"><%= dn %></option>
                <% } %>
            </select>
            <span class="sr-result-count" id="srResultCount"><%= urgentCount %> of <%= urgentCount %> requests</span>
        </div>

        <div class="modal-body">
            <table class="modal-table" id="modalRequestsTable">
                <thead>
                    <tr>
                        <th style="width:130px;">Ticket</th>
                        <th style="width:190px;">Department</th>
                        <th style="width:200px;">Location</th>
                        <th>Description</th>
                        <th style="width:190px;">Requested By</th>
                    </tr>
                </thead>
                <tbody>
                    <% for(Map.Entry<String, List<String[]>> entry : urgentGroupedMap.entrySet()){
                         String deptName = entry.getKey();
                         List<String[]> deptRequests = entry.getValue();
                         for(String[] row : deptRequests){
                             String reqBy = row[4] != null ? row[4] : "";
                             String reqInit = reqBy.trim().isEmpty() ? "?" : reqBy.trim().substring(0,1).toUpperCase();
                    %>
                        <tr data-dept="<%= deptName %>">
                            <td><span class="sr-ticket"><%= row[0] %></span></td>
                            <td><span class="badge-dept"><%= deptName %></span></td>
                            <td class="sr-muted"><i class="fa-solid fa-location-dot"></i> <%= row[2] != null ? row[2] : "N/A" %></td>
                            <td class="sr-desc-cell"><%= row[3] %></td>
                            <td><span class="sr-person"><span class="sr-avatar"><%= reqInit %></span><%= reqBy %></span></td>
                        </tr>
                    <%   }
                       }
                    %>
                </tbody>
            </table>
            <div class="sr-empty" id="srEmpty">No requests match your search.</div>
        </div>
        <div class="sr-modal-foot">
            <span class="sr-foot-note"><i class="fa-solid fa-circle-info"></i> Showing requests not yet Closed, Completed or Satisfied</span>
            <button type="button" class="sr-btn-neutral" onclick="closeUrgentModal()">Close</button>
        </div>
    </div>
</div>

<main>
</main>

<footer>
    <div class="footer-badge">
        <i class="fa-solid fa-code-branch text-primary"></i>
        <span class="brand"><%= branchess.toUpperCase() %></span>
        <span class="dot"></span>
        <span class="tagline">OFFICE CENTRAL ERP</span>
        <span class="dot"></span>
        <span class="developer">BY SSS IT</span>
        <span class="dot"></span>
        <span class="year">© 2026</span>
    </div>
</footer>

<script>
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

// Close sidebar on mobile overlay click
const sidebarOverlay = document.getElementById('sidebarOverlay');
if (sidebarOverlay) {
  sidebarOverlay.addEventListener('click', () => {
    document.body.classList.add('sidebar-collapsed');
  });
}

function toggleUrgentPopup(e){
    if (e) e.stopPropagation();
    let popup = document.getElementById("urgentPopup");
    let open = popup.style.display !== "block";
    popup.style.display = open ? "block" : "none";
    let btn = document.querySelector(".urgent-header");
    if (btn) btn.classList.toggle("is-open", open);
}

function openUrgentModal(){
    document.getElementById("urgentPopup").style.display = "none";
    let btn = document.querySelector(".urgent-header");
    if (btn) btn.classList.remove("is-open");
    document.getElementById("urgentModal").classList.add("active");
    document.body.style.overflow = "hidden";
    let s = document.getElementById("modalSearchInput");
    if (s) setTimeout(function(){ s.focus(); }, 50);
}

function closeUrgentModal(){
    document.getElementById("urgentModal").classList.remove("active");
    document.body.style.overflow = "";
}

function filterModalTable() {
    let filter = document.getElementById("modalSearchInput").value.toUpperCase();
    let deptSel = document.getElementById("modalDeptFilter");
    let dept = deptSel ? deptSel.value : "";
    let rows = document.querySelectorAll("#modalRequestsTable tbody tr");
    let shown = 0;
    rows.forEach(function(tr){
        let ok = tr.innerText.toUpperCase().indexOf(filter) > -1
              && (!dept || tr.getAttribute("data-dept") === dept);
        tr.style.display = ok ? "" : "none";
        if (ok) shown++;
    });
    let c = document.getElementById("srResultCount");
    if (c) c.innerText = shown + " of " + rows.length + " requests";
    let empty = document.getElementById("srEmpty");
    if (empty) empty.style.display = shown === 0 ? "block" : "none";
}

document.addEventListener("keydown", function(e){
    if (e.key === "Escape") {
        let m = document.getElementById("urgentModal");
        if (m && m.classList.contains("active")) closeUrgentModal();
        let p = document.getElementById("urgentPopup");
        if (p) p.style.display = "none";
    }
});

document.addEventListener("click", function(event){
    let wrapper = document.querySelector(".urgent-wrapper");
    if (wrapper && !wrapper.contains(event.target)){
        let popup = document.getElementById("urgentPopup");
        if(popup) popup.style.display = "none";
        let btn = document.querySelector(".urgent-header");
        if (btn) btn.classList.remove("is-open");
    }
});
</script>
</body>
</html>
