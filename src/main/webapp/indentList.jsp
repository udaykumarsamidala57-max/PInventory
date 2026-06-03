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
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
* { box-sizing: border-box; }
body {
  font-family: 'Poppins', sans-serif;
  background-color: #f3f3f3;
  margin: 0;
  padding: 0;
  color: #181818;
  -webkit-tap-highlight-color: transparent;
}

.main-content {
  width: 100%;
  max-width: 100%;
  margin: 0 auto;
  padding: 20px;
}

/* Salesforce Style Card Base - Clear View Configuration */
.card {
  background: #fff;
  border-radius: 4px;
  padding: 24px;
  width: 100%;
  border: 1px solid #c9c9c9;
  box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
  /* Completely open to prevent anything hiding internally */
  overflow: visible; 
}

.header-area {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 20px;
  border-bottom: 1px solid #e5e5e5;
  padding-bottom: 16px;
}

.icon-box {
  width: 40px;
  height: 40px;
  border-radius: 4px;
  background: #0176d3;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 18px;
}

h1 {
  margin: 0;
  font-size: 20px;
  color: #0176d3;
  font-weight: 700;
  text-align: left;
}

/* Salesforce Filter Toolbar Grid */
.search-bar {
  background: #fafaf9;
  border: 1px solid #c9c9c9;
  border-radius: 4px;
  padding: 16px;
  margin-bottom: 20px;
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  align-items: flex-end;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.search-bar label {
  font-size: 12px;
  font-weight: 700;
  color: #514f4d;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  white-space: nowrap;
}

.search-bar input[type="text"], 
.search-bar input[type="date"],
#deptFilter {
  height: 36px;
  padding: 0 12px;
  border: 1px solid #aeaeae;
  border-radius: 4px;
  font-family: inherit;
  font-size: 13px;
  background: #ffffff;
  outline: none;
  min-width: 160px;
}

.search-bar input:focus, 
#deptFilter:focus {
  border-color: #0176d3;
  box-shadow: 0 0 0 2px rgba(1,118,211,0.15);
}

.actions-group {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-left: auto;
}

/* Salesforce Lightning Action Buttons */
.btn {
  height: 36px;
  padding: 0 16px;
  border: 1px solid #0176d3;
  background: #0176d3;
  color: white;
  border-radius: 4px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  transition: all 0.1s ease;
}

.btn:hover { background: #015a9e; border-color: #015a9e; }

.btn-info {
  background-color: #0176d3;
  border-color: #0176d3;
  color: white;
}

.btn-secondary {
  background: #ffffff;
  border-color: #747472;
  color: #181818;
}
.btn-secondary:hover {
  background: #f4f6f9;
  border-color: #747472;
}

#expandAll {
  background-color: #ffffff;
  border-color: #747472;
  color: #181818;
}
#expandAll:hover {
  background-color: #f4f6f9;
}

/* Data Table Container - Unrestricted Scroll Design */
.table-container {
  width: 100%;
  overflow-x: visible;
}

.main-table {
  width: 100%;
  border-collapse: collapse;
  background: #fff;
  font-size: 12px;
}

.main-table th {
  background: #fafaf9;
  color: #514f4d;
  padding: 10px 6px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-bottom: 2px solid #c9c9c9;
  font-size: 11px;
  cursor: pointer;
  text-align: center;
}

.main-table th i {
  margin-left: 3px;
  font-size: 9px;
  color: #747472;
}

.main-table td {
  padding: 10px 6px;
  text-align: center;
  border-bottom: 1px solid #e5e5e5;
  color: #181818;
  vertical-align: middle;
  word-break: break-word;
}

.main-table tr:hover {
  background-color: #f3f3f3;
}

/* Modern Clean Print Button Form Styling */
.print-form {
  margin: 0;
  display: inline-block;
}

.print-action-btn {
  background: #ffffff;
  border: 1px solid #0176d3;
  color: #0176d3;
  padding: 6px 10px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  white-space: nowrap;
  transition: all 0.1s ease;
}

.print-action-btn:hover {
  background: #0176d3;
  color: #ffffff;
}

/* Footer Link formatting */
.form-link-container {
  margin-top: 20px;
  display: inline-block;
}
.form-link-container a {
  text-decoration: none;
  font-weight: 600;
  color: #2e844a;
  font-size: 14px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.form-link-container a:hover {
  color: #1b5e30;
}

/* Responsive Structural Refactor Engine */
@media (max-width: 1400px) {
  /* On tight desktop dashboards, transition to cards early to maintain layout beauty without cramping */
  .main-content { padding: 10px; }
  .card { padding: 16px; }
  .header-area { margin-bottom: 16px; padding-bottom: 12px; }

  .search-bar {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
    padding: 12px;
  }

  .filter-group {
    width: 100%;
  }

  .search-bar input[type="text"], 
  .search-bar input[type="date"],
  #deptFilter {
    width: 100%;
    height: 40px;
  }

  .actions-group {
    width: 100%;
    flex-direction: column;
    margin-left: 0;
    gap: 8px;
  }

  .btn {
    width: 100%;
    height: 40px;
  }

  table, thead, tbody, th, td, tr {
    display: block;
    width: 100%;
  }

  thead tr {
    display: none;
  }

  tr {
    margin-bottom: 16px;
    border: 1px solid #c9c9c9;
    border-radius: 4px;
    box-shadow: 0 1px 2px rgba(0,0,0,0.05);
    padding: 10px 0;
    background: #fff;
  }

  .main-table td {
    text-align: right;
    padding: 10px 16px;
    position: relative;
    border: none;
    border-bottom: 1px solid #f3f3f3;
    font-size: 13px;
  }

  .main-table td:last-child {
    border-bottom: none;
    text-align: right;
  }

  .main-table td:before {
    content: attr(data-label);
    position: absolute;
    left: 16px;
    width: 45%;
    font-weight: 700;
    text-align: left;
    color: #514f4d;
    white-space: nowrap;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  
  .print-action-btn {
    padding: 8px 14px;
    font-size: 12px;
  }
}
</style>
</head>

<body>

<%@ include file="header.jsp" %>

<div class="main-content">
  <div class="card">
    
    <div class="header-area">
      <div class="icon-box"><i class="fa fa-file-invoice"></i></div>
      <h1>Indents Report</h1>
    </div>

    <div class="search-bar">
      <div class="filter-group">
        <label>Keyword Search</label>
        <input type="text" id="keywordSearch" placeholder="Search by any field..." onkeyup="filterTable()">
      </div>

      <div class="filter-group">
        <label>From Date</label>
        <input type="date" id="fromDate">
      </div>

      <div class="filter-group">
        <label>To Date</label>
        <input type="date" id="toDate">
      </div>

      <div class="filter-group">
        <label>Department</label>
        <select id="deptFilter">
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

      <div class="actions-group">
        <button class="btn btn-info" onclick="filterTable()"><i class="fa fa-filter"></i> Filter</button>
        <button class="btn btn-secondary" onclick="resetFilters()"><i class="fa fa-rotate-left"></i> Reset</button>
        <button class="btn btn-success" onclick="downloadExcel()"><i class="fa fa-file-excel"></i> Download Excel</button>
        <button id="expandAll" class="btn" onclick="toggleExpand()">Collapse All</button>
      </div>
    </div>

    <div class="table-container">
      <table id="dataTable" class="main-table">
        <thead>
          <tr>
            <th onclick="sortTable(0)">ID <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(1)">Indent No <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(2)">Date <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(3)">Item <i class="fa fa-sort"></i></th>
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
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          <%
            List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
            if (indents != null && !indents.isEmpty()) {
              for (IndentItemFull ind : indents) {
                String istatus = ind.getIstatus();
                String status = ind.getStatus();
                String istatusStyle = "Approved".equalsIgnoreCase(istatus) ? "color:#2e844a;font-weight:bold;" : "color:#c23934;font-weight:bold;";
                String statusStyle = (status == null || status.trim().isEmpty() || "pending".equalsIgnoreCase(status))
                  ? "color:#c23934;font-weight:bold;" : "color:#2e844a;font-weight:bold;";
          %>
          <tr class="data-row">
            <td data-label="ID"><%= ind.getId() %></td>
            <td data-label="Indent No"><%= ind.getIndentNo() %></td>
            <td data-label="Date"><%= ind.getDate() %></td>
            <td data-label="Item" style="text-align: left;"><%= ind.getItemName() %></td>
            <td data-label="Avail. Qty" style="color:#FA6D16"><b><%= ind.getBalanceQty() %></b></td>
            <td data-label="Req. Qty"><%= ind.getQty() %></td>
            <td data-label="UOM"><%= ind.getUom() %></td>
            <td data-label="Dept"><%= ind.getDepartment() %></td>
            <td data-label="Requested By"><%= ind.getRequestedBy() %></td>
            <td data-label="Purpose"><%= ind.getPurpose() %></td>
            <td data-label="L1 Status" style="<%= istatusStyle %>">
              <%= (istatus == null || istatus.trim().isEmpty()) ? "Pending" : istatus %>
              <% if(ind.getApprovedBy() != null && !ind.getApprovedBy().trim().isEmpty()) { %>
                <br><span style="font-size:11px; color:#514f4d; font-weight:normal;">By: <%= ind.getApprovedBy() %></span>
              <% } %>
            </td>
            <td data-label="IApproveDate"><%= ind.getIapprovevdate() %></td>
            <td data-label="L2 Status" style="<%= statusStyle %>"><%= (status == null || status.trim().isEmpty()) ? "Pending" : status %></td>
            <td data-label="FApproveDate"><%= ind.getFapprovevdate() %></td>
            <td data-label="Indent status"><%= ind.getIndentNext() %></td>
            <td data-label="Action">
              <form action="PrintIndent.jsp" method="get" class="print-form">
                <input type="hidden" name="IndentNumber" value="<%= ind.getIndentNo() %>">
                <button type="submit" class="print-action-btn">
                  <i class="fa fa-print"></i> View / Print
                </button>
              </form>
            </td>
          </tr>
          <% } } else { %>
          <tr><td colspan="16" style="text-align:center;color:#c23934;font-weight:600;">No records found</td></tr>
          <% } %>
        </tbody>
      </table>
    </div>
    
   

  </div>
</div>

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
  const selectedDept = document.getElementById('deptFilter').value.toLowerCase();
  const rows = document.querySelectorAll('#dataTable tbody tr');
  
  rows.forEach(row => {
    if (row.cells.length === 1) return; 
    
    const dateCell = row.cells[2]?.innerText.trim();
    const dept = row.cells[7]?.innerText.toLowerCase();
    
    const textMatch = row.innerText.toLowerCase().includes(keyword);
    const deptMatch = selectedDept === "" || dept === selectedDept;
    
    let dateMatch = true;
    if (fromDate || toDate) {
      const rowDate = new Date(dateCell);
      const from = fromDate ? new Date(fromDate) : null;
      const to = toDate ? new Date(toDate) : null;
      if (from && rowDate < from) dateMatch = false;
      if (to && rowDate > to) dateMatch = false;
    }
    
    row.style.display = (textMatch && dateMatch && deptMatch) ? '' : 'none';
  });
}

function resetFilters() {
  document.getElementById('fromDate').value = '';
  document.getElementById('toDate').value = '';
  document.getElementById('keywordSearch').value = '';
  document.getElementById('deptFilter').value = '';
  document.querySelectorAll('#dataTable tbody tr').forEach(r => r.style.display = '');
}

function downloadExcel() {
  const table = document.getElementById('dataTable');
  let csv = [];
  const rows = table.querySelectorAll('tr');
  rows.forEach(row => {
    if (row.style.display !== 'none') {
      let cols = row.querySelectorAll('th, td');
      let rowData = [];
      cols.forEach(cell => {
        let text = cell.innerText.replace(/\n/g, ' ').replace(/"/g, '""').trim();
        
        if (window.innerWidth <= 1400 && cell.tagName === 'TD') {
          const labelText = cell.getAttribute('data-label') || '';
          if (text.startsWith(labelText)) {
            text = text.substring(labelText.length).trim();
          }
          if (cell.querySelector('button')) {
             text = "View / Print";
          }
        }
        rowData.push('"' + text + '"');
      });
      csv.push(rowData.join(','));
    }
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