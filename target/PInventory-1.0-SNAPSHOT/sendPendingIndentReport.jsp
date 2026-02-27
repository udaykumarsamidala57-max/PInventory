<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Send Pending Indent Report</title>
    <style>
        body {
            font-family: 'Poppins', sans-serif;
            background: #f3f4f6;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 550px;
            margin: 80px auto;
            background: #fff;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 6px 14px rgba(0,0,0,0.1);
            text-align: center;
        }
        h2 {
            color: #2563eb;
            font-size: 24px;
            margin-bottom: 10px;
        }
        p {
            color: #444;
            margin-bottom: 25px;
        }
        input[type="email"] {
            width: 80%;
            padding: 10px;
            border: 1px solid #ccc;
            border-radius: 6px;
            font-size: 15px;
            margin-bottom: 15px;
        }
        button {
            background-color: #2563eb;
            color: white;
            border: none;
            padding: 12px 25px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            font-size: 16px;
            transition: 0.3s;
        }
        button:hover {
            background-color: #1d4ed8;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>📦 Send Pending Indent Report</h2>
        <p>Enter the management’s email address to send the <b>Pending Indent PDF</b> automatically.</p>

        <form action="SendPendingIndentPDF" method="get">
            <input type="email" name="email" placeholder="Enter management email" required><br>
            <button type="submit">📩 Send Pending Indent Report</button>
        </form>
    </div>
</body>
</html>
