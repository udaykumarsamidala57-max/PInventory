<%@page import="java.util.*"%>

<%
HttpSession sess = request.getSession(false);

if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String user = (String) sess.getAttribute("username");
String role = (String) sess.getAttribute("role");
String dept = (String) sess.getAttribute("department");

if ((!"Global".equalsIgnoreCase(role)
        && !"Finance".equalsIgnoreCase(dept))) {

    out.println(
    "<div style='display:flex;justify-content:center;align-items:center;height:60vh;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;'>" +
    "<div style='background:#fff;padding:40px;border-radius:8px;box-shadow:0 12px 30px rgba(0,0,0,0.05);border:1px solid #e1e6eb;text-align:center;max-width:400px;'>" +
    "<div style='background:#ffe8e8;color:#ea001e;width:48px;height:48px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24px;font-weight:bold;margin:0 auto 16px;'>!</div>" +
    "<h3 style='color:#180d0d;font-size:1.25rem;margin:0 0 8px 0;font-weight:700;'>Access Denied</h3>" +
    "<p style='color:#514f4d;font-size:0.875rem;margin:0;'>You don't have the necessary administrative privileges to view this asset domain.</p>" +
    "</div></div>");

    return;
}
%>

<%
ArrayList<HashMap<String,Object>> categories =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("categories");

ArrayList<HashMap<String,Object>> subcategories =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("subcategories");

ArrayList<HashMap<String,Object>> assets =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("assets");

ArrayList<HashMap<String,Object>> locations =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("locations");

String selectedCategory =
request.getParameter("category_id");

String selectedSubcategory =
request.getParameter("subcategory_id");

if(selectedCategory == null){
    selectedCategory = "";
}

if(selectedSubcategory == null){
    selectedSubcategory = "";
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Asset Location Management</title>

<style>
:root {
    --slds-c-brand: #0176d3;
    --slds-c-brand-hover: #014486;
    --slds-g-neutral-10: #f3f3f3;
    --slds-g-neutral-20: #e5e5e5;
    --slds-g-text-10: #181818;
    --slds-g-text-20: #444444;
    --slds-g-text-30: #747474;
    --border-radius-medium: 0.25rem;
    --border-radius-large: 0.5rem;
}

body {
    font-family: "Salesforce Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    margin: 0;
    padding: 0;
    background-color: white;
   	
    background-repeat: no-repeat;
    color: var(--slds-g-text-10);
    font-size: 0.8125rem;
    min-height: 100vh;
}

.slds-canvas {
    padding: 24px;
    max-width: 1440px;
    margin: 0 auto;
}

.slds-page-header {
    background: #fff;
    padding: 16px 24px;
    border: 1px solid var(--slds-g-neutral-20);
    border-radius: var(--border-radius-large);
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
    margin-bottom: 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.slds-page-header__title {
    font-size: 1.125rem;
    font-weight: 700;
    color: var(--slds-g-text-10);
    margin: 0;
    display: flex;
    align-items: center;
    gap: 12px;
}

.slds-icon-container {
    background: #ec7a08;
    width: 32px;
    height: 32px;
    border-radius: var(--border-radius-medium);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    font-weight: bold;
}

.slds-card {
    background: #fff;
    border: 1px solid var(--slds-g-neutral-20);
    border-radius: var(--border-radius-large);
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.05);
    margin-bottom: 16px;
    overflow: hidden;
}

.slds-card__header {
    padding: 16px 24px;
    background: var(--slds-g-neutral-10);
    border-bottom: 1px solid var(--slds-g-neutral-20);
    font-weight: 600;
    font-size: 0.875rem;
    color: var(--slds-g-text-20);
}

.filter-box {
    padding: 20px 24px;
    display: flex;
    gap: 20px;
    align-items: flex-end;
    flex-wrap: wrap;
    background: #fff;
}

.filter-group {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

label {
    font-size: 0.75rem;
    font-weight: 600;
    color: var(--slds-g-text-20);
}

select {
    padding: 0 12px;
    height: 32px;
    border: 1px solid var(--slds-g-neutral-20);
    border-radius: var(--border-radius-medium);
    font-family: inherit;
    font-size: 0.8125rem;
    background: #fff;
    color: var(--slds-g-text-10);
    min-width: 240px;
    transition: border-color 0.1s linear, box-shadow 0.1s linear;
}

select:focus {
    outline: none;
    border-color: var(--slds-c-brand);
    box-shadow: 0 0 3px #0176d3;
}

.table-container {
    overflow-x: auto;
}

table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.8125rem;
    text-align: left;
}

th, td {
    padding: 10px 16px;
    border-bottom: 1px solid var(--slds-g-neutral-20);
    vertical-align: middle;
}

th {
    background: var(--slds-g-neutral-10);
    font-size: 0.75rem;
    font-weight: 700;
    color: var(--slds-g-text-20);
    text-transform: uppercase;
    letter-spacing: 0.04em;
    height: 32px;
}

tr:hover td {
    background-color: #fafafafb;
}

.badge-unassigned {
    display: inline-block;
    padding: 2px 8px;
    font-size: 0.75rem;
    font-weight: 600;
    border-radius: var(--border-radius-medium);
    background: #fff0ea;
    color: #b05000;
    border: 1px solid #ffdecb;
}

.badge-assigned {
    color: var(--slds-g-text-10);
    font-weight: 500;
}

button {
    background: var(--slds-c-brand);
    color: #fff;
    border: 1px solid transparent;
    padding: 0 16px;
    height: 32px;
    border-radius: var(--border-radius-medium);
    cursor: pointer;
    font-size: 0.8125rem;
    font-weight: 600;
    transition: background 0.1s, color 0.1s;
}

button:hover {
    background: var(--slds-c-brand-hover);
}

.history-link {
    display: inline-block;
    margin-top: 4px;
    font-size: 0.75rem;
    color: var(--slds-c-brand);
    text-decoration: none;
    cursor: pointer;
    font-weight: 600;
}

.history-link:hover {
    text-decoration: underline;
    color: var(--slds-c-brand-hover);
}

/* MODAL STRUCTURE */
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(11, 23, 44, 0.6);
    display: none;
    align-items: center;
    justify-content: center;
    z-index: 9999;
}

.modal-content {
    background: #fff;
    width: 90%;
    max-width: 840px;
    max-height: 85vh;
    overflow-y: auto;
    border-radius: var(--border-radius-large);
    box-shadow: 0 12px 36px rgba(0, 0, 0, 0.2);
    border: 1px solid var(--slds-g-neutral-20);
    display: flex;
    flex-direction: column;
}

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px 24px;
    background: var(--slds-g-neutral-10);
    border-bottom: 1px solid var(--slds-g-neutral-20);
}

.modal-title {
    font-size: 1rem;
    font-weight: 700;
    margin: 0;
    color: var(--slds-g-text-10);
}

.modal-close {
    background: none;
    border: none;
    font-size: 20px;
    cursor: pointer;
    color: var(--slds-g-text-30);
    line-height: 1;
    padding: 4px;
}

.modal-close:hover {
    color: var(--slds-g-text-10);
}

.modal-body {
    padding: 20px 24px;
}

.form-inline-container {
    display: contents;
}

.location-select {
    width: 100%;
}
</style>

<script>
function loadSubcategories(){
    let category = document.getElementById("category").value;
    window.location = "AssetLocationController?action=load&category_id=" + encodeURIComponent(category);
}

function loadAssets(){
    let category = document.getElementById("category").value;
    let subcategory = document.getElementById("subcategory").value;
    window.location = "AssetLocationController?action=load&category_id=" + encodeURIComponent(category) + "&subcategory_id=" + encodeURIComponent(subcategory);
}

function filterLocationDropdowns(){
    let building = document.getElementById("buildingFilter").value;
    let dropdowns = document.querySelectorAll(".locationDropdown");

    dropdowns.forEach(function(select){
        let options = select.querySelectorAll("option");
        options.forEach(function(option){
            let optionBuilding = option.getAttribute("data-building");

            if(option.value == ""){
                option.hidden = false;
                return;
            }

            if(building == "All"){
                option.hidden = false;
            } else {
                if(optionBuilding && optionBuilding.toLowerCase() == building.toLowerCase()){
                    option.hidden = false;
                } else {
                    option.hidden = true;
                }
            }
        });

        if(select.selectedIndex >= 0){
            let selectedOption = select.options[select.selectedIndex];
            if(selectedOption.hidden){
                select.value = "";
            }
        }
    });
}

function viewHistory(assetId, assetCode){
    document.getElementById("modalAssetTitle").innerText = " - " + assetCode;
    let modal = document.getElementById("historyModal");
    let container = document.getElementById("historyDataContainer");

    container.innerHTML = "<tr><td colspan='5' style='text-align:center;padding:24px;color:var(--slds-g-text-30);'>Retrieving audit logs...</td></tr>";
    modal.style.display = "flex";

    fetch("AssetLocationController?action=history&asset_id=" + assetId)
    .then(response => response.json())
    .then(data => {
        if(data && data.length > 0){
            let html = "";
            data.forEach(row => {
                html += "<tr>" +
                "<td>" + (row.from_location || "<span class='badge-unassigned'>Initial Base</span>") + "</td>" +
                "<td><strong>" + (row.to_location || "") + "</strong></td>" +
                "<td>" + (row.moved_by || "") + "</td>" +
                "<td>" + (row.moved_datetime || "") + "</td>" +
                "<td>" + (row.remarks || "-") + "</td>" +
                "</tr>";
            });
            container.innerHTML = html;
        } else {
            container.innerHTML = "<tr><td colspan='5' style='text-align:center;padding:24px;color:var(--slds-g-text-30);'>No historical relocation vectors found.</td></tr>";
        }
    })
    .catch(error => {
        console.log(error);
        container.innerHTML = "<tr><td colspan='5' style='text-align:center;padding:24px;color:#ea001e;'>Error mapping transmission timeline.</td></tr>";
    });
}

function closeModal(){
    document.getElementById("historyModal").style.display = "none";
}

window.onclick = function(event){
    let modal = document.getElementById("historyModal");
    if(event.target == modal){
        modal.style.display = "none";
    }
}

window.onload = function(){
    filterLocationDropdowns();
}
</script>
</head>

<body>

<%@ include file="../header.jsp" %>

<div class="slds-canvas">

    <div class="slds-page-header">
        <div class="slds-page-header__title">
            <div class="slds-icon-container">A</div>
            <div>
                <span style="font-size:0.75rem;font-weight:normal;color:var(--slds-g-text-30);display:block;text-transform:uppercase;">Assets Pipeline</span>
                Assign / Change Asset Location
            </div>
        </div>
    </div>

    <div class="slds-card">
        <div class="slds-card__header">Filter Scope</div>
        <div class="filter-box">
            
            <div class="filter-group">
                <label>Category</label>
                <select id="category" onchange="loadSubcategories()">
                    <option value="">Select Category</option>
                    <% if(categories != null){ for(HashMap<String,Object> c : categories){ %>
                    <option value="<%=c.get("category_id")%>" <%=selectedCategory.equals(String.valueOf(c.get("category_id"))) ? "selected" : ""%>>
                        <%=c.get("category_name")%>
                    </option>
                    <% } } %>
                </select>
            </div>

            <div class="filter-group">
                <label>Subcategory</label>
                <select id="subcategory" onchange="loadAssets()">
                    <option value="">Select Subcategory</option>
                    <% if(subcategories != null){ for(HashMap<String,Object> s : subcategories){ %>
                    <option value="<%=s.get("subcategory_id")%>" <%=selectedSubcategory.equals(String.valueOf(s.get("subcategory_id"))) ? "selected" : ""%>>
                        <%=s.get("subcategory_name")%>
                    </option>
                    <% } } %>
                </select>
            </div>

            <div class="filter-group">
                <label>Building / Staff Filter</label>
                <select id="buildingFilter" onchange="filterLocationDropdowns()">
                    <option value="All">All Horizons</option>
                    <%
                    TreeSet<String> buildings = new TreeSet<String>();
                    if(locations != null){
                        for(HashMap<String,Object> l : locations){
                            if(l.get("building") != null){
                                buildings.add(l.get("building").toString());
                            }
                        }
                        for(String b : buildings){
                    %>
                    <option value="<%=b%>"><%=b%></option>
                    <% } } %>
                </select>
            </div>
        </div>
    </div>

    <div class="slds-card">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th style="width: 18%;">Asset Code</th>
                        <th style="width: 22%;">Asset Name</th>
                        <th style="width: 25%;">Current Assignment</th>
                        <th style="width: 35%;" colspan="2">Target Allocation</th>
                    </tr>
                </thead>
                <tbody>
                    <% if(assets != null && assets.size() > 0){ for(HashMap<String,Object> a : assets){ %>
                    <tr>
                        <td>
                            <strong style="color:var(--slds-c-brand); font-size:0.875rem;"><%=a.get("asset_code")%></strong>
                            <br>
                            <a class="history-link" onclick="viewHistory('<%=a.get("asset_id")%>', '<%=a.get("asset_code")%>')">
                                History
                            </a>
                        </td>
                        <td style="font-weight: 500; color: var(--slds-g-text-10);">
                            <%=a.get("asset_name")%>
                        </td>
                        <td>
                            <% if(a.get("current_location") == null){ %>
                            <span class="badge-unassigned">Unassigned</span>
                            <% } else { %>
                            <span class="badge-assigned"><%=a.get("current_location")%></span>
                            <% } %>
                        </td>
                        <td colspan="2" style="padding:0;">
                            <form action="AssetLocationController" method="post" class="form-inline-container">
                                <input type="hidden" name="asset_id" value="<%=a.get("asset_id")%>">
                                <input type="hidden" name="category_id" value="<%=selectedCategory%>">
                                <input type="hidden" name="subcategory_id" value="<%=selectedSubcategory%>">
                                <input type="hidden" name="action" value="assign">
                                
                                <table style="width:100%; border-collapse:collapse; margin:0; background:transparent;">
                                    <tr>
                                        <td style="border-bottom:0; padding:8px 16px; width:70%;">
                                            <select name="location_id" required class="locationDropdown location-select">
                                                <option value="">Select Target Location...</option>
                                                <% if(locations != null){ for(HashMap<String,Object> l : locations){ %>
                                                <option value="<%=l.get("location_id")%>" data-building="<%=l.get("building")%>">
                                                    <%=l.get("location_name")%> (<%=l.get("building")%>)
                                                </option>
                                                <% } } %>
                                            </select>
                                        </td>
                                        <td style="border-bottom:0; padding:8px 16px; width:30%; text-align:right;">
                                            <button type="submit">Reallocate</button>
                                        </td>
                                    </tr>
                                </table>
                            </form>
                        </td>
                    </tr>
                    <% } } else { %>
                    <tr>
                        <td colspan="5" style="text-align:center; padding:48px; color:var(--slds-g-text-30); font-size:0.875rem;">
                            No matching asset records resident in this vector.
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>
</div>

<div id="historyModal" class="modal-overlay">
    <div class="modal-content">
        <div class="modal-header">
            <h3 class="modal-title">
                Lifecycle Routing History <span id="modalAssetTitle"></span>
            </h3>
            <button class="modal-close" onclick="closeModal()">&times;</button>
        </div>
        <div class="modal-body">
            <div class="table-container" style="border: 1px solid var(--slds-g-neutral-20); border-radius: var(--border-radius-medium);">
                <table>
                    <thead>
                        <tr>
                            <th>Origin Domain</th>
                            <th>Destination Target</th>
                            <th>Transfered By</th>
                            <th>Timestamp</th>
                            <th>Operational Notes</th>
                        </tr>
                    </thead>
                    <tbody id="historyDataContainer">
                        </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

</body>
</html>