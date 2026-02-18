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
    
    if (!"Global".equalsIgnoreCase(role) && !"Incharge".equalsIgnoreCase(role) && !"Admin".equalsIgnoreCase(role)) {
        response.setContentType("text/html");
        response.getWriter().println("<h3 style='color:red;'>Access Denied</h3>");
        return;
    }

    Map<Integer, Double> pendingMap = (Map<Integer, Double>) request.getAttribute("pendingPerItem");
    if (pendingMap == null) pendingMap = new HashMap<>();

    List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
    if (indents == null) indents = new ArrayList<>();

    Map<String, List<IndentItemFull>> groupedIndents = new LinkedHashMap<>();
    for (IndentItemFull i : indents) {
        groupedIndents.computeIfAbsent(i.getIndentNo(), k -> new ArrayList<>()).add(i);
    }

    List<Map.Entry<String, List<IndentItemFull>>> sortedIndents = new ArrayList<>(groupedIndents.entrySet());
    Collections.sort(sortedIndents, (a, b) -> {
        boolean aPending = a.getValue().stream().anyMatch(i -> i.getIndentNext() == null || i.getIndentNext().trim().isEmpty());
        boolean bPending = b.getValue().stream().anyMatch(i -> i.getIndentNext() == null || i.getIndentNext().trim().isEmpty());
        return aPending == bPending ? 0 : (aPending ? -1 : 1); 
    });
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Approve Indent </title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="CSS/approve-indent.css">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<style>
    /* Required for AJAX features not covered by the external CSS */
    .loading-overlay { display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.7); z-index:9999; justify-content:center; align-items:center; }
    .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; width: 30px; height: 30px; animation: spin 1s linear infinite; }
    @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
    .dropdown-container { display: none; margin-top: 8px; padding: 10px; background: #f8fafc; border-top: 1px solid #e2e8f0; }
    .filter-bar button { margin-left: 10px; }
    .filter-input { padding: 8px 12px; border-radius: 6px; border: 1px solid #cfd8dc; font-size: 14px; }
    .cancelled-row td { background-color: #ffe6e6 !important; text-decoration: line-through; color: #94a3b8 !important; }
</style>
</head>

<body>
<%@ include file="header.jsp" %>
<div id="loadingOverlay" class="loading-overlay"><div class="spinner"></div></div>

<div class="main-content">
<div class="card">
    <h1><i class="fa-solid fa-file-signature"></i> Approve Indent Dining Hall & RO Plant Indents</h1>

    <div class="filter-bar" style="background: #ffffff; padding: 15px 20px; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 25px; display: flex; align-items: center; justify-content: space-between;">
        <div style="display: flex; gap: 10px; align-items: center;">
            <label style="font-size: 13px; font-weight: 600;">From:</label><input type="date" id="fromDate" class="filter-input">
            <label style="font-size: 13px; font-weight: 600;">To:</label><input type="date" id="toDate" class="filter-input">
            <input type="text" id="keywordSearch" placeholder="🔍 Search item or dept..." class="filter-input" style="width: 250px;">
        </div>
        <div>
            <button onclick="filterTable()" class="btn-blue"><i class="fa-solid fa-search"></i> Search</button>
            <button onclick="resetFilters()" style="background: #64748b; color: white;" class="btn-blue">Reset</button>
        </div>
    </div>

    <% for (Map.Entry<String, List<IndentItemFull>> entry : sortedIndents) {
        String indentNo = entry.getKey();
        List<IndentItemFull> items = entry.getValue();
        IndentItemFull first = items.get(0);
        boolean isPurchase = items.stream().anyMatch(i -> "Purchase".equalsIgnoreCase(i.getPurchaseorIssue()));
        boolean isIssue = items.stream().anyMatch(i -> "Issue".equalsIgnoreCase(i.getPurchaseorIssue()));
    %>

    <div class="indent-card">
        <div class="indent-header">
            <div class="indent-no">
                #<%= indentNo %>
                <% if (isPurchase) { %><span class="badge badge-purchase" style="margin-left: 10px;">Purchase</span><% } 
                   else if (isIssue) { %><span class="badge badge-issue" style="margin-left: 10px;">Issue</span><% } %>
            </div>
            <div><i class="fa-regular fa-calendar-days"></i> <%= first.getDate() %></div>
            <div><i class="fa-solid fa-sitemap"></i> <%= first.getDepartment() %></div>
            <div><i class="fa-solid fa-user-pen"></i> <%= first.getRequestedBy() %></div>
            <div><span class="approved-badge"><%= first.getStatus() %></span></div>
        </div>

        <table class="inner-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Item Description</th>
                    <th>Avl</th>
                    <th>Req</th>
                    <th>UOM</th>
                    <th>Purpose</th>
                    <th>I/C Action</th>
                    <th>L1 Status</th>
                    <th>L2 Status</th>
                    <th>Final Action</th>
                </tr>
            </thead>
            <tbody>
<%
    for (IndentItemFull ind : items) {
        String I_Status = ind.getIstatus() != null ? ind.getIstatus().trim() : "";
        String status = ind.getStatus() != null ? ind.getStatus().trim() : "";
        Integer itemId = ind.getItemId();
        double pendingValue = (itemId != null && pendingMap.get(itemId) != null) ? pendingMap.get(itemId) : 0.0;
%>
<tr id="row-<%= ind.getId() %>" class="<%= "Cancelled".equalsIgnoreCase(status) ? "cancelled-row" : "" %>">
    <td><%= ind.getId() %></td>
    <td><%= ind.getItemName() %></td>
    <td><%= ind.getBalanceQty() %></td>
    <td><%= ind.getQty() %></td>
    <td><%= ind.getUom() %></td>
    <td><%= ind.getPurpose() %></td>

    <td id="ic-cell-<%= ind.getId() %>">
        <% if (("Incharge".equalsIgnoreCase(role) || "Admin".equalsIgnoreCase(role) || "Global".equalsIgnoreCase(role)) && !"Approved".equalsIgnoreCase(I_Status)) { %>
            <button class="btn-green" type="button" onclick="submitAjaxAction(<%= ind.getId() %>, 'Iapprove')"><i class="fa-solid fa-check"></i>Approve</button>
        <% } %>
    </td>

    <td id="l1-cell-<%= ind.getId() %>"><%= I_Status %></td>
    <td id="l2-cell-<%= ind.getId() %>"><%= status %></td>

    <td id="action-cell-<%= ind.getId() %>">
        <% if (("Global".equalsIgnoreCase(role) || "A_Veeresh".equalsIgnoreCase(user)) && "Approved".equalsIgnoreCase(I_Status) && !"Approved".equalsIgnoreCase(status)) { %>
            <div class="final-action">
                <div class="final-form" id="form-data-<%= ind.getId() %>" 
                     data-qty="<%= ind.getQty() %>" data-balance="<%= ind.getBalanceQty() %>" 
                     data-pending="<%= pendingValue %>" data-poi="<%= ind.getPurchaseorIssue() %>">
                    
                    <select id="select-<%= ind.getId() %>">
                        <option value="">--Action--</option>
                        <% if ("Issue".equalsIgnoreCase(ind.getPurchaseorIssue())) { %><option value="Issue">Issue</option><% } %>
                        <% if ("Purchase".equalsIgnoreCase(ind.getPurchaseorIssue())) { %><option value="PO">PO</option><% } %>
                        <option value="Cancelled">Cancel</option>
                        <option value="Management Note">Mgt Note</option>
                    </select>
                    <button class="btn-blue" type="button" onclick="handleFinalApproval(<%= ind.getId() %>)">Confirm</button>
                </div>
            </div>
        <% } else if ("Approved".equalsIgnoreCase(status)) { %>
            <span style="color:#10b981; font-weight: 700;"><i class="fa-solid fa-circle-check"></i> CLOSED</span>
        <% } %>
    </td>
</tr>
<% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</div>
</div>

<script>
async function submitAjaxAction(id, action, additional = {}) {
    document.getElementById("loadingOverlay").style.display = "flex";
    const params = new URLSearchParams();
    params.append('id', id);
    params.append('action', action);
    for (let key in additional) params.append(key, additional[key]);

    try {
        const response = await fetch('DIndentListServlet', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: params
        });

        if(response.ok) {
            if(action === 'Iapprove') {
                document.getElementById('ic-cell-'+id).innerHTML = "";
                document.getElementById('l1-cell-'+id).innerText = "Approved";
            } else if(action === 'approve') {
                document.getElementById('l2-cell-'+id).innerText = "Approved";
                document.getElementById('action-cell-'+id).innerHTML = "<span style='color:#10b981; font-weight:700;'><i class='fa-solid fa-circle-check'></i> CLOSED</span>";
                if(additional.indentnext === 'Cancelled') {
                    document.getElementById('row-'+id).classList.add('cancelled-row');
                }
            }
        } else { alert("Failed to update."); }
    } catch (e) { alert("Network error."); }
    finally { document.getElementById("loadingOverlay").style.display = "none"; }
}

function handleFinalApproval(id) {
    const dataDiv = document.getElementById('form-data-'+id);
    const qty = parseFloat(dataDiv.dataset.qty);
    const balance = parseFloat(dataDiv.dataset.balance);
    const pending = parseFloat(dataDiv.dataset.pending);
    const next = document.getElementById('select-'+id).value;

    if(!next) return alert("Select a step");
    if(next === "Issue" && (pending + qty) > balance) {
        return alert("⚠️ Insufficient Stock.\nAvailable: " + balance + "\nRequired: " + (pending + qty));
    }
    submitAjaxAction(id, 'approve', { indentnext: next });
}

function filterTable(){
    const keyword = document.getElementById("keywordSearch").value.toLowerCase();
    document.querySelectorAll(".indent-card").forEach(card => {
        card.style.display = card.innerText.toLowerCase().includes(keyword) ? "" : "none";
    });
}

function resetFilters() { location.reload(); }
</script>
</body>
</html>