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
    "<h3 style='color:#ef4444;text-align:center;font-family:sans-serif;margin-top:40px;'>Access Denied! You are not authorized.</h3>");

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
<html>
<head>

<meta charset="UTF-8">

<title>Asset Location</title>

<style>

:root {
    --primary: #2563eb;
    --primary-hover: #1d4ed8;
    --bg-main: #f8fafc;
    --bg-card: #ffffff;
    --border: #e2e8f0;
    --text-main: #0f172a;
    --text-muted: #64748b;
}

body {
    font-family: -apple-system,
    BlinkMacSystemFont,
    "Segoe UI",
    Roboto,
    Helvetica,
    Arial,
    sans-serif;

    margin: 0;
    padding: 32px;

    background-color: var(--bg-main);

    color: var(--text-main);

    line-height: 1.5;
}

h2 {
    margin-top: 0;
    margin-bottom: 24px;

    font-size: 1.5rem;
    font-weight: 700;

    letter-spacing: -0.02em;
}

.filter-box {

    background: var(--bg-card);

    border: 1px solid var(--border);

    border-radius: 12px;

    padding: 24px;

    margin-bottom: 24px;

    box-shadow:
    0 4px 6px -1px
    rgb(0 0 0 / 0.05);

    display: flex;

    gap: 24px;

    align-items: center;

    flex-wrap: wrap;
}

.filter-group {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

label {

    font-size: 13px;

    font-weight: 600;

    color: var(--text-muted);
}

select {

    padding: 10px 14px;

    border: 1px solid var(--border);

    border-radius: 8px;

    font-family: inherit;

    font-size: 14px;

    background: #fff;

    min-width: 220px;
}

select:focus {

    outline: none;

    border-color: var(--primary);

    box-shadow:
    0 0 0 3px
    rgba(37,99,235,0.15);
}

.table-container {

    overflow-x: auto;

    border: 1px solid var(--border);

    border-radius: 12px;

    background: #fff;

    box-shadow:
    0 4px 6px -1px
    rgb(0 0 0 / 0.05);
}

table {

    width: 100%;

    border-collapse: collapse;

    font-size: 14px;
}

th,
td {

    padding: 14px 20px;

    border-bottom:
    1px solid var(--border);
}

th {

    background: #f8fafc;

    font-size: 13px;

    font-weight: 600;

    color: var(--text-muted);

    text-transform: uppercase;
}

tr:last-child td {
    border-bottom: 0;
}

tr:hover {
    background: #fdfdfd;
}

.badge-unassigned {

    display: inline-block;

    padding: 2px 8px;

    font-size: 12px;

    border-radius: 6px;

    background: #f1f5f9;

    color: var(--text-muted);
}

button {

    background: var(--primary);

    color: #fff;

    border: 0;

    padding: 8px 16px;

    border-radius: 6px;

    cursor: pointer;

    font-size: 13px;

    font-weight: 600;
}

button:hover {
    background: var(--primary-hover);
}

.history-link {

    display: inline-block;

    margin-top: 4px;

    font-size: 11px;

    color: var(--primary);

    text-decoration: none;

    cursor: pointer;
}

.history-link:hover {
    text-decoration: underline;
}

.modal-overlay {

    position: fixed;

    top: 0;
    left: 0;

    width: 100%;
    height: 100%;

    background:
    rgba(15,23,42,0.4);

    backdrop-filter: blur(4px);

    display: none;

    align-items: center;

    justify-content: center;

    z-index: 9999;
}

.modal-content {

    background: #fff;

    width: 90%;
    max-width: 750px;

    max-height: 80vh;

    overflow-y: auto;

    border-radius: 12px;

    padding: 28px;

    border: 1px solid var(--border);
}

.modal-header {

    display: flex;

    justify-content: space-between;

    align-items: center;

    margin-bottom: 20px;

    padding-bottom: 12px;

    border-bottom:
    1px solid var(--border);
}

.modal-title {

    font-size: 1.2rem;

    font-weight: 700;

    margin: 0;
}

.modal-close {

    background: none;

    border: none;

    font-size: 24px;

    cursor: pointer;

    color: var(--text-muted);
}

.modal-close:hover {
    color: var(--text-main);
}

.form-inline-container {
    display: contents;
}

.location-select{
    width:100%;
}

</style>

<script>

/* CATEGORY */

function loadSubcategories(){

    let category =
    document.getElementById(
    "category").value;

    window.location =
    "AssetLocationController?action=load&category_id="
    + encodeURIComponent(category);
}

/* SUBCATEGORY */

function loadAssets(){

    let category =
    document.getElementById(
    "category").value;

    let subcategory =
    document.getElementById(
    "subcategory").value;

    window.location =
    "AssetLocationController?action=load&category_id="
    + encodeURIComponent(category)
    + "&subcategory_id="
    + encodeURIComponent(subcategory);
}

/* BUILDING FILTER */

function filterLocationDropdowns(){

    let building =
    document.getElementById(
    "buildingFilter").value;

    let dropdowns =
    document.querySelectorAll(
    ".locationDropdown");

    dropdowns.forEach(function(select){

        let options =
        select.querySelectorAll("option");

        options.forEach(function(option){

            let optionBuilding =
            option.getAttribute(
            "data-building");

            /* Select Location option */

            if(option.value == ""){

                option.hidden = false;
                return;
            }

            /* Show All */

            if(building == "All"){

                option.hidden = false;
            }

            /* Filter by Building */

            else{

                if(optionBuilding &&
                   optionBuilding.toLowerCase()
                   ==
                   building.toLowerCase()){

                    option.hidden = false;

                } else {

                    option.hidden = true;
                }
            }
        });

        /* Reset invalid selected value */

        if(select.selectedIndex >= 0){

            let selectedOption =
            select.options[
            select.selectedIndex];

            if(selectedOption.hidden){

                select.value = "";
            }
        }
    });
}

/* HISTORY */

function viewHistory(assetId, assetCode){

    document.getElementById(
    "modalAssetTitle").innerText =
    assetCode;

    let modal =
    document.getElementById(
    "historyModal");

    let container =
    document.getElementById(
    "historyDataContainer");

    container.innerHTML =
    "<tr><td colspan='5' style='text-align:center;padding:20px;'>Loading...</td></tr>";

    modal.style.display = "flex";

    fetch(
    "AssetLocationController?action=history&asset_id="
    + assetId)

    .then(response => response.json())

    .then(data => {

        if(data && data.length > 0){

            let html = "";

            data.forEach(row => {

                html +=
                "<tr>" +

                "<td>" +
                (row.from_location ||
                "<span class='badge-unassigned'>Initial Base</span>")
                +
                "</td>" +

                "<td><strong>" +
                (row.to_location || "")
                +
                "</strong></td>" +

                "<td>" +
                (row.moved_by || "")
                +
                "</td>" +

                "<td>" +
                (row.moved_datetime || "")
                +
                "</td>" +

                "<td>" +
                (row.remarks || "-")
                +
                "</td>" +

                "</tr>";
            });

            container.innerHTML = html;

        } else {

            container.innerHTML =
            "<tr><td colspan='5' style='text-align:center;padding:20px;'>No History Found</td></tr>";
        }
    })

    .catch(error => {

        console.log(error);

        container.innerHTML =
        "<tr><td colspan='5' style='text-align:center;padding:20px;color:red;'>Error Loading History</td></tr>";
    });
}

function closeModal(){

    document.getElementById(
    "historyModal").style.display =
    "none";
}

window.onclick = function(event){

    let modal =
    document.getElementById(
    "historyModal");

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

<h2>Assign / Change Asset Location</h2>

<div class="filter-box">

    <!-- CATEGORY -->

    <div class="filter-group">

        <label>Category </label>

        <select id="category"
        onchange="loadSubcategories()">

            <option value="">
            Select Category
            </option>

            <%
            if(categories != null){

                for(HashMap<String,Object> c : categories){
            %>

            <option
            value="<%=c.get("category_id")%>"

            <%=selectedCategory.equals(
            String.valueOf(
            c.get("category_id")))
            ? "selected" : ""%>>

                <%=c.get("category_name")%>

            </option>

            <%
                }
            }
            %>

        </select>

    </div>

    <!-- SUBCATEGORY -->

    <div class="filter-group">

        <label>Subcategory </label>

        <select id="subcategory"
        onchange="loadAssets()">

            <option value="">
            Select Subcategory
            </option>

            <%
            if(subcategories != null){

                for(HashMap<String,Object> s : subcategories){
            %>

            <option
            value="<%=s.get("subcategory_id")%>"

            <%=selectedSubcategory.equals(
            String.valueOf(
            s.get("subcategory_id")))
            ? "selected" : ""%>>

                <%=s.get("subcategory_name")%>

            </option>

            <%
                }
            }
            %>

        </select>

    </div>

    <!-- BUILDING FILTER -->

    <div class="filter-group">

        <label>Building / Staff Filter</label>

        <select id="buildingFilter"
        onchange="filterLocationDropdowns()">

            <option value="All">
            All
            </option>

            <%
            TreeSet<String> buildings =
            new TreeSet<String>();

            if(locations != null){

                for(HashMap<String,Object> l : locations){

                    if(l.get("building") != null){

                        buildings.add(
                        l.get("building").toString());
                    }
                }

                for(String b : buildings){
            %>

            <option value="<%=b%>">
                <%=b%>
            </option>

            <%
                }
            }
            %>

        </select>

    </div>

</div>

<div class="table-container">

<table>

<thead>

<tr>

<th>Asset Code</th>
<th>Asset Name</th>
<th>Current Location</th>
<th>New Location</th>
<th>Action</th>

</tr>

</thead>

<tbody>

<%
if(assets != null && assets.size() > 0){

    for(HashMap<String,Object> a : assets){
%>

<tr>

<td>

<strong>
<%=a.get("asset_code")%>
</strong>

<br>

<a class="history-link"
onclick="viewHistory(
'<%=a.get("asset_id")%>',
'<%=a.get("asset_code")%>')">

History

</a>

</td>

<td>
<%=a.get("asset_name")%>
</td>

<td>

<%
if(a.get("current_location") == null){
%>

<span class="badge-unassigned">
Not Assigned
</span>

<%
} else {
%>

<%=a.get("current_location")%>

<%
}
%>

</td>

<td colspan="2" style="padding:0;">

<form
action="AssetLocationController"
method="post"
class="form-inline-container">

<input type="hidden"
name="asset_id"
value="<%=a.get("asset_id")%>">

<input type="hidden"
name="category_id"
value="<%=selectedCategory%>">

<input type="hidden"
name="subcategory_id"
value="<%=selectedSubcategory%>">

<input type="hidden"
name="action"
value="assign">

<table
style="width:100%;
border-collapse:collapse;
margin:0;">

<tr>

<td
style="border-bottom:0;
padding:14px 20px;
width:70%;">

<select
name="location_id"
required
class="locationDropdown location-select">

<option value="">
Select Location
</option>

<%
if(locations != null){

    for(HashMap<String,Object> l : locations){
%>

<option
value="<%=l.get("location_id")%>"

data-building=
"<%=l.get("building")%>">

<%=l.get("location_name")%>
-
<%=l.get("building")%>

</option>

<%
    }
}
%>

</select>

</td>

<td
style="border-bottom:0;
padding:14px 20px;
width:30%;">

<button type="submit">
Assign
</button>

</td>

</tr>

</table>

</form>

</td>

</tr>

<%
    }
} else {
%>

<tr>

<td colspan="5"
style="text-align:center;
padding:32px;">

No Assets Found

</td>

</tr>

<%
}
%>

</tbody>

</table>

</div>

<!-- HISTORY MODAL -->

<div id="historyModal"
class="modal-overlay">

<div class="modal-content">

<div class="modal-header">

<h3 class="modal-title">

Tracking History

<span id="modalAssetTitle"
style="color:var(--primary);">
</span>

</h3>

<button
class="modal-close"
onclick="closeModal()">

&times;

</button>

</div>

<div class="table-container">

<table>

<thead>

<tr>

<th>Origin Location</th>
<th>Destination Location</th>
<th>Handled By</th>
<th>Timestamp</th>
<th>Remarks</th>

</tr>

</thead>

<tbody id="historyDataContainer">

</tbody>

</table>

</div>

</div>

</div>

</body>
</html>