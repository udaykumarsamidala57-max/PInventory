<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
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
    <form action="verify-otp" method="post">
        <p style="margin:0 0 8px;color:#555;font-size:14px;">We sent a 6-digit code to <b><c:out value="${email}"/></b>. It is valid for 5 minutes.</p>
        <input type="hidden" name="email" value="<c:out value='${email}'/>">
        <label>OTP</label>
        <input type="text" name="otp" inputmode="numeric" pattern="[0-9]{6}" maxlength="6" autocomplete="one-time-code" required autofocus>
        <button type="submit">Verify OTP</button>
    </form>

    <div class="error"><c:out value="${error}"/></div>
    <p style="text-align:center;font-size:13px;margin-top:14px;"><a href="login.jsp">Back to login / send a new code</a></p>
</div>
</body>
</html>
