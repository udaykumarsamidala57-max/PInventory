<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String user = (String) sess.getAttribute("username");
    
    Map<String,Integer> deptPendingMap = (Map<String,Integer>)request.getAttribute("deptPendingMap");
    Map<String,Integer> totalDeptMap = (Map<String,Integer>)request.getAttribute("totalDeptMap");
    Map<String,Integer> nextStageCountMap = (Map<String,Integer>)request.getAttribute("nextStageCountMap");
    List<String> departments = (List<String>)request.getAttribute("departments");
    List<String> years = (List<String>)request.getAttribute("years");
    Map<String,double[]> dataMap = (Map<String,double[]>)request.getAttribute("dataMap");
    String[] monthNames = (String[])request.getAttribute("monthNames");
    String selectedDept = (String)request.getAttribute("selectedDept");
    String selectedYear = (String)request.getAttribute("selectedYear");
    double grandTotal = (Double)request.getAttribute("grandTotal");
    int totalRows = (Integer)request.getAttribute("totalRows");

    Calendar cal = Calendar.getInstance();
    int hour = cal.get(Calendar.HOUR_OF_DAY);
    String greeting;
    String greetingIcon;
    if (hour < 12) {
        greeting = "Good Morning";
        greetingIcon = "fa-sun"; 
    } else if (hour < 17) {
        greeting = "Good Afternoon";
        greetingIcon = "fa-cloud-sun";
    } else {
        greeting = "Good Evening";
        greetingIcon = "fa-moon"; 
    }
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Inventory Dashboard</title>
<link href="https://fonts.googleapis.com/css2?family=Segoe+UI:wght@300;400;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<style>
    :root {
        --sf-blue-primary: #0176d3;
        --sf-blue-dark: #0b5cab;
        --sf-bg-gray: #f3f5f7;
        --sf-card-bg: #ffffff;
        --sf-border: #dddbda;
        --sf-text-main: #181818;
        --sf-text-muted: #444444;
        --sf-text-light: #696969;
        --sf-success: #2e844a;
        --sf-success-bg: #eaf5ea;
        --sf-error: #ea001e;
        --sf-error-bg: #ffeef0;
        --sf-radius: 0.25rem;
        --sf-shadow-sm: 0 2px 4px rgba(0,0,0,0.05);
        --sf-shadow-md: 0 4px 12px rgba(0,0,0,0.08);
    }

    body {
        font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, sans-serif;
        background: var(--sf-bg-gray);
        margin: 0;
        color: var(--sf-text-main);
        line-height: 1.5;
        -webkit-font-smoothing: antialiased;
    }

    .container {
        width: 96%;
        max-width: 1600px;
        margin: 0 auto;
        padding: 24px 0;
    }

    /* Premium Welcome Banner with Decorative Accent Pattern */
    .welcome-banner {
        background: linear-gradient(135deg, #ffffff 0%, #faffff 100%);
        padding: 20px 28px;
        border-radius: var(--sf-radius);
        border: 1px solid var(--sf-border);
        border-left: 4px solid var(--sf-blue-primary);
        margin-bottom: 24px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        box-shadow: var(--sf-shadow-sm);
    }

    .welcome-text h1 {
        margin: 0;
        font-size: 22px;
        font-weight: 600;
        color: var(--sf-text-main);
        letter-spacing: -0.3px;
    }

    .welcome-text p {
        margin: 4px 0 0 0;
        color: var(--sf-text-light);
        font-size: 13.5px;
    }

    .date-badge {
        font-size: 13px;
        color: var(--sf-text-muted);
        background: #f3f5f7;
        padding: 6px 14px;
        border-radius: 20px;
        display: flex;
        align-items: center;
        gap: 8px;
        font-weight: 600;
        border: 1px solid #e2e0df;
    }

    h1.page-title {
        color: var(--sf-text-main);
        font-weight: 600;
        margin: 32px 0 16px 0;
        font-size: 16px;
        display: flex;
        align-items: center;
        gap: 8px;
    }

    /* Enhanced Card Interface */
    .card {
        background: var(--sf-card-bg);
        border-radius: var(--sf-radius);
        border: 1px solid var(--sf-border);
        box-shadow: var(--sf-shadow-sm);
        margin-bottom: 24px;
        overflow: hidden;
        transition: box-shadow 0.2s ease;
    }
    
    .card:hover {
        box-shadow: var(--sf-shadow-md);
    }

    .card-header {
        padding: 14px 20px;
        border-bottom: 1px solid var(--sf-border);
        background: #fafaf9;
        display: flex;
        align-items: center;
        justify-content: space-between;
    }

    .card-title {
        font-size: 14px;
        font-weight: 600;
        margin: 0;
        color: var(--sf-text-main);
        display: flex;
        align-items: center;
        gap: 10px;
    }

    .card-body {
        padding: 20px;
    }

    .dashboard-grid {
        display: grid;
        grid-template-columns: 1.3fr 0.7fr;
        gap: 24px;
    }

    .table-container { 
        overflow-x: auto; 
    }

    /* Salesforce Clean Compact Tables */
    table { 
        width: 100%; 
        border-collapse: collapse; 
        font-size: 13px; 
    }

    thead { 
        background: #fafaf9; 
    }

    th { 
        color: var(--sf-text-muted); 
        padding: 10px 14px; 
        font-weight: 600; 
        text-align: right;
        border-bottom: 2px solid var(--sf-border);
        text-transform: uppercase;
        font-size: 11px;
        letter-spacing: 0.6px;
    }

    td { 
        padding: 11px 14px; 
        border-bottom: 1px solid var(--sf-border); 
        text-align: right; 
        color: var(--sf-text-main);
    }

    tr:last-child td {
        border-bottom: none;
    }

    tr:hover td {
        background-color: #f9fbfd;
    }

    /* Utility Status Badges */
    .badge-status {
        display: inline-block;
        padding: 2px 8px;
        border-radius: 12px;
        font-size: 11.5px;
        font-weight: 600;
    }
    
    .badge-status.error {
        color: var(--sf-error);
        background: var(--sf-error-bg);
    }

    .badge-status.success {
        color: var(--sf-success);
        background: var(--sf-success-bg);
    }

    /* Interactive Operational Stage Cards */
    .stage-container { 
        display: grid; 
        grid-template-columns: 1fr 1fr; 
        gap: 14px; 
    }

    .stage-card {
        padding: 18px 16px; 
        text-align: left; 
        border-radius: var(--sf-radius);
        background: var(--sf-card-bg); 
        border: 1px solid var(--sf-border);
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative;
    }

    .stage-card:hover {
        border-color: var(--sf-blue-primary);
        transform: translateY(-2px);
        box-shadow: 0 4px 10px rgba(1, 118, 211, 0.08);
    }

    .stage-card h4 { 
        font-size: 12px; 
        color: var(--sf-text-light); 
        margin: 0 0 10px 0; 
        font-weight: 400;
    }

    .stage-card h2 { 
        font-size: 24px; 
        color: var(--sf-blue-dark); 
        font-weight: 600; 
        margin: 0; 
    }

    .chart-grid { 
        display: grid; 
        grid-template-columns: 1fr 1fr; 
        gap: 24px; 
    }

    .scrollable-chart-area {
        height: 380px;
        overflow-y: auto;
    }

    /* Enhanced Salesforce Controls Bar */
    .filter-panel {
        background: var(--sf-card-bg); 
        padding: 20px; 
        border-radius: var(--sf-radius);
        border: 1px solid var(--sf-border);
        margin: 24px 0; 
        display: flex; 
        justify-content: flex-start; 
        align-items: flex-end;
        gap: 20px; 
        box-shadow: var(--sf-shadow-sm);
    }

    .filter-panel select { 
        padding: 8px 12px; 
        border-radius: var(--sf-radius); 
        border: 1px solid var(--sf-border);
        font-size: 13px;
        color: var(--sf-text-main);
        outline: none;
        min-width: 220px;
        background-color: #fff;
        transition: border-color 0.15s ease;
    }
    
    .filter-panel select:focus {
        border-color: var(--sf-blue-primary);
        box-shadow: 0 0 0 2px rgba(1, 118, 211, 0.15);
    }

    .filter-panel button { 
        background: var(--sf-blue-primary); 
        color: white; 
        padding: 9px 24px; 
        border: 1px solid transparent; 
        border-radius: var(--sf-radius); 
        font-weight: 600; 
        font-size: 13px;
        cursor: pointer; 
        transition: background 0.1s linear, transform 0.1s ease;
    }

    .filter-panel button:hover {
        background: var(--sf-blue-dark);
    }
    
    .filter-panel button:active {
        transform: scale(0.98);
    }

    /* Executive Summary Component */
    .report-summary { 
        display: flex; 
        gap: 20px; 
        margin-bottom: 24px; 
    }

    .summary-item { 
        flex: 1; 
        background: var(--sf-card-bg); 
        padding: 18px 24px; 
        border-radius: var(--sf-radius); 
        text-align: left; 
        border: 1px solid var(--sf-border);
        box-shadow: var(--sf-shadow-sm);
    }

    .summary-item h3 { 
        font-size: 11px; 
        color: var(--sf-text-light); 
        text-transform: uppercase; 
        margin: 0;
        font-weight: 600;
        letter-spacing: 0.8px;
    }

    .summary-item p {
        font-size: 26px;
        font-weight: 300;
        margin: 6px 0 0 0;
        color: var(--sf-text-main);
    }

    footer { 
        text-align: center; 
        padding: 32px; 
        color: var(--sf-text-light); 
        font-size: 12px; 
        border-top: 1px solid var(--sf-border);
        margin-top: 48px;
    }

    @media (max-width: 1100px) {
        .dashboard-grid, .chart-grid { grid-template-columns: 1fr; }
        .filter-panel { flex-direction: column; align-items: stretch; }
    }
</style>
</head>
<body>
<%@ include file="header.jsp" %>

<div class="container">
    
    <!-- Salesforce Intelligence Header Banner -->
    <div class="welcome-banner">
        <div class="welcome-text">
            <h1><%= greeting %>, <%= user.toUpperCase() %>!</h1>
            <p>Inventory Performance Dashboard & Real-Time Analytics Explorer</p>
        </div>
        <div class="date-badge">
            <i class="slate-icon far fa-calendar-alt"></i>
            <%= new java.text.SimpleDateFormat("EEEE, dd MMMM yyyy").format(new java.util.Date()) %>
        </div>
    </div>

    <!-- Layout Framework Grid -->
    <div class="dashboard-grid">
        <div class="card">
            <div class="card-header">
                <h3 class="card-title"><i class="fas fa-layer-group" style="color: #0176d3;"></i> Indents by Department</h3>
            </div>
            <div class="card-body" style="padding:0;">
                <div class="table-container" style="max-height: 298px;">
                    <table style="margin:0;">
                        <thead>
                            <tr>
                                <th style="text-align:left; padding-left: 20px;">Department</th>
                                <th>Total</th>
                                <th>Pending</th>
                                <th>Approved</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            if(totalDeptMap != null){
                                for(Map.Entry<String,Integer> entry : totalDeptMap.entrySet()){
                                    String dName = entry.getKey(); 
                                    int total = entry.getValue();
                                    int pending = deptPendingMap != null ? deptPendingMap.getOrDefault(dName, 0) : 0;
                        %>
                            <tr>
                                <td style="text-align:left; padding-left: 20px; font-weight: 600; color: var(--sf-blue-dark);"><%= dName %></td>
                                <td style="font-weight: 600; color: var(--sf-text-main);"><%= total %></td>
                                <td><span class="badge-status error"><%= pending %></span></td>
                                <td><span class="badge-status success"><%= total - pending %></span></td>
                            </tr>
                        <%      }
                            } 
                        %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <h3 class="card-title"><i class="fas fa-tasks" style="color: #1aa0be;"></i> Stage Summary</h3>
            </div>
            <div class="card-body">
                <div class="stage-container">
                    <%
                        if(nextStageCountMap != null){
                            String[][] list = {{"Approval Pending", "fas fa-user-check"}, {"PO Generation", "fas fa-file-invoice"}, 
                                              {"Issue Pending", "fas fa-box"}, {"Management Note", "fas fa-clipboard-list"}};
                            for(String[] s : list){
                                int count = nextStageCountMap.getOrDefault(s[0], 0);
                    %>
                    <div class="stage-card">
                        <div>
                            <i class="<%= s[1] %>" style="color: var(--sf-text-light); margin-bottom: 8px; font-size:14px;"></i>
                            <h4><%= s[0] %></h4>
                        </div>
                        <h2><%= count %></h2>
                    </div>
                    <%      }
                        } 
                    %>
                </div>
            </div>
        </div>
    </div>

    <!-- Graphical Matrix Viewports -->
    <div class="chart-grid">
        <div class="card">
            <div class="card-header">
                <h3 class="card-title"><i class="fas fa-chart-bar" style="color: #ff9d3b;"></i> Departmental Consumption (₹)</h3>
            </div>
            <div class="card-body">
                <div class="scrollable-chart-area">
                    <div id="deptChartWrapper">
                        <canvas id="deptChart"></canvas>
                    </div>
                </div>
            </div>
        </div>
        <div class="card">
            <div class="card-header">
                <h3 class="card-title"><i class="fas fa-chart-line" style="color: #4b97f3;"></i> Monthly Trend — Financial Year <%= selectedYear %></h3>
            </div>
            <div class="card-body">
                <div style="height: 380px;">
                    <canvas id="monthChart"></canvas>
                </div>
            </div>
        </div>
    </div>

    <h1 class="page-title"><i class="fas fa-search-dollar" style="color: var(--sf-text-light);"></i> Expenditure Analysis Engine</h1>
    
    <!-- Parametric Configuration Controls -->
    <form class="filter-panel" method="get" action="Home">
        <div style="display:flex; flex-direction:column; gap:6px;">
            <label style="font-size:12px; font-weight:600; color: var(--sf-text-muted);">Select Department</label>
            <select name="department">
                <option value="All">All Departments</option>
                <% if(departments != null){ for(String d : departments){ %>
                    <option value="<%= d %>" <%= d.equals(selectedDept) ? "selected" : "" %>><%= d %></option>
                <% }} %>
            </select>
        </div>
        <div style="display:flex; flex-direction:column; gap:6px;">
            <label style="font-size:12px; font-weight:600; color: var(--sf-text-muted);">Financial Year</label>
            <select name="year">
                <% if(years != null){ for(String y : years){ %>
                    <option value="<%= y %>" <%= y.equals(selectedYear) ? "selected" : "" %>><%= y %></option>
                <% }} %>
            </select>
        </div>
        <button type="submit"><i class="fas fa-sync-alt" style="margin-right: 6px;"></i>Update View</button>
    </form>

    <!-- Context Metric Blocks -->
    <div class="report-summary">
        <div class="summary-item" style="border-top: 3px solid #54a3f5;">
            <h3>Active Domains</h3>
            <p><%= totalRows %></p>
        </div>
        <div class="summary-item" style="border-top: 3px solid #1aa0be;">
            <h3>Aggregated Balance</h3>
            <% NumberFormat indianFmt = NumberFormat.getCurrencyInstance(new Locale("en", "IN")); %>
            <p style="color: var(--sf-blue-dark); font-weight: 600;"><%= indianFmt.format(grandTotal) %></p>
        </div>
    </div>

    <!-- Tabular Breakdown Layout -->
    <div class="card" style="padding:0;">
        <div class="card-header">
            <h3 class="card-title"><i class="fas fa-table" style="color:var(--sf-text-light);"></i> Structured Periodic Rollup Matrix</h3>
        </div>
        <div class="table-container">
            <table style="margin: 0;">
                <thead>
                    <tr>
                        <th style="text-align:left; padding-left:24px;">Department</th>
                        <% for(String m : monthNames){ %><th><%= m.substring(0,3) %></th><% } %>
                        <th style="background:#fafaf9; color:var(--sf-text-main); font-weight: 700; border-left: 1px solid var(--sf-border);">Subtotal</th>
                    </tr>
                </thead>
                <tbody>
                <% if(dataMap != null){ 
                    for(Map.Entry<String,double[]> entry : dataMap.entrySet()){
                        double total = 0; 
                %>
                    <tr>
                        <td style="text-align:left; padding-left:24px; font-weight:600; color:var(--sf-text-main);"><%= entry.getKey() %></td>
                        <% for(double val : entry.getValue()){ total += val; %>
                            <td style="color: var(--sf-text-muted);"><%= val > 0 ? String.format("%,.0f", val) : "—" %></td>
                        <% } %>
                        <td style="font-weight:700; background:#fafdff; color: var(--sf-blue-dark); border-left: 1px solid var(--sf-border);"><%= String.format("%,.2f", total) %></td>
                    </tr>
                <%  }
                   } 
                %>
                </tbody>
            </table>
        </div>
    </div>
</div>

<script>
(function() {
    const dLabels = [<% if(dataMap != null){ for(Iterator<String> it = dataMap.keySet().iterator(); it.hasNext();){ %>"<%= it.next() %>"<%= it.hasNext() ? "," : "" %><% }} %>];
    const dValues = [<% if(dataMap != null){ for(Iterator<double[]> it = dataMap.values().iterator(); it.hasNext();){ double[] arr = it.next(); double sum = 0; for(double v : arr) sum += v; %><%= sum %><%= it.hasNext() ? "," : "" %><% }} %>];

    const mLabels = [<% for(int i=0; i<monthNames.length; i++){ %>"<%= monthNames[i] %>"<%= i < monthNames.length-1 ? "," : "" %><% } %>];
    const mValues = [<%
        double[] sums = new double[monthNames.length];
        if(dataMap != null){ for(double[] vals : dataMap.values()){ for(int i=0; i<vals.length; i++) sums[i] += vals[i]; } }
        for(int i=0; i<sums.length; i++){ %><%= sums[i] %><%= i < sums.length-1 ? "," : "" %><% } %>];

    const chartHeight = Math.max(400, dLabels.length * 36);
    document.getElementById('deptChartWrapper').style.height = chartHeight + 'px';

    const sfBlue = '#1b5eae';
    const sfOrange = '#ff9d3b';

    new Chart(document.getElementById('deptChart'), {
        type: 'bar',
        data: {
            labels: dLabels,
            datasets: [{
                data: dValues,
                backgroundColor: sfBlue,
                hoverBackgroundColor: '#0176d3',
                borderRadius: 2,
                barThickness: 16
            }]
        },
        options: {
            indexAxis: 'y',
            maintainAspectRatio: false,
            responsive: true,
            plugins: { legend: { display: false } },
            scales: { 
                x: { grid: { color: '#eef0f1' }, ticks: { font: { size: 11, family: 'Segoe UI' } } },
                y: { ticks: { autoSkip: false, font: { size: 11, weight: '600', family: 'Segoe UI' } }, grid: { display: false } }
            }
        }
    });

    new Chart(document.getElementById('monthChart'), {
        type: 'line',
        data: {
            labels: mLabels,
            datasets: [{
                data: mValues,
                borderColor: sfOrange,
                backgroundColor: 'rgba(255, 157, 59, 0.05)',
                fill: true,
                tension: 0.2,
                pointRadius: 4,
                pointHoverRadius: 6,
                pointBackgroundColor: sfOrange
            }]
        },
        options: {
            maintainAspectRatio: false,
            responsive: true,
            plugins: { legend: { display: false } },
            scales: { 
                y: { beginAtZero: true, grid: { color: '#eef0f1' }, ticks: { font: { family: 'Segoe UI' }, callback: v => '₹' + v.toLocaleString('en-IN') } },
                x: { grid: { display: false }, ticks: { font: { family: 'Segoe UI' } } }
            }
        }
    });
})();
</script>
</body>
</html>