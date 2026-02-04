<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String fromDate = request.getParameter("fromDate");
String toDate = request.getParameter("toDate");
String category = request.getParameter("category");
String export = request.getParameter("export"); // for Excel export

java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
if (fromDate == null || fromDate.isEmpty()) {
    Calendar cal = Calendar.getInstance();
    cal.set(Calendar.DAY_OF_MONTH, 1);
    fromDate = sdf.format(cal.getTime());
}
if (toDate == null || toDate.isEmpty()) {
    toDate = sdf.format(new java.util.Date());
}


if ("excel".equals(export)) {
    response.setContentType("application/vnd.ms-excel");
    response.setHeader("Content-Disposition", "attachment; filename=Stock_Summary.xls");
}

Connection conn = null;
PreparedStatement ps = null, psCat = null;
ResultSet rs = null, rsCat = null;

try {
    conn = DBUtil.getConnection();

   
    psCat = conn.prepareStatement(
        "SELECT DISTINCT Category FROM item_master " +
        "WHERE Category IS NOT NULL AND Category<>'' ORDER BY Category");
    rsCat = psCat.executeQuery();

    String sql =
        "SELECT im.Item_id, im.Item_name, im.Category, " +

        // Opening Balance
        "COALESCE(SUM(CASE WHEN sl.trans_type='RECEIPT' AND sl.trans_date < ? THEN sl.qty END),0) - " +
        "COALESCE(SUM(CASE WHEN sl.trans_type='ISSUE' AND sl.trans_date < ? THEN sl.qty END),0) AS opening_balance, " +

        // Receipts
        "COALESCE(SUM(CASE WHEN sl.trans_type='RECEIPT' AND sl.trans_date BETWEEN ? AND ? THEN sl.qty END),0) AS receipts, " +

        // Issues
        "COALESCE(SUM(CASE WHEN sl.trans_type='ISSUE' AND sl.trans_date BETWEEN ? AND ? THEN sl.qty END),0) AS issues " +

        "FROM stock_ledger sl " +
        "JOIN item_master im ON sl.item_id = im.Item_id ";

    if (category != null && !category.equals("ALL")) {
        sql += "WHERE im.Category=? ";
    }

    sql += "GROUP BY im.Item_id, im.Item_name, im.Category " +
           "ORDER BY im.Category, im.Item_name";

    ps = conn.prepareStatement(sql);

    ps.setString(1, fromDate);
    ps.setString(2, fromDate);
    ps.setString(3, fromDate);
    ps.setString(4, toDate);
    ps.setString(5, fromDate);
    ps.setString(6, toDate);

    if (category != null && !category.equals("ALL")) {
        ps.setString(7, category);
    }

    rs = ps.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
<title>Stock Summary Report</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>

body {
    font-family:'Poppins',sans-serif;
    background:#f4f6f9;
    margin:0;
}
.main-content {
    display:flex;
    justify-content:center;
    padding:20px;
}
.card {
    background:#fff;
    width:100%;
    max-width:1200px;
    border-radius:10px;
    padding:20px;
    box-shadow:0 4px 12px rgba(0,0,0,0.1);
}
h2 {
    text-align:center;
    margin-bottom:20px;
    color:#333;
}
form.filter-form {
    display:flex;
    flex-wrap:wrap;
    gap:15px;
    justify-content:center;
    align-items:flex-end;
    margin-bottom:20px;
}
.form-group {
    display:flex;
    flex-direction:column;
}
.form-group label {
    font-weight:600;
    margin-bottom:4px;
}
input, select, button {
    padding:8px 10px;
    border-radius:6px;
    border:1px solid #ccc;
    min-width:150px;
}
button {
    border:none;
    font-weight:600;
    cursor:pointer;
}
button.btn-primary { background:#007bff; color:#fff; }
button.btn-primary:hover { background:#0056b3; }
button.btn-success { background:#28a745; color:#fff; }
button.btn-success:hover { background:#218838; }
.buttons { display:flex; gap:10px; }

.table-container { overflow-x:auto; }
.main-table { width:100%; border-collapse:collapse; margin-top:10px; }
.main-table th {
    background:#007bff; color:#fff; padding:10px; position:sticky; top:0;
}
.main-table td {
    padding:10px; text-align:center; border-bottom:1px solid #ddd;
}
.main-table tr:hover { background:#f1f3f6; }


@media(max-width:768px){
    .filter-form{ flex-direction:column; align-items:stretch; }
    .buttons{ justify-content:center; }
}
</style>
</head>

<body>
<jsp:include page="header.jsp" />

<div class="main-content">
<div class="card">
<h2>📊 Stock Summary Report (Between Dates)</h2>

<form method="get" class="filter-form">
    <div class="form-group">
        <label>From</label>
        <input type="date" name="fromDate" value="<%=fromDate%>">
    </div>
    <div class="form-group">
        <label>To</label>
        <input type="date" name="toDate" value="<%=toDate%>">
    </div>
    <div class="form-group">
        <label>Category</label>
        <select name="category">
            <option value="ALL">All Categories</option>
            <% while(rsCat.next()){ String c=rsCat.getString(1); %>
                <option value="<%=c%>" <%=c.equals(category)?"selected":""%>><%=c%></option>
            <% } %>
        </select>
    </div>
    <div class="form-group buttons">
        <button type="submit" class="btn-primary"><i class="fa fa-search"></i> View</button>
        <button type="submit" name="export" value="excel" class="btn-success"><i class="fa fa-file-excel"></i> Export</button>
    </div>
</form>

<div class="table-container">
<table class="main-table">
<thead>
<tr>
<th>Category</th>
<th>Item ID</th>
<th>Item Name</th>
<th>Opening Balance</th>
<th>Receipts</th>
<th>Issues</th>
<th>Closing Balance</th>
</tr>
</thead>
<tbody>

<%
boolean hasData=false;
while(rs.next()){
    hasData=true;
    double opening=rs.getDouble("opening_balance");
    double rec=rs.getDouble("receipts");
    double iss=rs.getDouble("issues");
    double closing=opening+rec-iss;
%>
<tr>
<td><%=rs.getString("Category")%></td>
<td><%=rs.getInt("Item_id")%></td>
<td><%=rs.getString("Item_name")%></td>
<td><%=opening%></td>
<td><%=rec%></td>
<td><%=iss%></td>
<td><b><%=closing%></b></td>
</tr>
<% } if(!hasData){ %>
<tr><td colspan="7" style="text-align:center;">No records found</td></tr>
<% } %>

</tbody>
</table>
</div>
</div>
</div>

<jsp:include page="Footer.jsp" />
</body>
</html>

<%
} catch(Exception e){
    out.println("<p style='color:red;text-align:center;'>"+e.getMessage()+"</p>");
} finally{
    if(rs!=null) rs.close();
    if(ps!=null) ps.close();
    if(rsCat!=null) rsCat.close();
    if(psCat!=null) psCat.close();
    if(conn!=null) conn.close();
}
%>
