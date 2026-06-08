<%@ page language="java"
contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

<%@ page import="java.util.*" %>

<%
ArrayList<String> availableMonths =
(ArrayList<String>)request.getAttribute("availableMonths");

List<Map<String,Object>> reportList =
(List<Map<String,Object>>)request.getAttribute("reportList");

String selectedMonth =
(String)request.getAttribute("selectedMonth");
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Stock Audit Report</title>

<style>

body{
    font-family:Arial;
    margin:20px;
}

table{
    width:100%;
    border-collapse:collapse;
    margin-top:20px;
}

th,td{
    border:1px solid #ccc;
    padding:8px;
}

th{
    background:#007bff;
    color:white;
}

.filter-box{
    margin-bottom:20px;
    padding:15px;
    background:#f5f5f5;
    border-radius:5px;
}

select,button{
    padding:8px;
}

</style>

<script>
function loadReport() {
    document.getElementById("filterForm").submit();
}
</script>

</head>

<body>

<h2>Stock Audit Report</h2>

<div class="filter-box">

<form id="filterForm"
      action="StockAuditReportServlet"
      method="get">

    <label><b>Select Month :</b></label>

    <select name="month" onchange="loadReport()">

        <option value="">-- Select Month --</option>

        <%
        if(availableMonths!=null){
            for(String month : availableMonths){
        %>

        <option value="<%=month%>"
            <%=month.equals(selectedMonth)?"selected":""%>>
            <%=month%>
        </option>

        <%
            }
        }
        %>

    </select>

</form>

</div>

<%
if(selectedMonth!=null && !selectedMonth.equals("")){
%>

<table>

<tr>
    <th>Audit ID</th>
    <th>Date</th>
    <th>Verified By</th>
    <th>Status</th>
    <th>Category</th>
    <th>Sub Category</th>
    <th>Item Name</th>
    <th>UOM</th>
    <th>System Qty</th>
    <th>Physical Qty</th>
    <th>Variance Qty</th>
    <th>Remarks</th>
</tr>

<%
if(reportList!=null && !reportList.isEmpty()){

for(Map<String,Object> row : reportList){
%>

<tr>
    <td><%=row.get("verificationId")%></td>
    <td><%=row.get("verificationDate")%></td>
    <td><%=row.get("verifiedBy")%></td>
    <td><%=row.get("status")%></td>
    <td><%=row.get("category")%></td>
    <td><%=row.get("subCategory")%></td>
    <td><%=row.get("itemName")%></td>
    <td><%=row.get("uom")%></td>
    <td><%=row.get("systemQty")%></td>
    <td><%=row.get("physicalQty")%></td>
    <td><%=row.get("varianceQty")%></td>
    <td><%=row.get("remarks")%></td>
</tr>

<%
}
}else{
%>

<tr>
    <td colspan="12" align="center">
        No Records Found For Selected Month
    </td>
</tr>

<%
}
%>

</table>

<%
}
%>

</body>
</html>