package com.controller;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Random;

import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

@WebServlet("/SendOTPServlet")
public class SendOTPServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        Random rand = new Random();
        int otp = 100000 + rand.nextInt(900000);
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(5);

        try (Connection con = DBUtil.getConnection()) {

            PreparedStatement check = con.prepareStatement("SELECT * FROM users WHERE mail=?");
            check.setString(1, email);
            ResultSet rs = check.executeQuery();

            if (rs.next()) {
                PreparedStatement ps = con.prepareStatement("UPDATE users SET otp=?, otp_expiry=? WHERE mail=?");
                ps.setInt(1, otp);
                ps.setString(2, expiry.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
                ps.setString(3, email);
                ps.executeUpdate();

                // Send OTP using Brevo API
                boolean sent = sendEmailViaBrevo(email, otp);

                if (sent) {
                    request.setAttribute("email", email);
                    RequestDispatcher rd = request.getRequestDispatcher("verify_otp.jsp");
                    rd.forward(request, response);
                } else {
                    request.setAttribute("error", "Failed to send OTP. Try again later.");
                    RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
                    rd.forward(request, response);
                }

            } else {
                request.setAttribute("error", "Email not registered!");
                RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
                rd.forward(request, response);
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error sending OTP. Try again.");
            RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
            rd.forward(request, response);
        }
    }

    // ✅ Brevo (Sendinblue) API method — Works in Railway
    private boolean sendEmailViaBrevo(String to, int otp) {
        try {
            String apiKey = System.getenv("BREVO_API_KEY"); 
            if (apiKey == null || apiKey.isEmpty()) {
                throw new RuntimeException("⚠️ Brevo API key not found in environment variables!");
            }

            URL url = new URL("https://api.brevo.com/v3/smtp/email");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("accept", "application/json");
            conn.setRequestProperty("api-key", apiKey);
            conn.setRequestProperty("content-type", "application/json");
            conn.setDoOutput(true);

            String json = """
            		{
            		  "sender": {"name":"SRS Central Admin","email":"udaykumarsamidala57@gmail.com"},
            		  "to":[{"email":"%s"}],
            		  "subject":"🔐 Your One-Time Password (OTP) for Login",
            		  "htmlContent":"<div style='font-family:Poppins,Arial,sans-serif;color:#333;line-height:1.6;'><h2 style='color:#2563eb;'>Hello,</h2><p style='font-size:15px;'>Your one-time password (OTP) for login is:</p><p style='font-size:22px;font-weight:bold;color:#2563eb;letter-spacing:2px;'>%d</p><p style='font-size:14px;color:#555;'>This OTP is valid for <b>5 minutes</b>. Please do not share it with anyone.</p><br><p style='font-size:14px;color:#555;'>Regards,<br><b>SRS Central Admin</b></p></div>"
            		}
            		""".formatted(to, otp);


            try (OutputStream os = conn.getOutputStream()) {
                os.write(json.getBytes());
            }

            int code = conn.getResponseCode();
            conn.disconnect();

            System.out.println("Brevo API response code: " + code);
            return code == 201 || code == 202; // success

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
}
