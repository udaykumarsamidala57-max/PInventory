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
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body {
            margin: 0;
            font-family: 'Poppins', sans-serif;
            background: #f5f6fa;
            display: flex;
        }

        /* Sidebar */
        .nav-container {
            width: 240px;
            height: 100vh;
            background: linear-gradient(180deg, #ffffff, #f7f7f7);
            padding: 20px;
            box-sizing: border-box;
            border-right: 2px solid #F07A05;
            box-shadow: 2px 0 10px rgba(0,0,0,0.08);
            position: fixed;
            top: 0;
            left: 0;
            overflow-y: auto;
        }

        .nav-container h2 {
            text-align: center;
            color: #F07A05;
            margin-bottom: 25px;
            font-size: 18px;
            font-weight: bold;
            letter-spacing: 1px;
        }

        .nav-container a {
            display: flex;
            align-items: center;
            padding: 12px 15px;
            margin: 8px 0;
            color: #333;
            text-decoration: none;
            font-weight: 500;
            font-size: 15px;
            border-radius: 25px;
            transition: all 0.3s ease;
        }

        .nav-container a:hover {
            background-color: #F07A05;
            color: #fff;
            transform: translateX(6px);
            box-shadow: 0 3px 8px rgba(240,122,5,0.3);
        }

        .nav-container a h3 {
            margin: 0;
            font-size: 15px;
            font-weight: normal;
        }

        .icon {
            margin-right: 10px;
            font-size: 16px;
        }

        /* Main layout (header + content) */
        .main {
            margin-left: 260px;
            width: 100%;
        }

        header {
            background: white;
            color: black;
            padding: 10px 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0px 4px 8px rgba(0,0,0,0.1);
        }

        header img {
            height: 60px;
        }

        header .user-info {
            text-align: right;
            font-size: 16px;
            line-height: 1.4;
        }

        .container {
            padding: 30px;
        }
    </style>
</head>
<body>

<!-- Sidebar -->
<div class="nav-container">
    <h2>Navigation</h2>
    <a href=""><i class="fas fa-home icon"></i><h3>HOME</h3></a>
    <a href="IndentServlet"><i class="fas fa-file-alt icon"></i><h3>INDENT FORM</h3></a>
    <a href="AIndentListServlet"><i class="fas fa-check-circle icon"></i><h3>APPROVE INDENT</h3></a>
    <a href="IndentlistServlet"><i class="fas fa-list icon"></i><h3>INDENT REPORT</h3></a>
    <a href="IndentPO"><i class="fas fa-shopping-cart icon"></i><h3>PURCHASE ORDER</h3></a>
    <a href="IssueServlet"><i class="fas fa-box icon"></i><h3>ISSUE ITEMS</h3></a>
    <a href="Vendor.jsp"><i class="fas fa-user-tie icon"></i><h3>VENDOR MASTER</h3></a>
    <a href="Reports.jsp"><i class="fas fa-chart-bar icon"></i><h3>REPORTS</h3></a>
    <a href="Logout.jsp"><i class="fas fa-sign-out-alt icon"></i><h3>LOGOUT</h3></a>
</div>

<!-- Main -->
<div class="main">
    <!-- Header -->
    <header>
        <img src="logo.png" alt="Logo">
        <div class="user-info">
            <strong><%= user.toUpperCase() %></strong><br>
            Access: <%= role.toUpperCase() %>
        </div>
    </header>

    <!-- Page Content -->
    <div class="container">
        <h1>Welcome, <%= user %>!</h1>
        <p>This is your SRS Dashboard with top header and left sidebar navigation.</p>
    </div>
</div>

</body>
</html>
