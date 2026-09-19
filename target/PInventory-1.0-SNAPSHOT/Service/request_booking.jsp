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

String username =
((String)sess.getAttribute("username")).toUpperCase();
%>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

<title>Service Request</title>

<style>

*{
    box-sizing:border-box;
}

body{
    margin:0;
    background:#f3f6f9;
    font-family:-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    -webkit-tap-highlight-color: transparent;
}

.container{
    width: 100%;
    max-width: 650px;
    margin: 0 auto;
    padding: 12px;
}

.card{
    background:white;
    border-radius:12px;
    padding:20px 16px;
    box-shadow:0 2px 10px rgba(0,0,0,0.06);
}

.title{
    font-size:20px;
    font-weight:700;
    color:#0176d3;
    margin-bottom:20px;
}

.grid{
    display:grid;
    grid-template-columns:1fr;
    gap:16px;
}

.form-group{
    display:flex;
    flex-direction:column;
}

.full{
    grid-column: 1 / -1;
}

label{
    font-size:13px;
    margin-bottom:6px;
    font-weight:600;
    color:#444;
}

input,
select,
textarea{
    padding:10px 12px;
    border:1px solid #d8dde6;
    border-radius:8px;
    font-size:16px; /* 16px prevents iOS Safari auto-zoom on focus */
    background:white;
    width: 100%;
    outline: none;
    min-height: 44px; /* Optimal mobile touch target size */
    color: #181818;
}

/* Styled custom arrow for selects to look clean across mobile devices */
select {
    -webkit-appearance: none;
    appearance: none;
    background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='6' viewBox='0 0 10 6'><path fill='%23514f4d' d='M0 0l5 5 5-5z'/></svg>");
    background-repeat: no-repeat;
    background-position: right 14px center;
    padding-right: 36px;
}

input[readonly] {
    background-color: #f3f6f9;
    color: #747472;
}

input:focus,
select:focus,
textarea:focus{
    border-color:#0176d3;
    box-shadow:0 0 0 3px rgba(1,118,211,0.15);
}

textarea{
    min-height:110px;
    resize:vertical;
    padding-top: 10px;
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
    width: 100%;
    min-height: 46px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    transition: background 0.15s ease;
}

.btn:active{
    background:#015fb2;
}

.success{
    background:#d8f3dc;
    color:#1b4332;
    padding:12px 14px;
    border-radius:8px;
    margin-bottom:16px;
    font-size:13px;
    font-weight: 600;
    border: 1px solid #b7e4c7;
}

/* DESKTOP RESPONSIVE BREAKPOINT */
@media (min-width: 600px) {
    .container {
        padding: 24px 16px;
    }

    .card {
        padding: 30px;
    }
    
    .title {
        font-size: 24px;
        margin-bottom: 24px;
    }
    
    .grid {
        grid-template-columns: 1fr 1fr;
        gap: 18px;
    }
    
    .full {
        grid-column: 1 / 3;
    }
    
    input, select, textarea {
        font-size: 14px;
    }

    .btn:hover{
        background:#015fb2;
    }
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
ArrayList<HashMap<String,Object>> departments =
(ArrayList<HashMap<String,Object>>)request.getAttribute("departments");

Set<String> uniqueDepartments = new HashSet<String>();

if(departments != null){

    for(HashMap<String,Object> d : departments){

        String deptName =
        String.valueOf(d.get("department_name"));

        if(!uniqueDepartments.contains(deptName)){

            uniqueDepartments.add(deptName);
%>

<option value="<%=d.get("id")%>">

    <%=deptName%>

</option>

<%
        }
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