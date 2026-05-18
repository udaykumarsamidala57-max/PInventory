<%@page import="java.sql.ResultSet"%>

<%@ page language="java"
contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
String user = (String) sess.getAttribute("username");
String role = (String) sess.getAttribute("role");
String dept = (String) sess.getAttribute("department");
if ((!"Global".equalsIgnoreCase(role) &&  !"Finance".equalsIgnoreCase(dept))) {

    out.println("<h3 style='color:red;text-align:center;'>Access Denied! You are not authorized.</h3>");
    return;
}
%>
<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<title>Location Management</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/Asset/css/location.css">

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
<% if ("Global".equalsIgnoreCase(role) ) { %>
<button type="submit"
class="save-btn">

Save Location

</button>
<%} %>
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
<th>Floor</th>
<th>Room</th>
<th>Description</th>
<th width="220">Action</th>

</tr>

<%

ResultSet rs =
(ResultSet)request.getAttribute("locationData");

String currentBuilding = "";

if(rs != null){

    while(rs.next()){

        int id =
        rs.getInt("location_id");

        String building =
        rs.getString("building");

        if(building == null || building.trim().equals("")){

            building = "No Building";
        }

        // BUILDING HEADING

        if(!building.equals(currentBuilding)){

            currentBuilding = building;

%>

<tr class="building-row">

<td colspan="6"
style="
background:#eef4ff;
font-weight:bold;
font-size:15px;
color:#172b5b;
padding:14px;
border-top:2px solid #d6e4ff;
">

🏢 <%=building%>

</td>

</tr>

<%
        }
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
<%=rs.getString("floor_name")%>
</td>

<td>
<%=rs.getString("room_number")%>
</td>

<td>
<%=rs.getString("description")%>
</td>

<td>
<% if ("Global".equalsIgnoreCase(role) ) { %>
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
<%} %>
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

<input type="hidden"
name="building"
value="<%=building%>">

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