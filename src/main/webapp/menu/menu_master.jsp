<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List"%>
<%@ page import="java.util.Map"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="java.util.ArrayList"%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Menu Master - Day-Wise</title>
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

/* Page Header */
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

/* Toast Notifications */
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

/* Card Component */
.card {
    background: #ffffff;
    border: 1px solid #dddbda;
    border-radius: 4px;
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.03);
    margin-bottom: 12px;
}

.card-header {
    padding: 8px 12px;
    background: #f3f3f3;
    border-bottom: 1px solid #dddbda;
    font-size: 13px;
    font-weight: 700;
    color: #080707;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.card-body { padding: 12px; }

/* Form Grid */
.form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr 1.5fr 2fr auto;
    gap: 10px;
    align-items: end;
}

.form-group { min-width: 0; }
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

/* Buttons */
.btn {
    height: 32px;
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
.btn-success { background: #2e844a; border-color: #2e844a; color: #ffffff; }
.btn-success:hover { background: #1c522e; border-color: #1c522e; }
.btn-secondary { background: #ffffff; border-color: #dddbda; color: #444444; }
.btn-secondary:hover { background: #f3f3f3; border-color: #c9c7c5; }

.btn-sm-edit { 
    color: #0176d3; 
    background: #ffffff; 
    border: 1px solid #0176d3; 
    padding: 2px 8px; 
    font-size: 10px; 
    font-weight: 600;
    border-radius: 3px; 
    cursor: pointer; 
}
.btn-sm-edit:hover { background: #0176d3; color: #ffffff; }

.btn-sm-danger { 
    color: #ea001e; 
    background: #ffffff; 
    border: 1px solid #ea001e; 
    padding: 2px 8px; 
    font-size: 10px; 
    font-weight: 600;
    border-radius: 3px; 
    cursor: pointer; 
}
.btn-sm-danger:hover { background: #ea001e; color: #ffffff; }

/* Table Styling */
.table-wrapper { width: 100%; overflow-x: auto; }

.menu-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 12px;
}

.menu-table th {
    text-align: left;
    color: #444444;
    font-size: 10px;
    font-weight: 700;
    text-transform: uppercase;
    background: #f8f9fa;
    border-bottom: 2px solid #dddbda;
    padding: 6px 8px;
    white-space: nowrap;
}

.menu-table td {
    padding: 6px 8px;
    border-bottom: 1px solid #f3f3f3;
    vertical-align: middle;
}

.menu-table tr:hover td { background-color: #fafafa; }
.menu-table tr:last-child td { border-bottom: none; }

.session-badge {
    background: #0176d3;
    color: #ffffff;
    font-size: 10px;
    font-weight: 700;
    padding: 2px 6px;
    border-radius: 3px;
    text-transform: uppercase;
}

.status-active { color: #2e844a; font-weight: 700; font-size: 11px; }
.status-inactive { color: #ea001e; font-weight: 700; font-size: 11px; }

.day-header-badge {
    background: #0176d3;
    color: #ffffff;
    padding: 3px 8px;
    border-radius: 12px;
    font-size: 11px;
    font-weight: 700;
}

.actions { display: flex; gap: 4px; align-items: center; }
.empty { text-align: center; padding: 16px !important; color: #747474; }

@media (max-width: 900px) {
    .form-grid { grid-template-columns: 1fr 1fr; }
    .form-group:last-child { grid-column: 1 / -1; }
}

@media (max-width: 600px) {
    .form-grid { grid-template-columns: 1fr; }
    .form-group:last-child { grid-column: auto; }
}
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

    <!-- PAGE HEADER -->
    <div class="page-header">
        <div>
            <h1 class="page-title">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#0176d3" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3h18v18H3z"/><path d="M21 9H3"/><path d="M9 21V9"/></svg>
                Menu Master (Day-Wise View)
            </h1>
            <div class="page-subtitle">Manage daily menus organized by days of the week</div>
        </div>
    </div>

    <!-- TOAST NOTIFICATION -->
    <div id="toastContainer"></div>

    <!-- ADD / EDIT FORM CARD -->
    <div class="card">
        <div class="card-header" id="formCardHeader">Add Menu Item</div>

        <div class="card-body">
            <form id="menuForm" onsubmit="submitFormAjax(event)">
                <input type="hidden" name="action" id="form_action" value="save">
                <input type="hidden" name="menu_id" id="form_menu_id" value="">

                <div class="form-grid">
                    <!-- DAY -->
                    <div class="form-group">
                        <label class="form-label">Day</label>
                        <select name="day_of_week" id="form_day_of_week" class="form-control" required>
                            <option value="">Select Day</option>
                            <%
                                String[] daysList = {"MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"};
                                for (String day : daysList) {
                            %>
                                <option value="<%=day%>"><%=day%></option>
                            <% } %>
                        </select>
                    </div>

                    <!-- SESSION -->
                    <div class="form-group">
                        <label class="form-label">Session</label>
                        <select name="session" id="form_session" class="form-control" required>
                            <option value="">Select Session</option>
                            <option value="BREAKFAST">BREAKFAST</option>
                            <option value="LUNCH">LUNCH</option>
                            <option value="SNACKS">SNACKS</option>
                            <option value="DINNER">DINNER</option>
                        </select>
                    </div>

                    <!-- MENU NAME -->
                    <div class="form-group">
                        <label class="form-label">Menu Name</label>
                        <input type="text" name="menu_name" id="form_menu_name" class="form-control" placeholder="Eg: IDLY" maxlength="100" required>
                    </div>

                    <!-- REMARKS -->
                    <div class="form-group">
                        <label class="form-label">Remarks</label>
                        <input type="text" name="remarks" id="form_remarks" class="form-control" placeholder="Optional" maxlength="255">
                    </div>

                    <!-- BUTTON ACTIONS -->
                    <div class="form-group">
                        <div id="addBtnGroup">
                            <button type="submit" class="btn btn-primary" id="btnSubmitForm">+ Add Menu</button>
                        </div>
                        <div id="editBtnGroup" style="display: none; gap: 6px;">
                            <button type="submit" class="btn btn-success" id="btnUpdateForm">Update</button>
                            <button type="button" class="btn btn-secondary" onclick="resetFormState()">Cancel</button>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- DAY-WISE SEGREGATED TABLES -->
    <div id="dayWiseTablesContainer">
    <%
        List<Map<String,Object>> menus = (List<Map<String,Object>>) request.getAttribute("menus");
        
        // Group menus by day_of_week
        Map<String, List<Map<String,Object>>> dayWiseMap = new HashMap<>();
        for (String d : daysList) {
            dayWiseMap.put(d, new ArrayList<>());
        }

        if (menus != null) {
            for (Map<String,Object> menu : menus) {
                String dayVal = menu.get("day_of_week") != null ? menu.get("day_of_week").toString().toUpperCase() : "";
                if (dayWiseMap.containsKey(dayVal)) {
                    dayWiseMap.get(dayVal).add(menu);
                }
            }
        }

        for (String currentDay : daysList) {
            List<Map<String,Object>> dayMenus = dayWiseMap.get(currentDay);
    %>
        <div class="card" id="card-day-<%=currentDay%>">
            <div class="card-header">
                <span><%=currentDay%></span>
                <span class="day-header-badge"><%=dayMenus.size()%> Items</span>
            </div>
            <div class="card-body" style="padding: 0;">
                <div class="table-wrapper">
                    <table class="menu-table">
                        <thead>
                            <tr>
                                <th style="width: 50px;">ID</th>
                                <th style="width: 140px;">SESSION</th>
                                <th>MENU ITEM</th>
                                <th>REMARKS</th>
                                <th style="width: 80px;">STATUS</th>
                                <th style="width: 110px;">ACTION</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            if (!dayMenus.isEmpty()) {
                                for (Map<String,Object> menu : dayMenus) {
                                    Object id = menu.get("menu_id");
                                    Object sessionValue = menu.get("session");
                                    Object name = menu.get("menu_name");
                                    Object remark = menu.get("remarks");
                                    Object status = menu.get("active");

                                    int statusValue = status != null ? Integer.parseInt(status.toString()) : 0;
                                    String remarkStr = remark != null ? remark.toString() : "";
                        %>
                            <tr id="menu-row-<%=id%>">
                                <td style="color: #747474; font-weight: 600;"><%=id%></td>
                                <td><span class="session-badge"><%=sessionValue%></span></td>
                                <td><strong style="color: #080707;"><%=name%></strong></td>
                                <td><%=remarkStr%></td>
                                <td>
                                    <% if (statusValue == 1) { %>
                                        <span class="status-active">ACTIVE</span>
                                    <% } else { %>
                                        <span class="status-inactive">INACTIVE</span>
                                    <% } %>
                                </td>
                                <td>
                                    <div class="actions">
                                        <button type="button" class="btn-sm-edit" 
                                                onclick="populateEditForm('<%=id%>', '<%=currentDay%>', '<%=sessionValue%>', '<%=escapeJs(name != null ? name.toString() : "")%>', '<%=escapeJs(remarkStr)%>')">
                                            Edit
                                        </button>
                                        <button type="button" class="btn-sm-danger" 
                                                onclick="deleteMenuAjax('<%=id%>', this)">
                                            Delete
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        <%
                                }
                            } else {
                        %>
                            <tr>
                                <td colspan="6" class="empty">No menu items configured for <%=currentDay%>.</td>
                            </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    <% } %>
    </div>

</div>

<%!
    private String escapeJs(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\")
                    .replace("'", "\\'")
                    .replace("\"", "\\\"")
                    .replace("\r", "")
                    .replace("\n", " ");
    }
%>

<!-- CLIENT-SIDE SCRIPT -->
<script>
const servletUrl = "<%=request.getContextPath()%>/MenuMasterServlet";

function showToast(message, type = 'success') {
    const toast = document.getElementById("toastContainer");
    toast.className = 'message ' + type;
    toast.innerText = message;
    setTimeout(() => {
        toast.className = '';
        toast.innerText = '';
    }, 4000);
}

/* REFRESH TABLES VIA AJAX */
function reloadTableContent() {
    fetch(servletUrl, {
        headers: { 'X-Requested-With': 'XMLHttpRequest' }
    })
    .then(response => response.text())
    .then(htmlText => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(htmlText, "text/html");
        const newTablesContainer = doc.getElementById("dayWiseTablesContainer");
        if (newTablesContainer) {
            document.getElementById("dayWiseTablesContainer").innerHTML = newTablesContainer.innerHTML;
        }
    })
    .catch(err => console.error("Error refreshing tables:", err));
}

/* SAVE OR UPDATE MENU VIA AJAX */
function submitFormAjax(event) {
    event.preventDefault();

    const form = document.getElementById("menuForm");
    const formData = new FormData(form);
    const params = new URLSearchParams();

    for (const [key, value] of formData.entries()) {
        params.append(key, value);
    }

    const action = document.getElementById("form_action").value;
    const submitBtn = action === 'update' ? document.getElementById("btnUpdateForm") : document.getElementById("btnSubmitForm");
    
    submitBtn.disabled = true;

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
        showToast(action === 'update' ? "Menu updated successfully." : "Menu added successfully.", "success");
        resetFormState();
        reloadTableContent();
    })
    .catch(err => {
        console.error("Form Submit Error:", err);
        showToast("Could not save menu record. Please try again.", "error");
    })
    .finally(() => {
        submitBtn.disabled = false;
    });
}

/* DELETE MENU VIA AJAX */
function deleteMenuAjax(menuId, btnElement) {
    if (!confirm('Are you sure you want to delete this menu item?')) return;

    const params = new URLSearchParams();
    params.append("action", "delete");
    params.append("menu_id", menuId);

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
        
        showToast("Menu deleted successfully.", "success");
        reloadTableContent();
        if (document.getElementById("form_menu_id").value === menuId) {
            resetFormState();
        }
    })
    .catch(err => {
        console.error("Delete Error:", err);
        showToast("Could not delete menu record. Please try again.", "error");
    });
}

/* POPULATE EDIT FORM */
function populateEditForm(id, day, sessionValue, name, remarks) {
    document.getElementById("formCardHeader").innerText = "Edit Menu Item";
    document.getElementById("form_action").value = "update";
    document.getElementById("form_menu_id").value = id;
    document.getElementById("form_day_of_week").value = day;
    document.getElementById("form_session").value = sessionValue;
    document.getElementById("form_menu_name").value = name;
    document.getElementById("form_remarks").value = remarks;

    document.getElementById("addBtnGroup").style.display = "none";
    document.getElementById("editBtnGroup").style.display = "flex";

    window.scrollTo({ top: 0, behavior: 'smooth' });
}

/* RESET FORM */
function resetFormState() {
    document.getElementById("formCardHeader").innerText = "Add Menu Item";
    document.getElementById("form_action").value = "save";
    document.getElementById("form_menu_id").value = "";
    document.getElementById("menuForm").reset();

    document.getElementById("addBtnGroup").style.display = "block";
    document.getElementById("editBtnGroup").style.display = "none";
}
</script>

</body>
</html>