<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    List<String> stores = (List<String>) request.getAttribute("stores");
    String error = (String) request.getAttribute("error");
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
    <form action="<%= request.getContextPath() %>/SelectStoreServlet" method="post">
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
</body>
</html>
