<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<!DOCTYPE html>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Indent Dashboard</title>
<style>
    *{box-sizing:border-box;}
    body{font-family:'Segoe UI',sans-serif;background:#f6f8fb;margin:0;}
    h1,h3{text-align:center;color:#003366;}
    .container{margin:40px auto;padding:20px;margin-left:250px;transition:.3s;}
    @media(max-width:992px){.container{margin-left:200px;}}
    @media(max-width:768px){.container{margin-left:0;padding:10px;}}

    .dashboard-row{display:flex;justify-content:center;align-items:stretch;gap:25px;flex-wrap:nowrap;overflow-x:auto;padding-bottom:10px;}
    .summary-card{background:white;border-radius:10px;padding:20px;width:280px;text-align:center;
        box-shadow:0 3px 10px rgba(0,0,0,0.1);transition:transform .2s ease;flex-shrink:0;}
    .summary-card:hover{transform:translateY(-5px);}
    .summary-card h3{color:#004085;margin-bottom:8px;}
    .summary-card h2{color:#007bff;font-size:26px;margin:5px 0;}
    .summary-card:first-child{background:linear-gradient(135deg,#ff8c00,#8e2de2);color:#fff;box-shadow:0 4px 15px rgba(0,0,0,0.2);}
    .summary-card:first-child h3,.summary-card:first-child h2{color:#fff;}

    .table-box{background:white;border-radius:10px;box-shadow:0 3px 10px rgba(0,0,0,0.08);padding:15px;width:450px;flex-shrink:0;}
    table{width:100%;border-collapse:collapse;font-size:14px;}
    th,td{padding:8px;border-bottom:1px solid #ddd;text-align:center;}
    th{background:linear-gradient(135deg,#ff8c00,#8e2de2);color:white;}
    tr:hover{background:#f1f7ff;}

    .stages{background:white;border-radius:10px;box-shadow:0 3px 10px rgba(0,0,0,0.08);padding:20px;text-align:center;width:600px;flex-shrink:0;}
    .stage-title{color:#003366;font-size:20px;margin-bottom:20px;}
    .stage-cards{display:flex;justify-content:center;gap:20px;flex-wrap:wrap;}
    .stage-card{flex:0 0 160px;border-radius:12px;text-align:center;padding:18px;
        background:linear-gradient(145deg,#ffffff,#f0f3f8);box-shadow:0 3px 6px rgba(0,0,0,0.1);
        transition:transform .2s,box-shadow .2s;min-height:120px;}
    .stage-card:hover{transform:translateY(-6px);box-shadow:0 6px 14px rgba(0,0,0,0.15);}
    .stage-card h4{margin:5px 0;font-size:15px;color:#003366;font-weight:600;}
    .stage-card h2{font-size:28px;margin:0;color:#004085;font-weight:bold;}
    .approval-pending{background:linear-gradient(135deg,#fff4cc,#ffe082);border-left:6px solid #ffc107;}
    .po{background:linear-gradient(135deg,#d6e4ff,#aecbfa);border-left:6px solid #007bff;}
    .issue-pending{background:linear-gradient(135deg,#d7f9db,#b2f2bb);border-left:6px solid #28a745;}
    .issued{background:linear-gradient(135deg,#d9f3f9,#b8e3f5);border-left:6px solid #17a2b8;}
    .management-note{background:linear-gradient(135deg,#edd7ff,#d9b8ff);border-left:6px solid #6f42c1;}

    .dual-tables{display:flex;flex-wrap:wrap;justify-content:center;gap:25px;margin-top:25px;}
    footer{text-align:center;color:#666;padding:20px;font-size:13px;}
</style>
</head>
<body>
<%@ include file="header.jsp" %>
<div class="container">
    <h1>Inventory Dashboard</h1>

    <!-- Top summary -->
    <div class="dashboard-row">
     

        <!-- Department Table -->
        <div class="table-box">
            <h3>Indents by Department</h3>
            <table>
                <thead><tr><th>Department</th><th>Total</th><th>Pending</th><th>Approved</th></tr></thead>
                <tbody>
                <%
                    Map<String,Integer> totalDeptMap=(Map<String,Integer>)request.getAttribute("totalDeptMap");
                    Map<String,Integer> deptPendingMap=(Map<String,Integer>)request.getAttribute("deptPendingMap");
                    if(totalDeptMap!=null && !totalDeptMap.isEmpty()){
                        for(Map.Entry<String,Integer> e:totalDeptMap.entrySet()){
                            String deptName=e.getKey();
                            int total=e.getValue();
                            int pending=deptPendingMap!=null?deptPendingMap.getOrDefault(deptName,0):0;
                            int approved=total-pending;
                %>
                    <tr><td><%=deptName%></td><td><%=total%></td><td><%=pending%></td><td><%=approved%></td></tr>
                <% }}else{ %>
                    <tr><td colspan="4">No Indents Found</td></tr>
                <% } %>
                </tbody>
            </table>
        </div>

        <!-- Stage Summary -->
        <div class="stages">
            <h3 class="stage-title">Indents / Issues by Stage</h3>
            <div class="stage-cards">
                <%
                    Map<String,Integer> nextStageCountMap=(Map<String,Integer>)request.getAttribute("nextStageCountMap");
                    if(nextStageCountMap!=null){
                        String[][] stages={{"Approval-Pending","approval-pending"},{"PO","po"},
                                           {"Issue Pending","issue-pending"},{"Issued","issued"},
                                           {"Management Note","management-note"}};
                        for(String[] s:stages){
                            int count=nextStageCountMap.getOrDefault(s[0],0);
                %>
                <div class="stage-card <%=s[1]%>"><h4><%=s[0]%></h4><h2><%=count%></h2></div>
                <% }} %>
            </div>
        </div>
    </div>

    <!-- ✅ Top 5 Lists -->
    <div class="dual-tables">
        <div class="table-box">
            <h3>Top 5 Costliest Items</h3>
            <table>
                <thead><tr><th>Item</th><th>Category</th><th>Last Price (₹)</th></tr></thead>
                <tbody>
                <%
                    List<Map<String,Object>> topCostliest=(List<Map<String,Object>>)request.getAttribute("topCostliest");
                    if(topCostliest!=null && !topCostliest.isEmpty()){
                        for(Map<String,Object> row:topCostliest){
                %>
                    <tr>
                        <td><%=row.get("Item_name")%></td>
                        <td><%=row.get("Category")%></td>
                        <td><%=row.get("last_price")%></td>
                    </tr>
                <% }}else{ %>
                    <tr><td colspan="3">No Data Found</td></tr>
                <% } %>
                </tbody>
            </table>
        </div>

        <div class="table-box">
            <h3>Top 5 Highest Quantity Items</h3>
            <table>
                <thead><tr><th>Item</th><th>Category</th><th>Qty</th></tr></thead>
                <tbody>
                <%
                    List<Map<String,Object>> topQty=(List<Map<String,Object>>)request.getAttribute("topQty");
                    if(topQty!=null && !topQty.isEmpty()){
                        for(Map<String,Object> row:topQty){
                %>
                    <tr>
                        <td><%=row.get("Item_name")%></td>
                        <td><%=row.get("Category")%></td>
                        <td><%=row.get("balance_qty")%></td>
                    </tr>
                <% }}else{ %>
                    <tr><td colspan="3">No Data Found</td></tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>

    <footer>© <%=java.time.Year.now()%> Inventory Management Dashboard</footer>
</div>
</body>
</html>
