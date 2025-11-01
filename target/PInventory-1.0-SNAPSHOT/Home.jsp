<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

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
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Inventory Dashboard</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<style>
    :root {
        --primary: #0a66c2;
        --secondary: #0077b6;
        --accent: #00b4d8;
        --light-bg: #f1f7ff;
        --white: #fff;
        --text: #1e3050;
        --shadow: 0 3px 8px rgba(0,0,0,0.1);
    }

    body {
        font-family: 'Segoe UI', sans-serif;
        background: var(--light-bg);
        margin: 0;
        padding-bottom: 70px;
        color: var(--text);
    }

    h1, h3 {
        text-align: center;
        color: var(--secondary);
        font-weight: 600;
        margin: 15px 0;
    }

    .container {
        width: 95%;
        max-width: 1400px;
        margin: 0 auto;
    }

    /* --- Grid Layout --- */
    .dashboard-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(340px, 1fr));
        gap: 18px;
        margin-top: 20px;
    }

    .card {
        background: var(--white);
        border-radius: 10px;
        box-shadow: var(--shadow);
        padding: 15px 20px;
        transition: 0.3s;
    }

    .card:hover { transform: translateY(-3px); }

    /* --- Table --- */
    table {
        width: 100%;
        border-collapse: collapse;
        font-size: 13.5px;
    }

    th, td {
        padding: 8px;
        text-align: center;
        border-bottom: 1px solid #eee;
    }

    th {
        background: linear-gradient(135deg, var(--primary), var(--secondary));
        color: #fff;
        font-weight: 600;
    }

    tr:hover { background: #f0f8ff; }

    /* --- Stage Cards --- */
    .stage-container {
        display: flex;
        flex-wrap: wrap;
        justify-content: space-evenly;
        gap: 12px;
    }

    .stage-card {
        flex: 1 1 150px;
        background: linear-gradient(120deg,#eaf3ff,#d7e7ff);
        border-left: 5px solid var(--primary);
        border-radius: 8px;
        padding: 10px;
        text-align: center;
        box-shadow: var(--shadow);
        transition: 0.3s;
    }

    .stage-card:hover { background: #d9ecff; transform: scale(1.05); }

    .stage-card h4 { font-size: 13px; color: var(--secondary); margin: 5px 0; }
    .stage-card h2 { font-size: 22px; color: var(--primary); margin: 0; }

    /* --- Filters --- */
    .filter-form {
        text-align: center;
        margin: 25px 0 15px;
    }

    select, button {
        padding: 7px 12px;
        border-radius: 6px;
        border: 1px solid #ccc;
        font-size: 13.5px;
        margin: 5px;
    }

    button {
        background: var(--primary);
        color: white;
        border: none;
        cursor: pointer;
        font-weight: 500;
    }

    button:hover { background: var(--secondary); }

    /* --- Chart & Table Section Side-by-Side --- */
    .chart-table-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(420px, 1fr));
        gap: 20px;
        margin-top: 25px;
    }

    .chart-container, .report-table {
        background: var(--white);
        border-radius: 10px;
        box-shadow: var(--shadow);
        padding: 15px;
    }

    canvas {
        height: 260px !important;
    }

    /* --- Summary Cards --- */
    .report-summary {
        display: flex;
        justify-content: center;
        flex-wrap: wrap;
        gap: 15px;
        margin: 20px 0;
    }

    .report-card {
        background: var(--white);
        border-radius: 10px;
        box-shadow: var(--shadow);
        padding: 12px 25px;
        text-align: center;
        min-width: 190px;
        border-top: 4px solid var(--primary);
    }

    .report-card h3 { margin: 0; color: var(--secondary); font-size: 14px; }

    .report-card p {
        font-size: 18px;
        color: var(--primary);
        font-weight: bold;
        margin: 5px 0 0;
    }

    footer {
        text-align: center;
        font-size: 13px;
        color: #777;
        padding: 12px 0;
        margin-top: 50px;
        background: #f1f4fa;
        border-top: 1px solid #e0e0e0;
    }

    @media (max-width: 768px) {
        canvas { height: 200px !important; }
    }
</style>
</head>
<body>
<%@ include file="header.jsp" %>

<div class="container">
    <h1>Inventory Dashboard</h1>

    <!-- Top Cards -->
    <div class="dashboard-grid">
        <div class="card">
            <h3>Indents by Department</h3>
            <table>
                <thead><tr><th>Department</th><th>Total</th><th>Pending</th><th>Approved</th></tr></thead>
                <tbody>
                <%
                    if(totalDeptMap!=null && !totalDeptMap.isEmpty()){
                        for(Map.Entry<String,Integer> e:totalDeptMap.entrySet()){
                            String deptName=e.getKey();
                            int total=e.getValue();
                            int pending=deptPendingMap!=null?deptPendingMap.getOrDefault(deptName,0):0;
                            int approved=total-pending;
                %>
                    <tr><td><%=deptName%></td><td><%=total%></td><td><%=pending%></td><td><%=approved%></td></tr>
                <% }} else { %>
                    <tr><td colspan="4">No Indents Found</td></tr>
                <% } %>
                </tbody>
            </table>
        </div>

        <div class="card">
            <h3>Stage Summary</h3>
            <div class="stage-container">
                <%
                    if(nextStageCountMap!=null){
                        String[][] stages={{"Approval Pending","approval-pending"},{"PO","po"},
                                           {"Issue Pending","issue-pending"},{"Issued","issued"},
                                           {"Management Note","management-note"}};
                        for(String[] s:stages){
                            int count=nextStageCountMap.getOrDefault(s[0],0);
                %>
                <div class="stage-card">
                    <h4><%=s[0]%></h4><h2><%=count%></h2>
                </div>
                <% }} %>
            </div>
        </div>
    </div>

    <!-- Charts + Table Side by Side -->
    <div class="chart-table-grid">
        <div class="chart-container">
            <h3>Department-wise Total Issue Value (₹)</h3>
            <canvas id="deptChart"></canvas>
        </div>
        <div class="chart-container">
            <h3>Monthly Issue Value Trend - <%=selectedYear%></h3>
            <canvas id="monthChart"></canvas>
        </div>
    </div>

    <!-- Department-wise Report -->
    <h1>Department-wise Monthly Report (<%=selectedYear%>)</h1>
    <form class="filter-form" method="get" action="Home">
        <label>Department:</label>
        <select name="department">
            <option value="All" <%= "All".equals(selectedDept) ? "selected" : "" %>>All</option>
            <% if(departments!=null){ for(String d:departments){ %>
                <option value="<%=d%>" <%= d.equals(selectedDept) ? "selected" : "" %>><%=d%></option>
            <% }} %>
        </select>
        <label>Year:</label>
        <select name="year">
            <% if(years!=null){ for(String y:years){ %>
                <option value="<%=y%>" <%= y.equals(selectedYear) ? "selected" : "" %>><%=y%></option>
            <% }} %>
        </select>
        <button type="submit">Show Report</button>
    </form>

    <div class="report-summary">
        <div class="report-card"><h3>Total Departments</h3><p><%= totalRows %></p></div>
        <div class="report-card"><h3>Total Issue Value (₹)</h3><p><%= String.format("%.2f", grandTotal) %></p></div>
    </div>

    <div class="report-table">
        <table>
            <thead>
                <tr><th>Department</th>
                    <% for(String m:monthNames){ %><th><%=m%></th><% } %>
                    <th>Total (₹)</th>
                </tr>
            </thead>
            <tbody>
            <%
                if(dataMap!=null && !dataMap.isEmpty()){
                    for(Map.Entry<String,double[]> e : dataMap.entrySet()){
                        String dept=e.getKey();
                        double[] vals=e.getValue();
                        double total=0;
            %>
                <tr>
                    <td><%=dept%></td>
                    <% for(double v:vals){ total+=v; %>
                        <td><%=String.format("%.2f", v)%></td>
                    <% } %>
                    <td><%=String.format("%.2f", total)%></td>
                </tr>
            <% }} else { %>
                <tr><td colspan="14">No data available.</td></tr>
            <% } %>
            </tbody>
        </table>
    </div>
<br><br><br><br><br><br><br><br>
    <footer>© <%=java.time.Year.now()%> Inventory Dashboard | Built with JSP, Servlet & Chart.js</footer>
</div>

<!-- Chart Scripts -->
<!-- Chart Scripts -->
<script>
const ctxDept = document.getElementById('deptChart').getContext('2d');
const ctxMonth = document.getElementById('monthChart').getContext('2d');

// ======= Dynamic Data =======
const deptLabels = [<% if(dataMap!=null){ 
    for(Iterator<String> it=dataMap.keySet().iterator(); it.hasNext();){ 
        String d=it.next(); %>"<%=d%>"<%= it.hasNext() ? "," : "" %><% }} %>];
const deptTotals = [<% if(dataMap!=null){ 
    for(Iterator<double[]> it=dataMap.values().iterator(); it.hasNext();){ 
        double[] arr=it.next(); double t=0; for(double v:arr)t+=v; %><%=String.format("%.2f",t)%><%= it.hasNext() ? "," : "" %><% }} %>];

const monthLabels = [<% for(int i=0;i<monthNames.length;i++){ %>"<%=monthNames[i]%>"<%= i<monthNames.length-1 ? "," : "" %><% } %>];
const monthTotals = [<%
    double[] monthSums = new double[monthNames.length];
    if(dataMap!=null){
        for(double[] vals : dataMap.values()){
            for(int i=0;i<vals.length;i++){ monthSums[i]+=vals[i]; }
        }
    }
    for(int i=0;i<monthSums.length;i++){ %><%=String.format("%.2f",monthSums[i])%><%= i<monthSums.length-1 ? "," : "" %><% } %>];

// ======= Gradient Styles =======
const barGradient = ctxDept.createLinearGradient(0, 0, 0, 400);
barGradient.addColorStop(0, '#0077b6');
barGradient.addColorStop(1, '#90e0ef');

const lineGradient = ctxMonth.createLinearGradient(0, 0, 0, 400);
lineGradient.addColorStop(0, '#00b4d8');
lineGradient.addColorStop(1, '#caf0f8');

// ======= Department Bar Chart =======
new Chart(ctxDept, {
    type: 'bar',
    data: {
        labels: deptLabels,
        datasets: [{
            label: 'Total Value (₹)',
            data: deptTotals,
            backgroundColor: barGradient,
            borderRadius: 6,
            borderSkipped: false,
            hoverBackgroundColor: '#023e8a'
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: { display: false },
            tooltip: {
                backgroundColor: '#023e8a',
                titleColor: '#fff',
                bodyColor: '#fff',
                boxPadding: 6,
                borderWidth: 0,
                displayColors: false
            }
        },
        scales: {
            x: {
                grid: { display: false },
                ticks: { color: '#023e8a', font: { weight: '600' } }
            },
            y: {
                beginAtZero: true,
                ticks: { color: '#0077b6' },
                grid: { color: '#e0f0ff' }
            }
        },
        animation: {
            duration: 1200,
            easing: 'easeOutQuart'
        }
    }
});

// ======= Monthly Line Chart =======
new Chart(ctxMonth, {
    type: 'line',
    data: {
        labels: monthLabels,
        datasets: [{
            label: 'Monthly Total (₹)',
            data: monthTotals,
            fill: true,
            borderColor: '#0077b6',
            backgroundColor: lineGradient,
            tension: 0.35,
            pointRadius: 5,
            pointBackgroundColor: '#0077b6',
            pointHoverRadius: 7,
            pointHoverBackgroundColor: '#03045e',
            pointBorderWidth: 2,
            borderWidth: 3
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: {
                labels: { color: '#023e8a', font: { weight: '600' } },
                position: 'top'
            },
            tooltip: {
                backgroundColor: '#03045e',
                titleColor: '#fff',
                bodyColor: '#fff',
                borderWidth: 0,
                displayColors: false
            }
        },
        scales: {
            x: {
                grid: { display: false },
                ticks: { color: '#023e8a', font: { weight: '500' } }
            },
            y: {
                beginAtZero: true,
                ticks: { color: '#0077b6' },
                grid: { color: '#e0f7fa' }
            }
        },
        animation: {
            duration: 1500,
            easing: 'easeInOutCubic'
        }
    }
});
</script>

</body>
</html>
