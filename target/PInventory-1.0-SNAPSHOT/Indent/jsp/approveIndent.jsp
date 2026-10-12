<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Approve Indents | PInventory</title>
  <link rel="stylesheet" href="../css/indent.css">
  <script defer src="../js/indent.js"></script>
</head>
<body>
  <header class="indent-topbar"><a class="indent-brand" href="${pageContext.request.contextPath}/Home">PInventory · Indents</a><nav class="indent-nav"><a href="${pageContext.request.contextPath}/indent/new">New indent</a><a href="${pageContext.request.contextPath}/indent/report">Indent report</a></nav></header>
  <main class="indent-shell">
    <div class="indent-titlebar"><div><h1>Indent approvals</h1><p class="indent-subtitle">Approve or reject requests waiting for a decision.</p></div></div>
    <div class="indent-message" data-indent-message role="status" aria-live="polite"></div>
    <section class="indent-panel indent-table-wrap">
      <table class="indent-table"><thead><tr><th>Reference</th><th>Date</th><th>Item</th><th>Quantity</th><th>Requester</th><th>Purpose</th><th>Decision</th></tr></thead>
        <tbody data-approval-body>
          <c:choose>
            <c:when test="${empty indents}"><tr><td class="indent-empty" colspan="7">No indents are waiting for approval.</td></tr></c:when>
            <c:otherwise><c:forEach items="${indents}" var="indent">
              <tr>
                <td><c:out value="${indent.indentNo}"/></td><td><c:out value="${indent.requestDate}"/></td><td><c:out value="${indent.itemName}"/></td><td><c:out value="${indent.quantity}"/></td><td><c:out value="${indent.requestedBy}"/><div class="indent-help"><c:out value="${indent.department}"/></div></td><td><c:out value="${indent.purpose}"/></td>
                <td><form class="row-actions" method="post" action="${pageContext.request.contextPath}/indent/approve" data-approval-form><input type="hidden" name="csrfToken" value="<c:out value='${csrfToken}'/>"><input type="hidden" name="indentId" value="<c:out value='${indent.indentId}'/>"><input type="hidden" name="decision" value=""><button class="indent-button" type="button" data-decision="Approved">Approve</button><button class="indent-button danger" type="button" data-decision="Rejected">Reject</button></form></td>
              </tr>
            </c:forEach></c:otherwise>
          </c:choose>
        </tbody>
      </table>
    </section>
  </main>
</body>
</html>
