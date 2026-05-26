<%@ page language="java" contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

<%@ page import="java.util.*" %>

<%
HttpSession sess = request.getSession(false);

if(sess == null || sess.getAttribute("username") == null){

    response.sendRedirect(
    request.getContextPath()+"/login.jsp");

    return;
}

String username =
((String)sess.getAttribute("username"))
.toUpperCase();
%>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<title>My Service Requests</title>

<link rel="stylesheet"
href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

<style>

*{
    box-sizing:border-box;
}

body{
    margin:0;
    font-family:Segoe UI;
    background:#f4f6f9;
    color:#1f2937;
}

.page-header{
    background:white;
    padding:16px 24px;
    border-bottom:1px solid #d8dde6;
    display:flex;
    justify-content:space-between;
    align-items:center;
    flex-wrap:wrap;
    gap:15px;
}

.header-left{
    display:flex;
    align-items:center;
    gap:12px;
}

.icon-box{
    width:48px;
    height:48px;
    border-radius:14px;
    background:linear-gradient(135deg,#0176d3,#005fb2);
    display:flex;
    align-items:center;
    justify-content:center;
    color:white;
    font-size:20px;
    box-shadow:0 4px 10px rgba(1,118,211,0.25);
}

.title h2{
    margin:0;
    color:#16325c;
    font-size:23px;
}

.title p{
    margin:3px 0 0;
    color:#667085;
    font-size:13px;
}

.user-chip{
    background:#eef4ff;
    color:#0176d3;
    padding:9px 15px;
    border-radius:25px;
    font-weight:700;
    font-size:13px;
    border:1px solid #dbeafe;
}

.container{
    padding:20px;
}

.alert{
    padding:14px 16px;
    border-radius:12px;
    margin-bottom:18px;
    font-size:14px;
    font-weight:700;
}

.success{
    background:#ecfdf3;
    color:#027a48;
    border:1px solid #abefc6;
}

.error{
    background:#fef2f2;
    color:#b42318;
    border:1px solid #fecdca;
}

.request-card{
    background:white;
    border-radius:18px;
    padding:20px;
    margin-bottom:20px;
    border:1px solid #e5e7eb;
    box-shadow:0 2px 10px rgba(0,0,0,0.05);
}

.top-row{
    display:flex;
    justify-content:space-between;
    align-items:center;
    margin-bottom:18px;
    gap:10px;
    flex-wrap:wrap;
}

.request-no{
    font-size:18px;
    font-weight:700;
    color:#0176d3;
}

.status-badge{
    padding:7px 14px;
    border-radius:25px;
    font-size:11px;
    font-weight:700;
    text-transform:uppercase;
    letter-spacing:0.5px;
}

.open{
    background:#fff7e6;
    color:#b54708;
}

.assigned{
    background:#ecfdf3;
    color:#027a48;
}

.in-progress{
    background:#eef4ff;
    color:#175cd3;
}

.pending{
    background:#fef3c7;
    color:#92400e;
}

.completed{
    background:#f3e8ff;
    color:#7e22ce;
}

.satisfied{
    background:#dcfce7;
    color:#166534;
}

.closed{
    background:#e2e8f0;
    color:#334155;
}

.info-grid{
    display:grid;
    grid-template-columns:
    repeat(auto-fit,minmax(180px,1fr));
    gap:14px;
    margin-bottom:18px;
}

.info-box{
    background:#f8fafc;
    padding:14px;
    border-radius:12px;
    border:1px solid #edf2f7;
}

.label{
    font-size:11px;
    color:#667085;
    margin-bottom:5px;
    font-weight:700;
    letter-spacing:0.5px;
}

.value{
    font-size:14px;
    font-weight:600;
    color:#111827;
}

.description-box{
    background:#f8fafc;
    padding:16px;
    border-radius:12px;
    margin-bottom:18px;
    border:1px solid #edf2f7;
}

.description-text{
    font-size:14px;
    line-height:1.7;
    color:#374151;
    margin-top:6px;
}

.timeline-title{
    margin:0 0 14px;
    color:#16325c;
    font-size:17px;
}

.followup-box{
    background:#f8fbff;
    border-left:4px solid #0176d3;
    border-radius:12px;
    padding:14px;
    margin-bottom:12px;
}

.followup-top{
    display:flex;
    justify-content:space-between;
    align-items:flex-start;
    gap:10px;
    margin-bottom:10px;
    flex-wrap:wrap;
}

.followup-status{
    background:#eef4ff;
    color:#0176d3;
    padding:5px 12px;
    border-radius:18px;
    font-size:11px;
    font-weight:700;
}

.date{
    color:#667085;
    font-size:12px;
    line-height:1.5;
}

.remark{
    font-size:13px;
    line-height:1.7;
    color:#344054;
}

.form-section{
    margin-top:18px;
    padding-top:18px;
    border-top:1px dashed #d0d5dd;
}

.form-title{
    font-size:15px;
    font-weight:700;
    color:#16325c;
    margin-bottom:12px;
}

.form-grid{
    display:grid;
    grid-template-columns:1fr 2fr auto;
    gap:12px;
    align-items:start;
}

select,
textarea{
    width:100%;
    border:1px solid #d0d5dd;
    border-radius:12px;
    padding:12px;
    font-size:13px;
    outline:none;
    transition:0.3s;
    background:white;
}

select:focus,
textarea:focus{
    border-color:#0176d3;
    box-shadow:0 0 0 3px rgba(1,118,211,0.1);
}

textarea{
    min-height:55px;
    resize:vertical;
}

.submit-btn{
    background:linear-gradient(135deg,#0176d3,#005fb2);
    color:white;
    border:none;
    padding:12px 20px;
    border-radius:12px;
    font-weight:700;
    cursor:pointer;
    transition:0.3s;
    min-width:150px;
}

.submit-btn:hover{
    transform:translateY(-1px);
    box-shadow:0 5px 12px rgba(1,118,211,0.25);
}

.empty{
    background:white;
    padding:70px 30px;
    border-radius:18px;
    text-align:center;
    color:#667085;
    border:1px solid #e5e7eb;
}

.empty h3{
    margin-top:16px;
    color:#16325c;
}

@media(max-width:768px){

.container{
    padding:14px;
}

.form-grid{
    grid-template-columns:1fr;
}

.top-row{
    flex-direction:column;
    align-items:flex-start;
}

.page-header{
    padding:16px;
}

}

</style>

</head>

<body>

<%@ include file="../header.jsp" %>

<div class="page-header">

    <div class="header-left">

        <div class="icon-box">
            <i class="fas fa-ticket-alt"></i>
        </div>

        <div class="title">
            <h2>My Service Requests</h2>
            <p>Track requests and manage follow-ups</p>
        </div>

    </div>

    <div class="user-chip">

        <i class="fas fa-user-circle"></i>

        <%= username %>

    </div>

</div>

<div class="container">

<%

String msg = request.getParameter("msg");

if("success".equals(msg)){
%>

<div class="alert success">

    <i class="fas fa-circle-check"></i>

    Follow-up submitted successfully.

</div>

<%
}

if("error".equals(msg)){
%>

<div class="alert error">

    <i class="fas fa-circle-xmark"></i>

    Failed to submit follow-up.

</div>

<%
}

ArrayList<HashMap<String,Object>> requestList =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("requestList");

if(requestList != null &&
requestList.size() > 0){

for(HashMap<String,Object> row : requestList){

String status =
String.valueOf(row.get("status"));
%>

<div class="request-card">

    <div class="top-row">

        <div class="request-no">

            <i class="fas fa-hashtag"></i>

            <%= row.get("request_no") %>

        </div>

        <div class="status-badge
        <%= status.toLowerCase()
        .replace(" ","-") %>">

            <%= status %>

        </div>

    </div>

    <div class="info-grid">

        <div class="info-box">

            <div class="label">REQUEST DATE</div>

            <div class="value">
                <%= row.get("request_date") %>
            </div>

        </div>

        <div class="info-box">

            <div class="label">PRIORITY</div>

            <div class="value">
                <%= row.get("priority") %>
            </div>

        </div>

        <div class="info-box">

            <div class="label">ASSIGNED TO</div>

            <div class="value">

                <%= row.get("assigned_name") != null
                ? row.get("assigned_name")
                : "Pending Assignment" %>

            </div>

        </div>

        <div class="info-box">

            <div class="label">LOCATION</div>

            <div class="value">
                <%= row.get("location") %>
            </div>

        </div>

    </div>

    <div class="description-box">

        <div class="label">DESCRIPTION</div>

        <div class="description-text">

            <%= row.get("description") %>

        </div>

    </div>

    <h3 class="timeline-title">

        <i class="fas fa-clock-rotate-left"></i>

        Follow-up Timeline

    </h3>

<%

ArrayList<HashMap<String,Object>>
followupList =

(ArrayList<HashMap<String,Object>>)
row.get("followupList");

if(followupList != null &&
followupList.size() > 0){

for(HashMap<String,Object> f
: followupList){
%>

<div class="followup-box">

    <div class="followup-top">

        <div class="followup-status">

            <%= f.get("status") %>

        </div>

        <div class="date">

            <i class="fas fa-user"></i>

            <%= f.get("updated_by") %>

            &nbsp; | &nbsp;

            <i class="fas fa-clock"></i>

            <%= f.get("updated_on") %>

        </div>

    </div>

    <div class="remark">

        <%= f.get("remarks") %>

    </div>

</div>

<%
}

}else{
%>

<div class="followup-box">

    <div class="remark">

        No follow-ups available yet.

    </div>

</div>

<%
}
%>

<div class="form-section">

    <div class="form-title">

        <i class="fas fa-comment-dots"></i>

        Add Follow-up

    </div>

    <form action="<%=request.getContextPath()%>/TrackRequestServlet"
    method="post">

    <input type="hidden"
    name="request_id"
    value="<%= row.get("id") %>">

    <div class="form-grid">

        <select name="status" required>

            <option value="">
                Select Status
            </option>

            <option value="OPEN">
                OPEN
            </option>

            <option value="ASSIGNED">
                ASSIGNED
            </option>

            <option value="IN PROGRESS">
                IN PROGRESS
            </option>

            <option value="PENDING">
                PENDING
            </option>

            <option value="COMPLETED">
                COMPLETED
            </option>

            <option value="SATISFIED">
                SATISFIED
            </option>

            <option value="CLOSED">
                CLOSED
            </option>

        </select>

        <textarea name="remarks"
        placeholder="Enter follow-up remarks..."
        required></textarea>

        <button type="submit"
        class="submit-btn">

            <i class="fas fa-paper-plane"></i>

            Submit

        </button>

    </div>

    </form>

</div>

</div>

<%
}

}else{
%>

<div class="empty">

    <i class="fas fa-folder-open"
    style="font-size:60px;
    color:#cbd5e1;"></i>

    <h3>No Requests Found</h3>

    <p>
        You have not created any
        service requests yet.
    </p>

</div>

<%
}
%>

</div>

</body>
</html>