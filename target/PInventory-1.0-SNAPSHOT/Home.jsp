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
        
        background: var(--light-bg);
        margin: 0;
        padding-bottom: 70px;
        color: var(--text);
    }
    body::before {
    font-family: 'Segoe UI', sans-serif;
    content: "";
    position: fixed;
    top: -20%;
    left: -20%;
    width: 140%;
    height: 140%;
    background: radial-gradient(circle at 20% 30%, rgba(108, 92, 231, 0.25), transparent 60%),
                radial-gradient(circle at 80% 70%, rgba(52, 152, 219, 0.25), transparent 60%),
                radial-gradient(circle at 50% 100%, rgba(255, 159, 67, 0.25), transparent 70%);
    animation: moveGradient 18s ease-in-out infinite alternate;
    z-index: -1;
    filter: blur(90px);
    opacity: 0.9;
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

     td,th {
        padding: 8px;
        text-align: center;
        border-bottom: 1px solid #eee;
    }

    thead  {
    text-align: center;
    padding: 10px;
    border-bottom: 1px solid #eee;
    background: linear-gradient(135deg, #ff8c00, #8e2de2);
    color: #fff;
    font-weight: 600;
}

    tr:hover { background: #f0f8ff; }

   /* --- Stage Cards (Modern Colorful Version) --- */
.stage-container {
    display: flex;
    flex-wrap: wrap;
    justify-content: space-evenly;
    gap: 18px;
    margin-top: 10px;
}

.stage-card {
    flex: 1 1 170px;
    padding: 18px 10px;
    border-radius: 16px;
    color: white;
    text-align: center;
    box-shadow: 0 6px 14px rgba(0,0,0,0.18);
    transition: 0.35s ease;
    transform: translateY(0px);
    cursor: pointer;
}

/* Hover Effect */
.stage-card:hover {
    transform: translateY(-6px);
    box-shadow: 0 12px 22px rgba(0,0,0,0.25);
}

/* Stage Heading */
.stage-card h4 {
    font-size: 14px;
    margin: 8px 0;
    font-weight: 600;
}

/* Stage Count */
.stage-card h2 {
    font-size: 28px;
    margin: 0;
    font-weight: 700;
}

/* Icons */
.stage-icon {
    font-size: 30px;
    margin-bottom: 8px;
}

/* Color Themes */
.stage-approval  { background: linear-gradient(135deg, #ff7b00, #ffb84d); }
.stage-po        { background: linear-gradient(135deg, #005eff, #4da3ff); }
.stage-issue     { background: linear-gradient(135deg, #9b00ff, #d96cff); }
.stage-issued    { background: linear-gradient(135deg, #02a858, #56e99a); }
.stage-note      { background: linear-gradient(135deg, #ff3e6c, #ff85a1); }

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

        <% if(nextStageCountMap!=null){ %>

            <!-- Approval Pending -->
            <div class="stage-card stage-approval">
                <div class="stage-icon">⏳</div>
                <h4>Approval Pending</h4>
                <h2><%= nextStageCountMap.getOrDefault("Approval Pending",0) %></h2>
            </div>

            <!-- PO -->
            <div class="stage-card stage-po">
                <div class="stage-icon">📄</div>
                <h4>PO</h4>
                <h2><%= nextStageCountMap.getOrDefault("PO",0) %></h2>
            </div>

            <!-- Issue Pending -->
            <div class="stage-card stage-issue">
                <div class="stage-icon">📦</div>
                <h4>Issue Pending</h4>
                <h2><%= nextStageCountMap.getOrDefault("Issue Pending",0) %></h2>
            </div>

            <!-- Issued -->
            <div class="stage-card stage-issued">
                <div class="stage-icon">✔️</div>
                <h4>Issued</h4>
                <h2><%= nextStageCountMap.getOrDefault("Issued",0) %></h2>
            </div>

            <!-- Management Note -->
            <div class="stage-card stage-note">
                <div class="stage-icon">📝</div>
                <h4>Management Note</h4>
                <h2><%= nextStageCountMap.getOrDefault("Management Note",0) %></h2>
            </div>

        <% } %>

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
        <div class="report-card"><h3>Total Issue Value (₹)</h3>
    <%
    java.text.NumberFormat nf = java.text.NumberFormat.getNumberInstance(new java.util.Locale("en", "IN"));
    nf.setMinimumFractionDigits(2);
    nf.setMaximumFractionDigits(2);
%>
<p>₹<%= nf.format(grandTotal) %></p>
</div>
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
    <footer>  <p> | SRS Inventory System | <i class="fas fa-leaf" style="color:green;"></i> Developed by <i class="fas fa-leaf" style="color:green;"></i> School IT Department
</p></footer>
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
