<%@page import="java.sql.ResultSet"%>

<%@ page language="java"
contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<title>Location Management</title>

<style>

body{
    margin:0;
    padding:20px;
    font-family:Arial;
    background:#f3f5f9;
}

/* MAIN CARD */

.container{
    width:95%;
    margin:auto;
    background:#ffffff;
    border-radius:18px;
    padding:30px;
    box-shadow:0 4px 20px rgba(0,0,0,0.08);
}

/* TITLE */

.page-title{
    font-size:34px;
    font-weight:bold;
    color:#172b5b;
    margin-bottom:25px;
    border-left:6px solid #172b5b;
    padding-left:15px;
}

/* ALERTS */

.success{
    background:#e8fff0;
    color:#00a651;
    padding:12px;
    border-radius:10px;
    margin-bottom:20px;
    font-weight:bold;
}

.error{
    background:#ffecec;
    color:#ff3b3b;
    padding:12px;
    border-radius:10px;
    margin-bottom:20px;
    font-weight:bold;
}

/* FORM */

.form-grid{
    display:grid;
    grid-template-columns:repeat(2,1fr);
    gap:20px;
}

.form-group label{
    display:block;
    margin-bottom:8px;
    color:#172b5b;
    font-weight:bold;
}

.form-group input,
.form-group textarea{
    width:100%;
    padding:12px;
    border:1px solid #d6dce8;
    border-radius:10px;
    font-size:14px;
    box-sizing:border-box;
}

.form-group textarea{
    height:90px;
    resize:none;
}

/* BUTTON */

.save-btn{
    margin-top:25px;
    background:#172b5b;
    color:white;
    border:none;
    padding:14px 25px;
    border-radius:10px;
    font-size:15px;
    cursor:pointer;
    font-weight:bold;
}

.save-btn:hover{
    background:#0f1d42;
}

/* TABLE SECTION */

.table-title{
    margin-top:45px;
    margin-bottom:20px;
    color:#172b5b;
    font-size:28px;
    font-weight:bold;
}

.table-wrapper{
    overflow:auto;
    border-radius:15px;
}

table{
    width:100%;
    border-collapse:collapse;
    background:white;
}

table th{
    background:#172b5b;
    color:white;
    padding:14px;
    text-align:left;
    font-size:15px;
}

table td{
    padding:12px;
    border-bottom:1px solid #e5e9f2;
}

/* TABLE INPUT */

.table-input{
    width:100%;
    padding:8px;
    border:1px solid #d6dce8;
    border-radius:8px;
    box-sizing:border-box;
}

/* ACTION BUTTONS */

.action-btn{
    border:none;
    padding:8px 14px;
    border-radius:8px;
    color:white;
    cursor:pointer;
    font-size:13px;
    font-weight:bold;
    text-decoration:none;
    margin-right:5px;
}

.edit-btn{
    background:#f4b400;
}

.update-btn{
    background:#00a651;
}

.delete-btn{
    background:#ff3b3b;
}

.cancel-btn{
    background:#6c757d;
}

</style>

<script>

function enableEdit(id){

    document.getElementById("text_"+id).style.display="none";

    document.getElementById("edit_"+id).style.display="table-row";

}

function cancelEdit(id){

    document.getElementById("text_"+id).style.display="table-row";

    document.getElementById("edit_"+id).style.display="none";

}

</script>

</head>

<body>
<%@ include file="../header.jsp" %>
<div class="container">

<div class="page-title">
Location Management
</div>

<%
if(request.getParameter("success") != null){
%>

<div class="success">
Location Added Successfully
</div>

<%
}

if(request.getParameter("updated") != null){
%>

<div class="success">
Location Updated Successfully
</div>

<%
}

if(request.getParameter("deleted") != null){
%>

<div class="success">
Location Deleted Successfully
</div>

<%
}

if(request.getParameter("error") != null){
%>

<div class="error">
Operation Failed
</div>

<%
}
%>

<!-- ADD FORM -->

<form action="<%=request.getContextPath()%>/LocationController"
method="post">

<input type="hidden"
name="action"
value="insert">

<div class="form-grid">

<div class="form-group">

<label>Location Name</label>

<input type="text"
name="location_name"
required>

</div>

<div class="form-group">

<label>Building</label>

<input type="text"
name="building">

</div>

<div class="form-group">

<label>Floor Name</label>

<input type="text"
name="floor_name">

</div>

<div class="form-group">

<label>Room Number</label>

<input type="text"
name="room_number">

</div>

<div class="form-group"
style="grid-column:1/3;">

<label>Description</label>

<textarea name="description"></textarea>

</div>

</div>

<button type="submit"
class="save-btn">

Save Location

</button>

</form>

<!-- TABLE -->

<div class="table-title">
Location List
</div>

<div class="table-wrapper">

<table>

<tr>

<th>ID</th>
<th>Location</th>
<th>Building</th>
<th>Floor</th>
<th>Room</th>
<th>Description</th>
<th width="220">Action</th>

</tr>

<%

ResultSet rs =
(ResultSet)request.getAttribute("locationData");

if(rs != null){

    while(rs.next()){

        int id =
        rs.getInt("location_id");

%>

<!-- NORMAL VIEW -->

<tr id="text_<%=id%>">

<td>
<%=id%>
</td>

<td>
<%=rs.getString("location_name")%>
</td>

<td>
<%=rs.getString("building")%>
</td>

<td>
<%=rs.getString("floor_name")%>
</td>

<td>
<%=rs.getString("room_number")%>
</td>

<td>
<%=rs.getString("description")%>
</td>

<td>

<button type="button"
class="action-btn edit-btn"
onclick="enableEdit('<%=id%>')">

Edit

</button>

<a class="action-btn delete-btn"

onclick="return confirm('Are you sure to delete?')"

href="<%=request.getContextPath()%>/LocationController?action=delete&id=<%=id%>">

Delete

</a>

</td>

</tr>

<!-- EDIT ROW -->

<tr id="edit_<%=id%>"
style="display:none;background:#f9fbff;">

<form action="<%=request.getContextPath()%>/LocationController"
method="post">

<input type="hidden"
name="action"
value="update">

<input type="hidden"
name="location_id"
value="<%=id%>">

<td>
<%=id%>
</td>

<td>

<input type="text"
class="table-input"
name="location_name"
value="<%=rs.getString("location_name")%>">

</td>

<td>

<input type="text"
class="table-input"
name="building"
value="<%=rs.getString("building")%>">

</td>

<td>

<input type="text"
class="table-input"
name="floor_name"
value="<%=rs.getString("floor_name")%>">

</td>

<td>

<input type="text"
class="table-input"
name="room_number"
value="<%=rs.getString("room_number")%>">

</td>

<td>

<input type="text"
class="table-input"
name="description"
value="<%=rs.getString("description")%>">

</td>

<td>

<button type="submit"
class="action-btn update-btn">

Update

</button>

<button type="button"
class="action-btn cancel-btn"
onclick="cancelEdit('<%=id%>')">

Cancel

</button>

</td>

</form>

</tr>

<%
    }
}
%>

</table>

</div>

</div>

</body>
</html>