<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page session="true" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Verify OTP</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f2f6fb;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 15px rgba(0,0,0,0.1);
            width: 350px;
            text-align: center;
        }
        input[type="text"] {
            width: 80%;
            padding: 10px;
            margin: 10px 0;
            border: 1px solid #ccc;
            border-radius: 5px;
        }
        input[type="submit"] {
            width: 85%;
            padding: 10px;
            background-color: #34A853;
            border: none;
            color: white;
            border-radius: 5px;
            cursor: pointer;
        }
        input[type="submit"]:hover {
            background-color: #2C8A45;
        }
        .message {
            color: red;
            font-size: 14px;
        }
    </style>
</head>
<body>
<div class="container">
    <h2>Verify OTP</h2>
    <form action="VerifyOtpServlet" method="post">
        <input type="text" name="otp" placeholder="Enter OTP" required><br>
        <input type="submit" value="Verify OTP">
    </form>
    <div class="message">
        <%
            String msg = (String) request.getAttribute("msg");
            if (msg != null) {
                out.print(msg);
            }
        %>
    </div>
</div>
</body>
</html>
