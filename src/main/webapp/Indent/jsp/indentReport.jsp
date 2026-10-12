<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Indent Report | PInventory</title>
  <link rel="stylesheet" href="../css/indent.css">
  <script defer src="../js/indent.js"></script>
</head>
<body>
  <header class="indent-topbar"><a class="indent-brand" href="${pageContext.request.contextPath}/Home">PInventory · Indents</a><nav class="indent-nav"><a href="${pageContext.request.contextPath}/indent/new">New indent</a><a href="${pageContext.request.contextPath}/indent/approve">Approvals</a></nav></header>
  <main class="indent-shell">
    <div class="indent-titlebar"><div><h1>Indent report</h1><p class="indent-subtitle">Track submitted indent requests and decisions.</p></div></div>
    <div class="indent-toolbar"><input class="indent-search" type="search" data-indent-filter placeholder="Search item, requester, or status" aria-label="Filter indents"></div>
    <section class="indent-panel indent-table-wrap">
      <table class="indent-table"><thead><tr><th>Reference</th><th>Request date</th><th>Item</th><th>Quantity</th><th>Requested by</th><th>Status</th></tr></thead>
        <tbody>
          <c:choose>
            <c:when test="${empty indents}"><tr><td class="indent-empty" colspan="6">No indents found.</td></tr></c:when>
            <c:otherwise><c:forEach items="${indents}" var="indent">
              <tr data-indent-row="<c:out value='${indent.indentNo}'/> <c:out value='${indent.itemName}'/> <c:out value='${indent.requestedBy}'/> <c:out value='${indent.status}'/>">
                <td><c:out value="${indent.indentNo}"/></td><td><c:out value="${indent.requestDate}"/></td><td><c:out value="${indent.itemName}"/></td><td><c:out value="${indent.quantity}"/></td><td><c:out value="${indent.requestedBy}"/></td>
                <td><span class="indent-chip ${indent.status == 'Pending' ? 'pending' : (indent.status == 'Approved' ? 'approved' : (indent.status == 'Rejected' ? 'rejected' : ''))}"><c:out value="${indent.status}"/></span></td>
              </tr>
            </c:forEach></c:otherwise>
          </c:choose>
        </tbody>
      </table>
    </section>
  </main>
</body>
</html>
