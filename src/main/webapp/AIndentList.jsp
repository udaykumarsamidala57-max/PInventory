<%@ page import="java.util.*, com.bean.IndentItemFull" %>
<%@ page import="javax.servlet.http.HttpSession" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String user = (String) sess.getAttribute("username");
    String role = (String) sess.getAttribute("role");

    if (!"Global".equalsIgnoreCase(role) &&
        !"Incharge".equalsIgnoreCase(role) &&
        !"Admin".equalsIgnoreCase(role)) {
        response.setContentType("text/html");
        response.getWriter().println("<h3 style='color:red;'>Access Denied</h3>");
        return;
    }

    Map<Integer, Double> pendingMap = (Map<Integer, Double>) request.getAttribute("pendingPerItem");
    if (pendingMap == null) pendingMap = new HashMap<>();

    List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
    if (indents == null) indents = new ArrayList<>();

    String errorMsg = (String) request.getAttribute("errorMsg");

    Map<String, List<IndentItemFull>> groupedIndents = new LinkedHashMap<>();
    for (IndentItemFull i : indents) {
        groupedIndents.computeIfAbsent(i.getIndentNo(), k -> new ArrayList<>()).add(i);
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Approve Indent</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<style>
body {
    font-family: 'Poppins', sans-serif;
    background-color: #eef2f8;
    color: #333;
    margin: 0;
    padding: 0;
}
h1 {
    color: #003366;
    text-align: center;
    margin: 25px 0;
    font-weight: 600;
}
.card {
    background: transparent;
    max-width: 95%;
    margin: auto;
}
.filter-bar {
    background: white;
    padding: 12px 18px;
    border-radius: 12px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.08);
    margin-bottom: 20px;
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    align-items: center;
}
.filter-input {
    padding: 7px 10px;
    border-radius: 6px;
    border: 1px solid #ccc;
    min-width: 150px;
}

/* ---------- Indent Card ---------- */
.indent-card {
    background: white;
    border-radius: 14px;
    box-shadow: 0 3px 15px rgba(0,0,0,0.08);
    margin-bottom: 25px;
    overflow: hidden;
    transition: transform 0.2s ease;
}
.indent-card:hover {
    transform: translateY(-2px);
}

/* ---------- Indent Header ---------- */
.indent-header {
    background: linear-gradient(90deg, #004080, #0059b3);
    color: white;
    padding: 14px 20px;
    display: flex;
    justify-content: space-between;
    flex-wrap: wrap;
    border-bottom: 4px solid #003366;
}
.indent-header div {
    flex: 1;
    text-align: center;
    font-size: 14px;
    font-weight: 500;
    margin: 3px 0;
}
.indent-header .indent-no {
    font-weight: 800;
    font-size: 20px;
}

/* ---------- Inner Table ---------- */
.inner-table {
    width: 98%;
    margin: 12px auto 20px;
    border-collapse: collapse;
    border-radius: 10px;
    overflow: hidden;
    box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}
.inner-table th {
    background-color: #f0f4fa;
    color: #003366;
    padding: 10px 12px;
    font-size: 13px;
    border-bottom: 2px solid #d5e0f2;
}
.inner-table td {
    padding: 8px 12px;
    border-bottom: 1px solid #e6ecf5;
    text-align: center;
    background-color: #fff;
    font-size: 13px;
}
.inner-table tr:nth-child(even) td { background-color: #f9fbff; }
.inner-table tr:hover td { background-color: #eef4ff; }

.cancelled-row td {
    background-color: #ffe6e6 !important;
}

/* ---------- Buttons ---------- */
button, .btn-blue, .btn-orange, .btn-edit, .btn-delete, .btn-green {
    border: none;
    border-radius: 6px;
    padding: 6px 10px;
    font-size: 13px;
    cursor: pointer;
    font-weight: 500;
}
.btn-blue { background-color: #007bff; color: white; }
.btn-blue:hover { background-color: #0056b3; }
.btn-orange { background-color: #ff9800; color: white; }
.btn-orange:hover { background-color: #e68900; }
.btn-edit { background-color: #17a2b8; color: white; }
.btn-edit:hover { background-color: #138496; }
.btn-delete { background-color: #dc3545; color: white; }
.btn-delete:hover { background-color: #b02a37; }
.btn-green { background-color: #28a745; color: white; }
.btn-green:hover { background-color: #218838; }

/* ---------- Dropdown ---------- */
.dropdown-container {
    display: none;
    margin-top: 6px;
    background: #f8f9fb;
    padding: 8px;
    border-radius: 6px;
    border: 1px solid #d1d9e6;
}
.dropdown-container select { padding: 6px; border-radius: 5px; border: 1px solid #ccc; }
.dropdown-container button { margin-left: 6px; }

/* ---------- Modals ---------- */
.modal-overlay {
    position: fixed; top: 0; left: 0; width: 100%; height: 100%;
    background: rgba(0,0,0,0.4);
    display: none;
    justify-content: center;
    align-items: center;
    z-index: 1000;
}
.modal {
    background: white;
    border-radius: 10px;
    width: 400px;
    padding: 20px;
    text-align: center;
    box-shadow: 0 6px 20px rgba(0,0,0,0.2);
}
.modal h3 { color: #004080; font-weight: 600; margin-bottom: 10px; }
.modal button { margin-top: 10px; }

@media (max-width: 768px) {
    .indent-header div { font-size: 12px; }
    .inner-table, button { font-size: 12px; }
}
</style>
</head>

<body>
<%@ include file="header.jsp" %>

<div class="main-content">
<div class="card">
    <h1>Approve Indent</h1>

    <% if (errorMsg != null) { %>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            showPopup("<%= errorMsg.replace("\"","\\\"").replace("\n"," ") %>");
        });
    </script>
    <% } %>

    <div class="filter-bar">
        <label>From:</label><input type="date" id="fromDate" class="filter-input">
        <label>To:</label><input type="date" id="toDate" class="filter-input">
        <input type="text" id="keywordSearch" placeholder="Search keyword..." class="filter-input" style="flex:1; min-width:200px;">
        <button onclick="filterTable()" class="btn-blue">Search</button>
        <button onclick="resetFilters()" class="btn-orange">Reset</button>
    </div>

    <% if (!groupedIndents.isEmpty()) { 
        for (Map.Entry<String, List<IndentItemFull>> entry : groupedIndents.entrySet()) {
            String indentNo = entry.getKey();
            List<IndentItemFull> items = entry.getValue();
            IndentItemFull first = items.get(0);
    %>
    <div class="indent-card">
        <div class="indent-header">
            <div class="indent-no">Indent No: <%= indentNo %></div>
            <div>Date: <%= first.getDate() %></div>
            <div>Dept: <%= first.getDepartment() %></div>
            <div>Requested By: <%= first.getRequestedBy() %></div>
            <div>Status: <%= first.getStatus() %></div>
        </div>

        <table class="inner-table">
            <thead>
                <tr>
                    <th>ID</th><th>Item</th><th>Avl.Qty</th><th>Req.Qty</th><th>UOM</th><th>Purpose</th>
                    <th>I/C Act</th><th>L1</th><th>L1 Approved By</th><th>L2</th><th>Actions</th><th>Next</th>
                </tr>
            </thead>
            <tbody>
            <%
                for (IndentItemFull ind : items) {
                    String status = ind.getStatus() != null ? ind.getStatus().trim() : "";
                    String I_Status = ind.getIstatus() != null ? ind.getIstatus().trim() : "";
                    String next = ind.getIndentNext() != null ? ind.getIndentNext().trim() : "";
                    Integer itemId = ind.getItemId();
                    double pending = (itemId != null && pendingMap.get(itemId) != null) ? pendingMap.get(itemId) : 0.0;
                    boolean editable = (next == null || next.isEmpty());
            %>
            <tr class="<%= "Cancelled".equalsIgnoreCase(status) ? "cancelled-row" : "" %>">
                <td><%= ind.getId() %></td>
                <td><%= ind.getItemName() %></td>
                <td><%= ind.getBalanceQty() %></td>
                <td><%= ind.getQty() %></td>
                <td><%= ind.getUom() %></td>
                <td><%= ind.getPurpose() %></td>
                <td>
                    <% if (("Incharge".equalsIgnoreCase(role) || "Admin".equalsIgnoreCase(role) || "Global".equalsIgnoreCase(role)) && !"Approved".equalsIgnoreCase(I_Status)) { %>
                        <form action="AIndentListServlet" method="post">
                            <input type="hidden" name="id" value="<%= ind.getId() %>">
                            <input type="hidden" name="action" value="Iapprove">
                            <button class="btn-green" type="submit">Approve</button>
                        </form>
                    <% } %>
                </td>
                <td><%= I_Status %></td>
                <td><%= ind.getApprovedBy() %></td>
                <td><%= status %></td>
                <td>
                    <% if (editable) { %>
                        <button class="btn-edit" type="button" onclick="openEditModal(<%= ind.getId() %>, '<%= ind.getQty() %>', '<%= ind.getPurpose().replace("'", "\\'") %>')">Edit</button>
                        <form action="AIndentListServlet" method="post" style="display:inline;">
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<%= ind.getId() %>">
                            <button type="submit" class="btn-delete">Delete</button>
                        </form>
                    <% } %>
                    <% if ("Global".equalsIgnoreCase(role) && "Approved".equalsIgnoreCase(I_Status) && !"Approved".equalsIgnoreCase(status)) { %>
                        <button class="btn-orange" type="button" onclick="toggleDropdown(<%= ind.getId() %>)">Final Approve</button>
                        <div class="dropdown-container" id="dropdown-<%= ind.getId() %>">
                            <form action="AIndentListServlet" method="post"
                                  data-qty="<%= ind.getQty() %>"
                                  data-balance="<%= ind.getBalanceQty() %>"
                                  data-pending="<%= pending %>"
                                  onsubmit="return validateApprovalForm(this)">
                                <input type="hidden" name="id" value="<%= ind.getId() %>">
                                <input type="hidden" name="action" value="approve">
                                <select name="indentnext" required>
                                    <option value="">--Select Next Step--</option>
                                    <option value="Issue">Issue</option>
                                    <option value="PO">PO</option>
                                    <option value="Cancelled">Cancel</option>
                                    <option value="Management Note">Management Note</option>
                                </select>
                                <button class="btn-blue" type="submit">Confirm</button>
                            </form>
                        </div>
                    <% } %>
                </td>
                <td><%= next %></td>
            </tr>
            <% } %>
            </tbody>
        </table>
    </div>
    <% } } else { %>
        <p style="text-align:center; font-weight:500;">No records found</p>
    <% } %>
</div>
</div>

<!-- Edit Modal -->
<div class="modal-overlay" id="editModal">
    <div class="modal edit-modal">
        <h3>Edit Indent</h3>
        <form action="AIndentListServlet" method="post" id="editForm">
            <input type="hidden" name="action" value="edit">
            <input type="hidden" id="editId" name="id">
            <label>Quantity:</label><br>
            <input type="number" id="editQty" name="qty" step="0.01" required><br>
            <label>Purpose:</label><br>
            <textarea id="editPurpose" name="purpose" rows="3" required></textarea><br>
            <button type="submit" class="btn-blue">Update</button>
            <button type="button" onclick="closeEditModal()" class="btn-orange">Cancel</button>
        </form>
    </div>
</div>

<!-- Popup -->
<div class="modal-overlay" id="popupOverlay">
    <div class="modal" id="popupBox">
        <h3 id="popupTitle">Notice</h3>
        <p id="popupMessage"></p>
        <button id="popupOkBtn" class="btn-blue">OK</button>
    </div>
</div>

<%@ include file="Footer.jsp" %>

<script>
let formToSubmit = null;
function showPopup(msg, form = null) {
    document.getElementById("popupMessage").innerText = msg;
    document.getElementById("popupOverlay").style.display = "flex";
    formToSubmit = form;
}
function closePopup() {
    document.getElementById("popupOverlay").style.display = "none";
    if (formToSubmit) { formToSubmit.submit(); formToSubmit = null; }
}
document.getElementById("popupOkBtn").addEventListener("click", closePopup);

function toggleDropdown(id) {
    document.querySelectorAll(".dropdown-container").forEach(d => {
        d.style.display = (d.id === "dropdown-" + id && d.style.display !== "block") ? "block" : "none";
    });
}

function openEditModal(id, qty, purpose) {
    document.getElementById("editId").value = id;
    document.getElementById("editQty").value = qty;
    document.getElementById("editPurpose").value = purpose;
    document.getElementById("editModal").style.display = "flex";
}
function closeEditModal() {
    document.getElementById("editModal").style.display = "none";
}

function validateApprovalForm(form) {
    const qty = parseFloat(form.dataset.qty) || 0;
    const balance = parseFloat(form.dataset.balance) || 0;
    const pending = parseFloat(form.dataset.pending) || 0;
    const next = form.querySelector('select[name="indentnext"]').value;

    if (next === "Issue") {
        if ((pending + qty) > balance) {
            showPopup("⚠️ Stock not available.\n\nAvailable: " + balance + "\nPending: " + pending + "\nRequested: " + qty);
            return false;
        } else {
            showPopup("✅ Indent sent to Stock Issue section.", form);
            return false;
        }
    } else if (next === "PO") {
        showPopup("✅ Indent moved to Purchase Order section.", form);
        return false;
    } else if (next === "Cancelled") {
        form.submit();
        return false;
    } else if (next === "Management Note") {
        showPopup("ℹ️ Indent moved to Management Note section.", form);
        return false;
    } else {
        showPopup("Please select next step.");
        return false;
    }
}

// SEARCH FILTERS
function filterTable() {
    const fromDate = document.getElementById("fromDate").value;
    const toDate = document.getElementById("toDate").value;
    const keyword = document.getElementById("keywordSearch").value.toLowerCase();
    const rows = document.querySelectorAll(".indent-card");

    rows.forEach(card => {
        const headerText = card.innerText.toLowerCase();
        const dateText = card.querySelector(".indent-header div:nth-child(2)").innerText.split(":")[1].trim();
        let visible = true;

        if (fromDate && dateText < fromDate) visible = false;
        if (toDate && dateText > toDate) visible = false;
        if (keyword && !headerText.includes(keyword)) visible = false;

        card.style.display = visible ? "" : "none";
    });
}
function resetFilters() {
    document.getElementById("fromDate").value = "";
    document.getElementById("toDate").value = "";
    document.getElementById("keywordSearch").value = "";
    document.querySelectorAll(".indent-card").forEach(r => r.style.display = "");
}
</script>
</body>
</html>
