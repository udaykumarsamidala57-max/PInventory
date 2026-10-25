<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.math.BigDecimal, java.text.NumberFormat, java.time.format.DateTimeFormatter" %>
<%!
    /** HTML-escape everything that comes from the database or the user. */
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
    /** ₹1,23,456.78 */
    private static String inr(BigDecimal v) {
        NumberFormat nf = NumberFormat.getNumberInstance(new Locale("en", "IN"));
        nf.setMinimumFractionDigits(2);
        nf.setMaximumFractionDigits(2);
        return "₹" + nf.format(v == null ? BigDecimal.ZERO : v);
    }
    private static String qty(BigDecimal v) {
        return v == null ? "0" : v.stripTrailingZeros().toPlainString();
    }
%>
<%
    // Data is prepared by WastageServlet (/wastage), which also checks Finance / Global access.
    @SuppressWarnings("unchecked") List<Map<String, Object>> items = (List<Map<String, Object>>) request.getAttribute("items");
    @SuppressWarnings("unchecked") List<Map<String, Object>> recent = (List<Map<String, Object>>) request.getAttribute("recent");
    @SuppressWarnings("unchecked") Map<String, Object> form = (Map<String, Object>) request.getAttribute("form");
    String[] types = (String[]) request.getAttribute("types");
    if (items == null || types == null) { response.sendRedirect(request.getContextPath() + "/wastage"); return; }
    String error = (String) request.getAttribute("error");
    String saved = (String) request.getAttribute("saved");
    String minDate = (String) request.getAttribute("minDate");
    String maxDate = (String) request.getAttribute("maxDate");
    String fDate = form != null && form.get("date") != null ? String.valueOf(form.get("date")) : maxDate;
    String fDept = form != null && form.get("department") != null ? String.valueOf(form.get("department")) : "";
    DateTimeFormatter dmy = DateTimeFormatter.ofPattern("dd-MM-yyyy");
%>
<!DOCTYPE html>
<html>
<head>
<title>Damage / Wastage Entry</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
* { box-sizing: border-box; }
body { font-family: 'Poppins', sans-serif; background: #f3f3f3; margin: 0; color: #181818; }
.main-content { width: 100%; max-width: 1440px; margin: 0 auto; padding: 16px; }
.card { background: #fff; border: 1px solid #c9c9c9; border-radius: 4px; padding: 24px; box-shadow: 0 2px 2px rgba(0,0,0,.1); margin-bottom: 16px; }
.header-area { display: flex; align-items: center; gap: 12px; margin-bottom: 18px; border-bottom: 1px solid #e5e5e5; padding-bottom: 14px; }
.icon-box { width: 40px; height: 40px; border-radius: 4px; background: #c23934; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 18px; }
h2 { margin: 0; font-size: 20px; color: #181818; font-weight: 700; }
.sub { font-size: 12.5px; color: #514f4d; margin-top: 2px; }
.alert { padding: 10px 14px; border-radius: 4px; font-size: 13px; margin-bottom: 14px; }
.alert.err { background: #fdecea; color: #8c1d18; border: 1px solid #f3b5b0; }
.alert.ok { background: #e3f3e8; color: #1b5e30; border: 1px solid #a8d5b5; }
.top-row { display: flex; flex-wrap: wrap; gap: 14px; margin-bottom: 14px; }
.fg { display: flex; flex-direction: column; gap: 4px; }
.fg label, th { font-size: 11px; font-weight: 700; color: #514f4d; text-transform: uppercase; letter-spacing: .5px; }
input, select { height: 36px; padding: 0 10px; border: 1px solid #aeaeae; border-radius: 4px; font-family: inherit; font-size: 13px; background: #fff; }
input:focus, select:focus { outline: none; border-color: #0176d3; box-shadow: 0 0 0 2px rgba(1,118,211,.15); }
.table-wrap { overflow-x: auto; border: 1px solid #c9c9c9; border-radius: 4px; }
table { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff; }
th { background: #fafaf9; text-align: left; padding: 10px 8px; border-bottom: 2px solid #c9c9c9; white-space: nowrap; }
td { padding: 8px; border-bottom: 1px solid #e5e5e5; vertical-align: middle; }
td.num, th.num { text-align: right; white-space: nowrap; }
#lines input.item { width: 100%; min-width: 260px; }
#lines input.qty { width: 100px; text-align: right; }
#lines input.reason { width: 100%; min-width: 200px; }
.bal { font-size: 11.5px; color: #514f4d; margin-top: 3px; }
.bal.bad { color: #c23934; font-weight: 600; }
.btn { height: 36px; padding: 0 16px; border-radius: 4px; font-family: inherit; font-size: 13px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; border: 1px solid #747472; background: #fff; color: #181818; }
.btn:hover { background: #f3f3f3; }
.btn-danger { background: #c23934; border-color: #c23934; color: #fff; }
.btn-danger:hover { background: #a12b27; }
.btn-icon { width: 34px; padding: 0; justify-content: center; color: #c23934; }
.actions { display: flex; justify-content: space-between; align-items: center; gap: 12px; margin-top: 14px; flex-wrap: wrap; }
.total { font-size: 14px; font-weight: 700; }
.badge { display: inline-block; padding: 1px 8px; border-radius: 10px; font-size: 11px; font-weight: 600; background: #fdeaea; color: #c23934; }
.note { font-size: 12px; color: #514f4d; margin-top: 10px; }
@media (max-width: 768px) { .main-content { padding: 10px; } .card { padding: 14px; } }
</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />

<div class="main-content">

<div class="card">
    <div class="header-area">
        <div class="icon-box"><i class="fa-solid fa-trash-can"></i></div>
        <div>
            <h2>Damage / Wastage Entry</h2>
            <div class="sub">Items written off here are removed from stock and shown in the Stock Ledger as Wastage.</div>
        </div>
    </div>

    <% if (saved != null && !saved.isEmpty()) { %>
        <div class="alert ok"><i class="fa-solid fa-circle-check"></i> Wastage entry <b><%= esc(saved) %></b> saved. Stock, Stock Ledger and Stock Report are updated.</div>
    <% } %>
    <% if (error != null) { %>
        <div class="alert err"><i class="fa-solid fa-triangle-exclamation"></i> <%= esc(error) %></div>
    <% } %>

    <form method="post" action="<%= request.getContextPath() %>/wastage" id="wastageForm" autocomplete="off">
        <input type="hidden" name="csrf" value="<%= esc(request.getAttribute("csrf")) %>">

        <div class="top-row">
            <div class="fg">
                <label for="wastageDate">Wastage Date</label>
                <input type="date" id="wastageDate" name="wastageDate" required
                       min="<%= esc(minDate) %>" max="<%= esc(maxDate) %>" value="<%= esc(fDate) %>">
            </div>
            <div class="fg">
                <label for="department">Department / Location (optional)</label>
                <input type="text" id="department" name="department" maxlength="45" value="<%= esc(fDept) %>" placeholder="e.g. Dining Hall, Store">
            </div>
        </div>

        <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th style="width:36px">#</th>
                    <th>Item</th>
                    <th class="num">Qty</th>
                    <th>Type</th>
                    <th>Reason</th>
                    <th class="num">Value (₹)</th>
                    <th></th>
                </tr>
            </thead>
            <tbody id="lines"></tbody>
        </table>
        </div>

        <div class="actions">
            <button type="button" class="btn" id="addRow"><i class="fa-solid fa-plus"></i> Add Item</button>
            <div class="total">Total value: <span id="totalValue">₹0.00</span></div>
            <button type="submit" class="btn btn-danger"><i class="fa-solid fa-floppy-disk"></i> Save Wastage</button>
        </div>
        <div class="note">Only items with stock are listed. Quantity cannot exceed the available balance. Value uses the item's last purchase rate.</div>

        <datalist id="itemList">
        <% for (Map<String, Object> it : items) { %>
            <option value="<%= esc(it.get("name")) %> — <%= esc(it.get("category")) %> [#<%= it.get("id") %>]"></option>
        <% } %>
        </datalist>
    </form>
</div>

<div class="card">
    <div class="header-area" style="margin-bottom:12px">
        <div class="icon-box" style="background:#514f4d"><i class="fa-solid fa-clock-rotate-left"></i></div>
        <div><h2>Recent Wastage Entries</h2><div class="sub">Last 25 items. Full details: <a href="<%= request.getContextPath() %>/wastage-report">Wastage Report</a></div></div>
    </div>
    <div class="table-wrap">
    <table>
        <thead><tr><th>Date</th><th>Wastage No</th><th>Item</th><th>Type</th><th class="num">Qty</th><th class="num">Value</th><th>Reason</th><th>Entered by</th></tr></thead>
        <tbody>
        <% if (recent == null || recent.isEmpty()) { %>
            <tr><td colspan="8" style="text-align:center;color:#514f4d">No wastage entries yet.</td></tr>
        <% } else { for (Map<String, Object> r : recent) { %>
            <tr>
                <td><%= ((java.time.LocalDate) r.get("date")).format(dmy) %></td>
                <td><%= esc(r.get("no")) %></td>
                <td><%= esc(r.get("item")) %></td>
                <td><span class="badge"><%= esc(r.get("type")) %></span></td>
                <td class="num"><%= qty((BigDecimal) r.get("qty")) %> <%= esc(r.get("uom")) %></td>
                <td class="num"><%= inr((BigDecimal) r.get("value")) %></td>
                <td><%= esc(r.get("reason")) %></td>
                <td><%= esc(r.get("by")) %></td>
            </tr>
        <% } } %>
        </tbody>
    </table>
    </div>
</div>

</div>

<jsp:include page="/WEB-INF/views/layout/Footer.jsp" />

<script>
(function () {
    'use strict';
    // id -> {bal, uom, rate}; label -> id  (built from server data; written with textContent / value only)
    var ITEMS = {
    <% boolean first = true; for (Map<String, Object> it : items) { %>
        <%= first ? "" : "," %>"<%= it.get("id") %>": {bal: <%= qty((BigDecimal) it.get("balance")) %>, uom: "<%= esc(it.get("uom")).replace("\\", "\\\\") %>", rate: <%= qty((BigDecimal) it.get("rate")) %>}
    <% first = false; } %>
    };
    var TYPES = [<% for (int i = 0; i < types.length; i++) { %><%= i == 0 ? "" : "," %>"<%= types[i] %>"<% } %>];
    var MAX = 50;
    var body = document.getElementById('lines');
    var inrFmt = new Intl.NumberFormat('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2});

    function idFrom(text) {
        var m = /\[#(\d+)\]\s*$/.exec(text || '');
        return m && ITEMS[m[1]] ? m[1] : '';
    }

    function addRow() {
        if (body.children.length >= MAX) { return; }
        var tr = document.createElement('tr');
        tr.innerHTML =
            '<td class="n"></td>' +
            '<td><input class="item" list="itemList" placeholder="Type to search item" required>' +
            '<input type="hidden" name="itemId"><div class="bal"></div></td>' +
            '<td class="num"><input class="qty" name="qty" type="number" min="0.01" step="0.01" required></td>' +
            '<td><select name="type" required><option value="">-- Select --</option></select></td>' +
            '<td><input class="reason" name="reason" maxlength="255" required placeholder="e.g. Rotten, broken in transit"></td>' +
            '<td class="num val">₹0.00</td>' +
            '<td><button type="button" class="btn btn-icon" title="Remove"><i class="fa-solid fa-xmark"></i></button></td>';
        var sel = tr.querySelector('select');
        TYPES.forEach(function (t) {
            var o = document.createElement('option');
            o.value = t;
            o.textContent = t.charAt(0) + t.slice(1).toLowerCase();
            sel.appendChild(o);
        });
        var item = tr.querySelector('input.item'), hid = tr.querySelector('input[name=itemId]'),
            q = tr.querySelector('input.qty'), bal = tr.querySelector('.bal');
        function refresh() {
            var id = idFrom(item.value);
            hid.value = id;
            var it = ITEMS[id];
            bal.className = 'bal';
            if (!id) { bal.textContent = item.value ? 'Select an item from the list' : ''; item.setCustomValidity(item.value ? 'Select an item from the list' : ''); }
            else {
                item.setCustomValidity('');
                bal.textContent = 'In stock: ' + it.bal + ' ' + it.uom;
                q.max = it.bal;
                var v = parseFloat(q.value);
                if (v > it.bal) { bal.className = 'bal bad'; bal.textContent += ' — quantity is more than stock'; }
            }
            total();
        }
        item.addEventListener('input', refresh);
        q.addEventListener('input', refresh);
        tr.querySelector('button').addEventListener('click', function () {
            if (body.children.length > 1) { tr.remove(); number(); total(); }
        });
        body.appendChild(tr);
        number();
    }

    function number() {
        Array.prototype.forEach.call(body.children, function (tr, i) { tr.querySelector('.n').textContent = i + 1; });
    }

    function total() {
        var sum = 0;
        Array.prototype.forEach.call(body.children, function (tr) {
            var it = ITEMS[tr.querySelector('input[name=itemId]').value];
            var v = parseFloat(tr.querySelector('input.qty').value) || 0;
            var val = it ? v * it.rate : 0;
            tr.querySelector('.val').textContent = '₹' + inrFmt.format(val);
            sum += val;
        });
        document.getElementById('totalValue').textContent = '₹' + inrFmt.format(sum);
    }

    document.getElementById('addRow').addEventListener('click', addRow);
    document.getElementById('wastageForm').addEventListener('submit', function (e) {
        var ids = {}, ok = true;
        Array.prototype.forEach.call(body.children, function (tr) {
            var id = tr.querySelector('input[name=itemId]').value;
            if (!id) ok = false;
            if (ids[id]) { ok = false; tr.querySelector('input.item').setCustomValidity('Same item twice'); }
            ids[id] = true;
        });
        if (!ok) { e.preventDefault(); this.reportValidity(); return; }
        if (!window.confirm('Save this wastage entry? Stock will be reduced and this cannot be edited later.')) e.preventDefault();
    });
    addRow();
})();
</script>
</body>
</html>
