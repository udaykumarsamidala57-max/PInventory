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
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap');

*, *::before, *::after {
    box-sizing: border-box;
    -webkit-tap-highlight-color: transparent;
}

html, body {
    margin: 0;
    padding: 0;
    font-family: 'Poppins', -apple-system, BlinkMacSystemFont, sans-serif;
    background-color: #f1f5f9;
    color: #0f172a;
    font-size: 14px;
    line-height: 1.5;
    -webkit-font-smoothing: antialiased;
}

/* ==========================================
   APP CONTAINER & VIEWPORT WRAPPER
   ========================================== */

.main-content {
    display: flex;
    justify-content: center;
    padding: 16px;
    min-height: 100vh;
}

.card {
    width: 100%;
    max-width: 1000px;
    background: #ffffff;
    padding: 24px;
    border-radius: 16px;
    border: 1px solid #e2e8f0;
    box-shadow: 0 4px 20px -2px rgba(15, 23, 42, 0.05);
}

/* Header Styling */
h2 {
    margin: 0 0 20px 0;
    color: #0f2a4d;
    font-size: 1.35rem;
    font-weight: 700;
    letter-spacing: -0.02em;
    display: flex;
    align-items: center;
    gap: 8px;
}

/* ==========================================
   GRID & FORM FIELD CONTROLS
   ========================================== */

.table-section {
    display: grid;
    grid-template-columns: 120px 1fr 120px 1fr;
    gap: 12px 16px;
    align-items: center;
    margin-bottom: 20px;
}

label {
    margin: 0;
    color: #64748b;
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

/* Touch-Optimized Inputs */
input[type="text"],
input[type="date"],
input[type="number"],
select {
    width: 100%;
    height: 44px;
    padding: 10px 14px;
    margin: 0;
    border: 1.5px solid #cbd5e1;
    border-radius: 10px;
    background-color: #f8fafc;
    color: #0f172a;
    font-family: inherit;
    font-size: 14px;
    font-weight: 500;
    outline: none;
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    appearance: none;
    -webkit-appearance: none;
}

input[type="text"]:focus,
input[type="date"]:focus,
input[type="number"]:focus,
select:focus {
    background-color: #ffffff;
    border-color: #2563eb;
    box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.12);
}

/* Custom Select Arrow */
select {
    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%2064748b'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 9l-7 7-7-7'%3E%3C/path%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: right 12px center;
    background-size: 16px;
    padding-right: 36px;
}

/* ==========================================
   SEGMENTED CONTROL (RADIO TOGGLES)
   ========================================== */

.indent-type-group {
    display: flex;
    align-items: center;
    gap: 8px;
    background: #f1f5f9;
    padding: 4px;
    border-radius: 10px;
    width: 100%;
}

.indent-type-option {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    padding: 8px 12px;
    margin: 0;
    color: #475569;
    font-size: 13px;
    font-weight: 600;
    border-radius: 8px;
    cursor: pointer;
    user-select: none;
    transition: all 0.2s ease;
}

.indent-type-option:has(input:checked) {
    background: #ffffff;
    color: #2563eb;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.indent-type-option input {
    accent-color: #2563eb;
    width: 16px;
    height: 16px;
}

/* ==========================================
   TABLE DESIGN (DESKTOP)
   ========================================== */

.table-wrapper {
    width: 100%;
    margin-top: 16px;
}

table.main-table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    overflow: hidden;
    background: #fff;
}

thead {
    background: #0f2a4d;
    color: #ffffff;
}

thead th {
    padding: 12px 10px;
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    text-align: left;
}

th, td {
    padding: 8px 10px;
    border-bottom: 1px solid #f1f5f9;
}

tbody tr:last-child td {
    border-bottom: none;
}

/* ==========================================
   BUTTON SYSTEM
   ========================================== */

.btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-height: 44px;
    padding: 10px 20px;
    border: 0;
    border-radius: 10px;
    font-family: inherit;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    user-select: none;
    transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
}

.btn:active {
    transform: scale(0.97);
}

.btn-green {
    background: #16a34a;
    color: #ffffff;
    box-shadow: 0 2px 8px rgba(22, 163, 74, 0.25);
}

.btn-info {
    background: #2563eb;
    color: #ffffff;
    box-shadow: 0 2px 8px rgba(37, 99, 235, 0.25);
}

.btn-red {
    background: #ef4444;
    color: #ffffff;
    box-shadow: 0 2px 8px rgba(239, 68, 68, 0.25);
}

.center-buttons {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
    align-items: center;
    gap: 10px;
}

.btn-add-item {
    width: 100%;
    background: #eff6ff;
    color: #2563eb;
    border: 1.5px dashed #bfdbfe;
    margin-top: 12px;
}

.btn-add-item:hover {
    background: #dbeafe;
}

/* ==========================================
   MOBILE NATIVE APP TRANSFORMATIONS (< 640px)
   ========================================== */

@media (max-width: 640px) {

    .main-content {
        padding: 0;
        background: #f8fafc;
    }

    .card {
        padding: 16px 16px 90px 16px; /* Safe space for bottom action bar */
        border-radius: 0;
        border: none;
        box-shadow: none;
        background: transparent;
    }

    h2 {
        font-size: 1.25rem;
        margin-bottom: 16px;
        padding-bottom: 12px;
        border-bottom: 1px solid #e2e8f0;
    }

    /* Stack form items like native iOS/Android screens */
    .table-section {
        display: flex;
        flex-direction: column;
        align-items: stretch;
        gap: 12px;
        background: #ffffff;
        padding: 16px;
        border-radius: 14px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
    }

    .table-section > label {
        margin-bottom: -6px;
        color: #475569;
    }

    /* Convert Table into App-Style Cards */
    table.main-table,
    table.main-table thead,
    table.main-table tbody,
    table.main-table th,
    table.main-table td,
    table.main-table tr {
        display: block;
    }

    table.main-table thead {
        display: none; /* Hide standard headers */
    }

    table.main-table tbody tr {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 14px;
        margin-bottom: 12px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
        position: relative;
    }

    table.main-table td {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        text-align: left;
        padding: 6px 0;
        border: none;
    }

    /* Render inline label above inputs inside items */
    table.main-table td::before {
        content: attr(data-label);
        font-size: 10px;
        font-weight: 700;
        text-transform: uppercase;
        color: #64748b;
        margin-bottom: 4px;
        letter-spacing: 0.03em;
    }

    table select,
    table input[type="text"],
    table input[type="number"] {
        height: 42px;
        font-size: 14px;
    }

    .btn-add-item {
        height: 48px;
        font-size: 15px;
        border-radius: 12px;
    }

    /* Sticky Bottom Navigation Bar for Primary Actions */
    .center-buttons {
        position: fixed;
        bottom: 0;
        left: 0;
        right: 0;
        background: rgba(255, 255, 255, 0.9);
        backdrop-filter: blur(10px);
        -webkit-backdrop-filter: blur(10px);
        padding: 12px 16px;
        margin: 0;
        border-top: 1px solid #e2e8f0;
        box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.05);
        z-index: 100;
        gap: 8px;
    }

    .center-buttons .btn {
        flex: 1;
        min-height: 46px;
        font-size: 14px;
        border-radius: 10px;
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
      <div class="table-section">
        <label>Indent No:</label>
        <input type="text" name="indentNumber" value="${nextIndentNo}" readonly>

        <label>Date:</label>
        <input type="date" name="date" id="dateField" required>

        <label>Department:</label>
        <select name="department" id="departmentSelect" required>
          <option value="">-- Select Department --</option>
          <c:forEach var="d" items="${masterData.departments}">
            <option value="${d.name}" <c:if test="${d.name == selectedDept}">selected</c:if>>${d.name}</option>
          </c:forEach>
        </select>

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

      <table class="main-table" id="itemsTable">
        <thead>
          <tr>
            <th>Category</th>
            <th>SubCategory</th>
            <th>Item</th>
            <th>UOM</th>
            <th>Available Stock</th>
            <th>Qty</th>
            <th>Purpose</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody></tbody>
      </table>

      <div class="center-buttons">
        <button type="button" class="btn btn-info" id="addItemBtn">Add Item</button>
        <button type="submit" class="btn btn-green">Save Indent</button>
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

  // Allow multi-department selection for Global AND Admin roles
  if (userRole !== "global" && userRole !== "admin" && userDept) {
    deptSelect.value = userDept;
    deptSelect.disabled = true;
  }

  // Clear existing row options if department changes mid-form fill
  deptSelect.addEventListener("change", () => {
    document.querySelectorAll("#itemsTable tbody tr").forEach(tr => tr.remove());
  });

  document.getElementById("addItemBtn").addEventListener("click", addRow);
});

function addRow() {
  const deptSel = document.getElementById("departmentSelect");
  const selectedDept = deptSel.value || userDept;

  if (!selectedDept && (userRole === "global" || userRole === "admin")) {
    alert("Please select a Department first!");
    return;
  }

  const tbody = document.querySelector("#itemsTable tbody");
  const tr = document.createElement("tr");
  tr.innerHTML = `
    <td><select class="cat"><option value="">-- Select Category --</option></select></td>
    <td><select class="subcat"><option value="">-- Select SubCategory --</option></select></td>
    <td><select class="item"><option value="">-- Select Item --</option></select></td>
    <td class="uom"></td>
    <td style="color: #FA6D16; font-weight: bold;" class="stock"></td>
    <td><input type="number" class="qty" min="0" step="any" required></td>
    <td><input type="text" class="purpose" required></td>
    <td><button type="button" class="btn btn-red removeBtn">Remove</button></td>
  `;
  tbody.appendChild(tr);

  const catSel = tr.querySelector(".cat");
  const subSel = tr.querySelector(".subcat");
  const itemSel = tr.querySelector(".item");
  const uomCell = tr.querySelector(".uom");
  const stockCell = tr.querySelector(".stock");

  fillDropdowns(catSel, subSel, itemSel, uomCell, stockCell, selectedDept);
  tr.querySelector(".removeBtn").onclick = () => tr.remove();
}

function fillDropdowns(catSel, subSel, itemSel, uomCell, stockCell, selectedDept) {
  // Filter categories by selected department or common category
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
    uomCell.textContent = '';
    stockCell.textContent = '';
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
    uomCell.textContent = '';
    stockCell.textContent = '';
  };

  itemSel.onchange = () => {
    const opt = itemSel.options[itemSel.selectedIndex];
    uomCell.textContent = opt?.dataset.uom || '';
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
  deptSelect.disabled = false; // Re-enable temporarily to ensure submitted with POST form

  const indentType = document.querySelector('input[name="indentType"]:checked');
  const ids = [], names = [], qtys = [], purps = [], uomsArr = [];
  let issueError = false;

  const rows = document.querySelectorAll("#itemsTable tbody tr");
  if (rows.length === 0) {
    e.preventDefault();
    alert("❌ Please add at least one item before saving.");
    return;
  }

  rows.forEach(tr => {
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
        tr.style.backgroundColor = "#ffcccc";
      } else {
        tr.style.backgroundColor = "";
      }
    }
  });

  if (issueError) {
    e.preventDefault();
    alert("❌ Some items do not have enough stock for Issue type.\nPlease adjust the quantities or check stock levels.");
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