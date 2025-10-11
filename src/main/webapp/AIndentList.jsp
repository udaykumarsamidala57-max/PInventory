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

    Map<Integer, Double> pendingMap = (Map<Integer, Double>) request.getAttribute("pendingPerItem");
    if (pendingMap == null) pendingMap = new HashMap<>();

    List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
    if (indents == null) indents = new ArrayList<>();

    String errorMsg = (String) request.getAttribute("errorMsg");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Indent List</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">

    <style>
        body { font-family: 'Poppins', sans-serif; }
        .highlight-cell { background-color: #fff3cd; }
        .btn-orange { background-color: #ff9800; color: white; border: none; padding: 6px 10px; border-radius: 4px; cursor: pointer; }
        .btn-edit { background-color: #17a2b8; color: white; border: none; padding: 5px 10px; border-radius: 4px; cursor: pointer; }
        .btn-edit:hover { background-color: #138496; }
        .btn-delete { background-color: #dc3545; color: white; border: none; padding: 5px 10px; border-radius: 4px; cursor: pointer; }
        .btn-delete:hover { background-color: #c82333; }
        .modal-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); display: none; justify-content: center; align-items: center; z-index: 1000; }
        .modal { background: white; border-radius: 12px; width: 460px; padding: 20px; text-align: center; box-shadow: 0 8px 25px rgba(0,0,0,0.2); animation: fadeIn 0.25s ease; }
        .modal h3 { color: #333; font-weight: 600; margin-bottom: 18px; }
        .modal p { color: #555; font-size: 18px; margin-bottom: 20px; }
        .modal button { background-color: #007bff; color: white; border: none; border-radius: 6px; padding: 8px 18px; font-weight: 500; cursor: pointer; transition: background 0.3s ease; }
        .modal button:hover { background-color: #0056b3; }
        @keyframes fadeIn { from { opacity: 0; transform: scale(0.9); } to { opacity: 1; transform: scale(1); } }
        .dropdown-container { display: none; margin-top: 5px; }
        .dropdown-container select { padding: 4px; border-radius: 5px; border: 1px solid #ccc; }
        .dropdown-container button { margin-left: 6px; }
        .cancelled-row { background-color: #f8d7da !important; }
        .edit-modal input, .edit-modal textarea { width: 90%; margin: 6px auto; padding: 5px; border: 1px solid #ccc; border-radius: 4px; }
    </style>
</head>

<body>
<%@ include file="header.jsp" %>

<div class="main-content">
    <div class="card">
        <h2>Indent List</h2>

        <% if (errorMsg != null) { %>
        <script>
            document.addEventListener("DOMContentLoaded", function() {
                showPopup("<%= errorMsg.replace("\"","\\\"").replace("\n"," ") %>");
            });
        </script>
        <% } %>

        <!-- Search filters -->
        <div style="margin-bottom: 15px; display: flex; flex-wrap: wrap; gap: 10px; align-items: center;">
            <label>From:</label>
            <input type="date" id="fromDate" class="filter-input">
            <label>To:</label>
            <input type="date" id="toDate" class="filter-input">
            <input type="text" id="keywordSearch" placeholder="Search keyword..." class="filter-input" style="flex:1; min-width:200px;">
            <button onclick="filterTable()" class="btn btn-blue">Search</button>
            <button onclick="resetFilters()" class="btn btn-orange">Reset</button>
        </div>

        <!-- Indent table -->
        <table class="main-table">
            <thead>
            <tr>
                <th>ID</th><th>Ind. No</th><th>Date</th><th>Item</th><th>Qty</th><th>Avl. Qty</th>
                <th>UOM</th><th>Dept.</th><th>Req. By</th><th>Purpose</th>
                <th>I/C Act</th><th>I/C Stat</th><th>Status</th><th>Next</th><th>Actions</th>
            </tr>
            </thead>
            <tbody>
            <%
                if (!indents.isEmpty()) {
                    for (IndentItemFull ind : indents) {
                        String status = ind.getStatus() != null ? ind.getStatus().trim() : "";
                        String I_Status = ind.getIstatus() != null ? ind.getIstatus().trim() : "";
                        String next = ind.getIndentNext() != null ? ind.getIndentNext().trim() : "";
                        Integer itemId = ind.getItemId();
                        double pending = (itemId != null && pendingMap.get(itemId) != null) ? pendingMap.get(itemId) : 0.0;
                        boolean editable = (next == null || next.isEmpty());
            %>
            <tr class="<%= "Cancelled".equalsIgnoreCase(status) ? "cancelled-row" : "" %>">
                <td><%= ind.getId() %></td>
                <td><%= ind.getIndentNo() %></td>
                <td><%= ind.getDate() %></td>
                <td><%= ind.getItemName() %></td>
                <td><%= ind.getQty() %></td>
                <td><%= ind.getBalanceQty() %></td>
                <td><%= ind.getUom() %></td>
                <td><%= ind.getDepartment() %></td>
                <td><%= ind.getRequestedBy() %></td>
                <td><%= ind.getPurpose() %></td>
                <td>
                    <% if (("Incharge".equalsIgnoreCase(role) || "Global".equalsIgnoreCase(role)) && !"Approved".equalsIgnoreCase(I_Status)) { %>
                        <form action="AIndentListServlet" method="post">
                            <input type="hidden" name="id" value="<%= ind.getId() %>">
                            <input type="hidden" name="action" value="Iapprove">
                            <button class="btn btn-green" type="submit">Approve</button>
                        </form>
                    <% } %>
                </td>
                <td><%= I_Status %></td>
                <td><%= status %></td>
                <td><%= next %></td>
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
                                <button class="btn btn-blue" type="submit">Confirm</button>
                            </form>
                        </div>
                    <% } %>
                </td>
            </tr>
            <%
                    }
                } else {
            %>
            <tr><td colspan="15" style="text-align:center;">No records found</td></tr>
            <% } %>
            </tbody>
        </table>
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
            <button type="submit" class="btn btn-blue">Update</button>
            <button type="button" onclick="closeEditModal()" class="btn btn-orange">Cancel</button>
        </form>
    </div>
</div>

<!-- Popup -->
<div class="modal-overlay" id="popupOverlay">
    <div class="modal" id="popupBox">
        <h3 id="popupTitle">Notice</h3>
        <p id="popupMessage"></p>
        <button id="popupOkBtn">OK</button>
    </div>
</div>

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
        form.submit(); // Direct cancel (Option A)
        return false;
    } else if (next === "Management Note") {
        showPopup("ℹ️ Indent moved to Management Note section.", form);
        return false;
    } else {
        showPopup("Please select next step.");
        return false;
    }
}
</script>

</body>
</html>
