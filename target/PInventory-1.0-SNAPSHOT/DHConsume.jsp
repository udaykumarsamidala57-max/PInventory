<%@ page contentType="text/html; charset=UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Dining Hall Consumption</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<style>
/* === RESET & PAGE BASE === */
body {
  font-family: 'Poppins', sans-serif;
  background: #f5f6fa;
  margin: 0;
  padding: 0;
}

/* === MAIN CONTENT WRAPPER === */
.main-content {
  margin-left: 230px; /* keep space for sidebar */
  padding: 90px 30px 30px; /* space below header */
  transition: all 0.3s ease;
  min-height: 100vh;
}

/* === CARD STYLE === */
.card {
  background: white;
  width: 90%;
  margin: 0 auto;
  padding: 25px 30px;
  border-radius: 12px;
  box-shadow: 0 4px 10px rgba(0,0,0,0.1);
}

/* === TABLE === */
table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
  font-size: 14px;
}
th, td {
  border: 1px solid #ccc;
  padding: 8px;
  text-align: center;
}
th {
  background: #4a69bd;
  color: white;
}

/* === BUTTONS === */
.btn {
  padding: 8px 14px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-weight: 600;
  font-size: 14px;
}
.btn-green { background: #38ada9; color: white; }
.btn-info { background: #60a3bc; color: white; }
.btn-red { background: #e55039; color: white; }

/* === HEADINGS === */
h2 {
  text-align: center;
  color: #222f3e;
  margin-bottom: 20px;
}

/* === INPUT FIELDS === */
input[type="text"], input[type="date"], input[type="number"] {
  padding: 5px;
  border: 1px solid #bbb;
  border-radius: 5px;
  width: 100%;
  box-sizing: border-box;
}

/* === FORM TABLE === */
.form-table td {
  padding: 5px 10px;
  font-weight: 500;
}
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-content">
  <div class="card">
    <h2>Dining Hall Indent Form</h2>

    <form id="indentForm" action="DHConsume" method="post">
      <table class="form-table">
        <tr>
          <td><b>Indent No:</b></td>
          <td><input type="text" name="indentNumber" value="${nextIndentNo}" readonly></td>
          <td><b>Date:</b></td>
          <td><input type="date" name="date" id="dateField" required></td>
          <td><b>Department:</b></td>
          <td><input type="text" name="department" value="Dining Hall" readonly></td>
        </tr>
      </table>

      <br>

      <table id="itemsTable">
        <thead>
          <tr>
            <th>Category</th>
            <th>SubCategory</th>
            <th>Item</th>
            <th>UOM</th>
            <th>Stock</th>
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

<script>
/* === DATA ARRAYS FROM SERVLET === */
const categories = [];
<c:forEach var="c" items="${categories}">
  categories.push({ name: '${c.name}' });
</c:forEach>

const subcategories = [];
<c:forEach var="s" items="${subcategories}">
  subcategories.push({ name: '${s.name}', categoryName: '${s.categoryName}' });
</c:forEach>

const items = [];
<c:forEach var="i" items="${items}">
  items.push({
    id: '${i.id}',
    name: '${i.name}',
    UOM: '${i.UOM}',
    category: '${i.category}',
    subcategory: '${i.subcategory}',
    stock: '${i.stock}'
  });
</c:forEach>

/* === ON LOAD === */
document.addEventListener("DOMContentLoaded", () => {
  const today = new Date().toISOString().split("T")[0];
  document.getElementById("dateField").value = today;
  document.getElementById("addItemBtn").addEventListener("click", addRow);
});

/* === ADD NEW ROW === */
function addRow() {
  const tbody = document.querySelector("#itemsTable tbody");
  const tr = document.createElement("tr");
  tr.innerHTML = `
    <td><select class="cat"><option value="">-- Select --</option></select></td>
    <td><select class="subcat"><option value="">-- Select --</option></select></td>
    <td><select class="item"><option value="">-- Select --</option></select></td>
    <td class="uom"></td>
    <td class="stock"></td>
    <td><input type="number" class="qty" min="0" step="any"></td>
    <td><input type="text" class="purpose"></td>
    <td><button type="button" class="btn btn-red removeBtn">X</button></td>
  `;
  tbody.appendChild(tr);

  const catSel = tr.querySelector(".cat");
  const subSel = tr.querySelector(".subcat");
  const itemSel = tr.querySelector(".item");
  const uomCell = tr.querySelector(".uom");
  const stockCell = tr.querySelector(".stock");

  categories.forEach(c => {
    const opt = document.createElement("option");
    opt.value = c.name;
    opt.text = c.name;
    catSel.add(opt);
  });

  catSel.onchange = () => {
    subSel.innerHTML = '<option value="">-- Select --</option>';
    subcategories.filter(s => s.categoryName === catSel.value).forEach(s => {
      const o = document.createElement("option");
      o.value = s.name;
      o.text = s.name;
      subSel.add(o);
    });
    itemSel.innerHTML = '<option value="">-- Select --</option>';
  };

  subSel.onchange = () => {
    itemSel.innerHTML = '<option value="">-- Select --</option>';
    items.filter(i => i.category === catSel.value && i.subcategory === subSel.value)
         .forEach(i => {
           const o = document.createElement("option");
           o.value = i.name;
           o.text = i.name;
           o.dataset.id = i.id;
           o.dataset.uom = i.UOM;
           o.dataset.stock = i.stock;
           itemSel.add(o);
         });
  };

  itemSel.onchange = () => {
    const opt = itemSel.options[itemSel.selectedIndex];
    uomCell.textContent = opt.dataset.uom || "";
    stockCell.textContent = opt.dataset.stock || "0";
  };

  tr.querySelector(".removeBtn").onclick = () => tr.remove();
}

/* === FORM SUBMIT === */
document.getElementById("indentForm").addEventListener("submit", function() {
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
