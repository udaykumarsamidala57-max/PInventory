<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String user  = (String) sess.getAttribute("username");
    String role  = (String) sess.getAttribute("role");
    String dept  = (String) sess.getAttribute("department");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Items Requisition Form</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

<style>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');

* {
    box-sizing: border-box;
}

body {
    font-family: 'Poppins', sans-serif;
    background: #f8f9fa;
    margin: 0;
    padding: 0;
    font-size: 0.95rem;
    color: #334155;
    padding-bottom: 90px; /* Space for fixed bottom bar on long lists */
}

.main-content {
    display: flex;
    justify-content: center;
    align-items: flex-start;
    padding: 20px 10px;
}

.card {
    background: #ffffff;
    border-radius: 16px;
    padding: 24px;
    width: 100%;
    max-width: 1200px;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.05);
    border: 1px solid #eef2f6;
}

h2 {
    text-align: center;
    font-size: 1.5rem;
    margin: 0 0 20px 0;
    color: #0f2a4d;
    font-weight: 700;
    letter-spacing: -0.5px;
    position: relative;
    padding-bottom: 10px;
}

h2::after {
    content: '';
    position: absolute;
    bottom: 0;
    left: 50%;
    transform: translateX(-50%);
    width: 60px;
    height: 4px;
    background: #8e2de2;
    border-radius: 10px;
}

/* Header Form Grid */
.table-section {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px 20px;
    margin-bottom: 24px;
    align-items: center;
    background: #f8fafc;
    padding: 16px;
    border-radius: 12px;
    border: 1px solid #e2e8f0;
}

.table-section .field-group {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

label {
    font-weight: 600;
    color: #475569;
    font-size: 0.82rem;
    text-transform: uppercase;
    letter-spacing: 0.3px;
}

input[type="text"],
input[type="date"],
select,
input[type="number"],
textarea {
    width: 100%;
    padding: 10px 12px;
    border: 1.5px solid #cbd5e1;
    border-radius: 8px;
    font-size: 0.9rem;
    background-color: #ffffff;
    transition: all 0.2s ease;
    color: #1e293b;
    font-family: inherit;
}

input:focus, select:focus, textarea:focus {
    outline: none;
    border-color: #8e2de2;
    box-shadow: 0 0 0 3px rgba(142, 45, 226, 0.15);
}

.indent-type-group {
    display: flex;
    align-items: center;
    gap: 16px;
    height: 42px;
}

.indent-type-option {
    display: flex;
    align-items: center;
    gap: 6px;
    font-weight: 500;
    cursor: pointer;
}

/* Items List Header Summary */
.items-summary-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
    padding: 0 4px;
}

.items-count-badge {
    background: #e0e7ff;
    color: #3730a3;
    font-weight: 600;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 0.85rem;
}

/* Desktop Table Styles */
.table-wrapper {
    width: 100%;
    overflow-x: auto;
    border-radius: 10px;
    border: 1px solid #e2e8f0;
    max-height: 600px; /* Scrollable table container for 20-30 rows */
    position: relative;
}

table.main-table {
    width: 100%;
    border-collapse: collapse;
    min-width: 900px;
}

thead {
    position: sticky;
    top: 0;
    z-index: 10;
    background: #0f2a4d;
    color: #ffffff;
}

thead th {
    font-weight: 600;
    text-transform: uppercase;
    font-size: 0.8rem;
    letter-spacing: 0.5px;
    padding: 12px 10px;
    text-align: left;
}

th, td {
    padding: 10px 8px;
    border-bottom: 1px solid #e2e8f0;
    vertical-align: middle;
}

tbody tr:hover {
    background-color: #f1f5f9;
}

/* Field specific sizes inside table */
table select {
    min-width: 130px;
}

table input[type="number"].qty {
    width: 80px;
    text-align: center;
}

table textarea.purpose {
    width: 100%;
    min-width: 160px;
    height: 38px;
    padding: 6px 8px;
    resize: vertical;
}

.stock-badge {
    color: #d97706;
    font-weight: 700;
    text-align: center;
    display: block;
}

/* Action Buttons */
.btn {
    padding: 9px 18px;
    border: none;
    border-radius: 8px;
    font-weight: 600;
    font-size: 0.9rem;
    cursor: pointer;
    transition: all 0.2s ease;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
}

.btn-green {
    background: #16a34a;
    color: #fff;
}
.btn-green:hover { 
    background: #15803d; 
}

.btn-info {
    background: #2563eb;
    color: #fff;
}
.btn-info:hover { 
    background: #1d4ed8; 
}

.btn-red {
    background: #dc2626;
    color: #fff;
    padding: 6px 12px;
    font-size: 0.82rem;
}
.btn-red:hover { 
    background: #b91c1c; 
}

/* Floating Actions Bar for easy submit/add with 20-30 items */
.sticky-actions-bar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    background: #ffffff;
    box-shadow: 0 -4px 15px rgba(0,0,0,0.1);
    padding: 12px 20px;
    display: flex;
    justify-content: center;
    gap: 16px;
    z-index: 100;
    border-top: 1px solid #e2e8f0;
}

/* Mobile Responsive Adjustments (Cards Layout) */
@media (max-width: 768px) {
    .main-content {
        padding: 10px 6px;
    }

    .card {
        padding: 16px 12px;
        border-radius: 12px;
    }

    .table-section {
        grid-template-columns: 1fr;
        gap: 12px;
        padding: 12px;
    }

    .table-wrapper {
        border: none;
        max-height: none;
        overflow-x: visible;
    }

    table.main-table, 
    table.main-table thead, 
    table.main-table tbody, 
    table.main-table th, 
    table.main-table td, 
    table.main-table tr { 
        display: block; 
    }

    table.main-table thead {
        display: none; /* Hide standard headers on mobile */
    }

    table.main-table tbody tr {
        background: #ffffff;
        border: 1.5px solid #e2e8f0;
        border-radius: 12px;
        margin-bottom: 16px;
        padding: 14px;
        box-shadow: 0 4px 10px rgba(0,0,0,0.03);
        position: relative;
    }

    table.main-table td {
        border: none;
        padding: 6px 0;
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        text-align: left;
    }

    /* Add pseudo-label for fields in mobile card view */
    table.main-table td::before {
        content: attr(data-label);
        font-weight: 700;
        font-size: 0.75rem;
        color: #64748b;
        text-transform: uppercase;
        margin-bottom: 4px;
    }

    table.main-table td[data-label="UOM"],
    table.main-table td[data-label="Available Stock"] {
        display: inline-block;
        width: 48%;
    }

    .mobile-inline-row {
        display: flex;
        width: 100%;
        justify-content: space-between;
        background: #f8fafc;
        padding: 8px;
        border-radius: 8px;
        margin: 6px 0;
    }

    table input[type="number"].qty {
        width: 100%;
        text-align: left;
    }

    table.main-table td[data-label="Action"] {
        margin-top: 8px;
        align-items: flex-end;
    }

    .btn-red {
        width: 100%;
        padding: 10px;
    }

    .sticky-actions-bar {
        padding: 10px 12px;
    }

    .sticky-actions-bar .btn {
        flex: 1;
        font-size: 0.85rem;
        padding: 12px 8px;
    }
}
</style>
</head>

<body>
<%@ include file="header.jsp" %>

<div class="main-content">
  <div class="card">
    <h2>Items Requisition Form</h2>

    <form action="IndentServlet" method="post" id="indentForm">
      <!-- Master Info Controls -->
      <div class="table-section">
        <div class="field-group">
            <label>Indent No:</label>
            <input type="text" name="indentNumber" value="${nextIndentNo}" readonly>
        </div>

        <div class="field-group">
            <label>Date:</label>
            <input type="date" name="date" id="dateField" required>
        </div>

        <div class="field-group">
            <label>Department:</label>
            <select name="department" id="departmentSelect" required>
              <option value="">-- Select Department --</option>
              <c:forEach var="d" items="${masterData.departments}">
                <option value="${d.name}" <c:if test="${d.name == selectedDept}">selected</c:if>>${d.name}</option>
              </c:forEach>
            </select>
        </div>

        <div class="field-group">
            <label>Indent Type:</label>
            <div class="indent-type-group">
              <label class="indent-type-option">
                <input type="radio" name="indentType" value="Purchase" required> Purchase
              </label>
              <label class="indent-type-option">
                <input type="radio" name="indentType" value="Issue"> Issue
              </label>
            </div>
        </div>
      </div>

      <!-- Items Summary Bar -->
      <div class="items-summary-header">
        <label>Requested Items</label>
        <span class="items-count-badge" id="rowCountBadge">Total Items: 0</span>
      </div>

      <!-- Dynamic Items Container -->
      <div class="table-wrapper">
          <table class="main-table" id="itemsTable">
            <thead>
              <tr>
                <th style="width: 18%;">Category</th>
                <th style="width: 18%;">SubCategory</th>
                <th style="width: 20%;">Item</th>
                <th style="width: 8%;">UOM</th>
                <th style="width: 10%;">Stock</th>
                <th style="width: 8%;">Qty</th>
                <th style="width: 13%;">Purpose</th>
                <th style="width: 5%;">Action</th>
              </tr>
            </thead>
            <tbody></tbody>
          </table>
      </div>

      <!-- Sticky Floating Action Bar for Quick Addition/Submission -->
      <div class="sticky-actions-bar">
        <button type="button" class="btn btn-info" id="addItemBtn">➕ Add Item</button>
        <button type="submit" class="btn btn-green">💾 Save Indent</button>
      </div>

      <input type="hidden" name="itemIds">
      <input type="hidden" name="itemNames">
      <input type="hidden" name="quantities">
      <input type="hidden" name="purposes">
      <input type="hidden" name="uoms">
    </form>
  </div>
</div>

<script>
const userRole = "<%= (role != null ? role.trim() : "") %>".toLowerCase();
const userDept = "<%= (dept != null ? dept.trim() : "") %>";

const categories = [];
<c:forEach var="c" items="${masterData.categories}">
  categories.push({ name: '${c.name}', departmentName: '${c.departmentName}' });
</c:forEach>

const subcategories = [];
<c:forEach var="s" items="${masterData.subcategories}">
  subcategories.push({ name: '${s.name}', categoryName: '${s.categoryName}' });
</c:forEach>

const items = [];
<c:forEach var="i" items="${masterData.items}">
  items.push({ 
    id: '${i.id}', 
    name: '${i.name}', 
    UOM: '${i.UOM}', 
    category: '${i.category}', 
    subcategory: '${i.subcategory}', 
    stock: '${i.stock}'
  });
</c:forEach>

document.addEventListener("DOMContentLoaded", () => {
  restrictDateToToday();

  const deptSelect = document.getElementById("departmentSelect");

  if (userRole !== "global" && userRole !== "admin" && userDept) {
    deptSelect.value = userDept;
    deptSelect.disabled = true;
  }

  deptSelect.addEventListener("change", () => {
    document.querySelectorAll("#itemsTable tbody tr").forEach(tr => tr.remove());
    updateItemCount();
  });

  document.getElementById("addItemBtn").addEventListener("click", addRow);
  
  // Add first initial row automatically
  addRow();
});

function updateItemCount() {
  const count = document.querySelectorAll("#itemsTable tbody tr").length;
  document.getElementById("rowCountBadge").textContent = `Total Items: ${count}`;
}

function addRow() {
  const deptSel = document.getElementById("departmentSelect");
  const selectedDept = deptSel.value || userDept;

  if (!selectedDept && (userRole === "global" || userRole === "admin")) {
    alert("Please select a Department first!");
    return;
  }

  const tbody = document.querySelector("#itemsTable tbody");
  const tr = document.createElement("tr");

  // Included data-label attributes for full mobile responsive layout
  tr.innerHTML = `
    <td data-label="Category"><select class="cat"><option value="">-- Select Category --</option></select></td>
    <td data-label="SubCategory"><select class="subcat"><option value="">-- Select SubCategory --</option></select></td>
    <td data-label="Item"><select class="item"><option value="">-- Select Item --</option></select></td>
    <td data-label="UOM" class="uom">--</td>
    <td data-label="Available Stock" class="stock-badge stock">0</td>
    <td data-label="Qty"><input type="number" class="qty" min="0" step="any" placeholder="Qty" required></td>
    <td data-label="Purpose"><textarea class="purpose" rows="1" placeholder="Enter purpose..." required></textarea></td>
    <td data-label="Action"><button type="button" class="btn btn-red removeBtn">🗑️ Remove</button></td>
  `;
  tbody.appendChild(tr);

  const catSel = tr.querySelector(".cat");
  const subSel = tr.querySelector(".subcat");
  const itemSel = tr.querySelector(".item");
  const uomCell = tr.querySelector(".uom");
  const stockCell = tr.querySelector(".stock");

  fillDropdowns(catSel, subSel, itemSel, uomCell, stockCell, selectedDept);
  
  tr.querySelector(".removeBtn").onclick = () => {
    tr.remove();
    updateItemCount();
  };

  updateItemCount();

  // Scroll smooth to newly added item on long screens
  if (tbody.children.length > 3) {
    tr.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }
}

function fillDropdowns(catSel, subSel, itemSel, uomCell, stockCell, selectedDept) {
  let filteredCats = categories.filter(c => 
    c.departmentName === selectedDept || 
    c.departmentName.toLowerCase() === 'common' ||
    userRole === 'global'
  );

  const uniqueNames = [...new Set(filteredCats.map(c => c.name))];
  catSel.innerHTML = '<option value="">-- Select Category --</option>';
  uniqueNames.forEach(name => catSel.add(new Option(name, name)));

  catSel.onchange = () => {
    subSel.innerHTML = '<option value="">-- Select SubCategory --</option>';
    subcategories.filter(s => s.categoryName === catSel.value)
      .forEach(s => subSel.add(new Option(s.name, s.name)));
    itemSel.innerHTML = '<option value="">-- Select Item --</option>';
    uomCell.textContent = '--';
    stockCell.textContent = '0';
  };

  subSel.onchange = () => {
    itemSel.innerHTML = '<option value="">-- Select Item --</option>';
    items.filter(i => i.category === catSel.value && i.subcategory === subSel.value)
      .forEach(i => {
        const o = new Option(i.name, i.name);
        o.dataset.id = i.id;
        o.dataset.uom = i.UOM;
        o.dataset.stock = i.stock;
        itemSel.add(o);
      });
    uomCell.textContent = '--';
    stockCell.textContent = '0';
  };

  itemSel.onchange = () => {
    const opt = itemSel.options[itemSel.selectedIndex];
    uomCell.textContent = opt?.dataset.uom || '--';
    stockCell.textContent = opt?.dataset.stock || '0';
  };
}

function restrictDateToToday() {
  const today = new Date().toISOString().split('T')[0];
  const dateField = document.getElementById("dateField");
  dateField.value = today;
  dateField.min = today;
  dateField.max = today;
}

document.getElementById('indentForm').addEventListener('submit', function(e) {
  const deptSelect = document.getElementById("departmentSelect");
  deptSelect.disabled = false;

  const indentType = document.querySelector('input[name="indentType"]:checked');
  const ids = [], names = [], qtys = [], purps = [], uomsArr = [];
  let issueError = false;

  const rows = document.querySelectorAll("#itemsTable tbody tr");
  if (rows.length === 0) {
    e.preventDefault();
    alert("❌ Please add at least one item before saving.");
    return;
  }

  rows.forEach((tr, index) => {
    const sel = tr.querySelector(".item");
    const opt = sel.options[sel.selectedIndex];
    const stock = parseFloat(tr.querySelector(".stock").textContent || "0");
    const qty = parseFloat(tr.querySelector(".qty").value || "0");

    ids.push(opt ? opt.dataset.id : "");
    names.push(opt ? opt.value : "");
    qtys.push(qty);
    purps.push(tr.querySelector(".purpose").value);
    uomsArr.push(tr.querySelector(".uom").textContent);

    if (indentType && indentType.value === "Issue") {
      if (isNaN(stock) || stock <= 0 || qty > stock) {
        issueError = true;
        tr.style.border = "2px solid #dc2626";
      } else {
        tr.style.border = "";
      }
    }
  });

  if (issueError) {
    e.preventDefault();
    alert("❌ Some items do not have enough stock for 'Issue' type.\nPlease adjust quantities or verify stock levels.");
    return;
  }

  this.itemIds.value = ids.join(",");
  this.itemNames.value = names.join(",");
  this.quantities.value = qtys.join(",");
  this.purposes.value = purps.join(",");
  this.uoms.value = uomsArr.join(",");
});
</script>

</body>
</html>