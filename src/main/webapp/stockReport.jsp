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

String subCategory = request.getParameter("subCategory");
String export = request.getParameter("export");


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

    // Category List
    psCat = conn.prepareStatement(
        "SELECT DISTINCT Category FROM item_master " +
        "WHERE Category IS NOT NULL AND Category<>'' " +
        "ORDER BY Category"
    );

    rsCat = psCat.executeQuery();

    subCategory = request.getParameter("subCategory");

 // Main Query
 String sql =
     "SELECT " +
     "im.Item_id, " +
     "im.Item_name, " +
     "im.Category, " +
     "im.Sub_Category, " +

     /* Opening Balance */
     "COALESCE(( " +
     "   SELECT SUM(CASE " +
     "       WHEN sl.trans_type='RECEIPT' THEN sl.qty " +
     "       WHEN sl.trans_type='ISSUE' THEN -sl.qty " +
     "       ELSE 0 END) " +
     "   FROM stock_ledger sl " +
     "   WHERE sl.item_id = im.Item_id " +
     "   AND sl.trans_date < ? " +
     "),0) AS opening_balance, " +

     /* Receipts */
     "COALESCE(( " +
     "   SELECT SUM(sl.qty) " +
     "   FROM stock_ledger sl " +
     "   WHERE sl.item_id = im.Item_id " +
     "   AND sl.trans_type='RECEIPT' " +
     "   AND sl.trans_date BETWEEN ? AND ? " +
     "),0) AS receipts, " +

     /* Issues */
     "COALESCE(( " +
     "   SELECT SUM(sl.qty) " +
     "   FROM stock_ledger sl " +
     "   WHERE sl.item_id = im.Item_id " +
     "   AND sl.trans_type='ISSUE' " +
     "   AND sl.trans_date BETWEEN ? AND ? " +
     "),0) AS issues " +

     "FROM item_master im ";

 boolean hasWhere = false;

 if (category != null && !category.equals("ALL")) {
     sql += "WHERE im.Category = ? ";
     hasWhere = true;
 }

 if (subCategory != null && !subCategory.equals("ALL")) {
     sql += hasWhere
             ? "AND im.Sub_Category = ? "
             : "WHERE im.Sub_Category = ? ";
 }

 sql += "ORDER BY im.Category, im.Sub_Category, im.Item_name";

 ps = conn.prepareStatement(sql);

 // Date Parameters
 ps.setString(1, fromDate);

 ps.setString(2, fromDate);
 ps.setString(3, toDate);

 ps.setString(4, fromDate);
 ps.setString(5, toDate);

 // Filter Parameters
 int paramIndex = 6;

 if (category != null && !category.equals("ALL")) {
     ps.setString(paramIndex++, category);
 }

 if (subCategory != null && !subCategory.equals("ALL")) {
     ps.setString(paramIndex++, subCategory);
 }

 rs = ps.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>

<title>Stock Summary Report</title>

<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
* { box-sizing: border-box; }
body{
    font-family:'Poppins',sans-serif;
    background:#f3f3f3;
    margin:0;
    color: #181818;
    -webkit-tap-highlight-color: transparent;
}

.main-content{
    width:100%;
    max-width:1440px;
    margin: 0 auto;
    padding:16px;
}

/* Salesforce Style Card Base */
.card{
    background:#fff;
    width:100%;
    border-radius:4px;
    padding:24px;
    border: 1px solid #c9c9c9;
    box-shadow:0 2px 2px 0 rgba(0,0,0,0.1);
}

.header-area {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 20px;
    border-bottom: 1px solid #e5e5e5;
    padding-bottom: 16px;
}

.icon-box {
    width: 40px;
    height: 40px;
    border-radius: 4px;
    background: #0176d3;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 18px;
}

h2{
    margin: 0;
    font-size: 20px;
    color: #0176d3;
    font-weight: 700;
}

/* Salesforce Filter Toolbar */
.filter-form{
    background: #fafaf9;
    border: 1px solid #c9c9c9;
    border-radius: 4px;
    padding: 16px;
    margin-bottom: 20px;
    display: flex;
    flex-wrap: wrap;
    gap: 14px;
    align-items: flex-end;
}

.form-group{
    display:flex;
    flex-direction:column;
    gap: 4px;
}

.form-group label{
    font-size: 12px;
    font-weight: 700;
    color: #514f4d;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    white-space: nowrap;
}

input, select, button {
    height: 36px;
    padding: 0 12px;
    border: 1px solid #aeaeae;
    border-radius: 4px;
    font-family: inherit;
    font-size: 13px;
    background: #ffffff;
    outline: none;
    min-width: 180px;
}

input:focus, select:focus {
    border-color: #0176d3;
    box-shadow: 0 0 0 2px rgba(1,118,211,0.15);
}

.buttons{
    display:flex;
    gap:8px;
    margin-left: auto;
}

/* Salesforce Lightning Action Buttons */
button{
    border: none;
    cursor: pointer;
    font-size: 13px;
    font-weight: 600;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    transition: all 0.1s ease;
    min-width: unset;
}

.btn-primary{
    background:#0176d3;
    color:#fff;
    border: 1px solid #0176d3;
}

.btn-primary:hover{
    background:#015a9e;
    border-color: #015a9e;
}

.btn-success{
    background:#2e844a;
    color:#fff;
    border: 1px solid #2e844a;
}

.btn-success:hover{
    background:#1b5e30;
    border-color: #1b5e30;
}

/* Data Presentation Layout */
.table-container{
    width: 100%;
    overflow-x:auto;
    border: 1px solid #c9c9c9;
    border-radius: 4px;
}

.main-table{
    width:100%;
    border-collapse:collapse;
    min-width: 950px;
    background: #fff;
    font-size: 13px;
}

.main-table th{
    background:#fafaf9;
    color:#514f4d;
    padding: 12px 10px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-bottom: 2px solid #c9c9c9;
    font-size: 11px;
    position:sticky;
    top:0;
}

.main-table td{
    padding:10px;
    text-align:right; /* Alignment for uniform metric alignment */
    border-bottom:1px solid #e5e5e5;
    color: #181818;
}

/* Text elements layout overriding rule */
.main-table td.txt-align-left, .main-table th.txt-align-left {
    text-align: left;
}

.main-table tr:hover{
    background:#f3f3f3;
}

.balance{
    font-weight:700;
    color:#0176d3;
}

/* Responsive Architecture */
@media(max-width:768px){
    .main-content { padding: 10px; }
    .card { padding: 16px; }
    
    .header-area { margin-bottom: 16px; padding-bottom: 12px; }

    .filter-form{
        flex-direction:column;
        align-items:stretch;
        gap: 12px;
        padding: 12px;
    }

    .form-group input, 
    .form-group select {
        width: 100%;
        height: 40px;
    }

    .buttons{
        width: 100%;
        flex-direction:column;
        margin-left: 0;
        gap: 8px;
    }
    
    .buttons button {
        width: 100%;
        height: 40px;
    }

    .table-container {
        border: none;
    }

    table, thead, tbody, th, td, tr {
        display: block;
        width: 100%;
    }

    thead tr {
        display: none;
    }

    tr {
        margin-bottom: 12px;
        border: 1px solid #c9c9c9;
        border-radius: 4px;
        box-shadow: 0 1px 2px rgba(0,0,0,0.05);
        padding: 8px 0;
        background: #fff;
    }

    .main-table td{
        text-align: right;
        padding: 8px 14px;
        position: relative;
        border: none;
        border-bottom: 1px solid #f3f3f3;
        font-size: 13px;
    }
    
    .main-table td:last-child {
        border-bottom: none;
    }

    .main-table td:before {
        content: attr(data-label);
        position: absolute;
        left: 14px;
        width: 45%;
        font-weight: 700;
        text-align: left;
        color: #514f4d;
        white-space: nowrap;
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
    
    .main-table td.txt-align-left {
        text-align: right;
    }
}

</style>

</head>

<body>

<%-- Only include the markup header if not downloading Excel sheet logs --%>
<% if (!"excel".equals(export)) { %>
<jsp:include page="header.jsp" />
<% } %>

<div class="main-content">

<div class="card">

<div class="header-area">
    <div class="icon-box"><i class="fa fa-chart-bar"></i></div>
    <h2>Stock Summary Reports</h2>
</div>

<form method="get" class="filter-form">

    <div class="form-group">
        <label>From Date</label>
        <input type="date" name="fromDate" value="<%=fromDate%>">
    </div>

    <div class="form-group">
        <label>To Date</label>
        <input type="date" name="toDate" value="<%=toDate%>">
    </div>

    <div class="form-group">
        <label>Category</label>

        <select name="category">

            <option value="ALL">All Categories</option>

            <%
            while(rsCat.next()){

                String c = rsCat.getString("Category");
            %>

            <option value="<%=c%>"
                <%=c.equals(category) ? "selected" : ""%>>
                <%=c%>
            </option>

            <% } %>

        </select>
    </div>




    <div class="form-group buttons">

        <button type="submit" class="btn-primary">
            <i class="fa fa-search"></i> View
        </button>

        <button type="submit"
                name="export"
                value="excel"
                class="btn-success">

            <i class="fa fa-file-excel"></i> Export

        </button>

    </div>

</form>

<div class="table-container">

<table class="main-table">

<thead>

<tr>
    <th class="txt-align-left">Category</th>
     <th class="txt-align-left">Sub Category</th>
    <th style="text-align: right;">Item ID</th>
    <th class="txt-align-left">Item Name</th>
    <th style="text-align: right;">Opening Balance</th>
    <th style="text-align: right;">Receipts</th>
    <th style="text-align: right;">Issues</th>
    <th style="text-align: right;">Closing Balance</th>
</tr>

</thead>

<tbody>

<%

boolean hasData = false;

while(rs.next()){

    hasData = true;

    double opening = rs.getDouble("opening_balance");
    double receipts = rs.getDouble("receipts");
    double issues = rs.getDouble("issues");
    double closing = opening + receipts - issues;

%>

<tr>

    <td data-label="Category" class="txt-align-left"><%=rs.getString("Category")%></td>
    <td data-label="Sub Category" class="txt-align-left">
    <%=rs.getString("Sub_Category")%>
</td>

    <td data-label="Item ID"><%=rs.getInt("Item_id")%></td>

    <td data-label="Item Name" class="txt-align-left">
        <%=rs.getString("Item_name")%>
    </td>

    <td data-label="Opening Balance">
<%= opening < 0
        ? "(" + String.format("%.2f", Math.abs(opening)) + ")"
        : String.format("%.2f", opening)
%>
</td>

    <td data-label="Receipts"><%=String.format("%.2f", receipts)%></td>

    <td data-label="Issues"><%=String.format("%.2f", issues)%></td>

    <td data-label="Closing Balance" class="balance">
        <%=String.format("%.2f", closing)%>
    </td>

</tr>

<%
}

if(!hasData){
%>

<tr>
    <td colspan="7" style="text-align:center; color:#c23934; font-weight: 600;">
        No Records Found
    </td>
</tr>

<%
}
%>

</tbody>

</table>

</div>

</div>

</div>

<%-- Only include the layout footer structure if not downloading Excel sheet logs --%>
<% if (!"excel".equals(export)) { %>
<jsp:include page="Footer.jsp" />
<% } %>

</body>
</html>

<%

}catch(Exception e){

    out.println(
        "<h3 style='color:#c23934;text-align:center;margin-top:20px;'>"+
        e.getMessage()+
        "</h3>"
    );

}finally{

    if(rs != null) rs.close();

    if(ps != null) ps.close();

    if(rsCat != null) rsCat.close();

    if(psCat != null) psCat.close();

    if(conn != null) conn.close();
}
%>