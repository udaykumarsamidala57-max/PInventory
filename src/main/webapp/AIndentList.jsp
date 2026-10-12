<%@ page import="java.util.*, com.bean.IndentItemFull" %>
<%@ page import="javax.servlet.http.HttpSession" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>

<%!
// minimal HTML escaping for values printed into the page
private static String esc(Object o) {
    if (o == null) return "";
    return String.valueOf(o).replace("&","&amp;").replace("<","&lt;")
           .replace(">","&gt;").replace("\"","&quot;");
}
%>

<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String role = (String) sess.getAttribute("role");
String loginUser = (String) sess.getAttribute("username");

Map<Integer, Double> pendingMap = (Map<Integer, Double>) request.getAttribute("pendingPerItem");
if (pendingMap == null) pendingMap = new HashMap<>();

List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
if (indents == null) indents = new ArrayList<>();

// Split into Purchase (left) and Issue (right), grouped by indent no
Map<String, List<IndentItemFull>> purchaseGroups = new LinkedHashMap<>();
Map<String, List<IndentItemFull>> issueGroups    = new LinkedHashMap<>();
for (IndentItemFull i : indents) {
    if ("Issue".equalsIgnoreCase(i.getPurchaseorIssue())) {
        issueGroups.computeIfAbsent(i.getIndentNo(), k -> new ArrayList<>()).add(i);
    } else {
        purchaseGroups.computeIfAbsent(i.getIndentNo(), k -> new ArrayList<>()).add(i);
    }
}

List<Map<String, List<IndentItemFull>>> panes = new ArrayList<>();
panes.add(purchaseGroups);
panes.add(issueGroups);
String[] paneTitles  = {"Purchase Indents", "Issue Indents"};
String[] paneClasses = {"pane-purchase", "pane-issue"};
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Approve Indent</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="<%= request.getContextPath() %>/CSS/approve-indent.css">
</head>

<body>
<%@ include file="header.jsp" %>

<script>
var LOGIN_USER = "<%= esc(loginUser) %>";
</script>

<div class="main-content">
<div class="card">
<div class="split">

<% for (int p = 0; p < panes.size(); p++) {
     Map<String, List<IndentItemFull>> groups = panes.get(p);
%>
<section class="pane <%= paneClasses[p] %>">

    <div class="pane-title">
        <h2><%= paneTitles[p] %></h2>
        <span class="pane-count"><%= groups.size() %></span>
    </div>

    <% if (groups.isEmpty()) { %>
        <div class="empty-state">No <%= p == 0 ? "purchase" : "issue" %> indents</div>
    <% } %>

    <% for (Map.Entry<String, List<IndentItemFull>> e : groups.entrySet()) {
         List<IndentItemFull> items = e.getValue();
         IndentItemFull first = items.get(0);
         String poi = first.getPurchaseorIssue();
         String hStatus = first.getStatus() == null ? "" : first.getStatus();
    %>

    <div class="indent-card">

        <div class="indent-header">
            <span class="indent-no">#<%= esc(e.getKey()) %></span>
            <span class="meta"><%= esc(first.getDate()) %></span>
            <span class="meta"><b><%= esc(first.getDepartment()) %></b></span>
            <span class="meta"><%= esc(first.getRequestedBy()) %></span>
            <span class="status-text"><span class="pill" data-s="<%= esc(hStatus.toLowerCase()) %>"><%= esc(hStatus) %></span></span>
        </div>

        <table class="inner-table">
        <thead>
        <tr>
            <th>Item</th>
            <th>Avl</th>
            <th>Req</th>
            <th>Purpose</th>
            <th>L1 Approval</th>
            <th>L2 / Action</th>
        </tr>
        </thead>

        <tbody>
        <% for (IndentItemFull ind : items) {
             double pending = pendingMap.getOrDefault(ind.getItemId(), 0.0);
             String l2 = ind.getStatus() == null ? "" : ind.getStatus();
             String l1 = ind.getIstatus() == null ? "" : ind.getIstatus();
             String by = (ind.getApprovedBy() == null || ind.getApprovedBy().isEmpty()) ? "" : ind.getApprovedBy();
             String nextAction = "Issue".equalsIgnoreCase(poi) ? "Issue" : "PO";
        %>

        <tr id="row-<%= ind.getId() %>">
            <td>
                <div class="item-name" title="<%= esc(ind.getItemName()) %>"><%= esc(ind.getItemName()) %></div>
                <div class="item-id">ID <%= ind.getId() %></div>
            </td>

            <td><%= ind.getBalanceQty() %></td>

            <td><span class="req"><%= ind.getQty() %></span><span class="uom"><%= esc(ind.getUom()) %></span></td>

            <td class="purpose" title="<%= esc(ind.getPurpose()) %>"><%= esc(ind.getPurpose()) %></td>

            <td>
                <span class="ic-status">
                <% if ("Approved".equalsIgnoreCase(l1)) { %>
                    <span class="approved-badge">&#10004; Approved</span>
                <% } else if ("Rejected".equalsIgnoreCase(l1)) { %>
                    <span class="rejected-badge">&#10008; Rejected</span>
                <% } else { %>
                    <button class="btn-green" onclick="ajaxApproveIC(<%= ind.getId() %>, 'Approved')">Approve</button>
                    <button class="btn-red" onclick="ajaxApproveIC(<%= ind.getId() %>, 'Rejected')">Reject</button>
                <% } %>
                </span>
                <span class="approved-by" id="approvedBy-<%= ind.getId() %>"><%= by.isEmpty() ? "" : esc(by) %></span>
            </td>

            <td>
                <span class="pill l2-status" data-s="<%= esc(l2.toLowerCase()) %>"><%= esc(l2) %></span>

                <% if ("Global".equalsIgnoreCase(role)
                       && "Approved".equalsIgnoreCase(ind.getIstatus())
                       && !"Approved".equalsIgnoreCase(ind.getStatus())
                       && !"Rejected".equalsIgnoreCase(ind.getStatus())
                       && !"Issue".equalsIgnoreCase(ind.getStatus())
                       && !"PO".equalsIgnoreCase(ind.getStatus())) { %>
                <div class="final-action" id="final-action-<%= ind.getId() %>">
                    <button class="btn-blue"
                        onclick="ajaxFinalApprove(<%= ind.getId() %>, '<%= nextAction %>', <%= ind.getQty() %>, <%= ind.getBalanceQty() %>, <%= pending %>)">
                        <%= nextAction %>
                    </button>
                    <button class="btn-red"
                        onclick="ajaxFinalApprove(<%= ind.getId() %>, 'Rejected', <%= ind.getQty() %>, <%= ind.getBalanceQty() %>, <%= pending %>)">
                        Reject
                    </button>
                </div>
                <% } %>
            </td>
        </tr>

        <% } %>
        </tbody>
        </table>
    </div>

    <% } %>
</section>
<% } %>

</div>
</div>
</div>

<script>
function ajaxApproveIC(id, status){
    fetch("AIndentListServlet",{
        method:"POST",
        headers:{'Content-Type':'application/x-www-form-urlencoded'},
        body:"action=Iapprove&id="+id+"&status="+encodeURIComponent(status)
    }).then(function(){
        if(status === 'Approved'){
            document.querySelector("#row-"+id+" .ic-status").innerHTML = '<span class="approved-badge">&#10004; Approved</span>';
        } else {
            document.querySelector("#row-"+id+" .ic-status").innerHTML = '<span class="rejected-badge">&#10008; Rejected</span>';
        }
        document.getElementById("approvedBy-"+id).innerText = LOGIN_USER;
    }).catch(function(){ alert("Action failed. Please try again."); });
}

function ajaxFinalApprove(id, next, qty, balance, pending){
    if(next === "Issue" && (pending + qty) > balance){
        alert("Stock not available"); return;
    }

    fetch("AIndentListServlet",{
        method:"POST",
        headers:{'Content-Type':'application/x-www-form-urlencoded'},
        body:"action=approve&id="+id+"&indentnext="+encodeURIComponent(next)
    }).then(function(){
        var pill = document.querySelector("#row-"+id+" .l2-status");
        pill.innerText = next;
        pill.setAttribute("data-s", next.toLowerCase());
        var el = document.getElementById("final-action-"+id);
        if(el) el.remove();
    }).catch(function(){ alert("Action failed. Please try again."); });
}
</script>

</body>
</html>