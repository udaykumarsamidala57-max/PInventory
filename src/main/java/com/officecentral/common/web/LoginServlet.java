package com.officecentral.common.web;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.officecentral.common.db.InventoryDB; // Using InventoryDB instead of hardcoded connection details

@WebServlet(urlPatterns = {"/login", "/LoginServlet"})   // second one = old address, kept so old links still work
public class LoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

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
          
            con = InventoryDB.getAuthConnection();

            ps = con.prepareStatement(
                    "SELECT id, role, department, branch FROM users WHERE username=? AND password=?");

            ps.setString(1, uname);
            ps.setString(2, pass);

            rs = ps.executeQuery();

            if (rs.next()) {
                int userId = rs.getInt("id");
                String role = rs.getString("role");
                String department = rs.getString("department");
                String branch = rs.getString("branch");

                HttpSession session = request.getSession();

                session.setAttribute("username", uname);
                session.setAttribute("userId", userId);
                session.setAttribute("role", role);
                session.setAttribute("department", department);
                session.setAttribute("assignedBranch", branch);
                session.setAttribute("branch", branch);

                response.sendRedirect("select-store");

            } else {
                request.setAttribute("error", "Invalid Username or Password!");
                RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
                rd.forward(request, response);
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database connection error. Please try again later.");
            RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
            rd.forward(request, response);

        } finally {
            try {
                if (rs != null) rs.close();
            } catch (Exception e) {
                e.printStackTrace();
            }

            try {
                if (ps != null) ps.close();
            } catch (Exception e) {
                e.printStackTrace();
            }

            try {
                if (con != null) con.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
