<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>

<%
HttpSession sess = request.getSession(false);

if(sess == null || sess.getAttribute("username") == null){
    response.sendRedirect(request.getContextPath() + "/login.jsp");
    return;
}

String username = String.valueOf(sess.getAttribute("username")).trim().toUpperCase();
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<!-- CRITICAL FOR MOBILE: Prevents standard desktop zooming on mobile devices -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>My Service Requests</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

<style>
:root {
    --slds-brand: #1b5ebe;
    --slds-brand-hover: #0b4ca0;
    --bg-light: #f3f4f6;
    --border-color: #e5e7eb;
    --text-main: #1f2937;
    --text-muted: #4b5563;
}

*{
    box-sizing: border-box;
    -webkit-tap-highlight-color: transparent; /* Removes blue tap overlay on iOS/Android */
}

body{
    margin: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background: var(--bg-light);
    color: var(--text-main);
}

.container{
    max-width: 600px; /* Constraints card width for clean single-hand mobile usage */
    margin: auto;
    padding: 12px;
    padding-bottom: 60px; /* Gives room so elements aren't cut off by mobile browser bars */
}

/* APP HEADER BANNER */
.mobile-app-bar {
    background: #ffffff;
    border-bottom: 1px solid var(--border-color);
    padding: 14px 16px;
    display: flex;
    align-items: center;
    gap: 12px;
    position: sticky;
    top: 0;
    z-index: 100;
}

.mobile-app-bar h1 {
    margin: 0;
    font-size: 16px;
    font-weight: 700;
    color: var(--text-main);
}

/* SALESFORCE MOBILE STYLE ALERTS */
.alert{
    padding: 12px 14px;
    border-radius: 8px;
    margin-bottom: 12px;
    font-size: 13px;
    font-weight: 600;
    display: flex;
    align-items: center;
    gap: 10px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.success{ background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; }
.error{ background: #fef2f2; color: #991b1b; border: 1px solid #fca5a5; }

/* MOBILE STICKY TOOLBAR */
.filter-toolbar{
    background: #ffffff;
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 10px 12px;
    margin-bottom: 14px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.filter-group{
    display: flex;
    align-items: center;
    gap: 10px;
    width: 100%;
}

.filter-select{
    flex: 1;
    height: 42px; /* Large mobile tap targets (Minimum 40px rule) */
    font-size: 14px;
    border: 1px solid #cbd5e1;
    border-radius: 6px;
    padding: 0 12px;
    background: #ffffff;
    color: var(--text-main);
}

/* MOBILE-OPTIMIZED COMPACT CARD */
.request-card{
    background: white;
    border-radius: 12px;
    border: 1px solid var(--border-color);
    margin-bottom: 14px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.04);
    overflow: hidden;
}

.top-row{
    padding: 14px 14px 10px 14px;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.request-no{
    font-size: 15px;
    font-weight: 700;
    color: var(--slds-brand);
}

/* HIGH VISIBILITY METRIC BADGES */
.status-badge{
    padding: 4px 10px;
    border-radius: 6px;
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.open{ background: #fef3c7; color: #92400e; }
.assigned{ background: #e0f2fe; color: #0369a1; }
.in-progress{ background: #dbeafe; color: #1d4ed8; }
.pending{ background: #ffedd5; color: #c2410c; }
.completed{ background: #f3e8ff; color: #6b21a8; }
.satisfied{ background: #d1fae5; color: #065f46; }
.closed{ background: #e2e8f0; color: #334155; }

/* COMPACT SUMMARY DATA GRID */
.summary-section{
    padding: 0 14px 14px 14px;
}

.info-grid-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
    padding-bottom: 10px;
    border-bottom: 1px dashed var(--border-color);
    margin-bottom: 10px;
}

.label{
    font-size: 10px;
    color: var(--text-muted);
    font-weight: 700;
    text-transform: uppercase;
    margin-bottom: 2px;
}

.value{
    font-size: 13px;
    color: var(--text-main);
    font-weight: 600;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.description-box{
    background: #f9fafb;
    border-radius: 8px;
    padding: 10px 12px;
    margin-top: 8px;
    border: 1px solid var(--border-color);
}

.description-text{
    font-size: 13px;
    line-height: 1.5;
    color: #374151;
}

/* BOTTOM WORKSPACE BUTTON */
.card-actions-strip {
    display: flex;
    border-top: 1px solid var(--border-color);
    background: #fafafa;
}

.toggle-details-btn{
    flex: 1;
    background: transparent;
    border: none;
    color: var(--slds-brand);
    padding: 14px;
    font-size: 13px;
    font-weight: 700;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
}

.toggle-details-btn.active {
    background: #f0f7ff;
    color: var(--slds-brand-hover);
}

/* ONE-HAND WORKSPACE INTERFACE */
.collapsible-workspace{
    max-height: 3000px;
    overflow: hidden;
    transition: max-height 0.3s cubic-bezier(0, 1, 0, 1); /* Pure smooth mobile toggle acceleration */
    background: #ffffff;
    border-top: 1px solid var(--border-color);
}

.collapsible-workspace.collapsed{
    max-height: 0;
    border-top: none;
}

.workspace-block {
    padding: 14px;
}

/* MOBILE TIMELINE SEGMENT */
.timeline-title, .form-title{
    font-size: 12px;
    font-weight: 700;
    color: var(--text-muted);
    margin: 0 0 10px 0;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    display: flex;
    align-items: center;
    gap: 6px;
}

.mobile-timeline {
    max-height: 240px;
    overflow-y: auto;
    padding-right: 4px;
    margin-bottom: 16px;
    border-bottom: 2px solid var(--border-color);
    padding-bottom: 12px;
}

.followup-box{
    border-radius: 8px;
    padding: 10px 12px;
    margin-bottom: 8px;
    border: 1px solid var(--border-color);
    font-size: 12px;
}

.followup-requester{ background: #f0fdf4; border-left: 4px solid #10b981; }
.followup-staff{ background: #eff6ff; border-left: 4px solid #3b82f6; }

.followup-top{
    display: flex;
    justify-content: space-between;
    margin-bottom: 4px;
    font-size: 11px;
    color: var(--text-muted);
}

.user-tag {
    font-weight: 700;
    color: var(--text-main);
}

.remark{
    font-size: 13px;
    line-height: 1.4;
    color: #374151;
    word-break: break-word;
}

/* SMART ONE-HAND ACTION FORMS */
.form-vertical{
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.input-label {
    font-size: 11px;
    font-weight: 700;
    color: var(--text-muted);
    margin-bottom: -6px;
}

select.mobile-input, textarea.mobile-input{
    width: 100%;
    border: 1px solid #cbd5e1;
    border-radius: 8px;
    padding: 12px; /* Thick layout target padding */
    font-size: 14px; /* Essential 16px rule for iOS to prevent viewport layout shift */
    background: #ffffff;
    color: var(--text-main);
    font-family: inherit;
}

select.mobile-input:focus, textarea.mobile-input:focus{
    outline: none;
    border-color: var(--slds-brand);
    box-shadow: 0 0 0 3px rgba(27, 94, 190, 0.15);
}

textarea.mobile-input{
    min-height: 80px;
}

.submit-btn{
    background: var(--slds-brand);
    color: white;
    border: none;
    border-radius: 8px;
    padding: 14px;
    font-size: 14px;
    font-weight: 700;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    box-shadow: 0 2px 4px rgba(27, 94, 190, 0.2);
}

.submit-btn:active{
    background: var(--slds-brand-hover);
    transform: scale(0.98);
}

/* MOBILE EMPTY STATES */
.empty{
    background: white;
    border: 1px solid var(--border-color);
    border-radius: 12px;
    padding: 40px 20px;
    text-align: center;
    box-shadow: 0 2px 4px rgba(0,0,0,0.02);
}
.empty h3 { margin: 12px 0 6px 0; font-size: 16px; }
.empty p { margin: 0; font-size: 13px; color: var(--text-muted); }

</style>
</head>
<body>
<%@ include file="../header.jsp" %>
<div class="mobile-app-bar">
    <i class="fas fa-screwdriver-wrench" style="color: var(--slds-brand); font-size: 18px;"></i>
    <h1>Field Operations Workspace</h1>
</div>

<div class="container">

<%
String msg = request.getParameter("msg");
if("success".equals(msg)){
%>
<div class="alert success">
    <i class="fas fa-circle-check"></i> Status Updated Successfully
</div>
<%
}
if("error".equals(msg)){
%>
<div class="alert error">
    <i class="fas fa-circle-xmark"></i> Update failed. Try again.
</div>
<%
}

List<Map<String, Object>> requestList = (List<Map<String, Object>>) request.getAttribute("requestList");

if(requestList != null && !requestList.isEmpty()){
    Set<String> uniqueOwners = new TreeSet<String>();
    for(Map<String, Object> row : requestList){
        String ownerName = (row.get("assigned_name") != null) 
            ? String.valueOf(row.get("assigned_name")).trim() 
            : "Unassigned";
        uniqueOwners.add(ownerName);
    }
%>

<!-- FILTER MECHANISM -->
<div class="filter-toolbar">
    <div class="filter-group">
        <select id="ownerFilter" class="filter-select" onchange="filterRequestsByOwner(this.value)">
            <option value="ALL">🔍 All Assigned Incharges</option>
            <% for(String owner : uniqueOwners){ %>
            <option value="<%= owner.toUpperCase() %>"><%= owner %></option>
            <% } %>
        </select>
    </div>
</div>

<div id="requestsWrapper">

<%
for(Map<String, Object> row : requestList){
    String status = row.get("status") != null ? String.valueOf(row.get("status")) : "OPEN";
    String badgeClass = status.toLowerCase().replace(" ","-");
    String rawOwner = row.get("assigned_name") != null ? String.valueOf(row.get("assigned_name")) : "Unassigned";

    List<Map<String, Object>> followupList = (List<Map<String, Object>>) row.get("followupList");
    int logCount = (followupList != null) ? followupList.size() : 0;
%>

<!-- REQUEST CARD CONTAINER -->
<div class="request-card" data-owner="<%= rawOwner.toUpperCase().trim() %>">

    <div class="top-row">
        <span class="request-no">#<%= row.get("request_no") %></span>
        <span class="status-badge <%= badgeClass %>"><%= status %></span>
    </div>

    <div class="summary-section">
        <div class="info-grid-row">
            <div>
                <div class="label">Date</div>
                <div class="value"><%= row.get("request_date") %></div>
            </div>
            <div>
                <div class="label">Location</div>
                <div class="value" style="color: #ef4444;"><i class="fas fa-location-dot"></i> <%= row.get("location") %></div>
            </div>
        </div>
        
        <div class="info-grid-row" style="border:none; margin:0; padding:0;">
            <div>
                <div class="label">Raised By</div>
                <div class="value"><%= row.get("requested_by") %></div>
            </div>
            <div>
                <div class="label">Priority</div>
                <div class="value"><%= row.get("priority") %></div>
            </div>
        </div>

        <div class="description-box">
            <div class="label">Operational Description</div>
            <div class="description-text"><%= row.get("description") %></div>
        </div>
    </div>

    <!-- STICKY ACTION TRIGGER FOOTER -->
    <div class="card-actions-strip">
        <button type="button" class="toggle-details-btn" onclick="toggleWorkspace(this)">
            <i class="fas fa-expand-arrows-alt"></i>
            <span>Action Workspace (<%= logCount %>)</span>
        </button>
    </div>

    <!-- EXPANDABLE ACTION PANEL -->
    <div class="collapsible-workspace collapsed">
        <div class="workspace-block">
            
            <!-- TIMELINE LIST -->
            <h3 class="timeline-title"><i class="fas fa-history"></i> Updates History</h3>
            <div class="mobile-timeline">
                <%
                if(logCount > 0){
                    for(Map<String, Object> f : followupList){
                        String updatedBy = String.valueOf(f.get("updated_by"));
                        String requestedByUser = String.valueOf(row.get("requested_by"));
                        boolean isRequesterUpdate = updatedBy.equalsIgnoreCase(requestedByUser);
                %>
                <div class="followup-box <%= isRequesterUpdate ? "followup-requester" : "followup-staff" %>">
                    <div class="followup-top">
                        <span class="user-tag"><%= f.get("updated_by") %></span>
                        <span><%= f.get("updated_on") %></span>
                    </div>
                    <div class="remark"><%= f.get("remarks") %></div>
                </div>
                <%
                    }
                }else{
                %>
                <div class="followup-box" style="text-align:center; border-style:dashed;">
                    <div class="remark" style="color:var(--text-muted);">No history updates logged yet.</div>
                </div>
                <% } %>
            </div>

            <!-- MOBILITY CONVENIENT FORM -->
            <h3 class="form-title"><i class="fas fa-pen-to-square"></i> Push Quick Update</h3>
            <form action="<%=request.getContextPath()%>/Incharge" method="post" class="form-vertical">
                <input type="hidden" name="request_id" value="<%= row.get("id") %>">
                
                <span class="input-label">Select Action Status</span>
                <select name="status" class="mobile-input" required>
                    <option value="">-- Choose --</option>
                    <option value="OPEN">OPEN</option>
                    <option value="IN PROGRESS">IN PROGRESS</option>
                    <%
                    String requestedBy = String.valueOf(row.get("requested_by"));
                    if(username.equalsIgnoreCase(requestedBy)){
                    %>
                    <option value="SATISFIED">SATISFIED</option>
                    <% } %>
                </select>

                <span class="input-label">Operational Field Remarks</span>
                <textarea name="remarks" class="mobile-input" placeholder="Type what actions you performed on ground..." required></textarea>

                <button type="submit" class="submit-btn">
                    <i class="fas fa-cloud-arrow-up"></i> Submit Field Update
                </button>
            </form>

        </div>
    </div>

</div>
<%
}
%>
</div>

<div class="empty" id="filterEmptyState" style="display:none;">
    <i class="fas fa-user-slash" style="font-size:36px; color:#cbd5e1;"></i>
    <h3>No Matches</h3>
    <p>No requests found for this Incharge.</p>
</div>

<%
}else{
%>
<div class="empty">
    <i class="fas fa-folder-open" style="font-size:36px; color:#cbd5e1;"></i>
    <h3>All Clean!</h3>
    <p>You have no active or assigned service requests right now.</p>
</div>
<%
}
%>

</div>

<script>
function toggleWorkspace(button){
    const card = button.closest('.request-card');
    const workspace = card.querySelector('.collapsible-workspace');
    const btnText = button.querySelector('span');
    const btnIcon = button.querySelector('i');

    if(workspace.classList.contains('collapsed')){
        workspace.classList.remove('collapsed');
        button.classList.add('active');
        btnText.textContent = "Close Workspace";
        btnIcon.className = "fas fa-compress-arrows-alt";
        
        // Mobile UX touch: Smoothly centers the expanded card on the viewport automatically
        setTimeout(() => {
            card.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }, 180);
    }else{
        workspace.classList.add('collapsed');
        button.classList.remove('active');
        btnText.textContent = "Action Workspace";
        btnIcon.className = "fas fa-expand-arrows-alt";
    }
}

function filterRequestsByOwner(selectedOwner){
    const cards = document.querySelectorAll('#requestsWrapper .request-card');
    const emptyState = document.getElementById('filterEmptyState');
    let visibleCount = 0;

    cards.forEach(card => {
        const cardOwner = card.getAttribute('data-owner');
        if(selectedOwner === "ALL" || cardOwner === selectedOwner){
            card.style.display = "block";
            visibleCount++;
        }else{
            card.style.display = "none";
        }
    });

    emptyState.style.display = (visibleCount === 0) ? "block" : "none";
}
</script>
</body>
</html>