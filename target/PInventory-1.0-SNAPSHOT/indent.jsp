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
body {
    font-family: 'Poppins', sans-serif;
    background: linear-gradient(135deg, #dbe8ff, #e6d7ff, #ffd6e0, #d9faff);
    margin: 0;
    padding: 0;
    overflow-x: hidden;
    font-size: 0.95rem;
    color: #333;
}

/* ----- Card Layout ----- */
.main-content {
    display: flex;
    justify-content: center;
    align-items: flex-start;
    padding: 50px 10px;
}

.card {
    background: #fff;
    border-radius: 14px;
    padding: 28px;
    width: 95%;
    max-width: 1000px;
    min-width: 340px;
    box-shadow: 0 6px 22px rgba(0,0,0,0.1);
    transition: all 0.3s ease;
}

h2 {
    text-align: center;
    font-size: 1.45rem;
    margin: 0 0 18px 0;
    color: #2d3436;
    border-bottom: 2px solid #8e2de2;
    padding-bottom: 8px;
}

/* ----- Form Layout ----- */
.table-section {
    display: grid;
    grid-template-columns: 180px 1fr 180px 1fr;
    gap: 14px 20px;
    margin-bottom: 20px;
    align-items: center;
}

label {
    font-weight: 500;
    color: #222;
    font-size: 0.95rem;
    white-space: nowrap;
}

input[type="text"],
input[type="date"],
select {
    width: 100%;
    padding: 8px 10px;
    border: 1px solid #ccc;
    border-radius: 6px;
    box-sizing: border-box;
    font-size: 0.95rem;
    background-color: #fafafa;
    min-height: 38px;
    white-space: normal;
    overflow-wrap: anywhere;
}

/* ----- Table Styling & Inputs ----- */
table.main-table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 16px;
    font-size: 0.95rem;
    table-layout: auto;
    word-wrap: break-word;
}

thead {
    background: linear-gradient(135deg, #ff8c00, #8e2de2);
    color: #fff;
    font-size: 0.95rem;
}

th, td {
    text-align: center;
    padding: 10px 6px;
    border: 1px solid #ddd;
    vertical-align: middle;
    word-wrap: break-word;
}

/* Make dropdown and inputs comfortable & flexible */
table select, 
table input[type="text"],
table input[type="number"] {
    width: 100%;
    border-radius: 6px;
    border: 1px solid #ccc;
    font-size: 0.9rem;
    padding: 7px 8px;
    background-color: #fafafa;
    box-sizing: border-box;
    line-height: 1.4;
    height: auto;
    min-height: 36px;
    max-height: 100px;
    white-space: normal !important;
    word-break: break-word !important;
    overflow-wrap: anywhere !important;
    resize: vertical;
}

/* Dropdown behavior fix */
table select {
    display: block;
    width: 100%;
    appearance: none;
    background-color: #fafafa;
    overflow-y: auto;
    white-space: normal !important;
    word-wrap: break-word;
    text-overflow: ellipsis;
}

/* Dropdown options text wrapping */
table select option {
    white-space: normal !important;
    word-wrap: break-word !important;
    overflow-wrap: anywhere !important;
    line-height: 1.4;
    font-size: 0.9rem;
    padding: 6px 8px;
}

/* For long text inside table cells */
table td {
    max-width: 260px;
    word-wrap: break-word;
    white-space: normal;
    overflow-wrap: anywhere;
}

/* ----- Indent Type Buttons ----- */
.indent-type-group {
    display: flex;
    flex-wrap: wrap;
    gap: 15px;
    align-items: center;
}

.indent-type-option {
    display: flex;
    align-items: center;
    gap: 6px;
    font-weight: 500;
    cursor: pointer;
}

.indent-type-option input[type="radio"] {
    appearance: none;
    width: 16px;
    height: 16px;
    border: 2px solid #777;
    border-radius: 50%;
}

.indent-type-option input[type="radio"]:checked {
    border-color: #007bff;
    background: radial-gradient(circle at center, #007bff 50%, white 52%);
}

/* ----- Buttons ----- */
.btn {
    padding: 8px 16px;
    border: none;
    border-radius: 8px;
    font-weight: 600;
    font-size: 0.9rem;
    cursor: pointer;
    transition: all 0.3s ease;
    white-space: nowrap;
}

.btn-green {
    background: linear-gradient(135deg, #27ae60, #2ecc71);
    color: #fff;
}
.btn-green:hover { background: linear-gradient(135deg, #219150, #27ae60); }

.btn-info {
    background: linear-gradient(135deg, #3498db, #2980b9);
    color: #fff;
}
.btn-info:hover { background: linear-gradient(135deg, #217dbb, #3498db); }

.btn-red {
    background: linear-gradient(135deg, #e74c3c, #ff7675);
    color: #fff;
}
.btn-red:hover { background: linear-gradient(135deg, #c0392b, #e74c3c); }

.center-buttons {
    text-align: center;
    margin-top: 18px;
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 10px;
}

/* ----- Responsive Design ----- */
@media (max-width: 992px) {
    .card {
        padding: 22px;
        max-width: 95%;
    }
    .table-section {
        grid-template-columns: 1fr 1fr;
        gap: 12px 16px;
    }
    label { font-size: 0.9rem; }
    input, select { font-size: 0.9rem; }
    th, td { font-size: 0.85rem; padding: 6px 4px; }
}

@media (max-width: 600px) {
    body { font-size: 0.9rem; }
    .main-content { padding: 30px 10px; }
    .table-section { grid-template-columns: 1fr; gap: 10px; }
    .card { padding: 18px; width: 98%; }
    h2 { font-size: 1.1rem; }
    table.main-table { font-size: 0.85rem; display: block; overflow-x: auto; }
    table select, table input { font-size: 0.85rem; }
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
