package com.mobile;

import java.io.IOException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Web admin page: enable / disable Android app options by role and department.
 * Global administrators only. GET shows the grid, POST saves it.
 */
@WebServlet("/mobile-access")
public class MobileAccessServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(MobileAccessServlet.class.getName());
    private static final String CSRF = "mobileAccessCsrf";
    private static final SecureRandom RANDOM = new SecureRandom();

    private final transient MobileAccessDAO dao = new MobileAccessDAO();

    /** Rows of the grid: all/all, each role/all, all/each department, then each role/department pair. */
    private List<String[]> rows() throws java.sql.SQLException {
        Map<String, String[]> rows = new LinkedHashMap<>();
        List<String[]> pairs = dao.roleDepartments();
        rows.put("*|*", new String[]{MobileAccessDAO.ANY, MobileAccessDAO.ANY});
        for (String[] p : pairs) rows.putIfAbsent((p[0] + "|*").toLowerCase(), new String[]{p[0], MobileAccessDAO.ANY});
        for (String[] p : pairs) {
            if (!p[1].isEmpty()) rows.putIfAbsent(("*|" + p[1]).toLowerCase(), new String[]{MobileAccessDAO.ANY, p[1]});
        }
        for (String[] p : pairs) {
            if (!p[1].isEmpty()) rows.putIfAbsent((p[0] + "|" + p[1]).toLowerCase(), p);
        }
        return new ArrayList<>(rows.values());
    }

    private static boolean isGlobal(HttpSession s) {
        return s != null && s.getAttribute("username") != null && "Global".equalsIgnoreCase(String.valueOf(s.getAttribute("role")));
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null) { resp.sendRedirect(req.getContextPath() + "/login.jsp"); return; }
        if (!isGlobal(s)) { resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Global administrator access required."); return; }
        resp.setHeader("Cache-Control", "no-store");

        String token = (String) s.getAttribute(CSRF);
        if (token == null) {
            byte[] b = new byte[24];
            RANDOM.nextBytes(b);
            token = Base64.getUrlEncoder().withoutPadding().encodeToString(b);
            s.setAttribute(CSRF, token);
        }
        try {
            req.setAttribute("rows", rows());
            req.setAttribute("rules", dao.loadRules());
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Could not load mobile access", e);
            req.setAttribute("rows", new ArrayList<String[]>());
            req.setAttribute("rules", new LinkedHashMap<String, Boolean>());
            req.setAttribute("message", "Could not load mobile access settings.");
            req.setAttribute("messageType", "error");
        }
        Object msg = s.getAttribute("mobileAccessFlash");
        if (msg != null) {
            req.setAttribute("message", msg);
            req.setAttribute("messageType", s.getAttribute("mobileAccessFlashType"));
            s.removeAttribute("mobileAccessFlash");
            s.removeAttribute("mobileAccessFlashType");
        }
        req.setAttribute("csrfToken", token);
        req.getRequestDispatcher("/WEB-INF/views/common/mobile-access.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null) { resp.sendRedirect(req.getContextPath() + "/login.jsp"); return; }
        if (!isGlobal(s)) { resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Global administrator access required."); return; }

        String expected = (String) s.getAttribute(CSRF);
        String given = req.getParameter("csrfToken");
        if (expected == null || given == null
                || !MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), given.getBytes(StandardCharsets.UTF_8))) {
            flash(s, "Your page expired. Refresh and try again.", "error");
            resp.sendRedirect(req.getContextPath() + "/mobile-access");
            return;
        }

        try {
            // Only rows the server itself lists are accepted (never trust role/department text from the browser).
            Map<String, String[]> allowed = new LinkedHashMap<>();
            for (String[] r : rows()) allowed.put((r[0] + "\u0001" + r[1]).toLowerCase(), r);
            List<String> features = new ArrayList<>(MobileAccessDAO.FEATURES.keySet());
            List<MobileAccessDAO.Rule> rules = new ArrayList<>();
            int count;
            try { count = Math.min(Integer.parseInt(req.getParameter("rowCount")), 2000); } catch (NumberFormatException e) { count = 0; }
            for (int i = 0; i < count; i++) {
                String role = req.getParameter("role_" + i), dept = req.getParameter("dept_" + i);
                if (role == null || dept == null) continue;
                String[] r = allowed.get((role + "\u0001" + dept).toLowerCase());
                if (r == null) continue; // unknown row: ignore
                for (int f = 0; f < features.size(); f++) {
                    String v = req.getParameter("v_" + i + "_" + f);
                    if (v == null) continue;
                    Boolean enabled = "on".equals(v) ? Boolean.TRUE : "off".equals(v) ? Boolean.FALSE : null;
                    rules.add(new MobileAccessDAO.Rule(r[0], r[1], features.get(f), enabled));
                }
            }
            if (rules.isEmpty()) {
                flash(s, "Nothing changed.", "success");
            } else {
                dao.save(rules, String.valueOf(s.getAttribute("username")));
                flash(s, rules.size() + (rules.size() == 1 ? " setting" : " settings")
                        + " updated. Users get the change within 2 minutes or at next login.", "success");
            }
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Could not save mobile access", e);
            flash(s, "Could not save. Please try again.", "error");
        }
        resp.sendRedirect(req.getContextPath() + "/mobile-access");
    }

    private static void flash(HttpSession s, String msg, String type) {
        s.setAttribute("mobileAccessFlash", msg);
        s.setAttribute("mobileAccessFlashType", type);
    }
}
