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
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Indent Dashboard</title>
<style>
    * { box-sizing: border-box; }
    body { font-family: 'Segoe UI', sans-serif; background-color: #f6f8fb; margin: 0; }

    h1, h3 { color: #003366; text-align: center; }
    
    .container {
        max-width: 100%;
        margin: 40px auto;
        padding: 20px;
        margin-left: 250px; /* adjust for sidebar */
        transition: all 0.3s ease;
        text-align: center;
    }

    @media (max-width: 992px) { .container { margin-left: 200px; } }
    @media (max-width: 768px) { .container { margin-left: 0; padding: 10px; } }

    /* ✅ Dashboard Row — all boxes in one line */
    .dashboard-row {
        display: flex;
        justify-content: center;
        align-items: stretch;
        gap: 25px;
        flex-wrap: nowrap;
        overflow-x: auto;
        padding-bottom: 10px;
        text-align: left;
    }

    /* Summary Cards */
    .summary-card { 
        background: white;
        border-radius: 10px;
        padding: 20px;
        width: 280px;
        text-align: center;
        box-shadow: 0 3px 10px rgba(0,0,0,0.1);
        transition: transform 0.2s ease;
        flex-shrink: 0;
    }
    
    .summary-card:hover { transform: translateY(-5px); }
    .summary-card h3 { color: #004085; margin-bottom: 8px; }
    .summary-card h2 { color: #007bff; font-size: 28px; margin: 5px 0; }

    /* ✅ Highlighted First Summary Card */
    .summary-card:first-child {
        background: linear-gradient(135deg, #ff8c00, #8e2de2);
        color: white;
        box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        border: none;
        position: relative;
        overflow: hidden;
    }

    .summary-card:first-child::before {
        content: "";
        position: absolute;
        top: -50%;
        left: -50%;
        width: 200%;
        height: 200%;
        background: radial-gradient(circle at center, rgba(255,255,255,0.25), transparent 70%);
        transform: rotate(25deg);
        opacity: 0;
        transition: opacity 0.5s ease;
    }

    .summary-card:first-child:hover::before { opacity: 1; }
    .summary-card:first-child h3, .summary-card:first-child h2 { color: #fff; }

    /* Combined Table Card */
    .table-box {
        background: white;
        border-radius: 10px;
        box-shadow: 0 3px 10px rgba(0,0,0,0.08);
        padding: 15px;
        width: 350px;
        flex-shrink: 0;
    }

    table { width: 100%; border-collapse: collapse; font-size: 14px; min-width: 250px; }
    th, td { padding: 10px; border-bottom: 1px solid #ddd; text-align: center; }
    th { background: linear-gradient(135deg, #ff8c00, #8e2de2); color: white; }
    tr:hover { background-color: #f1f7ff; }

    /* ✅ Stages Section aligned in same row */
    .stages {
        background: white;
        border-radius: 10px;
        box-shadow: 0 3px 10px rgba(0,0,0,0.08);
        padding: 20px;
        text-align: center;
        width: 600px;
        flex-shrink: 0;
    }

    .stage-title {
        color: #003366;
        text-align: center;
        margin-bottom: 20px;
        font-weight: 600;
        font-size: 20px;
    }

    .stage-cards {
        display: flex;
        justify-content: center;
        align-items: stretch;
        gap: 20px;
        flex-wrap: wrap;
    }

    .stage-card {
        flex: 0 0 160px;
        border-radius: 12px;
        text-align: center;
        padding: 18px;
        background: linear-gradient(145deg, #ffffff, #f0f3f8);
        box-shadow: 0 3px 6px rgba(0,0,0,0.1);
        transition: transform 0.2s ease, box-shadow 0.2s ease;
        white-space: normal;
        min-height: 120px;
    }

    .stage-card:hover { transform: translateY(-6px); box-shadow: 0 6px 14px rgba(0,0,0,0.15); }

    .stage-card h4 { margin: 5px 0; font-size: 15px; color: #003366; font-weight: 600; }
    .stage-card h2 { font-size: 28px; margin: 0; font-weight: bold; color: #004085; }

    /* Stage Color Themes with Gradient */
    .approval-pending { background: linear-gradient(135deg, #fff4cc, #ffe082); border-left: 6px solid #ffc107; }
    .po { background: linear-gradient(135deg, #d6e4ff, #aecbfa); border-left: 6px solid #007bff; }
    .issue-pending { background: linear-gradient(135deg, #d7f9db, #b2f2bb); border-left: 6px solid #28a745; }
    .issued { background: linear-gradient(135deg, #d9f3f9, #b8e3f5); border-left: 6px solid #17a2b8; }
    .management-note { background: linear-gradient(135deg, #edd7ff, #d9b8ff); border-left: 6px solid #6f42c1; }

    footer { text-align: center; color: #666; padding: 20px; font-size: 13px; }
</style>
</head>
<body>
<%@ include file="header.jsp" %>

<div class="container">
    <br>
    <br>

    <!-- ✅ All boxes aligned in single row -->
    <div class="dashboard-row">

        <!-- ✅ Summary Card -->
        <div class="summary-card">
            <h3>Pending Indents</h3><br>
            <h3>Pending at In-charge</h3>
            <h2><%= request.getAttribute("istatusPending") %></h2><br>
            <h3>Pending at Secretary</h3>
            <h2><%= request.getAttribute("statusPending") %></h2>
        </div>

        <!-- ✅ Indents by Department -->
        <div class="table-box">
            <h3>Indents by Department</h3>
            <table>
                <thead>
                    <tr>
                        <th>Department</th>
                        <th>Total</th>
                        <th>Pending</th>
                        <th>Approved</th>
                    </tr>
                </thead>
                <%
                    Map<String, Integer> totalDeptMap = (Map<String, Integer>) request.getAttribute("totalDeptMap");
                    Map<String, Integer> deptPendingMap = (Map<String, Integer>) request.getAttribute("deptPendingMap");
                    if (totalDeptMap != null && !totalDeptMap.isEmpty()) {
                        for (Map.Entry<String, Integer> entry : totalDeptMap.entrySet()) {
                            String deptName = entry.getKey();
                            int total = entry.getValue();
                            int pending = deptPendingMap != null ? deptPendingMap.getOrDefault(deptName, 0) : 0;
                            int approved = total - pending;
                %>
                <tr>
                    <td><%= deptName %></td>
                    <td><%= total %></td>
                    <td><%= pending %></td>
                    <td><%= approved %></td>
                </tr>
                <%   }
                    } else { %>
                <tr><td colspan="4">No Indents Found</td></tr>
                <% } %>
            </table>
        </div>

        <!-- ✅ Stages Section -->
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

    </div>

    <footer>© <%= java.time.Year.now() %> Inventory Management Dashboard</footer>
</div>
</body>
</html>
