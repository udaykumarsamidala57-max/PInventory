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
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
    <title>SRS System - Indent List</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/Form.css">
<title>Create Indent</title>
<script>
    var department   = [];
    <c:forEach var="d" items="${masterData.departments}">
        department.push({ name: '${d.name}' });
    </c:forEach>

    var categories   = [];
    <c:forEach var="c" items="${masterData.categories}">
        categories.push({ name: '${c.name}', departmentName: '${c.departmentName}' });
    </c:forEach>

    var subcategories = [];
    <c:forEach var="s" items="${masterData.subcategories}">
        subcategories.push({ name: '${s.name}', categoryName: '${s.categoryName}' });
    </c:forEach>

    var items = [];
    <c:forEach var="i" items="${masterData.items}">
        items.push({
            id: ${i.id},
            name: '${i.name}',
            UOM: '${i.UOM}',
            category: '${i.category}',
            subcategory: '${i.subcategory}'
        });
    </c:forEach>
</script>

</head>
<body>

<%@ include file="header.jsp" %>
<center></br></br></br>
<div class="main-content">
        <div class="card">
<h2 align="center">Create Indent</h2>

<table class="main-table">
<form action="IndentServlet" method="post" id="indentForm">
   <table class="main-table">
      <tr><td><label>Indent No:</label></td>
          <td><input type="text" name="indentNumber" value="${nextIndentNo}" readonly></td></tr>
      <tr><td><label>Date:</label></td>
          <td><input type="date" name="date" required></td></tr>
      <tr><td><label>Department:</label></td>
          <td><select name="department" id="departmentSelect"></select></td></tr>
   </table>

   <!-- Items table -->
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

   <center>
       <input type="button" class="btn btn-info" onclick="addRow()" value="Add Item">
       <input type="submit" class="btn btn-green" value="Save Indent">
   </center>

   <!-- ✅ Hidden fields placed here -->
   <input type="hidden" name="itemIds">
   <input type="hidden" name="itemNames">
   <input type="hidden" name="quantities">
   <input type="hidden" name="purposes">
   <input type="hidden" name="uoms">
</form>


<script>
function populateDepartments() {
    const sel = document.getElementById('departmentSelect');
    department.forEach(d => {
        let opt = document.createElement('option');
        opt.value = d.name;
        opt.text = d.name;
        sel.add(opt);
    });
}
populateDepartments();

function addRow() {
    const tbody = document.querySelector("#itemsTable tbody");
    const tr = document.createElement("tr");
    tr.innerHTML = `
        <td><select class="cat"></select></td>
        <td><select class="subcat"></select></td>
        <td><select class="item"></select></td>
        <td class="uom"></td>
        <td><input type="number" class="qty" min="1"></td>
        <td><input type="text" class="purpose"></td>
        <td><input type="button" onclick="this.closest('tr').remove()" value="Remove" class="btn btn-red"></td>
    `;
    tbody.appendChild(tr);
    fillCategories(tr.querySelector(".cat"), tr.querySelector(".subcat"), tr.querySelector(".item"), tr.querySelector(".uom"));
}

function fillCategories(catSel, subSel, itemSel, uomCell) {
    categories.forEach(c => {
        let o = document.createElement('option');
        o.value = c.name;
        o.text = c.name;
        catSel.add(o);
    });

    catSel.onchange = () => {
        subSel.innerHTML = '';
        subcategories.filter(s => s.categoryName === catSel.value)
            .forEach(s => {
                let o = document.createElement('option');
                o.value = s.name;
                o.text = s.name;
                subSel.add(o);
            });
        subSel.onchange();
    };

    subSel.onchange = () => {
        itemSel.innerHTML = '';
        items.filter(i => i.category === catSel.value && i.subcategory === subSel.value)
            .forEach(i => {
                let o = document.createElement('option');
                o.value = i.name;
                o.text = i.name;
                o.dataset.id = i.id;      // ✅ attach item id
                o.dataset.uom = i.UOM;
                itemSel.add(o);
            });
        itemSel.onchange();
    };

    itemSel.onchange = () => {
        let opt = itemSel.options[itemSel.selectedIndex];
        uomCell.textContent = opt ? opt.dataset.uom : '';
    };

    catSel.onchange();
}

// collect data before submit
document.getElementById('indentForm').onsubmit = function() {
    const ids = [], names = [], qtys = [], purps = [], uomsArr = [];
    document.querySelectorAll("#itemsTable tbody tr").forEach(tr => {
        let sel = tr.querySelector(".item");
        let opt = sel.options[sel.selectedIndex];
        ids.push(opt ? opt.dataset.id : "");
        names.push(opt ? opt.value : "");
        qtys.push(tr.querySelector(".qty").value);
        purps.push(tr.querySelector(".purpose").value);
        uomsArr.push(tr.querySelector(".uom").textContent);
    });
    this.itemIds.value   = ids.join(",");
    this.itemNames.value = names.join(",");
    this.quantities.value = qtys.join(",");
    this.purposes.value   = purps.join(",");
    this.uoms.value       = uomsArr.join(",");
};
</script>

<c:if test="${not empty message}">
    <p style="color:red;">${message}</p>
</c:if>
</div>
<%@ include file="Footer.jsp" %>


</body>
</html>
