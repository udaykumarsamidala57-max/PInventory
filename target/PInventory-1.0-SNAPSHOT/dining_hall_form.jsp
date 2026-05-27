<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String user = (String) sess.getAttribute("username");
    String role = (String) sess.getAttribute("role");
    String dept = (String) sess.getAttribute("department");
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
select { width: 180px; max-height: 180px; overflow-y: auto; }
table.main-table select { padding: 4px; font-size: 14px; }
.stock-unavailable { color: red; font-weight: 600; }
.qty[disabled] { background-color: #f8d7da; cursor: not-allowed; }
</style>
</head>
<body>
<%@ include file="header.jsp" %>

<div class="main-content">
  <div class="card">
    <h2 align="center">DINING HALL CONSUMPTION FORM</h2>
    <form action="DiningHallServlet" method="post" id="diningForm">
      <table class="main-table">
        <tr><td><label>Issue No:</label></td><td><input type="text" name="issueno" value="${nextIssueNo}" readonly></td></tr>
        <tr><td><label>Department:</label></td><td><input type="hidden" name="department" value="Dining Hall"><b>Dining Hall</b></td></tr>
        <tr><td><label>Issued To:</label></td><td><input type="text" name="issued_to" required></td></tr>
        <tr><td><label>Session:</label></td>
          <td>
            <select name="session" required>
              <option value="">-- Select --</option>
              <option>Morning Drink</option><option>Break Fast</option><option>Lunch</option>
              <option>Snacks</option><option>Dinner</option><option>Staff Tea</option><option>Special Event</option>
            </select>
          </td></tr>
        <tr><td><label>Issue Date:</label></td><td><input type="date" name="issue_date" id="issue_date" required></td></tr>
      </table><br>

      <table border="1" id="itemsTable" class="main-table">
        <thead>
          <tr><th>Category</th><th>SubCategory</th><th>Item</th><th>UOM</th><th>Available Stock</th><th>Qty Issued</th><th>Remarks</th><th>Action</th></tr>
        </thead><tbody></tbody>
      </table>

      <center style="margin-top:15px;">
        <button type="button" id="addItemBtn" class="btn btn-info">➕ Add Item</button>
        <button type="submit" class="btn btn-green">✅ Submit Consumption</button>
      </center>
    </form>
  </div>
</div>



<script>
document.addEventListener("DOMContentLoaded", () => {
  const today = new Date().toISOString().split('T')[0];
  document.getElementById("issue_date").value = today;

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
    items.push({ id: '${i.id}', name: '${i.name}', UOM: '${i.UOM}', category: '${i.category}', subcategory: '${i.subcategory}', stock: '${i.stock}' });
  </c:forEach>

  document.getElementById("addItemBtn").addEventListener("click", () => addRow());

  function addRow() {
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
      <td><button type="button" class="btn btn-red removeBtn">Remove</button></td>`;
    tbody.appendChild(tr);

    const catSel = tr.querySelector(".cat");
    const subSel = tr.querySelector(".subcat");
    const itemSel = tr.querySelector(".item");
    const uomCell = tr.querySelector(".uom");
    const stockCell = tr.querySelector(".stock");
    const qtyInput = tr.querySelector(".qty");

    const uniqueCats = [...new Set(categories.map(c => c.name))];
    catSel.innerHTML = '<option value="">-- Select Category --</option>';
    uniqueCats.forEach(n => catSel.add(new Option(n, n)));

    catSel.onchange = () => {
      subSel.innerHTML = '<option value="">-- Select SubCategory --</option>';
      subcategories.filter(s => s.categoryName === catSel.value)
        .forEach(s => subSel.add(new Option(s.name, s.name)));
      itemSel.innerHTML = '<option value="">-- Select Item --</option>';
      uomCell.textContent = '';
      stockCell.textContent = '';
      qtyInput.value = '';
      qtyInput.disabled = false;
      stockCell.classList.remove("stock-unavailable");
    };

    subSel.onchange = () => {
      itemSel.innerHTML = '<option value="">-- Select Item --</option>';
      items.filter(i => i.category === catSel.value && i.subcategory === subSel.value)
        .forEach(i => {
          const opt = new Option(i.name, i.id);
          opt.dataset.uom = i.UOM;
          opt.dataset.stock = i.stock;
          itemSel.add(opt);
        });
      uomCell.textContent = '';
      stockCell.textContent = '';
      qtyInput.value = '';
      qtyInput.disabled = false;
      stockCell.classList.remove("stock-unavailable");
    };

    itemSel.onchange = () => {
      const opt = itemSel.options[itemSel.selectedIndex];
      const stock = parseFloat(opt?.dataset.stock || '0');
      uomCell.textContent = opt?.dataset.uom || '';
      stockCell.textContent = stock > 0 ? stock : "Stock Not Available";

      if (stock <= 0) {
        stockCell.classList.add("stock-unavailable");
        qtyInput.disabled = true;
        qtyInput.value = '';
        alert("⚠️ Stock not available for this item! Please remove or choose another item.");
      } else {
        stockCell.classList.remove("stock-unavailable");
        qtyInput.disabled = false;
      }
    };

   
    qtyInput.addEventListener("input", () => {
      const opt = itemSel.options[itemSel.selectedIndex];
      const stock = parseFloat(opt?.dataset.stock || '0');
      const qty = parseFloat(qtyInput.value || '0');

      if (qty > stock) {
        alert("⚠️ Quantity issued cannot be greater than available stock!");
        qtyInput.value = '';
      }
    });

    tr.querySelector(".removeBtn").onclick = () => tr.remove();
  }

  
  document.getElementById("diningForm").addEventListener("submit", (e) => {
    let invalid = false;
    document.querySelectorAll("#itemsTable tbody tr").forEach(tr => {
      const stockText = tr.querySelector(".stock").textContent.trim();
      const qtyInput = tr.querySelector(".qty");
      const stock = parseFloat(stockText) || 0;
      const qty = parseFloat(qtyInput.value) || 0;

      if (stock <= 0 || qty > stock) {
        invalid = true;
      }
    });

    if (invalid) {
      alert("⚠️ Some items have invalid stock or quantity values. Please fix or remove them before submitting.");
      e.preventDefault();
    }
  });
});
</script>
</body>
</html>
