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
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600&display=swap');

* {
    box-sizing: border-box;
}

html,
body {
    margin: 0;
    padding: 0;
    font-family: 'Poppins', sans-serif;
    background: #f5f7fa;
    color: #1e293b;
    font-size: 14px;
    overflow-x: hidden;
}

/* =========================
   MAIN CONTAINER
   ========================= */

.main-content {
    display: flex;
    justify-content: center;
    align-items: flex-start;
    padding: 12px;
}

.card {
    width: 100%;
    max-width: 1050px;
    min-width: 0;
    background: #fff;
    padding: 16px;
    border-radius: 10px;
    border: 1px solid #e2e8f0;
    box-shadow: 0 2px 8px rgba(15, 42, 77, 0.06);
}

/* =========================
   TITLE
   ========================= */

h2 {
    margin: 0 0 14px;
    padding: 0;
    text-align: left;
    color: #0f2a4d;
    font-size: 1.25rem;
    font-weight: 600;
    letter-spacing: 0;
}

h2::after {
    display: none;
}

/* =========================
   FORM SECTION
   ========================= */

.table-section {
    display: grid;
    grid-template-columns: 125px minmax(0, 1fr) 125px minmax(0, 1fr);
    gap: 8px 10px;
    margin-bottom: 10px;
    align-items: center;
}

label {
    margin: 0;
    color: #475569;
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: .2px;
}

/* =========================
   INPUTS
   ========================= */

input[type="text"],
input[type="date"],
input[type="number"],
select {
    width: 100%;
    height: 40px;
    padding: 7px 10px;
    margin: 0;
    border: 1px solid #cbd5e1;
    border-radius: 6px;
    background: #fff;
    color: #1e293b;
    font-family: inherit;
    font-size: 14px;
    outline: none;
    transition: border-color .12s ease,
                box-shadow .12s ease;
}

input[type="text"]:focus,
input[type="date"]:focus,
input[type="number"]:focus,
select:focus {
    border-color: #2563eb;
    box-shadow: 0 0 0 2px rgba(37, 99, 235, .12);
}

/* =========================
   INDENT TYPE
   ========================= */

.indent-type-group {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
    padding: 2px 0;
}

.indent-type-option {
    display: flex;
    align-items: center;
    gap: 5px;
    margin: 0;
    padding: 2px 0;
    color: #334155;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
}

.indent-type-option input {
    margin: 0;
    width: 15px;
    height: 15px;
}

/* =========================
   MAIN TABLE
   ========================= */

table.main-table {
    width: 100%;
    margin-top: 10px;
    border-collapse: separate;
    border-spacing: 0;
    border: 1px solid #dbe2ea;
    border-radius: 7px;
    overflow: hidden;
    background: #fff;
}

thead {
    background: #0f2a4d;
    color: #fff;
}

thead th {
    padding: 9px 7px;
    border: none;
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: .3px;
    white-space: nowrap;
}

th,
td {
    padding: 6px;
    text-align: center;
    border-right: 1px solid #e2e8f0;
    border-bottom: 1px solid #e2e8f0;
}

th:last-child,
td:last-child {
    border-right: none;
}

tbody tr:last-child td {
    border-bottom: none;
}

tbody tr:hover {
    background: #f8fafc;
}

/* Table inputs */
table select,
table input[type="text"],
table input[type="number"] {
    height: 36px;
    width: 100%;
    padding: 5px 7px;
    border: 1px solid #cbd5e1;
    border-radius: 5px;
    font-size: 13px;
}

/* =========================
   BUTTONS
   ========================= */

.btn {
    min-height: 40px;
    padding: 8px 16px;
    border: 0;
    border-radius: 6px;
    font-family: inherit;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    box-shadow: none;
    transition: background-color .1s ease,
                transform .05s ease;
}

.btn:active {
    transform: scale(.98);
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
}

.btn-red:hover {
    background: #b91c1c;
}

/* =========================
   BUTTON AREA
   ========================= */

.center-buttons {
    margin-top: 12px;
    display: flex;
    justify-content: flex-end;
    align-items: center;
    gap: 8px;
}

/* =========================
   RAPID ADD ITEM
   ========================= */

.btn-add-item {
    min-width: 110px;
    background: #2563eb;
    color: #fff;
    font-size: 14px;
    font-weight: 600;
    border-radius: 6px;
}

.btn-add-item:hover {
    background: #1d4ed8;
}

/* =========================
   TABLET
   ========================= */

@media (max-width: 992px) {

    .main-content {
        padding: 8px;
    }

    .card {
        padding: 12px;
    }

    .table-section {
        grid-template-columns: 110px minmax(0, 1fr);
        gap: 7px 8px;
    }
}

/* =========================
   MOBILE
   ========================= */

@media (max-width: 600px) {

    body {
        font-size: 13px;
    }

    .main-content {
        display: block;
        padding: 5px;
    }

    .card {
        width: 100%;
        padding: 10px;
        border-radius: 7px;
        box-shadow: none;
    }

    h2 {
        font-size: 1.1rem;
        margin-bottom: 10px;
    }

    /*
       Single-column rapid-entry layout
    */

    .table-section {
        display: grid;
        grid-template-columns: 1fr;
        gap: 3px;
        margin-bottom: 8px;
    }

    label {
        margin-top: 3px;
        font-size: 11px;
    }

    input[type="text"],
    input[type="date"],
    input[type="number"],
    select {
        height: 40px;
        padding: 7px 9px;
        font-size: 14px;
        border-radius: 5px;
    }

    .indent-type-group {
        gap: 10px;
        min-height: 36px;
    }

    .indent-type-option {
        font-size: 13px;
    }

    /* Horizontal table scroll */
    .table-wrapper {
        width: 100%;
        overflow-x: auto;
        -webkit-overflow-scrolling: touch;
    }

    table.main-table {
        min-width: 650px;
        margin-top: 7px;
    }

    thead th {
        padding: 8px 6px;
        font-size: 10px;
    }

    th,
    td {
        padding: 5px;
    }

    table select,
    table input[type="text"],
    table input[type="number"] {
        height: 36px;
        font-size: 13px;
    }

    .center-buttons {
        margin-top: 8px;
        gap: 6px;
    }

    .btn {
        min-height: 40px;
        padding: 8px 12px;
        font-size: 13px;
    }

    .btn-add-item {
        width: 100%;
        min-height: 44px;
        font-size: 14px;
    }
}

/* =========================
   VERY SMALL PHONES
   ========================= */

@media (max-width: 380px) {

    .main-content {
        padding: 3px;
    }

    .card {
        padding: 8px;
    }

    h2 {
        font-size: 1rem;
    }

    input[type="text"],
    input[type="date"],
    input[type="number"],
    select {
        height: 38px;
    }

    .btn {
        min-height: 38px;
        padding: 7px 10px;
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