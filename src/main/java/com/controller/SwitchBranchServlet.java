package com.controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/SwitchBranchServlet")
public class SwitchBranchServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session != null) {
            String role = (String) session.getAttribute("role");
            String username = (String) session.getAttribute("username");
            String assignedBranch = (String) session.getAttribute("branch");
            String selectedBranch = request.getParameter("branch");

            // Authorize user: Global role, admin username, or users belonging to Sanpoly branches
            boolean isAllowedUser = "Global".equalsIgnoreCase(role)         
                                 || "Sanpoly".equalsIgnoreCase(assignedBranch)
                                 || "Sanpoly2".equalsIgnoreCase(assignedBranch);

            // Restrict target branch switching STRICTLY to Sanpoly and Sanpoly2
            boolean isValidBranch = "Sanpoly".equalsIgnoreCase(selectedBranch) 
                                 || "Sanpoly2".equalsIgnoreCase(selectedBranch);

            if (isAllowedUser && isValidBranch) {
                session.setAttribute("currentBranch", selectedBranch);
            }
        }

        // Redirect back to referring page or Home
        String referer = request.getHeader("Referer");
        if (referer != null && !referer.trim().isEmpty()) {
            response.sendRedirect(referer);
        } else {
            response.sendRedirect("Home");
        }
    }
}