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
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Dining Hall Analytics Dashboard</title>


<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<link href="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.11/index.global.min.css" rel="stylesheet"/>
<script src="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.11/index.global.min.js"></script>

<style>
body {
    font-family: 'Poppins', sans-serif;
    background: linear-gradient(135deg, #e0f7fa, #e8f5e9);
    margin: 0;
    padding: 0;
}
.content {
    margin-left: 260px;
    width: calc(100% - 260px);
    padding: 90px 30px 30px;
    display: flex;
    flex-direction: column;
    align-items: center;
}


h2 {
    text-align: center;
    color: #2d3436;
    margin-bottom: 30px;
    font-weight: 600;
    letter-spacing: 1px;
}


.summary {
    display: flex;
    flex-wrap: wrap;
    gap: 25px;
    justify-content: center;
    margin-bottom: 40px;
}
.card {
    background: white;
    border-radius: 20px;
    box-shadow: 0 6px 20px rgba(0,0,0,0.1);
    width: 220px;
    padding: 25px;
    text-align: center;
    transition: 0.3s;
}
.card:hover { transform: scale(1.05); }
.card h3 {
    font-size: 15px;
    color: #777;
}
.card p {
    font-size: 22px;
    font-weight: bold;
    color: #007bff;
    margin: 0;
}


.chart-container {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 40px;
    margin-bottom: 60px;
}
.chart-box {
    background: white;
    border-radius: 20px;
    box-shadow: 0 4px 15px rgba(0,0,0,0.1);
    padding: 20px 30px;
    width: 500px;
}


.calendar-container {
    background: white;
    border-radius: 25px;
    box-shadow: 0 8px 25px rgba(0,0,0,0.15);
    padding: 50px 40px;
    width: 95%;
    max-width: 1220px;
    margin: 0 auto 80px;
    border: 2px solid #007bff30;
    display: flex;
    flex-direction: column;
    align-items: center;
}


.fc {
    border-radius: 20px;
    overflow: hidden;
    width: 100%;
    background-color: #fdfefe;
    padding: 15px;
}
.fc .fc-scrollgrid {
    border-radius: 16px;
    box-shadow: 0 3px 12px rgba(0,0,0,0.08);
}
.fc-toolbar { justify-content: center !important; }
.fc-toolbar-title { font-size: 22px !important; color: #2d3436 !important; }
.fc-button {
    border-radius: 8px !important;
    background: #007bff !important;
    border: none !important;
}
.fc-button:hover { background: #0056b3 !important; }


.fc-event-title {
    display: block;
    border-radius: 10px;
    margin: 4px 0;
    font-size: 12px;
    font-weight: 600;
    color: #fff;
    text-align: center;
    box-shadow: 0 3px 8px rgba(0,0,0,0.25);
    transition: all 0.25s ease;
}
.fc-event-title.breakfast {
    background: linear-gradient(135deg, #6ec6ff, #0984e3);
}
.fc-event-title.lunch {
    background: linear-gradient(135deg, #ffb347, #ff7f50);
}
.fc-event-title.dinner {
    background: linear-gradient(135deg, #00b894, #00cec9);
}
.fc-event-title.total {
    background: linear-gradient(135deg, #6c5ce7, #a29bfe);
    font-weight: 700;
    font-size: 13px;
}


.filter-box { text-align: center; margin-bottom: 30px; }
input[type="date"], button {
    padding: 10px 15px;
    border-radius: 8px;
    border: 1px solid #ccc;
    margin: 5px;
}
button {
    background: #007bff;
    color: white;
    cursor: pointer;
    border: none;
    transition: 0.3s;
}
button:hover { background: #0056b3; }

@media (max-width: 992px) {
    .content { margin-left: 0; width: 100%; padding-top: 80px; }
    .chart-box { width: 90%; }
}
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="content">
<h2><i class="fas fa-chart-line"></i> Dining Hall Analytics Dashboard</h2>

<%
Connection con = null;
double todayCost = 0, weekCost = 0, monthCost = 0, totalCost = 0;
Map<String, Double> dayWise = new LinkedHashMap<>();
Map<String, Map<String, Double>> sessionWise = new LinkedHashMap<>();

try {
    con = DBUtil.getConnection();
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

    // 🥣 Session-wise cost (merge Morning Drink with Breakfast)
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
    out.println("<p style='color:red;text-align:center;'>Error: "+e.getMessage()+"</p>");
} finally { if (con != null) con.close(); }
%>


<div class="filter-box">
    <form method="post">
        <label>From:</label>
        <input type="date" name="fromDate" value="<%= request.getParameter("fromDate") != null ? request.getParameter("fromDate") : "" %>">
        <label>To:</label>
        <input type="date" name="toDate" value="<%= request.getParameter("toDate") != null ? request.getParameter("toDate") : "" %>">
        <button type="submit"><i class="fas fa-filter"></i> Filter</button>
    </form>
</div>


<div class="summary">
    <div class="card"><h3>Today</h3><p>₹ <%= String.format("%.2f", todayCost) %></p></div>
    <div class="card"><h3>This Week</h3><p>₹ <%= String.format("%.2f", weekCost) %></p></div>
    <div class="card"><h3>This Month</h3><p>₹ <%= String.format("%.2f", monthCost) %></p></div>
    <div class="card"><h3>Total</h3><p>₹ <%= String.format("%.2f", totalCost) %></p></div>
</div>


<div class="chart-container">
    <div class="chart-box">
        <h4 style="text-align:center;">📅 Day-wise Cost</h4>
        <canvas id="dayChart"></canvas>
    </div>
    <div class="chart-box">
        <h4 style="text-align:center;">🍽 Session-wise Cost (Latest Day)</h4>
        <canvas id="sessionChart"></canvas>
    </div>
</div>


<div class="calendar-container">
    <h4 style="text-align:center;">🗓 Dining Hall Calendar (Session-wise & Total Cost)</h4>
    <div id="diningCalendar"></div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const dayLabels = [<% for(String d : dayWise.keySet()) { %>"<%= d %>", <% } %>];
    const dayData = [<% for(Double val : dayWise.values()) { %><%= val %>, <% } %>];
    new Chart(document.getElementById('dayChart'), {
        type: 'bar',
        data: { labels: dayLabels, datasets: [{ label: '₹ Cost', data: dayData, backgroundColor: '#74b9ff' }] },
        options: { plugins: { legend: { display: false } } }
    });

    <% String lastDay = sessionWise.isEmpty() ? "" : new ArrayList<>(sessionWise.keySet()).get(sessionWise.size()-1);
       Map<String, Double> latest = lastDay.isEmpty() ? new HashMap<>() : sessionWise.get(lastDay); %>
    const sessionLabels = [<% for(String s : latest.keySet()) { %>"<%= s %>", <% } %>];
    const sessionData = [<% for(Double v : latest.values()) { %><%= v %>, <% } %>];
    new Chart(document.getElementById('sessionChart'), {
        type: 'doughnut',
        data: { labels: sessionLabels, datasets: [{ data: sessionData, backgroundColor: ['#74b9ff','#ffa502','#2ed573'] }] },
        options: { plugins: { legend: { position: 'bottom' } } }
    });

    var calendarEl = document.getElementById('diningCalendar');
    var calendar = new FullCalendar.Calendar(calendarEl, {
        initialView: 'dayGridMonth',
        height: 700,
        expandRows: true,
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
