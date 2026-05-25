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

<title>Service Request</title>

<style>

*{
    box-sizing:border-box;
}

body{
    margin:0;
    background:#f3f6f9;
    font-family:Segoe UI;
}

.container{
    width:650px;
    margin:30px auto;
}

.card{

    background:white;
    border-radius:12px;
    padding:30px;
    box-shadow:0 2px 10px rgba(0,0,0,0.08);
}

.title{

    font-size:26px;
    font-weight:600;
    color:#0176d3;
    margin-bottom:25px;
}

.grid{

    display:grid;
    grid-template-columns:1fr 1fr;
    gap:18px;
}

.form-group{

    display:flex;
    flex-direction:column;
}

.full{
    grid-column:1/3;
}

label{

    font-size:14px;
    margin-bottom:6px;
    font-weight:600;
    color:#444;
}

input,
select,
textarea{

    padding:11px 12px;
    border:1px solid #d8dde6;
    border-radius:8px;
    font-size:14px;
    background:white;
}

input:focus,
select:focus,
textarea:focus{

    outline:none;
    border:1px solid #0176d3;
    box-shadow:0 0 4px rgba(1,118,211,0.3);
}

textarea{

    height:120px;
    resize:none;
}

.btn{

    background:#0176d3;
    color:white;
    border:none;
    padding:12px 22px;
    border-radius:8px;
    font-size:15px;
    cursor:pointer;
    font-weight:600;
}

.btn:hover{

    background:#015fb2;
}

.success{

    background:#d8f3dc;
    color:#1b4332;
    padding:12px;
    border-radius:8px;
    margin-bottom:20px;
}

</style>

<script>

function loadComplaintTypes(){

    var departmentId =
    document.getElementById("department_id").value;

    if(departmentId==""){

        document.getElementById(
        "complaint_type_id"
        ).innerHTML=
        "<option value=''>Select Complaint Type</option>";

        return;
    }

    var xhr = new XMLHttpRequest();

    xhr.open(

        "GET",

        "<%=request.getContextPath()%>/RequestBookingServlet?action=loadComplaintTypes&department_id="
        + departmentId,

        true
    );

    xhr.onreadystatechange=function(){

        if(xhr.readyState==4 && xhr.status==200){

            document.getElementById(
            "complaint_type_id"
            ).innerHTML=xhr.responseText;
        }
    };

    xhr.send();
}

</script>

</head>

<body>

<%@ include file="../header.jsp" %>

<div class="container">

<div class="card">

<div class="title">

    Book Service Request

</div>

<%
String msg=(String)request.getAttribute("msg");

if(msg!=null){
%>

<div class="success">

    <%=msg%>

</div>

<%
}
%>

<form action="<%=request.getContextPath()%>/RequestBookingServlet"
      method="post">

<div class="grid">

<div class="form-group">

<label>Requested By</label>

<input type="text"
       name="requested_by"
       value="<%=username%>"
       readonly>

</div>

<div class="form-group">

<label>Priority</label>

<select name="priority" required>

<option value="">Select Priority</option>

<option value="Low">Low</option>
<option value="Medium">Medium</option>
<option value="High">High</option>
<option value="Urgent">Urgent</option>

</select>

</div>

<div class="form-group">

<label>Department</label>

<select name="department_id"
        id="department_id"
        onchange="loadComplaintTypes()"
        required>

<option value="">Select Department</option>

<%
ArrayList<HashMap<String,Object>> departments=
(ArrayList<HashMap<String,Object>>)request.getAttribute("departments");

if(departments!=null){

    for(HashMap<String,Object> d:departments){
%>

<option value="<%=d.get("id")%>">

<%=d.get("department_name")%>

</option>

<%
    }
}
%>

</select>

</div>

<div class="form-group">

<label>Complaint Type</label>

<select name="complaint_type_id"
        id="complaint_type_id"
        required>

<option value="">Select Complaint Type</option>

</select>

</div>

<div class="form-group full">

<label>Location</label>

<input type="text"
       name="location"
       placeholder="Enter Location"
       required>

</div>

<div class="form-group full">

<label>Description</label>

<textarea name="description"
          placeholder="Describe the issue"
          required></textarea>

</div>

<div class="form-group full">

<button type="submit" class="btn">

    Submit Request

</button>

</div>

</div>

</form>

</div>

</div>
<%
String popupMsg = (String)session.getAttribute("msg");

if(popupMsg != null){
%>

<script>

alert("<%= popupMsg %>");

</script>

<%
session.removeAttribute("msg");
}
%>
</body>
</html>