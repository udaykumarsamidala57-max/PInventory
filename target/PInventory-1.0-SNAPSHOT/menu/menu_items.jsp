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
    background-color: #afb8c11a;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    color: #181818;
    line-height: 1.35;
    font-size: 12px;
}

.container {
    max-width: 1360px;
    margin: 0 auto;
    padding: 12px;
}

/* Salesforce SLDS Page Header */
.page-header {
    background: #ffffff;
    border: 1px solid #dddbda;
    border-radius: 4px;
    padding: 10px 16px;
    margin-bottom: 10px;
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.03);
}

.page-title { margin: 0; font-size: 16px; font-weight: 700; color: #080707; display: flex; align-items: center; gap: 8px; }
.page-subtitle { margin-top: 2px; color: #444444; font-size: 11px; }

/* Day Filter Navigation Tabs */
.day-tabs {
    display: flex;
    gap: 4px;
    margin-bottom: 10px;
    background: #eef4fe;
    padding: 3px;
    border: 1px solid #dddbda;
    border-radius: 4px;
    overflow-x: auto;
}

.day-tab {
    background: transparent;
    border: none;
    color: #444444;
    padding: 6px 14px;
    border-radius: 3px;
    font-size: 11px;
    font-weight: 600;
    cursor: pointer;
    text-decoration: none;
    transition: all 0.1s ease;
    white-space: nowrap;
    text-transform: uppercase;
    letter-spacing: 0.3px;
}

.day-tab:hover { background: rgba(255,255,255,0.7); color: #0176d3; }
.day-tab.active {
    background: #0176d3;
    border-color: #0176d3;
    color: #ffffff;
    box-shadow: 0 1px 2px rgba(0,0,0,0.12);
}

/* Dynamic Toast Notification Area */
#toastContainer {
    display: none;
    padding: 8px 12px;
    border-radius: 4px;
    margin-bottom: 10px;
    font-size: 12px;
    font-weight: 600;
}
#toastContainer.success { background: #eaf5ea; border: 1px solid #2e844a; color: #2e844a; display: block; }
#toastContainer.error { background: #fef0f0; border: 1px solid #ea001e; color: #ea001e; display: block; }

/* Grid Layout */
.menu-cards-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
    gap: 10px;
}

/* Salesforce SLDS Cards */
.menu-card {
    background: #ffffff;
    border: 1px solid #dddbda;
    border-radius: 4px;
    box-shadow: 0 2px 2px 0 rgba(0,0,0,0.03);
    display: flex;
    flex-direction: column;
    overflow: hidden;
}

.menu-card-header {
    padding: 8px 12px;
    background: #f3f3f3;
    border-bottom: 1px solid #dddbda;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.menu-title { font-weight: 700; color: #080707; font-size: 13px; }
.session-tag {
    background: #0176d3;
    color: #ffffff;
    font-size: 10px;
    font-weight: 700;
    padding: 2px 6px;
    border-radius: 3px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.menu-card-body { padding: 8px 12px; flex: 1; min-height: 120px; }

/* Dense Table Formatting */
.item-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 12px;
}

.item-table th {
    text-align: left;
    color: #444444;
    font-size: 10px;
    font-weight: 700;
    text-transform: uppercase;
    border-bottom: 2px solid #dddbda;
    padding: 4px 6px;
}

.item-table td {
    padding: 6px;
    border-bottom: 1px solid #f3f3f3;
    vertical-align: middle;
}

.item-table tr:hover td { background-color: #fafafa; }
.item-table tr:last-child td { border-bottom: none; }

.item-category-tag {
    display: inline-block;
    font-size: 10px;
    color: #747474;
}

/* SLDS Buttons */
.btn {
    height: 30px;
    border: 1px solid #dddbda;
    border-radius: 4px;
    padding: 0 12px;
    font-size: 11px;
    font-weight: 600;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 4px;
    text-decoration: none;
    transition: all 0.1s ease;
}

.btn-primary { background: #0176d3; border-color: #0176d3; color: #ffffff; }
.btn-primary:hover { background: #014486; border-color: #014486; }
.btn-secondary { background: #ffffff; border-color: #dddbda; color: #0176d3; }
.btn-secondary:hover { background: #f3f3f3; border-color: #c9c7c5; }
.btn-sm-danger { 
    color: #ea001e; 
    background: #ffffff; 
    border: 1px solid #ea001e; 
    padding: 2px 8px; 
    font-size: 10px; 
    font-weight: 600;
    border-radius: 3px; 
    cursor: pointer; 
    transition: all 0.1s;
}
.btn-sm-danger:hover { background: #ea001e; color: #ffffff; }

/* Compact Modal Styles */
.modal-overlay {
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(11, 26, 51, 0.6);
    display: none;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    backdrop-filter: blur(1px);
}

.modal-overlay.active { display: flex; }

.modal {
    background: #ffffff;
    border-radius: 4px;
    width: 100%;
    max-width: 640px;
    padding: 16px;
    box-shadow: 0 8px 18px 0 rgba(0, 0, 0, 0.16);
    border: 1px solid #dddbda;
}

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-bottom: 8px;
    margin-bottom: 12px;
    border-bottom: 1px solid #dddbda;
}

.modal-title { font-size: 14px; font-weight: 700; color: #080707; }

.form-group { margin-bottom: 8px; }
.form-label { display: block; font-size: 10px; font-weight: 700; color: #444444; margin-bottom: 3px; text-transform: uppercase; letter-spacing: 0.5px; }
.form-control {
    width: 100%;
    height: 32px;
    border: 1px solid #dddbda;
    border-radius: 4px;
    padding: 0 8px;
    font-size: 12px;
    background: #ffffff;
    color: #181818;
}
.form-control:focus { outline: none; border-color: #0176d3; box-shadow: 0 0 0 1px #0176d3; }

.staging-table-container {
    max-height: 180px;
    overflow-y: auto;
    border: 1px solid #dddbda;
    border-radius: 4px;
    margin-top: 10px;
    background: #ffffff;
}

.staging-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 12px;
}

.staging-table th {
    background: #f3f3f3;
    padding: 6px 8px;
    text-align: left;
    font-size: 10px;
    font-weight: 700;
    color: #444444;
    text-transform: uppercase;
    border-bottom: 1px solid #dddbda;
}

.staging-table td {
    padding: 4px 8px;
    border-bottom: 1px solid #f3f3f3;
}

.modal-actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 14px; padding-top: 10px; border-top: 1px solid #dddbda; }
</style>
</head>

<body>
<%@ include file="../header.jsp" %>
<div style="display: flex; justify-content: center; align-items: center; gap: 12px; margin: 12px 0;">
    <a href="MenuMasterServlet" 
       style="display: inline-flex; align-items: center; gap: 6px; padding: 6px 14px; background-color: #ffffff; color: #0176d3; border: 1px solid #dddbda; border-radius: 4px; text-decoration: none; font-family: 'Inter', -apple-system, sans-serif; font-size: 12px; font-weight: 600; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05); transition: all 0.15s ease;" 
       onmouseover="this.style.backgroundColor='#f3f3f3'; this.style.borderColor='#0176d3';" 
       onmouseout="this.style.backgroundColor='#ffffff'; this.style.borderColor='#dddbda';">
        <i class="fa-solid fa-square-plus" style="color: #2e844a; font-size: 14px;"></i>
        <span>Day Wise Menu</span>
    </a>

    <a href="MenuItemsServlet" 
       style="display: inline-flex; align-items: center; gap: 6px; padding: 6px 14px; background-color: #ffffff; color: #0176d3; border: 1px solid #dddbda; border-radius: 4px; text-decoration: none; font-family: 'Inter', -apple-system, sans-serif; font-size: 12px; font-weight: 600; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05); transition: all 0.15s ease;" 
       onmouseover="this.style.backgroundColor='#f3f3f3'; this.style.borderColor='#0176d3';" 
       onmouseout="this.style.backgroundColor='#ffffff'; this.style.borderColor='#dddbda';">
        <i class="fa-solid fa-square-plus" style="color: #2e844a; font-size: 14px;"></i>
        <span>Menu Items</span>
    </a>
</div>
<div class="container">

    <div class="page-header">
        <h1 class="page-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#0176d3" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3h18v18H3z"/><path d="M21 9H3"/><path d="M9 21V9"/></svg>
            Menu Configurations
        </h1>
        <div class="page-subtitle">Filter menus by day and configure portioned items using category dynamic filters</div>
    </div>

    <!-- TOAST ALERT CONTAINER FOR AJAX FEEDBACK -->
    <div id="toastContainer"></div>

    <%
        String activeDay = request.getParameter("day");
        if (activeDay == null || activeDay.trim().isEmpty()) {
            activeDay = "MONDAY";
        }
        String[] days = {"MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"};
    %>

    <!-- DAY TABS (AJAX SWITCH) -->
    <div class="day-tabs">
        <% for (String day : days) { %>
            <button type="button" 
                    onclick="switchDayAjax('<%=day%>')" 
                    id="tab-<%=day%>" 
                    class="day-tab <%=day.equalsIgnoreCase(activeDay) ? "active" : ""%>">
               <%=day%>
            </button>
        <% } %>
    </div>

    <!-- CARDS GRID CONTAINER -->
    <div class="menu-cards-grid" id="menuCardsGrid">
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
            <div class="menu-card" id="menu-card-<%=menuId%>">
                <div class="menu-card-header">
                    <div class="menu-title"><%=menuName%></div>
                    <span class="session-tag"><%=sessionName%></span>
                </div>

                <div class="menu-card-body">
                    <table class="item-table">
                        <thead>
                            <tr>
                                <th style="width: 32px;">Seq</th>
                                <th>Item details</th>
                                <th style="text-align: right; width: 60px;">Qty</th>
                                <th style="text-align: right; width: 60px;">Action</th>
                            </tr>
                        </thead>
                        <tbody id="menu-body-<%=menuId%>">
                        <%
                            boolean hasItems = false;
                            if (menuItems != null) {
                                for (Map<String,Object> row : menuItems) {
                                    int itemMenuId = Integer.parseInt(String.valueOf(row.get("menu_id")));
                                    if (itemMenuId == menuId) {
                                        hasItems = true;
                        %>
                            <tr id="item-row-<%=row.get("menu_item_id")%>">
                                <td style="color: #747474; font-weight: 600;"><%=row.get("sequence_no")%></td>
                                <td>
                                    <strong style="color: #080707;"><%=row.get("item_name")%></strong><br>
                                    <span class="item-category-tag">
                                        <%=row.get("category")%>
                                        <% if (row.get("sub_category") != null && !String.valueOf(row.get("sub_category")).trim().isEmpty()) { %>
                                            / <%=row.get("sub_category")%>
                                        <% } %>
                                    </span>
                                </td>
                                <td style="text-align: right; font-weight: 600;">
                                    <%=row.get("quantity")%> <span style="font-size: 10px; color: #747474;"><%=row.get("uom") != null ? row.get("uom") : ""%></span>
                                </td>
                                <td style="text-align: right;">
                                    <button type="button" 
                                            class="btn-sm-danger" 
                                            onclick="deleteMenuItemAjax('<%=row.get("menu_item_id")%>', '<%=activeDay%>', this)">
                                        Remove
                                    </button>
                                </td>
                            </tr>
                        <%
                                    }
                                }
                            }
                            if (!hasItems) {
                        %>
                            <tr class="no-items-row">
                                <td colspan="4" style="text-align: center; color: #747474; padding: 16px 0;">
                                    No items configured for this menu.
                                </td>
                            </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>

                <div style="padding: 8px 12px; background: #f3f3f3; border-top: 1px solid #dddbda; text-align: right;">
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
            <div style="grid-column: 1 / -1; background: #ffffff; border: 1px solid #dddbda; border-radius: 4px; padding: 32px; text-align: center; color: #444444;">
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
            <button type="button" onclick="closeAddItemModal()" style="border:none; background:none; cursor:pointer; font-size:20px; color:#747474; line-height: 1;">&times;</button>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
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

        <div style="display: flex; gap: 8px; align-items: flex-end;">
            <div class="form-group" style="flex: 1;">
                <label class="form-label">Quantity</label>
                <input type="number" id="modal_quantity" class="form-control" value="1.00" min="0.01" step="0.01">
            </div>

            <div class="form-group" style="flex: 1;">
                <label class="form-label">Sequence No.</label>
                <input type="number" id="modal_sequence" class="form-control" value="1" min="1" step="1">
            </div>

            <div class="form-group">
                <button type="button" class="btn btn-secondary" onclick="addItemToStagingList()" style="height:32px;">+ Add to List</button>
            </div>
        </div>

        <!-- FORM NOW HANDLED BY AJAX -->
        <form id="multiItemForm" onsubmit="submitStagingFormAjax(event)">
            <input type="hidden" name="action" value="save">
            <input type="hidden" name="menu_id" id="modal_menu_id">
            <input type="hidden" name="day" id="modal_active_day" value="<%=activeDay%>">

            <!-- STAGING TABLE FOR MULTIPLE ITEMS -->
            <div class="staging-table-container">
                <table class="staging-table">
                    <thead>
                        <tr>
                            <th>Item Name</th>
                            <th style="width: 70px;">Qty</th>
                            <th style="width: 70px;">Seq</th>
                            <th style="width: 45px; text-align: center;">Action</th>
                        </tr>
                    </thead>
                    <tbody id="stagingTableBody">
                        <tr id="emptyStagingRow">
                            <td colspan="4" style="text-align: center; color: #747474; padding: 12px;">
                                No items added to list yet. Select an item above and click "+ Add to List".
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div class="modal-actions">
                <button type="button" class="btn btn-secondary" onclick="closeAddItemModal()">Cancel</button>
                <button type="submit" class="btn btn-primary" id="btnSaveStagedItems">Save All Items</button>
            </div>
        </form>
    </div>
</div>

<!-- CLIENT-SIDE SCRIPT -->
<script>
const servletUrl = "<%=request.getContextPath()%>/MenuItemsServlet";
let currentActiveDay = "<%=activeDay%>";

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

function showToast(message, type = 'success') {
    const toast = document.getElementById("toastContainer");
    toast.className = 'message ' + type;
    toast.innerText = message;
    setTimeout(() => {
        toast.className = '';
        toast.innerText = '';
    }, 4000);
}

/* AJAX 1: SWITCH DAY WITHOUT PAGE RELOAD */
function switchDayAjax(day) {
    currentActiveDay = day;
    document.getElementById("modal_active_day").value = day;

    document.querySelectorAll(".day-tab").forEach(tab => tab.classList.remove("active"));
    const activeTab = document.getElementById("tab-" + day);
    if (activeTab) activeTab.classList.add("active");

    fetch(servletUrl + "?day=" + encodeURIComponent(day), {
        headers: { 'X-Requested-With': 'XMLHttpRequest' }
    })
    .then(response => response.text())
    .then(htmlText => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(htmlText, "text/html");
        const newGrid = doc.getElementById("menuCardsGrid");
        if (newGrid) {
            document.getElementById("menuCardsGrid").innerHTML = newGrid.innerHTML;
        }
    })
    .catch(err => {
        console.error("Failed to load day data:", err);
        showToast("Error switching active day view.", "error");
    });
}

/* AJAX 2: DELETE MENU ITEM WITHOUT RELOAD */
function deleteMenuItemAjax(menuItemId, day, btnElement) {
    if (!confirm('Remove this item?')) return;

    const params = new URLSearchParams();
    params.append("action", "delete");
    params.append("menu_item_id", menuItemId);
    params.append("day", day);

    fetch(servletUrl, {
        method: "POST",
        headers: { 
            "Content-Type": "application/x-www-form-urlencoded",
            "X-Requested-With": "XMLHttpRequest"
        },
        body: params.toString()
    })
    .then(response => {
        if (!response.ok) throw new Error("Delete request failed");
        
        const row = document.getElementById("item-row-" + menuItemId);
        if (row) {
            const tbody = row.closest("tbody");
            row.remove();
            
            if (tbody && tbody.querySelectorAll("tr").length === 0) {
                tbody.innerHTML = `
                    <tr class="no-items-row">
                        <td colspan="4" style="text-align: center; color: #747474; padding: 16px 0;">
                            No items configured for this menu.
                        </td>
                    </tr>`;
            }
        }
        showToast("Item removed successfully.", "success");
    })
    .catch(err => {
        console.error("Delete Error:", err);
        showToast("Could not remove item. Please try again.", "error");
    });
}

/* AJAX 3: SAVE STAGED ITEMS WITHOUT RELOAD */
function submitStagingFormAjax(event) {
    event.preventDefault();

    if (!validateFormSubmit()) return;

    const form = document.getElementById("multiItemForm");
    const formData = new FormData(form);
    const params = new URLSearchParams();

    for (const [key, value] of formData.entries()) {
        params.append(key, value);
    }

    const saveBtn = document.getElementById("btnSaveStagedItems");
    saveBtn.disabled = true;
    saveBtn.innerText = "Saving...";

    fetch(servletUrl, {
        method: "POST",
        headers: { 
            "Content-Type": "application/x-www-form-urlencoded",
            "X-Requested-With": "XMLHttpRequest"
        },
        body: params.toString()
    })
    .then(response => {
        if (!response.ok) throw new Error("Save request failed");
        closeAddItemModal();
        showToast("Menu items updated successfully.", "success");
        switchDayAjax(currentActiveDay);
    })
    .catch(err => {
        console.error("Save Error:", err);
        showToast("Failed to save menu items.", "error");
    })
    .finally(() => {
        saveBtn.disabled = false;
        saveBtn.innerText = "Save All Items";
    });
}

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
                <td colspan="4" style="text-align: center; color: #747474; padding: 12px;">
                    No items added to list yet. Select an item above and click "+ Add to List".
                </td>
            </tr>`;
        return;
    }

    stagedItems.forEach((item, idx) => {
        const tr = document.createElement("tr");

        tr.innerHTML = 
            '<td>' +
                '<strong style="color:#080707;">' + escapeHtml(item.name) + '</strong>' +
                '<input type="hidden" name="item_id" value="' + item.id + '">' +
            '</td>' +
            '<td>' +
                '<input type="number" name="quantity" class="form-control" style="height: 26px; padding: 2px 4px; font-size:11px;" value="' + item.quantity + '" min="0.01" step="0.01" oninput="updateStagedQuantity(' + idx + ', this.value)" required>' +
            '</td>' +
            '<td>' +
                '<input type="number" name="sequence_no" class="form-control" style="height: 26px; padding: 2px 4px; font-size:11px;" value="' + item.sequence + '" min="1" step="1" oninput="updateStagedSequence(' + idx + ', this.value)" required>' +
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
    const itemInputs = document.querySelectorAll('#stagingTableBody input[name="item_id"]');
    if (!itemInputs || itemInputs.length === 0) {
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