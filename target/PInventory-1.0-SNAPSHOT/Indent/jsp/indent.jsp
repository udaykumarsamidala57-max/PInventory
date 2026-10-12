<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>New Indent | PInventory</title>
  <link rel="stylesheet" href="../css/indent.css">
  <script defer src="../js/indent.js"></script>
</head>
<body>
  <header class="indent-topbar">
    <a class="indent-brand" href="${pageContext.request.contextPath}/Home">PInventory · Indents</a>
    <nav class="indent-nav"><a href="${pageContext.request.contextPath}/indent/report">My indents</a><a href="${pageContext.request.contextPath}/indent/approve">Approvals</a></nav>
  </header>
  <main class="indent-shell">
    <div class="indent-titlebar"><div><h1>New indent</h1><p class="indent-subtitle">Request stock or raise a purchase indent.</p></div></div>
    <div class="indent-message" data-indent-message role="status" aria-live="polite"></div>
    <section class="indent-panel">
      <div class="indent-panel-head">Request details</div>
      <div class="indent-panel-body">
        <form action="${pageContext.request.contextPath}/indent/create" method="post" data-indent-create>
          <input type="hidden" name="csrfToken" value="<c:out value='${csrfToken}'/>">
          <div class="indent-grid">
            <div class="indent-field"><label for="requestDate">Request date</label><input id="requestDate" name="requestDate" type="date" required></div>
            <div class="indent-field"><label for="requestedBy">Requested by</label><input id="requestedBy" value="<c:out value='${requestedBy}'/>" readonly></div>
            <div class="indent-field"><label for="itemId">Inventory item</label><select id="itemId" name="itemId" data-inventory-endpoint="${pageContext.request.contextPath}/inventory/items" required disabled><option value="">Loading inventory…</option></select><span class="indent-help">Stock and price are loaded from this store’s inventory.</span></div>
            <div class="indent-field"><label for="quantity">Quantity</label><input id="quantity" name="quantity" type="number" min="0.01" step="0.01" required></div>
            <div class="indent-field"><label for="indentType">Request type</label><select id="indentType" name="indentType" required><option value="">Choose type</option><option value="Issue">Issue from stock</option><option value="Purchase">Purchase</option></select></div>
            <div class="indent-field"><label for="purpose">Purpose</label><input id="purpose" name="purpose" maxlength="500" placeholder="Reason for this request"></div>
          </div>
          <div class="indent-actions"><button class="indent-button" type="submit">Submit indent</button></div>
        </form>
      </div>
    </section>
  </main>
</body>
</html>
