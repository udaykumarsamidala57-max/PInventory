package com.controller;

import java.io.IOException;
import java.sql.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import com.bean.DBUtil;

@WebServlet("/VerifyOtpServlet")
public class VerifyOtpServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        String otpInput = request.getParameter("otp");

        try (Connection con = DBUtil.getConnection()) {
            PreparedStatement ps = con.prepareStatement("SELECT username, role, department, otp, otp_expiry FROM users WHERE mail=?");
            ps.setString(1, email);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                int otpDB = rs.getInt("otp");
                String expiryStr = rs.getString("otp_expiry");
                LocalDateTime expiry = LocalDateTime.parse(expiryStr, DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

                if (otpDB == Integer.parseInt(otpInput) && LocalDateTime.now().isBefore(expiry)) {
                    HttpSession session = request.getSession();
                    session.setAttribute("username", rs.getString("username"));
                    session.setAttribute("role", rs.getString("role"));
                    session.setAttribute("department", rs.getString("department"));

                    // Clear OTP after successful login
                    PreparedStatement clear = con.prepareStatement("UPDATE users SET otp=NULL, otp_expiry=NULL WHERE mail=?");
                    clear.setString(1, email);
                    clear.executeUpdate();

                    response.sendRedirect("IndentServlet");
                } else {
                    request.setAttribute("error", "Invalid or expired OTP!");
                    request.setAttribute("email", email);
                    RequestDispatcher rd = request.getRequestDispatcher("verify_otp.jsp");
                    rd.forward(request, response);
                }
            } else {
                request.setAttribute("error", "Email not found!");
                RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
                rd.forward(request, response);
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error verifying OTP!");
            request.setAttribute("email", email);
            RequestDispatcher rd = request.getRequestDispatcher("verify_otp.jsp");
            rd.forward(request, response);
        }
    }
}
