<%@ page import="javax.servlet.http.HttpSession" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String user = (String) sess.getAttribute("username");
    String role = (String) sess.getAttribute("role");
    String dept = (String) sess.getAttribute("department");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>SRS Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <style>
        body {
            margin: 0;
            font-family: 'Poppins', sans-s erif;
            background: white;
        }

        header {
            background: white;
            color: black;
            padding: 0.5px 50px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0px 8px 10px rgba(0,0,0,0.2);
        }

        header h1 {
            margin: 0;
            font-size: 26px;
            font-weight: 600;
        }

        header .user-info {
            text-align: right;
            font-size: 16px;
            line-height: 1.5;
        }

        nav {
            background:  white;
            box-shadow: 0px 2px 6px rgba(0,0,0,0.2);
        }

        nav ul {
            list-style: none;
            margin: 0;
            padding: 0;
            display: flex;
        }

        nav li {
            flex: 1;
        }

        nav a {
            display: block;
            text-align: center;
            padding: 10px 10px;
            color: Black;
            text-decoration: none;
            font-weight: 500;
            transition: all 0.3s ease;
        }

        nav a:hover {
            background: #3498db;
            color: #fff;
            border: 2px solid #F57C0C;
            transform: translateY(-2px);
        }

        hr {
            border: none;
            height: 2px;
            background: #f56827;
            margin: 0;
        }

        .container {
            padding: 30px;
        }
    </style>
</head>
<body>

<header>
    <img src="logo.png" width="20%">
    <div class="user-info">
        <strong><%= user.toUpperCase() %></strong><br>
        Access: <%= role.toUpperCase() %>
    </div>
</header>

<nav>
    <ul>
        <li><a href="IndentServlet">Indent</a>
        <li><a href="IndentPO">Purchase Order</a>
        
        <li><a href="IssueServlet"> Issue Items</a></li>
        <li><a href="Vendor.jsp"> Vendor Master</a></li>
       <li><a href="Vendor.jsp"> Reports</a></li>
        <li><a href="Logout.jsp"> Logout</a></li>
        
    </ul>
</nav>

<hr>

<div class="container">
    <!-- Page content goes here -->
</div>

</body>
</html>
