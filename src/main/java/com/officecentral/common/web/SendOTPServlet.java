package com.officecentral.common.web;

import java.io.*;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.security.SecureRandom;

import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.officecentral.common.db.InventoryDB;

@WebServlet(urlPatterns = {"/send-otp", "/SendOTPServlet"})   // second one = old address, kept so old links still work
public class SendOTPServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.sendRedirect("login.jsp");
    }

    /** Step 1 of "Login with Gmail OTP": the person is NOT logged in yet, so no session is needed here. */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        email = email == null ? "" : email.trim();
        if (email.isEmpty()) {
            fail(request, response, "Please enter your registered Gmail.");
            return;
        }

        int otp = 100000 + new SecureRandom().nextInt(900000);
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(5);

        // Same user list as the normal username / password login
        try (Connection con = InventoryDB.getAuthConnection()) {
            String registeredMail = null;
            try (PreparedStatement check = con.prepareStatement("SELECT mail FROM users WHERE LOWER(mail) = LOWER(?)")) {
                check.setString(1, email);
                try (ResultSet rs = check.executeQuery()) {
                    if (rs.next()) registeredMail = rs.getString("mail");
                }
            }
            if (registeredMail == null) {
                fail(request, response, "Email not registered!");
                return;
            }

            try (PreparedStatement ps = con.prepareStatement("UPDATE users SET otp=?, otp_expiry=? WHERE mail=?")) {
                ps.setInt(1, otp);
                ps.setString(2, expiry.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
                ps.setString(3, registeredMail);
                ps.executeUpdate();
            }

            if (sendEmailViaBrevo(registeredMail, otp)) {
                request.setAttribute("email", registeredMail);
                request.getRequestDispatcher("/WEB-INF/views/common/verify_otp.jsp").forward(request, response);
            } else {
                fail(request, response, "Failed to send OTP. Try again later.");
            }

        } catch (Exception e) {
            e.printStackTrace();
            fail(request, response, "Error sending OTP. Try again.");
        }
    }

    private static void fail(HttpServletRequest request, HttpServletResponse response, String message)
            throws ServletException, IOException {
        request.setAttribute("error", message);
        request.getRequestDispatcher("login.jsp").forward(request, response);
    }

    /** Sends the OTP e-mail (Brevo or Gmail, whichever is set up). Logs the reason if it fails. */
    private boolean sendEmailViaBrevo(String to, int otp) {
        String html = "<div style='font-family:Poppins,Arial,sans-serif;color:#333;line-height:1.6;'>"
                + "<h2 style='color:#2563eb;'>Hello,</h2>"
                + "<p style='font-size:15px;'>Your one-time password (OTP) for login is:</p>"
                + "<p style='font-size:22px;font-weight:bold;color:#2563eb;letter-spacing:2px;'>" + otp + "</p>"
                + "<p style='font-size:14px;color:#555;'>This OTP is valid for <b>5 minutes</b>. Please do not share it with anyone.</p>"
                + "<br><p style='font-size:14px;color:#555;'>Regards,<br><b>SRS Central Admin</b></p></div>";
        try {
            com.officecentral.common.mail.Mailer.send(to, "🔐 Your One-Time Password (OTP) for Login", html, null, null);
            return true;
        } catch (Exception e) {
            System.err.println("OTP e-mail NOT sent to " + to + ": " + e.getMessage());
            return false;
        }
    }
}
