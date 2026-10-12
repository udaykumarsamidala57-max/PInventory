package com.controller;

import java.io.IOException;
import java.sql.Connection;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.DAO.StoreAccessDAO;
import com.bean.DBUtil;

@WebServlet("/SelectStoreServlet")
public class SelectStoreServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final StoreAccessDAO storeAccessDAO = new StoreAccessDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (!isSignedIn(session)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        showStorePage(request, response, session, null);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (!isSignedIn(session)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String requestedStore = request.getParameter("store");
        try {
            List<String> allowedStores = allowedStores(session);
            String selectedStore = DBUtil.canonicalBranch(requestedStore);
            if (!allowedStores.contains(selectedStore)) {
                showStorePage(request, response, session, "You do not have access to that store.");
                return;
            }
            try (Connection ignored = DBUtil.getConnection(selectedStore)) {
                session.setAttribute("branch", selectedStore);
            }

            String department = (String) session.getAttribute("department");
            if ("HOSTEL".equalsIgnoreCase(department)) {
                response.sendRedirect(request.getContextPath() + "/TrackRequestServlet");
            } else {
                response.sendRedirect(request.getContextPath() + "/Home");
            }
        } catch (Exception ex) {
            showStorePage(request, response, session,
                    "Could not connect to that store. Please try again.");
        }
    }

    private void showStorePage(HttpServletRequest request, HttpServletResponse response,
                               HttpSession session, String error)
            throws ServletException, IOException {
        try {
            request.setAttribute("stores", allowedStores(session));
            request.setAttribute("selectedStore", session.getAttribute("branch"));
            request.setAttribute("username", session.getAttribute("username"));
            request.setAttribute("error", error);
            request.getRequestDispatcher("/select-store.jsp").forward(request, response);
        } catch (Exception ex) {
            throw new ServletException("Could not load the stores assigned to this account.", ex);
        }
    }

    private List<String> allowedStores(HttpSession session) throws Exception {
        Object userId = session.getAttribute("userId");
        if (!(userId instanceof Integer)) throw new IllegalStateException("User session has no ID.");
        return storeAccessDAO.findAllowedStores((Integer) userId,
                (String) session.getAttribute("assignedBranch"));
    }

    private boolean isSignedIn(HttpSession session) {
        return session != null && session.getAttribute("username") != null
                && session.getAttribute("userId") != null;
    }
}
