<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%!
    // HTML-escape for text/attributes
    private static String h(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
    // Escape for JS string literals
    private static String js(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("'", "\\'")
                .replace("\n", " ").replace("\r", " ").replace("<", "\\u003c");
    }
%>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String user = (String) sess.getAttribute("username");

    @SuppressWarnings("unchecked")
    Map<String, Double> todayDeptMap = (Map<String, Double>) request.getAttribute("todayDeptMap");
    Double tt = (Double) request.getAttribute("todayTotal");
    if (todayDeptMap == null) todayDeptMap = new LinkedHashMap<String, Double>();
    double todayTotal = tt != null ? tt : 0;

    @SuppressWarnings("unchecked")
    List<String> departments = (List<String>) request.getAttribute("departments");
    @SuppressWarnings("unchecked")
    List<String> years = (List<String>) request.getAttribute("years");
    @SuppressWarnings("unchecked")
    Map<String, double[]> dataMap = (Map<String, double[]>) request.getAttribute("dataMap");
    // Financial year months, always April to March
    String[] monthNames = {"Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec","Jan","Feb","Mar"};
    String selectedDept = (String) request.getAttribute("selectedDept");
    String selectedYear = (String) request.getAttribute("selectedYear");
    Double gt = (Double) request.getAttribute("grandTotal");
    Integer tr = (Integer) request.getAttribute("totalRows");

    if (departments == null) departments = new ArrayList<String>();
    if (years == null) years = new ArrayList<String>();
    if (dataMap == null) dataMap = new LinkedHashMap<String, double[]>();
    if (selectedDept == null) selectedDept = "All";
    if (selectedYear == null) selectedYear = "";
    double grandTotal = gt != null ? gt : 0;
    int totalRows = tr != null ? tr : 0;

    // Greeting
    int hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY);
    String greeting = hour < 12 ? "Good morning" : (hour < 17 ? "Good afternoon" : "Good evening");

    // Aggregates for KPIs and charts
    double[] monthTotals = new double[monthNames.length];
    for (double[] vals : dataMap.values()) {
        for (int i = 0; i < vals.length && i < monthTotals.length; i++) monthTotals[i] += vals[i];
    }
    int peakIdx = -1; double peakVal = 0;
    for (int i = 0; i < monthTotals.length; i++) {
        if (monthTotals[i] > peakVal) { peakVal = monthTotals[i]; peakIdx = i; }
    }
    String topDept = "—"; double topDeptVal = 0;
    for (Map.Entry<String, double[]> e : dataMap.entrySet()) {
        double s = 0; for (double v : e.getValue()) s += v;
        if (s > topDeptVal) { topDeptVal = s; topDept = e.getKey(); }
    }

    NumberFormat inr = NumberFormat.getCurrencyInstance(new Locale("en", "IN"));
    inr.setMaximumFractionDigits(0);

    // JSON-ish arrays for Chart.js
    StringBuilder dLabels = new StringBuilder();
    StringBuilder dValues = new StringBuilder();
    for (Iterator<Map.Entry<String, double[]>> it = dataMap.entrySet().iterator(); it.hasNext();) {
        Map.Entry<String, double[]> e = it.next();
        double s = 0; for (double v : e.getValue()) s += v;
        dLabels.append("\"").append(js(e.getKey())).append("\"");
        dValues.append(String.format(Locale.ROOT, "%.2f", s));
        if (it.hasNext()) { dLabels.append(","); dValues.append(","); }
    }
    StringBuilder mLabels = new StringBuilder();
    StringBuilder mValues = new StringBuilder();
    for (int i = 0; i < monthNames.length; i++) {
        mLabels.append("\"").append(js(monthNames[i])).append("\"");
        mValues.append(String.format(Locale.ROOT, "%.2f", monthTotals[i]));
        if (i < monthNames.length - 1) { mLabels.append(","); mValues.append(","); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Inventory Dashboard</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<style>
    /* ---------- Salesforce Lightning-style tokens ---------- */
    :root {
        --brand: #0176d3;
        --brand-dark: #014486;
        --brand-light: #eef4ff;
        --navy: #032d60;
        --bg: #f3f3f3;
        --card: #ffffff;
        --border: #e5e5e5;
        --border-strong: #c9c9c9;
        --text: #181818;
        --text-weak: #444444;
        --text-weaker: #5c5c5c;
        --success: #2e844a;
        --warning: #fe9339;
        --focus: #1b96ff;
        --radius: 0.25rem;
        --radius-lg: 0.5rem;
        --shadow: 0 2px 2px 0 rgba(0,0,0,0.10);
    }
    * { box-sizing: border-box; }
    body {
        font-family: "Salesforce Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
        background: var(--bg);
        color: var(--text);
        margin: 0;
        font-size: 13px;
        line-height: 1.5;
        -webkit-font-smoothing: antialiased;
    }
    .container { width: 96%; max-width: 1600px; margin: 0 auto; padding: 16px 0 24px; }

    /* ---------- Page header (record-home style) ---------- */
    .page-header {
        background: var(--card);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow);
        padding: 14px 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 16px;
        margin-bottom: 12px;
        flex-wrap: wrap;
    }
    .ph-left { display: flex; align-items: center; gap: 12px; }
    .ph-icon {
        width: 40px; height: 40px; border-radius: var(--radius);
        background: #3a9bdc; color: #fff;
        display: flex; align-items: center; justify-content: center;
        font-size: 18px; flex-shrink: 0;
    }
    .ph-sub { font-size: 12px; color: var(--text-weaker); margin: 0; }
    .ph-title { font-size: 20px; font-weight: 700; margin: 0; color: var(--text); line-height: 1.25; }
    .ph-date {
        font-size: 12px; color: var(--text-weak);
        border: 1px solid var(--border-strong); border-radius: 15rem;
        padding: 4px 12px; background: #fff; white-space: nowrap;
    }
    .ph-date i { margin-right: 6px; color: var(--text-weaker); }

    /* ---------- Today's cost ---------- */
    .today-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(190px, 1fr));
        gap: 10px;
    }
    .today-tile {
        border: 1px solid var(--border);
        border-left: 3px solid var(--brand);
        border-radius: var(--radius);
        padding: 10px 14px;
        background: #fff;
    }
    .today-tile .t-dept { font-size: 12px; color: var(--text-weaker); margin: 0 0 2px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .today-tile .t-val { font-size: 18px; font-weight: 400; color: var(--navy); margin: 0; }
    .today-total { font-size: 13px; color: var(--text-weak); }
    .today-total b { font-size: 16px; color: var(--navy); margin-left: 4px; }

    /* ---------- Filter bar ---------- */
    .filter-panel {
        background: var(--card);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow);
        padding: 12px 20px;
        margin-bottom: 12px;
        display: flex;
        align-items: flex-end;
        gap: 16px;
        flex-wrap: wrap;
    }
    .field { display: flex; flex-direction: column; gap: 4px; }
    .field label { font-size: 12px; color: var(--text-weak); }
    .filter-panel select {
        height: 32px;
        min-width: 220px;
        padding: 0 12px;
        border: 1px solid var(--border-strong);
        border-radius: var(--radius);
        background: #fff;
        color: var(--text);
        font-size: 13px;
        font-family: inherit;
    }
    .filter-panel select:focus {
        outline: none; border-color: var(--focus);
        box-shadow: 0 0 3px #0176d3;
    }
    .btn-brand {
        height: 32px; padding: 0 16px;
        background: var(--brand); color: #fff;
        border: 1px solid var(--brand); border-radius: var(--radius);
        font-size: 13px; font-weight: 400; font-family: inherit; cursor: pointer;
    }
    .btn-brand:hover { background: var(--brand-dark); border-color: var(--brand-dark); }
    .btn-brand:focus-visible { outline: none; box-shadow: 0 0 3px #0176d3; }
    .btn-brand i { margin-right: 6px; }

    /* ---------- KPI tiles ---------- */
    .kpi-grid {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 12px;
        margin-bottom: 12px;
    }
    .kpi {
        background: var(--card);
        border: 1px solid var(--border);
        border-top: 3px solid var(--brand);
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow);
        padding: 14px 18px;
    }
    .kpi:nth-child(2) { border-top-color: var(--success); }
    .kpi:nth-child(3) { border-top-color: var(--warning); }
    .kpi:nth-child(4) { border-top-color: #8e5af7; }
    .kpi .k-label { font-size: 12px; color: var(--text-weaker); margin: 0 0 4px; }
    .kpi .k-value { font-size: 24px; font-weight: 300; color: var(--text); margin: 0; line-height: 1.2; word-break: break-word; }
    .kpi .k-note { font-size: 12px; color: var(--text-weaker); margin: 2px 0 0; }

    /* ---------- Cards ---------- */
    .card {
        background: var(--card);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow);
        margin-bottom: 12px;
        overflow: hidden;
    }
    .card-header {
        padding: 12px 16px;
        display: flex; align-items: center; justify-content: space-between;
        border-bottom: 1px solid var(--border);
    }
    .card-title {
        margin: 0; font-size: 15px; font-weight: 700; color: var(--text);
        display: flex; align-items: center; gap: 10px;
    }
    .card-title .ti {
        width: 28px; height: 28px; border-radius: var(--radius);
        display: inline-flex; align-items: center; justify-content: center;
        color: #fff; font-size: 13px;
    }
    .card-meta { font-size: 12px; color: var(--text-weaker); }
    .card-body { padding: 16px; }

    .chart-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    .scroll-chart { height: 360px; overflow-y: auto; }

    /* ---------- Data table ---------- */
    .table-container { overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    thead th {
        background: #f3f3f3;
        color: var(--text-weak);
        font-weight: 700;
        font-size: 12px;
        text-align: right;
        padding: 8px 12px;
        border-top: 1px solid var(--border);
        border-bottom: 1px solid var(--border);
        white-space: nowrap;
    }
    tbody td {
        padding: 8px 12px;
        text-align: right;
        border-bottom: 1px solid var(--border);
        color: var(--text-weak);
        white-space: nowrap;
    }
    tbody tr:hover td { background: #f3f9ff; }
    th.left, td.left { text-align: left; padding-left: 16px; }
    td.dept { color: var(--brand); font-weight: 600; }
    td.sub, th.sub { border-left: 1px solid var(--border); font-weight: 700; color: var(--text); background: #fafafa; }
    td.zero { color: #b0adab; }
    tfoot td {
        padding: 9px 12px; text-align: right; font-weight: 700;
        background: var(--brand-light); color: var(--navy);
        border-top: 2px solid var(--border-strong);
        white-space: nowrap;
    }
    tfoot td.left { text-align: left; padding-left: 16px; }

    .empty {
        padding: 36px 16px; text-align: center; color: var(--text-weaker);
    }
    .empty i { font-size: 28px; color: var(--border-strong); display: block; margin-bottom: 8px; }

    @media (max-width: 1100px) {
        .chart-grid { grid-template-columns: 1fr; }
        .kpi-grid { grid-template-columns: 1fr 1fr; }
    }
    @media (max-width: 600px) {
        .kpi-grid { grid-template-columns: 1fr; }
        .filter-panel select { min-width: 100%; }
        .field { width: 100%; }
    }
</style>
</head>
<body>
<jsp:include page="header.jsp" />

<div class="container">

    <!-- Page header -->
    <div class="page-header">
        <div class="ph-left">
            <div class="ph-icon"><i class="fas fa-warehouse"></i></div>
            <div>
                <p class="ph-sub">Inventory</p>
                <h1 class="ph-title"><%= greeting %>, <%= h(user.toUpperCase()) %></h1>
            </div>
        </div>
        <div class="ph-date">
            <i class="far fa-calendar-alt"></i><%= new SimpleDateFormat("EEEE, dd MMMM yyyy").format(new Date()) %>
        </div>
    </div>

    <!-- Today's cost by department -->
    <div class="card">
        <div class="card-header">
            <h3 class="card-title">
                
                Today's cost by department
            </h3>
            <span class="today-total">Total today<b><%= inr.format(todayTotal) %></b></span>
        </div>
        <div class="card-body">
        <% if (todayDeptMap.isEmpty()) { %>
            <div class="empty" style="padding:12px 0;">No stock issued today yet.</div>
        <% } else { %>
            <div class="today-grid">
            <% for (Map.Entry<String, Double> e : todayDeptMap.entrySet()) { %>
                <div class="today-tile">
                    <p class="t-dept" title="<%= h(e.getKey()) %>"><%= h(e.getKey()) %></p>
                    <p class="t-val"><%= inr.format(e.getValue()) %></p>
                </div>
            <% } %>
            </div>
        <% } %>
        </div>
    </div>

    <!-- Filters -->
    <form class="filter-panel" method="get" action="Home">
        <div class="field">
            <label for="department">Department</label>
            <select id="department" name="department">
                <option value="All">All Departments</option>
                <% for (String d : departments) { %>
                    <option value="<%= h(d) %>" <%= d.equals(selectedDept) ? "selected" : "" %>><%= h(d) %></option>
                <% } %>
            </select>
        </div>
        <div class="field">
            <label for="year">Financial Year</label>
            <select id="year" name="year">
                <% for (String y : years) { %>
                    <option value="<%= h(y) %>" <%= y.equals(selectedYear) ? "selected" : "" %>><%= h(y) %></option>
                <% } %>
            </select>
        </div>
        <button type="submit" class="btn-brand"><i class="fas fa-sync-alt"></i>Update view</button>
    </form>

    <!-- KPI tiles -->
    <div class="kpi-grid">
        <div class="kpi">
            <p class="k-label">Active departments</p>
            <p class="k-value"><%= totalRows %></p>
            <p class="k-note">FY <%= h(selectedYear) %></p>
        </div>
        <div class="kpi">
            <p class="k-label">Total expenditure</p>
            <p class="k-value"><%= inr.format(grandTotal) %></p>
            <p class="k-note">Apr – Mar</p>
        </div>
        <div class="kpi">
            <p class="k-label">Highest month</p>
            <p class="k-value"><%= peakIdx >= 0 ? monthNames[peakIdx] : "—" %></p>
            <p class="k-note"><%= peakIdx >= 0 ? inr.format(peakVal) : "No data" %></p>
        </div>
        <div class="kpi">
            <p class="k-label">Top department</p>
            <p class="k-value" style="font-size:20px;"><%= h(topDept) %></p>
            <p class="k-note"><%= topDeptVal > 0 ? inr.format(topDeptVal) : "No data" %></p>
        </div>
    </div>

    <!-- Charts -->
    <div class="chart-grid">
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">
                    <span class="ti" style="background:#0176d3;"><i class="fas fa-chart-bar"></i></span>
                    Departmental consumption (₹)
                </h3>
            </div>
            <div class="card-body">
                <div class="scroll-chart">
                    <div id="deptChartWrapper"><canvas id="deptChart"></canvas></div>
                </div>
            </div>
        </div>
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">
                    <span class="ti" style="background:#fe9339;"><i class="fas fa-chart-line"></i></span>
                    Monthly trend
                </h3>
                <span class="card-meta">FY <%= h(selectedYear) %></span>
            </div>
            <div class="card-body">
                <div style="height:360px;"><canvas id="monthChart"></canvas></div>
            </div>
        </div>
    </div>

    <!-- Month-wise table -->
    <div class="card">
        <div class="card-header">
            <h3 class="card-title">
                <span class="ti" style="background:#2e844a;"><i class="fas fa-table"></i></span>
                Month-wise expenditure
            </h3>
            <span class="card-meta"><%= dataMap.size() %> department<%= dataMap.size() == 1 ? "" : "s" %> · FY <%= h(selectedYear) %></span>
        </div>
        <% if (dataMap.isEmpty()) { %>
            <div class="empty">
                <i class="far fa-folder-open"></i>
                No expenditure found for this department and financial year. Try a different selection.
            </div>
        <% } else { %>
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th class="left">Department</th>
                        <% for (String m : monthNames) { %><th><%= h(m) %></th><% } %>
                        <th class="sub">Subtotal</th>
                    </tr>
                </thead>
                <tbody>
                <% for (Map.Entry<String, double[]> entry : dataMap.entrySet()) {
                       double total = 0; %>
                    <tr>
                        <td class="left dept"><%= h(entry.getKey()) %></td>
                        <% for (double val : entry.getValue()) { total += val; %>
                            <td class="<%= val > 0 ? "" : "zero" %>"><%= val > 0 ? String.format("%,.0f", val) : "—" %></td>
                        <% } %>
                        <td class="sub"><%= String.format("%,.2f", total) %></td>
                    </tr>
                <% } %>
                </tbody>
                <tfoot>
                    <tr>
                        <td class="left">Total</td>
                        <% for (double v : monthTotals) { %><td><%= v > 0 ? String.format("%,.0f", v) : "—" %></td><% } %>
                        <td><%= String.format("%,.2f", grandTotal) %></td>
                    </tr>
                </tfoot>
            </table>
        </div>
        <% } %>
    </div>
</div>

<script>
(function () {
    var dLabels = [<%= dLabels %>];
    var dValues = [<%= dValues %>];
    var mLabels = [<%= mLabels %>];
    var mValues = [<%= mValues %>];

    var font = { family: '"Salesforce Sans", -apple-system, "Segoe UI", Roboto, Arial, sans-serif', size: 11 };
    var inr = function (v) { return '₹' + Number(v).toLocaleString('en-IN'); };
    Chart.defaults.font.family = font.family;
    Chart.defaults.color = '#444444';

    var tooltip = {
        backgroundColor: '#032d60',
        padding: 10,
        cornerRadius: 4,
        displayColors: false,
        callbacks: { label: function (c) { return inr((c.parsed.x !== undefined && c.chart.options.indexAxis === 'y') ? c.parsed.x : c.parsed.y); } }
    };

    var wrap = document.getElementById('deptChartWrapper');
    wrap.style.height = Math.max(340, dLabels.length * 34) + 'px';

    new Chart(document.getElementById('deptChart'), {
        type: 'bar',
        data: {
            labels: dLabels,
            datasets: [{ data: dValues, backgroundColor: '#0176d3', hoverBackgroundColor: '#014486', borderRadius: 2, barThickness: 16 }]
        },
        options: {
            indexAxis: 'y',
            maintainAspectRatio: false,
            responsive: true,
            plugins: { legend: { display: false }, tooltip: tooltip },
            scales: {
                x: { grid: { color: '#e5e5e5' }, ticks: { font: font, callback: function (v) { return inr(v); } } },
                y: { grid: { display: false }, ticks: { autoSkip: false, font: { family: font.family, size: 11, weight: '600' } } }
            }
        }
    });

    new Chart(document.getElementById('monthChart'), {
        type: 'line',
        data: {
            labels: mLabels,
            datasets: [{
                data: mValues,
                borderColor: '#0176d3',
                backgroundColor: 'rgba(1,118,211,0.08)',
                fill: true,
                tension: 0.25,
                borderWidth: 2,
                pointRadius: 4,
                pointHoverRadius: 6,
                pointBackgroundColor: '#ffffff',
                pointBorderColor: '#0176d3',
                pointBorderWidth: 2
            }]
        },
        options: {
            maintainAspectRatio: false,
            responsive: true,
            plugins: { legend: { display: false }, tooltip: tooltip },
            scales: {
                y: { beginAtZero: true, grid: { color: '#e5e5e5' }, ticks: { font: font, callback: function (v) { return inr(v); } } },
                x: { grid: { display: false }, ticks: { font: font } }
            }
        }
    });
})();
</script>
</body>
</html>
