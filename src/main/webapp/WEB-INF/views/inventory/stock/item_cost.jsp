<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.math.BigDecimal, java.text.NumberFormat, java.time.LocalDate, java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
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
    private static String plain(BigDecimal v) {
        return v == null ? "" : v.setScale(2, java.math.RoundingMode.HALF_UP).toPlainString();
    }
    private static String pct(BigDecimal v) {
        return v == null ? "" : v.stripTrailingZeros().toPlainString() + "%";
    }
    /** PO dates are stored as text (yyyy-MM-dd...) – show dd-MM-yyyy when possible. */
    private static String poDate(Object o) {
        if (o == null) return "";
        String s = String.valueOf(o).trim();
        try {
            return LocalDate.parse(s.length() > 10 ? s.substring(0, 10) : s).format(DateTimeFormatter.ofPattern("dd-MM-yyyy"));
        } catch (Exception e) {
            return s;
        }
    }
    private static String when(Object o) {
        return o == null ? "" : ((LocalDateTime) o).format(DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm"));
    }
    private static String label(Map<String, Object> it) {
        return it.get("name") + " — " + (it.get("category") == null ? "" : it.get("category")) + " [#" + it.get("id") + "]";
    }
%>
<%
    // Data is prepared by ItemCostServlet (/item-cost), which also checks Finance / Global access.
    @SuppressWarnings("unchecked") List<Map<String, Object>> items = (List<Map<String, Object>>) request.getAttribute("items");
    @SuppressWarnings("unchecked") List<Map<String, Object>> history = (List<Map<String, Object>>) request.getAttribute("history");
    @SuppressWarnings("unchecked") Map<String, Object> form = (Map<String, Object>) request.getAttribute("form");
    @SuppressWarnings("unchecked") Map<String, String> bases = (Map<String, String>) request.getAttribute("bases");
    if (items == null || bases == null) { response.sendRedirect(request.getContextPath() + "/item-cost"); return; }
    String error = (String) request.getAttribute("error");
    String saved = (String) request.getAttribute("saved");
    String synced = (String) request.getAttribute("synced");
    int countPending = (Integer) request.getAttribute("countPending");
    Object autoSynced = request.getAttribute("autoSynced");

    String savedName = null;
    if (saved != null) {
        for (Map<String, Object> it : items) if (String.valueOf(it.get("id")).equals(saved)) { savedName = (String) it.get("name"); break; }
    }
    String fItemId = form != null ? String.valueOf(form.get("itemId")) : "";
    String fItemLabel = "";
    if (!fItemId.isEmpty()) {
        for (Map<String, Object> it : items) if (String.valueOf(it.get("id")).equals(fItemId)) { fItemLabel = label(it); break; }
    }
    String fCost = form != null ? String.valueOf(form.get("cost")) : "";
    String fBasis = form != null ? String.valueOf(form.get("basis")) : "";
    String fRef = form != null ? String.valueOf(form.get("reference")) : "";
    String ctx = request.getContextPath();

    // Category list for the filter (sub-categories are filled by the script from the table rows)
    TreeSet<String> categories = new TreeSet<>();   // exact values, so the filter matches the rows exactly
    boolean blankCategory = false;
    for (Map<String, Object> it : items) {
        String c = it.get("category") == null ? "" : ((String) it.get("category")).trim();
        if (c.isEmpty()) blankCategory = true; else categories.add(c);
    }
%>
<!DOCTYPE html>
<html>
<head>
<title>Item Cost Master</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
* { box-sizing: border-box; }
body { font-family: 'Poppins', sans-serif; background: #f3f3f3; margin: 0; color: #181818; }
.main-content { width: 100%; max-width: 1440px; margin: 0 auto; padding: 16px; }
.card { background: #fff; border: 1px solid #c9c9c9; border-radius: 4px; padding: 24px; box-shadow: 0 2px 2px rgba(0,0,0,.1); margin-bottom: 16px; }
.header-area { display: flex; align-items: center; gap: 12px; margin-bottom: 18px; border-bottom: 1px solid #e5e5e5; padding-bottom: 14px; flex-wrap: wrap; }
.header-area .grow { flex: 1; min-width: 220px; }
.icon-box { width: 40px; height: 40px; border-radius: 4px; background: #2e844a; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 18px; flex-shrink: 0; }
h2 { margin: 0; font-size: 20px; color: #181818; font-weight: 700; }
h3 { margin: 0; font-size: 16px; font-weight: 700; }
.sub { font-size: 12.5px; color: #514f4d; margin-top: 2px; }
.alert { padding: 10px 14px; border-radius: 4px; font-size: 13px; margin-bottom: 14px; display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.alert.err { background: #fdecea; color: #8c1d18; border: 1px solid #f3b5b0; }
.alert.ok { background: #e3f3e8; color: #1b5e30; border: 1px solid #a8d5b5; }
.alert.warn { background: #fef4e5; color: #8a4b00; border: 1px solid #f5cf8f; }
.tiles { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; margin-bottom: 16px; }
.tile { border: 1px solid #c9c9c9; border-radius: 4px; padding: 12px 14px; background: #fafaf9; cursor: pointer; text-align: left; font-family: inherit; }
.tile:hover { border-color: #0176d3; }
.tile.active { border-color: #0176d3; box-shadow: 0 0 0 2px rgba(1,118,211,.2); background: #fff; }
.tile .k { font-size: 11px; font-weight: 700; color: #514f4d; text-transform: uppercase; letter-spacing: .5px; }
.tile .v { font-size: 22px; font-weight: 700; margin-top: 2px; }
.tile.po .v { color: #0176d3; } .tile.man .v { color: #8a4b00; } .tile.none .v { color: #c23934; }
.form-row { display: grid; grid-template-columns: 2fr 1fr 1.4fr 2fr auto; gap: 12px; align-items: end; }
.fg { display: flex; flex-direction: column; gap: 4px; min-width: 0; }
.fg label, th { font-size: 11px; font-weight: 700; color: #514f4d; text-transform: uppercase; letter-spacing: .5px; }
input, select { height: 36px; padding: 0 10px; border: 1px solid #aeaeae; border-radius: 4px; font-family: inherit; font-size: 13px; background: #fff; width: 100%; }
input:focus, select:focus { outline: none; border-color: #0176d3; box-shadow: 0 0 0 2px rgba(1,118,211,.15); }
.rupee { position: relative; } .rupee span { position: absolute; left: 10px; top: 8px; font-size: 13px; color: #514f4d; }
.rupee input { padding-left: 22px; text-align: right; }
.hint { font-size: 11.5px; color: #514f4d; margin-top: 8px; }
.toolbar { display: flex; gap: 12px; align-items: flex-end; margin-bottom: 12px; flex-wrap: wrap; }
.toolbar .fg { width: 200px; }
.toolbar .grow-search { width: auto; flex: 1; min-width: 200px; max-width: 340px; }
#shown { margin-bottom: 9px; }
@media (max-width: 560px) { .toolbar .fg, .toolbar .grow-search { width: 100%; max-width: none; } }
.table-wrap { overflow-x: auto; border: 1px solid #c9c9c9; border-radius: 4px; }
table { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff; }
th { background: #fafaf9; text-align: left; padding: 10px 8px; border-bottom: 2px solid #c9c9c9; white-space: nowrap; position: sticky; top: 0; }
td { padding: 8px; border-bottom: 1px solid #e5e5e5; vertical-align: middle; }
td.num, th.num { text-align: right; white-space: nowrap; }
td.cost { font-weight: 700; }
.muted { color: #514f4d; font-size: 12px; }
.badge { display: inline-block; padding: 1px 8px; border-radius: 10px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.b-po { background: #eef4fe; color: #0176d3; border: 1px solid #aacbfa; }
.b-man { background: #fef4e5; color: #8a4b00; border: 1px solid #f5cf8f; }
.b-none { background: #fdeaea; color: #c23934; border: 1px solid #f3b5b0; }
.b-chg { background: #fff8e6; color: #8a4b00; border: 1px dashed #d9a441; }
.btn { height: 36px; padding: 0 16px; border-radius: 4px; font-family: inherit; font-size: 13px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; border: 1px solid #747472; background: #fff; color: #181818; white-space: nowrap; }
.btn:hover { background: #f3f3f3; }
.btn-primary { background: #0176d3; border-color: #0176d3; color: #fff; }
.btn-primary:hover { background: #014486; }
.btn-success { background: #2e844a; border-color: #2e844a; color: #fff; }
.btn-success:hover { background: #22683a; }
.btn-sm { height: 28px; padding: 0 10px; font-size: 12px; }
tr.hidden { display: none; }
.empty { text-align: center; color: #514f4d; padding: 18px; }
@media (max-width: 900px) { .form-row { grid-template-columns: 1fr 1fr; } .tiles { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
@media (max-width: 560px) { .main-content { padding: 10px; } .card { padding: 14px; } .form-row { grid-template-columns: 1fr; } }
</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />

<div class="main-content">

<div class="card">
    <div class="header-area">
        <div class="icon-box"><i class="fa-solid fa-indian-rupee-sign"></i></div>
        <div class="grow">
            <h2>Item Cost Master</h2>
            <div class="sub">Cost of one unit including GST &middot; Store: <b><%= esc(request.getAttribute("store")) %></b>.
                Updated <b>automatically</b> every time a Purchase Order is approved (latest approved PO, incl. GST).
                Enter a cost manually only for items that have no approved PO.</div>
        </div>
    </div>

    <% if (savedName != null) { %>
        <div class="alert ok"><i class="fa-solid fa-circle-check"></i> Cost of <b><%= esc(savedName) %></b> saved.</div>
    <% } %>
    <% if (synced != null) { %>
        <div class="alert ok"><i class="fa-solid fa-circle-check"></i>
            <% if ("0".equals(synced)) { %>All costs already match the latest approved Purchase Orders. Nothing to update.
            <% } else { %>Cost updated from Purchase Orders for <b><%= esc(synced) %></b> item(s).<% } %></div>
    <% } %>
    <% if (error != null) { %>
        <div class="alert err"><i class="fa-solid fa-triangle-exclamation"></i> <%= esc(error) %></div>
    <% } %>
    <% if (autoSynced != null) { %>
        <div class="alert ok"><i class="fa-solid fa-rotate"></i>
            Cost of <b><%= autoSynced %></b> item(s) brought up to date from approved Purchase Orders.</div>
    <% } %>
    <% if (countPending > 0) { %>
        <div class="alert warn"><i class="fa-solid fa-circle-exclamation"></i>
            <b><%= countPending %></b> item(s) could not be updated from their approved Purchase Order. Reload this page; if it stays, contact IT.</div>
    <% } %>

    <div class="tiles">
        <button type="button" class="tile active" data-filter="all"><div class="k">All items</div><div class="v"><%= request.getAttribute("countAll") %></div></button>
        <button type="button" class="tile po" data-filter="po"><div class="k">Cost from PO</div><div class="v"><%= request.getAttribute("countPo") %></div></button>
        <button type="button" class="tile man" data-filter="manual"><div class="k">Manual cost</div><div class="v"><%= request.getAttribute("countManual") %></div></button>
        <button type="button" class="tile none" data-filter="none"><div class="k">No cost yet</div><div class="v"><%= request.getAttribute("countNone") %></div></button>
    </div>

    <h3 id="manualTitle" style="margin-bottom:10px"><i class="fa-solid fa-pen-to-square" style="color:#8a4b00"></i> Enter manual cost</h3>
    <form method="post" action="<%= ctx %>/item-cost" id="manualForm" autocomplete="off">
        <input type="hidden" name="csrf" value="<%= esc(request.getAttribute("csrf")) %>">
        <input type="hidden" name="action" value="manual">
        <input type="hidden" name="itemId" id="itemId" value="<%= esc(fItemId) %>">
        <div class="form-row">
            <div class="fg">
                <label for="itemText">Item (without an approved PO)</label>
                <input id="itemText" list="manualItems" placeholder="Type to search item" required value="<%= esc(fItemLabel) %>">
            </div>
            <div class="fg">
                <label for="cost">Cost per unit (incl. GST)</label>
                <div class="rupee"><span>₹</span><input id="cost" name="cost" type="number" min="0" step="0.01" max="9999999999.99" required value="<%= esc(fCost) %>"></div>
            </div>
            <div class="fg">
                <label for="basis">How was the cost decided?</label>
                <select id="basis" name="basis" required>
                    <option value="">-- Select --</option>
                    <% for (Map.Entry<String, String> b : bases.entrySet()) { %>
                        <option value="<%= esc(b.getKey()) %>" <%= b.getKey().equals(fBasis) ? "selected" : "" %>><%= esc(b.getValue()) %></option>
                    <% } %>
                </select>
            </div>
            <div class="fg">
                <label for="reference">Reference</label>
                <input id="reference" name="reference" maxlength="255" required value="<%= esc(fRef) %>" placeholder="Bill no., quotation or approval note">
            </div>
            <button type="submit" class="btn btn-success"><i class="fa-solid fa-floppy-disk"></i> Save Cost</button>
        </div>
        <div class="hint">Items with an approved Purchase Order are not listed here: their cost always comes from the PO.
            ₹0 is allowed only for <i>Donation / free supply</i>. Every change is kept in the history below.</div>
        <datalist id="manualItems">
        <% for (Map<String, Object> it : items) { if (it.get("poCost") == null) { %>
            <option value="<%= esc(label(it)) %>"></option>
        <% } } %>
        </datalist>
    </form>
</div>

<div class="card">
    <div class="toolbar">
        <div class="fg">
            <label for="fCat">Category</label>
            <select id="fCat">
                <option value="*">All categories</option>
                <% for (String c : categories) { %><option value="<%= esc(c) %>"><%= esc(c) %></option><% } %>
                <% if (blankCategory) { %><option value="">(No category)</option><% } %>
            </select>
        </div>
        <div class="fg">
            <label for="fSub">Sub-category</label>
            <select id="fSub"><option value="*">All sub-categories</option></select>
        </div>
        <div class="fg grow-search">
            <label for="search">Search</label>
            <input type="search" id="search" placeholder="Item, category or sub-category">
        </div>
        <button type="button" class="btn" id="clearFilters"><i class="fa-solid fa-filter-circle-xmark"></i> Clear</button>
        <span class="muted" id="shown"></span>
    </div>
    <div class="table-wrap">
    <table>
        <thead>
            <tr>
                <th>Item</th>
                <th>Category</th>
                <th>Sub-category</th>
                <th>UOM</th>
                <th class="num">Cost / unit (incl. GST)</th>
                <th>Source</th>
                <th>Details</th>
                <th>Last updated</th>
                <th></th>
            </tr>
        </thead>
        <tbody id="rows">
        <% for (Map<String, Object> it : items) {
               BigDecimal cost = (BigDecimal) it.get("cost");
               String source = (String) it.get("source");
               boolean noPo = it.get("poCost") == null;
               String f = cost == null ? "none" : ("PO".equals(source) ? "po" : "manual");
               String cat = it.get("category") == null ? "" : ((String) it.get("category")).trim();
               String sub = it.get("subcategory") == null ? "" : ((String) it.get("subcategory")).trim();
               String text = (it.get("name") + " " + cat + " " + sub).toLowerCase(Locale.ROOT);
        %>
            <tr data-f="<%= f %>" data-text="<%= esc(text) %>" data-cat="<%= esc(cat) %>" data-sub="<%= esc(sub) %>">
                <td><%= esc(it.get("name")) %></td>
                <td><%= esc(cat) %></td>
                <td><%= esc(sub) %></td>
                <td><%= esc(it.get("uom")) %></td>
                <td class="num cost"><%= cost == null ? "<span class='muted'>—</span>" : inr(cost) %></td>
                <td>
                    <% if (cost == null) { %><span class="badge b-none">No cost</span>
                    <% } else if ("PO".equals(source)) { %><span class="badge b-po">PO</span>
                    <% } else { %><span class="badge b-man">Manual</span><% } %>
                    <% if (Boolean.TRUE.equals(it.get("pending"))) { %>
                        <div style="margin-top:4px"><span class="badge b-chg" title="Latest approved PO cost">PO now <%= inr((BigDecimal) it.get("poCost")) %></span></div>
                    <% } %>
                </td>
                <td class="muted">
                    <% if ("PO".equals(source)) { %>
                        <%= esc(it.get("poNumber")) %><%= it.get("poDate") == null ? "" : " &middot; " + esc(poDate(it.get("poDate"))) %>
                        <%= it.get("gst") == null ? "" : " &middot; GST " + esc(pct((BigDecimal) it.get("gst"))) %>
                    <% } else if ("MANUAL".equals(source)) { %>
                        <%= esc(bases.getOrDefault((String) it.get("basis"), String.valueOf(it.get("basis")))) %>
                        <%= it.get("reference") == null ? "" : "<br>" + esc(it.get("reference")) %>
                    <% } %>
                </td>
                <td class="muted"><%= esc(it.get("by")) %><%= it.get("at") == null ? "" : "<br>" + when(it.get("at")) %></td>
                <td>
                    <% if (noPo) { %>
                        <button type="button" class="btn btn-sm pick"
                                data-id="<%= it.get("id") %>" data-label="<%= esc(label(it)) %>"
                                data-cost="<%= "MANUAL".equals(source) ? plain(cost) : "" %>"
                                data-basis="<%= "MANUAL".equals(source) ? esc(it.get("basis")) : "" %>"
                                data-ref="<%= "MANUAL".equals(source) ? esc(it.get("reference")) : "" %>">
                            <i class="fa-solid fa-pen"></i> <%= cost == null ? "Add cost" : "Edit" %></button>
                    <% } else { %>
                        <span class="muted" title="Cost comes from the approved Purchase Order"><i class="fa-solid fa-lock"></i></span>
                    <% } %>
                </td>
            </tr>
        <% } %>
        <tr id="noRows" class="hidden"><td colspan="9" class="empty">No items match.</td></tr>
        </tbody>
    </table>
    </div>
</div>

<div class="card">
    <div class="header-area" style="margin-bottom:12px">
        <div class="icon-box" style="background:#514f4d"><i class="fa-solid fa-clock-rotate-left"></i></div>
        <div><h2>Recent Cost Changes</h2><div class="sub">Last 25 changes in this store (audit trail).</div></div>
    </div>
    <div class="table-wrap">
    <table>
        <thead><tr><th>Changed on</th><th>Item</th><th class="num">Old cost</th><th class="num">New cost</th><th>Source</th><th>Details</th><th>Changed by</th></tr></thead>
        <tbody>
        <% if (history == null || history.isEmpty()) { %>
            <tr><td colspan="7" class="empty">No cost changes yet.</td></tr>
        <% } else { for (Map<String, Object> h : history) { %>
            <tr>
                <td><%= when(h.get("at")) %></td>
                <td><%= esc(h.get("item")) %></td>
                <td class="num"><%= h.get("oldCost") == null ? "<span class='muted'>—</span>" : inr((BigDecimal) h.get("oldCost")) %></td>
                <td class="num cost"><%= inr((BigDecimal) h.get("newCost")) %></td>
                <td><span class="badge <%= "PO".equals(h.get("source")) ? "b-po" : "b-man" %>"><%= "PO".equals(h.get("source")) ? "PO" : "Manual" %></span></td>
                <td class="muted"><%= "PO".equals(h.get("source")) ? esc(h.get("poNumber"))
                        : esc(bases.getOrDefault((String) h.get("basis"), String.valueOf(h.get("basis")))) + (h.get("reference") == null ? "" : " &middot; " + esc(h.get("reference"))) %></td>
                <td><%= esc(h.get("by")) %></td>
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
    var rows = Array.prototype.slice.call(document.querySelectorAll('#rows tr[data-f]'));
    var noRows = document.getElementById('noRows');
    var search = document.getElementById('search');
    var shown = document.getElementById('shown');
    var filter = 'all';
    var fCat = document.getElementById('fCat'), fSub = document.getElementById('fSub');

    // category -> sorted list of its sub-categories, read from the table rows
    var subsOf = {};
    rows.forEach(function (tr) {
        var c = tr.getAttribute('data-cat'), s = tr.getAttribute('data-sub');
        (subsOf[c] = subsOf[c] || {})[s] = true;
    });

    function fillSubs() {
        var keep = fSub.value, set = {};
        Object.keys(subsOf).forEach(function (c) {
            if (fCat.value === '*' || fCat.value === c) Object.keys(subsOf[c]).forEach(function (s) { set[s] = true; });
        });
        while (fSub.options.length > 1) fSub.remove(1);
        var list = Object.keys(set).sort(function (a, b) { return a.localeCompare(b, 'en', {sensitivity: 'base'}); });
        list.forEach(function (s) {
            if (s === '') return;
            var o = document.createElement('option');
            o.value = s;
            o.textContent = s;
            fSub.appendChild(o);
        });
        if (set['']) {
            var o = document.createElement('option');
            o.value = '';
            o.textContent = '(No sub-category)';
            fSub.appendChild(o);
        }
        fSub.value = (keep in set) ? keep : '*';
    }

    function apply() {
        var q = (search.value || '').trim().toLowerCase(), n = 0;
        var c = fCat.value, s = fSub.value;
        rows.forEach(function (tr) {
            var ok = (filter === 'all' || tr.getAttribute('data-f') === filter)
                  && (c === '*' || tr.getAttribute('data-cat') === c)
                  && (s === '*' || tr.getAttribute('data-sub') === s)
                  && (!q || tr.getAttribute('data-text').indexOf(q) !== -1);
            tr.classList.toggle('hidden', !ok);
            if (ok) n++;
        });
        noRows.classList.toggle('hidden', n !== 0);
        shown.textContent = 'Showing ' + n + ' of ' + rows.length + ' items';
    }
    search.addEventListener('input', apply);
    fCat.addEventListener('change', function () { fillSubs(); apply(); });
    fSub.addEventListener('change', apply);
    document.getElementById('clearFilters').addEventListener('click', function () {
        fCat.value = '*';
        fillSubs();
        fSub.value = '*';
        search.value = '';
        apply();
    });
    fillSubs();
    Array.prototype.forEach.call(document.querySelectorAll('.tile'), function (t) {
        t.addEventListener('click', function () {
            document.querySelectorAll('.tile').forEach(function (x) { x.classList.remove('active'); });
            t.classList.add('active');
            filter = t.getAttribute('data-filter');
            apply();
        });
    });

    // ---- manual form: the visible item text must match an item in the list; its id goes in the hidden field
    var allowed = {};
    Array.prototype.forEach.call(document.querySelectorAll('#manualItems option'), function (o) { allowed[o.value] = true; });
    var itemText = document.getElementById('itemText'), itemId = document.getElementById('itemId');
    function syncItem() {
        var m = /\[#(\d+)\]\s*$/.exec(itemText.value || '');
        var ok = m && allowed[itemText.value];
        itemId.value = ok ? m[1] : '';
        itemText.setCustomValidity(itemText.value && !ok ? 'Select an item from the list' : '');
    }
    itemText.addEventListener('input', syncItem);
    syncItem();

    document.getElementById('rows').addEventListener('click', function (e) {
        var b = e.target.closest('button.pick');
        if (!b) return;
        itemText.value = b.getAttribute('data-label');
        syncItem();
        document.getElementById('cost').value = b.getAttribute('data-cost');
        document.getElementById('basis').value = b.getAttribute('data-basis');
        document.getElementById('reference').value = b.getAttribute('data-ref');
        document.getElementById('manualTitle').scrollIntoView({behavior: 'smooth', block: 'start'});
        document.getElementById('cost').focus({preventScroll: true});
    });

    document.getElementById('manualForm').addEventListener('submit', function (e) {
        syncItem();
        var cost = parseFloat(document.getElementById('cost').value);
        var basis = document.getElementById('basis').value;
        if (!itemId.value) { e.preventDefault(); this.reportValidity(); return; }
        if (cost === 0 && basis !== 'DONATION') {
            e.preventDefault();
            window.alert('Cost must be more than ₹0. ₹0 is allowed only for Donation / free supply.');
        }
    });
    apply();
})();
</script>
</body>
</html>
