<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.bean.IndentItemFull" %>
<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Indent Full Report</title>

<!-- Fonts & Icons -->
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
body {
  font-family: 'Poppins', sans-serif;
  background-color: #f5f7fa;
  margin: 0;
  padding: 0;
  overflow-x: hidden;
}


.main-content {
  width: 100%;
  padding: 10px;
  box-sizing: border-box;
}


.card {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 3px 10px rgba(0,0,0,0.1);
  padding: 15px;
  width: 100%;
  overflow-x: auto;
}


.main-table {
  width: 100%;
  border-collapse: collapse;
  table-layout: fixed;
  word-wrap: break-word;
}
.main-table th, .main-table td {
  padding: 8px;
  text-align: center;
  border: 1px solid #ddd;
  vertical-align: middle;
  white-space: normal;
  word-break: break-word;
}

thead {
  background:  #0f2a4d;
}

.main-table th {
  
  color: white;
  cursor: pointer;
  position: sticky;
  top: 0;
  z-index: 1;
}
.main-table tr:nth-child(even) {
  background-color: #f9f9f9;
}


.search-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 15px;
  align-items: center;
}
.search-bar input[type="text"], .search-bar input[type="date"] {
  padding: 6px 10px;
  border: 1px solid #ccc;
  border-radius: 6px;
  flex: 1;
  min-width: 120px;
}
.btn {
  padding: 6px 14px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  transition: 0.3s;
}
.btn-info {
  background-color: #007bff;
  color: white;
}
.btn-info:hover {
  background-color: #0056b3;
}
#expandAll {
  background-color: #28a745;
  color: #fff;
}
#expandAll:hover {
  background-color: #218838;
}


@media (max-width: 992px) {
  .card {
    padding: 10px;
  }
  h1 {
    font-size: 20px;
  }
  .search-bar {
    flex-direction: column;
    align-items: stretch;
  }
  .main-table th, .main-table td {
    font-size: 12px;
    padding: 6px;
  }
  .btn {
    width: 100%;
  }
}


footer {
  text-align: center;
  padding: 10px;
  margin-top: 30px;
  font-size: 14px;
  color: #666;
  border-top: 1px solid #ddd;
}
footer i {
  color: green;
}
</style>
</head>

<body>

<%@ include file="header.jsp" %>

<div class="main-content">
  <div class="card">
    <h1 style="text-align:center;">Indents Report</h1>
    <br>

    <div class="search-bar">
      <input type="text" id="keywordSearch" placeholder="Search by any field..." onkeyup="filterTable()">
      <label>From: <input type="date" id="fromDate"></label>
      <label>To: <input type="date" id="toDate"></label>
      <button class="btn btn-info" onclick="filterTable()">Filter</button>
      <button class="btn btn-info" onclick="resetFilters()">Reset</button>
      <button class="btn btn-info" onclick="downloadExcel()">Download Excel</button>
      <button id="expandAll" class="btn" onclick="toggleExpand()">Collapse All</button>
    </div>
<select id="deptFilter" style="padding:6px 10px; border:1px solid #ccc; border-radius:6px; min-width:160px;">
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

<button class="btn btn-info" onclick="filterDept()">Filter by Dept</button>
    <table id="dataTable" class="main-table">
      <thead>
        <tr>
          <th onclick="sortTable(0)">ID</th>
          <th onclick="sortTable(1)">Indent No</th>
          <th onclick="sortTable(2)">Date</th>
          <th onclick="sortTable(3)">Item</th>
          <th>Avail. Qty</th>
          <th>Req. Qty</th>
          <th>UOM</th>
          <th>Dept</th>
          <th>Requested By</th>
          <th>Purpose</th>
          <th>L1 Status</th>
          <th>IApproveDate</th>
          <th>L2 Status</th>
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
              String istatus = ind.getIstatus();
              String status = ind.getStatus();
              String istatusStyle = "Approved".equalsIgnoreCase(istatus) ? "color:green;font-weight:bold;" : "color:red;font-weight:bold;";
              String statusStyle = (status == null || status.trim().isEmpty() || "pending".equalsIgnoreCase(status))
                ? "color:red;font-weight:bold;" : "color:green;font-weight:bold;";
        %>
        <tr class="data-row">
          <td><%= ind.getId() %></td>
          <td><%= ind.getIndentNo() %></td>
          <td><%= ind.getDate() %></td>
          <td><%= ind.getItemName() %></td>
          <td><%= ind.getBalanceQty() %></td>
          <td><%= ind.getQty() %></td>
          <td><%= ind.getUom() %></td>
          <td><%= ind.getDepartment() %></td>
          <td><%= ind.getRequestedBy() %></td>
          <td><%= ind.getPurpose() %></td>
          <td style="<%= istatusStyle %>"><%= (istatus == null || istatus.trim().isEmpty()) ? "Pending" : istatus %></td>
          <td><%= ind.getIapprovevdate() %></td>
          <td style="<%= statusStyle %>"><%= (status == null || status.trim().isEmpty()) ? "Pending" : status %></td>
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
        <tr><td colspan="16" style="text-align:center;color:red;">No records found</td></tr>
        <% } %>
      </tbody>
    </table>
  </div>
</div>
<a href="IndentServlet"><i class="fas fa-plus-circle text-success"></i> Item Requisition Form</a>

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
  const rows = table.querySelectorAll('tr');
  rows.forEach(row => {
    let cols = row.querySelectorAll('th, td');
    let rowData = [];
    cols.forEach(cell => {
      let text = cell.innerText.replace(/\n/g, ' ').replace(/"/g, '""').trim();
      rowData.push('"' + text + '"');
    });
    csv.push(rowData.join(','));
  });
  const csvString = csv.join('\n');
  const blob = new Blob([csvString], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', 'Indent_Full_Report.csv');
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
function filterDept() {
	  const selectedDept = document.getElementById('deptFilter').value.toLowerCase();
	  const rows = document.querySelectorAll('#dataTable tbody tr');

	  rows.forEach(row => {
	    const dept = row.cells[7]?.innerText.toLowerCase(); // 8th column Dept
	    if (selectedDept === "" || dept === selectedDept) {
	      row.style.display = "";
	    } else {
	      row.style.display = "none";
	    }
	  });
	}

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
