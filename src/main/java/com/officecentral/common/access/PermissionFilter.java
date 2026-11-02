package com.officecentral.common.access;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Logger;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Enforces page access from the Access Control settings for every PInventory address in the catalogue
 * (new address, old address and .jsp alias of a page all belong to the same page key). The menu only
 * hides links; this is the real check. Pages keep their own checks too.
 *
 * Not signed in, addresses outside the catalogue, and everything while the access tables are missing are
 * passed through unchanged.
 */
@WebFilter(filterName = "PermissionFilter", urlPatterns = "/*")
public class PermissionFilter implements Filter {

    private static final Logger LOG = Logger.getLogger(PermissionFilter.class.getName());

    /** Where users land after login: when not allowed, send them to their first allowed page instead. */
    private static final Set<String> LANDING = new HashSet<>(Arrays.asList(
            "/home", "/Home", "/Home.jsp", "/indent", "/TrackRequestServlet", "/RequestBookingServlet"));

    @Override public void init(FilterConfig filterConfig) { }
    @Override public void destroy() { }

    @Override
    public void doFilter(ServletRequest sreq, ServletResponse sresp, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) sreq;
        HttpServletResponse resp = (HttpServletResponse) sresp;
        String path = pathOf(req);
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null || !AccessControl.isMapped(path)
                || AccessControl.canPath(s, path)) {
            chain.doFilter(req, resp);
            return;
        }
        LOG.warning("[access] DENIED " + req.getMethod() + " " + path + " for user " + s.getAttribute("username")
                + " (role " + s.getAttribute("role") + ", dept " + s.getAttribute("department") + ")");
        boolean page = "GET".equalsIgnoreCase(req.getMethod()) && !isAjax(req);
        String first = page ? AccessControl.firstAllowedPage(s) : null;
        if (page && first != null && LANDING.contains(path) && !first.equals(path)) {
            resp.sendRedirect(req.getContextPath() + first);
            return;
        }
        if (!page) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have access to this page.");
            return;
        }
        resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
        resp.setContentType("text/html;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        String ctx = req.getContextPath();
        try (PrintWriter w = resp.getWriter()) {
            w.write("<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><meta name=\"viewport\" "
                    + "content=\"width=device-width, initial-scale=1\"><title>No access</title><style>"
                    + "body{margin:0;background:#f3f3f3;font:14px/1.5 'Salesforce Sans',Inter,'Segoe UI',Arial,sans-serif;color:#181818}"
                    + ".box{max-width:520px;margin:12vh auto;background:#fff;border:1px solid #dddbda;border-radius:4px;"
                    + "padding:28px 30px;box-shadow:0 2px 4px rgba(0,0,0,.08)}h1{font-size:20px;margin:0 0 6px}"
                    + "p{color:#514f4d;margin:0 0 18px}a{display:inline-block;margin-right:10px;padding:8px 14px;border-radius:4px;"
                    + "text-decoration:none;font-weight:600;border:1px solid #0176d3}a.p{background:#0176d3;color:#fff}"
                    + "a.s{color:#0176d3;background:#fff}</style></head><body><div class=\"box\"><h1>You do not have access to this page</h1>"
                    + "<p>Ask a Global user to give your role or department access on the Access Control page.</p>");
            if (first != null) w.write("<a class=\"p\" href=\"" + esc(ctx + first) + "\">Go to my first page</a>");
            w.write("<a class=\"s\" href=\"" + esc(ctx) + "/select-store\">Change store</a>"
                    + "<a class=\"s\" href=\"" + esc(ctx) + "/Logout.jsp\">Sign out</a></div></body></html>");
        }
    }

    /**
     * Address inside the application as the container matched it (decoded and normalised, so encoded or
     * "/./" variants of an address are checked the same way).
     */
    static String pathOf(HttpServletRequest req) {
        String sp = req.getServletPath();
        String pi = req.getPathInfo();
        String path = (sp == null ? "" : sp) + (pi == null ? "" : pi);
        return path.isEmpty() ? "/" : path;
    }

    private static boolean isAjax(HttpServletRequest req) {
        String xrw = req.getHeader("X-Requested-With");
        String accept = req.getHeader("Accept");
        return "XMLHttpRequest".equalsIgnoreCase(xrw)
                || (accept != null && accept.contains("application/json") && !accept.contains("text/html"));
    }

    private static String esc(String v) {
        return v.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
}
