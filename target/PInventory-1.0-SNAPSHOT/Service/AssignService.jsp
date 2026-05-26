<%@ page language="java" contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

<%@ page import="java.util.*" %>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Open Service Requests</title>

<link rel="stylesheet"
href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

<style>

body{
    margin:0;
    font-family:Segoe UI;
    background:#f4f6f9;
}

.header{
    background:#0d6efd;
    color:white;
    padding:18px 25px;
    font-size:24px;
    font-weight:bold;
    display:flex;
    align-items:center;
    gap:10px;
}

.container{
    padding:25px;
}

.card{
    background:white;
    padding:20px;
    border-radius:12px;
    box-shadow:0 2px 10px rgba(0,0,0,0.08);
}

table{
    width:100%;
    border-collapse:collapse;
    margin-top:15px;
}

table th{
    background:#0d6efd;
    color:white;
    padding:12px;
    font-size:14px;
}

table td{
    padding:12px;
    border-bottom:1px solid #ddd;
    font-size:14px;
    vertical-align:top;
}

select{
    width:100%;
    padding:8px;
    border-radius:6px;
    border:1px solid #ccc;
}

button{
    background:#198754;
    color:white;
    border:none;
    padding:9px 14px;
    border-radius:6px;
    cursor:pointer;
    font-weight:bold;
}

button:hover{
    background:#157347;
}

.badge{
    background:#ffc107;
    color:#000;
    padding:5px 12px;
    border-radius:20px;
    font-size:12px;
    font-weight:bold;
}

.empty{
    text-align:center;
    padding:40px;
    color:#777;
    font-size:18px;
}

.success{
    background:#d1e7dd;
    color:#0f5132;
    padding:12px;
    border-radius:8px;
    margin-bottom:15px;
}

.error{
    background:#f8d7da;
    color:#842029;
    padding:12px;
    border-radius:8px;
    margin-bottom:15px;
}

</style>

</head>

<body>

<div class="header">
    <i class="fas fa-headset"></i>
    Open Service Requests
</div>

<div class="container">

<div class="card">

<%
String msg = request.getParameter("msg");

if("success".equals(msg)){
%>

<div class="success">
    Request Assigned Successfully
</div>

<%
}

if("error".equals(msg)){
%>

<div class="error">
    Failed To Assign Request
</div>

<%
}

ArrayList<HashMap<String,Object>> requestList =
(ArrayList<HashMap<String,Object>>)request.getAttribute("requestList");

if(requestList != null && requestList.size() > 0){
%>

<table>

<tr>
    <th>Request No</th>
    <th>Date</th>
    <th>Requested By</th>
    <th>Location</th>
    <th>Description</th>
    <th>Priority</th>
    <th>Status</th>
    <th>Assigned To</th>
    <th>Assign To</th>
    <th>Action</th>
</tr>

<%
for(HashMap<String,Object> row : requestList){

ArrayList<HashMap<String,Object>> inchargeList =
(ArrayList<HashMap<String,Object>>)row.get("inchargeList");
%>

<tr>

<form action="<%=request.getContextPath()%>/Assign_ServiceRequestServlet"
method="post">

<td>
    <%= row.get("request_no") %>

    <input type="hidden"
    name="request_id"
    value="<%= row.get("id") %>">
</td>

<td><%= row.get("request_date") %></td>

<td><%= row.get("requested_by") %></td>

<td><%= row.get("location") %></td>

<td><%= row.get("description") %></td>

<td><%= row.get("priority") %></td>

<td>
    <span class="badge">
        <%= row.get("status") %>
    </span>
</td>
<td>

<%

String assignedName =
(String)row.get("assigned_name");

if(assignedName != null){

%>

    <span style="color:#198754;font-weight:bold;">
        <i class="fas fa-user-check"></i>
        <%= assignedName %>
    </span>

<%

}else{

%>

    <span style="color:#999;">
        Not Assigned
    </span>

<%
}
%>

</td>

<td width="250">

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

<button type="submit">

    <i class="fas fa-save"></i>

    Assign

</button>

</td>

</form>

</tr>

<%
}
%>

</table>

<%
}else{
%>

<div class="empty">

    <i class="fas fa-folder-open"></i>

    <br><br>

    No Open Service Requests Found

</div>

<%
}
%>

</div>

</div>

</body>
</html>