<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%!
    // HTML-escape for text/attributes[cite: 1]
    private static String h(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
    // Escape for JS string literals[cite: 1]
    private static String js(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("'", "\\'")
                .replace("\n", " ").replace("\r", " ").replace("<", "\\u003c");
    }
    // Indian digit grouping (12,34,56,789) - java.text.DecimalFormat cannot do this
    private static String fmtIN(double v, int decimals) {
        java.math.BigDecimal bd = new java.math.BigDecimal(v).setScale(decimals, java.math.RoundingMode.HALF_UP);
        boolean neg = bd.signum() < 0;
        String s = bd.abs().toPlainString();
        String frac = "";
        int dot = s.indexOf('.');
        if (dot >= 0) { frac = s.substring(dot); s = s.substring(0, dot); }
        if (s.length() > 3) {
            String last3 = s.substring(s.length() - 3);
            String rest = s.substring(0, s.length() - 3);
            StringBuilder sb = new StringBuilder();
            int first = rest.length() % 2;
            if (first > 0) sb.append(rest, 0, first);
            for (int i = first; i < rest.length(); i += 2) {
                if (sb.length() > 0) sb.append(',');
                sb.append(rest, i, i + 2);
            }
            s = sb.append(',').append(last3).toString();
        }
        return (neg ? "-" : "") + s + frac;
    }
    private static String rupee(double v)  { return "\u20B9" + fmtIN(v, 0); }
    private static String indInt(double v) { return fmtIN(v, 0); }
    private static String indDec(double v) { return fmtIN(v, 2); }
%>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // This page needs the date-range totals prepared by the Home servlet.
    // Route direct Home.jsp requests through the servlet before rendering.
    if (request.getAttribute("last30DaysDeptMap") == null) {
        response.sendRedirect(request.getContextPath() + "/Home");
        return;
    }

    String user = (String) sess.getAttribute("username");

    @SuppressWarnings("unchecked")
    Map<String, Double> todayDeptMap = (Map<String, Double>) request.getAttribute("todayDeptMap");
    Double tt = (Double) request.getAttribute("todayTotal");
    if (todayDeptMap == null) todayDeptMap = new LinkedHashMap<String, Double>();
    double todayTotal = tt != null ? tt : 0;

    @SuppressWarnings("unchecked")
    Map<String, Double> last7DaysDeptMap = (Map<String, Double>) request.getAttribute("last7DaysDeptMap");
    Double l7t = (Double) request.getAttribute("last7DaysTotal");
    if (last7DaysDeptMap == null) last7DaysDeptMap = new LinkedHashMap<String, Double>();
    double last7DaysTotal = l7t != null ? l7t : 0;

    @SuppressWarnings("unchecked")
    Map<String, Double> last30DaysDeptMap = (Map<String, Double>) request.getAttribute("last30DaysDeptMap");
    Double l30t = (Double) request.getAttribute("last30DaysTotal");
    if (last30DaysDeptMap == null) last30DaysDeptMap = new LinkedHashMap<String, Double>();
    double last30DaysTotal = l30t != null ? l30t : 0;

    @SuppressWarnings("unchecked")
    Map<String, Double> last6MonthsDeptMap = (Map<String, Double>) request.getAttribute("last6MonthsDeptMap");
    Double l6mt = (Double) request.getAttribute("last6MonthsTotal");
    if (last6MonthsDeptMap == null) last6MonthsDeptMap = new LinkedHashMap<String, Double>();
    double last6MonthsTotal = l6mt != null ? l6mt : 0;

    @SuppressWarnings("unchecked")
    Map<String, Double> thisYearDeptMap = (Map<String, Double>) request.getAttribute("thisYearDeptMap");
    Double tyt = (Double) request.getAttribute("thisYearTotal");
    if (thisYearDeptMap == null) thisYearDeptMap = new LinkedHashMap<String, Double>();
    double thisYearTotal = tyt != null ? tyt : 0;
    String thisYearFrom = (String) request.getAttribute("thisYearFrom");
    if (thisYearFrom == null) thisYearFrom = "1 Apr";

    @SuppressWarnings("unchecked")
    List<String> departments = (List<String>) request.getAttribute("departments");
    @SuppressWarnings("unchecked")
    List<String> years = (List<String>) request.getAttribute("years");
    @SuppressWarnings("unchecked")
    Map<String, double[]> dataMap = (Map<String, double[]>) request.getAttribute("dataMap");
    // Financial year months, always April to March[cite: 1]
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

    // Greeting[cite: 1]
    int hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY);
    String greeting = hour < 12 ? "Good morning" : (hour < 17 ? "Good afternoon" : "Good evening");

    // Aggregates for KPIs and charts[cite: 1]
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

    // JSON-ish arrays for Chart.js[cite: 1]
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
    :root {
        --accent: #2f6fb3;
        --accent-hover: #255a94;
        --accent-soft: #edf4fb;
        --bg: #f4f6f9;
        --surface: #ffffff;
        --surface-2: #f8fafc;
        --head: #f1f5f9;
        --border: #dde3ea;
        --border-strong: #c3ccd6;
        --text-heading: #1f2a37;
        --text-body: #374151;
        --text-muted: #667085;
        --radius: 4px;
        --focus: 0 0 0 3px rgba(47,111,179,0.18);
    }
    *, *::before, *::after { box-sizing: border-box; }
    body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
        background: var(--bg);
        color: var(--text-body);
        margin: 0;
        font-size: 13px;
        line-height: 1.45;
        -webkit-font-smoothing: antialiased;
        font-variant-numeric: tabular-nums;
    }
    .container { width: 100%; max-width: 1600px; margin: 0 auto; padding: 14px 18px 28px; }

    /* ---------- Header ---------- */
    .page-header {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        padding: 10px 16px;
        display: flex; justify-content: space-between; align-items: center;
        gap: 12px; margin-bottom: 12px; flex-wrap: wrap;
    }
    .ph-left { display: flex; align-items: center; gap: 12px; }
    .ph-icon {
        width: 34px; height: 34px; border-radius: var(--radius);
        background: var(--accent-soft); color: var(--accent);
        display: flex; align-items: center; justify-content: center;
        font-size: 15px; flex-shrink: 0;
    }
    .ph-sub { font-size: 11px; font-weight: 600; color: var(--text-muted); margin: 0; letter-spacing: 0.02em; }
    .ph-title { font-size: 17px; font-weight: 600; margin: 0; color: var(--text-heading); line-height: 1.25; }
    .ph-date {
        font-size: 12px; font-weight: 500; color: var(--text-body);
        border: 1px solid var(--border); border-radius: var(--radius);
        padding: 5px 10px; background: var(--surface-2); white-space: nowrap;
    }
    .ph-date i { color: var(--accent); margin-right: 6px; }

    /* ---------- Cards ---------- */
    .card {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        margin-bottom: 12px;
        overflow: hidden;
    }
    .card-header {
        padding: 8px 14px;
        display: flex; align-items: center; justify-content: space-between;
        gap: 10px; flex-wrap: wrap;
        background: var(--surface-2);
        border-bottom: 1px solid var(--border);
        min-height: 46px;
    }
    .card-title {
        margin: 0; font-size: 13.5px; font-weight: 600; color: var(--text-heading);
        display: flex; align-items: center; gap: 8px;
    }
    .card-title .ti {
        width: 22px; height: 22px; border-radius: var(--radius);
        display: inline-flex; align-items: center; justify-content: center;
        background: var(--accent-soft); color: var(--accent); font-size: 11px;
    }
    .card-meta { font-size: 12px; color: var(--text-muted); }
    .card-body { padding: 14px; }

    /* ---------- Tabs ---------- */
    .tab-header {
        display: inline-flex; align-items: center; gap: 2px;
        background: var(--head);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        padding: 2px; overflow-x: auto; max-width: 100%;
    }
    .tab-btn {
        background: none; border: 1px solid transparent;
        padding: 5px 12px; font-size: 12.5px; font-weight: 500; font-family: inherit;
        color: var(--text-muted); cursor: pointer;
        display: flex; align-items: center; gap: 6px; white-space: nowrap;
        border-radius: 3px;
    }
    .tab-btn i { font-size: 11px; }
    .tab-btn:hover { color: var(--text-heading); }
    .tab-btn.active { background: var(--surface); color: var(--accent); font-weight: 600; border-color: var(--border); }
    .tab-btn:focus-visible { outline: none; box-shadow: var(--focus); }
    .tab-content { display: none; }
    .tab-content.active { display: block; }

    /* ---------- Period tiles ---------- */
    .today-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 10px; }
    .today-tile {
        border: 1px solid var(--border);
        border-radius: var(--radius);
        padding: 9px 12px;
        background: var(--surface);
    }
    .today-tile .t-dept {
        font-size: 12px; color: var(--text-muted); margin: 0 0 2px;
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .today-tile .t-val { font-size: 17px; font-weight: 600; color: var(--text-heading); margin: 0; }
    .today-total { font-size: 12.5px; color: var(--text-muted); display: flex; align-items: baseline; }
    .today-total b { font-size: 16px; font-weight: 600; color: var(--text-heading); margin-left: 8px; }

    /* ---------- Filters ---------- */
    .filter-panel {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        padding: 10px 14px; margin-bottom: 12px;
        display: flex; align-items: flex-end; gap: 12px; flex-wrap: wrap;
    }
    .field { display: flex; flex-direction: column; gap: 4px; }
    .field label { font-size: 12px; font-weight: 500; color: var(--text-muted); }
    .filter-panel select {
        height: 32px; min-width: 210px; padding: 0 10px;
        border: 1px solid var(--border-strong); border-radius: var(--radius);
        background: var(--surface); color: var(--text-heading);
        font-size: 13px; font-family: inherit; cursor: pointer;
    }
    .filter-panel select:hover { border-color: var(--accent); }
    .filter-panel select:focus { outline: none; border-color: var(--accent); box-shadow: var(--focus); }
    .btn-brand {
        height: 32px; padding: 0 16px;
        background: var(--accent); color: #fff;
        border: 1px solid var(--accent); border-radius: var(--radius);
        font-size: 13px; font-weight: 600; font-family: inherit; cursor: pointer;
        display: inline-flex; align-items: center; justify-content: center;
    }
    .btn-brand:hover { background: var(--accent-hover); border-color: var(--accent-hover); }
    .btn-brand:focus-visible { outline: none; box-shadow: var(--focus); }
    .btn-brand i { margin-right: 6px; }

    /* ---------- KPIs ---------- */
    .kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px; }
    .kpi {
        background: var(--surface);
        border: 1px solid var(--border);
        border-left: 3px solid var(--accent);
        border-radius: var(--radius);
        padding: 12px 16px;
    }
    .kpi .k-label { font-size: 12px; font-weight: 500; color: var(--text-muted); margin: 0 0 4px; }
    .kpi .k-value { font-size: 23px; font-weight: 600; color: var(--text-heading); margin: 0; line-height: 1.15; word-break: break-word; }
    .kpi .k-note { font-size: 12px; color: var(--text-muted); margin: 4px 0 0; }

    .chart-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    .scroll-chart { height: 340px; overflow-y: auto; }

    /* ---------- Table ---------- */
    .table-container { overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    thead th {
        background: var(--head);
        color: var(--text-muted);
        font-weight: 600; font-size: 12px;
        text-align: right;
        padding: 8px 10px;
        border-bottom: 1px solid var(--border-strong);
        white-space: nowrap;
    }
    tbody td {
        padding: 7px 10px; text-align: right;
        border-bottom: 1px solid var(--border);
        color: var(--text-body); white-space: nowrap;
    }
    tbody tr:nth-child(even) td { background: var(--surface-2); }
    tbody tr:hover td { background: var(--accent-soft); }
    th.left, td.left { text-align: left; padding-left: 14px; }
    td.dept { color: var(--text-heading); font-weight: 600; }
    td.sub, th.sub { border-left: 1px solid var(--border); font-weight: 600; color: var(--text-heading); }
    td.zero { color: #b5bdc8; }
    tfoot td {
        padding: 9px 10px; text-align: right; font-weight: 600;
        background: var(--head); color: var(--text-heading);
        border-top: 1px solid var(--border-strong);
        white-space: nowrap;
    }
    tfoot td.left { text-align: left; padding-left: 14px; }

    .empty { padding: 30px 16px; text-align: center; color: var(--text-muted); }
    .empty i { font-size: 24px; color: var(--border-strong); display: block; margin-bottom: 8px; }

    @media (max-width: 1100px) {
        .chart-grid { grid-template-columns: 1fr; }
        .kpi-grid { grid-template-columns: repeat(2, 1fr); }
    }
    @media (max-width: 600px) {
        .container { padding: 8px; }
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

    <!-- Multi-Period Cost Card with Tabs -->
    <div class="card">
        <div class="card-header">
            <div class="tab-header">
                <button type="button" class="tab-btn active" onclick="switchTab(event, 'todayTab')">
                    <i class="fas fa-calendar-day"></i> Today
                </button>
                <button type="button" class="tab-btn" onclick="switchTab(event, 'last7DaysTab')">
                    <i class="fas fa-calendar-week"></i> Last 7 Days
                </button>
                <button type="button" class="tab-btn" onclick="switchTab(event, 'last30DaysTab')">
                    <i class="fas fa-calendar-alt"></i> Last 30 Days
                </button>
                <button type="button" class="tab-btn" onclick="switchTab(event, 'last6MonthsTab')">
                    <i class="fas fa-clock"></i> Last 6 Months
                </button>
                <button type="button" class="tab-btn" onclick="switchTab(event, 'thisYearTab')">
                    <i class="fas fa-calendar"></i> This Year
                </button>
            </div>
            <div>
                <span class="today-total period-total" id="todayTotalLabel">Total today<b><%= rupee(todayTotal) %></b></span>
                <span class="today-total period-total" id="last7DaysTotalLabel" style="display: none;">Total last 7 days<b><%= rupee(last7DaysTotal) %></b></span>
                <span class="today-total period-total" id="last30DaysTotalLabel" style="display: none;">Total last 30 days<b><%= rupee(last30DaysTotal) %></b></span>
                <span class="today-total period-total" id="last6MonthsTotalLabel" style="display: none;">Total last 6 months<b><%= rupee(last6MonthsTotal) %></b></span>
                <span class="today-total period-total" id="thisYearTotalLabel" style="display: none;">Total since <%= thisYearFrom %><b><%= rupee(thisYearTotal) %></b></span>
            </div>
        </div>
        <div class="card-body">
            <!-- Today Tab Content -->
            <div id="todayTab" class="tab-content active">
                <% if (todayDeptMap.isEmpty()) { %>
                    <div class="empty" style="padding:12px 0;">No stock issued today yet.</div>
                <% } else { %>
                    <div class="today-grid">
                    <% for (Map.Entry<String, Double> e : todayDeptMap.entrySet()) { %>
                        <div class="today-tile">
                            <p class="t-dept" title="<%= h(e.getKey()) %>"><%= h(e.getKey()) %></p>
                            <p class="t-val"><%= rupee(e.getValue()) %></p>
                        </div>
                    <% } %>
                    </div>
                <% } %>
            </div>

            <!-- Last 7 Days Tab Content -->
            <div id="last7DaysTab" class="tab-content">
                <% if (last7DaysDeptMap.isEmpty()) { %>
                    <div class="empty" style="padding:12px 0;">No stock issued in the last 7 days.</div>
                <% } else { %>
                    <div class="today-grid">
                    <% for (Map.Entry<String, Double> e : last7DaysDeptMap.entrySet()) { %>
                        <div class="today-tile">
                            <p class="t-dept" title="<%= h(e.getKey()) %>"><%= h(e.getKey()) %></p>
                            <p class="t-val"><%= rupee(e.getValue()) %></p>
                        </div>
                    <% } %>
                    </div>
                <% } %>
            </div>

            <!-- Last 30 Days Tab Content -->
            <div id="last30DaysTab" class="tab-content">
                <% if (last30DaysDeptMap.isEmpty()) { %>
                    <div class="empty" style="padding:12px 0;">No stock issued in the last 30 days.</div>
                <% } else { %>
                    <div class="today-grid">
                    <% for (Map.Entry<String, Double> e : last30DaysDeptMap.entrySet()) { %>
                        <div class="today-tile">
                            <p class="t-dept" title="<%= h(e.getKey()) %>"><%= h(e.getKey()) %></p>
                            <p class="t-val"><%= rupee(e.getValue()) %></p>
                        </div>
                    <% } %>
                    </div>
                <% } %>
            </div>

            <!-- Last 6 Months Tab Content -->
            <div id="last6MonthsTab" class="tab-content">
                <% if (last6MonthsDeptMap.isEmpty()) { %>
                    <div class="empty" style="padding:12px 0;">No stock issued in the last 6 months.</div>
                <% } else { %>
                    <div class="today-grid">
                    <% for (Map.Entry<String, Double> e : last6MonthsDeptMap.entrySet()) { %>
                        <div class="today-tile">
                            <p class="t-dept" title="<%= h(e.getKey()) %>"><%= h(e.getKey()) %></p>
                            <p class="t-val"><%= rupee(e.getValue()) %></p>
                        </div>
                    <% } %>
                    </div>
                <% } %>
            </div>

            <!-- This Year Tab Content -->
            <div id="thisYearTab" class="tab-content">
                <% if (thisYearDeptMap.isEmpty()) { %>
                    <div class="empty" style="padding:12px 0;">No stock issued since <%= thisYearFrom %>.</div>
                <% } else { %>
                    <div class="today-grid">
                    <% for (Map.Entry<String, Double> e : thisYearDeptMap.entrySet()) { %>
                        <div class="today-tile">
                            <p class="t-dept" title="<%= h(e.getKey()) %>"><%= h(e.getKey()) %></p>
                            <p class="t-val"><%= rupee(e.getValue()) %></p>
                        </div>
                    <% } %>
                    </div>
                <% } %>
            </div>
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
            <p class="k-value"><%= rupee(grandTotal) %></p>
            <p class="k-note">Apr – Mar</p>
        </div>
        <div class="kpi">
            <p class="k-label">Highest month</p>
            <p class="k-value"><%= peakIdx >= 0 ? monthNames[peakIdx] : "—" %></p>
            <p class="k-note"><%= peakIdx >= 0 ? rupee(peakVal) : "No data" %></p>
        </div>
        <div class="kpi">
            <p class="k-label">Top department</p>
            <p class="k-value" style="font-size:19px;"><%= h(topDept) %></p>
            <p class="k-note"><%= topDeptVal > 0 ? rupee(topDeptVal) : "No data" %></p>
        </div>
    </div>

    <!-- Charts -->
    <div class="chart-grid">
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">
                    <span class="ti"><i class="fas fa-chart-bar"></i></span>
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
                    <span class="ti"><i class="fas fa-chart-line"></i></span>
                    Monthly trend
                </h3>
                <span class="card-meta">FY <%= h(selectedYear) %></span>
            </div>
            <div class="card-body">
                <div style="height:340px;"><canvas id="monthChart"></canvas></div>
            </div>
        </div>
    </div>

    <!-- Month-wise table -->
    <div class="card">
        <div class="card-header">
            <h3 class="card-title">
                <span class="ti"><i class="fas fa-table"></i></span>
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
                            <td class="<%= val > 0 ? "" : "zero" %>"><%= val > 0 ? indInt(val) : "—" %></td>
                        <% } %>
                        <td class="sub"><%= indDec(total) %></td>
                    </tr>
                <% } %>
                </tbody>
                <tfoot>
                    <tr>
                        <td class="left">Total</td>
                        <% for (double v : monthTotals) { %><td><%= v > 0 ? indInt(v) : "—" %></td><% } %>
                        <td><%= indDec(grandTotal) %></td>
                    </tr>
                </tfoot>
            </table>
        </div>
        <% } %>
    </div>
</div>

<script>
function switchTab(evt, tabId) {
    var i, tabContent, tabBtns;
    tabContent = document.getElementsByClassName("tab-content");
    for (i = 0; i < tabContent.length; i++) {
        tabContent[i].classList.remove("active");
    }
    tabBtns = document.getElementsByClassName("tab-btn");
    for (i = 0; i < tabBtns.length; i++) {
        tabBtns[i].classList.remove("active");
    }
    document.getElementById(tabId).classList.add("active");
    evt.currentTarget.classList.add("active");

    var totals = document.getElementsByClassName("period-total");
    for (i = 0; i < totals.length; i++) {
        totals[i].style.display = 'none';
    }

    if (tabId === 'todayTab') document.getElementById('todayTotalLabel').style.display = 'inline';
    else if (tabId === 'last7DaysTab') document.getElementById('last7DaysTotalLabel').style.display = 'inline';
    else if (tabId === 'last30DaysTab') document.getElementById('last30DaysTotalLabel').style.display = 'inline';
    else if (tabId === 'last6MonthsTab') document.getElementById('last6MonthsTotalLabel').style.display = 'inline';
    else if (tabId === 'thisYearTab') document.getElementById('thisYearTotalLabel').style.display = 'inline';
}

(function () {
    var dLabels = [<%= dLabels %>];
    var dValues = [<%= dValues %>];
    var mLabels = [<%= mLabels %>];
    var mValues = [<%= mValues %>];

    var font = { family: '"Salesforce Sans", -apple-system, "Segoe UI", Roboto, Arial, sans-serif', size: 11 };
    var inr = function (v) {
        var n = Math.round(Number(v)), neg = n < 0, s = String(Math.abs(n));
        if (s.length > 3) s = s.slice(0, -3).replace(/\B(?=(\d{2})+(?!\d))/g, ',') + ',' + s.slice(-3);
        return (neg ? '-' : '') + '\u20B9' + s;
    };
    Chart.defaults.font.family = font.family;
    Chart.defaults.color = '#667085';

    var tooltip = {
        backgroundColor: '#1f2a37',
        padding: 8,
        cornerRadius: 3,
        displayColors: false,
        callbacks: { label: function (c) { return inr((c.parsed.x !== undefined && c.chart.options.indexAxis === 'y') ? c.parsed.x : c.parsed.y); } }
    };

    var wrap = document.getElementById('deptChartWrapper');
    wrap.style.height = Math.max(320, dLabels.length * 30) + 'px';

    new Chart(document.getElementById('deptChart'), {
        type: 'bar',
        data: {
            labels: dLabels,
            datasets: [{ data: dValues, backgroundColor: '#5b94cf', hoverBackgroundColor: '#2f6fb3', borderRadius: 2, barThickness: 14 }]
        },
        options: {
            indexAxis: 'y',
            maintainAspectRatio: false,
            responsive: true,
            plugins: { legend: { display: false }, tooltip: tooltip },
            scales: {
                x: { grid: { color: '#e9edf2' }, border: { display: false }, ticks: { font: font, callback: function (v) { return inr(v); } } },
                y: { grid: { display: false }, border: { display: false }, ticks: { autoSkip: false, color: '#374151', font: { family: font.family, size: 11, weight: '500' } } }
            }
        }
    });

    new Chart(document.getElementById('monthChart'), {
        type: 'line',
        data: {
            labels: mLabels,
            datasets: [{
                data: mValues,
                borderColor: '#2f6fb3',
                backgroundColor: 'rgba(47,111,179,0.07)',
                fill: true,
                tension: 0.25,
                borderWidth: 2,
                pointRadius: 3,
                pointHoverRadius: 6,
                pointBackgroundColor: '#ffffff',
                pointBorderColor: '#2f6fb3',
                pointBorderWidth: 1.5
            }]
        },
        options: {
            maintainAspectRatio: false,
            responsive: true,
            plugins: { legend: { display: false }, tooltip: tooltip },
            scales: {
                y: { beginAtZero: true, grid: { color: '#e9edf2' }, border: { display: false }, ticks: { font: font, callback: function (v) { return inr(v); } } },
                x: { grid: { display: false }, border: { color: '#c3ccd6' }, ticks: { font: font } }
            }
        }
    });
})();
</script>
</body>
</html>
