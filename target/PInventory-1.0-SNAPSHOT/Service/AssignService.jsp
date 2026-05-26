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

String username =
((String)sess.getAttribute("username")).toUpperCase();
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Service Request Management</title>

<link rel="stylesheet"
href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

<style>

*{
    box-sizing:border-box;
}

body{
    margin:0;
    font-family:Segoe UI;
    background:#f3f3f3;
    color:#181818;
}

.container{
    max-width:1450px;
    margin:auto;
    padding:20px;
}

/* ALERT */

.alert{
    padding:12px 16px;
    border-radius:4px;
    margin-bottom:16px;
    font-size:13px;
    font-weight:600;
}

.alert-success{
    background:#ecfdf5;
    color:#065f46;
    border:1px solid #a7f3d0;
}

.alert-error{
    background:#fef2f2;
    color:#991b1b;
    border:1px solid #fecaca;
}

/* CARD */

.request-card{
    background:white;
    border:1px solid #d8dde6;
    border-radius:6px;
    margin-bottom:18px;
    overflow:hidden;
    box-shadow:0 2px 6px rgba(0,0,0,0.05);
}

.request-top{
    background:#f8fafc;
    border-bottom:1px solid #e2e8f0;
    padding:12px 16px;
    display:flex;
    justify-content:space-between;
    align-items:center;
}

.header-left-group{
    display:flex;
    align-items:center;
    gap:12px;
}

.request-no{
    font-size:15px;
    font-weight:700;
    color:#0176d3;
}

/* TOGGLE */

.toggle-details-btn{
    border:1px solid #0176d3;
    background:white;
    color:#0176d3;
    padding:6px 14px;
    border-radius:4px;
    cursor:pointer;
    font-size:12px;
    font-weight:600;
}

.toggle-details-btn:hover{
    background:#eef4ff;
}

/* STATUS */

.status-badge{
    padding:4px 12px;
    border-radius:20px;
    font-size:11px;
    font-weight:700;
    text-transform:uppercase;
}

.open{
    background:#fff1d6;
    color:#8a4b00;
}

.assigned{
    background:#dcfce7;
    color:#166534;
}

.in-progress{
    background:#dbeafe;
    color:#1d4ed8;
}

.pending{
    background:#fef3c7;
    color:#92400e;
}

.satisfied{
    background:#e0f2fe;
    color:#0369a1;
}

.closed{
    background:#e2e8f0;
    color:#334155;
}

/* SUMMARY */

.highlights-panel{
    padding:16px;
    display:flex;
    flex-wrap:wrap;
    gap:18px;
}

.info-box{
    flex:1;
    min-width:150px;
}

.description-box{
    flex:3;
    min-width:320px;
}

.label{
    font-size:11px;
    font-weight:700;
    color:#64748b;
    text-transform:uppercase;
    margin-bottom:5px;
}

.value{
    font-size:13px;
    font-weight:600;
}

.description-text{
    font-size:13px;
    line-height:1.5;
}

/* WORKSPACE */

.collapsible-workspace{
    display:none;
    border-top:1px solid #e2e8f0;
}

.workspace-grid{
    display:grid;
    grid-template-columns:360px 1fr;
}

/* LEFT PANEL */

.action-card-panel{
    background:#f8fafc;
    border-right:1px solid #e2e8f0;
    padding:16px;
}

.action-block{
    margin-bottom:20px;
}

.action-title{
    font-size:12px;
    font-weight:700;
    margin-bottom:10px;
    text-transform:uppercase;
}

.action-form{
    display:flex;
    flex-direction:column;
    gap:10px;
}

select,
textarea,
input[type=text]{

    width:100%;
    border:1px solid #cbd5e1;
    border-radius:4px;
    padding:10px;
    font-size:13px;
    outline:none;
}

textarea{
    resize:none;
    min-height:80px;
}

select:focus,
textarea:focus,
input[type=text]:focus{
    border-color:#0176d3;
}

/* BUTTONS */

.assign-btn,
.close-btn,
.followup-btn{

    border:none;
    border-radius:4px;
    padding:10px;
    font-size:13px;
    font-weight:700;
    cursor:pointer;
}

.assign-btn{
    background:#0176d3;
    color:white;
}

.close-btn{
    background:#2e7d32;
    color:white;
}

.followup-btn{
    background:#ea580c;
    color:white;
}

.assign-btn:hover{
    background:#015a9e;
}

.close-btn:hover{
    background:#1f6a24;
}

.followup-btn:hover{
    background:#c2410c;
}

/* TIMELINE */

.timeline-section{
    padding:16px;
}

.timeline-heading{
    font-size:12px;
    font-weight:700;
    margin-bottom:12px;
    text-transform:uppercase;
}

.followup-container{
    max-height:500px;
    overflow-y:auto;
}

.followup-box{
    background:white;
    border:1px solid #d8dde6;
    border-left:4px solid #0176d3;
    border-radius:4px;
    padding:10px 14px;
    margin-bottom:10px;
}

.followup-top{
    display:flex;
    justify-content:space-between;
    align-items:center;
    margin-bottom:6px;
}

.followup-status{
    background:#e0f2fe;
    color:#0369a1;
    font-size:10px;
    font-weight:700;
    padding:3px 7px;
    border-radius:3px;
}

.followup-date{
    font-size:11px;
    color:#64748b;
}

.followup-remark{
    font-size:13px;
    line-height:1.4;
}

/* LOCK */

.action-lock-notice{
    background:#f1f5f9;
    border:1px dashed #cbd5e1;
    border-radius:4px;
    padding:12px;
    font-size:12px;
    color:#64748b;
}

/* EMPTY */

.empty-state{
    background:white;
    border:1px solid #d8dde6;
    border-radius:6px;
    padding:60px 20px;
    text-align:center;
}

.empty-state i{
    font-size:44px;
    color:#cbd5e1;
}

@media(max-width:1000px){

    .workspace-grid{
        grid-template-columns:1fr;
    }

    .action-card-panel{
        border-right:none;
        border-bottom:1px solid #e2e8f0;
    }
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

<div class="alert alert-success">
    <i class="fas fa-circle-check"></i>
    Request processed successfully.
</div>

<%
}

if("error".equals(msg)){
%>

<div class="alert alert-error">
    <i class="fas fa-circle-xmark"></i>
    Something went wrong while processing request.
</div>

<%
}

ArrayList<HashMap<String,Object>> requestList =
(ArrayList<HashMap<String,Object>>) request.getAttribute("requestList");

if(requestList != null && requestList.size() > 0){

    for(HashMap<String,Object> row : requestList){

        String id =
        String.valueOf(row.get("id"));

        String status =
        String.valueOf(row.get("status"));

        String priority =
        String.valueOf(row.get("priority"));

        ArrayList<HashMap<String,Object>> inchargeList =
        (ArrayList<HashMap<String,Object>>) row.get("inchargeList");

        ArrayList<HashMap<String,Object>> followupList =
        (ArrayList<HashMap<String,Object>>) row.get("followupList");
%>

<div class="request-card">

    <div class="request-top">

        <div class="header-left-group">

            <button type="button"
            class="toggle-details-btn"
            onclick="toggleWorkspaceGrid(this)">
                <i class="fas fa-chevron-down"></i>
                Open Workspace
            </button>

            <div class="request-no">
                <i class="fas fa-ticket"></i>
                <%= row.get("request_no") %>
            </div>

        </div>

        <div class="status-badge <%= status.toLowerCase().replace(" ","-") %>">
            <%= status %>
        </div>

    </div>

    <!-- SUMMARY -->

    <div class="highlights-panel">

        <div class="info-box">
            <div class="label">Request Date</div>
            <div class="value"><%= row.get("request_date") %></div>
        </div>

        <div class="info-box">
            <div class="label">Requested By</div>
            <div class="value"><%= row.get("requested_by") %></div>
        </div>

        <div class="info-box">
            <div class="label">Priority</div>

            <div class="value">

                <% if("HIGH".equalsIgnoreCase(priority)){ %>

                    <span style="color:#ba0517;">HIGH</span>

                <% }else if("MEDIUM".equalsIgnoreCase(priority)){ %>

                    <span style="color:#b54708;">MEDIUM</span>

                <% }else{ %>

                    <span style="color:#027a48;">LOW</span>

                <% } %>

            </div>
        </div>

        <div class="info-box">
            <div class="label">Assigned Owner</div>
            <div class="value" style="color:#0176d3;">
                <%= row.get("assigned_name") != null ?
                row.get("assigned_name") : "Unassigned" %>
            </div>
        </div>

        <div class="info-box">
            <div class="label">Location</div>
            <div class="value"><%= row.get("location") %></div>
        </div>

        <div class="description-box">
            <div class="label">Description</div>
            <div class="description-text">
                <%= row.get("description") %>
            </div>
        </div>

    </div>

    <!-- WORKSPACE -->

    <div class="collapsible-workspace">

        <div class="workspace-grid">

            <!-- LEFT -->

            <div class="action-card-panel">

                <!-- ASSIGN -->

                <div class="action-block">

                    <div class="action-title">
                        <i class="fas fa-user-check"></i>
                        Assign Owner
                    </div>

                    <form action="<%=request.getContextPath()%>/Assign_ServiceRequestServlet"
                    method="post"
                    class="action-form">

                        <input type="hidden"
                        name="request_id"
                        value="<%= id %>">

                        <input type="hidden"
                        name="action_type"
                        value="ASSIGN">

                        <select name="assigned_to" required>

                            <option value="">
                                Select Incharge
                            </option>

                            <% for(HashMap<String,Object> inc : inchargeList){ %>

                            <option value="<%= inc.get("id") %>">
                                <%= inc.get("incharge_name") %>
                                -
                                <%= inc.get("designation") %>
                            </option>

                            <% } %>

                        </select>

                        <button type="submit" class="assign-btn">
                            <i class="fas fa-paper-plane"></i>
                            Assign Request
                        </button>

                    </form>

                </div>

                <hr>

                <!-- FOLLOWUP -->

                <div class="action-block">

                    <div class="action-title">
                        <i class="fas fa-comment-dots"></i>
                        Add Followup
                    </div>

                    <form action="<%=request.getContextPath()%>/Assign_ServiceRequestServlet"
                    method="post"
                    class="action-form">

                        <input type="hidden"
                        name="request_id"
                        value="<%= id %>">

                        <input type="hidden"
                        name="action_type"
                        value="FOLLOWUP">

                        <select name="status" required>

                            <option value="">Select Status</option>

                            <option value="OPEN">OPEN</option>

                            <option value="ASSIGNED">ASSIGNED</option>

                            <option value="IN PROGRESS">IN PROGRESS</option>

                            <option value="PENDING">PENDING</option>

                            <option value="SATISFIED">SATISFIED</option>

                        </select>

                        <textarea name="remarks"
                        placeholder="Enter followup remarks..."
                        required></textarea>

                        <button type="submit" class="followup-btn">
                            <i class="fas fa-notes-medical"></i>
                            Update Followup
                        </button>

                    </form>

                </div>

                <hr>

                <!-- CLOSE -->

                <div class="action-block">

                    <div class="action-title">
                        <i class="fas fa-circle-xmark"></i>
                        Close Request
                    </div>

                    <% if("SATISFIED".equalsIgnoreCase(status)){ %>

                    <form action="<%=request.getContextPath()%>/Assign_ServiceRequestServlet"
                    method="post"
                    class="action-form">

                        <input type="hidden"
                        name="request_id"
                        value="<%= id %>">

                        <input type="hidden"
                        name="action_type"
                        value="CLOSE">

                        <input type="text"
                        name="resolution"
                        placeholder="Resolution remarks"
                        required>

                        <button type="submit" class="close-btn">
                            <i class="fas fa-box-archive"></i>
                            Close Request
                        </button>

                    </form>

                    <% } else { %>

                    <div class="action-lock-notice">

                        <i class="fas fa-lock"></i>

                        Request can only be closed after
                        status becomes SATISFIED.

                    </div>

                    <% } %>

                </div>

            </div>

            <!-- RIGHT -->

            <div class="timeline-section">

                <div class="timeline-heading">
                    <i class="fas fa-clock-rotate-left"></i>
                    Activity Timeline
                </div>

                <div class="followup-container">

                    <%

                    if(followupList != null &&
                    followupList.size() > 0){

                        for(HashMap<String,Object> f : followupList){
                    %>

                    <div class="followup-box">

                        <div class="followup-top">

                            <span class="followup-status">
                                <%= f.get("status") %>
                            </span>

                            <span class="followup-date">

                                <i class="fas fa-user"></i>
                                <%= f.get("updated_by") %>

                                &nbsp; | &nbsp;

                                <i class="fas fa-clock"></i>
                                <%= f.get("updated_on") %>

                            </span>

                        </div>

                        <div class="followup-remark">
                            <%= f.get("remarks") %>
                        </div>

                    </div>

                    <%
                        }

                    } else {
                    %>

                    <div class="followup-box">

                        <div class="followup-remark"
                        style="color:#64748b;">

                            No followups available.

                        </div>

                    </div>

                    <% } %>

                </div>

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

    <p>
        No pending requests available right now.
    </p>

</div>

<%
}
%>

</div>

<script>

function toggleWorkspaceGrid(button){

    const card =
    button.closest('.request-card');

    const workspace =
    card.querySelector('.collapsible-workspace');

    if(workspace.style.display === "block"){

        workspace.style.display = "none";

        button.innerHTML =
        '<i class="fas fa-chevron-down"></i> Open Workspace';

    }else{

        workspace.style.display = "block";

        button.innerHTML =
        '<i class="fas fa-chevron-up"></i> Hide Workspace';
    }
}

</script>

</body>
</html>