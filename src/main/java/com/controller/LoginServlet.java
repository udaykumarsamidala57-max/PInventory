package com.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    private static final String URL =
            "jdbc:mysql://shuttle.proxy.rlwy.net:26985/inventory?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&tcpKeepAlive=true";

    private static final String USER = "root";
    private static final String PASSWORD = "vSZVibKCzvcovcGjaLlxrTddrjiNPVQn";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.sendRedirect("login.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String uname = request.getParameter("username");
        String pass = request.getParameter("password");

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {

            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(URL, USER, PASSWORD);

            ps = con.prepareStatement(
                    "SELECT role, department, branch FROM users WHERE username=? AND password=?");

            ps.setString(1, uname);
            ps.setString(2, pass);

            rs = ps.executeQuery();

            if (rs.next()) {

                String role = rs.getString("role");
                String department = rs.getString("department");
                String branch = rs.getString("branch");

                HttpSession session = request.getSession();

                session.setAttribute("username", uname);
                session.setAttribute("role", role);
                session.setAttribute("department", department);
                session.setAttribute("branch", branch);

                // Redirect based on role/department

                if ("Global".equalsIgnoreCase(role)) {

                    response.sendRedirect("Home");

                } else if ("incharge".equalsIgnoreCase(role)
                        || "Finance".equalsIgnoreCase(department)) {

                    response.sendRedirect("Home");

                } else if ("HOSTEL".equalsIgnoreCase(department)) {

                    response.sendRedirect("TrackRequestServlet");

                } else {

                    response.sendRedirect("Home");
                }

            } else {

                request.setAttribute("error", "Invalid Username or Password!");
                RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
                rd.forward(request, response);

            }

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            try {
                if (rs != null)
                    rs.close();
            } catch (Exception e) {
            }

            try {
                if (ps != null)
                    ps.close();
            } catch (Exception e) {
            }

            try {
                if (con != null)
                    con.close();
            } catch (Exception e) {
            }

        }
    }
}