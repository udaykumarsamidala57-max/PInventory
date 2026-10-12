<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Assign Stores | PInventory</title>
  <style>
    :root { color-scheme: light; --navy:#12345a; --blue:#1769aa; --ink:#192b3c; --muted:#667789; --line:#dce4ec; --bg:#f3f6f9; }
    * { box-sizing:border-box; }
    body { margin:0; background:var(--bg); color:var(--ink); font:15px/1.5 Inter,Segoe UI,Arial,sans-serif; }
    .topbar { background:var(--navy); color:#fff; padding:14px max(22px,calc((100% - 1180px)/2)); display:flex; justify-content:space-between; align-items:center; }
    .topbar strong { font-size:16px; letter-spacing:.02em; }
    .topbar a { color:#fff; text-decoration:none; opacity:.9; }
    main { max-width:1180px; margin:34px auto; padding:0 20px 50px; }
    .intro { display:flex; align-items:flex-end; justify-content:space-between; gap:20px; margin-bottom:22px; }
    h1 { margin:0 0 5px; font-size:28px; letter-spacing:-.03em; }
    .intro p { margin:0; color:var(--muted); }
    .count { white-space:nowrap; color:var(--muted); font-size:14px; }
    .notice { padding:12px 15px; border-radius:8px; margin:0 0 18px; }
    .success { background:#e8f6ee; color:#17643a; border:1px solid #c6e8d2; }
    .error { background:#fff0ed; color:#9b2c20; border:1px solid #f2c9c2; }
    .toolbar { margin-bottom:16px; }
    .toolbar input { width:min(100%,440px); padding:11px 13px; border:1px solid var(--line); border-radius:8px; font:inherit; background:#fff; }
    .user-card { background:#fff; border:1px solid var(--line); border-radius:12px; padding:20px; margin:0 0 14px; box-shadow:0 3px 12px #18324a0a; }
    .user-head { display:flex; align-items:flex-start; justify-content:space-between; gap:18px; padding-bottom:15px; border-bottom:1px solid #edf1f5; }
    .identity { min-width:0; }
    .identity h2 { font-size:18px; margin:0 0 3px; overflow-wrap:anywhere; }
    .meta { color:var(--muted); font-size:13px; }
    .store-list { display:grid; grid-template-columns:repeat(auto-fit,minmax(190px,1fr)); gap:9px; padding:16px 0; }
    .store-option { display:flex; align-items:center; gap:9px; padding:10px 11px; border:1px solid var(--line); border-radius:8px; cursor:pointer; min-height:42px; }
    .store-option:hover { border-color:#91b5d4; background:#f8fbfe; }
    .store-option input { accent-color:var(--blue); width:17px; height:17px; margin:0; }
    .actions { display:flex; align-items:center; justify-content:space-between; gap:12px; }
    .help { color:var(--muted); font-size:12px; }
    button { border:0; border-radius:7px; padding:10px 16px; color:#fff; background:var(--blue); font:inherit; font-weight:600; font-size:14px; cursor:pointer; }
    button:hover { background:#10578f; }
    .empty { padding:34px; text-align:center; color:var(--muted); background:white; border:1px solid var(--line); border-radius:12px; }
    @media(max-width:650px) { main { margin-top:23px; padding:0 13px 35px; } .intro { align-items:flex-start; flex-direction:column; gap:5px; } .user-card { padding:15px; } .user-head { flex-direction:column; gap:7px; } .store-list { grid-template-columns:1fr 1fr; } }
    @media(max-width:390px) { .store-list { grid-template-columns:1fr; } .actions { align-items:flex-start; flex-direction:column; } }
  </style>
</head>
<body>
  <div class="topbar"><strong>PInventory · Store access</strong><a href="${pageContext.request.contextPath}/">Back to app</a></div>
  <main>
    <div class="intro">
      <div><h1>Assign stores to users</h1><p>Choose which stores each user can access when signing in.</p></div>
      <div class="count"><c:out value="${users.size()}"/> users</div>
    </div>
    <c:if test="${not empty message}"><div class="notice ${messageType == 'success' ? 'success' : 'error'}"><c:out value="${message}"/></div></c:if>
    <div class="toolbar"><input id="userSearch" type="search" placeholder="Search by user, role, or department" aria-label="Search users"></div>
    <c:choose>
      <c:when test="${empty users}"><div class="empty">No users were found.</div></c:when>
      <c:otherwise>
        <c:forEach items="${users}" var="user">
          <section class="user-card" data-search="<c:out value='${user.username}'/> <c:out value='${user.role}'/> <c:out value='${user.department}'/>">
            <form method="post" action="${pageContext.request.contextPath}/StoreAccessAdminServlet">
              <input type="hidden" name="csrfToken" value="<c:out value='${csrfToken}'/>">
              <input type="hidden" name="userId" value="<c:out value='${user.userId}'/>">
              <div class="user-head">
                <div class="identity">
                  <h2><c:out value="${user.username}"/></h2>
                  <div class="meta">User ID <c:out value="${user.userId}"/> · <c:out value="${user.role}"/><c:if test="${not empty user.department}"> · <c:out value="${user.department}"/></c:if></div>
                </div>
              </div>
              <div class="store-list">
                <c:forEach items="${storeCodes}" var="code">
                  <label class="store-option"><input type="checkbox" name="storeCodes" value="<c:out value='${code}'/>" <c:if test="${user.storeCodes.contains(code)}">checked</c:if>><span><c:out value="${code}"/></span></label>
                </c:forEach>
              </div>
              <div class="actions"><span class="help">Saving replaces this user’s current store assignments.</span><button type="submit">Save assignments</button></div>
            </form>
          </section>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </main>
  <script>
    const search = document.getElementById('userSearch');
    search.addEventListener('input', () => {
      const term = search.value.trim().toLowerCase();
      document.querySelectorAll('.user-card').forEach(card => {
        card.hidden = !card.dataset.search.toLowerCase().includes(term);
      });
    });
  </script>
</body>
</html>
