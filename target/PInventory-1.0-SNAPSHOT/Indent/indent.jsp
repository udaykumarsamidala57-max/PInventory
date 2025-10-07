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
<title>SRS System - Create Indent</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="CSS/Form.css">
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-content">
    <div class="card">
        <h2 align="center">Create Indent</h2>

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
                    <td><select name="department" id="departmentSelect"></select></td>
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

            <!-- Hidden fields for sending collected data -->
            <input type="hidden" name="itemIds">
            <input type="hidden" name="itemNames">
            <input type="hidden" name="quantities">
            <input type="hidden" name="purposes">
            <input type="hidden" name="uoms">
        </form>

        <c:if test="${not empty message}">
            <p style="color:red;">${message}</p>
        </c:if>
    </div>
</div>

<%@ include file="Footer.jsp" %>

<script>
    // Prepare master data arrays
    const department = [];
    <c:forEach var="d" items="${masterData.departments}">
        department.push({ name: '${d.name}' });
    </c:forEach>

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
            id: ${i.id},
            name: '${i.name}',
            UOM: '${i.UOM}',
            category: '${i.category}',
            subcategory: '${i.subcategory}'
        });
    </c:forEach>

    // Populate departments
    function populateDepartments() {
        const sel = document.getElementById('departmentSelect');
        sel.innerHTML = '<option value="">-- Select Department --</option>';
        department.forEach(d => {
            const opt = document.createElement('option');
            opt.value = d.name;
            opt.text = d.name;
            sel.add(opt);
        });
    }

    // Add new row
    function addRow() {
        const tbody = document.querySelector("#itemsTable tbody");
        const tr = document.createElement("tr");
        tr.innerHTML = `
            <td><select class="cat"></select></td>
            <td><select class="subcat"></select></td>
            <td><select class="item"></select></td>
            <td class="uom"></td>
            <td><input type="number" class="qty" min="1" required></td>
            <td><input type="text" class="purpose" required></td>
            <td><button type="button" class="btn btn-red removeBtn">Remove</button></td>
        `;
        tbody.appendChild(tr);

        const selectedDept = document.getElementById("departmentSelect").value;
        fillCategories(tr.querySelector(".cat"), tr.querySelector(".subcat"), tr.querySelector(".item"), tr.querySelector(".uom"), selectedDept);

        tr.querySelector(".removeBtn").onclick = () => tr.remove();
    }

    // Fill categories, subcategories, and items based on selections
    function fillCategories(catSel, subSel, itemSel, uomCell, selectedDept) {
        catSel.innerHTML = '<option value="">-- Select Category --</option>';
        const deptCategories = categories.filter(c => c.departmentName === selectedDept);
        deptCategories.forEach(c => {
            const opt = document.createElement('option');
            opt.value = c.name;
            opt.text = c.name;
            catSel.add(opt);
        });

        catSel.onchange = () => {
            subSel.innerHTML = '<option value="">-- Select SubCategory --</option>';
            const relatedSubcats = subcategories.filter(s => s.categoryName === catSel.value);
            relatedSubcats.forEach(s => {
                const o = document.createElement('option');
                o.value = s.name;
                o.text = s.name;
                subSel.add(o);
            });
            subSel.onchange();
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
            itemSel.onchange();
        };

        itemSel.onchange = () => {
            const opt = itemSel.options[itemSel.selectedIndex];
            uomCell.textContent = opt ? opt.dataset.uom || '' : '';
        };
    }

    // Collect and submit data
    document.getElementById('indentForm').addEventListener('submit', function(e) {
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

        this.itemIds.value   = ids.join(",");
        this.itemNames.value = names.join(",");
        this.quantities.value = qtys.join(",");
        this.purposes.value   = purps.join(",");
        this.uoms.value       = uomsArr.join(",");
    });

    // Set date field to today's date only
    function restrictDateToToday() {
        const today = new Date().toISOString().split('T')[0];
        const dateField = document.getElementById("dateField");
        dateField.value = today;
        dateField.min = today;
        dateField.max = today;
    }

    // Initialize page
    document.addEventListener("DOMContentLoaded", () => {
        populateDepartments();
        restrictDateToToday();
        document.getElementById("addItemBtn").addEventListener("click", () => {
            const deptSel = document.getElementById("departmentSelect");
            if (!deptSel.value) {
                alert("Please select a Department first!");
                return;
            }
            addRow();
        });
    });
</script>

</body>
</html>
