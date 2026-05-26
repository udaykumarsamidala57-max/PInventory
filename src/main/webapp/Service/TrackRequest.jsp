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
<title>My Service Requests</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<style>
*{ box-sizing:border-box; }
body{
    margin:0;
    font-family:-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background:#f3f3f3;
    color:#181818;
}

/* HEADER (Salesforce Style) */
.page-header{
    background:#ffffff;
    padding:12px 24px;
    border-bottom:1px solid #c9c9c9;
    display:flex;
    justify-content:space-between;
    align-items:center;
    position:sticky;
    top:0;
    z-index:99;
}
.header-left{ display:flex; align-items:center; gap:12px; }
.icon-box{
    width:40px;
    height:40px;
    border-radius:4px;
    background:#0176d3;
    display:flex;
    align-items:center;
    justify-content:center;
    color:white;
    font-size:18px;
}
.title h2{ margin:0; font-size:18px; color:#0176d3; font-weight:700; }
.title p{ margin:2px 0 0; font-size:12px; color:#514f4d; }
.user-chip{
    background:#f3f3f3;
    color:#181818;
    padding:6px 12px;
    border-radius:4px;
    font-size:12px;
    font-weight:600;
    border:1px solid #c9c9c9;
}

/* CONTAINER */
.container{ max-width:1440px; margin:auto; padding:16px; }

/* ALERTS */
.alert{ padding:10px 16px; border-radius:4px; margin-bottom:16px; font-size:13px; font-weight:600; display:flex; align-items:center; gap:8px;}
.success{ background:#e1f5fe; color:#005fb2; border:1px solid #b8e3fa; }
.error{ background:#fededb; color:#c23934; border:1px solid #faaaa3; }

/* COMPACT COMPONENT CARD */
.request-card{
    background:white;
    border-radius:4px;
    border:1px solid #c9c9c9;
    margin-bottom:16px;
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
}

/* CARD TOP BAR */
.top-row{
    padding:12px 16px;
    border-bottom:1px solid #c9c9c9;
    background:#f3f3f3;
    display:flex;
    justify-content:space-between;
    align-items:center;
}
.request-no{ font-size:15px; font-weight:700; color:#0176d3; }

/* STATUS BADGES */
.status-badge{ padding:3px 12px; border-radius:12px; font-size:11px; font-weight:700; text-transform:uppercase; border: 1px solid transparent;}
.open{ background:#fff1d6; color:#8a4b00; border-color:#fcc06f;}
.assigned{ background:#dcfce7; color:#166534; border-color:#86efac;}
.in-progress{ background:#e0edff; color:#1d4ed8; border-color:#93c5fd;}
.pending{ background:#fef3c7; color:#92400e; border-color:#fcd34d;}
.completed{ background:#f3e8ff; color:#7e22ce; border-color:#d8b4fe;}
.satisfied{ background:#d1fae5; color:#065f46; border-color:#6ee7b7;}
.closed{ background:#e2e8f0; color:#334155; border-color:#cbd5e1;}

/* COMPACT SUMMARY DATA GRID */
.summary-section{
    display:flex;
    flex-wrap:wrap;
    padding:12px 16px;
    background:#fafaf9;
    border-bottom:1px solid #e5e5e5;
    gap:16px;
}
.info-box{ flex: 1; min-width: 160px; }
.description-box { flex: 2.5; min-width: 280px; border-left: 1px solid #e5e5e5; padding-left: 16px; }
.label{ font-size:11px; color:#514f4d; font-weight:700; margin-bottom:2px; letter-spacing:0.5px; text-transform:uppercase;}
.value{ font-size:13px; color:#181818; font-weight:500; }
.description-text{ font-size:13px; color:#181818; line-height:1.4; margin-top:2px; }

/* TWO-COLUMN SPLIT WORKSPACE */
.card-split-workspace{
    display: grid;
    grid-template-columns: 1fr 340px;
    background: #fff;
}

/* LEFT COLUMN: TIMELINE */
.timeline-column{
    padding:16px;
    border-right: 1px solid #e5e5e5;
    max-height: 280px;
    overflow-y: auto;
}
.timeline-title, .form-title{ font-size:13px; font-weight:700; color:#181818; margin:0 0 12px 0; text-transform: uppercase; letter-spacing: 0.5px;}

.followup-box{
    position:relative;
    background:#fafaf9;
    border:1px solid #e5e5e5;
    border-left:3px solid #0176d3;
    border-radius:3px;
    padding:10px 12px;
    margin-bottom:8px;
}
.followup-top{ display:flex; justify-content:between; align-items:center; gap:8px; margin-bottom:4px; }
.followup-status{ font-size:10px; font-weight:700; background:#e0edff; color:#0176d3; padding:1px 6px; border-radius:2px; }
.date{ font-size:11px; color:#747472; margin-left: auto; }
.remark{ font-size:12px; color:#181818; line-height:1.4; }

/* RIGHT COLUMN: ACTION FORM */
.form-column{ padding:16px; background:#fafaf9; }
.form-vertical{ display:flex; flex-direction:column; gap:10px; }
select, textarea{
    width:100%;
    border:1px solid #c9c9c9;
    border-radius:4px;
    padding:8px 10px;
    font-size:13px;
    background:white;
    outline:none;
}
select:focus, textarea:focus{ border-color:#0176d3; }
textarea{ min-height:65px; resize:none; }

/* BUTTON */
.submit-btn{
    background:#0176d3;
    color:white;
    border:none;
    border-radius:4px;
    padding:9px 16px;
    font-size:13px;
    font-weight:600;
    cursor:pointer;
    align-self: flex-end;
    width: 100%;
    text-align: center;
}
.submit-btn:hover{ background:#015a9e; }

/* EMPTY STATE */
.empty{ background:white; border:1px solid #c9c9c9; border-radius:4px; padding:60px 20px; text-align:center; }
.empty h3{ color:#181818; margin:12px 0 4px 0; }
.empty p{ color:#747472; margin:0; font-size:13px;}

/* MOBILE RESPONSIVENESS */
@media(max-width:900px){
    .card-split-workspace{ grid-template-columns:1fr; }
    .timeline-column{ border-right:none; border-bottom:1px solid #e5e5e5; max-height:auto;}
    .description-box{ border-left:none; padding-left:0; margin-top:8px;}
    .summary-section{ flex-direction: column; gap:10px; }
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
    for(HashMap<String,Object> row : requestList){
        String status = String.valueOf(row.get("status"));
%>

<div class="request-card">
    <!-- Header Block -->
    <div class="top-row">
        <div class="request-no"><i class="fas fa-hashtag"></i> <%= row.get("request_no") %></div>
        <div class="status-badge <%= status.toLowerCase().replace(" ","-") %>"><%= status %></div>
    </div>

    <!-- Data Summary Section -->
    <div class="summary-section">
        <div class="info-box">
            <div class="label">Request Date</div>
            <div class="value"><%= row.get("request_date") %></div>
        </div>
        <div class="info-box">
            <div class="label">Priority</div>
            <div class="value"><%= row.get("priority") %></div>
        </div>
        <div class="info-box">
            <div class="label">Assigned To</div>
            <div class="value"><%= row.get("assigned_name") != null ? row.get("assigned_name") : "Pending Assignment" %></div>
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

    <!-- Workspace Area split into Timeline & Activity Action Panel -->
    <div class="card-split-workspace">
        
        <!-- Timeline Columns -->
        <div class="timeline-column">
            <h3 class="timeline-title"><i class="fas fa-clock-rotate-left"></i> History Timeline</h3>
            <%
            ArrayList<HashMap<String,Object>> followupList = (ArrayList<HashMap<String,Object>>) row.get("followupList");
            if(followupList != null && followupList.size() > 0){
                for(HashMap<String,Object> f : followupList){
            %>
            <div class="followup-box">
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
            <div class="followup-box"><div class="remark">No logs recorded yet.</div></div>
            <% } %>
        </div>

        <!-- Update Action Column -->
        <div class="form-column">
            <h3 class="form-title"><i class="fas fa-comment-dots"></i> Update Status</h3>
            <form action="<%=request.getContextPath()%>/TrackRequestServlet" method="post" class="form-vertical">
                <input type="hidden" name="request_id" value="<%= row.get("id") %>">
                
                <select name="status" required>
                    <option value="">Select Status</option>
                    <option value="OPEN">OPEN</option>
                    <option value="ASSIGNED">ASSIGNED</option>
                    <option value="IN PROGRESS">IN PROGRESS</option>
                    <option value="PENDING">PENDING</option>
                    <option value="COMPLETED">COMPLETED</option>
                    <option value="SATISFIED">SATISFIED</option>
                    <option value="CLOSED">CLOSED</option>
                </select>

                <textarea name="remarks" placeholder="Provide operational remarks..." required></textarea>
                
                <button type="submit" class="submit-btn"><i class="fas fa-paper-plane"></i> Update</button>
            </form>
        </div>

    </div>
</div>

<%
    }
} else {
%>
<div class="empty">
    <i class="fas fa-folder-open" style="font-size:44px; color:#cbd5e1;"></i>
    <h3>No Requests Found</h3>
    <p>You have not created any service requests yet.</p>
</div>
<%
}
%>

</div>
</body>
</html>