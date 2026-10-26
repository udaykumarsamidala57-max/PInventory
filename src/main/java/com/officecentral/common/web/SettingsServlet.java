package com.officecentral.common.web;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Settings Master overview (/settings) – Global role or Finance department only.
 * The System Masters pages are listed as a sidebar by header.jsp on this page and on every master page.
 * Access is also enforced by AccessFilter; the check here keeps the page safe on its own.
 */
@WebServlet("/settings")
public class SettingsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }
        if (!AccessFilter.isGlobalOrFinance(s)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Settings Master is available only to Global and Finance users.");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/views/common/settings.jsp").forward(req, resp);
    }
}
