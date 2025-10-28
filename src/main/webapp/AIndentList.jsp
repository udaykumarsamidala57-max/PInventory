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

    // Group indents by IndentNo
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
<link rel="stylesheet" href="CSS/tablestyle.css">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<style>
    body { font-family: 'Poppins', sans-serif; background-color: #f5f7fb; color: #333; }
    h1 { color: #004080; text-align: center; margin-bottom: 25px; }

    .card {
        background: white;
        border-radius: 12px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        padding: 20px;
        max-width: 98%;
        margin: auto;
    }

    table {
        width: 100%;
        border-collapse: collapse;
        font-size: 14px;
    }

    th {
        background-color: #004080;
        color: white;
        padding: 10px;
        text-align: center;
    }

    td {
        padding: 8px;
        border-bottom: 1px solid #ddd;
        text-align: center;
    }

    tr.expand-row { background-color: #eef6ff; cursor: pointer; transition: all 0.3s; }
    tr.expand-row:hover { background-color: #dcecff; }
    tr.cancelled-row { background-color: #f8d7da !important; }
    tr.hidden { display: none; }

    /* Buttons */
    .btn-blue { background-color: #007bff; color: white; border: none; padding: 6px 10px; border-radius: 5px; cursor: pointer; font-weight: 500; }
    .btn-blue:hover { background-color: #0056b3; }
    .btn-orange { background-color: #ff9800; color: white; border: none; padding: 6px 10px; border-radius: 5px; cursor: pointer; font-weight: 500; }
    .btn-orange:hover { background-color: #e68900; }
    .btn-edit { background-color: #17a2b8; color: white; border: none; padding: 6px 10px; border-radius: 5px; cursor: pointer; }
    .btn-edit:hover { background-color: #138496; }
    .btn-delete { background-color: #dc3545; color: white; border: none; padding: 6px 10px; border-radius: 5px; cursor: pointer; }
    .btn-delete:hover { background-color: #b02a37; }
    .btn-green { background-color: #28a745; color: white; border: none; padding: 6px 10px; border-radius: 5px; cursor: pointer; }
    .btn-green:hover { background-color: #218838; }

    /* Modal */
    .modal-overlay {
        position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(0,0,0,0.4); display: none; justify-content: center; align-items: center;
        z-index: 1000;
    }
    .modal {
        background: white; border-radius: 10px; width: 420px; padding: 20px; text-align: center;
        box-shadow: 0 6px 20px rgba(0,0,0,0.2);
        animation: fadeIn 0.25s ease-in-out;
    }
    .modal h3 { margin-bottom: 15px; color: #004080; font-weight: 600; }
    .modal p { color: #555; font-size: 16px; margin-bottom: 20px; }
    .modal button { border: none; border-radius: 6px; padding: 8px 15px; cursor: pointer; }

    @keyframes fadeIn { from { opacity: 0; transform: scale(0.95);} to { opacity: 1; transform: scale(1);} }

    /* Dropdown */
    .dropdown-container {
        display: none;
        margin-top: 6px;
        background: #f1f1f1;
        padding: 8px;
        border-radius: 6px;
    }
    .dropdown-container select { padding: 5px; border-radius: 5px; border: 1px solid #ccc; }
    .dropdown-container button { margin-left: 8px; }

    /* Filters */
    .filter-bar {
        margin-bottom: 15px;
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
        align-items: center;
    }
    .filter-input {
        padding: 6px 8px;
        border-radius: 5px;
        border: 1px solid #ccc;
    }

    .inner-table th { background-color: #007acc; color: white; }
    .inner-table td { background: #fafafa; }

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

    <table id="indentTable">
        <thead>
            <tr><th></th><th>Indent No</th><th>Date</th><th>Department</th><th>Requested By</th><th>Status</th></tr>
        </thead>
        <tbody>
        <%
            if (!groupedIndents.isEmpty()) {
                for (Map.Entry<String, List<IndentItemFull>> entry : groupedIndents.entrySet()) {
                    String indentNo = entry.getKey();
                    List<IndentItemFull> items = entry.getValue();
                    IndentItemFull first = items.get(0);
        %>
        <tr class="expand-row" onclick="toggleIndentDetails('<%= indentNo %>')">
            <td><i class="fa fa-chevron-down"></i></td>
            <td><%= indentNo %></td>
            <td><%= first.getDate() %></td>
            <td><%= first.getDepartment() %></td>
            <td><%= first.getRequestedBy() %></td>
            <td><%= first.getStatus() %></td>
        </tr>

        <tr id="details-<%= indentNo %>" class="hidden">
            <td colspan="6">
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
            </td>
        </tr>
        <% } } else { %>
        <tr><td colspan="6" style="text-align:center;">No records found</td></tr>
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

// ✅ allows only one indent open
function toggleIndentDetails(indentNo) {
    const allDetails = document.querySelectorAll("[id^='details-']");
    allDetails.forEach(d => {
        if (d.id !== "details-" + indentNo) {
            d.classList.add("hidden");
            const icon = d.previousElementSibling.querySelector("i");
            if (icon) icon.classList.replace("fa-chevron-up", "fa-chevron-down");
        }
    });

    const details = document.getElementById("details-" + indentNo);
    if (details) {
        const icon = details.previousElementSibling.querySelector("i");
        const isHidden = details.classList.contains("hidden");
        details.classList.toggle("hidden", !isHidden ? true : false);
        if (icon) icon.classList.toggle("fa-chevron-up", isHidden);
        if (icon) icon.classList.toggle("fa-chevron-down", !isHidden);
    }
}

// SEARCH FILTERS
function filterTable() {
    const fromDate = document.getElementById("fromDate").value;
    const toDate = document.getElementById("toDate").value;
    const keyword = document.getElementById("keywordSearch").value.toLowerCase();
    const rows = document.querySelectorAll("#indentTable tbody tr.expand-row");

    rows.forEach(row => {
        const date = row.cells[2].textContent.trim();
        const text = row.textContent.toLowerCase();
        let visible = true;

        if (fromDate && date < fromDate) visible = false;
        if (toDate && date > toDate) visible = false;
        if (keyword && !text.includes(keyword)) visible = false;

        row.style.display = visible ? "" : "none";
        const details = document.getElementById("details-" + row.cells[1].textContent.trim());
        if (details) details.style.display = visible ? "" : "none";
    });
}
function resetFilters() {
    document.getElementById("fromDate").value = "";
    document.getElementById("toDate").value = "";
    document.getElementById("keywordSearch").value = "";
    document.querySelectorAll("#indentTable tbody tr").forEach(r => r.style.display = "");
}
</script>

</body>
</html>
