<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
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
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dining Hall Consumption Form</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="CSS/Form.css">
    <link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />

    <style>
        :root {
            --primary: #1e3a8a;
            --primary-hover: #1e40af;
            --surface-bg: #f1f5f9;
            --card-bg: #ffffff;
            --text-dark: #0f172a;
            --text-muted: #475569;
            --border-dark: #94a3b8;
            --border-light: #cbd5e1;
            --success-badge: #15803d;
            --success-bg: #dcfce7;
            --danger-badge: #b91c1c;
            --danger-bg: #fee2e2;
        }

        body {
            background-color: var(--surface-bg);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            color: var(--text-dark);
            margin: 0;
            padding: 0;
            line-height: 1.4;
        }

        .main-content {
            max-width: 1360px;
            margin: 24px auto;
            padding: 0 16px;
        }

        .card {
            background: var(--card-bg);
            border: 2px solid var(--border-dark);
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);
            padding: 24px;
        }

        .page-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 2px solid var(--text-dark);
            padding-bottom: 12px;
            margin-bottom: 20px;
        }

        .page-header .title-area {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .page-header .icon-box {
            width: 40px;
            height: 40px;
            background-color: var(--primary);
            color: #ffffff;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
        }

        .page-header h2 {
            margin: 0;
            font-size: 22px;
            font-weight: 700;
            color: var(--text-dark);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .page-header .subtitle {
            font-size: 13px;
            color: var(--text-muted);
            margin: 0;
            font-weight: 500;
        }

        .form-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px;
            background-color: #f8fafc;
            border: 1px solid var(--border-dark);
            padding: 16px;
            border-radius: 6px;
            margin-bottom: 20px;
        }

        @media (max-width: 1024px) { .form-grid { grid-template-columns: repeat(2, 1fr); } }
        @media (max-width: 640px) { .form-grid { grid-template-columns: 1fr; } }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .form-group label {
            font-size: 12px;
            font-weight: 700;
            color: var(--text-dark);
            text-transform: uppercase;
            letter-spacing: 0.4px;
        }

        .form-control-static {
            font-size: 14px;
            font-weight: 700;
            color: var(--text-dark);
            padding: 6px 10px;
            background-color: #e2e8f0;
            border: 1px solid var(--border-dark);
            border-radius: 4px;
            height: 38px;
            box-sizing: border-box;
            display: flex;
            align-items: center;
        }

        input[type="text"], input[type="date"], input[type="number"], select {
            height: 38px;
            padding: 6px 10px;
            font-size: 14px;
            font-weight: 500;
            font-family: inherit;
            color: var(--text-dark);
            background-color: #ffffff;
            border: 1px solid var(--border-dark);
            border-radius: 4px;
            box-sizing: border-box;
            width: 100%;
        }

        input:focus, select:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 2px rgba(30, 58, 138, 0.25);
        }

        input[readonly] {
            background-color: #e2e8f0;
            color: var(--text-dark);
            font-weight: 700;
            cursor: not-allowed;
        }

        .select2-container { width: 100% !important; }
        .select2-container .select2-selection--single {
            height: 38px;
            border: 1px solid var(--border-dark);
            border-radius: 4px;
            padding: 4px 8px;
        }
        .select2-container--default .select2-selection--single .select2-selection__rendered {
            line-height: 28px;
            font-size: 14px;
            font-weight: 500;
            color: var(--text-dark);
            padding-left: 0;
        }
        .select2-container--default .select2-selection--single .select2-selection__arrow { height: 36px; }

        .table-wrapper {
            border: 1px solid var(--border-dark);
            border-radius: 6px;
            overflow: hidden;
            margin-bottom: 20px;
        }

        #itemsTable {
            width: 100%;
            border-collapse: collapse;
            background: #ffffff;
        }

        #itemsTable th {
            background-color: var(--primary);
            color: #ffffff;
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 10px 12px;
            text-align: left;
            border-right: 1px solid rgba(255, 255, 255, 0.15);
        }

        #itemsTable td {
            padding: 8px 10px;
            border-bottom: 1px solid var(--border-light);
            vertical-align: middle;
            font-size: 13px;
        }

        #itemsTable tbody tr:nth-child(even) { background-color: #f8fafc; }
        #itemsTable tbody tr:hover { background-color: #f1f5f9; }

        .uom { text-align: center !important; font-weight: 600; color: var(--text-dark); }
        .stock { text-align: center !important; }

        .stock-available {
            color: var(--success-badge);
            background-color: var(--success-bg);
            padding: 2px 8px;
            border-radius: 4px;
            font-weight: 700;
            font-size: 12px;
            display: inline-block;
            border: 1px solid #86efac;
        }

        .stock-unavailable {
            color: var(--danger-badge);
            background-color: var(--danger-bg);
            padding: 2px 8px;
            border-radius: 4px;
            font-weight: 700;
            font-size: 12px;
            display: inline-block;
            border: 1px solid #fca5a5;
        }

        .qty:disabled {
            background-color: #fee2e2;
            border-color: #fca5a5;
            cursor: not-allowed;
        }

        .button-area {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding-top: 16px;
            border-top: 2px solid var(--border-dark);
        }

        .btn-brand {
            background-color: var(--primary);
            color: #ffffff;
            border: 1px solid var(--primary);
            padding: 10px 20px;
            font-size: 14px;
            font-weight: 700;
            border-radius: 4px;
            cursor: pointer;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .btn-brand:hover { background-color: var(--primary-hover); }

        .btn-neutral {
            background-color: #ffffff;
            color: var(--primary);
            border: 2px solid var(--primary);
            padding: 8px 16px;
            font-size: 13px;
            font-weight: 700;
            border-radius: 4px;
            cursor: pointer;
            text-transform: uppercase;
        }

        .btn-neutral:hover {
            background-color: var(--primary);
            color: #ffffff;
        }

        .btn-destructive {
            background-color: #ffffff;
            color: var(--danger-badge);
            border: 1px solid var(--danger-badge);
            padding: 4px 10px;
            font-size: 12px;
            font-weight: 700;
            border-radius: 4px;
            cursor: pointer;
        }

        .btn-destructive:hover {
            background-color: var(--danger-badge);
            color: #ffffff;
        }
    </style>
</head>

<body>

<%@ include file="header.jsp" %>

<div class="main-content">
    <div class="card">
        <div class="page-header">
            <div class="title-area">
                <div class="icon-box">📦</div>
                <div>
                    <h2>Dining Hall Consumption</h2>
                    <p class="subtitle">Record dining hall stock issues</p>
                </div>
            </div>
        </div>

        <form action="DiningHallServlet" method="post" id="diningForm">
            <div class="form-grid">
                <div class="form-group">
                    <label for="issueno">Issue No</label>
                    <input type="text" id="issueno" name="issueno" value="${nextIssueNo}" readonly>
                </div>

                <div class="form-group">
                    <label>Department</label>
                    <input type="hidden" name="department" value="Dining Hall">
                    <div class="form-control-static">Dining Hall</div>
                </div>

                <div class="form-group">
                    <label for="issued_to">Issued To</label>
                    <input type="text" id="issued_to" name="issued_to" placeholder="Recipient Name" required>
                </div>

                <div class="form-group">
                    <label for="session">Session</label>
                    <select name="session" id="session" required>
                        <option value="">-- Select Session --</option>
                        <option value="Morning Drink">Morning Drink</option>
                        <option value="Break Fast">Break Fast</option>
                        <option value="Lunch">Lunch</option>
                        <option value="Snacks">Snacks</option>
                        <option value="Dinner">Dinner</option>
                        <option value="Staff Tea">Staff Tea</option>
                        <option value="Special Event">Special Event</option>
                        <% if ("Global".equalsIgnoreCase(role)) { %>
                            <option value="Adjustment">Adjustment</option>
                        <% } %>
                    </select>
                </div>

                <div class="form-group">
                    <label for="issue_date">Issue Date</label>
                    <input type="date" name="issue_date" id="issue_date" required>
                </div>
            </div>

            <div class="table-wrapper">
                <table id="itemsTable">
                    <thead>
                        <tr>
                            <th style="width: 18%;">Category</th>
                            <th style="width: 18%;">SubCategory</th>
                            <th style="width: 28%;">Item</th>
                            <th style="width: 8%; text-align: center;">UOM</th>
                            <th style="width: 10%; text-align: center;">Stock</th>
                            <th style="width: 10%;">Qty Issued</th>
                            <th style="width: 15%;">Remarks</th>
                            <th style="width: 5%; text-align: center;">Action</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>

            <div class="button-area">
                <button type="button" id="addItemBtn" class="btn-neutral">+ Add Line Item</button>
                <button type="submit" class="btn-brand">Confirm Consumption</button>
            </div>
        </form>
    </div>
</div>

<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>

<script>
document.addEventListener("DOMContentLoaded", function () {

    const issueDate = document.getElementById("issue_date");
    if (issueDate) {
        issueDate.value = new Date().toISOString().split("T")[0];
    }

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

    document.getElementById("addItemBtn").addEventListener("click", function () {
        addRow();
    });

    function addRow() {
        const tbody = document.querySelector("#itemsTable tbody");
        const tr = document.createElement("tr");

        tr.innerHTML = `
            <td><select class="cat"><option value="">-- Category --</option></select></td>
            <td><select class="subcat"><option value="">-- SubCategory --</option></select></td>
            <td><select class="item" name="item_id"><option value="">-- Item --</option></select></td>
            <td class="uom"></td>
            <td class="stock"></td>
            <td><input type="number" name="qty_issued" class="qty" min="0" step="any" required></td>
            <td><input type="text" name="remarks" class="remarks"></td>
            <td style="text-align: center;"><button type="button" class="btn-destructive removeBtn">Remove</button></td>
        `;

        tbody.appendChild(tr);

        const catSel = tr.querySelector(".cat");
        const subSel = tr.querySelector(".subcat");
        const itemSel = tr.querySelector(".item");
        const uomCell = tr.querySelector(".uom");
        const stockCell = tr.querySelector(".stock");
        const qtyInput = tr.querySelector(".qty");
        const removeBtn = tr.querySelector(".removeBtn");

        $(itemSel).select2({ placeholder: "-- Select Item --", allowClear: true });

        const uniqueCats = [...new Set(categories.map(c => c.name))];
        catSel.innerHTML = '<option value="">-- Category --</option>';
        uniqueCats.forEach(name => catSel.add(new Option(name, name)));

        catSel.addEventListener("change", function () {
            subSel.innerHTML = '<option value="">-- SubCategory --</option>';
            subcategories.filter(s => s.categoryName === catSel.value)
                         .forEach(s => subSel.add(new Option(s.name, s.name)));

            $(itemSel).empty().append('<option value="">-- Item --</option>').trigger('change');
            resetRowDetails();
        });

        subSel.addEventListener("change", function () {
            $(itemSel).empty().append('<option value="">-- Item --</option>');
            items.filter(item => item.category === catSel.value && item.subcategory === subSel.value)
                 .forEach(item => {
                     const option = new Option(item.name, item.id);
                     option.dataset.uom = item.UOM || "";
                     option.dataset.stock = item.stock || "0";
                     itemSel.add(option);
                 });

            $(itemSel).trigger('change');
            resetRowDetails();
        });

        $(itemSel).on("change", function () {
            const selectedOption = itemSel.options[itemSel.selectedIndex];
            if (!selectedOption || !selectedOption.value) {
                resetRowDetails();
                return;
            }

            const stock = parseFloat(selectedOption.dataset.stock || "0");
            const uom = selectedOption.dataset.uom || "";

            uomCell.textContent = uom;

            if (stock > 0) {
                stockCell.textContent = stock;
                stockCell.className = "stock stock-available";
                qtyInput.disabled = false;
            } else {
                stockCell.textContent = "Out of Stock";
                stockCell.className = "stock stock-unavailable";
                qtyInput.disabled = true;
                qtyInput.value = "";
                alert("⚠️ Selected item is out of stock.");
            }
        });

        qtyInput.addEventListener("input", function () {
            const selectedOption = itemSel.options[itemSel.selectedIndex];
            if (!selectedOption || !selectedOption.value) return;
            const stock = parseFloat(selectedOption.dataset.stock || "0");
            const qty = parseFloat(qtyInput.value || "0");

            if (qty < 0) qtyInput.value = "";
            if (qty > stock) {
                alert("⚠️ Quantity issued exceeds available stock.");
                qtyInput.value = "";
            }
        });

        removeBtn.addEventListener("click", function () {
            $(itemSel).select2('destroy');
            tr.remove();
        });

        function resetRowDetails() {
            uomCell.textContent = "";
            stockCell.textContent = "";
            stockCell.className = "stock";
            qtyInput.value = "";
            qtyInput.disabled = false;
        }
    }

    document.getElementById("diningForm").addEventListener("submit", function (event) {
        const rows = document.querySelectorAll("#itemsTable tbody tr");
        if (rows.length === 0) {
            alert("⚠️ Please add at least one line item.");
            event.preventDefault();
            return;
        }

        let invalid = false;
        rows.forEach(tr => {
            const itemSelect = tr.querySelector(".item");
            const qtyInput = tr.querySelector(".qty");
            const itemId = itemSelect.value.trim();
            const qty = parseFloat(qtyInput.value || "0");
            const stock = parseFloat(itemSelect.options[itemSelect.selectedIndex]?.dataset.stock || "0");

            if (!itemId || stock <= 0 || isNaN(qty) || qty <= 0 || qty > stock) {
                invalid = true;
            }
        });

        if (invalid) {
            alert("⚠️ Please review item rows for missing values or stock overruns.");
            event.preventDefault();
            return;
        }

        if (!confirm("Confirm submission of this Dining Hall consumption record?")) {
            event.preventDefault();
        }
    });
});
</script>

</body>
</html>