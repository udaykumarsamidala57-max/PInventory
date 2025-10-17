<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
<title>Add Stock</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Form.css">
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-content">
  <div class="card">
    <h2 align="center">ADD STOCK</h2>

    <form action="AddStock" method="post" id="stockForm">
      <table class="main-table" id="stockTable">
        <thead>
          <tr>
            <th>Category</th>
            <th>Sub Category</th>
            <th>Item Name</th>
            <th>UOM</th>
            <th>Stock Qty</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody></tbody>
      </table>

      <br>
      <center>
        <button type="button" class="btn btn-info" id="addRowBtn">Add Row</button>
        <button type="submit" class="btn btn-green">Save Stock</button>
      </center>

      <input type="hidden" name="itemIds">
      <input type="hidden" name="quantities">
    </form>
  </div>
</div>

<%@ include file="Footer.jsp" %>

<script>
const categories = [];
<c:forEach var="i" items="${masterData.items}">
  if (!categories.includes('${i.category}')) categories.push('${i.category}');
</c:forEach>

const items = [];
<c:forEach var="i" items="${masterData.items}">
  items.push({
    id: '${i.id}',
    name: '${i.name}',
    category: '${i.category}',
    subcategory: '${i.subcategory}',
    uom: '${i.UOM}'
  });
</c:forEach>

document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("addRowBtn").addEventListener("click", addRow);
});

function addRow() {
  const tbody = document.querySelector("#stockTable tbody");
  const tr = document.createElement("tr");
  tr.innerHTML = `
    <td><select class="cat"><option value="">--Select--</option></select></td>
    <td><select class="subcat"><option value="">--Select--</option></select></td>
    <td><select class="item"><option value="">--Select--</option></select></td>
    <td class="uom"></td>
    <td><input type="number" min="1" class="qty" required></td>
    <td><button type="button" class="btn btn-red removeBtn">Remove</button></td>
  `;
  tbody.appendChild(tr);

  const catSel = tr.querySelector(".cat");
  const subSel = tr.querySelector(".subcat");
  const itemSel = tr.querySelector(".item");
  const uomCell = tr.querySelector(".uom");

  categories.forEach(c => {
    const opt = document.createElement("option");
    opt.value = c;
    opt.text = c;
    catSel.add(opt);
  });

  catSel.onchange = () => {
    const selectedCat = catSel.value;
    subSel.innerHTML = '<option value="">--Select--</option>';
    const uniqueSubs = [...new Set(items.filter(i => i.category === selectedCat).map(i => i.subcategory))];
    uniqueSubs.forEach(s => {
      const opt = document.createElement("option");
      opt.value = s;
      opt.text = s;
      subSel.add(opt);
    });
    itemSel.innerHTML = '<option value="">--Select--</option>';
    uomCell.textContent = '';
  };

  subSel.onchange = () => {
    const selectedCat = catSel.value;
    const selectedSub = subSel.value;
    itemSel.innerHTML = '<option value="">--Select--</option>';
    items.filter(i => i.category === selectedCat && i.subcategory === selectedSub)
         .forEach(i => {
            const opt = document.createElement("option");
            opt.value = i.id;
            opt.text = i.name;
            opt.dataset.uom = i.uom;
            itemSel.add(opt);
         });
  };

  itemSel.onchange = () => {
    const uom = itemSel.options[itemSel.selectedIndex].dataset.uom || '';
    uomCell.textContent = uom;
  };

  tr.querySelector(".removeBtn").onclick = () => tr.remove();
}

// ======== Submit handler ========
document.getElementById("stockForm").addEventListener("submit", function() {
  const ids = [], qtys = [];
  document.querySelectorAll("#stockTable tbody tr").forEach(tr => {
    const itemSel = tr.querySelector(".item");
    const id = itemSel.value;
    const qty = tr.querySelector(".qty").value;
    if (id && qty > 0) {
      ids.push(id);
      qtys.push(qty);
    }
  });
  this.itemIds.value = ids.join(",");
  this.quantities.value = qtys.join(",");
});
</script>

</body>
</html>
