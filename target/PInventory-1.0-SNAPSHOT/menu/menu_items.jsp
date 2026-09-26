<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List"%>
<%@ page import="java.util.Map"%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Menu Items Management</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

<style>
*, *::before, *::after { box-sizing: border-box; }

body {
    margin: 0;
    background-color: #f8fafc;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    color: #1e293b;
    line-height: 1.5;
}

.container {
    max-width: 1280px;
    margin: 0 auto;
    padding: 24px 20px 48px 20px;
}

.page-header {
    background: #ffffff;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    padding: 20px 24px;
    margin-bottom: 24px;
}

.page-title { margin: 0; font-size: 20px; font-weight: 700; color: #0f172a; }
.page-subtitle { margin-top: 4px; color: #64748b; font-size: 13px; }

/* Day Filter Navigation */
.day-tabs {
    display: flex;
    gap: 8px;
    margin-bottom: 24px;
    overflow-x: auto;
    padding-bottom: 4px;
}

.day-tab {
    background: #ffffff;
    border: 1px solid #cbd5e1;
    color: #475569;
    padding: 10px 18px;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    text-decoration: none;
    transition: all 0.15s ease;
    white-space: nowrap;
}

.day-tab:hover { background: #f1f5f9; color: #0f172a; }
.day-tab.active {
    background: #0284c7;
    border-color: #0284c7;
    color: #ffffff;
}

.message {
    padding: 12px 16px;
    border-radius: 8px;
    margin-bottom: 20px;
    font-size: 14px;
    font-weight: 500;
}
.message.success { background: #f0fdf4; border: 1px solid #bbf7d0; color: #166534; }
.message.error { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; }

.menu-cards-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
    gap: 20px;
}

.menu-card {
    background: #ffffff;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.03);
    display: flex;
    flex-direction: column;
    overflow: hidden;
}

.menu-card-header {
    padding: 16px 20px;
    background: #f8fafc;
    border-bottom: 1px solid #e2e8f0;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.menu-title { font-weight: 700; color: #0f172a; font-size: 15px; }
.session-tag {
    background: #e0f2fe;
    color: #0369a1;
    font-size: 11px;
    font-weight: 600;
    padding: 3px 8px;
    border-radius: 4px;
    text-transform: uppercase;
}

.menu-card-body { padding: 16px 20px; flex: 1; }

.item-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
}

.item-table th {
    text-align: left;
    color: #64748b;
    font-size: 11px;
    text-transform: uppercase;
    border-bottom: 1px solid #e2e8f0;
    padding-bottom: 8px;
}

.item-table td {
    padding: 10px 0;
    border-bottom: 1px solid #f1f5f9;
}

.item-table tr:last-child td { border-bottom: none; }

.item-category-tag {
    display: inline-block;
    font-size: 11px;
    color: #64748b;
}

.btn {
    height: 36px;
    border: 1px solid transparent;
    border-radius: 6px;
    padding: 0 14px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    text-decoration: none;
}

.btn-primary { background: #0284c7; color: #ffffff; }
.btn-primary:hover { background: #0369a1; }
.btn-secondary { background: #ffffff; border-color: #cbd5e1; color: #475569; }
.btn-secondary:hover { background: #f1f5f9; }
.btn-sm-danger { color: #dc2626; background: #fef2f2; border: 1px solid #fecaca; padding: 2px 8px; font-size: 11px; border-radius: 4px; cursor: pointer; }
.btn-sm-danger:hover { background: #fee2e2; }

/* Modal Styles */
.modal-overlay {
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(15, 23, 42, 0.4);
    display: none;
    align-items: center;
    justify-content: center;
    z-index: 1000;
}

.modal-overlay.active { display: flex; }

.modal {
    background: #ffffff;
    border-radius: 12px;
    width: 100%;
    max-width: 680px;
    padding: 24px;
    box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
}

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}

.modal-title { font-size: 16px; font-weight: 700; color: #0f172a; }

.form-group { margin-bottom: 12px; }
.form-label { display: block; font-size: 12px; font-weight: 600; color: #475569; margin-bottom: 6px; text-transform: uppercase; }
.form-control {
    width: 100%;
    height: 38px;
    border: 1px solid #cbd5e1;
    border-radius: 6px;
    padding: 0 12px;
    font-size: 13px;
    background: #ffffff;
}
.form-control:focus { outline: none; border-color: #0284c7; }

.staging-table-container {
    max-height: 200px;
    overflow-y: auto;
    border: 1px solid #e2e8f0;
    border-radius: 6px;
    margin-top: 16px;
}

.staging-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
}

.staging-table th {
    background: #f8fafc;
    padding: 8px 12px;
    text-align: left;
    font-size: 11px;
    color: #64748b;
    border-bottom: 1px solid #e2e8f0;
}

.staging-table td {
    padding: 8px 12px;
    border-bottom: 1px solid #f1f5f9;
}

.modal-actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 20px; }
</style>
</head>

<body>

<div class="container">

    <div class="page-header">
        <h1 class="page-title">Menu Configurations</h1>
        <div class="page-subtitle">Filter menus by day and configure portioned items using category dynamic filters</div>
    </div>

    <%
        String success = request.getParameter("success");
        if ("1".equals(success)) {
    %>
        <div class="message success">Menu items updated successfully.</div>
    <%
        }
        String error = (String) request.getAttribute("error");
        if (error != null && !error.trim().isEmpty()) {
    %>
        <div class="message error"><%=error%></div>
    <%
        }
    %>

    <%
        String activeDay = request.getParameter("day");
        if (activeDay == null || activeDay.trim().isEmpty()) {
            activeDay = "MONDAY";
        }
        String[] days = {"MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"};
    %>

    <!-- DAY TABS -->
    <div class="day-tabs">
        <% for (String day : days) { %>
            <a href="<%=request.getContextPath()%>/MenuItemsServlet?day=<%=day%>" 
               class="day-tab <%=day.equalsIgnoreCase(activeDay) ? "active" : ""%>">
               <%=day%>
            </a>
        <% } %>
    </div>

    <!-- CARDS GRID -->
    <div class="menu-cards-grid">
        <%
            List<Map<String,Object>> menus = (List<Map<String,Object>>) request.getAttribute("menus");
            List<Map<String,Object>> menuItems = (List<Map<String,Object>>) request.getAttribute("menuItems");

            boolean foundMenusForDay = false;

            if (menus != null) {
                for (Map<String,Object> menu : menus) {
                    String menuDay = String.valueOf(menu.get("day_of_week"));

                    if (menuDay.equalsIgnoreCase(activeDay)) {
                        foundMenusForDay = true;
                        int menuId = Integer.parseInt(String.valueOf(menu.get("menu_id")));
                        String menuName = String.valueOf(menu.get("menu_name"));
                        String sessionName = String.valueOf(menu.get("session"));
        %>
            <div class="menu-card">
                <div class="menu-card-header">
                    <div class="menu-title"><%=menuName%></div>
                    <span class="session-tag"><%=sessionName%></span>
                </div>

                <div class="menu-card-body">
                    <table class="item-table">
                        <thead>
                            <tr>
                                <th>Seq</th>
                                <th>Item details</th>
                                <th style="text-align: right;">Qty</th>
                                <th style="text-align: right;">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            boolean hasItems = false;
                            if (menuItems != null) {
                                for (Map<String,Object> row : menuItems) {
                                    int itemMenuId = Integer.parseInt(String.valueOf(row.get("menu_id")));
                                    if (itemMenuId == menuId) {
                                        hasItems = true;
                        %>
                            <tr>
                                <td style="color: #94a3b8;"><%=row.get("sequence_no")%></td>
                                <td>
                                    <strong><%=row.get("item_name")%></strong><br>
                                    <span class="item-category-tag">
                                        <%=row.get("category")%>
                                        <% if (row.get("sub_category") != null && !String.valueOf(row.get("sub_category")).trim().isEmpty()) { %>
                                            / <%=row.get("sub_category")%>
                                        <% } %>
                                    </span>
                                </td>
                                <td style="text-align: right; font-weight: 600;">
                                    <%=row.get("quantity")%> <%=row.get("uom") != null ? row.get("uom") : ""%>
                                </td>
                                <td style="text-align: right;">
                                    <form method="post" action="<%=request.getContextPath()%>/MenuItemsServlet" style="display:inline;" onsubmit="return confirm('Remove this item?');">
                                        <input type="hidden" name="action" value="delete">
                                        <input type="hidden" name="menu_item_id" value="<%=row.get("menu_item_id")%>">
                                        <input type="hidden" name="day" value="<%=activeDay%>">
                                        <button type="submit" class="btn-sm-danger">Remove</button>
                                    </form>
                                </td>
                            </tr>
                        <%
                                    }
                                }
                            }
                            if (!hasItems) {
                        %>
                            <tr>
                                <td colspan="4" style="text-align: center; color: #94a3b8; padding: 20px 0;">
                                    No items configured for this menu yet.
                                </td>
                            </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>

                <div style="padding: 12px 20px; background: #f8fafc; border-top: 1px solid #e2e8f0; text-align: right;">
                    <button class="btn btn-primary" onclick="openAddItemModal('<%=menuId%>', '<%=menuName%> (<%=sessionName%>)')">
                        + Add Items
                    </button>
                </div>
            </div>
        <%
                    }
                }
            }

            if (!foundMenusForDay) {
        %>
            <div style="grid-column: 1 / -1; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 48px; text-align: center; color: #64748b;">
                <strong>No active menus configured for <%=activeDay%>.</strong>
            </div>
        <% } %>
    </div>

</div>

<!-- MULTI-ITEM ADD MODAL -->
<div class="modal-overlay" id="addItemModal">
    <div class="modal">
        <div class="modal-header">
            <div class="modal-title" id="modalMenuTitle">Add Items to Menu</div>
            <button type="button" onclick="closeAddItemModal()" style="border:none; background:none; cursor:pointer; font-size:18px;">&times;</button>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
            <!-- CATEGORY -->
            <div class="form-group">
                <label class="form-label">Category</label>
                <select id="filter_category" class="form-control" onchange="onCategoryChange()">
                    <option value="">-- All Categories --</option>
                </select>
            </div>

            <!-- SUB-CATEGORY -->
            <div class="form-group">
                <label class="form-label">Sub Category</label>
                <select id="filter_sub_category" class="form-control" onchange="onSubCategoryChange()">
                    <option value="">-- All Sub Categories --</option>
                </select>
            </div>
        </div>

        <!-- ITEM MASTER DROPDOWN -->
        <div class="form-group">
            <label class="form-label">Catalog Item</label>
            <select id="modal_item_id" class="form-control">
                <option value="">-- Select Item --</option>
            </select>
        </div>

        <div style="display: flex; gap: 12px; align-items: flex-end;">
            <div class="form-group" style="flex: 1;">
                <label class="form-label">Quantity</label>
                <input type="number" id="modal_quantity" class="form-control" value="1.00" min="0.01" step="0.01">
            </div>

            <div class="form-group" style="flex: 1;">
                <label class="form-label">Sequence No.</label>
                <input type="number" id="modal_sequence" class="form-control" value="1" min="1" step="1">
            </div>

            <div class="form-group">
                <button type="button" class="btn btn-secondary" onclick="addItemToStagingList()">+ Add to List</button>
            </div>
        </div>

        <form method="post" action="<%=request.getContextPath()%>/MenuItemsServlet" id="multiItemForm" onsubmit="return validateFormSubmit();">
            <input type="hidden" name="action" value="save">
            <input type="hidden" name="menu_id" id="modal_menu_id">
            <input type="hidden" name="day" value="<%=activeDay%>">

            <!-- STAGING TABLE FOR MULTIPLE ITEMS -->
            <div class="staging-table-container">
                <table class="staging-table">
                    <thead>
                        <tr>
                            <th>Item Name</th>
                            <th style="width: 80px;">Qty</th>
                            <th style="width: 80px;">Seq</th>
                            <th style="width: 60px; text-align: center;">Action</th>
                        </tr>
                    </thead>
                    <tbody id="stagingTableBody">
                        <tr id="emptyStagingRow">
                            <td colspan="4" style="text-align: center; color: #94a3b8; padding: 16px;">
                                No items added to list yet. Select an item above and click "+ Add to List".
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div class="modal-actions">
                <button type="button" class="btn btn-secondary" onclick="closeAddItemModal()">Cancel</button>
                <button type="submit" class="btn btn-primary">Save All Items</button>
            </div>
        </form>
    </div>
</div>

<!-- CLIENT-SIDE SCRIPT -->
<script>
<%
    List<Map<String,Object>> itemsList = (List<Map<String,Object>>) request.getAttribute("items");
%>
const allCatalogItems = [
<%
    if (itemsList != null) {
        for (int i = 0; i < itemsList.size(); i++) {
            Map<String,Object> item = itemsList.get(i);
            
            String itemId = String.valueOf(item.get("item_id"));
            String itemName = item.get("item_name") != null 
                ? String.valueOf(item.get("item_name")).replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "").replace("\n", " ") : "";
            String category = item.get("category") != null 
                ? String.valueOf(item.get("category")).replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "").replace("\n", " ") : "";
            String subCategory = item.get("sub_category") != null 
                ? String.valueOf(item.get("sub_category")).replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "").replace("\n", " ") : "";
            String uom = item.get("uom") != null 
                ? String.valueOf(item.get("uom")).replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "").replace("\n", " ") : "";
%>
    {
        id: "<%=itemId%>",
        name: "<%=itemName%>",
        category: "<%=category%>",
        subCategory: "<%=subCategory%>",
        uom: "<%=uom%>"
    }<%= (i < itemsList.size() - 1) ? "," : "" %>
<%
        }
    }
%>
];

let stagedItems = [];

function initCategoryDropdowns() {
    const categorySelect = document.getElementById("filter_category");
    if (!categorySelect) return;
    
    categorySelect.innerHTML = '<option value="">-- All Categories --</option>';

    const categories = [...new Set(allCatalogItems.map(item => item.category).filter(Boolean))];
    categories.sort().forEach(cat => {
        const opt = document.createElement("option");
        opt.value = cat;
        opt.textContent = cat;
        categorySelect.appendChild(opt);
    });

    onCategoryChange();
}

function onCategoryChange() {
    const selectedCat = document.getElementById("filter_category").value;
    const subCatSelect = document.getElementById("filter_sub_category");
    if (!subCatSelect) return;

    subCatSelect.innerHTML = '<option value="">-- All Sub Categories --</option>';

    const filteredItems = selectedCat 
        ? allCatalogItems.filter(item => item.category === selectedCat)
        : allCatalogItems;

    const subCategories = [...new Set(filteredItems.map(item => item.subCategory).filter(Boolean))];
    subCategories.sort().forEach(sub => {
        const opt = document.createElement("option");
        opt.value = sub;
        opt.textContent = sub;
        subCatSelect.appendChild(opt);
    });

    onSubCategoryChange();
}

function onSubCategoryChange() {
    const selectedCat = document.getElementById("filter_category").value;
    const selectedSub = document.getElementById("filter_sub_category").value;
    const itemSelect = document.getElementById("modal_item_id");
    if (!itemSelect) return;

    itemSelect.innerHTML = '<option value="">-- Select Item --</option>';

    let items = allCatalogItems;
    if (selectedCat) {
        items = items.filter(item => item.category === selectedCat);
    }
    if (selectedSub) {
        items = items.filter(item => item.subCategory === selectedSub);
    }

    items.forEach(item => {
        const opt = document.createElement("option");
        opt.value = item.id;
        opt.textContent = item.name + (item.uom ? " (" + item.uom + ")" : "");
        itemSelect.appendChild(opt);
    });
}

function addItemToStagingList() {
    const itemSelect = document.getElementById("modal_item_id");
    const qtyInput = document.getElementById("modal_quantity");
    const seqInput = document.getElementById("modal_sequence");

    const itemId = itemSelect.value;
    if (!itemId) {
        alert("Please select an item from the catalog.");
        return;
    }

    const itemObj = allCatalogItems.find(i => i.id === itemId);
    if (!itemObj) return;

    const quantity = parseFloat(qtyInput.value) || 1.0;
    const sequence = parseInt(seqInput.value) || (stagedItems.length + 1);

    stagedItems.push({
        id: itemId,
        name: itemObj.name,
        uom: itemObj.uom,
        quantity: quantity,
        sequence: sequence
    });

    // Auto-increment sequence for next item
    seqInput.value = sequence + 1;

    renderStagingTable();
}

function removeStagedItem(index) {
    stagedItems.splice(index, 1);
    renderStagingTable();
}

function updateStagedQuantity(index, val) {
    if (stagedItems[index]) {
        stagedItems[index].quantity = parseFloat(val) || 1.0;
    }
}

function updateStagedSequence(index, val) {
    if (stagedItems[index]) {
        stagedItems[index].sequence = parseInt(val) || 1;
    }
}

function renderStagingTable() {
    const tbody = document.getElementById("stagingTableBody");
    tbody.innerHTML = "";

    if (stagedItems.length === 0) {
        tbody.innerHTML = `
            <tr id="emptyStagingRow">
                <td colspan="4" style="text-align: center; color: #94a3b8; padding: 16px;">
                    No items added to list yet. Select an item above and click "+ Add to List".
                </td>
            </tr>`;
        return;
    }

    stagedItems.forEach((item, idx) => {
        const tr = document.createElement("tr");

        tr.innerHTML = 
            '<td>' +
                '<strong>' + escapeHtml(item.name) + '</strong>' +
                '<input type="hidden" name="item_id" value="' + item.id + '">' +
            '</td>' +
            '<td>' +
                '<input type="number" name="quantity" class="form-control" style="height: 30px; padding: 2px 6px;" value="' + item.quantity + '" min="0.01" step="0.01" onchange="updateStagedQuantity(' + idx + ', this.value)" required>' +
            '</td>' +
            '<td>' +
                '<input type="number" name="sequence_no" class="form-control" style="height: 30px; padding: 2px 6px;" value="' + item.sequence + '" min="1" step="1" onchange="updateStagedSequence(' + idx + ', this.value)" required>' +
            '</td>' +
            '<td style="text-align: center;">' +
                '<button type="button" class="btn-sm-danger" onclick="removeStagedItem(' + idx + ')">&times;</button>' +
            '</td>';

        tbody.appendChild(tr);
    });
}

function escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, "&amp;")
              .replace(/</g, "&lt;")
              .replace(/>/g, "&gt;")
              .replace(/"/g, "&quot;")
              .replace(/'/g, "&#039;");
}

function validateFormSubmit() {
    if (stagedItems.length === 0) {
        alert("Please add at least one item to the list before saving.");
        return false;
    }
    return true;
}

function openAddItemModal(menuId, title) {
    const menuInput = document.getElementById("modal_menu_id");
    const titleEl = document.getElementById("modalMenuTitle");
    const modal = document.getElementById("addItemModal");

    if (menuInput) menuInput.value = menuId;
    if (titleEl) titleEl.innerText = "Add Items: " + title;
    
    stagedItems = [];
    document.getElementById("modal_sequence").value = 1;
    renderStagingTable();
    initCategoryDropdowns();

    if (modal) modal.classList.add("active");
}

function closeAddItemModal() {
    const modal = document.getElementById("addItemModal");
    if (modal) modal.classList.remove("active");
}
</script>

</body>
</html>