<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Optional: You can check session login here if needed
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String message = request.getParameter("msg");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Send Pending Indent Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f3f4f6;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 600px;
            margin: 80px auto;
            background: #fff;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            text-align: center;
        }
        h2 {
            color: #2563eb;
            font-size: 22px;
            margin-bottom: 20px;
        }
        p {
            color: #444;
            margin-bottom: 30px;
        }
        button {
            background-color: #2563eb;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            font-size: 16px;
            transition: 0.3s;
        }
        button:hover {
            background-color: #1d4ed8;
        }
        .msg {
            margin-top: 20px;
            font-weight: bold;
            color: green;
        }
        .error {
            color: red;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>📦 Pending Indent Report</h2>
        <p>Click the button below to generate and send the latest <b>Pending Indent PDF Report</b> to the management email.</p>

        <form action="SendPendingIndentPDF" method="get">
            <button type="submit">📩 Send Pending Indent Report</button>
        </form>

        <% if (message != null) { %>
            <div class="msg <%= message.contains("error") ? "error" : "" %>">
                <%= message %>
            </div>
        <% } %>
    </div>
</body>
</html>
