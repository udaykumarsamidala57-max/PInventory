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

String role = (String) sess.getAttribute("role");
String loginUser = (String) sess.getAttribute("username");

Map<Integer, Double> pendingMap = (Map<Integer, Double>) request.getAttribute("pendingPerItem");
if (pendingMap == null) pendingMap = new HashMap<>();

List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
if (indents == null) indents = new ArrayList<>();

Map<String, List<IndentItemFull>> grouped = new LinkedHashMap<>();
for (IndentItemFull i : indents) {
    grouped.computeIfAbsent(i.getIndentNo(), k -> new ArrayList<>()).add(i);
}
%>

<!DOCTYPE html>
<html>
<head>
<title>Approve Indent</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/CSS/approve-indent.css">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>

<body>
<%@ include file="header.jsp" %>

<script>
var LOGIN_USER = "<%= loginUser %>";
</script>

<div class="main-content">
<div class="card">
<h1>Approve Indent</h1>

<% for (Map.Entry<String,List<IndentItemFull>> e : grouped.entrySet()) {
   List<IndentItemFull> items = e.getValue();
   IndentItemFull first = items.get(0);
   String poi = first.getPurchaseorIssue();
%>

<div class="indent-card">

<div class="indent-header">
    <div class="indent-no">
        #<%= e.getKey() %>
        <% if ("Purchase".equalsIgnoreCase(poi)) { %>
            <span class="badge badge-purchase">Purchase</span>
        <% } else if ("Issue".equalsIgnoreCase(poi)) { %>
            <span class="badge badge-issue">Issue</span>
        <% } %>
    </div>
    <div><%= first.getDate() %></div>
    <div><%= first.getDepartment() %></div>
    <div><%= first.getRequestedBy() %></div>
    <div class="status-text"><%= first.getStatus() %></div>
</div>

<table class="inner-table">
<thead>
<tr>
<th>ID</th>
<th>Item</th>
<th>Avl</th>
<th>Req</th>
<th>UOM</th>
<th>Purpose</th>
<th>I/C</th>
<th>L1 Approved By</th>
<th>L2</th>
<th>Actions</th>
</tr>
</thead>

<tbody>
<% for (IndentItemFull ind : items) {
   double pending = pendingMap.getOrDefault(ind.getItemId(),0.0);
%>

<tr id="row-<%= ind.getId() %>">
<td><%= ind.getId() %></td>
<td><%= ind.getItemName() %></td>
<td><%= ind.getBalanceQty() %></td>
<td><%= ind.getQty() %></td>
<td><%= ind.getUom() %></td>
<td><%= ind.getPurpose() %></td>

<td class="ic-status">
<% if (!"Approved".equalsIgnoreCase(ind.getIstatus())) { %>
<button class="btn-green" onclick="ajaxApproveIC(<%= ind.getId() %>)">Approve</button>
<% } else { %>
<span class="approved-badge">✔ Approved</span>
<% } %>
</td>

<td class="approved-by" id="approvedBy-<%= ind.getId() %>">
<%= (ind.getApprovedBy()==null || ind.getApprovedBy().isEmpty()) ? "-" : ind.getApprovedBy() %>
</td>

<td class="l2-status"><%= ind.getStatus() %></td>

<td>
<% if ("Global".equalsIgnoreCase(role)
   && "Approved".equalsIgnoreCase(ind.getIstatus())
   && !"Approved".equalsIgnoreCase(ind.getStatus())) { %>

<div class="final-action" id="final-action-<%= ind.getId() %>">
<select id="next-<%= ind.getId() %>">
<option value="">Select</option>
<% if ("Issue".equalsIgnoreCase(poi)) { %><option value="Issue">Issue</option><% } %>
<% if ("Purchase".equalsIgnoreCase(poi)) { %><option value="PO">PO</option><% } %>
<option value="Cancelled">Cancel</option>
<option value="Management Note">Management Note</option>
</select>

<button class="btn-blue"
onclick="ajaxFinalApprove(<%= ind.getId() %>,<%= ind.getQty() %>,<%= ind.getBalanceQty() %>,<%= pending %>)">
Confirm
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

</div>
</div>

<script>
function ajaxApproveIC(id){
fetch("AIndentListServlet",{
method:"POST",
headers:{'Content-Type':'application/x-www-form-urlencoded'},
body:"action=Iapprove&id="+id
}).then(()=>{
document.querySelector("#row-"+id+" .ic-status").innerHTML = '<span class="approved-badge">✔ Approved</span>';	
document.getElementById("approvedBy-"+id).innerText = LOGIN_USER;
});
}

function ajaxFinalApprove(id,qty,balance,pending){
var next=document.getElementById("next-"+id).value;
if(!next){ alert("Select next step"); return; }

if(next==="Issue" && (pending+qty)>balance){
alert("Stock not available"); return;
}

fetch("AIndentListServlet",{
method:"POST",
headers:{'Content-Type':'application/x-www-form-urlencoded'},
body:"action=approve&id="+id+"&indentnext="+encodeURIComponent(next)
}).then(()=>{
document.querySelector("#row-"+id+" .l2-status").innerText = next;
var el=document.getElementById("final-action-"+id);
if(el) el.remove();
});
}
</script>

</body>
</html>