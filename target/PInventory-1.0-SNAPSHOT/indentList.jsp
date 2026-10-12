<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.bean.IndentItemFull" %>

<%!
// HTML-escape any value; null -> ""
private static String esc(Object o) {
    if (o == null) return "";
    return String.valueOf(o).replace("&","&amp;").replace("<","&lt;")
           .replace(">","&gt;").replace("\"","&quot;");
}
// show "-" for empty values
private static String dash(Object o) {
    String s = (o == null) ? "" : String.valueOf(o).trim();
    return (s.isEmpty() || "null".equalsIgnoreCase(s)) ? "-" : esc(s);
}
// colour class for status pills
private static String pillClass(String s) {
    if (s == null) return "warn";
    s = s.trim().toLowerCase();
    if (s.isEmpty() || s.equals("pending")) return "warn";
    if (s.equals("cancelled") || s.equals("rejected")) return "bad";
    return "ok";
}
%>
<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}

List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
if (indents == null) indents = new ArrayList<>();

// Left = Purchase, Right = Issue
List<IndentItemFull> purchaseList = new ArrayList<>();
List<IndentItemFull> issueList    = new ArrayList<>();
for (IndentItemFull i : indents) {
    if ("Issue".equalsIgnoreCase(i.getPurchaseorIssue() == null ? "" : i.getPurchaseorIssue().trim()))
        issueList.add(i);
    else
        purchaseList.add(i);
}

List<List<IndentItemFull>> panes = new ArrayList<>();
panes.add(purchaseList);
panes.add(issueList);
String[] paneTitles  = {"Purchase Indents", "Issue Indents"};
String[] paneClasses = {"pane-purchase", "pane-issue"};
String[] tableIds    = {"tblPurchase", "tblIssue"};
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Indent Full Report</title>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
:root {
  --sf-blue: #0176d3;
  --sf-blue-dark: #014486;
  --sf-navy: #032d60;
  --sf-bg: #f3f3f3;
  --sf-border: #dddbda;
  --sf-border-soft: #ecebea;
  --sf-text: #181818;
  --sf-muted: #5c5c5c;
  --sf-green: #2e844a;
  --sf-green-bg: #ebf7e6;
  --sf-amber: #b45f06;
  --sf-amber-bg: #fef1d6;
  --sf-red: #ba0517;
  --sf-red-bg: #fde8ea;
  --sf-purchase: #fe9339;
  --sf-issue: #2e844a;
}

* { box-sizing: border-box; }

body {
  font-family: 'Salesforce Sans', 'Segoe UI', 'Inter', Arial, sans-serif;
  background: var(--sf-bg);
  color: var(--sf-text);
  margin: 0;
  padding: 0;
  font-size: 12px;
  line-height: 1.35;
  -webkit-tap-highlight-color: transparent;
}

.main-content { width: 100%; padding: 10px 12px 24px; }

/* ---------- Page title + toolbar ---------- */
.page-head {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}
.icon-box {
  width: 28px; height: 28px;
  border-radius: 4px;
  background: var(--sf-blue);
  color: #fff;
  display: flex; align-items: center; justify-content: center;
  font-size: 13px;
  flex-shrink: 0;
}
.page-head h1 {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: var(--sf-navy);
}
.page-head .total { color: var(--sf-muted); font-size: 11.5px; }

.search-bar {
  background: #fff;
  border: 1px solid var(--sf-border);
  border-radius: 4px;
  padding: 8px 10px;
  margin-bottom: 10px;
  display: flex;
  flex-wrap: wrap;
  gap: 8px 10px;
  align-items: flex-end;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1 1 130px;
  min-width: 110px;
}
.filter-group.grow { flex: 2 1 200px; }

.search-bar label {
  font-size: 10px;
  font-weight: 700;
  color: var(--sf-muted);
  text-transform: uppercase;
  letter-spacing: .4px;
  white-space: nowrap;
}

.search-bar input[type="text"],
.search-bar input[type="date"],
#deptFilter,
#statusFilter {
  height: 28px;
  padding: 0 8px;
  border: 1px solid #c9c7c5;
  border-radius: 4px;
  font-family: inherit;
  font-size: 12px;
  background: #fff;
  outline: none;
  width: 100%;
}
.search-bar input:focus, #statusFilter:focus, #deptFilter:focus {
  border-color: var(--sf-blue);
  box-shadow: 0 0 0 1px var(--sf-blue);
}

.actions-group { display: flex; flex-wrap: wrap; gap: 6px; margin-left: auto; align-items: center; }

.btn {
  height: 28px;
  padding: 0 11px;
  border: 1px solid var(--sf-blue);
  background: var(--sf-blue);
  color: #fff;
  border-radius: 4px;
  cursor: pointer;
  font-family: inherit;
  font-size: 11.5px;
  font-weight: 600;
  display: inline-flex; align-items: center; justify-content: center; gap: 5px;
  white-space: nowrap;
  transition: background .15s;
}
.btn:hover { background: var(--sf-blue-dark); border-color: var(--sf-blue-dark); }
.btn-success { background: var(--sf-green); border-color: var(--sf-green); }
.btn-success:hover { background: #1b5e30; border-color: #1b5e30; }
.btn-secondary { background: #fff; border-color: #c9c7c5; color: var(--sf-text); }
.btn-secondary:hover { background: #f4f6f9; border-color: #a8a6a4; }

/* ---------- Two-pane split ---------- */
.split {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 12px;
  align-items: start;
}
.pane { min-width: 0; }

.pane-title {
  display: flex; align-items: center; justify-content: space-between;
  background: var(--sf-navy);
  color: #fff;
  padding: 7px 12px;
  border-radius: 4px 4px 0 0;
  border-top: 3px solid var(--sf-purchase);
}
.pane-issue .pane-title { border-top-color: var(--sf-issue); }
.pane-title h2 {
  margin: 0;
  font-size: 12.5px; font-weight: 700;
  letter-spacing: .6px; text-transform: uppercase;
}
.pane-count {
  background: rgba(255,255,255,.18);
  border-radius: 10px;
  padding: 1px 9px;
  font-size: 11px; font-weight: 700;
}

.table-container {
  width: 100%;
  overflow-x: auto;
  background: #fff;
  border: 1px solid var(--sf-border);
  border-top: none;
  border-radius: 0 0 4px 4px;
  scrollbar-width: thin;
}
.pane.collapsed .table-container { display: none; }

/* ---------- Table ---------- */
.main-table {
  width: 100%;
  min-width: 640px;
  border-collapse: collapse;
  table-layout: fixed;
  background: #fff;
}

.main-table th {
  background: #fafaf9;
  color: var(--sf-muted);
  padding: 5px 6px;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: .3px;
  border-bottom: 1px solid var(--sf-border);
  text-align: left;
  white-space: nowrap;
  cursor: pointer;
  user-select: none;
  overflow: hidden;
  text-overflow: ellipsis;
}
.main-table th:hover { color: var(--sf-blue); }
.main-table th i { margin-left: 2px; font-size: 8px; color: #9b9a98; }
.main-table th.no-sort { cursor: default; }
.main-table th.no-sort:hover { color: var(--sf-muted); }

.main-table td {
  padding: 4px 6px;
  text-align: left;
  vertical-align: middle;
  border-bottom: 1px solid var(--sf-border-soft);
  overflow: hidden;
  text-overflow: ellipsis;
  font-size: 11.5px;
}
.main-table tbody tr:last-child td { border-bottom: none; }
.main-table tbody tr.data-row:hover td { background: #f3f9ff; }

/* column widths: Indent | Date | Item | Avl | Req | Purpose | L1 | L2 | Action */
.main-table th:nth-child(1), .main-table td:nth-child(1) { width: 10%; }
.main-table th:nth-child(2), .main-table td:nth-child(2) { width: 11%; white-space: nowrap; }
.main-table th:nth-child(3), .main-table td:nth-child(3) { width: 21%; }
.main-table th:nth-child(4), .main-table td:nth-child(4) { width: 6%;  text-align: right; }
.main-table th:nth-child(5), .main-table td:nth-child(5) { width: 8%;  text-align: right; }
.main-table th:nth-child(6), .main-table td:nth-child(6) { width: 14%; }
.main-table th:nth-child(7), .main-table td:nth-child(7) { width: 13%; }
.main-table th:nth-child(8), .main-table td:nth-child(8) { width: 12%; }
.main-table th:nth-child(9), .main-table td:nth-child(9) { width: 5%;  text-align: center; }

.indent-no  { font-weight: 700; color: var(--sf-blue); white-space: nowrap; }
.sub        { display: block; color: var(--sf-muted); font-size: 10.5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.item-name  { display: block; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.avl        { color: #c55a00; font-weight: 700; }
.req        { font-weight: 700; color: var(--sf-blue-dark); }
.uom        { color: var(--sf-muted); font-size: 10px; margin-left: 2px; }
.purpose    { color: var(--sf-muted); white-space: normal; word-break: break-word; overflow-wrap: anywhere; line-height: 1.3; }

/* status pills */
.pill {
  display: inline-block;
  padding: 1px 8px;
  border-radius: 10px;
  font-size: 10px; font-weight: 700;
  text-transform: uppercase; letter-spacing: .3px;
  white-space: nowrap;
}
.pill.ok   { background: var(--sf-green-bg); color: var(--sf-green); }
.pill.warn { background: var(--sf-amber-bg); color: var(--sf-amber); }
.pill.bad  { background: var(--sf-red-bg);   color: var(--sf-red); }

/* print button */
.print-form { margin: 0; display: flex; justify-content: center; }
.print-action-btn {
  width: 24px; height: 24px;
  background: #fff;
  border: 1px solid var(--sf-blue);
  color: var(--sf-blue);
  border-radius: 4px;
  font-size: 11px;
  cursor: pointer;
  display: inline-flex; align-items: center; justify-content: center;
  transition: all .15s;
}
.print-action-btn:hover { background: var(--sf-blue); color: #fff; }

.empty-row td { text-align: center !important; color: var(--sf-muted); padding: 18px 6px; white-space: normal; }

/* ---------- Responsive ---------- */
@media (max-width: 1100px) {
  .split { grid-template-columns: 1fr; }
  .actions-group { width: 100%; margin-left: 0; }
  .actions-group .btn { flex: 1 1 auto; }
}
@media (max-width: 600px) {
  .main-content { padding: 8px 6px 20px; }
}
</style>
</head>

<body>

<%@ include file="header.jsp" %>

<div class="main-content">

  <div class="page-head">
    <div class="icon-box"><i class="fa fa-file-invoice"></i></div>
    <h1>Indents Report</h1>
    <span class="total">&middot; <%= indents.size() %> items</span>
  </div>

  <div class="search-bar">
    <div class="filter-group grow">
      <label>Keyword Search</label>
      <input type="text" id="keywordSearch" placeholder="Search by any field..." onkeyup="filterTable()">
    </div>

    <div class="filter-group">
      <label>From Date</label>
      <input type="date" id="fromDate" onchange="filterTable()">
    </div>

    <div class="filter-group">
      <label>To Date</label>
      <input type="date" id="toDate" onchange="filterTable()">
    </div>

    <div class="filter-group">
      <label>Department</label>
      <select id="deptFilter" onchange="filterTable()">
        <option value="">All Departments</option>
        <option value="Electrical">Electrical</option>
        <option value="Housekeeping">Housekeeping</option>
        <option value="Plumbing">Plumbing</option>
        <option value="Dining Hall">Dining Hall</option>
        <option value="RO Plant">RO Plant</option>
        <option value="Store">Store</option>
        <option value="Academics">Academics</option>
        <option value="Finance">Finance</option>
      </select>
    </div>

    <div class="filter-group">
      <label>Status</label>
      <select id="statusFilter" onchange="filterTable()">
        <option value="">All Status</option>
        <option value="pending">Pending</option>
        <option value="approved">Approved</option>
        <option value="cancelled">Cancelled</option>
      </select>
    </div>

    <div class="actions-group">
      <button class="btn" onclick="filterTable()"><i class="fa fa-filter"></i> Filter</button>
      <button class="btn btn-secondary" onclick="resetFilters()"><i class="fa fa-rotate-left"></i> Reset</button>
      <button class="btn btn-success" onclick="downloadExcel()"><i class="fa fa-file-excel"></i> Download Excel</button>
      <button id="expandAll" class="btn btn-secondary" onclick="toggleExpand()">Collapse All</button>
    </div>
  </div>

  <div class="split">

  <% for (int p = 0; p < panes.size(); p++) {
       List<IndentItemFull> list = panes.get(p);
       String tid = tableIds[p];
  %>
    <section class="pane <%= paneClasses[p] %>">

      <div class="pane-title">
        <h2><%= paneTitles[p] %></h2>
        <span class="pane-count"><%= list.size() %></span>
      </div>

      <div class="table-container">
        <table id="<%= tid %>" class="main-table">
          <thead>
            <tr>
              <th onclick="sortTable('<%= tid %>',0)">Indent <i class="fa fa-sort"></i></th>
              <th onclick="sortTable('<%= tid %>',1)">Date <i class="fa fa-sort"></i></th>
              <th onclick="sortTable('<%= tid %>',2)">Item <i class="fa fa-sort"></i></th>
              <th onclick="sortTable('<%= tid %>',3)">Avl <i class="fa fa-sort"></i></th>
              <th onclick="sortTable('<%= tid %>',4)">Req <i class="fa fa-sort"></i></th>
              <th onclick="sortTable('<%= tid %>',5)">Purpose <i class="fa fa-sort"></i></th>
              <th onclick="sortTable('<%= tid %>',6)">L1 Status <i class="fa fa-sort"></i></th>
              <th onclick="sortTable('<%= tid %>',7)">L2 Status <i class="fa fa-sort"></i></th>
              <th class="no-sort"></th>
            </tr>
          </thead>
          <tbody>
          <% if (list.isEmpty()) { %>
            <tr class="empty-row"><td colspan="9">No records found</td></tr>
          <% } else {
               for (IndentItemFull ind : list) {
                 String istatus = ind.getIstatus();
                 String status  = ind.getStatus();
                 String l1Text  = (istatus == null || istatus.trim().isEmpty()) ? "Pending" : istatus;
                 String l2Text  = (status  == null || status.trim().isEmpty())  ? "Pending" : status;
                 String l1Class = "Approved".equalsIgnoreCase(istatus) ? "ok" : "bad";
                 String l2Class = pillClass(status);
                 String statusKey = "bad".equals(l2Class) ? "cancelled" : ("ok".equals(l2Class) ? "approved" : "pending");
                 String typeVal = (ind.getPurchaseorIssue() == null || ind.getPurchaseorIssue().trim().isEmpty()) ? "-" : ind.getPurchaseorIssue().trim();
          %>
            <tr class="data-row"
                data-dept="<%= esc(ind.getDepartment()) %>"
                data-status="<%= statusKey %>"
                data-date="<%= esc(ind.getDate()) %>"
                data-id="<%= esc(ind.getId()) %>"
                data-no="<%= esc(ind.getIndentNo()) %>"
                data-type="<%= esc(typeVal) %>"
                data-item="<%= esc(ind.getItemName()) %>"
                data-avl="<%= esc(ind.getBalanceQty()) %>"
                data-req="<%= esc(ind.getQty()) %>"
                data-uom="<%= esc(ind.getUom()) %>"
                data-by="<%= esc(ind.getRequestedBy()) %>"
                data-purpose="<%= esc(ind.getPurpose()) %>"
                data-l1="<%= esc(l1Text) %>"
                data-l1by="<%= esc(ind.getApprovedBy()) %>"
                data-l1date="<%= esc(ind.getIapprovevdate()) %>"
                data-l2="<%= esc(l2Text) %>"
                data-l2date="<%= esc(ind.getFapprovevdate()) %>"
                data-next="<%= esc(ind.getIndentNext()) %>">

              <td data-sort="<%= esc(ind.getIndentNo()) %>">
                <span class="indent-no">#<%= esc(ind.getIndentNo()) %></span>
                <span class="sub">ID <%= esc(ind.getId()) %></span>
              </td>

              <td data-sort="<%= esc(ind.getDate()) %>"><%= dash(ind.getDate()) %></td>

              <td data-sort="<%= esc(ind.getItemName()) %>" title="<%= esc(ind.getItemName()) %>">
                <span class="item-name"><%= esc(ind.getItemName()) %></span>
                <span class="sub"><%= esc(ind.getDepartment()) %> &middot; <%= esc(ind.getRequestedBy()) %></span>
              </td>

              <td data-sort="<%= esc(ind.getBalanceQty()) %>"><span class="avl"><%= esc(ind.getBalanceQty()) %></span></td>

              <td data-sort="<%= esc(ind.getQty()) %>"><span class="req"><%= esc(ind.getQty()) %></span><span class="uom"><%= esc(ind.getUom()) %></span></td>

              <td class="purpose" title="<%= esc(ind.getPurpose()) %>"><%= esc(ind.getPurpose()) %></td>

              <td data-sort="<%= esc(l1Text) %>">
                <span class="pill <%= l1Class %>"><%= esc(l1Text) %></span>
                <% if (ind.getApprovedBy() != null && !ind.getApprovedBy().trim().isEmpty()) { %>
                  <span class="sub">By: <%= esc(ind.getApprovedBy()) %></span>
                <% } %>
                <span class="sub"><%= dash(ind.getIapprovevdate()) %></span>
              </td>

              <td data-sort="<%= esc(l2Text) %>">
                <span class="pill <%= l2Class %>"><%= esc(l2Text) %></span>
                <% if (ind.getIndentNext() != null && !ind.getIndentNext().trim().isEmpty()) { %>
                  <span class="sub">Next: <%= esc(ind.getIndentNext()) %></span>
                <% } %>
                <span class="sub"><%= dash(ind.getFapprovevdate()) %></span>
              </td>

              <td>
                <form action="PrintIndent.jsp" method="get" class="print-form">
                  <input type="hidden" name="IndentNumber" value="<%= esc(ind.getIndentNo()) %>">
                  <button type="submit" class="print-action-btn" title="View / Print">
                    <i class="fa fa-print"></i>
                  </button>
                </form>
              </td>
            </tr>
          <% } } %>
          </tbody>
        </table>
      </div>
    </section>
  <% } %>

  </div>
</div>

<script>
/* ---------- Sorting (per table) ---------- */
function sortTable(tid, n) {
  const t = document.getElementById(tid);
  const tb = t.tBodies[0];
  const rows = Array.from(tb.querySelectorAll('tr.data-row'));
  const dir = (t.dataset.col == n && t.dataset.dir === 'asc') ? 'desc' : 'asc';
  t.dataset.col = n;
  t.dataset.dir = dir;

  const val = r => {
    const c = r.cells[n];
    const s = (c.dataset.sort !== undefined ? c.dataset.sort : c.innerText).trim().toLowerCase();
    const f = parseFloat(s);
    return (!isNaN(f) && /^-?[\d.]+$/.test(s)) ? f : s;
  };

  rows.sort((a, b) => {
    const x = val(a), y = val(b);
    if (x < y) return dir === 'asc' ? -1 : 1;
    if (x > y) return dir === 'asc' ? 1 : -1;
    return 0;
  });
  rows.forEach(r => tb.appendChild(r));
}

/* ---------- Filtering (both tables) ---------- */
function updateCounts() {
  document.querySelectorAll('.pane').forEach(p => {
    const n = Array.from(p.querySelectorAll('tbody tr.data-row'))
                   .filter(r => r.style.display !== 'none').length;
    p.querySelector('.pane-count').textContent = n;
  });
}

function filterTable() {
  const fromDate = document.getElementById('fromDate').value;
  const toDate = document.getElementById('toDate').value;
  const keyword = document.getElementById('keywordSearch').value.toLowerCase().trim();
  const selectedDept = document.getElementById('deptFilter').value.toLowerCase().trim();
  const selectedStatus = document.getElementById('statusFilter').value;

  document.querySelectorAll('#tblPurchase tbody tr.data-row, #tblIssue tbody tr.data-row').forEach(row => {
    const deptCell = (row.dataset.dept || '').toLowerCase().trim();
    const textMatch = keyword === '' || row.innerText.toLowerCase().includes(keyword);
    const deptMatch = selectedDept === '' || deptCell === selectedDept;
    const statusMatch = selectedStatus === '' || row.dataset.status === selectedStatus;

    let dateMatch = true;
    if (fromDate || toDate) {
      const rowDate = new Date(row.dataset.date);
      const from = fromDate ? new Date(fromDate) : null;
      const to = toDate ? new Date(toDate) : null;
      if (!isNaN(rowDate.getTime())) {
        if (from && rowDate < from) dateMatch = false;
        if (to && rowDate > to) dateMatch = false;
      }
    }
    row.style.display = (textMatch && dateMatch && deptMatch && statusMatch) ? '' : 'none';
  });
  updateCounts();
}

function resetFilters() {
  document.getElementById('fromDate').value = '';
  document.getElementById('toDate').value = '';
  document.getElementById('keywordSearch').value = '';
  document.getElementById('deptFilter').value = '';
  document.getElementById('statusFilter').value = '';
  document.querySelectorAll('tr.data-row').forEach(r => r.style.display = '');
  updateCounts();
}

/* ---------- Excel / CSV export (full 17 columns, visible rows only) ---------- */
function downloadExcel() {
  const cols = [
    ['ID','id'], ['Indent No','no'], ['Type','type'], ['Date','date'], ['Item','item'],
    ['Avail. Qty','avl'], ['Req. Qty','req'], ['UOM','uom'], ['Dept','dept'],
    ['Requested By','by'], ['Purpose','purpose'], ['L1 Status','l1'], ['L1 Approved By','l1by'],
    ['IApproveDate','l1date'], ['L2 Status','l2'], ['FApproveDate','l2date'], ['Indent Status','next']
  ];
  const q = s => '"' + String(s == null ? '' : s).replace(/\r?\n/g, ' ').replace(/"/g, '""').trim() + '"';

  const csv = [cols.map(c => q(c[0])).join(',')];
  document.querySelectorAll('#tblPurchase tbody tr.data-row, #tblIssue tbody tr.data-row').forEach(row => {
    if (row.style.display === 'none') return;
    csv.push(cols.map(c => q(row.dataset[c[1]])).join(','));
  });

  const blob = new Blob(['\uFEFF' + csv.join('\n')], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = 'Indent_Full_Report.csv';
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

/* ---------- Collapse / expand both panes ---------- */
let expanded = true;
function toggleExpand() {
  expanded = !expanded;
  document.querySelectorAll('.pane').forEach(p => p.classList.toggle('collapsed', !expanded));
  document.getElementById('expandAll').innerText = expanded ? 'Collapse All' : 'Expand All';
}
</script>

</body>
</html>
