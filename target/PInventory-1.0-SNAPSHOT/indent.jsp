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
<html>
<head>
<meta charset="UTF-8">
<title>Items Requisition Form</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Form.css">
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-content">
  <div class="card">
    <h2 align="center">ITEMS REQUISITION FORM</h2>

    <form action="IndentServlet" method="post" id="indentForm">
      <table class="main-table">
        <tr>
          <td><label>Indent No:</label></td>
          <td><input type="text" name="indentNumber" value="${nextIndentNo}" readonly></td>
        </tr>
        <tr>
          <td><label>Date:</label></td>
          <td><input type="date" name="date" id="dateField" required></td>
        </tr>
        <tr>
          <td><label>Department:</label></td>
          <td>
            <select name="department" id="departmentSelect" required>
              <option value="">-- Select Department --</option>
              <c:forEach var="d" items="${masterData.departments}">
                <option value="${d.name}" <c:if test="${d.name == selectedDept}">selected</c:if>>${d.name}</option>
              </c:forEach>
            </select>
          </td>
        </tr>
      </table>

      <br>

      <table border="1" id="itemsTable" class="main-table">
        <thead>
          <tr>
            <th>Category</th>
            <th>SubCategory</th>
            <th>Item</th>
            <th>UOM</th>
            <th>Qty</th>
            <th>Purpose</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody></tbody>
      </table>

      <br>
      <center>
        <button type="button" class="btn btn-info" id="addItemBtn">Add Item</button>
        <button type="submit" class="btn btn-green">Save Indent</button>
      </center>

      <input type="hidden" name="itemIds">
      <input type="hidden" name="itemNames">
      <input type="hidden" name="quantities">
      <input type="hidden" name="purposes">
      <input type="hidden" name="uoms">
    </form>
  </div>
</div>

<%@ include file="Footer.jsp" %>

<script>
const userRole = "<%= (role != null ? role : "") %>";
const userDept = "<%= (dept != null ? dept : "") %>";

// ===== Master Data =====
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
  items.push({ id: '${i.id}', name: '${i.name}', UOM: '${i.UOM}', category: '${i.category}', subcategory: '${i.subcategory}' });
</c:forEach>

document.addEventListener("DOMContentLoaded", () => {
  restrictDateToToday();

  if (userRole !== "Global" && userDept) {
    document.getElementById("departmentSelect").value = userDept;
    document.getElementById("departmentSelect").disabled = true;
  }

  document.getElementById("addItemBtn").addEventListener("click", () => addRow(userRole));
});

function addRow(userRole) {
  const deptSel = document.getElementById("departmentSelect");
  const selectedDept = deptSel.value;
  if (!selectedDept && userRole !== "Global") {
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
    <td><input type="number" class="qty" min="1" required></td>
    <td><input type="text" class="purpose" required></td>
    <td><button type="button" class="btn btn-red removeBtn">Remove</button></td>
  `;
  tbody.appendChild(tr);

  const catSel = tr.querySelector(".cat");
  const subSel = tr.querySelector(".subcat");
  const itemSel = tr.querySelector(".item");
  const uomCell = tr.querySelector(".uom");

  fillDropdowns(catSel, subSel, itemSel, uomCell, selectedDept);
  tr.querySelector(".removeBtn").onclick = () => tr.remove();
}

function fillDropdowns(catSel, subSel, itemSel, uomCell, selectedDept) {
  let filteredCats = (userRole === "Global") ? categories : categories.filter(c => c.departmentName === selectedDept);

  catSel.innerHTML = '<option value="">-- Select Category --</option>';
  filteredCats.forEach(c => {
    const opt = document.createElement('option');
    opt.value = c.name;
    opt.text = c.name;
    catSel.add(opt);
  });

  catSel.onchange = () => {
    subSel.innerHTML = '<option value="">-- Select SubCategory --</option>';
    const relatedSubs = subcategories.filter(s => s.categoryName === catSel.value);
    relatedSubs.forEach(s => {
      const o = document.createElement('option');
      o.value = s.name;
      o.text = s.name;
      subSel.add(o);
    });
    itemSel.innerHTML = '<option value="">-- Select Item --</option>';
  };

  subSel.onchange = () => {
    itemSel.innerHTML = '<option value="">-- Select Item --</option>';
    const relatedItems = items.filter(i => i.category === catSel.value && i.subcategory === subSel.value);
    relatedItems.forEach(i => {
      const o = document.createElement('option');
      o.value = i.name;
      o.text = i.name;
      o.dataset.id = i.id;
      o.dataset.uom = i.UOM;
      itemSel.add(o);
    });
  };

  itemSel.onchange = () => {
    const opt = itemSel.options[itemSel.selectedIndex];
    uomCell.textContent = opt ? opt.dataset.uom || '' : '';
  };
}

function restrictDateToToday() {
  const today = new Date().toISOString().split('T')[0];
  const dateField = document.getElementById("dateField");
  dateField.value = today;
  dateField.min = today;
  dateField.max = today;
}

// ===== Submit =====
document.getElementById('indentForm').addEventListener('submit', function() {
  const ids = [], names = [], qtys = [], purps = [], uomsArr = [];
  document.querySelectorAll("#itemsTable tbody tr").forEach(tr => {
    const sel = tr.querySelector(".item");
    const opt = sel.options[sel.selectedIndex];
    ids.push(opt ? opt.dataset.id : "");
    names.push(opt ? opt.value : "");
    qtys.push(tr.querySelector(".qty").value);
    purps.push(tr.querySelector(".purpose").value);
    uomsArr.push(tr.querySelector(".uom").textContent);
  });
  this.itemIds.value = ids.join(",");
  this.itemNames.value = names.join(",");
  this.quantities.value = qtys.join(",");
  this.purposes.value = purps.join(",");
  this.uoms.value = uomsArr.join(",");
});
</script>

</body>
</html>
