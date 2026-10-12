<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Store Access | PInventory</title>
  <style>
    :root { --blue:#0176d3; --blue-dark:#014486; --navy:#032d60; --ink:#181818; --muted:#5e5e5e; --line:#dddbda; --page:#f3f3f3; --white:#fff; --green:#2e844a; }
    * { box-sizing:border-box; }
    body { margin:0; background:var(--page); color:var(--ink); font:14px/1.45 "Salesforce Sans",Inter,"Segoe UI",Arial,sans-serif; }
    .topbar { height:54px; display:flex; align-items:center; justify-content:space-between; padding:0 max(18px,calc((100% - 1240px)/2)); background:var(--navy); color:#fff; }
    .brand { font-weight:700; letter-spacing:.02em; }
    .topbar a { color:#fff; text-decoration:none; font-size:13px; }
    .topbar a:hover { text-decoration:underline; }
    main { max-width:1240px; margin:22px auto; padding:0 18px 40px; }
    .titlebar { display:flex; align-items:center; justify-content:space-between; gap:16px; margin-bottom:14px; }
    h1 { margin:0; font-size:22px; font-weight:600; }
    .subtitle { margin:3px 0 0; color:var(--muted); font-size:13px; }
    .count { color:var(--muted); white-space:nowrap; }
    .toolbar { display:flex; gap:12px; align-items:center; margin:0 0 12px; }
    .search { width:min(100%,360px); height:36px; border:1px solid #c9c9c9; border-radius:4px; background:#fff; padding:0 11px; font:inherit; outline:none; }
    .search:focus { border-color:var(--blue); box-shadow:0 0 3px #0176d3a6; }
    .panel { overflow:hidden; background:var(--white); border:1px solid var(--line); border-radius:5px; box-shadow:0 2px 5px #0000000a; }
    .column-head,.user-row { display:grid; grid-template-columns:minmax(185px,1.05fr) minmax(380px,2.6fr) 138px; align-items:center; gap:18px; }
    .column-head { min-height:36px; padding:0 16px; background:#fafaf9; color:var(--muted); border-bottom:1px solid var(--line); font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.04em; }
    .user-row { padding:12px 16px; border-bottom:1px solid #ecebea; }
    .user-row:last-child { border-bottom:0; }
    .identity { min-width:0; }
    .username { font-weight:600; overflow-wrap:anywhere; }
    .meta { color:var(--muted); font-size:12px; }
    .stores { display:flex; flex-wrap:wrap; gap:6px 14px; }
    .store { display:inline-flex; align-items:center; gap:6px; color:#2e2e2e; font-size:12px; cursor:pointer; white-space:nowrap; }
    .store input { width:14px; height:14px; margin:0; accent-color:var(--blue); }
    .row-actions { display:flex; align-items:center; justify-content:flex-end; gap:8px; }
    .save { min-width:72px; border:1px solid var(--blue); border-radius:4px; background:var(--blue); color:#fff; padding:7px 12px; font:inherit; font-weight:600; font-size:12px; cursor:pointer; }
    .save:hover { background:var(--blue-dark); border-color:var(--blue-dark); }
    .save:disabled { opacity:.6; cursor:wait; }
    .status { color:var(--muted); font-size:11px; min-width:42px; text-align:right; }
    .status.ok { color:var(--green); }
    .status.fail { color:#ba0517; }
    .notice { margin:0 0 12px; padding:9px 12px; border-radius:4px; font-size:13px; }
    .notice.success { color:#194e31; background:#eaf5ee; border:1px solid #91db8b; }
    .notice.error { color:#8e030f; background:#fef1ee; border:1px solid #ea001e; }
    .empty { padding:28px; text-align:center; color:var(--muted); }
    @media(max-width:850px) {
      .column-head { display:none; }
      .user-row { grid-template-columns:minmax(0,1fr) auto; gap:8px 14px; padding:12px; }
      .identity { grid-column:1; }
      .stores { grid-column:1 / -1; grid-row:2; padding-top:4px; }
      .row-actions { grid-column:2; grid-row:1; }
    }
    @media(max-width:520px) {
      main { margin-top:16px; padding:0 10px 26px; }
      .topbar { padding:0 12px; }
      .titlebar { align-items:flex-start; }
      h1 { font-size:19px; }
      .count { font-size:12px; }
      .stores { gap:8px 12px; }
    }
  </style>
</head>
<body>
  <div class="topbar"><span class="brand">PInventory <span style="opacity:.7;font-weight:400">/ Store Access</span></span><a href="${pageContext.request.contextPath}/">Back to app</a></div>
  <main>
    <div class="titlebar">
      <p class="subtitle">Choose the stores each user can access.</p></div>
      <div class="count"><strong><c:out value="${fn:length(users)}"/></strong> users</div>
    </div>
    <c:if test="${not empty message}"><div class="notice ${messageType == 'success' ? 'success' : 'error'}" role="status"><c:out value="${message}"/></div></c:if>
    <div class="toolbar"><input class="search" id="userSearch" type="search" placeholder="Search users, roles, departments" aria-label="Search users"></div>
    <div class="panel" id="userList">
      <div class="column-head"><span>User</span><span>Assigned stores</span><span></span></div>
      <c:choose>
        <c:when test="${empty users}"><div class="empty">No users were found.</div></c:when>
        <c:otherwise>
          <c:forEach items="${users}" var="user">
            <form class="user-row assignment-form" method="post" action="${pageContext.request.contextPath}/StoreAccessAdminServlet" data-search="<c:out value="${user.username}"/> <c:out value="${user.role}"/> <c:out value="${user.department}"/>">
              <input type="hidden" name="csrfToken" value="<c:out value="${csrfToken}"/>">
              <input type="hidden" name="userId" value="<c:out value="${user.userId}"/>">
              <div class="identity"><div class="username"><c:out value="${user.username}"/></div><div class="meta">ID <c:out value="${user.userId}"/> · <c:out value="${user.role}"/><c:if test="${not empty user.department}"> · <c:out value="${user.department}"/></c:if></div></div>
              <div class="stores">
                <c:forEach items="${storeCodes}" var="code">
                  <label class="store"><input type="checkbox" name="storeCodes" value="<c:out value="${code}"/>" <c:if test="${user.storeCodeFlags[code]}">checked</c:if>><span><c:out value="${code}"/></span></label>
                </c:forEach>
              </div>
              <div class="row-actions"><span class="status" aria-live="polite"></span><button class="save" type="submit">Save</button></div>
            </form>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </div>
  </main>
  <script>
    const search = document.getElementById('userSearch');
    search.addEventListener('input', () => {
      const term = search.value.trim().toLowerCase();
      document.querySelectorAll('.assignment-form').forEach(form => {
        form.hidden = !form.dataset.search.toLowerCase().includes(term);
      });
    });

    document.querySelectorAll('.assignment-form').forEach(form => {
      form.addEventListener('change', () => {
        const status = form.querySelector('.status');
        status.textContent = 'Unsaved';
        status.className = 'status';
      });
      form.addEventListener('submit', async event => {
        event.preventDefault();
        const button = form.querySelector('.save');
        const status = form.querySelector('.status');
        button.disabled = true;
        button.textContent = 'Saving…';
        status.textContent = '';
        status.className = 'status';
        try {
          const formData = new FormData(form);
          const body = new URLSearchParams();
          formData.forEach((value, key) => body.append(key, value));
          const response = await fetch(form.action, {
            method: 'POST',
            body,
            headers: { 'X-Requested-With': 'XMLHttpRequest', 'Accept': 'application/json' },
            credentials: 'same-origin'
          });
          let result = {};
          try { result = await response.json(); } catch (_) { /* handled by response status below */ }
          if (!response.ok || result.success !== true) throw new Error(result.message || 'Could not save');
          status.textContent = 'Saved';
          status.className = 'status ok';
        } catch (error) {
          status.textContent = error.message || 'Error';
          status.className = 'status fail';
        } finally {
          button.disabled = false;
          button.textContent = 'Save';
        }
      });
    });
  </script>
</body>
</html>