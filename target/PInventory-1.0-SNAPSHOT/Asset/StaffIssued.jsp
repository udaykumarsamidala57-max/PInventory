<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<title>Staff Issued Assets</title>

<style>

body{
    font-family:Arial;
    background:#f4f6f9;
    margin:20px;
}

.container{
    width:98%;
    margin:auto;
}

h2{
    color:#2c3e50;
}

table{
    width:100%;
    border-collapse:collapse;
    background:white;
}

th{
    background:#1976d2;
    color:white;
    padding:10px;
}

td{
    padding:8px;
    border:1px solid #ddd;
}

tr:nth-child(even){
    background:#f8f8f8;
}

tr:hover{
    background:#eef5ff;
}

.badge{
    background:#4CAF50;
    color:white;
    padding:4px 10px;
    border-radius:15px;
}

</style>

</head>

<body>

<div class="container">

<h2>Staff Issued Assets</h2>

<%

List<Map<String,Object>> assetList =
(List<Map<String,Object>>)request.getAttribute("assetList");

int i=1;

%>

<table>

<tr>

<th>Sl No</th>
<th>Asset Code</th>
<th>Asset Name</th>
<th>Brand</th>

<th>Location</th>
<th>Assigned Date</th>
<th>Assigned By</th>

</tr>

<%

if(assetList!=null){

for(Map<String,Object> row : assetList){

%>

<tr>

<td><%=i++%></td>

<td><%=row.get("assetCode")%></td>

<td><%=row.get("assetName")%></td>

<td><%=row.get("brand")%></td>



<td>

<span class="badge">
<%=row.get("location")%>
</span>

</td>

<td><%=row.get("assignedDate")%></td>

<td><%=row.get("assignedBy")%></td>

</tr>

<%

}

}

%>

</table>

<br>

<b>Total Issued Assets : <%=assetList==null?0:assetList.size()%></b>

</div>

</body>
</html>