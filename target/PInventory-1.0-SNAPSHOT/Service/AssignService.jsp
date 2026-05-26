<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%
HttpSession sess = request.getSession(false);
if(sess == null || sess.getAttribute("username") == null){
    response.sendRedirect(request.getContextPath()+"/login.jsp");
    return;
}

String role = (String)sess.getAttribute("role");
String dept = (String)sess.getAttribute("department");
if((!"Global".equalsIgnoreCase(role)) 
	    && (!"Finance".equalsIgnoreCase(dept))
	    && (!"Admin".equalsIgnoreCase(role))){
    out.println("<h3 style='text-align:center;color:red;'>Access Denied</h3>");
    return;
}

String username = ((String)sess.getAttribute("username")).toUpperCase();
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Service Request Management</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<style>
*{ box-sizing:border-box; }
body{
    margin:0;
    font-family:-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background:#eaeaea; 
    color:#161616;
}

/* HEADER (Salesforce Console Style) */
.page-header{
    background:#ffffff;
    padding:14px 24px;
    border-bottom:2px solid #d8dde6;
    display:flex;
    justify-content:space-between;
    align-items:center;
}
.page-title{ display:flex; align-items:center; gap:14px; }
.icon-box{
    width:42px;
    height:42px;
    border-radius:4px;
    background:#0176d3;
    display:flex;
    align-items:center;
    justify-content:center;
    color:white;
    font-size:20px;
}
.title-text h2{ margin:0; font-size:20px; color:#0176d3; font-weight:700; }
.title-text p{ margin:3px 0 0; font-size:13px; color:#444444; }
.user-chip{
    background:#ffffff;
    color:#161616;
    padding:8px 14px;
    border-radius:4px;
    font-size:13px;
    font-weight:600;
    border:1px solid #b0adab;
}

/* CONTAINER */
.container{ padding:16px; max-width:1440px; margin:auto; }

/* ALERTS */
.alert{ padding:12px 16px; border-radius:4px; margin-bottom:16px; font-size:14px; font-weight:600; display:flex; align-items:center; gap:8px;}
.alert-success{ background:#e1f5fe; color:#005fb2; border:1px solid #b8e3fa; }
.alert-error{ background:#fededb; color:#c23934; border:1px solid #faaaa3; }

/* DENSE CARD MATRIX */
.request-card{
    background:#ffffff;
    border-radius:4px;
    border:1px solid #b0adab;
    margin-bottom:20px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.06);
}

/* CARD BAR HEADER */
.request-top{
    padding:10px 16px;
    background:#f3f3f3;
    border-bottom:1px solid #c9c9c9;
    display:flex;
    justify-content:space-between;
    align-items:center;
}
.request-no{ font-size:15px; font-weight:700; color:#0176d3; }

/* STATUS BADGE */
.status-badge{ padding:4px 12px; border-radius:4px; font-size:11px; font-weight:700; text-transform:uppercase; border: 1px solid transparent;}
.open{ background:#fff1d6; color:#8a4b00; border-color:#fcc06f;}
.assigned{ background:#dcfce7; color:#166534; border-color:#86efac;}
.pending{ background:#fef3c7; color:#92400e; border-color:#fcd34d;}
.satisfied{ background:#e0f2fe; color:#0369a1; border-color:#7dd3fc;}
.completed{ background:#f3e8ff; color:#7e22ce; border-color:#d8b4fe;}
.closed{ background:#e2e8f0; color:#334155; border-color:#cbd5e1;}

/* HIGHLIGHTS PANEL */
.highlights-panel{
    display:flex;
    flex-wrap:wrap;
    padding:14px 16px;
    background:#ffffff;
    border-bottom:1px solid #c9c9c9;
    gap:20px;
}
.info-box{ flex:1; min-width:140px; }
.description-box{ flex:3; min-width:320px; border-left:1px solid #d8dde6; padding-left:16px; }
.label{ font-size:11px; color:#444444; font-weight:700; margin-bottom:4px; letter-spacing:0.5px; text-transform:uppercase;}
.value{ font-size:14px; color:#161616; font-weight:600; line-height:1.3; }

.priority-high{ color:#c23934; font-weight:700; }
.priority-medium{ color:#b54708; font-weight:700; }
.priority-low{ color:#027a48; font-weight:700; }
.description-text{ font-size:14px; color:#161616; line-height:1.45; margin-top:4px; font-weight:500; }

/* REBALANCED CORE TWO-COLUMN WORKSPACE GRID */
.workspace-grid{
    display:grid;
    grid-template-columns: 320px 1fr;
    background:#ffffff;
    border-top:1px solid #e5e5e5;
}

/* UNIFIED ACTION CARD PANEL */
.action-card-panel{
    padding:16px;
    border-right:1px solid #d8dde6;
    background:#f9f9fa;
    display:flex;
    flex-direction:column;
    gap:20px;
}
.action-block{
    display:flex;
    flex-direction:column;
    gap:8px;
}
.action-title{ 
    font-size:12px; 
    font-weight:700; 
    color:#161616; 
    margin:0 0 2px 0; 
    text-transform:uppercase; 
    letter-spacing:0.5px;
    display:flex;
    align-items:center;
    gap:6px;
}
.action-title.assign-color{ color: #0176d3; }
.action-title.close-color{ color: #2e7d32; }

.action-form{ display:flex; flex-direction:column; gap:8px; }

select, input[type="text"]{
    width:100%;
    border:1px solid #a09e9c;
    border-radius:4px;
    padding:8px 12px;
    font-size:13px;
    background:#ffffff;
    color:#161616;
    outline:none;
    height:38px;
}
select:focus, input[type="text"]:focus{ border-color:#0176d3; box-shadow:0 0 0 2px rgba(1,118,211,0.2); }

.assign-btn{
    background:#0176d3;
    color:#ffffff;
    border:none;
    border-radius:4px;
    padding:10px 16px;
    font-size:13px;
    font-weight:700;
    cursor:pointer;
    text-align:center;
    height:38px;
    transition: background 0.1s ease;
}
.assign-btn:hover{ background:#015a9e; }

.close-btn{
    background:#2e7d32;
    color:#ffffff;
    border:none;
    border-radius:4px;
    padding:10px 16px;
    font-size:13px;
    font-weight:700;
    cursor:pointer;
    text-align:center;
    height:38px;
    transition: background 0.1s ease;
}
.close-btn:hover{ background:#1b5e20; }

/* LOCKED ACCORDION COMPONENT FOR PRE-SATISFIED CONDITIONS */
.action-lock-notice{
    background:#f1f5f9;
    border:1px dashed #cbd5e1;
    border-radius:4px;
    padding:12px;
    font-size:12px;
    color:#64748b;
    line-height:1.4;
    font-weight:500;
}
.action-lock-notice i { color:#94a3b8; margin-right:4px; }

/* MAXIMIZED TIMELINE STREAM VIEWPORT */
.timeline-section{ 
    padding:16px; 
    background:#ffffff;
    width: 100%;
    display:flex;
    flex-direction:column;
}
.timeline-heading{
    font-size:12px; 
    font-weight:700; 
    color:#161616; 
    margin:0 0 10px 0; 
    text-transform:uppercase; 
    letter-spacing:0.5px;
}

.followup-container{
    display:block;
    height:210px; 
    overflow-y:auto;
    border:1px solid #c9c9c9;
    border-radius:4px;
    padding:12px;
    background:#f9f9fa;
}

.followup-container::-webkit-scrollbar { width: 8px; }
.followup-container::-webkit-scrollbar-track { background: #f1f1f1; }
.followup-container::-webkit-scrollbar-thumb { background: #adadad; border-radius: 4px; }
.followup-container::-webkit-scrollbar-thumb:hover { background: #888888; }

.followup-box{
    background:#ffffff;
    border:1px solid #c9c9c9;
    border-left:4px solid #0176d3;
    border-radius:3px;
    padding:10px 14px;
    margin-bottom:8px;
}
.followup-box:last-child{ margin-bottom:0; }
.followup-top{ display:flex; justify-content:space-between; align-items:center; margin-bottom:6px; }
.followup-status{ font-size:10px; font-weight:700; background:#e0edff; color:#0176d3; padding:2px 6px; border-radius:2px; }
.followup-date{ font-size:12px; color:#514f4d; font-weight:500; }
.followup-remark{ font-size:13px; color:#161616; line-height:1.4; font-weight:500; word-break: break-word; }

/* EMPTY STATE */
.empty-state{ background:#ffffff; border:1px solid #b0adab; border-radius:4px; padding:60px 20px; text-align:center; }
.empty-state i{ font-size:40px; color:#cbd5e1; margin-bottom:12px; }
.empty-state h3{ margin:0; font-size:16px; color:#161616; }
.empty-state p{ color:#444444; margin-top:4px; font-size:14px; }

/* RESPONSIVE LAYOUT MATRIX */
@media(max-width:1150px){
    .workspace-grid { grid-template-columns: 1fr; }
    .action-card-panel { border-right:none; border-bottom:1px solid #d8dde6; }
    .description-box{ border-left:none; padding-left:0; margin-top:10px;}
    .highlights-panel{ flex-direction:column; gap:12px; }
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
<div class="alert alert-success"><i class="fas fa-circle-check"></i> Request processed successfully.</div>
<%
}
if("error".equals(msg)){
%>
<div class="alert alert-error"><i class="fas fa-circle-xmark"></i> Operational processing error encountered.</div>
<%
}

ArrayList<HashMap<String,Object>> requestList = (ArrayList<HashMap<String,Object>>) request.getAttribute("requestList");
if(requestList != null && requestList.size() > 0){
    for(HashMap<String,Object> row : requestList){
        String id = String.valueOf(row.get("id"));
        String status = String.valueOf(row.get("status"));
        String priority = String.valueOf(row.get("priority"));
        ArrayList<HashMap<String,Object>> inchargeList = (ArrayList<HashMap<String,Object>>) row.get("inchargeList");
        ArrayList<HashMap<String,Object>> followupList = (ArrayList<HashMap<String,Object>>) row.get("followupList");
%>

<div class="request-card">
    <div class="request-top">
        <div class="request-no"><i class="fas fa-hashtag"></i> <%= row.get("request_no") %></div>
        <div class="status-badge <%= status.toLowerCase().replace(" ","-") %>"><%= status %></div>
    </div>

    <div class="highlights-panel">
        <div class="info-box">
            <div class="label">Date / Creator</div>
            <div class="value"><%= row.get("request_date") %></div>
            <div class="value" style="font-size:12px; color:#444444; font-weight:500; margin-top:2px;"><%= row.get("requested_by") %></div>
        </div>
        <div class="info-box">
            <div class="label">Priority</div>
            <div class="value">
                <% if("HIGH".equalsIgnoreCase(priority)){ %>
                    <span class="priority-high">HIGH</span>
                <% }else if("MEDIUM".equalsIgnoreCase(priority)){ %>
                    <span class="priority-medium">MEDIUM</span>
                <% }else{ %>
                    <span class="priority-low">LOW</span>
                <% } %>
            </div>
        </div>
        <div class="info-box">
            <div class="label">Location</div>
            <div class="value"><%= row.get("location") %></div>
        </div>
        <div class="info-box">
            <div class="label">Assigned Owner</div>
            <div class="value" style="color:#0176d3;"><%= row.get("assigned_name") != null ? row.get("assigned_name") : "Unassigned" %></div>
        </div>
        <div class="description-box">
            <div class="label">Description Summary</div>
            <div class="description-text"><%= row.get("description") %></div>
        </div>
    </div>

    <div class="workspace-grid">
        
        <div class="action-card-panel">
            
            <div class="action-block">
                <h3 class="action-title assign-color"><i class="fas fa-user-check"></i> Assign Owner</h3>
                <form action="<%=request.getContextPath()%>/Assign_ServiceRequestServlet" method="post" class="action-form">
                    <input type="hidden" name="request_id" value="<%= id %>">
                    <input type="hidden" name="action_type" value="ASSIGN">
                    
                    <select name="assigned_to" required>
                        <option value="">Select Incharge Member</option>
                        <% for(HashMap<String,Object> inc : inchargeList){ %>
                            <option value="<%= inc.get("id") %>">
                                <%= inc.get("incharge_name") %> — <%= inc.get("designation") %>
                            </option>
                        <% } %>
                    </select>
                    <button type="submit" class="assign-btn"><i class="fas fa-paper-plane"></i> Update Owner</button>
                </form>
            </div>
            
            <hr style="border: 0; border-top: 1px solid #d8dde6; margin: 4px 0;">

            <div class="action-block">
                <h3 class="action-title close-color"><i class="fas fa-circle-xmark"></i> Resolve &amp; Close Ticket</h3>
                <% if("SATISFIED".equalsIgnoreCase(status)){ %>
                    <form action="<%=request.getContextPath()%>/Assign_ServiceRequestServlet" method="post" class="action-form">
                        <input type="hidden" name="request_id" value="<%= id %>">
                        <input type="hidden" name="action_type" value="CLOSE">
                        
                        <input type="text" name="resolution" placeholder="Enter resolution remarks here..." required autocomplete="off">
                        <button type="submit" class="close-btn"><i class="fas fa-box-archive"></i> Close Request</button>
                    </form>
                <% } else { %>
                    <div class="action-lock-notice">
                        <i class="fas fa-lock"></i> This action is locked. Tickets can only be closed once their status has changed to <strong>SATISFIED</strong>.
                    </div>
                <% } %>
            </div>
            
        </div>

        <div class="timeline-section">
            <h3 class="timeline-heading"><i class="fas fa-clock-rotate-left"></i> Activity Logs</h3>

            <div class="followup-container" id="followup_<%= id %>">
                <%
                if(followupList != null && followupList.size() > 0){
                    for(HashMap<String,Object> f : followupList){
                %>
                <div class="followup-box">
                    <div class="followup-top">
                        <span class="followup-status"><%= f.get("status") %></span>
                        <span class="followup-date">
                            <i class="fas fa-user"></i> <%= f.get("updated_by") %> &nbsp;|&nbsp; <i class="fas fa-clock"></i> <%= f.get("updated_on") %>
                        </span>
                    </div>
                    <div class="followup-remark"><%= f.get("remarks") %></div>
                </div>
                <%
                    }
                } else {
                %>
                <div class="followup-box"><div class="followup-remark" style="color:#444444;">No updates logged yet.</div></div>
                <% } %>
            </div>
        </div>

    </div>
</div>

<%
    }
} else {
%>
<div class="empty-state">
    <i class="fas fa-inbox"></i>
    <h3>No Service Requests Found</h3>
    <p>All clean! There are currently no pending entries available inside your workspace.</p>
</div>
<%
}
%>

</div>
</body>
</html>