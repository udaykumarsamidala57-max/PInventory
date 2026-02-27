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
<<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<style>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');

body {
    font-family: 'Poppins', sans-serif;
    background: #f8f9fa; /* Slightly off-white for better contrast */
    margin: 0;
    padding: 0;
    overflow-x: hidden;
    font-size: 0.95rem;
    color: #334155; /* Modern slate-gray */
}

/* ----- Card Layout ----- */
.main-content {
    display: flex;
    justify-content: center;
    align-items: flex-start;
    padding: 40px 15px;
}

.card {
    background: #ffffff;
    border-radius: 16px;
    padding: 32px;
    width: 100%;
    max-width: 1100px;
    min-width: 340px;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.05);
    border: 1px solid #eef2f6;
    transition: transform 0.2s ease;
}

h2 {
    text-align: center;
    font-size: 1.6rem;
    margin: 0 0 24px 0;
    color: #0f2a4d; /* Using your table header color for consistency */
    font-weight: 700;
    letter-spacing: -0.5px;
    position: relative;
    padding-bottom: 12px;
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

.table-section {
    display: grid;
    grid-template-columns: 160px 1fr 160px 1fr;
    gap: 16px 24px;
    margin-bottom: 24px;
    align-items: center;
}

label {
    font-weight: 600;
    color: #475569;
    font-size: 0.9rem;
    text-transform: uppercase;
    letter-spacing: 0.3px;
}

input[type="text"],
input[type="date"],
select {
    width: 100%;
    padding: 10px 12px;
    border: 1.5px solid #e2e8f0;
    border-radius: 8px;
    box-sizing: border-box;
    font-size: 0.95rem;
    background-color: #ffffff;
    transition: all 0.2s ease;
    color: #1e293b;
}

input:focus, select:focus {
    outline: none;
    border-color: #8e2de2;
    box-shadow: 0 0 0 3px rgba(142, 45, 226, 0.15);
    background-color: #fff;
}

/* ----- Table Styling ----- */
table.main-table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    margin-top: 20px;
    border-radius: 10px;
    overflow: hidden;
    border: 1px solid #e2e8f0;
}

thead {
    background: #0f2a4d;
    color: #ffffff;
}

thead th {
    font-weight: 500;
    text-transform: uppercase;
    font-size: 0.85rem;
    letter-spacing: 0.5px;
    padding: 14px 10px;
    border: none;
}

th, td {
    text-align: center;
    padding: 12px 8px;
    border-bottom: 1px solid #e2e8f0;
    border-right: 1px solid #e2e8f0;
}

td:last-child, th:last-child {
    border-right: none;
}

tbody tr:last-child td {
    border-bottom: none;
}

tbody tr {
    transition: background 0.2s ease;
}

tbody tr:hover {
    background-color: #f8fafc;
}

/* ----- Table Inputs ----- */
table select, 
table input[type="text"],
table input[type="number"] {
    border: 1px solid #cbd5e1;
    background-color: #ffffff;
    padding: 8px;
    border-radius: 6px;
}

/* ----- Indent Type Radio Buttons ----- */
.indent-type-group {
    display: flex;
    flex-wrap: wrap;
    gap: 20px;
    padding: 5px 0;
}

.indent-type-option {
    display: flex;
    align-items: center;
    gap: 8px;
    font-weight: 500;
    color: #334155;
    transition: color 0.2s ease;
}

.indent-type-option:hover {
    color: #8e2de2;
}

/* ----- Buttons ----- */
.btn {
    padding: 10px 24px;
    border: none;
    border-radius: 10px;
    font-weight: 600;
    font-size: 0.95rem;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
}

.btn:active {
    transform: translateY(1px);
}

.btn-green {
    background: #27ae60;
    color: #fff;
}
.btn-green:hover { 
    background: #219150; 
    box-shadow: 0 6px 15px rgba(39, 174, 96, 0.3);
}

.btn-info {
    background: #3498db;
    color: #fff;
}
.btn-info:hover { 
    background: #2980b9; 
    box-shadow: 0 6px 15px rgba(52, 152, 219, 0.3);
}

.btn-red {
    background: #e74c3c;
    color: #fff;
}
.btn-red:hover { 
    background: #c0392b; 
    box-shadow: 0 6px 15px rgba(231, 76, 60, 0.3);
}

.center-buttons {
    margin-top: 32px;
    gap: 16px;
}

/* ----- Responsive Adjustments ----- */
@media (max-width: 992px) {
    .table-section {
        grid-template-columns: 1fr 1fr;
    }
}

@media (max-width: 600px) {
    .card { padding: 20px; }
    .table-section { grid-template-columns: 1fr; }
    label { margin-bottom: -5px; }
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
<a href="IndentlistServlet"><i class="fas fa-list text-info"></i> Indent Report</a>
<script>
const userRole = "<%= (role != null ? role : "") %>".toLowerCase();
const userDept = "<%= (dept != null ? dept : "") %>";

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
  if (userRole !== "global" && userDept) {
    const deptSelect = document.getElementById("departmentSelect");
    deptSelect.value = userDept;
    deptSelect.disabled = true;
  }
  document.getElementById("addItemBtn").addEventListener("click", addRow);
});

function addRow() {
  const deptSel = document.getElementById("departmentSelect");
  const selectedDept = deptSel.value || userDept;
  if (!selectedDept && userRole !== "global") {
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
    <td class="stock"></td>
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
  let filteredCats = userRole === "global" ? categories :
      categories.filter(c => c.departmentName === selectedDept || c.departmentName.toLowerCase() === 'common');

  const uniqueNames = [...new Set(filteredCats.map(c => c.name))];
  catSel.innerHTML = '<option value="">-- Select Category --</option>';
  uniqueNames.forEach(name => catSel.add(new Option(name, name)));

  catSel.onchange = () => {
    subSel.innerHTML = '<option value="">-- Select SubCategory --</option>';
    subcategories.filter(s => s.categoryName === catSel.value)
      .forEach(s => subSel.add(new Option(s.name, s.name)));
    itemSel.innerHTML = '<option value="">-- Select Item --</option>';
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
  const indentType = document.querySelector('input[name="indentType"]:checked');
  const ids = [], names = [], qtys = [], purps = [], uomsArr = [];
  let issueError = false;

  document.querySelectorAll("#itemsTable tbody tr").forEach(tr => {
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
