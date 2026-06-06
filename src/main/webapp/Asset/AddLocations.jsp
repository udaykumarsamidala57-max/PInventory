<%@page import="java.sql.ResultSet"%>

<%@ page language="java"
contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

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

    out.println(
    "<div style='display:flex;justify-content:center;align-items:center;height:60vh;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;'>" +
    "<div style='background:#fff;padding:40px;border-radius:8px;box-shadow:0 12px 30px rgba(0,0,0,0.05);border:1px solid #e1e6eb;text-align:center;max-width:400px;'>" +
    "<div style='background:#ffe8e8;color:#ea001e;width:48px;height:48px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24px;font-weight:bold;margin:0 auto 16px;'>!</div>" +
    "<h3 style='color:#180d0d;font-size:1.25rem;margin:0 0 8px 0;font-weight:700;'>Access Denied</h3>" +
    "<p style='color:#514f4d;font-size:0.875rem;margin:0;'>You don't have the necessary administrative privileges to manage location routing registries.</p>" +
    "</div></div>");
    return;
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Location Structure Management</title>

<style>
:root {
    --slds-c-brand: #0176d3;
    --slds-c-brand-hover: #014486;
    --slds-g-neutral-10: #f3f3f3;
    --slds-g-neutral-20: #e5e5e5;
    --slds-g-text-10: #181818;
    --slds-g-text-20: #444444;
    --slds-g-text-30: #747474;
    --slds-success: #2e844a;
    --slds-error: #ea001e;
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
    background: #1b96ff;
    width: 32px;
    height: 32px;
    border-radius: var(--border-radius-medium);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    font-weight: bold;
}

/* NOTIFICATION TOASTS */
.slds-toast {
    padding: 12px 16px;
    border-radius: var(--border-radius-medium);
    margin-bottom: 16px;
    font-weight: 600;
    font-size: 0.875rem;
    display: flex;
    align-items: center;
    box-shadow: 0 4px 12px rgba(0,0,0,0.05);
}
.slds-toast--success {
    background: #edf8f0;
    color: var(--slds-success);
    border: 1px solid #b7e1c4;
}
.slds-toast--error {
    background: #feebeb;
    color: var(--slds-error);
    border: 1px solid #fec7c7;
}

.slds-card {
    background: #fff;
    border: 1px solid var(--slds-g-neutral-20);
    border-radius: var(--border-radius-large);
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.05);
    margin-bottom: 20px;
    overflow: hidden;
}

.slds-card__header {
    padding: 16px 24px;
    background: var(--slds-g-neutral-10);
    border-bottom: 1px solid var(--slds-g-neutral-20);
    font-weight: 700;
    font-size: 0.875rem;
    color: var(--slds-g-text-20);
    letter-spacing: 0.02em;
}

.form-grid {
    padding: 24px;
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 20px;
}

.form-group {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.form-group--full {
    grid-column: span 4;
}

label {
    font-size: 0.75rem;
    font-weight: 600;
    color: var(--slds-g-text-20);
}

input[type="text"], textarea {
    padding: 0 12px;
    height: 32px;
    border: 1px solid var(--slds-g-neutral-20);
    border-radius: var(--border-radius-medium);
    font-family: inherit;
    font-size: 0.8125rem;
    background: #fff;
    color: var(--slds-g-text-10);
    transition: border-color 0.1s linear, box-shadow 0.1s linear;
}

textarea {
    height: 64px;
    padding: 8px 12px;
    resize: vertical;
}

input[type="text"]:focus, textarea:focus {
    outline: none;
    border-color: var(--slds-c-brand);
    box-shadow: 0 0 3px #0176d3;
}

/* ACTIONS MATRIX */
.card-footer-actions {
    padding: 12px 24px;
    background: var(--slds-g-neutral-10);
    border-top: 1px solid var(--slds-g-neutral-20);
    text-align: right;
}

button {
    height: 32px;
    padding: 0 16px;
    border-radius: var(--border-radius-medium);
    cursor: pointer;
    font-size: 0.8125rem;
    font-weight: 600;
    border: 1px solid var(--slds-g-neutral-20);
    transition: background 0.1s, color 0.1s;
}

.btn-brand {
    background: var(--slds-c-brand);
    color: #fff;
    border-color: transparent;
}
.btn-brand:hover {
    background: var(--slds-c-brand-hover);
}

.btn-neutral {
    background: #fff;
    color: var(--slds-c-brand);
    border-color: var(--slds-g-neutral-20);
}
.btn-neutral:hover {
    background: var(--slds-g-neutral-10);
}

.btn-destructive {
    background: #fff;
    color: var(--slds-error);
    border-color: var(--slds-g-neutral-20);
}
.btn-destructive:hover {
    background: #fff0f0;
    border-color: #fec7c7;
}

/* DATA TABULATION */
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

.building-row td {
    background: #eef7ff !important;
    font-weight: 700;
    font-size: 0.875rem;
    color: #014486;
    padding: 12px 16px;
    border-top: 1px solid #b4cbe1;
    border-bottom: 1px solid #b4cbe1;
}

tr:hover td {
    background-color: #fafafafb;
}

.table-input {
    width: 90%;
    height: 28px !important;
}

.action-cluster {
    display: flex;
    gap: 8px;
    justify-content: flex-start;
}
</style>

<script>
function enableEdit(id){
    document.getElementById("text_"+id).style.display="none";
    document.getElementById("edit_"+id).style.display="table-row";
}

function cancelEdit(id){
    document.getElementById("text_"+id).style.display="table-row";
    document.getElementById("edit_"+id).style.display="none";
}
</script>
</head>

<body>

<%@ include file="../header.jsp" %>

<div class="slds-canvas">

    <% if(request.getParameter("success") != null){ %>
        <div class="slds-toast slds-toast--success">✓ Operational Blueprint Logged: Location Added Successfully</div>
    <% } %>
    <% if(request.getParameter("updated") != null){ %>
        <div class="slds-toast slds-toast--success">✓ Operational Matrix Altered: Location Updated Successfully</div>
    <% } %>
    <% if(request.getParameter("deleted") != null){ %>
        <div class="slds-toast slds-toast--success">✓ Registry Vector Cleaned: Location Deleted Successfully</div>
    <% } %>
    <% if(request.getParameter("error") != null){ %>
        <div class="slds-toast slds-toast--error">⚠ Processing Interrupted: Operation Failed to Commit</div>
    <% } %>

    <div class="slds-page-header">
        <div class="slds-page-header__title">
            <div class="slds-icon-container">L</div>
            <div>
                <span style="font-size:0.75rem;font-weight:normal;color:var(--slds-g-text-30);display:block;text-transform:uppercase;">Infrastructure Management</span>
                
            </div>
        </div>
    </div>

    <div class="slds-card">
        <div class="slds-card__header">Add Location</div>
        <form action="<%=request.getContextPath()%>/LocationController" method="post">
            <input type="hidden" name="action" value="insert">
            
            <div class="form-grid">
                <div class="form-group">
                    <label>Location Name</label>
                    <input type="text" name="location_name" required autocomplete="off">
                </div>
                <div class="form-group">
                    <label>Building / Complex Block</label>
                    <input type="text" name="building" autocomplete="off">
                </div>
                <div class="form-group">
                    <label>Floor Axis Identifier</label>
                    <input type="text" name="floor_name" autocomplete="off">
                </div>
                <div class="form-group">
                    <label>Room Allocation ID</label>
                    <input type="text" name="room_number" autocomplete="off">
                </div>
                <div class="form-group form-group--full">
                    <label>Description </label>
                    <textarea name="description"></textarea>
                </div>
            </div>

            <% if ("Global".equalsIgnoreCase(role) ) { %>
            <div class="card-footer-actions">
                <button type="submit" class="btn-brand">Save Location</button>
            </div>
            <% } %>
        </form>
    </div>

    <div class="slds-card">
        <div class="slds-card__header">Active Locations List</div>
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th style="width: 8%;">Node ID</th>
                        <th style="width: 20%;">Location Name</th>
                        <th style="width: 15%;">Floor Track</th>
                        <th style="width: 15%;">Room Index</th>
                        <th style="width: 22%;">Context Description</th>
                        <th style="width: 20%;">Broker Actions</th>
                    </tr>
                </thead>
                <tbody>
                <%
                ResultSet rs = (ResultSet)request.getAttribute("locationData");
                String currentBuilding = "";

                if(rs != null){
                    while(rs.next()){
                        int id = rs.getInt("location_id");
                        String building = rs.getString("building");

                        if(building == null || building.trim().equals("")){
                            building = "Unallocated Complex/No Building";
                        }

                        // CONDITIONAL HEADLINE MERGING FOR BUILDING MATRIX
                        if(!building.equals(currentBuilding)){
                            currentBuilding = building;
                %>
                    <tr class="building-row">
                        <td colspan="6">
                            🏢 Building: <%=building%>
                        </td>
                    </tr>
                <%
                        }
                %>
                    <tr id="text_<%=id%>">
                        <td style="font-weight: 600; color: var(--slds-g-text-30);"><%=id%></td>
                        <td style="font-weight: 700; color: var(--slds-c-brand);"><%=rs.getString("location_name")%></td>
                        <td><%=rs.getString("floor_name") == null ? "-" : rs.getString("floor_name")%></td>
                        <td><strong><%=rs.getString("room_number") == null ? "-" : rs.getString("room_number")%></strong></td>
                        <td style="color: var(--slds-g-text-20);"><%=rs.getString("description") == null ? "" : rs.getString("description")%></td>
                        <td>
                            <% if ("Global".equalsIgnoreCase(role) ) { %>
                            <div class="action-cluster">
                                <button type="button" class="btn-neutral" style="height:26px; padding:0 12px;" onclick="enableEdit('<%=id%>')">Edit</button>
                                <a class="btn-destructive" style="height:24px; padding:0 12px; line-height:24px; text-decoration:none; display:inline-block; font-size:0.8125rem; border:1px solid var(--slds-g-neutral-20); border-radius:var(--border-radius-medium);"
                                   onclick="return confirm('Confirm complete destruction of this location asset trace?')" 
                                   href="<%=request.getContextPath()%>/LocationController?action=delete&id=<%=id%>">
                                   Delete
                                </a>
                            </div>
                            <% } %>
                        </td>
                    </tr>

                    <tr id="edit_<%=id%>" style="display:none; background:#fafbfe;">
                        <form action="<%=request.getContextPath()%>/LocationController" method="post">
                            <input type="hidden" name="action" value="update">
                            <input type="hidden" name="location_id" value="<%=id%>">
                            <input type="hidden" name="building" value="<%=building%>">
                            
                            <td style="font-weight: 600; color: var(--slds-g-text-30);"><%=id%></td>
                            <td>
                                <input type="text" class="table-input" name="location_name" value="<%=rs.getString("location_name")%>" required>
                            </td>
                            <td>
                                <input type="text" class="table-input" name="floor_name" value="<%=rs.getString("floor_name") != null ? rs.getString("floor_name") : ""%>">
                            </td>
                            <td>
                                <input type="text" class="table-input" name="room_number" value="<%=rs.getString("room_number") != null ? rs.getString("room_number") : ""%>">
                            </td>
                            <td>
                                <input type="text" class="table-input" name="description" value="<%=rs.getString("description") != null ? rs.getString("description") : ""%>">
                            </td>
                            <td>
                                <div class="action-cluster">
                                    <button type="submit" class="btn-brand" style="height:26px; padding:0 12px;">Update</button>
                                    <button type="button" class="btn-neutral" style="height:26px; padding:0 12px;" onclick="cancelEdit('<%=id%>')">Cancel</button>
                                </div>
                            </td>
                        </form>
                    </tr>
                <%
                    }
                } else {
                %>
                    <tr>
                        <td colspan="6" style="text-align:center; padding:48px; color:var(--slds-g-text-30); font-size:0.875rem;">
                            No static structural matrices detected in scope database.
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
</div>

</body>
</html>