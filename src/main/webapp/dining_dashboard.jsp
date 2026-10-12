<%@ page import="java.sql.*, java.util.*, java.text.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String user  = (String) sess.getAttribute("username");
    String role  = (String) sess.getAttribute("role");
    String dept  = (String) sess.getAttribute("department");
    String branch = (String) sess.getAttribute("branch");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Dining Hall Analytics Dashboard</title>

<!-- Fonts & Icons -->
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">

<!-- Chart.js & FullCalendar -->
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<link href="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.11/index.global.min.css" rel="stylesheet"/>
<script src="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.11/index.global.min.js"></script>

<style>
body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    background-color: #f1f5f9; /* Slate 100 */
    color: #0f172a; /* Slate 900 */
    margin: 0;
    padding: 0;
    -webkit-font-smoothing: antialiased;
}

.content {
    margin-left: 260px;
    width: calc(100% - 260px);
    padding: 32px 40px;
    box-sizing: border-box;
}

/* ----- Page Header & Filters ----- */
.dashboard-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 28px;
    background: #ffffff;
    padding: 20px 28px;
    border-radius: 8px;
    border: 1px solid #cbd5e1;
    box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
}

h2 {
    margin: 0;
    font-size: 20px;
    font-weight: 700;
    color: #1e3a8a; /* Slate/Navy accent */
    display: flex;
    align-items: center;
    gap: 12px;
}

h2 i {
    color: #3b82f6;
    font-size: 22px;
}

.filter-form {
    display: flex;
    align-items: center;
    gap: 12px;
}

.filter-group {
    display: flex;
    align-items: center;
    gap: 8px;
}

.filter-group label {
    font-size: 12px;
    font-weight: 600;
    color: #475569;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

input[type="date"] {
    padding: 8px 12px;
    border: 1px solid #94a3b8;
    border-radius: 4px;
    font-size: 13px;
    color: #0f172a;
    background-color: #ffffff;
    font-family: inherit;
    outline: none;
    transition: all 0.15s ease;
}

input[type="date"]:focus {
    border-color: #1e3a8a;
    box-shadow: 0 0 0 2px rgba(30, 58, 138, 0.15);
}

.btn-filter {
    background: #1e3a8a;
    color: #ffffff;
    border: 1px solid #1e3a8a;
    padding: 8px 16px;
    border-radius: 4px;
    font-weight: 600;
    font-size: 13px;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    transition: all 0.15s ease;
}

.btn-filter:hover {
    background: #1e40af;
}

/* ----- Metrics Grid ----- */
.summary-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 20px;
    margin-bottom: 28px;
}

.metric-card {
    background: #ffffff;
    border-radius: 8px;
    padding: 20px 24px;
    border: 1px solid #cbd5e1;
    box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
    display: flex;
    flex-direction: column;
    justify-content: space-between;
}

.metric-card .card-label {
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    color: #64748b;
    margin-bottom: 8px;
}

.metric-card .card-value {
    font-size: 24px;
    font-weight: 700;
    color: #0f172a;
    font-variant-numeric: tabular-nums;
    margin: 0;
}

/* ----- Chart Section ----- */
.chart-grid {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: 20px;
    margin-bottom: 28px;
}

.chart-card {
    background: #ffffff;
    border-radius: 8px;
    border: 1px solid #cbd5e1;
    box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
    padding: 20px 24px;
    display: flex;
    flex-direction: column;
}

.chart-card h4 {
    margin: 0 0 20px 0;
    font-size: 14px;
    font-weight: 700;
    color: #1e3a8a;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    display: flex;
    align-items: center;
    gap: 8px;
}

.chart-wrapper {
    position: relative;
    flex-grow: 1;
    min-height: 260px;
}

/* ----- Calendar Section ----- */
.calendar-card {
    background: #ffffff;
    border-radius: 8px;
    border: 1px solid #cbd5e1;
    box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
    padding: 24px;
    margin-bottom: 40px;
}

.calendar-card h4 {
    margin: 0 0 20px 0;
    font-size: 15px;
    font-weight: 700;
    color: #1e3a8a;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    display: flex;
    align-items: center;
    gap: 8px;
}

.fc {
    font-family: inherit;
    --fc-border-color: #e2e8f0;
    --fc-page-bg-color: #ffffff;
    --fc-neutral-bg-color: #f8fafc;
    --fc-today-bg-color: #f1f5f9;
}

.fc-toolbar-title {
    font-size: 16px !important;
    font-weight: 700 !important;
    color: #0f172a !important;
}

.fc-button {
    background-color: #ffffff !important;
    border: 1px solid #cbd5e1 !important;
    color: #0f172a !important;
    font-size: 13px !important;
    font-weight: 600 !important;
    border-radius: 4px !important;
    box-shadow: none !important;
    text-transform: capitalize !important;
}

.fc-button-primary:not(:disabled):hover, 
.fc-button-primary:not(:disabled).fc-button-active {
    background-color: #f1f5f9 !important;
    border-color: #94a3b8 !important;
    color: #1e3a8a !important;
}

.fc-theme-standard td, .fc-theme-standard th {
    border-color: #e2e8f0;
}

.fc-col-header-cell-cushion {
    font-size: 12px;
    font-weight: 600;
    color: #475569;
    padding: 8px 0 !important;
    text-transform: uppercase;
}

.fc-event-title {
    display: block;
    border-radius: 3px;
    margin: 2px 0;
    padding: 3px 6px;
    font-size: 11px;
    font-weight: 600;
    box-shadow: none;
    border: none;
}

/* Professional Event Badge Styling */
.fc-event-title.breakfast {
    background-color: #e0f2fe;
    color: #0369a1;
    border-left: 3px solid #0284c7;
}

.fc-event-title.lunch {
    background-color: #fef3c7;
    color: #b45309;
    border-left: 3px solid #d97706;
}

.fc-event-title.dinner {
    background-color: #dcfce7;
    color: #15803d;
    border-left: 3px solid #16a34a;
}

.fc-event-title.total {
    background-color: #1e3a8a;
    color: #ffffff;
    font-weight: 700;
}

/* Responsive adjustments */
@media (max-width: 1200px) {
    .summary-grid { grid-template-columns: repeat(2, 1fr); }
    .chart-grid { grid-template-columns: 1fr; }
}

@media (max-width: 768px) {
    .content { margin-left: 0; width: 100%; padding: 20px 16px; }
    .dashboard-header { flex-direction: column; align-items: flex-start; gap: 16px; }
    .filter-form { flex-direction: column; align-items: flex-start; width: 100%; }
    .summary-grid { grid-template-columns: 1fr; }
}
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="content">

<%
Connection con = null;
double todayCost = 0, weekCost = 0, monthCost = 0, totalCost = 0;
Map<String, Double> dayWise = new LinkedHashMap<>();
Map<String, Map<String, Double>> sessionWise = new LinkedHashMap<>();

try {
    con = DBUtil.getConnection(branch);
    Statement st = con.createStatement();

    ResultSet rs = st.executeQuery("SELECT SUM(total_value) FROM dining_hall_consumption WHERE DATE(issue_date)=CURDATE()");
    if (rs.next()) todayCost = rs.getDouble(1); rs.close();

    rs = st.executeQuery("SELECT SUM(total_value) FROM dining_hall_consumption WHERE YEARWEEK(issue_date)=YEARWEEK(CURDATE())");
    if (rs.next()) weekCost = rs.getDouble(1); rs.close();

    rs = st.executeQuery("SELECT SUM(total_value) FROM dining_hall_consumption WHERE MONTH(issue_date)=MONTH(CURDATE()) AND YEAR(issue_date)=YEAR(CURDATE())");
    if (rs.next()) monthCost = rs.getDouble(1); rs.close();

    rs = st.executeQuery("SELECT SUM(total_value) FROM dining_hall_consumption");
    if (rs.next()) totalCost = rs.getDouble(1); rs.close();

    String from = request.getParameter("fromDate");
    String to = request.getParameter("toDate");
    StringBuilder daySql = new StringBuilder("SELECT DATE(issue_date) AS day, SUM(total_value) AS total FROM dining_hall_consumption ");
    if (from != null && !from.isEmpty() && to != null && !to.isEmpty())
        daySql.append("WHERE DATE(issue_date) BETWEEN '").append(from).append("' AND '").append(to).append("' ");
    daySql.append("GROUP BY DATE(issue_date) ORDER BY DATE(issue_date)");
    rs = st.executeQuery(daySql.toString());
    while (rs.next()) { dayWise.put(rs.getString("day"), rs.getDouble("total")); }
    rs.close();

    // Session-wise cost (merge Morning Drink with Breakfast)
    rs = st.executeQuery("SELECT DATE(issue_date) AS day, session, SUM(total_value) AS total_cost FROM dining_hall_consumption GROUP BY DATE(issue_date), session ORDER BY DATE(issue_date)");
    while (rs.next()) {
        String d = rs.getString("day");
        String mealSession = rs.getString("session");
        double val = rs.getDouble("total_cost");

        // Merge logic: Combine Morning Drink + Breakfast into one
        if (mealSession.equalsIgnoreCase("Morning Drink")) mealSession = "Break Fast";

        sessionWise.putIfAbsent(d, new LinkedHashMap<>());
        sessionWise.get(d).merge(mealSession, val, Double::sum);
    }
    rs.close(); st.close();
} catch (Exception e) {
    out.println("<div style='background:#fee2e2; border:1px solid #fca5a5; color:#b91c1c; padding:12px 16px; border-radius:6px; margin-bottom:20px; font-weight:500;'>Error: "+e.getMessage()+"</div>");
} finally { if (con != null) con.close(); }
%>

<!-- Header & Filter Toolbar -->
<div class="dashboard-header">
    <h2><i class="fas fa-chart-line"></i> Dining Hall Analytics</h2>
    
    <form method="post" class="filter-form">
        <div class="filter-group">
            <label>From</label>
            <input type="date" name="fromDate" value="<%= request.getParameter("fromDate") != null ? request.getParameter("fromDate") : "" %>">
        </div>
        <div class="filter-group">
            <label>To</label>
            <input type="date" name="toDate" value="<%= request.getParameter("toDate") != null ? request.getParameter("toDate") : "" %>">
        </div>
        <button type="submit" class="btn-filter"><i class="fas fa-filter"></i> Filter</button>
    </form>
</div>

<!-- Key Performance Indicators Grid -->
<div class="summary-grid">
    <div class="metric-card">
        <div class="card-label">Today's Expense</div>
        <div class="card-value">₹ <%= String.format("%.2f", todayCost) %></div>
    </div>
    <div class="metric-card">
        <div class="card-label">This Week</div>
        <div class="card-value">₹ <%= String.format("%.2f", weekCost) %></div>
    </div>
    <div class="metric-card">
        <div class="card-label">This Month</div>
        <div class="card-value">₹ <%= String.format("%.2f", monthCost) %></div>
    </div>
    <div class="metric-card">
        <div class="card-label">Total Cumulative</div>
        <div class="card-value">₹ <%= String.format("%.2f", totalCost) %></div>
    </div>
</div>

<!-- Charts Section -->
<div class="chart-grid">
    <div class="chart-card">
        <h4><i class="fas fa-chart-bar" style="color: #3b82f6;"></i> Day-Wise Consumption Trend</h4>
        <div class="chart-wrapper">
            <canvas id="dayChart"></canvas>
        </div>
    </div>
    <div class="chart-card">
        <h4><i class="fas fa-chart-pie" style="color: #3b82f6;"></i> Session Split (Latest Day)</h4>
        <div class="chart-wrapper">
            <canvas id="sessionChart"></canvas>
        </div>
    </div>
</div>

<!-- Calendar Section -->
<div class="calendar-card">
    <h4><i class="fas fa-calendar-days" style="color: #3b82f6;"></i> Consumption Calendar Breakdown</h4>
    <div id="diningCalendar"></div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    // Chart Typography Defaults
    Chart.defaults.font.family = "'Inter', -apple-system, sans-serif";
    Chart.defaults.color = "#475569";

    // Day-wise Bar Chart
    const dayLabels = [<% for(String d : dayWise.keySet()) { %>"<%= d %>", <% } %>];
    const dayData = [<% for(Double val : dayWise.values()) { %><%= val %>, <% } %>];
    
    new Chart(document.getElementById('dayChart'), {
        type: 'bar',
        data: { 
            labels: dayLabels, 
            datasets: [{ 
                label: 'Cost (₹)', 
                data: dayData, 
                backgroundColor: '#1e3a8a',
                borderRadius: 4,
                maxBarThickness: 40
            }] 
        },
        options: { 
            responsive: true,
            maintainAspectRatio: false,
            plugins: { 
                legend: { display: false },
                tooltip: {
                    backgroundColor: '#0f172a',
                    padding: 10,
                    cornerRadius: 4,
                    displayColors: false
                }
            },
            scales: {
                x: {
                    grid: { display: false },
                    ticks: { font: { size: 11 } }
                },
                y: {
                    border: { dash: [4, 4] },
                    grid: { color: '#e2e8f0' },
                    ticks: { font: { size: 11 } }
                }
            }
        }
    });

    // Session Doughnut Chart
    <% String lastDay = sessionWise.isEmpty() ? "" : new ArrayList<>(sessionWise.keySet()).get(sessionWise.size()-1);
       Map<String, Double> latest = lastDay.isEmpty() ? new HashMap<>() : sessionWise.get(lastDay); %>
    const sessionLabels = [<% for(String s : latest.keySet()) { %>"<%= s %>", <% } %>];
    const sessionData = [<% for(Double v : latest.values()) { %><%= v %>, <% } %>];
    
    new Chart(document.getElementById('sessionChart'), {
        type: 'doughnut',
        data: { 
            labels: sessionLabels, 
            datasets: [{ 
                data: sessionData, 
                backgroundColor: ['#0284c7', '#d97706', '#16a34a', '#64748b'],
                borderWidth: 2,
                borderColor: '#ffffff'
            }] 
        },
        options: { 
            responsive: true,
            maintainAspectRatio: false,
            plugins: { 
                legend: { 
                    position: 'bottom',
                    labels: { boxWidth: 12, padding: 16, font: { size: 12, weight: 500 } }
                },
                tooltip: {
                    backgroundColor: '#0f172a',
                    padding: 10,
                    cornerRadius: 4
                }
            },
            cutout: '70%'
        }
    });

    // FullCalendar Initialization
    var calendarEl = document.getElementById('diningCalendar');
    var calendar = new FullCalendar.Calendar(calendarEl, {
        initialView: 'dayGridMonth',
        height: 720,
        expandRows: true,
        headerToolbar: {
            left: 'prev,next today',
            center: 'title',
            right: 'dayGridMonth,timeGridWeek'
        },
        events: [
        <% for (Map.Entry<String, Map<String, Double>> entry : sessionWise.entrySet()) {
               String date = entry.getKey();
               Map<String, Double> meals = entry.getValue();
               double totalDay = meals.values().stream().mapToDouble(Double::doubleValue).sum();
               for (Map.Entry<String, Double> m : meals.entrySet()) {
                   String meal = m.getKey();
                   double val = m.getValue();
                   String cls = meal.equalsIgnoreCase("Lunch") ? "lunch" :
                                meal.equalsIgnoreCase("Dinner") ? "dinner" : "breakfast";
        %>
        { title: "<%= meal %>: ₹<%= String.format("%.0f", val) %>", start: "<%= date %>", display: "block", classNames: ["<%= cls %>"] },
        <% } %>
        { title: "Total: ₹<%= String.format("%.0f", totalDay) %>", start: "<%= date %>", display: "block", classNames: ["total"] },
        <% } %>
        ],
        eventDidMount: function(info) {
            info.el.classList.add('fc-event-title', ...info.event.classNames);
        }
    });
    calendar.render();
});
</script>

</div>
</body>
</html>