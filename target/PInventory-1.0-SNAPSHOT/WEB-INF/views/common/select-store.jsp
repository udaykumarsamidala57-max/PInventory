<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    List<String> stores = (List<String>) request.getAttribute("stores");
    String error = (String) request.getAttribute("error");
    boolean showAndroidAppPopup = Boolean.TRUE.equals(session.getAttribute("showAndroidAppPopup"));
    if (showAndroidAppPopup) session.removeAttribute("showAndroidAppPopup");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Select Store | Office Central ERP</title>
    <style>
        * { box-sizing: border-box; }
        body { min-height: 100vh; margin: 0; display: grid; place-items: center; padding: 24px; background: #f3f6fb; color: #182230; font-family: Arial, sans-serif; }
        .card { width: min(100%, 460px); padding: 32px; border: 1px solid #e1e7ef; border-radius: 16px; background: #fff; box-shadow: 0 16px 40px rgba(25, 45, 75, .10); }
        h1 { margin: 0 0 8px; font-size: 25px; }
        .intro { margin: 0 0 24px; color: #5b6573; line-height: 1.5; }
        .error { margin: 0 0 16px; padding: 11px 13px; border-radius: 8px; background: #fff1f0; color: #a12622; }
        .options { display: grid; gap: 10px; margin: 0 0 20px; padding: 0; border: 0; }
        .option { display: flex; align-items: center; gap: 12px; padding: 14px; border: 1px solid #dce3ed; border-radius: 9px; cursor: pointer; }
        .option:has(input:checked) { border-color: #1769aa; background: #f2f8fd; }
        .option input { accent-color: #1769aa; }
        .sr-only { position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0); white-space: nowrap; border: 0; }
        button { width: 100%; padding: 13px 16px; border: 0; border-radius: 8px; background: #1769aa; color: #fff; font-weight: 700; cursor: pointer; }
        button:disabled { background: #9aa8b7; cursor: not-allowed; }
        .logout { display: block; margin-top: 18px; color: #536273; text-align: center; text-decoration: none; }
    </style>
</head>
<body>
<main class="card">
    <h1>Select a Store</h1>
    <p class="intro">Signed in as <strong><c:out value="${username}" default="user"/></strong>. Choose the store database for this session.</p>
    <% if (error != null) { %><p class="error" role="alert"><c:out value="${error}"/></p><% } %>
    <form action="<%= request.getContextPath() %>/select-store" method="post">
        <fieldset class="options">
            <legend class="sr-only">Available stores</legend>
            <c:forEach items="${stores}" var="store">
                <label class="option">
                    <input type="radio" name="store" value="${store}" required <c:if test="${store eq selectedStore}">checked</c:if>>
                    <span><c:out value="${store}"/></span>
                </label>
            </c:forEach>
        </fieldset>
        <% if (stores == null || stores.isEmpty()) { %><p class="intro">No stores are assigned to your account.</p><% } %>
        <button type="submit" <%= stores == null || stores.isEmpty() ? "disabled" : "" %>>Connect and continue</button>
    </form>
    <a class="logout" href="<%= request.getContextPath() %>/Logout.jsp">Sign out</a>
</main>
<% if (showAndroidAppPopup) { %>
<div class="login-app-overlay" id="loginAppDownloadPopup" onclick="if(event.target===this)closeLoginAppPopup()">
  <section class="login-app-dialog" role="dialog" aria-modal="true" aria-label="Download Android App">
    <button type="button" class="login-app-close" onclick="closeLoginAppPopup()" aria-label="Close download dialog">×</button>
    <img class="login-app-logo" src="<%= request.getContextPath() %>/assets/branding/office-central-ofc.png" alt="Office Central OFC">

    <p id="loginAppDescription" class="login-app-description"><svg class="android-mini-icon" viewBox="0 0 24 24" aria-hidden="true"><g fill="currentColor"><path d="M6 9a6 6 0 0 1 12 0H6Z"/><circle cx="9" cy="6.6" r=".65" fill="#fff"/><circle cx="15" cy="6.6" r=".65" fill="#fff"/><rect x="7" y="10" width="10" height="7" rx="1.4"/><rect x="4.5" y="10.5" width="2" height="6" rx="1"/><rect x="17.5" y="10.5" width="2" height="6" rx="1"/><rect x="8" y="16" width="2.4" height="4" rx="1.1"/><rect x="13.6" y="16" width="2.4" height="4" rx="1.1"/></g><path d="M8.5 4.5 7.2 2.8M15.5 4.5l1.3-1.7" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round"/></svg>Download Android App</p>
    <a class="login-app-download" href="<%= request.getContextPath() %>/mobile-app/pinventory.apk" download="OFC-ERP.apk">↓&nbsp; Download Android App</a>
    <button type="button" class="login-app-later" onclick="closeLoginAppPopup()">Maybe later</button>
  </section>
</div>
<style>
  .login-app-overlay{position:fixed;z-index:3000;inset:0;display:grid;place-items:center;padding:20px;background:rgba(13,29,48,.58);backdrop-filter:blur(3px);animation:loginAppFade .2s ease-out}
  .login-app-dialog{position:relative;box-sizing:border-box;width:min(100%,370px);padding:30px;border:1px solid #e3eaf2;border-radius:18px;background:#fff;box-shadow:0 24px 70px rgba(8,27,48,.28);color:#16324f;text-align:center;animation:loginAppRise .24s ease-out}
  .login-app-close{position:absolute;top:12px;right:12px;display:grid;place-items:center;width:32px;height:32px;border:0;border-radius:9px;background:#f2f5f8;color:#627487;cursor:pointer;font-size:17px}
  .login-app-logo{display:block;width:min(100%,190px);height:auto;margin:0 auto 12px;animation:loginAppLogo 2.5s ease-in-out infinite}
  .login-app-description{display:flex;align-items:center;justify-content:center;gap:7px;margin:0 0 18px;color:#64788c;font-size:12px;font-weight:600}
  .login-app-description .android-mini-icon{width:22px;height:22px;flex:none;color:#2e9c58;animation:loginAndroidMove 1.8s ease-in-out infinite}
  .login-app-dialog p{margin:0 0 18px;color:#64788c;font-size:12px}
  .login-app-download{display:flex;align-items:center;justify-content:center;min-height:44px;border-radius:10px;background:#1266a8;color:#fff;text-decoration:none;font-size:13px;font-weight:700;transition:background .18s,transform .18s}
  .login-app-download:hover{background:#0c528b;transform:translateY(-1px)}
  .login-app-later{display:block;margin:10px auto 0;padding:7px 12px;border:0;background:transparent;color:#627487;cursor:pointer;font:600 13px Arial,sans-serif}
  .login-app-dialog button:focus-visible,.login-app-download:focus-visible{outline:3px solid rgba(1,118,211,.35);outline-offset:2px}
  @keyframes loginAppFade{from{opacity:0}to{opacity:1}}
  @keyframes loginAppRise{from{opacity:0;transform:translateY(8px) scale(.985)}to{opacity:1;transform:translateY(0) scale(1)}}
  @keyframes loginAppLogo{0%,100%{transform:translateY(0)}50%{transform:translateY(-3px)}}
  @keyframes loginAndroidMove{0%,100%{transform:translateY(0) rotate(-2deg)}50%{transform:translateY(-3px) rotate(2deg)}}
  @media(prefers-reduced-motion:reduce){.login-app-overlay,.login-app-dialog,.login-app-logo,.login-app-description .android-mini-icon,.login-app-download{animation:none;transition:none}}
</style>
<script>
  function closeLoginAppPopup(){var popup=document.getElementById('loginAppDownloadPopup');if(popup)popup.remove();}
  document.addEventListener('keydown',function(event){if(event.key==='Escape')closeLoginAppPopup();});
  document.getElementById('loginAppDownloadPopup').querySelector('.login-app-close').focus();
</script>
<% } %>
</body>
</html>
