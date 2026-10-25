<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.math.BigDecimal, java.text.NumberFormat, java.time.format.DateTimeFormatter" %>
<%!
    private static String esc(Object o) {
        if (o == null) return "";
        String s = String.valueOf(o);
        StringBuilder b = new StringBuilder(s.length() + 16);
        for (char c : s.toCharArray()) {
            switch (c) {
                case '<': b.append("&lt;"); break;
                case '>': b.append("&gt;"); break;
                case '&': b.append("&amp;"); break;
                case '"': b.append("&quot;"); break;
                case '\'': b.append("&#39;"); break;
                default: b.append(c);
            }
        }
        return b.toString();
    }
    private static String money(BigDecimal v) {
        NumberFormat nf = NumberFormat.getNumberInstance(new Locale("en", "IN"));
        nf.setMinimumFractionDigits(2);
        nf.setMaximumFractionDigits(2);
        return nf.format(v == null ? BigDecimal.ZERO : v);
    }
    private static String qty(BigDecimal v) {
        return v == null ? "0" : v.stripTrailingZeros().toPlainString();
    }
%>
<%
    // Prepared by WastageReportServlet (/wastage-report), which checks Finance / Global access.
    @SuppressWarnings("unchecked") List<Map<String, Object>> rows = (List<Map<String, Object>>) request.getAttribute("rows");
    if (rows == null) { response.sendRedirect(request.getContextPath() + "/wastage-report"); return; }
    @SuppressWarnings("unchecked") Map<String, BigDecimal> byType = (Map<String, BigDecimal>) request.getAttribute("byType");
    @SuppressWarnings("unchecked") List<String> categories = (List<String>) request.getAttribute("categories");
    String[] types = (String[]) request.getAttribute("types");
    BigDecimal total = (BigDecimal) request.getAttribute("total");
    boolean truncated = Boolean.TRUE.equals(request.getAttribute("truncated"));
    boolean excel = Boolean.TRUE.equals(request.getAttribute("excel"));
    String from = (String) request.getAttribute("from"), to = (String) request.getAttribute("to");
    String type = (String) request.getAttribute("type"), category = (String) request.getAttribute("category");
    String q = (String) request.getAttribute("q"), error = (String) request.getAttribute("error");
    DateTimeFormatter dmy = DateTimeFormatter.ofPattern("dd-MM-yyyy");
    String fromDmy = java.time.LocalDate.parse(from).format(dmy), toDmy = java.time.LocalDate.parse(to).format(dmy);
%>
<% if (excel) {
    // set here: the page directive above would otherwise keep text/html
    response.setContentType("application/vnd.ms-excel; charset=UTF-8");
    response.setHeader("Content-Disposition", "attachment; filename=Wastage_Report_" + from + "_to_" + to + ".xls");
%>
<html><head><meta charset="UTF-8"></head><body>
<table border="1">
<tr><th colspan="13">Wastage Report <%= fromDmy %> to <%= toDmy %></th></tr>
<tr><th>Date</th><th>Wastage No</th><th>Item ID</th><th>Item</th><th>Category</th><th>Sub Category</th><th>Type</th><th>Qty</th><th>UOM</th><th>Rate (Rs)</th><th>Value (Rs)</th><th>Reason</th><th>Department / Entered by</th></tr>
<% for (Map<String, Object> r : rows) { %>
<tr><td><%= ((java.time.LocalDate) r.get("date")).format(dmy) %></td><td><%= esc(r.get("no")) %></td><td><%= r.get("itemId") %></td>
<td><%= esc(r.get("item")) %></td><td><%= esc(r.get("category")) %></td><td><%= esc(r.get("subCategory")) %></td><td><%= esc(r.get("type")) %></td>
<td><%= qty((BigDecimal) r.get("qty")) %></td><td><%= esc(r.get("uom")) %></td><td><%= money((BigDecimal) r.get("rate")) %></td>
<td><%= money((BigDecimal) r.get("value")) %></td><td><%= esc(r.get("reason")) %></td><td><%= esc(r.get("department")) %> / <%= esc(r.get("by")) %></td></tr>
<% } %>
<tr><th colspan="10" style="text-align:right">Total</th><th><%= money(total) %></th><th colspan="2"></th></tr>
</table></body></html>
<% return; } %>
<!DOCTYPE html>
<html>
<head>
<title>Wastage Report</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
* { box-sizing: border-box; }
body { font-family: 'Poppins', sans-serif; background: #f3f3f3; margin: 0; color: #181818; }
.main-content { width: 100%; max-width: 1440px; margin: 0 auto; padding: 16px; }
.card { background: #fff; border: 1px solid #c9c9c9; border-radius: 4px; padding: 24px; box-shadow: 0 2px 2px rgba(0,0,0,.1); }
.header-area { display: flex; align-items: center; gap: 12px; margin-bottom: 18px; border-bottom: 1px solid #e5e5e5; padding-bottom: 14px; }
.icon-box { width: 40px; height: 40px; border-radius: 4px; background: #c23934; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 18px; }
h2 { margin: 0; font-size: 20px; font-weight: 700; }
.sub { font-size: 12.5px; color: #514f4d; margin-top: 2px; }
.filter { background: #fafaf9; border: 1px solid #c9c9c9; border-radius: 4px; padding: 14px; display: flex; flex-wrap: wrap; gap: 12px; align-items: flex-end; margin-bottom: 16px; }
.fg { display: flex; flex-direction: column; gap: 4px; }
.fg label, th { font-size: 11px; font-weight: 700; color: #514f4d; text-transform: uppercase; letter-spacing: .5px; }
input, select { height: 36px; padding: 0 10px; border: 1px solid #aeaeae; border-radius: 4px; font-family: inherit; font-size: 13px; background: #fff; min-width: 150px; }
.btn { height: 36px; padding: 0 16px; border-radius: 4px; font-family: inherit; font-size: 13px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; border: 1px solid #0176d3; background: #0176d3; color: #fff; text-decoration: none; }
.btn-success { background: #2e844a; border-color: #2e844a; }
.btn-plain { background: #fff; color: #181818; border-color: #747472; }
.btns { display: flex; gap: 8px; margin-left: auto; flex-wrap: wrap; }
.chips { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 14px; }
.chip { background: #fff; border: 1px solid #c9c9c9; border-radius: 4px; padding: 8px 14px; font-size: 12px; color: #514f4d; }
.chip b { display: block; font-size: 16px; color: #181818; margin-top: 2px; }
.chip.total { border-color: #c23934; }
.chip.total b { color: #c23934; }
.table-wrap { overflow-x: auto; border: 1px solid #c9c9c9; border-radius: 4px; }
table { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff; }
th { background: #fafaf9; text-align: left; padding: 10px 8px; border-bottom: 2px solid #c9c9c9; white-space: nowrap; position: sticky; top: 0; }
td { padding: 8px; border-bottom: 1px solid #e5e5e5; vertical-align: top; }
.num { text-align: right; white-space: nowrap; }
tfoot td { font-weight: 700; background: #fafaf9; border-top: 2px solid #c9c9c9; }
.badge { display: inline-block; padding: 1px 8px; border-radius: 10px; font-size: 11px; font-weight: 600; background: #fdeaea; color: #c23934; }
.alert { padding: 10px 14px; border-radius: 4px; font-size: 13px; margin-bottom: 14px; background: #fdecea; color: #8c1d18; border: 1px solid #f3b5b0; }
@media (max-width: 768px) { .main-content { padding: 10px; } .card { padding: 14px; } .btns { margin-left: 0; } }
</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />
<div class="main-content">
<div class="card">
    <div class="header-area">
        <div class="icon-box"><i class="fa-solid fa-file-circle-exclamation"></i></div>
        <div><h2>Wastage Report</h2><div class="sub">Damaged, expired and lost items written off from stock · <%= fromDmy %> to <%= toDmy %></div></div>
    </div>

    <% if (error != null) { %><div class="alert"><%= esc(error) %></div><% } %>

    <form method="get" class="filter">
        <div class="fg"><label>From</label><input type="date" name="from" value="<%= esc(from) %>"></div>
        <div class="fg"><label>To</label><input type="date" name="to" value="<%= esc(to) %>"></div>
        <div class="fg"><label>Type</label>
            <select name="type"><option value="">All types</option>
            <% for (String t : types) { %><option value="<%= t %>" <%= t.equals(type) ? "selected" : "" %>><%= t.charAt(0) + t.substring(1).toLowerCase() %></option><% } %>
            </select></div>
        <div class="fg"><label>Category</label>
            <select name="category"><option value="">All categories</option>
            <% for (String c : categories) { %><option value="<%= esc(c) %>" <%= c.equals(category) ? "selected" : "" %>><%= esc(c) %></option><% } %>
            </select></div>
        <div class="fg"><label>Search</label><input type="text" name="q" maxlength="60" value="<%= esc(q) %>" placeholder="Item, wastage no, reason"></div>
        <div class="btns">
            <button type="submit" class="btn"><i class="fa fa-search"></i> View</button>
            <button type="submit" name="export" value="excel" class="btn btn-success"><i class="fa fa-file-excel"></i> Export</button>
            <a class="btn btn-plain" href="<%= request.getContextPath() %>/wastage"><i class="fa-solid fa-plus"></i> New Entry</a>
        </div>
    </form>

    <div class="chips">
        <div class="chip total">Total wastage value<b>₹<%= money(total) %></b></div>
        <div class="chip">Entries<b><%= rows.size() %></b></div>
        <% for (Map.Entry<String, BigDecimal> e : byType.entrySet()) { %>
            <div class="chip"><%= esc(e.getKey()) %><b>₹<%= money(e.getValue()) %></b></div>
        <% } %>
    </div>
    <% if (truncated) { %><div class="alert">Showing the first <%= rows.size() %> entries only. Narrow the filters to see all.</div><% } %>

    <div class="table-wrap">
    <table>
        <thead><tr><th>Date</th><th>Wastage No</th><th>Item</th><th>Category</th><th>Type</th><th class="num">Qty</th><th class="num">Rate (₹)</th><th class="num">Value (₹)</th><th>Reason</th><th>Department</th><th>Entered by</th></tr></thead>
        <tbody>
        <% if (rows.isEmpty()) { %>
            <tr><td colspan="11" style="text-align:center;color:#514f4d;padding:20px">No wastage in this period.</td></tr>
        <% } else { for (Map<String, Object> r : rows) { %>
            <tr>
                <td style="white-space:nowrap"><%= ((java.time.LocalDate) r.get("date")).format(dmy) %></td>
                <td style="white-space:nowrap"><%= esc(r.get("no")) %></td>
                <td><%= esc(r.get("item")) %></td>
                <td><%= esc(r.get("category")) %><%= r.get("subCategory") == null ? "" : " / " + esc(r.get("subCategory")) %></td>
                <td><span class="badge"><%= esc(r.get("type")) %></span></td>
                <td class="num"><%= qty((BigDecimal) r.get("qty")) %> <%= esc(r.get("uom")) %></td>
                <td class="num"><%= money((BigDecimal) r.get("rate")) %></td>
                <td class="num"><%= money((BigDecimal) r.get("value")) %></td>
                <td><%= esc(r.get("reason")) %></td>
                <td><%= esc(r.get("department")) %></td>
                <td><%= esc(r.get("by")) %></td>
            </tr>
        <% } } %>
        </tbody>
        <% if (!rows.isEmpty()) { %>
        <tfoot><tr><td colspan="7" class="num">Total</td><td class="num">₹<%= money(total) %></td><td colspan="3"></td></tr></tfoot>
        <% } %>
    </table>
    </div>
</div>
</div>
<jsp:include page="/WEB-INF/views/layout/Footer.jsp" />
</body>
</html>
