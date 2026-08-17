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

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
* { 
  box-sizing: border-box; 
}

body {
  font-family: 'Poppins', sans-serif;
  background-color: #f3f3f3;
  margin: 0;
  padding: 0;
  color: #181818;
  -webkit-tap-highlight-color: transparent;
}

.main-content {
  width: 98%;
  max-width: 1600px;
  margin: 0 auto;
  padding: 20px 10px;
}

/* Salesforce Style Card Base */
.card {
  background: #fff;
  border-radius: 6px;
  padding: 20px;
  width: 100%;
  border: 1px solid #c9c9c9;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
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
  flex-shrink: 0;
}

h1 {
  margin: 0;
  font-size: 20px;
  color: #0176d3;
  font-weight: 700;
  text-align: left;
}

/* Responsive Grid Search & Filter Toolbar */
.search-bar {
  background: #fafaf9;
  border: 1px solid #c9c9c9;
  border-radius: 6px;
  padding: 16px;
  margin-bottom: 20px;
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  align-items: flex-end;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1 1 180px;
  min-width: 140px;
}

.search-bar label {
  font-size: 11px;
  font-weight: 700;
  color: #514f4d;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  white-space: nowrap;
}

.search-bar input[type="text"], 
.search-bar input[type="date"],
#deptFilter {
  height: 38px;
  padding: 0 10px;
  border: 1px solid #aeaeae;
  border-radius: 4px;
  font-family: inherit;
  font-size: 13px;
  background: #ffffff;
  outline: none;
  width: 100%;
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
  align-items: center;
}

/* Unified Button Styling */
.btn {
  height: 38px;
  padding: 0 14px;
  border: 1px solid #0176d3;
  background: #0176d3;
  color: white;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  transition: background-color 0.15s ease;
  white-space: nowrap;
}

.btn:hover { background: #015a9e; border-color: #015a9e; }

.btn-info {
  background-color: #0176d3;
  border-color: #0176d3;
  color: white;
}

.btn-success {
  background-color: #2e844a;
  border-color: #2e844a;
}
.btn-success:hover {
  background-color: #1b5e30;
  border-color: #1b5e30;
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

/* Dynamic High-Density Data Matrix */
.table-container {
  width: 100%;
  overflow-x: auto;
  scrollbar-width: thin;
  border: 1px solid #e5e5e5;
  border-radius: 4px;
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
  padding: 10px 8px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.3px;
  border-bottom: 2px solid #c9c9c9;
  font-size: 10.5px;
  cursor: pointer;
  text-align: center;
  white-space: nowrap;
  user-select: none;
}

.main-table th i {
  margin-left: 3px;
  font-size: 9px;
  color: #747472;
}

.main-table td {
  padding: 8px 6px;
  text-align: center;
  border-bottom: 1px solid #e5e5e5;
  color: #181818;
  vertical-align: middle;
  word-break: break-word;
}

.main-table tr:hover {
  background-color: #f4f6f9;
}

/* Type Status Badges (Purchase / Issue) */
.badge-type {
  display: inline-block;
  padding: 3px 8px;
  font-size: 10.5px;
  font-weight: 700;
  border-radius: 12px;
  text-transform: uppercase;
  letter-spacing: 0.4px;
  white-space: nowrap;
}

.badge-type-purchase {
  background-color: #eef4fe;
  color: #0176d3;
  border: 1px solid #aacbfa;
}

.badge-type-issue {
  background-color: #eaf5ea;
  color: #2e844a;
  border: 1px solid #a3d9b1;
}

.badge-type-default {
  background-color: #f3f3f3;
  color: #514f4d;
  border: 1px solid #c9c9c9;
}

/* Centered Table Action Buttons */
.print-form {
  margin: 0;
  display: flex;
  justify-content: center;
  align-items: center;
}

.print-action-btn {
  background: #ffffff;
  border: 1px solid #0176d3;
  color: #0176d3;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  white-space: nowrap;
  transition: all 0.15s ease;
}

.print-action-btn:hover {
  background: #0176d3;
  color: #ffffff;
}

/* CSS Mobile Card Transformation */
@media (max-width: 1024px) {
  .main-content { width: 100%; padding: 10px 5px; }
  .card { padding: 12px; }

  .actions-group {
    width: 100%;
    margin-left: 0;
  }

  .actions-group .btn {
    flex: 1 1 45%;
  }

  .table-container {
    border: none;
  }

  table.main-table, 
  .main-table thead, 
  .main-table tbody, 
  .main-table th, 
  .main-table td, 
  .main-table tr {
    display: block;
    width: 100%;
  }

  .main-table thead tr {
    display: none;
  }

  .main-table tr {
    margin-bottom: 14px;
    border: 1px solid #c9c9c9;
    border-radius: 6px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08);
    padding: 8px 0;
    background: #fff;
  }

  .main-table td {
    text-align: right;
    padding: 8px 14px;
    position: relative;
    border: none;
    border-bottom: 1px solid #f3f3f3;
    font-size: 12px;
    min-height: 36px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .main-table td:last-child {
    border-bottom: none;
  }

  .main-table td::before {
    content: attr(data-label);
    font-weight: 700;
    text-align: left;
    color: #514f4d;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    padding-right: 10px;
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

      <div class="actions-group">
        <button class="btn btn-info" onclick="filterTable()"><i class="fa fa-filter"></i> Filter</button>
        <button class="btn btn-secondary" onclick="resetFilters()"><i class="fa fa-rotate-left"></i> Reset</button>
        <button class="btn btn-success" onclick="downloadExcel()"><i class="fa fa-file-excel"></i> Download Excel</button>
        <button id="expandAll" class="btn btn-secondary" onclick="toggleExpand()">Collapse All</button>
      </div>
    </div>

    <div class="table-container">
      <table id="dataTable" class="main-table">
        <thead>
          <tr>
            <th onclick="sortTable(0)">ID <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(1)">Indent No <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(2)">Type <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(3)">Date <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(4)">Item <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(5)">Avail. Qty <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(6)">Req. Qty <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(7)">UOM <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(8)">Dept <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(9)">Requested By <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(10)">Purpose <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(11)">L1 Status <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(12)">IApproveDate <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(13)">L2 Status <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(14)">FApproveDate <i class="fa fa-sort"></i></th>
            <th onclick="sortTable(15)">Indent Status <i class="fa fa-sort"></i></th>
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
                String typeVal = ind.getPurchaseorIssue();
                
                String istatusStyle = "Approved".equalsIgnoreCase(istatus) ? "color:#2e844a;font-weight:bold;" : "color:#c23934;font-weight:bold;";
                String statusStyle = (status == null || status.trim().isEmpty() || "pending".equalsIgnoreCase(status))
                  ? "color:#c23934;font-weight:bold;" : "color:#2e844a;font-weight:bold;";
                
                String badgeClass = "badge-type-default";
                if (typeVal != null) {
                    if (typeVal.trim().equalsIgnoreCase("Purchase")) {
                        badgeClass = "badge-type-purchase";
                    } else if (typeVal.trim().equalsIgnoreCase("Issue")) {
                        badgeClass = "badge-type-issue";
                    }
                }
          %>
          <tr class="data-row">
            <td data-label="ID"><%= ind.getId() %></td>
            <td data-label="Indent No"><%= ind.getIndentNo() %></td>
            <td data-label="Type">
              <span class="badge-type <%= badgeClass %>"><%= (typeVal != null && !typeVal.trim().isEmpty()) ? typeVal : "-" %></span>
            </td>
            <td data-label="Date"><%= ind.getDate() %></td>
            <td data-label="Item"><%= ind.getItemName() %></td>
            <td data-label="Avail. Qty" style="color:#FA6D16; font-weight:bold;"><%= ind.getBalanceQty() %></td>
            <td data-label="Req. Qty"><%= ind.getQty() %></td>
            <td data-label="UOM"><%= ind.getUom() %></td>
            <td data-label="Dept"><%= ind.getDepartment() %></td>
            <td data-label="Requested By"><%= ind.getRequestedBy() %></td>
            <td data-label="Purpose"><%= ind.getPurpose() %></td>
            <td data-label="L1 Status" style="<%= istatusStyle %>">
              <%= (istatus == null || istatus.trim().isEmpty()) ? "Pending" : istatus %>
              <% if(ind.getApprovedBy() != null && !ind.getApprovedBy().trim().isEmpty()) { %>
                <br><span style="font-size:10px; color:#514f4d; font-weight:normal; display:block; line-height:1.2;">By: <%= ind.getApprovedBy() %></span>
              <% } %>
            </td>
            <td data-label="IApproveDate"><%= ind.getIapprovevdate() %></td>
            <td data-label="L2 Status" style="<%= statusStyle %>"><%= (status == null || status.trim().isEmpty()) ? "Pending" : status %></td>
            <td data-label="FApproveDate"><%= ind.getFapprovevdate() %></td>
            <td data-label="Indent Status"><%= ind.getIndentNext() %></td>
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
          <tr><td colspan="17" style="text-align:center;color:#c23934;font-weight:600;padding:20px;">No records found</td></tr>
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
      if (!x || !y) continue;
      
      let xVal = x.innerText.toLowerCase().trim();
      let yVal = y.innerText.toLowerCase().trim();
      
      let xNum = parseFloat(xVal), yNum = parseFloat(yVal);
      if (!isNaN(xNum) && !isNaN(yNum)) {
        xVal = xNum;
        yVal = yNum;
      }

      if (dir == "asc" && xVal > yVal) { shouldSwitch = true; break; }
      else if (dir == "desc" && xVal < yVal) { shouldSwitch = true; break; }
    }
    if (shouldSwitch) {
      rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
      switching = true; 
      switchcount++;
    } else {
      if (switchcount == 0 && dir == "asc") { dir = "desc"; switching = true; }
    }
  }
}

function filterTable() {
  const fromDate = document.getElementById('fromDate').value;
  const toDate = document.getElementById('toDate').value;
  const keyword = document.getElementById('keywordSearch').value.toLowerCase().trim();
  const selectedDept = document.getElementById('deptFilter').value.toLowerCase().trim();
  const rows = document.querySelectorAll('#dataTable tbody tr');
  
  rows.forEach(row => {
    if (row.cells.length <= 1) return; 
    
    const dateCell = row.cells[3]?.innerText.trim();
    const deptCell = row.cells[8]?.innerText.toLowerCase().trim();
    
    const textMatch = keyword === "" || row.innerText.toLowerCase().includes(keyword);
    const deptMatch = selectedDept === "" || deptCell === selectedDept;
    
    let dateMatch = true;
    if (fromDate || toDate) {
      const rowDate = new Date(dateCell);
      const from = fromDate ? new Date(fromDate) : null;
      const to = toDate ? new Date(toDate) : null;
      
      if (!isNaN(rowDate.getTime())) {
        if (from && rowDate < from) dateMatch = false;
        if (to && rowDate > to) dateMatch = false;
      }
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
        
        if (window.innerWidth <= 1024 && cell.tagName === 'TD') {
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