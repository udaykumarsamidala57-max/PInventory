package com.controller;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.DAO.StoreAccessAdminDAO;
import com.bean.DBUtil;

@WebServlet("/StoreAccessAdminServlet")
public class StoreAccessAdminServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final StoreAccessAdminDAO storeAccessDAO = new StoreAccessAdminDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (!requireGlobal(request, session, response)) return;

        Object flashMessage = session.getAttribute("storeAccessFlashMessage");
        Object flashType = session.getAttribute("storeAccessFlashType");
        if (flashMessage != null) {
            request.setAttribute("message", flashMessage);
            request.setAttribute("messageType", flashType);
            session.removeAttribute("storeAccessFlashMessage");
            session.removeAttribute("storeAccessFlashType");
        }
        request.setAttribute("users", loadUsers());
        request.setAttribute("storeCodes", DBUtil.getSupportedBranches().stream()
                .sorted(String.CASE_INSENSITIVE_ORDER).collect(Collectors.toList()));
        request.setAttribute("csrfToken", csrfToken(session));
        request.getRequestDispatcher("/admin/store-access.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        boolean ajax = isAjax(request);
        if (!requireGlobal(request, session, response)) return;

        String submittedToken = request.getParameter("csrfToken");
        Object expectedToken = session.getAttribute("storeAccessCsrfToken");
        if (!(expectedToken instanceof String) || submittedToken == null
                || !MessageDigest.isEqual(((String) expectedToken).getBytes(StandardCharsets.UTF_8),
                        submittedToken.getBytes(StandardCharsets.UTF_8))) {
            if (ajax) writeJson(response, HttpServletResponse.SC_FORBIDDEN, false, "Your session expired. Refresh the page and try again.");
            else response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid form token.");
            return;
        }

        try {
            int userId = Integer.parseInt(request.getParameter("userId"));
            String[] submittedCodes = request.getParameterValues("storeCodes");
            List<String> canonicalCodes = new ArrayList<>();
            if (submittedCodes != null) {
                for (String code : submittedCodes) {
                    String canonical = DBUtil.canonicalBranch(code);
                    if (!canonicalCodes.contains(canonical)) canonicalCodes.add(canonical);
                }
            }
            storeAccessDAO.replaceAssignments(userId, canonicalCodes);
            if (ajax) {
                writeJson(response, HttpServletResponse.SC_OK, true, "Store access saved.");
                return;
            }
            session.setAttribute("storeAccessFlashMessage", "Store access saved.");
            session.setAttribute("storeAccessFlashType", "success");
        } catch (NumberFormatException ex) {
            if (ajax) {
                writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false, "Invalid user selection.");
                return;
            }
            session.setAttribute("storeAccessFlashMessage", "Invalid user selection.");
            session.setAttribute("storeAccessFlashType", "error");
        } catch (SQLException ex) {
            getServletContext().log("Store access update failed for user " + request.getParameter("userId"), ex);
            if (ajax) {
                writeJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, false, "Could not save store access. Check the user and store selections.");
                return;
            }
            session.setAttribute("storeAccessFlashMessage", "Could not save store access. Check the user and store selections.");
            session.setAttribute("storeAccessFlashType", "error");
        }
        response.sendRedirect(request.getContextPath() + "/StoreAccessAdminServlet");
    }

    private List<com.bean.UserStoreAssignments> loadUsers() throws ServletException {
        try {
            return storeAccessDAO.findAllUsers();
        } catch (SQLException ex) {
            throw new ServletException("Could not load users and store assignments.", ex);
        }
    }

    private boolean requireGlobal(HttpServletRequest request, HttpSession session, HttpServletResponse response)
            throws IOException {
        if (session == null || session.getAttribute("username") == null) {
            if (isAjax(request)) {
                writeJson(response, HttpServletResponse.SC_UNAUTHORIZED, false, "Please sign in again.");
            } else {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
            }
            return false;
        }
        if (!"Global".equalsIgnoreCase((String) session.getAttribute("role"))) {
            if (isAjax(request)) {
                writeJson(response, HttpServletResponse.SC_FORBIDDEN, false, "Global administrator access required.");
            } else {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Global administrator access required.");
            }
            return false;
        }
        return true;
    }

    private boolean isAjax(HttpServletRequest request) {
        return "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"));
    }

    private void writeJson(HttpServletResponse response, int status, boolean success, String message)
            throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write("{\"success\":" + success + ",\"message\":\"" + jsonEscape(message) + "\"}");
    }

    private String jsonEscape(String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\r", "\\r").replace("\n", "\\n");
    }

    private String csrfToken(HttpSession session) {
        Object existing = session.getAttribute("storeAccessCsrfToken");
        if (existing instanceof String) return (String) existing;
        String token = UUID.randomUUID().toString();
        session.setAttribute("storeAccessCsrfToken", token);
        return token;
    }
}
