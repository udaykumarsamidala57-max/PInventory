<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>User Login</title>
<style>
    body {
        font-family: 'Poppins', sans-serif;
        background: linear-gradient(135deg, #1a2980, #26d0ce);
        margin: 0;
        height: 100vh;
        display: flex;
        justify-content: center;
        align-items: center;
    }

    .login-container {
        width: 360px;
        background: rgba(255, 255, 255, 0.12);
        backdrop-filter: blur(20px);
        padding: 35px 30px;
        border-radius: 18px;
        box-shadow: 0 10px 25px rgba(0, 0, 0, 0.25);
        color: #fff;
        animation: fadeIn 0.8s ease;
        box-sizing: border-box;
    }

    @keyframes fadeIn {
        from { opacity: 0; transform: translateY(-15px); }
        to { opacity: 1; transform: translateY(0); }
    }

    h2 {
        text-align: center;
        margin-bottom: 25px;
        font-weight: 700;
        color: #fff;
    }

    label {
        font-weight: 500;
        color: #f5f5f5;
        display: block;
        margin-bottom: 6px;
        font-size: 14px;
    }

    input[type=text],
    input[type=password],
    input[type=email] {
        width: 100%;
        padding: 12px 14px;
        margin-bottom: 18px;
        border: none;
        border-radius: 8px;
        font-size: 15px;
        outline: none;
        background: rgba(255, 255, 255, 0.95);
        color: #333;
        box-sizing: border-box;
        transition: box-shadow 0.3s ease;
    }

    input:focus {
        box-shadow: 0 0 6px rgba(0, 114, 255, 0.5);
    }

    .show-password {
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 13px;
        color: #f5f5f5;
        margin-top: -10px;
        margin-bottom: 20px;
    }

    button {
        width: 100%;
        padding: 12px;
        background: linear-gradient(135deg, #0072ff, #00c6ff);
        color: white;
        font-size: 16px;
        border: none;
        border-radius: 8px;
        cursor: pointer;
        font-weight: 600;
        transition: all 0.3s ease;
    }

    button:hover {
        transform: scale(1.03);
        background: linear-gradient(135deg, #005bea, #00c6ff);
    }

    .error {
        color: #ff6b6b;
        text-align: center;
        margin-top: 10px;
        font-size: 14px;
        font-weight: 500;
    }

    hr {
        border: none;
        border-top: 1px solid rgba(255, 255, 255, 0.4);
        margin: 25px 0;
    }

    .google-login {
        display: flex;
        align-items: center;
        justify-content: center;
        background: #fff;
        color: #333;
        padding: 12px;
        border-radius: 8px;
        cursor: pointer;
        font-weight: 600;
        border: none;
        width: 100%;
        transition: transform 0.3s ease, background 0.3s ease;
    }

    .google-login:hover {
        transform: scale(1.03);
        background: #f2f2f2;
    }

    .google-login img {
        width: 22px;
        margin-right: 10px;
    }

    input::placeholder {
        color: #777;
    }

    @media (max-width: 420px) {
        .login-container {
            width: 90%;
            padding: 25px 20px;
        }
    }
</style>
</head>
<body>
    <div class="login-container">
        <h2>User Login</h2>

      
        <form action="LoginServlet" method="post"> 
            <label>Username</label> 
            <input type="text" name="username" placeholder="Enter your username" required> 

            <label>Password</label>
            <input type="password" id="password" name="password" placeholder="Enter your password" required>

            <div class="show-password">
                <input type="checkbox" id="showPwd" onclick="togglePassword()">
                <label for="showPwd">Show Password</label>
            </div>

            <button type="submit">Login</button> 
        </form>

        <div class="error">
            <%= request.getAttribute("error") != null ? request.getAttribute("error") : "" %>
        </div> 

        <hr>

     
        <form action="SendOTPServlet" method="post">
            <button type="submit" class="google-login">
                <img src="https://www.gstatic.com/images/branding/product/1x/gmail_2020q4_48dp.png" alt="Google">
                Login with Gmail OTP
            </button>
            <input type="email" name="email" placeholder="Enter your registered Gmail" required style="margin-top:15px;">
        </form>
    </div>

    <script>
        function togglePassword() {
            const pwd = document.getElementById("password");
            pwd.type = pwd.type === "password" ? "text" : "password";
        }
    </script>
</body>
</html>
