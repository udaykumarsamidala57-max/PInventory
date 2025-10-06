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
<title>Issue Stock</title>
<script>
    var items = [];
    <c:forEach var="i" items="${items}">
        items.push({
            id: ${i.id},                 // item_id
            name: '${i.name}',
            UOM: '${i.UOM}',
            category: '${i.category}',
            subcategory: '${i.subcategory}',
            available: '${i.available}'  // 👈 available qty from servlet
        });
    </c:forEach>

    var categories = [];
    <c:forEach var="c" items="${categories}">
        categories.push('${c}');
    </c:forEach>;

    function getSubCategories(cat) {
        let subs = [...new Set(items.filter(i => i.category === cat).map(i => i.subcategory))];
        return subs;
    }

    function getItems(cat, subcat) {
        return items.filter(i => i.category === cat && i.subcategory === subcat);
    }
</script>
<meta charset="UTF-8">
    <title>SRS System - Issue Stock</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/Form.css">
</head>
<body>
<%@ include file="header.jsp" %>
<center>
<div class="main-content">
    <div class="card">
        <h2 align="center">Issue Stock</h2>

        <form action="IssueServlet" method="post" id="issueForm">
        <table class="main-table">
        <tr>
            <td>Issue No:</td>
            <td><input type="text" name="issueno" value="${nextIssueNo}" readonly></td>
        </tr>
        <tr>
            <td>Issued To:</td>
            <td><input type="text" name="issuedTo" required></td>
        </tr>
        <tr>
            <td>Remarks:</td>
            <td><input type="text" name="remarks"></td>
        </tr>
        </table>

        <!-- Items Table -->
        <table class="main-table" id="itemsTable">
        <thead>
        <tr>
            <th>Category</th>
            <th>SubCategory</th>
            <th>Item</th>
            <th>UOM</th>
            <th>Available Qty</th>
            <th>Qty Issued</th>
            <th>Action</th>
        </tr>
        </thead>
        <tbody></tbody>
        </table>

        <!-- Hidden fields for servlet -->
        <input type="hidden" name="itemIds">
        <input type="hidden" name="quantities">

        <input type="button" value="Add Item" class="btn btn-info" onclick="addRow()">
        <input type="submit"  class="btn btn-green" value="Save Issue">
        </form>

        <script>
        function addRow() {
            const tbody = document.querySelector("#itemsTable tbody");
            const tr = document.createElement("tr");
            tr.innerHTML = `
                <td>
                    <select class="cat"><option value="">--Select--</option></select>
                </td>
                <td>
                    <select class="subcat"><option value="">--Select--</option></select>
                </td>
                <td>
                    <select class="item"><option value="">--Select--</option></select>
                </td>
                <td class="uom"></td>
                <td class="available"></td>
                <td><input type="number" class="qty" min="1" required></td>
                <td><button type="button" onclick="this.closest('tr').remove()" class="btn btn-red">Remove</button></td>
            `;
            tbody.appendChild(tr);

            let catSel = tr.querySelector(".cat");
            let subcatSel = tr.querySelector(".subcat");
            let itemSel = tr.querySelector(".item");
            let uomCell = tr.querySelector(".uom");
            let availCell = tr.querySelector(".available");
            let qtyInput = tr.querySelector(".qty");

            // Fill categories
            categories.forEach(c => {
                let o = document.createElement('option');
                o.value = c; o.text = c;
                catSel.add(o);
            });

            catSel.onchange = () => {
                subcatSel.innerHTML = '<option value="">--Select--</option>';
                itemSel.innerHTML = '<option value="">--Select--</option>';
                uomCell.textContent = '';
                availCell.textContent = '';
                qtyInput.value = '';

                if (catSel.value) {
                    getSubCategories(catSel.value).forEach(s => {
                        let o = document.createElement('option');
                        o.value = s; o.text = s;
                        subcatSel.add(o);
                    });
                }
            };

            subcatSel.onchange = () => {
                itemSel.innerHTML = '<option value="">--Select--</option>';
                uomCell.textContent = '';
                availCell.textContent = '';
                qtyInput.value = '';

                if (catSel.value && subcatSel.value) {
                    getItems(catSel.value, subcatSel.value).forEach(i => {
                        let o = document.createElement('option');
                        o.value = i.id; // ITEM_ID
                        o.text = i.name + " (Avail: " + i.available + ")";
                        o.dataset.uom = i.UOM;
                        o.dataset.available = i.available;
                        itemSel.add(o);
                    });
                }
            };

            itemSel.onchange = () => {
                let opt = itemSel.options[itemSel.selectedIndex];
                if (opt) {
                    uomCell.textContent = opt.dataset.uom;
                    availCell.textContent = opt.dataset.available;
                    qtyInput.max = opt.dataset.available; // 👈 restricts entry
                }
            };
        }

        // Prepare hidden fields before submit
        document.getElementById('issueForm').onsubmit = function() {
            const ids = [], qtys = [];
            document.querySelectorAll("#itemsTable tbody tr").forEach(tr => {
                let sel = tr.querySelector(".item");
                if(sel && sel.value){
                    ids.push(sel.value);
                    qtys.push(tr.querySelector(".qty").value);
                }
            });
            this.itemIds.value = ids.join(",");
            this.quantities.value = qtys.join(",");
        };
        </script>

        <c:if test="${not empty message}">
            <p style="color:green;">${message}</p>
        </c:if>
    </div>

    <jsp:include page="Footer.jsp" />
</div>
</center>
</body>
</html>
