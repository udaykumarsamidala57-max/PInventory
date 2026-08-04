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
// Map to group requests by Department Name -> List of requests
Map<String, List<String[]>> urgentGroupedMap = new LinkedHashMap<>();

Connection consa = null;
PreparedStatement psaa = null;
ResultSet rsaa = null;

try {
    consa = DBUtil5.getConnection();

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

<style>
* { margin: 0; padding: 0; box-sizing: border-box; }

:root {
    /* Premium Salesforce Lightning Design System Palette */
    --bg-page: #f3f3f3;
    --bg-sidebar: #032d60; /* Deep Salesforce Brand Navy */
    --bg-sidebar-hover: #004487;
    --bg-sidebar-active: #0176d3;
    
    --accent-primary: #0176d3;
    --accent-dark: #032d60;
    --accent-gradient: linear-gradient(135deg, #032d60 0%, #0176d3 100%);
    --accent-gradient-hover: linear-gradient(135deg, #014486 0%, #018ed3 100%);
    
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
    --radius-pill: 50px;
    
    --shadow-sm: 0 2px 4px rgba(0, 0, 0, 0.05);
    --shadow-md: 0 6px 16px rgba(3, 45, 96, 0.08);
    --shadow-lg: 0 16px 36px rgba(3, 45, 96, 0.20);
    --shadow-glow-danger: 0 4px 14px rgba(234, 0, 30, 0.25);
}

body { 
    font-family: 'Salesforce Sans', 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; 
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
    box-shadow: 4px 0 16px rgba(0, 0, 0, 0.12); 
    z-index: 1001; 
    transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1); 
    overflow-y: auto; 
    border-right: 1px solid rgba(255, 255, 255, 0.08);
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
    color: #8faac9;
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
    background: rgba(255, 255, 255, 0.12);
    color: #ffffff;
    font-weight: 600;
}

.sidebar .dropdown-btn i.fa-caret-down {
    margin-left: auto;
    font-size: 11px;
    transition: transform 0.2s ease;
    color: #8faac9;
}
.dropdown.active .dropdown-btn i.fa-caret-down {
    transform: rotate(180deg);
    color: #ffffff;
}

.dropdown-content { 
    display: none; 
    flex-direction: column; 
    background: rgba(0, 0, 0, 0.2);
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
    color: #FC5005; 
    font-weight: 800; 
    font-size: 18px; 
    border-right: 1px solid var(--border-color);
    padding-right: 16px;
    line-height: 1;
}
.header-brand-title span {
    color: var(--accent-dark);
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
    background: var(--accent-dark); 
    color: white; 
    display: flex; 
    align-items: center; 
    justify-content: center; 
    font-weight: 700; 
    font-size: 13px; 
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.user-meta { display: flex; flex-direction: column; }
.user-meta .u-name { font-size: 13px; font-weight: 600; color: #080707; text-transform: capitalize; }
.user-meta .u-role { font-size: 11px; color: var(--text-muted); text-transform: uppercase;}

/* Modern Main Workspace Area */
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


/* ==========================================================================
   CLASSY & CONFIDENT SALESFORCE URGENT POPUP STYLING
   ========================================================================== */

.urgent-wrapper { 
    position: relative; 
    display: inline-block; 
}

/* Elegant SLDS Alert Trigger Pill */
.urgent-header {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    cursor: pointer;
    padding: 7px 16px;
    border-radius: var(--radius-pill);
    background: #fff0f0;
    border: 1px solid #fca5a5;
    color: var(--color-danger);
    font-size: 12px;
    font-weight: 700;
    letter-spacing: 0.3px;
    transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
    user-select: none;
    box-shadow: 0 2px 6px rgba(234, 0, 30, 0.08);
}

.urgent-header:hover {
    background: var(--color-danger);
    color: #ffffff;
    border-color: var(--color-danger);
    box-shadow: var(--shadow-glow-danger);
    transform: translateY(-1px);
}

/* Sleek Dropdown Popup Container */
.urgent-popup {
    display: none;
    position: absolute;
    top: calc(100% + 12px);
    right: 0;
    width: 440px;
    max-height: 540px;
    background: #ffffff;
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-lg), 0 0 0 1px rgba(0, 0, 0, 0.04);
    border: 1px solid #c9c9c9;
    z-index: 9999;
    overflow: hidden;
    animation: popupSlideDown 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes popupSlideDown {
    from { opacity: 0; transform: translateY(-12px) scale(0.98); }
    to { opacity: 1; transform: translateY(0) scale(1); }
}

/* Salesforce Branded Top Header Bar */
.popup-header-bar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 14px 18px;
    background: var(--accent-gradient);
    color: #ffffff;
    border-bottom: none;
}

.popup-title-group {
    display: flex;
    align-items: center;
    gap: 10px;
}

.popup-title {
    font-size: 13px;
    font-weight: 800;
    color: #ffffff;
    text-transform: uppercase;
    letter-spacing: 0.8px;
}

.popup-action-group {
    display: flex;
    align-items: center;
    gap: 8px;
}

.popup-expand-btn {
    background: rgba(255, 255, 255, 0.15);
    color: #ffffff;
    border: 1px solid rgba(255, 255, 255, 0.3);
    padding: 5px 12px;
    border-radius: var(--radius-pill);
    font-size: 11px;
    font-weight: 700;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    backdrop-filter: blur(4px);
    transition: all 0.2s ease;
}

.popup-expand-btn:hover {
    background: #ffffff;
    color: var(--accent-dark);
    border-color: #ffffff;
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.15);
}

.popup-body {
    padding: 16px;
    max-height: 460px;
    overflow-y: auto;
    background: #f8fafc;
}

/* Custom Scrollbar */
.popup-body::-webkit-scrollbar {
    width: 6px;
}
.popup-body::-webkit-scrollbar-track {
    background: #f1f5f9;
}
.popup-body::-webkit-scrollbar-thumb {
    background: #cbd5e1;
    border-radius: 3px;
}
.popup-body::-webkit-scrollbar-thumb:hover {
    background: #94a3b8;
}

/* Department Group Card Header */
.dept-group-header {
    font-size: 11px;
    font-weight: 800;
    color: var(--accent-dark);
    background: #eef4f9;
    padding: 8px 12px;
    border-radius: var(--radius-sm);
    margin: 16px 0 10px 0;
    text-transform: uppercase;
    letter-spacing: 0.8px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-left: 4px solid var(--accent-primary);
}
.dept-group-header:first-of-type {
    margin-top: 0;
}

.dept-badge-count {
    background: var(--accent-dark);
    color: #ffffff;
    font-size: 10px;
    padding: 2px 8px;
    border-radius: 12px;
    font-weight: 700;
}

/* Refined Elevated Card Styling */
.urgent-item {
    padding: 14px;
    border-radius: var(--radius-md);
    background: #ffffff;
    margin-bottom: 10px;
    border: 1px solid #e2e8f0;
    border-left: 4px solid var(--color-danger);
    box-shadow: var(--shadow-sm);
    transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}
.urgent-item:last-child { margin-bottom: 0; }
.urgent-item:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-md);
    border-color: #cbd5e1;
    border-left-color: var(--color-danger);
}

.urgent-item-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 8px;
}

.req-no { 
    font-size: 11.5px; 
    font-weight: 800; 
    color: #ffffff; 
    background: var(--accent-dark);
    padding: 3px 8px;
    border-radius: var(--radius-sm);
    letter-spacing: 0.5px;
}

.req-location { 
    font-size: 11.5px; 
    font-weight: 700; 
    color: var(--color-success); 
    display: inline-flex;
    align-items: center;
    gap: 4px;
}

.req-desc { 
    font-size: 12.5px; 
    font-weight: 500; 
    color: #1e293b; 
    margin: 8px 0; 
    line-height: 1.5; 
    word-break: break-word;
}

.req-user {
    font-size: 11px;
    font-weight: 600;
    color: var(--accent-primary);
    display: flex;
    align-items: center;
    gap: 6px;
    margin-top: 8px;
    padding-top: 8px;
    border-top: 1px dashed #e2e8f0;
}


/* ==========================================================================
   FULL SCREEN SALESFORCE MODAL DASHBOARD STYLING
   ========================================================================== */

.urgent-modal-overlay {
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background: rgba(3, 45, 96, 0.75); /* Deep Salesforce Navy Overlay */
    backdrop-filter: blur(8px);
    z-index: 10000;
    align-items: center;
    justify-content: center;
    padding: 24px;
}
.urgent-modal-overlay.active {
    display: flex;
}

.urgent-modal-content {
    background: #ffffff;
    width: 95%;
    max-width: 1240px;
    height: 88vh;
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-lg), 0 0 0 1px rgba(255, 255, 255, 0.2);
    display: flex;
    flex-direction: column;
    overflow: hidden;
    animation: modalFadeIn 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes modalFadeIn {
    from { opacity: 0; transform: scale(0.96) translateY(10px); }
    to { opacity: 1; transform: scale(1) translateY(0); }
}

.modal-header {
    background: var(--accent-gradient);
    color: #ffffff;
    padding: 20px 28px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-bottom: 3px solid #014486;
}

.modal-header h3 {
    font-size: 17px;
    font-weight: 800;
    letter-spacing: 0.5px;
    display: flex;
    align-items: center;
    gap: 12px;
}

.modal-close-btn {
    background: rgba(255, 255, 255, 0.15);
    border: 1px solid rgba(255, 255, 255, 0.25);
    color: #ffffff;
    width: 34px;
    height: 34px;
    border-radius: 50%;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    transition: all 0.2s ease;
}
.modal-close-btn:hover {
    background: var(--color-danger);
    border-color: var(--color-danger);
    transform: rotate(90deg);
}

.modal-toolbar {
    padding: 16px 28px;
    background: #f8fafc;
    border-bottom: 1px solid var(--border-color);
    display: flex;
    gap: 16px;
    align-items: center;
}

.modal-search-wrapper {
    position: relative;
}
.modal-search-wrapper i {
    position: absolute;
    left: 14px;
    top: 50%;
    transform: translateY(-50%);
    color: var(--text-muted);
    font-size: 13px;
}

.modal-search-input {
    padding: 9px 14px 9px 38px;
    border: 1px solid #cbd5e1;
    border-radius: var(--radius-md);
    font-size: 13px;
    width: 320px;
    outline: none;
    transition: all 0.2s ease;
}
.modal-search-input:focus {
    border-color: var(--accent-primary);
    box-shadow: 0 0 0 3px rgba(1, 118, 211, 0.18);
    background: #ffffff;
}

.modal-body {
    flex: 1;
    overflow-y: auto;
    padding: 24px 28px;
    background: #ffffff;
}

/* Crisp Salesforce Data Table */
.modal-table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    font-size: 13px;
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    overflow: hidden;
}

.modal-table th {
    background: var(--accent-dark);
    color: #ffffff;
    font-weight: 700;
    text-transform: uppercase;
    font-size: 11px;
    letter-spacing: 0.8px;
    padding: 14px 18px;
    border-bottom: 2px solid var(--border-color);
    position: sticky;
    top: 0;
    z-index: 10;
}

.modal-table td {
    padding: 14px 18px;
    border-bottom: 1px solid var(--border-color);
    vertical-align: middle;
    text-align: left !important;
    color: #1e293b;
}

.modal-table tr:nth-child(even) {
    background-color: #f8fafc;
}

.modal-table tr:hover {
    background-color: #eff6ff;
}

.modal-table tr:last-child td {
    border-bottom: none;
}

.badge-dept {
    background: #eef4f9;
    color: var(--accent-dark);
    padding: 5px 10px;
    border-radius: var(--radius-pill);
    font-size: 11px;
    font-weight: 700;
    border: 1px solid #c9deee;
    display: inline-block;
}


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
    .urgent-popup { width: 340px; right: -60px; }
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
<a href="javascript:void(0);" onclick="openUrgentModal()"><i class="fa-solid fa-clock-rotate-left text-warning"></i> Request Pending <% if(urgentCount > 0){ %><span class="badge bg-danger ms-auto" style="font-size: 0.75rem; padding: 2px 6px; border-radius: 10px; margin-left: 5px;"><%= urgentCount %></span><% } %></a>

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
                <i class="fa-solid fa-triangle-exclamation"></i> <%= urgentCount %> Open Service Requests
            </span>

            <div class="urgent-popup" id="urgentPopup">
                <div class="popup-header-bar">
                    <div class="popup-title-group">
                        <i class="fa-solid fa-bell text-danger"></i>
                        <span class="popup-title">Open Requests</span>
                    </div>
                    <div class="popup-action-group">
                        <button class="popup-expand-btn" onclick="openUrgentModal()"><i class="fa-solid fa-expand"></i> Expand</button>
                    </div>
                </div>
                
                <div class="popup-body">
                    <%-- Categorized Display grouped by Department --%>
                    <% for(Map.Entry<String, List<String[]>> entry : urgentGroupedMap.entrySet()){ 
                         String deptName = entry.getKey();
                         List<String[]> deptRequests = entry.getValue();
                    %>
                        <div class="dept-group-header">
                            <span><i class="fa-solid fa-building text-primary"></i> <%= deptName %></span>
                            <span class="dept-badge-count"><%= deptRequests.size() %></span>
                        </div>

                        <% for(String[] row : deptRequests){ %>
                            <div class="urgent-item">
                                <div class="urgent-item-header">
                                    <span class="req-no">#<%= row[0] %></span>
                                    <span class="req-location"><i class="fa-solid fa-location-dot"></i> <%= row[2] != null ? row[2] : "N/A" %></span>
                                </div>
                                <div class="req-desc"><%= row[3] %></div>
                                <div class="req-user"><i class="fa-solid fa-user-circle"></i> <%= row[4] %></div>
                            </div>
                        <% } %>
                    <% } %>
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

<!-- Full Screen Expanded Modal for Urgent Requests -->
<div class="urgent-modal-overlay" id="urgentModal">
    <div class="urgent-modal-content">
        <div class="modal-header">
            <h3><i class="fa-solid fa-list-check text-primary"></i> Open Service Requests Monitor (<%= urgentCount %> Total)</h3>
            <button class="modal-close-btn" onclick="closeUrgentModal()"><i class="fa-solid fa-xmark"></i></button>
        </div>
        <div class="modal-toolbar">
            <div class="modal-search-wrapper">
                <i class="fa-solid fa-magnifying-glass"></i>
                <input type="text" id="modalSearchInput" class="modal-search-input" placeholder="Search ticket, location, or requestor..." onkeyup="filterModalTable()">
            </div>
        </div>
        <div class="modal-body">
            <table class="modal-table" id="modalRequestsTable">
                <thead>
                    <tr>
                        <th>Ticket ID</th>
                        <th>Department</th>
                        <th>Location / Zone</th>
                        <th>Description</th>
                        <th>Requestor</th>
                    </tr>
                </thead>
                <tbody>
                    <% for(Map.Entry<String, List<String[]>> entry : urgentGroupedMap.entrySet()){ 
                         String deptName = entry.getKey();
                         List<String[]> deptRequests = entry.getValue();
                         for(String[] row : deptRequests){
                    %>
                        <tr>
                            <td><strong class="text-primary"><%= row[0] %></strong></td>
                            <td><span class="badge-dept"><%= deptName %></span></td>
                            <td><i class="fa-solid fa-location-dot text-danger"></i> <%= row[2] != null ? row[2] : "N/A" %></td>
                            <td style="max-width: 400px;"><%= row[3] %></td>
                            <td><i class="fa-solid fa-user text-secondary"></i> <%= row[4] %></td>
                        </tr>
                    <%   } 
                       } 
                    %>
                </tbody>
            </table>
        </div>
    </div>
</div>

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

function openUrgentModal(){
    let popup = document.getElementById("urgentPopup");
    if(popup) popup.style.display = "none";
    document.getElementById("urgentModal").classList.add("active");
}

function closeUrgentModal(){
    document.getElementById("urgentModal").classList.remove("active");
}

function filterModalTable() {
    let input = document.getElementById("modalSearchInput");
    let filter = input.value.toUpperCase();
    let table = document.getElementById("modalRequestsTable");
    let tr = table.getElementsByTagName("tr");

    for (let i = 1; i < tr.length; i++) {
        let tdText = tr[i].innerText;
        if (tdText.toUpperCase().indexOf(filter) > -1) {
            tr[i].style.display = "";
        } else {
            tr[i].style.display = "none";
        }
    }
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