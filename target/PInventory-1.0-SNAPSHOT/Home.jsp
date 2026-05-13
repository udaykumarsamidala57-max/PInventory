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
<title>SRS | Inventory Dashboard</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<style>
    :root {
        --primary-navy: #0f2a4d;
        --accent-gold: #fbbf24;
        --accent-blue: #38bdf8;
        --light-bg: #f8fafc;
        --white: #ffffff;
        --text-main: #0f172a;
        --text-muted: #64748b;
        --border: #e2e8f0;
        --shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
    }

    body {
        font-family: 'Inter', sans-serif;
        background: var(--light-bg);
        margin: 0;
        color: var(--text-main);
        line-height: 1.5;
    }

    .container {
        width: 92%;
        max-width: 1440px;
        margin: 0 auto;
        padding: 40px 0;
    }

    .welcome-banner {
        background: var(--white);
        padding: 30px;
        border-radius: 16px;
        box-shadow: var(--shadow);
        margin-bottom: 35px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        border-left: 6px solid var(--primary-navy);
    }

    .welcome-text h1 {
        margin: 0;
        font-size: 28px;
        font-weight: 800;
        color: var(--primary-navy);
    }

    .welcome-text p {
        margin: 5px 0 0 0;
        color: var(--text-muted);
        font-size: 15px;
    }

    .date-badge {
        background: #f1f5f9;
        padding: 10px 20px;
        border-radius: 10px;
        font-weight: 600;
        color: var(--primary-navy);
        display: flex;
        align-items: center;
        gap: 10px;
    }

    h1.page-title {
        color: var(--primary-navy);
        font-weight: 800;
        margin: 40px 0 20px 0;
        font-size: 22px;
        text-transform: uppercase;
        letter-spacing: 1px;
        display: flex;
        align-items: center;
        gap: 12px;
    }

    h1.page-title::before {
        content: "";
        width: 4px;
        height: 24px;
        background: var(--accent-gold);
        display: inline-block;
        border-radius: 10px;
    }

    .card {
        background: var(--white);
        border-radius: 16px;
        box-shadow: var(--shadow);
        padding: 24px;
        border: 1px solid var(--border);
    }

    .dashboard-grid {
        display: grid;
        grid-template-columns: 1.2fr 0.8fr;
        gap: 25px;
    }

    .table-container { 
        overflow-x: auto; 
    }

    table { 
        width: 100%; 
        border-collapse: collapse; 
        font-size: 13.5px; 
    }

    thead { 
        background: var(--primary-navy); 
    }

    th { 
        color: white; 
        padding: 14px 10px; 
        font-weight: 600; 
        text-align: center;
    }

    td { 
        padding: 12px 10px; 
        border-bottom: 1px solid var(--border); 
        text-align: center; 
        color: var(--text-main);
    }

    .stage-container { 
        display: grid; 
        grid-template-columns: 1fr 1fr; 
        gap: 15px; 
    }

    .stage-card {
        padding: 20px; 
        text-align: left; 
        border-radius: 12px;
        background: #f8fafc; 
        border: 1px solid var(--border);
        transition: all 0.3s ease;
    }

    .stage-card:hover {
        border-color: var(--accent-blue);
        transform: translateY(-2px);
    }

    .stage-card h4 { 
        font-size: 11px; 
        color: var(--text-muted); 
        text-transform: uppercase; 
        margin: 0; 
        letter-spacing: 0.5px;
    }

    .stage-card h2 { 
        font-size: 24px; 
        color: var(--primary-navy); 
        font-weight: 800; 
        margin: 8px 0 0 0; 
    }

    .chart-grid { 
        display: grid; 
        grid-template-columns: 1fr 1fr; 
        gap: 25px; 
        margin-top: 30px; 
    }

    .scrollable-chart-area {
        height: 380px;
        overflow-y: auto;
        padding-right: 8px;
    }

    .filter-panel {
        background: var(--primary-navy); 
        padding: 25px; 
        border-radius: 16px;
        margin: 30px 0; 
        display: flex; 
        justify-content: center; 
        align-items: center;
        gap: 20px; 
        color: white;
    }

    .filter-panel select { 
        padding: 10px 15px; 
        border-radius: 8px; 
        border: none;
        font-weight: 600;
        outline: none;
        min-width: 180px;
    }

    .filter-panel button { 
        background: var(--accent-gold); 
        color: var(--primary-navy); 
        padding: 10px 30px; 
        border: none; 
        border-radius: 8px; 
        font-weight: 700; 
        cursor: pointer; 
        transition: 0.2s;
    }

    .filter-panel button:hover {
        background: #fcd34d;
        transform: scale(1.03);
    }

    .report-summary { 
        display: flex; 
        gap: 20px; 
        margin-bottom: 30px; 
    }

    .summary-item { 
        flex: 1; 
        background: var(--white); 
        padding: 25px; 
        border-radius: 16px; 
        text-align: center; 
        box-shadow: var(--shadow);
        border-bottom: 4px solid var(--accent-gold);
    }

    .summary-item h3 { 
        font-size: 13px; 
        color: var(--text-muted); 
        text-transform: uppercase; 
        margin: 0;
    }

    .summary-item p {
        font-size: 24px;
        font-weight: 800;
        margin: 10px 0 0 0;
        color: var(--primary-navy);
    }

    footer { 
        text-align: center; 
        padding: 40px; 
        color: var(--text-muted); 
        font-size: 14px; 
    }

    @media (max-width: 1100px) {
        .dashboard-grid, .chart-grid { grid-template-columns: 1fr; }
    }
</style>
</head>
<body>
<%@ include file="header.jsp" %>

<div class="container">
    
    <div class="welcome-banner">
        <div class="welcome-text">
            <h1><%= greeting %>, <%= user %>!</h1>
            <p>Here is what's happening with the SRS Inventory system today.</p>
        </div>
        <div class="date-badge">
            <i class="far fa-calendar-alt"></i>
            <%= new java.text.SimpleDateFormat("EEEE, dd MMMM yyyy").format(new java.util.Date()) %>
        </div>
    </div>

    <div class="dashboard-grid">
        <div class="card">
            <h3 class="card-title"><i class="fas fa-layer-group" style="margin-right: 8px;"></i> Indents by Department</h3>
            <div class="table-container" style="max-height: 280px;">
                <table>
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
                            <td style="text-align:left; padding-left: 20px; font-weight: 600;"><%= dName %></td>
                            <td><%= total %></td>
                            <td style="color:#ef4444; font-weight: 700;"><%= pending %></td>
                            <td style="color:#10b981; font-weight: 700;"><%= total - pending %></td>
                        </tr>
                    <%      }
                        } 
                    %>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="card">
            <h3 class="card-title"><i class="fas fa-tasks" style="margin-right: 8px;"></i> Stage Summary</h3>
            <div class="stage-container">
                <%
                    if(nextStageCountMap != null){
                        String[][] list = {{"Approval Pending", "fas fa-user-check"}, {"PO Generation", "fas fa-file-invoice"}, 
                                          {"Issue Pending", "fas fa-box"}, {"Management Note", "fas fa-clipboard-list"}};
                        for(String[] s : list){
                            int count = nextStageCountMap.getOrDefault(s[0], 0);
                %>
                <div class="stage-card">
                    <i class="<%= s[1] %>" style="color: var(--accent-blue); margin-bottom: 10px;"></i>
                    <h4><%= s[0] %></h4>
                    <h2><%= count %></h2>
                </div>
                <%      }
                    } 
                %>
            </div>
        </div>
    </div>

    <div class="chart-grid">
        <div class="card">
            <h3 class="card-title"><i class="fas fa-chart-bar" style="margin-right: 8px;"></i> Departmental Consumption (₹)</h3>
            <div class="scrollable-chart-area">
                <div id="deptChartWrapper">
                    <canvas id="deptChart"></canvas>
                </div>
            </div>
        </div>
        <div class="card">
            <h3 class="card-title"><i class="fas fa-chart-line" style="margin-right: 8px;"></i> Monthly Trend - <%= selectedYear %></h3>
            <div style="height: 380px;">
                <canvas id="monthChart"></canvas>
            </div>
        </div>
    </div>

    <h1 class="page-title">Expenditure Analysis</h1>
    
    <form class="filter-panel" method="get" action="Home">
        <div style="display:flex; flex-direction:column; gap:5px;">
            <label style="font-size:12px; font-weight:700; opacity:0.8;">Select Department</label>
            <select name="department">
                <option value="All">All Departments</option>
                <% if(departments != null){ for(String d : departments){ %>
                    <option value="<%= d %>" <%= d.equals(selectedDept) ? "selected" : "" %>><%= d %></option>
                <% }} %>
            </select>
        </div>
        <div style="display:flex; flex-direction:column; gap:5px;">
            <label style="font-size:12px; font-weight:700; opacity:0.8;">Financial Year</label>
            <select name="year">
                <% if(years != null){ for(String y : years){ %>
                    <option value="<%= y %>" <%= y.equals(selectedYear) ? "selected" : "" %>><%= y %></option>
                <% }} %>
            </select>
        </div>
        <button type="submit">Refresh Data</button>
    </form>

    <div class="report-summary">
        <div class="summary-item">
            <h3>Monitoring</h3>
            <p><%= totalRows %> Departments</p>
        </div>
        <div class="summary-item">
            <h3>Yearly Total</h3>
            <% NumberFormat indianFmt = NumberFormat.getCurrencyInstance(new Locale("en", "IN")); %>
            <p><%= indianFmt.format(grandTotal) %></p>
        </div>
    </div>

    <div class="card" style="padding:0; overflow:hidden;">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th style="text-align:left; padding-left:25px;">Department</th>
                        <% for(String m : monthNames){ %><th><%= m.substring(0,3) %></th><% } %>
                        <th style="background:var(--accent-gold); color:var(--primary-navy);">Total</th>
                    </tr>
                </thead>
                <tbody>
                <% if(dataMap != null){ 
                    for(Map.Entry<String,double[]> entry : dataMap.entrySet()){
                        double total = 0; 
                %>
                    <tr>
                        <td style="text-align:left; padding-left:25px; font-weight:700; color:var(--primary-navy);"><%= entry.getKey() %></td>
                        <% for(double val : entry.getValue()){ total += val; %>
                            <td><%= val > 0 ? String.format("%,.0f", val) : "-" %></td>
                        <% } %>
                        <td style="font-weight:800; background:#fffbeb; color:#b45309;"><%= String.format("%,.2f", total) %></td>
                    </tr>
                <%  }
                   } 
                %>
                </tbody>
            </table>
        </div>
    </div>

    <footer>
        <p>© <%= cal.get(Calendar.YEAR) %> Sandur Residential School. Developed by School IT Department</p>
    </footer>
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

    const chartHeight = Math.max(400, dLabels.length * 38);
    document.getElementById('deptChartWrapper').style.height = chartHeight + 'px';

    new Chart(document.getElementById('deptChart'), {
        type: 'bar',
        data: {
            labels: dLabels,
            datasets: [{
                data: dValues,
                backgroundColor: '#0f2a4d',
                hoverBackgroundColor: '#fbbf24',
                borderRadius: 6
            }]
        },
        options: {
            indexAxis: 'y',
            maintainAspectRatio: false,
            responsive: true,
            plugins: { legend: { display: false } },
            scales: { 
                x: { grid: { color: '#f1f5f9' }, ticks: { font: { size: 10 } } },
                y: { ticks: { autoSkip: false, font: { size: 11, weight: '600' } }, grid: { display: false } }
            }
        }
    });

    new Chart(document.getElementById('monthChart'), {
        type: 'line',
        data: {
            labels: mLabels,
            datasets: [{
                data: mValues,
                borderColor: '#fbbf24',
                backgroundColor: 'rgba(251, 191, 36, 0.1)',
                fill: true,
                tension: 0.4,
                pointRadius: 5,
                pointBackgroundColor: '#0f2a4d'
            }]
        },
        options: {
            maintainAspectRatio: false,
            responsive: true,
            plugins: { legend: { display: false } },
            scales: { 
                y: { beginAtZero: true, grid: { color: '#f1f5f9' }, ticks: { callback: v => '₹' + v.toLocaleString('en-IN') } },
                x: { grid: { display: false } }
            }
        }
    });
})();
</script>
</body>
</html>