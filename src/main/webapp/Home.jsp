<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<!DOCTYPE html>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String user  = (String) sess.getAttribute("username");
    String role  = (String) sess.getAttribute("role");
    String dept  = (String) sess.getAttribute("department");
%>
<html>
<head>
<meta charset="UTF-8">
<title>Indent Dashboard</title>
<style>
    body {
        font-family: 'Segoe UI', sans-serif;
        background-color: #f6f8fb;
        margin: 0;
    }

    .container {
        max-width: 1800px;
        margin: 40px auto;
        padding: 20px;
    }

    h1 {
        color: #003366;
        text-align: center;
        margin-bottom: 30px;
    }

    /* Summary Cards */
    .summary {
        display: flex;
        justify-content: center;
        gap: 25px;
        flex-wrap: wrap;
        margin-bottom: 40px;
    }

    .summary-card, .summary-card2 {
        background: white;
        border-radius: 10px;
        padding: 20px;
        width: 320px;
        text-align: center;
        box-shadow: 0 3px 10px rgba(0,0,0,0.1);
    }

    .summary-card h3, .summary-card2 h3 {
        color: #004085;
        margin-bottom: 8px;
    }

    .summary-card h2, .summary-card2 h2 {
        color: #007bff;
        font-size: 30px;
        margin: 0;
    }

    /* Table Section */
    .table-box {
        background: white;
        border-radius: 10px;
        box-shadow: 0 3px 10px rgba(0,0,0,0.08);
        padding: 15px;
    }

    .table-box h3 {
        color: #003366;
        margin-bottom: 10px;
    }

    table {
        width: 100%;
        border-collapse: collapse;
        font-size: 15px;
    }

    th, td {
        padding: 10px;
        border-bottom: 1px solid #ddd;
        text-align: center;
    }

    th {
        background: blue;
        color: white;
    }

    tr:hover {
        background-color: #f1f7ff;
    }

    /* Stages Section */
    .stages {
        background: white;
        border-radius: 10px;
        box-shadow: 0 3px 10px rgba(0,0,0,0.08);
        padding: 20px;
    }

    .stage-title {
        color: #003366;
        text-align: center;
        margin-bottom: 20px;
    }

    .stage-cards {
        display: flex;
        flex-wrap: wrap;
        justify-content: space-evenly;
        gap: 25px;
        padding: 0 20px;
    }

    .stage-card {
        flex: 1 1 200px;
        max-width: 250px;
        min-width: 160px;
        border-radius: 10px;
        text-align: center;
        padding: 15px;
        box-shadow: 0 3px 6px rgba(0,0,0,0.1);
        transition: transform 0.2s ease, box-shadow 0.2s ease;
    }

    .stage-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 6px 12px rgba(0,0,0,0.15);
    }

    .stage-card h4 {
        margin: 5px 0;
        font-size: 17px;
        color: #003366;
    }

    .stage-card h2 {
        font-size: 28px;
        margin: 0;
        font-weight: bold;
        color: #004085;
    }

    /* Stage colors */
    .approval-pending { background: #fff8e1; border-left: 6px solid #ffc107; }
    .po { background: #e7f1ff; border-left: 6px solid #007bff; }
    .issue-pending { background: #eafbea; border-left: 6px solid #28a745; }
    .issued { background: #e8f4f8; border-left: 6px solid #17a2b8; }
    .management-note { background: #f5e6ff; border-left: 6px solid #6f42c1; }

    footer {
        text-align: center;
        color: #666;
        padding: 20px;
        font-size: 13px;
    }
</style>
</head>
<body>
<%@ include file="header.jsp" %>

<div class="container">
    <br><br>
    <div class="summary">

        <!-- 🔹 Pending Summary -->
        <div class="summary-card">
        <h3>Pending Indents</h3>
            <br><br>
            <h3>Pending at In-charge</h3>
            <h2><%= request.getAttribute("istatusPending") %></h2>
            <br>
            <h3>Pending at Secretary</h3>
            <h2><%= request.getAttribute("statusPending") %></h2>
        </div>

        <!-- 🔹 Total Indents by Department -->
        

        <!-- 🔹 Pending by Department -->
        <div class="summary-card2">
            <div class="table-box">
                <h3>Pending by Department</h3>
                <table>
                    <tr>
                        <th>Department</th>
                        <th>Pending</th>
                    </tr>
                    <%
                        Map<String, Integer> deptPendingMap = (Map<String, Integer>) request.getAttribute("deptPendingMap");
                        if (deptPendingMap != null && !deptPendingMap.isEmpty()) {
                            for (Map.Entry<String, Integer> entry : deptPendingMap.entrySet()) {
                    %>
                    <tr>
                        <td><%= entry.getKey() %></td>
                        <td><%= entry.getValue() %></td>
                    </tr>
                    <%  }
                        } else { %>
                    <tr><td colspan="2">No Pending Found</td></tr>
                    <% } %>
                </table>
            </div>
        </div>
        <div class="summary-card">
        <h3>Total Indents by Department</h3>
            <div class="table-box">
                
                <table>
                    <tr>
                        <th>Department</th>
                        <th>Total</th>
                    </tr>
                    <%
                        Map<String, Integer> totalDeptMap = (Map<String, Integer>) request.getAttribute("totalDeptMap");
                        if (totalDeptMap != null && !totalDeptMap.isEmpty()) {
                            for (Map.Entry<String, Integer> entry : totalDeptMap.entrySet()) {
                    %>
                    <tr>
                        <td><%= entry.getKey() %></td>
                        <td><%= entry.getValue() %></td>
                    </tr>
                    <%  }
                        } else { %>
                    <tr><td colspan="2">No Indents Found</td></tr>
                    <% } %>
                </table>
            </div>
        </div>
    </div>

    <!-- 🔹 Stages Section -->
    <div class="stages">
        <h3 class="stage-title">Indents / Issues by Stage</h3>
        <div class="stage-cards">
            <%
                Map<String, Integer> nextStageCountMap = (Map<String, Integer>) request.getAttribute("nextStageCountMap");
                if (nextStageCountMap != null) {
                    String[][] stages = {
                        {"Approval-Pending", "approval-pending"},
                        {"PO", "po"},
                        {"Issue Pending", "issue-pending"},
                        {"Issued", "issued"},
                        {"Management Note", "management-note"}
                    };
                    for (String[] s : stages) {
                        int count = nextStageCountMap.getOrDefault(s[0], 0);
                        String cssClass = s[1];
            %>
            <div class="stage-card <%= cssClass %>">
                <h4><%= s[0] %></h4>
                <h2><%= count %></h2>
            </div>
            <%  }
                }
            %>
        </div>
    </div>

    <footer>© <%= java.time.Year.now() %> Inventory Management Dashboard</footer>
</div>
</body>
</html>
