package com.officecentral.common.web;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.officecentral.common.db.InventoryDB;

/** Step 2 of "Login with Gmail OTP": checks the code and logs the person in, like the password login does. */
@WebServlet(urlPatterns = {"/verify-otp", "/VerifyOtpServlet"})   // second one = old address, kept so old links still work
public class VerifyOtpServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.sendRedirect("login.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        String otpInput = request.getParameter("otp");
        email = email == null ? "" : email.trim();
        otpInput = otpInput == null ? "" : otpInput.trim();

        if (email.isEmpty()) {
            request.setAttribute("error", "Please request a new OTP.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
            return;
        }
        if (!otpInput.matches("\\d{6}")) {
            again(request, response, email, "Please enter the 6-digit OTP from the e-mail.");
            return;
        }

        try (Connection con = InventoryDB.getAuthConnection()) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT id, username, role, department, branch, otp, otp_expiry FROM users WHERE mail=?")) {
                ps.setString(1, email);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        request.setAttribute("error", "Email not found!");
                        request.getRequestDispatcher("login.jsp").forward(request, response);
                        return;
                    }

                    String otpDB = rs.getString("otp");
                    String expiryStr = rs.getString("otp_expiry");
                    boolean valid = otpDB != null && expiryStr != null
                            && otpDB.trim().equals(otpInput)
                            && LocalDateTime.now().isBefore(LocalDateTime.parse(expiryStr.substring(0, 19),
                                    DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
                    if (!valid) {
                        again(request, response, email, "Invalid or expired OTP!");
                        return;
                    }

                    // Same session as the username / password login, then the store choice
                    HttpSession old = request.getSession(false);
                    if (old != null) old.invalidate();
                    HttpSession session = request.getSession(true);
                    String branch = rs.getString("branch");
                    session.setAttribute("username", rs.getString("username"));
                    session.setAttribute("userId", rs.getInt("id"));
                    session.setAttribute("role", rs.getString("role"));
                    session.setAttribute("department", rs.getString("department"));
                    session.setAttribute("assignedBranch", branch);
                    session.setAttribute("branch", branch);
                    session.setAttribute("showAndroidAppPopup", Boolean.TRUE);
                }
            }

            // An OTP works only once
            try (PreparedStatement clear = con.prepareStatement("UPDATE users SET otp=NULL, otp_expiry=NULL WHERE mail=?")) {
                clear.setString(1, email);
                clear.executeUpdate();
            }
            response.sendRedirect(request.getContextPath() + "/select-store");

        } catch (Exception e) {
            e.printStackTrace();
            again(request, response, email, "Error verifying OTP!");
        }
    }

    private static void again(HttpServletRequest request, HttpServletResponse response, String email, String message)
            throws ServletException, IOException {
        request.setAttribute("error", message);
        request.setAttribute("email", email);
        request.getRequestDispatcher("/WEB-INF/views/common/verify_otp.jsp").forward(request, response);
    }
}
