<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.bean.IndentItemFull" %>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Indent Full Report</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="CSS/tablestyle.css">

<style>
body {
  font-family: 'Poppins', sans-serif;
  background-color: #f5f7fa;
  margin: 0;
  padding: 0;
}
.main-content {
  padding: 20px;
}
.card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 3px 10px rgba(0,0,0,0.1);
  padding: 20px;
}
.main-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 15px;
}
.main-table th, .main-table td {
  padding: 10px;
  text-align: center;
  border: 1px solid #ddd;
}
.main-table th {
  background-color: #007bff;
  color: white;
  cursor: pointer;
}
.main-table tr:nth-child(even) {
  background-color: #f9f9f9;
}
input[type="text"], input[type="date"] {
  padding: 6px 10px;
  border: 1px solid #ccc;
  border-radius: 6px;
}
.btn {
  padding: 6px 14px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}
.btn-info {
  background-color: #007bff;
  color: white;
}
.btn-info:hover {
  background-color: #0056b3;
}
.search-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 15px;
  align-items: center;
}
#expandAll {
  background-color: #28a745;
  color: #fff;
}
#expandAll:hover {
  background-color: #218838;
}
.hidden-row {
  display: none;
}
</style>
</head>

<body>

<%@ include file="header.jsp" %>

<div class="main-content">
  <div class="card">
    <h2 style="text-align:center;">Indent Full Report</h2>

    <div class="search-bar">
      <input type="text" id="keywordSearch" placeholder="Search by any field..." onkeyup="filterTable()">
      <label>From: <input type="date" id="fromDate"></label>
      <label>To: <input type="date" id="toDate"></label>
      <button class="btn btn-info" onclick="filterTable()">Filter</button>
      <button class="btn btn-info" onclick="resetFilters()">Reset</button>
      <button class="btn btn-info" onclick="downloadExcel()">Download Excel</button>
      <button id="expandAll" class="btn" onclick="toggleExpand()">Expand/Collapse All</button>
    </div>

    <table id="dataTable" class="main-table">
      <thead>
        <tr>
          <th onclick="sortTable(0)">ID</th>
          <th onclick="sortTable(1)">Indent No</th>
          <th onclick="sortTable(2)">Date</th>
          <th onclick="sortTable(3)">Item</th>
          <th>Qty</th>
          <th>Issued Qty</th>
          <th>UOM</th>
          <th>Dept</th>
          <th>Requested By</th>
          <th>Purpose</th>
          <th>IStatus</th>
          <th>IApproveDate</th>
          <th>Status</th>
          <th>FApproveDate</th>
          <th>Indent status</th>
          
          <th>View / Print</th>
        </tr>
      </thead>
      <tbody>
        <%
          List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
          if (indents != null && !indents.isEmpty()) {
            for (IndentItemFull ind : indents) {
        %>
        <tr class="data-row">
          <td><%= ind.getId() %></td>
          <td><%= ind.getIndentNo() %></td>
          <td><%= ind.getDate() %></td>
          <td><%= ind.getItemName() %></td>
          <td><%= ind.getQty() %></td>
          <td><%= ind.getBalanceQty() %></td>
          <td><%= ind.getUom() %></td>
          <td><%= ind.getDepartment() %></td>
          <td><%= ind.getRequestedBy() %></td>
          <td><%= ind.getPurpose() %></td>
          <td><%= ind.getIstatus() %></td>
          <td><%= ind.getIapprovevdate() %></td>
          <td><%= ind.getStatus() %></td>
          <td><%= ind.getFapprovevdate() %></td>
          <td><%= ind.getIndentNext() %></td>
          
          <td>
            <form action="PrintIndent.jsp" method="get">
              <input type="hidden" name="IndentNumber" value="<%= ind.getIndentNo() %>">
              <input class="btn btn-info" type="submit" value="View / Print">
            </form>
          </td>
        </tr>
        <% } } else { %>
        <tr><td colspan="17" style="text-align:center;color:red;">No records found</td></tr>
        <% } %>
      </tbody>
    </table>
  </div>
</div>

<jsp:include page="Footer.jsp" />

<!-- === SCRIPT BLOCK === -->
<script>
function sortTable(n) {
  let table = document.getElementById("dataTable"), switching = true, dir = "asc", switchcount = 0;
  while (switching) {
    switching = false;
    let rows = table.rows;
    for (let i = 1; i < (rows.length - 1); i++) {
      let shouldSwitch = false;
      let x = rows[i].getElementsByTagName("TD")[n];
      let y = rows[i + 1].getElementsByTagName("TD")[n];
      if (dir == "asc" && x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) shouldSwitch = true;
      else if (dir == "desc" && x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) shouldSwitch = true;
      if (shouldSwitch) {
        rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
        switching = true; switchcount++; break;
      }
    }
    if (switchcount == 0 && dir == "asc") { dir = "desc"; switching = true; }
  }
}

function filterTable() {
  const fromDate = document.getElementById('fromDate').value;
  const toDate = document.getElementById('toDate').value;
  const keyword = document.getElementById('keywordSearch').value.toLowerCase();
  const rows = document.querySelectorAll('#dataTable tbody tr');
  rows.forEach(row => {
    const dateCell = row.cells[2]?.innerText.trim();
    const textMatch = row.innerText.toLowerCase().includes(keyword);
    let dateMatch = true;
    if (fromDate || toDate) {
      const rowDate = new Date(dateCell);
      const from = fromDate ? new Date(fromDate) : null;
      const to = toDate ? new Date(toDate) : null;
      if (from && rowDate < from) dateMatch = false;
      if (to && rowDate > to) dateMatch = false;
    }
    row.style.display = (textMatch && dateMatch) ? '' : 'none';
  });
}

function resetFilters() {
  document.getElementById('fromDate').value = '';
  document.getElementById('toDate').value = '';
  document.getElementById('keywordSearch').value = '';
  document.querySelectorAll('#dataTable tbody tr').forEach(r => r.style.display = '');
}

function downloadExcel() {
  const table = document.getElementById('dataTable');
  let csv = [];
  for (let row of table.rows) {
    let cols = [];
    for (let cell of row.cells) {
      let text = cell.innerText.replace(/"/g, '""');
      cols.push(`"${text}"`);
    }
    csv.push(cols.join(","));
  }
  const blob = new Blob([csv.join("\n")], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = "Indent_Full_Report.csv";
  link.click();
}

// Expand/Collapse
let expanded = true;
function toggleExpand() {
  expanded = !expanded;
  const rows = document.querySelectorAll('.data-row');
  rows.forEach(row => row.style.display = expanded ? '' : 'none');
  document.getElementById("expandAll").innerText = expanded ? "Collapse All" : "Expand All";
}
</script>
</body>
</html>
