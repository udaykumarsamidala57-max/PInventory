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
if ((!"Global".equalsIgnoreCase(role) &&  !"Finance".equalsIgnoreCase(dept))) {
    out.println("<h3 style='color:#ef4444;text-align:center;font-family:sans-serif;margin-top:40px;'>Access Denied! You are not authorized.</h3>");
    return;
}
%>
<%
ArrayList<HashMap<String,Object>> categories = (ArrayList<HashMap<String,Object>>) request.getAttribute("categories");
ArrayList<HashMap<String,Object>> subcategories = (ArrayList<HashMap<String,Object>>) request.getAttribute("subcategories");
ArrayList<HashMap<String,Object>> assets = (ArrayList<HashMap<String,Object>>) request.getAttribute("assets");
ArrayList<HashMap<String,Object>> locations = (ArrayList<HashMap<String,Object>>) request.getAttribute("locations");

String selectedCategory = request.getParameter("category_id");
String selectedSubcategory = request.getParameter("subcategory_id");

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
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
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
    color: var(--text-main);
}

.filter-box {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 24px;
    margin-bottom: 24px;
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.05);
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
    color: var(--text-main);
    background-color: #fff;
    min-width: 220px;
    transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

select:focus {
    outline: none;
    border-color: var(--primary);
    box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
}

.table-container {
    overflow-x: auto;
    border: 1px solid var(--border);
    border-radius: 12px;
    background: #fff;
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.05);
}

table {
    width: 100%;
    border-collapse: collapse;
    font-size: 14px;
    text-align: left;
    margin-top: 0;
}

th, td {
    padding: 14px 20px;
    border-bottom: 1px solid var(--border);
}

th {
    background: #f8fafc;
    font-weight: 600;
    color: var(--text-muted);
    font-size: 13px;
    text-transform: uppercase;
    letter-spacing: 0.03em;
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
    font-weight: 500;
    border-radius: 6px;
    background: #f1f5f9;
    color: var(--text-muted);
    font-style: italic;
}

button {
    background: var(--primary);
    color: #fff;
    border: 0;
    padding: 8px 16px;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 600;
    font-size: 13px;
    transition: background 0.15s ease;
}

button:hover {
    background: var(--primary-hover);
}

.history-link {
    display: inline-block;
    font-size: 11px;
    color: var(--primary);
    text-decoration: none;
    margin-top: 4px;
    font-weight: 500;
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
    background: rgba(15, 23, 42, 0.4);
    backdrop-filter: blur(4px);
    display: none;
    align-items: center;
    justify-content: center;
    z-index: 9999;
}

.modal-content {
    background: #fff;
    padding: 28px;
    border-radius: 12px;
    width: 90%;
    max-width: 750px;
    max-height: 80vh;
    overflow-y: auto;
    box-shadow: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
    border: 1px solid var(--border);
    position: relative;
    animation: modalSlide 0.2s ease-out;
}

@keyframes modalSlide {
    from { transform: translateY(15px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
}

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    border-bottom: 1px solid var(--border);
    padding-bottom: 12px;
}

.modal-title {
    font-size: 1.2rem;
    font-weight: 700;
    color: var(--text-main);
    margin: 0;
}

.modal-close {
    background: none;
    border: none;
    color: var(--text-muted);
    font-size: 24px;
    cursor: pointer;
    padding: 0;
    line-height: 1;
}
.modal-close:hover {
    color: var(--text-main);
}

.history-table {
    width: 100%;
    font-size: 13px;
}
.history-table th {
    padding: 10px 14px;
}
.history-table td {
    padding: 10px 14px;
}

.form-inline-container {
    display: contents;
}
</style>

<script>
function loadSubcategories(){
    let category = document.getElementById("category").value;
    window.location = "AssetLocationController?action=load&category_id=" + category;
}

function loadAssets(){
    let category = document.getElementById("category").value;
    let subcategory = document.getElementById("subcategory").value;
    window.location = "AssetLocationController?action=load&category_id=" + category + "&subcategory_id=" + subcategory;
}

function viewHistory(assetId, assetCode) {
    document.getElementById("modalAssetTitle").innerText = assetCode;
    var modal = document.getElementById("historyModal");
    var container = document.getElementById("historyDataContainer");
    
    container.innerHTML = '<tr><td colspan="5" style="text-align:center; color:var(--text-muted); padding:20px;">Fetching asset logs...</td></tr>';
    modal.style.display = "flex";

    fetch("AssetLocationController?action=history&asset_id=" + assetId)
        .then(response => response.json())
        .then(data => {
            if (data && data.length > 0) {
                var html = "";
                data.forEach(row => {
                    html += "<tr>" +
                        "<td>" + (row.from_location || '<span class="badge-unassigned">Initial Base</span>') + "</td>" +
                        "<td><strong>" + (row.to_location || 'Unknown') + "</strong></td>" +
                        "<td>" + (row.moved_by || '') + "</td>" +
                        "<td style='color:var(--text-muted);'>" + (row.moved_datetime || '') + "</td>" +
                        "<td>" + (row.remarks || '-') + "</td>" +
                        "</tr>";
                });
                container.innerHTML = html;
            } else {
                container.innerHTML = '<tr><td colspan="5" style="text-align:center; color:var(--text-muted); padding:20px;">No movement history transitions tracked for this asset item.</td></tr>';
            }
        })
        .catch(err => {
            console.error(err);
            container.innerHTML = '<tr><td colspan="5" style="text-align:center; color:#ef4444; padding:20px;">Error parsing database log details.</td></tr>';
        });
}

function closeModal() {
    document.getElementById("historyModal").style.display = "none";
}

window.onclick = function(event) {
    var modal = document.getElementById("historyModal");
    if (event.target == modal) {
        modal.style.display = "none";
    }
}
</script>
</head>

<body>
<%@ include file="../header.jsp" %>
<h2>Assign / Change Asset Location</h2>

<div class="filter-box">
    <div class="filter-group">
        <label>Category</label>
        <select id="category" onchange="loadSubcategories()">
            <option value="">Select Category</option>
            <%
            if(categories != null){
                for(HashMap<String,Object> c : categories){
            %>
            <option value="<%=c.get("category_id")%>" <%=selectedCategory.equals(String.valueOf(c.get("category_id"))) ? "selected" : ""%>>
                <%=c.get("category_name")%>
            </option>
            <%
                }
            }
            %>
        </select>
    </div>

    <div class="filter-group">
        <label>Subcategory</label>
        <select id="subcategory" onchange="loadAssets()">
            <option value="">Select Subcategory</option>
            <%
            if(subcategories != null){
                for(HashMap<String,Object> s : subcategories){
            %>
            <option value="<%=s.get("subcategory_id")%>" <%=selectedSubcategory.equals(String.valueOf(s.get("subcategory_id"))) ? "selected" : ""%>>
                <%=s.get("subcategory_name")%>
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
                    <strong><%=a.get("asset_code")%></strong>
                    <br>
                    <a class="history-link" onclick="viewHistory('<%=a.get("asset_id")%>', '<%=a.get("asset_code")%>')">History</a>
                </td>
                <td>
                    <%=a.get("asset_name")%>
                </td>
                <td>
                    <% if(a.get("current_location") == null) { %>
                        <span class="badge-unassigned">Not Assigned</span>
                    <% } else { %>
                        <%=a.get("current_location")%>
                    <% } %>
                </td>
                
                <!-- Form variables wrapped strictly within structural visual column elements -->
                <td colspan="2" style="padding: 0;">
                    <form action="AssetLocationController" method="post" class="form-inline-container">
                        <input type="hidden" name="asset_id" value="<%=a.get("asset_id")%>">
                        <input type="hidden" name="category_id" value="<%=selectedCategory%>">
                        <input type="hidden" name="subcategory_id" value="<%=selectedSubcategory%>">
                        <input type="hidden" name="action" value="assign">
                        
                        <table style="width: 100%; border-collapse: collapse; margin: 0;">
                            <tr>
                                <td style="border-bottom: 0; padding: 14px 20px; width: 50%;">
                                    <select name="location_id" required style="min-width: 180px; padding: 6px 10px; font-size: 13px; width: 100%;">
                                        <option value="">Select Location</option>
                                        <%
                                        if(locations != null){
                                            for(HashMap<String,Object> l : locations){
                                        %>
                                        <option value="<%=l.get("location_id")%>">
                                            <%=l.get("location_name")%> - <%=l.get("building")%>
                                        </option>
                                        <%
                                            }
                                        }
                                        %>
                                    </select>
                                </td>
                                <td style="border-bottom: 0; padding: 14px 20px; width: 50%;">
                                    <button type="submit">Assign</button>
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
                <td colspan="5" style="text-align: center; color: var(--text-muted); padding: 32px;">
                    No Assets Found
                </td>
            </tr>
            <%
            }
            %>
        </tbody>
    </table>
</div>

<!-- Dynamic Overlay Modal markup element component -->
<div id="historyModal" class="modal-overlay">
    <div class="modal-content">
        <div class="modal-header">
            <h3 class="modal-title">Tracking History <span id="modalAssetTitle" style="color:var(--primary);"></span></h3>
            <button class="modal-close" onclick="closeModal()">&times;</button>
        </div>
        <div class="table-container">
            <table class="history-table">
                <thead>
                    <tr>
                        <th>Origin Location</th>
                        <th>Destination Location</th>
                        <th>Handled By</th>
                        <th>Timestamp Details</th>
                        <th>Remarks</th>
                    </tr>
                </thead>
                <tbody id="historyDataContainer">
                    <!-- Loaded dynamically via JavaScript Fetch -->
                </tbody>
            </table>
        </div>
    </div>
</div>

</body>
</html>