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
<title>Dining Hall Consumption Form</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Form.css">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  select {
    width: 180px;
    max-height: 180px;
    overflow-y: auto;
  }
  table.main-table select {
    padding: 4px;
    font-size: 14px;
  }
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-content">
  <div class="card">
    <h2 align="center">DINING HALL CONSUMPTION FORM</h2>

    <form action="DiningHallServlet" method="post" id="diningForm">
      <table class="main-table">
        <tr>
          <td><label>Issue No:</label></td>
          <td><input type="text" name="issueno" value="${nextIssueNo}" readonly></td>
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
        <tr>
          <td><label>Issued To:</label></td>
          <td><input type="text" name="issued_to" required></td>
        </tr>
        <tr>
          <td><label>Session:</label></td>
          <td>
            <select name="session" required>
              <option value="">-- Select --</option>
              <option>Morning Drink</option>
              <option>Break Fast</option>
              <option>Lunch</option>
              <option>Snacks</option>
              <option>Dinner</option>
              <option>Staff Tea</option>
              <option>Special Event</option>
            </select>
          </td>
        </tr>
        <tr>
          <td><label>Issue Date:</label></td>
          <td><input type="date" name="issue_date" id="issue_date" required></td>
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
            <th>Available Stock</th>
            <th>Qty Issued</th>
            <th>Remarks</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody></tbody>
      </table>

      <center style="margin-top: 15px;">
        <button type="button" id="addItemBtn" class="btn btn-info">➕ Add Item</button>
        <button type="submit" class="btn btn-green">✅ Submit Consumption</button>
      </center>
    </form>
  </div>
</div>

<%@ include file="Footer.jsp" %>

<script>
document.addEventListener("DOMContentLoaded", () => {
  const userRole = "<%= (role != null ? role : "") %>".toLowerCase();
  const userDept = "<%= (dept != null ? dept : "") %>";

  // Auto-set today's date
  const dateInput = document.getElementById("issue_date");
  const today = new Date().toISOString().split('T')[0];
  dateInput.value = today;

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

  // 🔹 Preselect department for non-global users
  if (userRole !== "global" && userDept) {
    const deptSelect = document.getElementById("departmentSelect");
    deptSelect.value = userDept;
    deptSelect.disabled = true;
  }

  // ✅ Add Row button
  document.getElementById("addItemBtn").addEventListener("click", () => addRow());

  // ✅ Add Row function
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
      <td><select class="item" name="item_id"><option value="">-- Select Item --</option></select></td>
      <td class="uom"></td>
      <td class="stock"></td>
      <td><input type="number" name="qty_issued" class="qty" min="0" step="any" required></td>
      <td><input type="text" name="remarks" class="remarks" required></td>
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
    let filteredCats = [];
    if (userRole === "global") {
      filteredCats = categories;
    } else {
      filteredCats = categories.filter(c => 
        c.departmentName === selectedDept || c.departmentName.toLowerCase() === 'common'
      );
    }

    const uniqueNames = [...new Set(filteredCats.map(c => c.name))];
    catSel.innerHTML = '<option value="">-- Select Category --</option>';
    uniqueNames.forEach(name => {
      const opt = document.createElement('option');
      opt.value = name;
      opt.text = name;
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
      const relatedItems = items.filter(i => 
        i.category === catSel.value && i.subcategory === subSel.value
      );
      relatedItems.forEach(i => {
        const o = document.createElement('option');
        o.value = i.id;
        o.text = i.name;
        o.dataset.uom = i.UOM;
        o.dataset.stock = i.stock;
        itemSel.add(o);
      });
    };

    itemSel.onchange = () => {
      const opt = itemSel.options[itemSel.selectedIndex];
      uomCell.textContent = opt ? opt.dataset.uom || '' : '';
      stockCell.textContent = opt ? opt.dataset.stock || '0' : '0';
    };
  }
});
</script>

</body>
</html>
