<%@ page language="java" contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

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
&& (!"Finance".equalsIgnoreCase(dept))){

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
    font-family:"Segoe UI",sans-serif;
    background:#f3f6f9;
    color:#1f2937;
}

/* Top Section */

.page-header{
    background:white;
    padding:20px 28px;
    border-bottom:1px solid #d8dde6;
    display:flex;
    justify-content:space-between;
    align-items:center;
}

.page-title{
    display:flex;
    align-items:center;
    gap:14px;
}

.icon-box{
    width:52px;
    height:52px;
    background:#0176d3;
    border-radius:14px;
    display:flex;
    align-items:center;
    justify-content:center;
    color:white;
    font-size:22px;
    box-shadow:0 4px 12px rgba(1,118,211,0.25);
}

.title-text h2{
    margin:0;
    font-size:24px;
    font-weight:700;
    color:#16325c;
}

.title-text p{
    margin:4px 0 0;
    color:#5f6b7a;
    font-size:14px;
}

.user-chip{
    background:#eef4ff;
    color:#0176d3;
    padding:10px 16px;
    border-radius:30px;
    font-size:14px;
    font-weight:600;
}

/* Container */

.container{
    padding:24px;
}

/* Alert */

.alert{
    padding:14px 18px;
    border-radius:12px;
    margin-bottom:20px;
    font-size:14px;
    font-weight:600;
}

.alert-success{
    background:#edfdf3;
    color:#067647;
    border:1px solid #abefc6;
}

.alert-error{
    background:#fef3f2;
    color:#b42318;
    border:1px solid #fecdca;
}

/* Card */

.card{
    background:white;
    border-radius:18px;
    overflow:hidden;
    box-shadow:0 2px 12px rgba(15,23,42,0.06);
    border:1px solid #e5e7eb;
}

/* Table */

.table-wrapper{
    overflow:auto;
}

table{
    width:100%;
    border-collapse:collapse;
}

table thead{
    background:#f8fafc;
}

table th{
    padding:16px;
    text-align:left;
    font-size:13px;
    color:#475467;
    font-weight:700;
    border-bottom:1px solid #e5e7eb;
    white-space:nowrap;
}

table td{
    padding:16px;
    border-bottom:1px solid #f1f5f9;
    vertical-align:middle;
    font-size:14px;
}

table tr:hover{
    background:#fafcff;
}

/* Badges */

.status-badge{
    display:inline-flex;
    align-items:center;
    gap:6px;
    padding:6px 12px;
    border-radius:30px;
    font-size:12px;
    font-weight:700;
}

.open{
    background:#fff7e6;
    color:#b54708;
}

.assigned{
    background:#ecfdf3;
    color:#027a48;
}

/* Priority */

.priority{
    font-weight:700;
}

.high{
    color:#d92d20;
}

.medium{
    color:#b54708;
}

.low{
    color:#027a48;
}

/* Assigned */

.assigned-user{
    display:flex;
    align-items:center;
    gap:10px;
    font-weight:600;
    color:#027a48;
}

.assigned-user i{
    background:#ecfdf3;
    padding:8px;
    border-radius:50%;
}

.not-assigned{
    color:#98a2b3;
    font-weight:600;
}

/* Select */

select{
    width:100%;
    min-width:220px;
    padding:10px 12px;
    border-radius:10px;
    border:1px solid #d0d5dd;
    background:white;
    font-size:14px;
    outline:none;
}

select:focus{
    border-color:#0176d3;
    box-shadow:0 0 0 3px rgba(1,118,211,0.12);
}

/* Button */

.assign-btn{
    background:#0176d3;
    color:white;
    border:none;
    padding:10px 18px;
    border-radius:10px;
    cursor:pointer;
    font-size:14px;
    font-weight:700;
    transition:0.2s;
    white-space:nowrap;
}

.assign-btn:hover{
    background:#025fb2;
    transform:translateY(-1px);
}

/* Empty */

.empty-state{
    padding:70px 20px;
    text-align:center;
}

.empty-state i{
    font-size:60px;
    color:#cbd5e1;
    margin-bottom:18px;
}

.empty-state h3{
    margin:0;
    color:#334155;
}

.empty-state p{
    color:#64748b;
    margin-top:8px;
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
    Request assigned successfully.
</div>

<%
}

if("error".equals(msg)){
%>

<div class="alert alert-error">
    <i class="fas fa-circle-xmark"></i>
    Failed to assign request.
</div>

<%
}

ArrayList<HashMap<String,Object>> requestList =
(ArrayList<HashMap<String,Object>>)request.getAttribute("requestList");

if(requestList != null && requestList.size() > 0){
%>

<div class="card">

<div class="table-wrapper">

<table>

<thead>

<tr>
    <th>Request No</th>
    <th>Date</th>
    <th>Requested By</th>
    <th>Location</th>
    <th>Description</th>
    <th>Priority</th>
    <th>Status</th>
    <th>Assigned To</th>
    <th>Assign Incharge</th>
    <th>Action</th>
</tr>

</thead>

<tbody>

<%
for(HashMap<String,Object> row : requestList){

ArrayList<HashMap<String,Object>> inchargeList =
(ArrayList<HashMap<String,Object>>)row.get("inchargeList");

String status = String.valueOf(row.get("status"));
String priority = String.valueOf(row.get("priority"));
%>

<tr>

<form action="<%=request.getContextPath()%>/Assign_ServiceRequestServlet"
method="post">

<td>

    <strong style="color:#0176d3;">
        <%= row.get("request_no") %>
    </strong>

    <input type="hidden"
    name="request_id"
    value="<%= row.get("id") %>">

</td>

<td><%= row.get("request_date") %></td>

<td>
    <strong><%= row.get("requested_by") %></strong>
</td>

<td><%= row.get("location") %></td>

<td style="min-width:240px;">
    <%= row.get("description") %>
</td>

<td>

<%
if("HIGH".equalsIgnoreCase(priority)){
%>

<span class="priority high">
    <i class="fas fa-circle"></i> HIGH
</span>

<%
}else if("MEDIUM".equalsIgnoreCase(priority)){
%>

<span class="priority medium">
    <i class="fas fa-circle"></i> MEDIUM
</span>

<%
}else{
%>

<span class="priority low">
    <i class="fas fa-circle"></i> LOW
</span>

<%
}
%>

</td>

<td>

<%
if("OPEN".equalsIgnoreCase(status)){
%>

<span class="status-badge open">
    <i class="fas fa-folder-open"></i>
    OPEN
</span>

<%
}else{
%>

<span class="status-badge assigned">
    <i class="fas fa-user-check"></i>
    ASSIGNED
</span>

<%
}
%>

</td>

<td>

<%
String assignedName =
(String)row.get("assigned_name");

if(assignedName != null){
%>

<div class="assigned-user">

    <i class="fas fa-user"></i>

    <span><%= assignedName %></span>

</div>

<%
}else{
%>

<span class="not-assigned">
    Not Assigned
</span>

<%
}
%>

</td>

<td>

<select name="assigned_to" required>

<option value="">Select Incharge</option>

<%
for(HashMap<String,Object> inc : inchargeList){
%>

<option value="<%= inc.get("id") %>">

    <%= inc.get("incharge_name") %>
    -
    <%= inc.get("designation") %>

</option>

<%
}
%>

</select>

</td>

<td>

<button type="submit" class="assign-btn">

    <i class="fas fa-paper-plane"></i>

    Assign

</button>

</td>

</form>

</tr>

<%
}
%>

</tbody>

</table>

</div>

</div>

<%
}else{
%>

<div class="card">

<div class="empty-state">

    <i class="fas fa-inbox"></i>

    <h3>No Service Requests Found</h3>

    <p>All requests are cleared or no requests available.</p>

</div>

</div>

<%
}
%>

</div>

</body>
</html>