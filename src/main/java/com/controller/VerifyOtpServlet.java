package com.controller;

import java.io.IOException;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import com.bean.DBUtil;

@WebServlet("/VerifyOtpServlet")
public class VerifyOtpServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String enteredOtp = request.getParameter("otp");
        HttpSession session = request.getSession(false);
        String username = (String) session.getAttribute("username");

        try (Connection con = DBUtil.getConnection()) {
            PreparedStatement ps = con.prepareStatement("SELECT otp, role, department FROM users WHERE username=?");
            ps.setString(1, username);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                String dbOtp = rs.getString("otp");
                if (enteredOtp.equals(dbOtp)) {
                    // Clear OTP after successful verification
                    PreparedStatement clearOtp = con.prepareStatement("UPDATE users SET otp=NULL WHERE username=?");
                    clearOtp.setString(1, username);
                    clearOtp.executeUpdate();

                    session.setAttribute("role", rs.getString("role"));
                    session.setAttribute("department", rs.getString("department"));
                    response.sendRedirect("IndentServlet");
                } else {
                    request.setAttribute("error", "Invalid OTP!");
                    RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
                    rd.forward(request, response);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
