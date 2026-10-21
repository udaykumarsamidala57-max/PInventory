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

    /** From / To form inside the "Between dates" tab. Keeps the department / year filters of the page. */
    private static String rangeForm(String anchor, String from, String to, String dept, String year, boolean applied) {
        StringBuilder b = new StringBuilder();
        b.append("<form class='range-form' method='get' action='home#").append(anchor).append("'>");
        if (dept != null && !dept.isEmpty()) b.append("<input type='hidden' name='department' value='").append(h(dept)).append("'>");
        if (year != null && !year.isEmpty()) b.append("<input type='hidden' name='year' value='").append(h(year)).append("'>");
        b.append("<label>From <input type='date' name='from' value='").append(h(from)).append("' required></label>");
        b.append("<label>To <input type='date' name='to' value='").append(h(to)).append("' required></label>");
        b.append("<button type='submit' class='range-apply'><i class='fas fa-filter'></i> Apply</button>");
        if (applied) {
            StringBuilder q = new StringBuilder();
            if (dept != null && !dept.isEmpty()) q.append("department=").append(java.net.URLEncoder.encode(dept, java.nio.charset.StandardCharsets.UTF_8));
            if (year != null && !year.isEmpty()) q.append(q.length() > 0 ? "&" : "").append("year=").append(java.net.URLEncoder.encode(year, java.nio.charset.StandardCharsets.UTF_8));
            b.append("<a class='range-clear' href='home").append(q.length() > 0 ? "?" + q : "").append("#").append(anchor).append("'>Clear</a>");
        }
        b.append("</form>");
        return b.toString();
    }
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
        response.sendRedirect(request.getContextPath() + "/home");
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
    Map<String, Double> last60DaysDeptMap = (Map<String, Double>) request.getAttribute("last60DaysDeptMap");
    Double l60t = (Double) request.getAttribute("last60DaysTotal");
    if (last60DaysDeptMap == null) last60DaysDeptMap = new LinkedHashMap<String, Double>();
    double last60DaysTotal = l60t != null ? l60t : 0;

    @SuppressWarnings("unchecked")
    Map<String, Double> thisYearDeptMap = (Map<String, Double>) request.getAttribute("thisYearDeptMap");
    Double tyt = (Double) request.getAttribute("thisYearTotal");
    if (thisYearDeptMap == null) thisYearDeptMap = new LinkedHashMap<String, Double>();
    double thisYearTotal = tyt != null ? tyt : 0;
    String thisYearFrom = (String) request.getAttribute("thisYearFrom");
    if (thisYearFrom == null) thisYearFrom = "1 Apr";

    // "Between dates" - the 6th period, chosen on the page (from / to)
    boolean hasRange = Boolean.TRUE.equals(request.getAttribute("hasRange"));
    String rangeFrom = (String) request.getAttribute("rangeFrom");
    String rangeTo = (String) request.getAttribute("rangeTo");
    String rangeLabel = (String) request.getAttribute("rangeLabel");
    if (rangeFrom == null) rangeFrom = "";
    if (rangeTo == null) rangeTo = "";
    if (rangeLabel == null) rangeLabel = "";
    @SuppressWarnings("unchecked")
    Map<String, Double> rangeDeptMap = (Map<String, Double>) request.getAttribute("rangeDeptMap");
    if (rangeDeptMap == null) rangeDeptMap = new LinkedHashMap<String, Double>();
    Double rgt = (Double) request.getAttribute("rangeTotal");
    double rangeTotal = rgt != null ? rgt : 0;
    final int RANGE_TAB = 5;
    int activeTab = hasRange ? RANGE_TAB : 0;      // after "Apply", the cards open on Between dates

    // Dashboard periods, in display order: This Year (from 1 April) -> 60 -> 30 -> 7 days -> Today -> Between dates
    String[] pLabels = { "This Year", "Last 60 Days", "Last 30 Days", "Last 7 Days", "Today", "Between Dates" };
    String[] pIcons  = { "fa-calendar", "fa-clock", "fa-calendar-alt", "fa-calendar-week", "fa-calendar-day", "fa-calendar-check" };
    String[] pTotalText = { "Total since " + thisYearFrom, "Total last 60 days", "Total last 30 days", "Total last 7 days", "Total today",
                            hasRange ? "Total " + rangeLabel : "Choose dates" };
    String[] pWhen = { "since " + thisYearFrom, "in the last 60 days", "in the last 30 days", "in the last 7 days", "today",
                       "between " + rangeLabel };

    // Consumption (stock issued) by department
    String[] cTabIds = { "cYearTab", "c60Tab", "c30Tab", "c7Tab", "cTodayTab", "cRangeTab" };
    List<Map<String, Double>> cMaps = Arrays.asList(thisYearDeptMap, last60DaysDeptMap, last30DaysDeptMap, last7DaysDeptMap, todayDeptMap, rangeDeptMap);
    double[] cTotals = { thisYearTotal, last60DaysTotal, last30DaysTotal, last7DaysTotal, todayTotal, rangeTotal };

    // Top 3 consumed items per department (same period order)
    List<Map<String, List<Object[]>>> topMaps = new ArrayList<Map<String, List<Object[]>>>();
    for (String k : new String[] { "topYear", "top60", "top30", "top7", "topToday", "topRange" }) {
        Map<String, List<Object[]>> m = (Map<String, List<Object[]>>) request.getAttribute(k);
        topMaps.add(m != null ? m : new LinkedHashMap<String, List<Object[]>>());
    }
    List<Map<String, List<Object[]>>> topMapsQ = new ArrayList<Map<String, List<Object[]>>>();
    for (String k : new String[] { "topYearQ", "top60Q", "top30Q", "top7Q", "topTodayQ", "topRangeQ" }) {
        Map<String, List<Object[]>> m = (Map<String, List<Object[]>>) request.getAttribute(k);
        topMapsQ.add(m != null ? m : new LinkedHashMap<String, List<Object[]>>());
    }
    String[] tTabIds = { "tYearTab", "t60Tab", "t30Tab", "t7Tab", "tTodayTab", "tRangeTab" };

    // Vendor price comparison: { itemName, uom, totalValue, List<{vendor, avgRate, lastRate, qty, poCount, lastDate}> }
    Map<String, List<Object[]>> priceByCat = (Map<String, List<Object[]>>) request.getAttribute("priceCompareByCat");
    if (priceByCat == null) priceByCat = new LinkedHashMap<String, List<Object[]>>();
    Map<String, Integer> priceCatTotals = (Map<String, Integer>) request.getAttribute("priceCatTotals");
    if (priceCatTotals == null) priceCatTotals = new LinkedHashMap<String, Integer>();

    // Vendor-wise PO value: vendor -> {value, count}
    String[] poKeys   = { "poYearMap", "po60Map", "po30Map", "po7Map", "poTodayMap", "poRangeMap" };
    String[] poTabIds = { "poYearTab", "po60Tab", "po30Tab", "po7Tab", "poTodayTab", "poRangeTab" };
    List<Map<String, double[]>> poMaps = new ArrayList<Map<String, double[]>>();
    for (String k : poKeys) {
        Map<String, double[]> m = (Map<String, double[]>) request.getAttribute(k);
        poMaps.add(m != null ? m : new LinkedHashMap<String, double[]>());
    }

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

    /* =========================================================
       Open Service Request modal  (srm-)
       Light steel-blue / slate palette - no reds, no dark tones
       ========================================================= */
    .ph-right { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
    .srm-trigger {
        display: inline-flex; align-items: center; gap: 8px;
        height: 34px; padding: 0 14px;
        background: #ffffff; color: #2f6fb3;
        border: 1px solid #c3ccd6; border-radius: 6px;
        font: inherit; font-size: 13px; font-weight: 600;
        cursor: pointer;
        transition: background .15s ease, border-color .15s ease;
    }
    .srm-trigger:hover { background: #edf4fb; border-color: #9dbbdc; }
    .srm-trigger:active { background: #e3ecf7; }
    .srm-trigger:focus-visible { outline: none; box-shadow: 0 0 0 3px rgba(47,111,179,0.35); }

    .srm-overlay {
        position: fixed; inset: 0;
        z-index: 11000;
        display: flex; align-items: center; justify-content: center;
        padding: clamp(12px, 3vw, 32px);
        background: rgba(31, 42, 55, 0.28);
        opacity: 0; visibility: hidden;
        transition: opacity .22s ease, visibility 0s linear .22s;
    }
    .srm-overlay.is-open {
        opacity: 1; visibility: visible;
        transition: opacity .22s ease, visibility 0s;
    }

    .srm-dialog {
        width: min(640px, 92vw);
        max-width: 90vw;
        max-height: 85vh;
        display: flex; flex-direction: column;
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        box-shadow: 0 24px 48px -12px rgba(15,23,42,0.28), 0 4px 12px rgba(15,23,42,0.06);
        overflow: hidden;
        transform: translateY(12px) scale(.98);
        opacity: 0;
        transition: transform .24s cubic-bezier(.2,.8,.2,1), opacity .24s ease;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
        color: #334155;
    }
    .srm-overlay.is-open .srm-dialog { transform: none; opacity: 1; }

    /* everything inside wraps - never scrolls sideways */
    .srm-dialog, .srm-dialog * {
        word-wrap: break-word;
        overflow-wrap: anywhere;
        white-space: normal;
        min-width: 0;
    }

    .srm-head {
        display: flex; align-items: flex-start; justify-content: space-between; gap: 12px;
        padding: clamp(16px, 2.5vw, 22px) clamp(16px, 3vw, 24px) 14px;
        border-bottom: 1px solid #eef2f7;
    }
    .srm-head-main { display: flex; align-items: center; gap: 12px; }
    .srm-head-icon {
        width: 40px; height: 40px; flex-shrink: 0;
        border-radius: 10px;
        background: #edf4fb; color: #2f6fb3;
        display: flex; align-items: center; justify-content: center;
        font-size: 16px;
    }
    .srm-title { margin: 0; font-size: clamp(16px, 2.2vw, 18px); font-weight: 700; color: #0f172a; line-height: 1.3; }
    .srm-subtitle { margin: 2px 0 0; font-size: 12.5px; color: #64748b; }
    .srm-close {
        width: 34px; height: 34px; flex-shrink: 0;
        display: inline-flex; align-items: center; justify-content: center;
        background: transparent; border: 1px solid transparent; border-radius: 8px;
        color: #64748b; font-size: 16px; cursor: pointer;
        transition: background .15s ease, color .15s ease, border-color .15s ease;
    }
    .srm-close:hover { background: #f1f5f9; color: #0f172a; border-color: #e2e8f0; }
    .srm-close:focus-visible { outline: none; box-shadow: 0 0 0 3px rgba(47,111,179,0.30); }

    .srm-body {
        flex: 1 1 auto;
        overflow-y: auto;
        overflow-x: hidden;
        padding: clamp(16px, 3vw, 24px);
    }
    #srmForm { display: flex; flex-direction: column; flex: 1 1 auto; min-height: 0; }
    .srm-body { min-height: 0; }
    .srm-head, .srm-foot { flex-shrink: 0; }
    .srm-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
    .srm-field { display: flex; flex-direction: column; gap: 6px; }
    .srm-full { grid-column: 1 / -1; }
    .srm-label { font-size: 12.5px; font-weight: 600; color: #334155; }
    .srm-label .srm-req { color: #2f6fb3; margin-left: 2px; }
    .srm-input, .srm-select, .srm-textarea {
        width: 100%;
        padding: 9px 12px;
        background: #ffffff;
        border: 1px solid #cbd5e1;
        border-radius: 8px;
        font: inherit; font-size: 14px; color: #0f172a;
        outline: none;
        transition: border-color .15s ease, box-shadow .15s ease, background .15s ease;
    }
    .srm-input, .srm-select { height: 40px; }
    .srm-select {
        -webkit-appearance: none; appearance: none;
        padding-right: 34px; cursor: pointer;
        background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='6' viewBox='0 0 10 6'><path fill='%2364748b' d='M0 0l5 5 5-5z'/></svg>");
        background-repeat: no-repeat; background-position: right 12px center;
    }
    .srm-textarea { min-height: 120px; resize: vertical; line-height: 1.5; }
    .srm-input::placeholder, .srm-textarea::placeholder { color: #94a3b8; }
    .srm-input:hover, .srm-select:hover, .srm-textarea:hover { border-color: #94a3b8; }
    .srm-input:focus, .srm-select:focus, .srm-textarea:focus {
        border-color: #2f6fb3;
        box-shadow: 0 0 0 3px rgba(47,111,179,0.18);
    }
    .srm-field.has-error .srm-input,
    .srm-field.has-error .srm-select,
    .srm-field.has-error .srm-textarea { border-color: #f59e0b; box-shadow: 0 0 0 3px rgba(245,158,11,0.15); }
    .srm-hint { font-size: 11.5px; color: #64748b; display: flex; justify-content: space-between; gap: 8px; }
    .srm-error { font-size: 11.5px; color: #b45309; display: none; }
    .srm-field.has-error .srm-error { display: block; }

    .srm-banner {
        display: none;
        margin-bottom: 16px;
        padding: 10px 12px;
        border-radius: 8px;
        font-size: 13px;
        background: #fffbeb; border: 1px solid #fde68a; color: #92400e;
    }
    .srm-banner.is-shown { display: block; }

    .srm-success { display: none; text-align: center; padding: 28px 8px 12px; }
    .srm-success.is-shown { display: block; }
    .srm-success-icon {
        width: 56px; height: 56px; margin: 0 auto 14px;
        border-radius: 50%;
        background: #ecfdf5; color: #059669;
        display: flex; align-items: center; justify-content: center;
        font-size: 24px;
    }
    .srm-success h4 { margin: 0 0 6px; font-size: 17px; color: #0f172a; }
    .srm-success p { margin: 0; color: #64748b; font-size: 13px; }
    .srm-ticket {
        display: inline-block; margin-top: 12px;
        padding: 6px 12px; border-radius: 6px;
        background: #edf4fb; color: #255a94;
        font-weight: 700; font-size: 14px; letter-spacing: .3px;
    }

    .srm-foot {
        display: flex; justify-content: flex-end; align-items: center; gap: 10px;
        flex-wrap: wrap;
        padding: 14px clamp(16px, 3vw, 24px);
        background: #f8fafc;
        border-top: 1px solid #eef2f7;
    }
    .srm-btn {
        height: 38px; padding: 0 18px;
        display: inline-flex; align-items: center; justify-content: center; gap: 8px;
        border-radius: 8px;
        font: inherit; font-size: 13.5px; font-weight: 600;
        cursor: pointer;
        transition: background .15s ease, border-color .15s ease, color .15s ease, box-shadow .15s ease;
    }
    .srm-btn:focus-visible { outline: none; box-shadow: 0 0 0 3px rgba(47,111,179,0.30); }
    .srm-btn-secondary { background: #ffffff; color: #334155; border: 1px solid #cbd5e1; }
    .srm-btn-secondary:hover { background: #f1f5f9; border-color: #94a3b8; }
    .srm-btn-primary { background: #2f6fb3; color: #ffffff; border: 1px solid #2f6fb3; min-width: 150px; }
    .srm-btn-primary:hover { background: #255a94; border-color: #255a94; }
    .srm-btn-primary[disabled] { background: #9dbbdc; border-color: #9dbbdc; cursor: wait; }
    .srm-spinner {
        width: 14px; height: 14px; border-radius: 50%;
        border: 2px solid rgba(255,255,255,.45); border-top-color: #ffffff;
        animation: srmSpin .7s linear infinite; display: none;
    }
    .srm-btn-primary.is-loading .srm-spinner { display: inline-block; }
    @keyframes srmSpin { to { transform: rotate(360deg); } }

    body.srm-lock { overflow: hidden; }

    @media (max-width: 600px) {
        .srm-grid { grid-template-columns: 1fr; }
        .srm-foot { flex-direction: column-reverse; align-items: stretch; }
        .srm-btn { width: 100%; height: 44px; }
        .srm-input, .srm-select, .srm-textarea { font-size: 16px; } /* stops iOS zoom */
        .srm-trigger span.srm-trigger-text { display: none; }
    }
    @media (prefers-reduced-motion: reduce) {
        .srm-overlay, .srm-dialog { transition: none; }
    }


    /* Vendor-wise PO card */
    .po-card-title {
        display: inline-flex; align-items: center; gap: 6px;
        font-weight: 600; color: var(--text-heading);
        margin-right: 10px; padding-right: 12px;
        border-right: 1px solid var(--border);
        white-space: nowrap;
    }
    .po-card-title i { color: var(--accent); }
    /* Consumption + top-8 vendor tiles: share one row across the full width on any screen;
       only if there are too many to stay readable do they wrap - never a scroll bar.
       Typography tuned for comfortable reading: steady sizes, soft contrast, no hyphen splits. */
    .fit-row {
        grid-template-columns: repeat(auto-fit, minmax(104px, 1fr));
        gap: 10px;
        overflow: hidden;
    }
    .fit-row .today-tile {
        min-width: 0;
        padding: 10px 12px;
        display: flex; flex-direction: column; gap: 4px;
        -webkit-font-smoothing: antialiased;
    }
    .fit-row .today-tile .t-dept {
        margin: 0;
        font-size: 12px; font-weight: 500; line-height: 1.4;
        color: #5b6575;
        letter-spacing: 0.1px;
        white-space: normal; overflow: visible; text-overflow: clip;
        overflow-wrap: break-word; word-break: normal; hyphens: manual;
    }
    .fit-row .today-tile .t-val {
        margin: 0;
        font-size: 15px; font-weight: 600; line-height: 1.25;
        color: #1f2a37;
        font-variant-numeric: tabular-nums;
        letter-spacing: 0;
        white-space: nowrap;
        margin-top: auto;
    }
    .fit-row .today-tile .t-sub {
        margin: 0;
        font-size: 11.5px; font-weight: 400; line-height: 1.3;
        color: #8a94a3;
        white-space: nowrap;
    }
    .po-card-title { font-size: 13px; font-weight: 600; color: #344054; }
    /* Top 3 items per department */
    .top-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 10px; }
    .top-panel { border: 1px solid var(--border); border-radius: var(--radius); background: var(--surface); min-width: 0; }
    .top-head {
        display: flex; justify-content: space-between; align-items: baseline; gap: 8px;
        padding: 8px 12px; border-bottom: 1px solid var(--border); background: var(--surface-2);
    }
    .top-dept { font-weight: 600; color: var(--text-heading); font-size: 12.5px; overflow-wrap: break-word; min-width: 0; }
    .top-dtot { font-size: 12px; color: var(--text-muted); white-space: nowrap; }
    .top-list { list-style: none; margin: 0; padding: 4px 0; counter-reset: top; }
    .top-list li {
        counter-increment: top;
        display: grid; grid-template-columns: 18px 1fr; column-gap: 6px;
        padding: 6px 12px; border-bottom: 1px solid var(--border);
    }
    .top-list li:last-child { border-bottom: none; }
    .top-list li::before {
        content: counter(top);
        grid-row: span 2;
        width: 18px; height: 18px; border-radius: 50%;
        background: var(--accent-soft); color: var(--accent);
        font-size: 11px; font-weight: 700;
        display: flex; align-items: center; justify-content: center;
    }
    .top-name { color: var(--text-heading); font-size: 12.5px; line-height: 1.35; overflow-wrap: break-word; min-width: 0; }
    .top-meta { display: flex; justify-content: space-between; gap: 8px; font-size: 11.5px; margin-top: 1px; }
    .top-qty { color: var(--text-muted); white-space: nowrap; }
    .top-val { color: var(--text-heading); font-weight: 600; white-space: nowrap; }
    .rank-toggle { display: inline-flex; align-items: center; gap: 2px; padding: 2px; border: 1px solid var(--border); border-radius: 6px; background: var(--surface-2); }
    .rank-label { font-size: 11.5px; color: var(--text-muted); padding: 0 6px 0 4px; }
    .rank-btn {
        border: 1px solid transparent; background: transparent; color: var(--text-muted);
        font: inherit; font-size: 12px; font-weight: 600; padding: 4px 10px; border-radius: 4px; cursor: pointer;
        display: inline-flex; align-items: center; gap: 5px;
    }
    .rank-btn:hover { color: var(--text-heading); }
    .rank-btn.active { background: var(--surface); color: var(--accent); border-color: var(--border); box-shadow: 0 1px 1px rgba(0,0,0,.04); }
    .top-card .rank-q { display: none; }
    .top-card.by-qty .rank-v { display: none; }
    .top-card.by-qty .rank-q { display: block; }
    /* emphasise the figure being ranked on */
    .top-card.by-qty .top-qty { color: var(--text-heading); font-weight: 600; }
    .top-card.by-qty .top-val { color: var(--text-muted); font-weight: 400; }
    /* Vendor price comparison */
    .pc-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(270px, 1fr)); gap: 10px; }
    .pc-panel {
        border: 1px solid var(--border-strong); border-radius: var(--radius); background: var(--surface);
        min-width: 0; display: flex; flex-direction: column;
        box-shadow: 0 1px 2px rgba(31, 42, 55, 0.06);
    }
    .pc-panel .pc-head { border-bottom-color: var(--border-strong); }
    .pc-head {
        display: flex; justify-content: space-between; align-items: flex-start; gap: 10px;
        padding: 9px 12px; border-bottom: 1px solid var(--border); background: var(--surface-2);
    }
    .pc-item { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
    .pc-name { font-weight: 600; font-size: 12.5px; color: var(--text-heading); line-height: 1.35; overflow-wrap: break-word; }
    .pc-sub { font-size: 11.5px; color: #8a94a3; }
    .pc-cats { display: flex; flex-wrap: wrap; gap: 6px; margin: 0 0 12px; }
    .pc-cat-btn {
        border: 1px solid var(--border); background: var(--surface); color: #475467;
        font: inherit; font-size: 12px; font-weight: 500; padding: 4px 10px; border-radius: 999px; cursor: pointer;
        display: inline-flex; align-items: center; gap: 6px; transition: background .15s, border-color .15s, color .15s;
    }
    .pc-cat-btn:hover { border-color: #9dbbdc; color: var(--text-heading); }
    .pc-cat-btn.active { background: var(--accent-soft); border-color: #9dbbdc; color: var(--accent); font-weight: 600; }
    .pc-cat-n { font-size: 11px; color: #8a94a3; background: var(--surface-2); border-radius: 999px; padding: 0 6px; }
    .pc-cat-btn.active .pc-cat-n { background: #ffffff; color: var(--accent); }
    .pc-cat { display: none; }
    .pc-cat.active { display: grid; }
    .pc-use { font-size: 11.5px; color: var(--accent); }
    .pc-use i { font-size: 10px; margin-right: 2px; }
    .pc-spread {
        flex-shrink: 0; font-size: 11px; font-weight: 600; color: #8a5a00;
        background: #fdf6e7; border: 1px solid #f3e1b5; border-radius: 4px; padding: 1px 6px; white-space: nowrap;
    }
    .pc-list { list-style: none; margin: 0; padding: 2px 0; }
    .pc-list li { padding: 7px 12px; border-bottom: 1px solid var(--border); }
    .pc-list li:last-child { border-bottom: none; }
    .pc-list li.pc-best { background: #f3faf6; }
    .pc-row { display: flex; justify-content: space-between; align-items: baseline; gap: 10px; }
    .pc-vendor { font-size: 12.5px; color: #344054; line-height: 1.35; overflow-wrap: break-word; min-width: 0; }
    .pc-rate { font-size: 13px; font-weight: 600; color: var(--text-heading); white-space: nowrap; font-variant-numeric: tabular-nums; }
    .pc-rate small { font-size: 11px; font-weight: 400; color: #8a94a3; margin-left: 1px; }
    .pc-meta { display: flex; justify-content: space-between; gap: 8px; margin-top: 2px; font-size: 11px; color: #8a94a3; }
    .pc-tag { color: #1f7a4d; font-weight: 600; white-space: nowrap; }
    .pc-diff { color: #a15c07; font-weight: 600; white-space: nowrap; font-variant-numeric: tabular-nums; }
    .po-more { margin: 8px 0 0; font-size: 11.5px; color: var(--text-muted); }
    .today-tile .t-sub { margin: 2px 0 0; font-size: 11.5px; color: var(--text-muted); }

    /* "Between dates" tab */
    .range-form { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 10px 14px; margin: 0 0 14px;
                  padding: 10px 12px; background: #f7f9fb; border: 1px solid #e3e8ee; border-radius: 8px; }
    .range-form label { display: flex; flex-direction: column; gap: 3px; font-size: 11.5px; font-weight: 600; color: var(--text-muted); }
    .range-form input[type=date] { height: 34px; padding: 0 8px; border: 1px solid #c9d1db; border-radius: 6px; font: inherit;
                                   font-size: 13px; color: #1d2d3e; background: #fff; }
    .range-apply { height: 34px; padding: 0 16px; border: 1px solid #0176d3; background: #0176d3; color: #fff; border-radius: 6px;
                   font-weight: 600; font-size: 13px; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; }
    .range-apply:hover { background: #015a9e; border-color: #015a9e; }
    .range-clear { height: 34px; display: inline-flex; align-items: center; font-size: 13px; color: #0176d3; text-decoration: none; }
    .range-clear:hover { text-decoration: underline; }
    @media (max-width: 600px) { .range-form label { flex: 1 1 130px; } .range-form input[type=date] { width: 100%; } .range-apply { flex: 1 1 100%; justify-content: center; } }
</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />

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
        <div class="ph-right">
            <div class="ph-date">
                <i class="far fa-calendar-alt"></i><%= new SimpleDateFormat("EEEE, dd MMMM yyyy").format(new Date()) %>
            </div>
            <button type="button" class="srm-trigger" onclick="openRequestModal()">
                <i class="fas fa-plus"></i><span class="srm-trigger-text">Open Service Request</span>
            </button>
        </div>
    </div>

    <!-- Consumption cost by department (This Year -> 60 -> 30 -> 7 days -> Today -> Between dates) -->
    <div class="card" id="consCard">
        <div class="card-header">
            <div class="tab-header">
                <span class="po-card-title"><i class="fas fa-boxes"></i> Consumption by Department</span>
                <% for (int t = 0; t < cTabIds.length; t++) { %>
                <button type="button" class="tab-btn <%= t == activeTab ? "active" : "" %>" onclick="switchTab(event, '<%= cTabIds[t] %>')">
                    <i class="fas <%= pIcons[t] %>"></i> <%= pLabels[t] %>
                </button>
                <% } %>
            </div>
            <div>
                <% for (int t = 0; t < cTabIds.length; t++) { %>
                <span class="today-total period-total" id="<%= cTabIds[t].replace("Tab", "TotalLabel") %>" <%= t == activeTab ? "" : "style=\"display: none;\"" %>><%= pTotalText[t] %><b><%= rupee(cTotals[t]) %></b></span>
                <% } %>
            </div>
        </div>
        <div class="card-body">
            <% for (int t = 0; t < cTabIds.length; t++) {
                 Map<String, Double> cm = cMaps.get(t);
            %>
            <div id="<%= cTabIds[t] %>" class="tab-content <%= t == activeTab ? "active" : "" %>">
                <% if (t == RANGE_TAB) { %><%= rangeForm("consCard", rangeFrom, rangeTo, request.getParameter("department"), request.getParameter("year"), hasRange) %><% } %>
                <% if (cm.isEmpty()) { %>
                    <div class="empty" style="padding:12px 0;"><%= (t == RANGE_TAB && !hasRange) ? "Choose the From and To dates and press Apply." : "No stock issued " + pWhen[t] + "." %></div>
                <% } else { %>
                    <div class="today-grid fit-row">
                    <% for (Map.Entry<String, Double> e : cm.entrySet()) { %>
                        <div class="today-tile">
                            <p class="t-dept" title="<%= h(e.getKey()) %>"><%= h(e.getKey()) %></p>
                            <p class="t-val"><%= rupee(e.getValue()) %></p>
                        </div>
                    <% } %>
                    </div>
                <% } %>
            </div>
            <% } %>
        </div>
    </div>

    <!-- Vendor-wise Purchase Orders (cumulative) -->
    <div class="card" id="poCard">
        <div class="card-header">
            <div class="tab-header">
                <span class="po-card-title"><i class="fas fa-file-invoice"></i> Top Vendors by PO Value</span>
                <% for (int t = 0; t < poTabIds.length; t++) { %>
                <button type="button" class="tab-btn <%= t == activeTab ? "active" : "" %>" onclick="switchTab(event, '<%= poTabIds[t] %>')">
                    <i class="fas <%= pIcons[t] %>"></i> <%= pLabels[t] %>
                </button>
                <% } %>
            </div>
            <div>
                <% for (int t = 0; t < poTabIds.length; t++) {
                     double tv = 0; int tc = 0;
                     for (double[] a : poMaps.get(t).values()) { tv += a[0]; tc += (int) a[1]; }
                %>
                <span class="today-total period-total" id="<%= poTabIds[t].replace("Tab", "TotalLabel") %>" <%= t == activeTab ? "" : "style=\"display: none;\"" %>><%= pTotalText[t] %> &middot; <%= tc %> PO<%= tc == 1 ? "" : "s" %><b><%= rupee(tv) %></b></span>
                <% } %>
            </div>
        </div>
        <div class="card-body">
            <% for (int t = 0; t < poTabIds.length; t++) {
                 Map<String, double[]> pm = poMaps.get(t);
            %>
            <div id="<%= poTabIds[t] %>" class="tab-content <%= t == activeTab ? "active" : "" %>">
                <% if (t == RANGE_TAB) { %><%= rangeForm("poCard", rangeFrom, rangeTo, request.getParameter("department"), request.getParameter("year"), hasRange) %><% } %>
                <% if (pm.isEmpty()) { %>
                    <div class="empty" style="padding:12px 0;"><%= (t == RANGE_TAB && !hasRange) ? "Choose the From and To dates and press Apply." : "No purchase orders " + pWhen[t] + "." %></div>
                <% } else { %>
                    <div class="today-grid fit-row po-grid">
                    <% int shown = 0;
                       for (Map.Entry<String, double[]> e : pm.entrySet()) {
                         if (shown++ >= 8) break;   // top 8 vendors by PO value (map is sorted highest first)
                         int cnt = (int) e.getValue()[1];
                    %>
                        <div class="today-tile">
                            <p class="t-dept" title="<%= h(e.getKey()) %>"><%= h(e.getKey()) %></p>
                            <p class="t-val"><%= rupee(e.getValue()[0]) %></p>
                            <p class="t-sub"><%= cnt %> PO<%= cnt == 1 ? "" : "s" %></p>
                        </div>
                    <% } %>
                    </div>
                    <% if (pm.size() > 8) { %>
                    <p class="po-more">Showing top 8 of <%= pm.size() %> vendors by PO value &middot; header total includes all vendors</p>
                    <% } %>
                <% } %>
            </div>
            <% } %>
        </div>
    </div>

    <!-- Filters -->
    <form class="filter-panel" method="get" action="home">
        <% if (hasRange) { %><input type="hidden" name="from" value="<%= h(rangeFrom) %>"><input type="hidden" name="to" value="<%= h(rangeTo) %>"><% } %>
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

    <!-- Vendor price comparison: 10 items bought from 2+ vendors -->
    <div class="card">
        <div class="card-header">
            <div class="tab-header">
                <span class="po-card-title" style="border-right:none"><i class="fas fa-balance-scale"></i> Vendor Price Comparison</span>
            </div>
            <div><span class="today-total"> last 12 months &middot; unit price after discount, excl. GST</span></div>
        </div>
        <div class="card-body">
            <% if (priceByCat.isEmpty()) { %>
                <div class="empty" style="padding:12px 0;">No item was bought from two or more different vendors in the last 12 months.</div>
            <% } else { %>
            <div class="pc-cats" role="tablist" aria-label="Filter by category">
                <% int cb = 0; for (Map.Entry<String, List<Object[]>> ce : priceByCat.entrySet()) { %>
                <button type="button" class="pc-cat-btn <%= cb == 0 ? "active" : "" %>" data-cat="<%= cb %>" onclick="setPcCat(<%= cb %>)">
                    <%= h(ce.getKey()) %> <span class="pc-cat-n" title="items bought from 2+ vendors"><%= priceCatTotals.containsKey(ce.getKey()) ? priceCatTotals.get(ce.getKey()) : ce.getValue().size() %></span>
                </button>
                <% cb++; } %>
            </div>
            <% int ci = 0; for (Map.Entry<String, List<Object[]>> ce : priceByCat.entrySet()) {
                 List<Object[]> catItems = ce.getValue();
            %>
            <div class="pc-grid pc-cat <%= ci == 0 ? "active" : "" %>" data-cat="<%= ci %>">
            <% for (Object[] it : catItems) {
                 List<Object[]> vendors = (List<Object[]>) it[3];
                 String uom = it[1] == null ? "" : String.valueOf(it[1]).trim();
                 double best = (Double) vendors.get(0)[1];
                 double worst = (Double) vendors.get(vendors.size() - 1)[1];
                 double spread = best > 0 ? (worst - best) / best * 100.0 : 0;
            %>
                <div class="pc-panel">
                    <div class="pc-head">
                        <div class="pc-item">
                            <span class="pc-name"><%= h(String.valueOf(it[0])) %></span>
                            <span class="pc-sub"><%= vendors.size() %> vendors &middot; <%= rupee((Double) it[2]) %> purchased</span>
                            <% int poCnt = it.length > 4 ? (Integer) it[4] : 0; %>
                            <span class="pc-use"><i class="fas fa-shopping-cart"></i> Bought on <%= poCnt %> PO<%= poCnt == 1 ? "" : "s" %></span>
                        </div>
                        <% if (spread >= 0.5) { %><span class="pc-spread" title="Highest vs lowest average price"><%= fmtIN(spread, 0) %>% gap</span><% } %>
                    </div>
                    <ul class="pc-list">
                    <% for (int v = 0; v < vendors.size(); v++) {
                         Object[] vr = vendors.get(v);
                         double avg = (Double) vr[1];
                         double diff = best > 0 ? (avg - best) / best * 100.0 : 0;
                    %>
                        <li class="<%= v == 0 ? "pc-best" : "" %>">
                            <div class="pc-row">
                                <span class="pc-vendor"><%= h(String.valueOf(vr[0])) %></span>
                                <span class="pc-rate">&#8377;<%= fmtIN(avg, 2) %><% if (!uom.isEmpty()) { %><small>/<%= h(uom) %></small><% } %></span>
                            </div>
                            <div class="pc-meta">
                                <span><%= vr[4] %> PO<%= ((Integer) vr[4]) == 1 ? "" : "s" %> &middot; last &#8377;<%= fmtIN((Double) vr[2], 2) %> on <%= vr[5] %></span>
                                <% if (v == 0) { %><span class="pc-tag">Lowest</span><% } else { %><span class="pc-diff">+<%= fmtIN(diff, 1) %>%</span><% } %>
                            </div>
                        </li>
                    <% } %>
                    </ul>
                </div>
            <% } %>
            </div>
            <% ci++; } %>
            <% } %>
        </div>
    </div>

    <!-- Top 3 most consumed items per department -->
    <div class="card top-card" id="topCard">
        <div class="card-header">
            <div class="tab-header">
                <span class="po-card-title"><i class="fas fa-fire"></i> Top 3 Items by Department</span>
                <% for (int t = 0; t < tTabIds.length; t++) { %>
                <button type="button" class="tab-btn <%= t == activeTab ? "active" : "" %>" onclick="switchTab(event, '<%= tTabIds[t] %>')">
                    <i class="fas <%= pIcons[t] %>"></i> <%= pLabels[t] %>
                </button>
                <% } %>
            </div>
            <div class="rank-toggle" role="group" aria-label="Rank items by">
                
                <button type="button" class="rank-btn active" data-mode="value" onclick="setTopRank('value')"><i class="fas fa-rupee-sign"></i> Value</button>
                <button type="button" class="rank-btn" data-mode="qty" onclick="setTopRank('qty')"><i class="fas fa-sort-amount-down"></i> Quantity</button>
            </div>
        </div>
        <div class="card-body">
            <% for (int t = 0; t < tTabIds.length; t++) {
                 Map<String, List<Object[]>> tm = topMaps.get(t);
                 // department order = highest consumption first (same as the consumption card)
                 List<String> deptOrder = new ArrayList<String>(cMaps.get(t).keySet());
                 for (String k : tm.keySet()) if (!deptOrder.contains(k)) deptOrder.add(k);
            %>
            <div id="<%= tTabIds[t] %>" class="tab-content <%= t == activeTab ? "active" : "" %>">
                <% if (t == RANGE_TAB) { %><%= rangeForm("topCard", rangeFrom, rangeTo, request.getParameter("department"), request.getParameter("year"), hasRange) %><% } %>
                <% if (tm.isEmpty()) { %>
                    <div class="empty" style="padding:12px 0;"><%= (t == RANGE_TAB && !hasRange) ? "Choose the From and To dates and press Apply." : "No stock issued " + pWhen[t] + "." %></div>
                <% } else { %>
                    <div class="top-grid">
                    <% for (String dn : deptOrder) {
                         List<Object[]> items = tm.get(dn);
                         if (items == null || items.isEmpty()) continue;
                         Double dTot = cMaps.get(t).get(dn);
                    %>
                        <div class="top-panel">
                            <div class="top-head">
                                <span class="top-dept"><%= h(dn) %></span>
                                <% if (dTot != null) { %><span class="top-dtot"><%= rupee(dTot) %></span><% } %>
                            </div>
                            <% for (int mode = 0; mode < 2; mode++) {
                                 List<Object[]> list = (mode == 0 ? topMaps : topMapsQ).get(t).get(dn);
                                 if (list == null) list = new ArrayList<Object[]>();
                            %>
                            <ol class="top-list <%= mode == 0 ? "rank-v" : "rank-q" %>">
                            <% for (Object[] it : list) {
                                 double q = (Double) it[2];
                                 String uom = it[1] == null ? "" : String.valueOf(it[1]);
                            %>
                                <li>
                                    <span class="top-name"><%= h(String.valueOf(it[0])) %></span>
                                    <span class="top-meta">
                                        <span class="top-qty"><%= fmtIN(q, (q % 1 == 0) ? 0 : 2) %> <%= h(uom) %></span>
                                        <span class="top-val"><%= rupee((Double) it[3]) %></span>
                                    </span>
                                </li>
                            <% } %>
                            </ol>
                            <% } %>
                        </div>
                    <% } %>
                    </div>
                <% } %>
            </div>
            <% } %>
        </div>
    </div>
</div>

<script>
function setPcCat(idx) {
    document.querySelectorAll('.pc-cat').forEach(function (g) { g.classList.toggle('active', g.getAttribute('data-cat') == idx); });
    document.querySelectorAll('.pc-cat-btn').forEach(function (b) { b.classList.toggle('active', b.getAttribute('data-cat') == idx); });
}

function setTopRank(mode) {
    var card = document.getElementById('topCard');
    if (!card) return;
    card.classList.toggle('by-qty', mode === 'qty');
    card.querySelectorAll('.rank-btn').forEach(function (b) {
        b.classList.toggle('active', b.getAttribute('data-mode') === mode);
    });
    try { localStorage.setItem('homeTopRank', mode); } catch (e) {}
}
document.addEventListener('DOMContentLoaded', function () {
    var saved = null;
    try { saved = localStorage.getItem('homeTopRank'); } catch (e) {}
    if (saved === 'qty') setTopRank('qty');
});

function switchTab(evt, tabId) {
    // Works per card, so each card's tabs switch independently.
    var card = evt.currentTarget.closest('.card') || document;
    card.querySelectorAll('.tab-content').forEach(function (el) { el.classList.remove('active'); });
    card.querySelectorAll('.tab-btn').forEach(function (el) { el.classList.remove('active'); });
    card.querySelectorAll('.period-total').forEach(function (el) { el.style.display = 'none'; });
    document.getElementById(tabId).classList.add('active');
    evt.currentTarget.classList.add('active');
    var label = document.getElementById(tabId.replace(/Tab$/, 'TotalLabel'));
    if (label) label.style.display = 'inline';
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

<!-- ===================== Open Service Request modal ===================== -->
<div class="srm-overlay" id="srmOverlay" aria-hidden="true">
    <div class="srm-dialog" role="dialog" aria-modal="true" aria-labelledby="srmTitle">
        <div class="srm-head">
            <div class="srm-head-main">
                <div class="srm-head-icon"><i class="fas fa-headset"></i></div>
                <div>
                    <h2 class="srm-title" id="srmTitle">Open Service Request</h2>
                    <p class="srm-subtitle">Raised as <b><%= h(user.toUpperCase()) %></b> &middot; the concerned team will be notified</p>
                </div>
            </div>
            <button type="button" class="srm-close" onclick="closeRequestModal()" aria-label="Close"><i class="fas fa-times"></i></button>
        </div>

        <form id="srmForm" novalidate onsubmit="return submitRequestModal(event)">
            <div class="srm-body">
                <div class="srm-banner" id="srmBanner"></div>

                <div id="srmFields" class="srm-grid">
                    <div class="srm-field" data-field="category">
                        <label class="srm-label" for="srmCategory">Service Category<span class="srm-req">*</span></label>
                        <select id="srmCategory" class="srm-select" required>
                            <option value="">Loading categories&hellip;</option>
                        </select>
                        <span class="srm-error">Please choose a category.</span>
                    </div>

                    <div class="srm-field" data-field="priority">
                        <label class="srm-label" for="srmPriority">Priority<span class="srm-req">*</span></label>
                        <select id="srmPriority" name="priority" class="srm-select" required>
                            <option value="">Select priority</option>
                            <option value="Low">Low</option>
                            <option value="Medium" selected>Medium</option>
                            <option value="High">High</option>
                            <option value="Urgent">Urgent</option>
                        </select>
                        <span class="srm-error">Please choose a priority.</span>
                    </div>

                    <div class="srm-field srm-full" data-field="subject">
                        <label class="srm-label" for="srmSubject">Subject<span class="srm-req">*</span></label>
                        <input type="text" id="srmSubject" name="subject" class="srm-input" maxlength="120"
                               placeholder="e.g. Tube light not working" required>
                        <span class="srm-error">Please add a short subject.</span>
                    </div>

                    <div class="srm-field srm-full" data-field="location">
                        <label class="srm-label" for="srmLocation">Location<span class="srm-req">*</span></label>
                        <input type="text" id="srmLocation" name="location" class="srm-input" maxlength="150"
                               placeholder="e.g. Block B, Room 204" required>
                        <span class="srm-error">Please tell us where the issue is.</span>
                    </div>

                    <div class="srm-field srm-full" data-field="description">
                        <label class="srm-label" for="srmDescription">Description<span class="srm-req">*</span></label>
                        <textarea id="srmDescription" name="description" class="srm-textarea" maxlength="1000"
                                  placeholder="Describe the problem, when it started and anything already tried" required></textarea>
                        <div class="srm-hint"><span>Be specific &ndash; it helps the team fix it faster.</span><span id="srmCount">0 / 1000</span></div>
                        <span class="srm-error">Please describe the issue.</span>
                    </div>
                </div>

                <div class="srm-success" id="srmSuccess">
                    <div class="srm-success-icon"><i class="fas fa-check"></i></div>
                    <h4>Request submitted</h4>
                    <p>Your service request has been logged and the team will pick it up shortly.</p>
                    <span class="srm-ticket" id="srmTicketNo"></span>
                </div>
            </div>

            <div class="srm-foot" id="srmFoot">
                <button type="button" class="srm-btn srm-btn-secondary" id="srmCancelBtn" onclick="closeRequestModal()">Cancel</button>
                <button type="submit" class="srm-btn srm-btn-primary" id="srmSubmitBtn">
                    <span class="srm-spinner"></span><span class="srm-btn-text">Submit Request</span>
                </button>
            </div>
        </form>
    </div>
</div>

<script>
/* ===================== Open Service Request modal ===================== */
(function () {
    var CTX = "<%= request.getContextPath() %>";
    var overlay, form, lastFocus, categoriesLoaded = false, submitted = false;

    function $(id) { return document.getElementById(id); }

    function loadCategories() {
        if (categoriesLoaded) return;
        var sel = $("srmCategory");
        fetch(CTX + "/RequestBookingServlet?action=loadCategories", { credentials: "same-origin" })
            .then(function (r) { return r.json(); })
            .then(function (rows) {
                sel.innerHTML = '<option value="">Select a category</option>';
                var groups = {};
                rows.forEach(function (r) {
                    if (!groups[r.dept]) {
                        groups[r.dept] = document.createElement("optgroup");
                        groups[r.dept].label = r.dept;
                        sel.appendChild(groups[r.dept]);
                    }
                    var o = document.createElement("option");
                    o.value = r.deptId + "|" + r.typeId;
                    o.textContent = r.type;
                    groups[r.dept].appendChild(o);
                });
                if (!rows.length) sel.innerHTML = '<option value="">No categories configured</option>';
                categoriesLoaded = rows.length > 0;
            })
            .catch(function () {
                sel.innerHTML = '<option value="">Could not load categories</option>';
            });
    }

    function resetForm() {
        form.reset();
        submitted = false;
        $("srmFields").style.display = "";
        $("srmSuccess").classList.remove("is-shown");
        $("srmBanner").classList.remove("is-shown");
        $("srmCancelBtn").textContent = "Cancel";
        var btn = $("srmSubmitBtn");
        btn.style.display = "";
        btn.disabled = false;
        btn.classList.remove("is-loading");
        form.querySelectorAll(".srm-field").forEach(function (f) { f.classList.remove("has-error"); });
        $("srmCount").textContent = "0 / 1000";
    }

    window.openRequestModal = function () {
        overlay = overlay || $("srmOverlay");
        form = form || $("srmForm");
        lastFocus = document.activeElement;
        resetForm();
        loadCategories();
        overlay.classList.add("is-open");
        overlay.setAttribute("aria-hidden", "false");
        document.body.classList.add("srm-lock");
        setTimeout(function () { $("srmCategory").focus(); }, 220);
    };

    window.closeRequestModal = function () {
        if (!overlay) return;
        overlay.classList.remove("is-open");
        overlay.setAttribute("aria-hidden", "true");
        document.body.classList.remove("srm-lock");
        if (lastFocus && lastFocus.focus) lastFocus.focus();
        if (submitted) setTimeout(function () { window.location.reload(); }, 250); // refresh open-request count
    };

    function validate() {
        var ok = true, firstBad = null;
        [["category", "srmCategory"], ["priority", "srmPriority"], ["subject", "srmSubject"],
         ["location", "srmLocation"], ["description", "srmDescription"]].forEach(function (p) {
            var el = $(p[1]);
            var bad = !el.value || !el.value.trim();
            form.querySelector('[data-field="' + p[0] + '"]').classList.toggle("has-error", bad);
            if (bad) { ok = false; if (!firstBad) firstBad = el; }
        });
        if (firstBad) firstBad.focus();
        return ok;
    }

    window.submitRequestModal = function (e) {
        e.preventDefault();
        if (!validate()) return false;

        var parts = $("srmCategory").value.split("|");
        var data = new URLSearchParams();
        data.append("ajax", "1");
        data.append("department_id", parts[0]);
        data.append("complaint_type_id", parts[1]);
        data.append("priority", $("srmPriority").value);
        data.append("subject", $("srmSubject").value.trim());
        data.append("location", $("srmLocation").value.trim());
        data.append("description", $("srmDescription").value.trim());

        var btn = $("srmSubmitBtn");
        btn.disabled = true;
        btn.classList.add("is-loading");
        $("srmBanner").classList.remove("is-shown");

        fetch(CTX + "/RequestBookingServlet", {
            method: "POST",
            credentials: "same-origin",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: data.toString()
        })
        .then(function (r) { return r.json(); })
        .then(function (res) {
            if (!res.ok) throw new Error(res.message || "Request could not be saved.");
            submitted = true;
            $("srmFields").style.display = "none";
            $("srmTicketNo").textContent = res.requestNo;
            $("srmSuccess").classList.add("is-shown");
            btn.style.display = "none";
            $("srmCancelBtn").textContent = "Done";
            $("srmCancelBtn").focus();
        })
        .catch(function (err) {
            var b = $("srmBanner");
            b.textContent = "Couldn't submit the request: " + (err && err.message ? err.message : "please try again.");
            b.classList.add("is-shown");
            btn.disabled = false;
            btn.classList.remove("is-loading");
        });
        return false;
    };

    document.addEventListener("DOMContentLoaded", function () {
        overlay = $("srmOverlay");
        form = $("srmForm");
        if (!overlay) return;

        overlay.addEventListener("mousedown", function (e) { if (e.target === overlay) closeRequestModal(); });
        document.addEventListener("keydown", function (e) {
            if (e.key === "Escape" && overlay.classList.contains("is-open")) closeRequestModal();
        });
        form.addEventListener("input", function (e) {
            var f = e.target.closest(".srm-field");
            if (f && e.target.value.trim()) f.classList.remove("has-error");
            if (e.target.id === "srmDescription") $("srmCount").textContent = e.target.value.length + " / 1000";
        });
        form.addEventListener("change", function (e) {
            var f = e.target.closest(".srm-field");
            if (f && e.target.value) f.classList.remove("has-error");
        });
    });
})();
</script>
</body>
</html>
