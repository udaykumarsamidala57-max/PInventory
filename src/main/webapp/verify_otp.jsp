<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Verify OTP</title>
    <style>
        body { font-family: Arial; background: #f2f2f2; }
        .container {
            width: 350px; margin: 100px auto; padding: 25px;
            background: white; box-shadow: 0px 0px 10px gray; border-radius: 9px;
        }
        input { width: 100%; padding: 10px; margin: 8px 0; }
        button { width: 100%; padding: 10px; background: #0763B3; color: white; border: none; border-radius: 4px; }
        .error { color: red; text-align: center; }
    </style>
</head>
<body>
<div class="container">
    <h2>Enter OTP</h2>
    <form action="VerifyOtpServlet" method="post">
        <input type="hidden" name="email" value="<%= request.getAttribute("email") %>">
        <label>OTP</label>
        <input type="text" name="otp" required>
        <button type="submit">Verify OTP</button>
    </form>

    <div class="error">
        <%= request.getAttribute("error") != null ? request.getAttribute("error") : "" %>
    </div>
</div>
</body>
</html>
