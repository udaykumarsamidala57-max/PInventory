<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%
HttpSession sess = request.getSession(false);
if(sess == null || sess.getAttribute("username") == null){
    response.sendRedirect(request.getContextPath()+"/login.jsp");
    return;
}
String username = ((String)sess.getAttribute("username")).toUpperCase();
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>My Service Requests</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<style>
*{ box-sizing:border-box; }
body{
    margin:0;
    font-family:-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background:#f3f3f3;
    color:#181818;
    -webkit-tap-highlight-color: transparent;
}

/* HEADER (Salesforce Style) */
.page-header{
    background:#ffffff;
    padding:10px 14px;
    border-bottom:1px solid #c9c9c9;
    display:flex;
    justify-content:space-between;
    align-items:center;
    position:sticky;
    top:0;
    z-index:99;
}
.header-left{ display:flex; align-items:center; gap:10px; }
.icon-box{
    width:36px;
    height:36px;
    border-radius:4px;
    background:#0176d3;
    display:flex;
    align-items:center;
    justify-content:center;
    color:white;
    font-size:16px;
    flex-shrink: 0;
}
.title h2{ margin:0; font-size:15px; color:#0176d3; font-weight:700; }
.title p{ margin:2px 0 0; font-size:11px; color:#514f4d; }
.user-chip{
    background:#f3f3f3;
    color:#181818;
    padding:6px 10px;
    border-radius:4px;
    font-size:11px;
    font-weight:600;
    border:1px solid #c9c9c9;
    white-space: nowrap;
}

/* CONTAINER */
.container{ max-width:1440px; margin:auto; padding:12px; }

/* ALERTS */
.alert{ padding:12px 14px; border-radius:4px; margin-bottom:12px; font-size:13px; font-weight:600; display:flex; align-items:center; gap:8px;}
.success{ background:#e1f5fe; color:#005fb2; border:1px solid #b8e3fa; }
.error{ background:#fededb; color:#c23934; border:1px solid #faaaa3; }

/* FILTER CONTROLS TOOLBAR */
.filter-toolbar {
    background: #ffffff;
    border: 1px solid #c9c9c9;
    border-radius: 4px;
    padding: 10px 14px;
    margin-bottom: 12px;
    display: flex;
    flex-direction: column;
    gap: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}
.filter-group {
    display: flex;
    align-items: center;
    gap: 8px;
    width: 100%;
}
.filter-label {
    font-size: 11px;
    font-weight: 700;
    color: #514f4d;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    white-space: nowrap;
}
.filter-select {
    width: 100%;
    min-height: 42px; /* Touch-friendly height */
    font-size: 14px;
    border: 1px solid #aeaeae;
    border-radius: 4px;
    padding: 0 32px 0 12px;
    background: #ffffff;
    outline: none;
    -webkit-appearance: none;
    appearance: none;
    background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='6' viewBox='0 0 10 6'><path fill='%23514f4d' d='M0 0l5 5 5-5z'/></svg>");
    background-repeat: no-repeat;
    background-position: right 12px center;
}
.filter-select:focus {
    border-color: #0176d3;
    box-shadow: 0 0 0 2px rgba(1,118,211,0.15);
}

/* COMPACT COMPONENT CARD */
.request-card{
    background:white;
    border-radius:4px;
    border:1px solid #c9c9c9;
    margin-bottom:12px;
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.08);
    overflow: hidden;
}

/* CARD TOP BAR */
.top-row{
    padding:10px 12px;
    border-bottom:1px solid #c9c9c9;
    background:#f8f9fa;
    display:flex;
    flex-direction: column;
    gap: 10px;
}

.header-meta-group {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
}
.request-no{ font-size:15px; font-weight:700; color:#0176d3; }

.header-right-group { 
    display: flex; 
    align-items: center; 
    gap: 8px; 
    flex-wrap: wrap;
}

/* COLLAPSIBLE TOGGLE BUTTON */
.toggle-details-btn {
    width: 100%;
    min-height: 40px;
    background: #ffffff;
    border: 1px solid #0176d3;
    color: #0176d3;
    padding: 8px 14px;
    border-radius: 4px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    transition: all 0.1s ease;
}
.toggle-details-btn:active {
    background: #e0edff;
}
.toggle-details-btn i {
    transition: transform 0.2s ease;
}
.toggle-details-btn.active i {
    transform: rotate(180deg);
}

/* CONVERSATION COUNTER BADGE */
.conversation-counter {
    background: #e2e8f0;
    color: #334155;
    padding: 3px 8px;
    border-radius: 12px;
    font-size: 11px;
    font-weight: 600;
    display: flex;
    align-items: center;
    gap: 5px;
    border: 1px solid #cbd5e1;
    white-space: nowrap;
}

/* STATUS BADGES */
.status-badge{ padding:3px 10px; border-radius:12px; font-size:11px; font-weight:700; text-transform:uppercase; border: 1px solid transparent; white-space: nowrap;}
.open{ background:#fff1d6; color:#8a4b00; border-color:#fcc06f;}
.assigned{ background:#dcfce7; color:#166534; border-color:#86efac;}
.in-progress{ background:#e0edff; color:#1d4ed8; border-color:#93c5fd;}
.pending{ background:#fef3c7; color:#92400e; border-color:#fcd34d;}
.completed{ background:#f3e8ff; color:#7e22ce; border-color:#d8b4fe;}
.satisfied{ background:#d1fae5; color:#065f46; border-color:#6ee7b7;}
.closed{ background:#e2e8f0; color:#334155; border-color:#cbd5e1;}

/* RESPONSIVE SUMMARY DATA GRID */
.summary-section{
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    padding:12px;
    background:#fafaf9;
    gap:10px 12px;
}
.info-box{ min-width: 0; }
.description-box { 
    grid-column: 1 / -1; 
    border-top: 1px solid #e5e5e5; 
    padding-top: 10px; 
    margin-top: 2px;
}
.label{ font-size:10px; color:#514f4d; font-weight:700; margin-bottom:2px; letter-spacing:0.5px; text-transform:uppercase;}
.value{ font-size:13px; color:#181818; font-weight:500; word-break: break-word; }
.description-text{ font-size:13px; color:#181818; line-height:1.4; margin-top:2px; word-break: break-word;}

/* COLLAPSIBLE ANIMATION CONTAINER */
.collapsible-workspace {
    max-height: 2500px;
    opacity: 1;
    overflow: hidden;
    transition: max-height 0.3s ease-in-out, opacity 0.2s ease-in-out;
    border-top: 1px solid #e5e5e5;
}
.collapsible-workspace.collapsed {
    max-height: 0 !important;
    opacity: 0;
    border-top: none !important;
}

/* TWO-COLUMN SPLIT WORKSPACE */
.card-split-workspace{
    display: flex;
    flex-direction: column;
    background: #fff;
}

/* TIMELINE */
.timeline-column{
    padding:12px;
    border-bottom: 1px solid #e5e5e5;
    max-height: 300px;
    overflow-y: auto;
}
.timeline-title, .form-title{ font-size:12px; font-weight:700; color:#181818; margin:0 0 10px 0; text-transform: uppercase; letter-spacing: 0.5px;}

.followup-box{
    position:relative;
    border-radius:4px;
    padding:8px 10px;
    margin-bottom:8px;
    border:1px solid #d8dde6;
}

.followup-requester{ background:#f0f9ff; border-left:4px solid #0176d3; }
.followup-staff{ background:#fff7ed; border-left:4px solid #0176d3; }

.followup-top{
    display:flex;
    flex-direction: column;
    gap:4px;
    margin-bottom:6px;
}

.followup-status{
    font-size:10px;
    font-weight:700;
    background:#e0edff;
    color:#0176d3;
    padding:1px 6px;
    border-radius:2px;
    align-self: flex-start;
}

.followup-staff .followup-status{ background:#ffedd5; color:#c2410c; }
.date{ font-size:11px; color:#747472; display: block; word-break: break-word; }
.remark{ font-size:12px; color:#181818; line-height:1.4; word-break: break-word; }

/* ACTION FORM */
.form-column{ padding:12px; background:#fafaf9; }
.form-vertical{ display:flex; flex-direction:column; gap:10px; }

select, textarea{
    width:100%;
    border:1px solid #c9c9c9;
    border-radius:4px;
    padding:10px 12px;
    font-size:14px; /* Prevents auto-zoom on iOS */
    background:white;
    outline:none;
}
select{ height: 42px; }
select:focus, textarea:focus{ border-color:#0176d3; }
textarea{ min-height:80px; resize:vertical; }

/* BUTTON */
.submit-btn{
    background:#0176d3;
    color:white;
    border:none;
    border-radius:4px;
    padding:12px 16px;
    font-size:14px;
    font-weight:600;
    cursor:pointer;
    width: 100%;
    text-align: center;
    min-height: 44px; /* Touch target size */
}
.submit-btn:active{ background:#015a9e; }

/* EMPTY STATE */
.empty{ background:white; border:1px solid #c9c9c9; border-radius:4px; padding:30px 16px; text-align:center; }
.empty h3{ color:#181818; margin:10px 0 4px 0; font-size:15px;}
.empty p{ color:#747472; margin:0; font-size:12px;}

/* TABLET AND DESKTOP RESPONSIVENESS */
@media(min-width: 600px) {
    .top-row {
        flex-direction: row;
        align-items: center;
        justify-content: space-between;
    }
    .toggle-details-btn { width: auto; }
    .header-meta-group { width: auto; gap: 12px; }
    .filter-toolbar { flex-direction: row; }
    .filter-group { width: auto; }
    .filter-select { width: 240px; }
    .followup-top { flex-direction: row; align-items: center; justify-content: space-between; }
    .followup-status { align-self: auto; }
}

@media(min-width: 900px) {
    .container { padding: 16px; }
    .summary-section { grid-template-columns: repeat(5, 1fr) 2fr; }
    .description-box { 
        grid-column: auto; 
        border-top: none; 
        border-left: 1px solid #e5e5e5; 
        padding-top: 0; 
        padding-left: 14px; 
        margin-top: 0;
    }
    .card-split-workspace { grid-template-columns: 1fr 340px; display: grid; }
    .timeline-column { border-right: 1px solid #e5e5e5; border-bottom: none; max-height: 320px; }
}
</style>
</head>
<body>

<%@ include file="../header.jsp" %>

<div class="container">

<%
String msg = request.getParameter("msg");
if("success".equals(msg)){
%>
<div class="alert success"><i class="fas fa-circle-check"></i> Follow-up submitted successfully.</div>
<%
}
if("error".equals(msg)){
%>
<div class="alert error"><i class="fas fa-circle-xmark"></i> Failed to submit follow-up.</div>
<%
}

ArrayList<HashMap<String,Object>> requestList = (ArrayList<HashMap<String,Object>>) request.getAttribute("requestList");

if(requestList != null && requestList.size() > 0){
    Set<String> uniqueOwners = new TreeSet<>();
    for(HashMap<String,Object> row : requestList) {
        String ownerName = (row.get("assigned_name") != null) ? String.valueOf(row.get("assigned_name")).trim() : "Unassigned";
        uniqueOwners.add(ownerName);
    }
%>

<div class="filter-toolbar">
    <div class="filter-group">
        <i class="fas fa-filter" style="color: #0176d3;"></i>
        <label class="filter-label" for="ownerFilter">Filter Owner:</label>
    </div>
    <select id="ownerFilter" class="filter-select" onchange="filterRequestsByOwner(this.value)">
        <option value="ALL">All Assigned Owners (Show All)</option>
        <% for(String owner : uniqueOwners) { %>
            <option value="<%= owner.toUpperCase() %>"><%= owner %></option>
        <% } %>
    </select>
</div>

<div id="requestsWrapper">
<%
    for(HashMap<String,Object> row : requestList){
        String status = String.valueOf(row.get("status"));
        String rawOwner = (row.get("assigned_name") != null) ? String.valueOf(row.get("assigned_name")) : "Unassigned";
        ArrayList<HashMap<String,Object>> followupList = (ArrayList<HashMap<String,Object>>) row.get("followupList");
        int logCount = (followupList != null) ? followupList.size() : 0;
%>

<div class="request-card" data-owner="<%= rawOwner.toUpperCase().trim() %>">
    <div class="top-row">
        <div class="header-meta-group">
            <div class="request-no"><i class="fas fa-hashtag"></i> <%= row.get("request_no") %></div>
            <div class="header-right-group">
                <div class="conversation-counter">
                    <i class="fas fa-comments"></i> <span><%= logCount %></span>
                </div>
                <div class="status-badge <%= status.toLowerCase().replace(" ","-") %>"><%= status %></div>
            </div>
        </div>

        <button type="button" class="toggle-details-btn" onclick="toggleWorkspaceGrid(this)">
            <i class="fas fa-chevron-down"></i>
            <span>Open Workspace</span>
        </button>
    </div>

    <div class="summary-section">
        <div class="info-box">
            <div class="label">Request Date</div>
            <div class="value"><%= row.get("request_date") %></div>
        </div>
        
        <div class="info-box">
            <div class="label">Request by</div>
            <div class="value" style="color: brown; font-weight: 600;"><%= row.get("requested_by") %></div>
        </div> 
      
        <div class="info-box">
            <div class="label">Priority</div>
            <div class="value"><%= row.get("priority") %></div>
        </div>
        <div class="info-box">
            <div class="label">Assigned To</div>
            <div class="value" style="color: #0176d3; font-weight: 600;"><%= rawOwner %></div>
        </div>
        <div class="info-box">
            <div class="label">Location</div>
            <div class="value"><%= row.get("location") %></div>
        </div>
        <div class="description-box">
            <div class="label">Description</div>
            <div class="description-text"><%= row.get("description") %></div>
        </div>
    </div>

    <div class="collapsible-workspace collapsed">
        <div class="card-split-workspace">
            
            <div class="timeline-column">
                <h3 class="timeline-title"><i class="fas fa-clock-rotate-left"></i> History Timeline</h3>
                <%
                if(logCount > 0){
                    for(HashMap<String,Object> f : followupList){
                        String updatedBy = String.valueOf(f.get("updated_by"));
                        String requestedByUser = String.valueOf(row.get("requested_by"));
                        boolean isRequesterUpdate = updatedBy.equalsIgnoreCase(requestedByUser);
                %>
                <div class="followup-box <%= isRequesterUpdate ? "followup-requester" : "followup-staff" %>">
                    <div class="followup-top">
                        <span class="followup-status"><%= f.get("status") %></span>
                        <span class="date">
                            <i class="fas fa-user"></i> <%= f.get("updated_by") %> &nbsp;|&nbsp; <i class="fas fa-clock"></i> <%= f.get("updated_on") %>
                        </span>
                    </div>
                    <div class="remark"><%= f.get("remarks") %></div>
                </div>
                <%
                    }
                } else {
                %>
                <div class="followup-box"><div class="remark" style="color:#747472;">No logs recorded yet.</div></div>
                <% } %>
            </div>

            <div class="form-column">
                <h3 class="form-title"><i class="fas fa-comment-dots"></i> Update Status</h3>
                <form action="<%=request.getContextPath()%>/TrackRequestServlet" method="post" class="form-vertical">
                    <input type="hidden" name="request_id" value="<%= row.get("id") %>">
                    
                    <select name="status" required>
                        <option value="">Select Status</option>
                        <option value="OPEN">OPEN</option>
                        <option value="IN PROGRESS">IN PROGRESS</option>
                       
                        <% 
                        String requestedBy = String.valueOf(row.get("requested_by"));
                        if (username.equalsIgnoreCase(requestedBy)) { 
                        %>
                        <option value="SATISFIED">SATISFIED</option>
                        <% 
                        } 
                        %>
                    </select>

                    <textarea name="remarks" placeholder="Provide operational remarks..." required></textarea>
                    <button type="submit" class="submit-btn"><i class="fas fa-paper-plane"></i> Update</button>
                </form>
            </div>

        </div>
    </div>
</div>

<%
    }
%>
</div>

<div class="empty" id="filterEmptyState" style="display: none;">
    <i class="fas fa-user-slash" style="font-size:36px; color:#cbd5e1;"></i>
    <h3>No Matching Results</h3>
    <p>There are currently no active workspace entries assigned to this manager.</p>
</div>

<%
} else {
%>
<div class="empty">
    <i class="fas fa-folder-open" style="font-size:36px; color:#cbd5e1;"></i>
    <h3>No Requests Found</h3>
    <p>You have not created any service requests yet.</p>
</div>
<%
}
%>

</div>

<script>
function toggleWorkspaceGrid(button) {
    const card = button.closest('.request-card');
    const workspace = card.querySelector('.collapsible-workspace');
    const btnText = button.querySelector('span');
    
    if (workspace.classList.contains('collapsed')) {
        workspace.classList.remove('collapsed');
        button.classList.add('active');
        btnText.textContent = "Hide Workspace";
    } else {
        workspace.classList.add('collapsed');
        button.classList.remove('active');
        btnText.textContent = "Open Workspace";
    }
}

function filterRequestsByOwner(selectedOwner) {
    const cards = document.querySelectorAll('#requestsWrapper .request-card');
    const emptyState = document.getElementById('filterEmptyState');
    let visibleCount = 0;
    
    cards.forEach(card => {
        const cardOwner = card.getAttribute('data-owner');
        if (selectedOwner === "ALL" || cardOwner === selectedOwner) {
            card.style.display = "block";
            visibleCount++;
        } else {
            card.style.display = "none";
        }
    });
    
    if (visibleCount === 0) {
        emptyState.style.display = "block";
    } else {
        emptyState.style.display = "none";
    }
}
</script>
</body>
</html>