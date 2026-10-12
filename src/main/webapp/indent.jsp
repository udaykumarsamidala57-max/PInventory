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
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= request.getContextPath() %>/CSS/Indent.css">
</head>

<body>
<%@ include file="header.jsp" %>

<div class="main-content">
  <div class="card">
    <h2>Items Requisition Form</h2>

    <form action="IndentServlet" method="post" id="indentForm">
      <div class="table-section">
        <div class="field">
          <label for="indentNumber">Indent No</label>
          <input type="text" name="indentNumber" id="indentNumber" value="${nextIndentNo}" readonly>
        </div>

        <div class="field">
          <label for="dateField">Date</label>
          <input type="date" name="date" id="dateField" required>
        </div>

        <div class="field field-wide">
          <label for="departmentSelect">Department</label>
          <select name="department" id="departmentSelect" required>
            <option value="">-- Select Department --</option>
            <c:forEach var="d" items="${masterData.departments}">
              <option value="${d.name}" <c:if test="${d.name == selectedDept}">selected</c:if>>${d.name}</option>
            </c:forEach>
          </select>
        </div>

        <div class="field field-wide">
          <span class="field-label" id="indentTypeLabel">Indent Type</span>
          <div class="indent-type-group" role="radiogroup" aria-labelledby="indentTypeLabel">
            <label class="indent-type-option">
              <input type="radio" name="indentType" value="Purchase" required> Purchase
            </label>
            <label class="indent-type-option">
              <input type="radio" name="indentType" value="Issue"> Issue
            </label>
          </div>
        </div>
      </div>

      <div class="table-wrapper">
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
        <div class="items-empty">No items added yet. Tap “Add Item” to start.</div>
      </div>

      <div class="center-buttons">
        <button type="button" class="btn btn-add-item" id="addItemBtn">+ Add Item</button>
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
    <td data-label="Category"><select class="cat" aria-label="Category"><option value="">-- Select Category --</option></select></td>
    <td data-label="Sub category"><select class="subcat" aria-label="Sub category"><option value="">-- Select SubCategory --</option></select></td>
    <td data-label="Item"><select class="item" aria-label="Item"><option value="">-- Select Item --</option></select></td>
    <td class="uom" data-label="UOM"></td>
    <td class="stock" data-label="In stock"></td>
    <td data-label="Qty"><input type="number" class="qty" min="0" step="any" inputmode="decimal" aria-label="Quantity" required></td>
    <td data-label="Purpose"><input type="text" class="purpose" aria-label="Purpose" required></td>
    <td class="action"><button type="button" class="btn btn-red removeBtn">Remove</button></td>
  `;
  tbody.appendChild(tr);
  tr.scrollIntoView({ behavior: "smooth", block: "nearest" });

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