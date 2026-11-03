package com.officecentral.common.web;

import java.io.IOException;
import java.util.Locale;
import java.util.Set;

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

import com.website.bean.WebsiteDB;

/**
 * Users with role "Website" use only the Website module, for their own branch's website
 * (e.g. branch Sanpoly -> Sanpoly website). Every other PInventory page — including the store
 * choice after login — sends them to the Website Page Builder. Server-side check, not just a hidden menu.
 */
@WebFilter("/*")
public class WebsiteOnlyFilter implements Filter {

    /** Where a Website user lands after login and whenever they open a page outside the Website module. */
    static final String WEBSITE_HOME = "/website/pages";

    /** Sign in / out pages a Website user still needs. */
    private static final Set<String> ALLOWED_PATHS = Set.of(
            "/login", "/LoginServlet", "/login.jsp", "/Logout.jsp",
            "/verify-otp", "/VerifyOtpServlet", "/send-otp", "/SendOTPServlet");

    /** Admin-only website tools a Website user must not open. */
    private static final Set<String> BLOCKED_WEBSITE_PATHS = Set.of("/website/move-photos");

    @Override
    public void init(FilterConfig filterConfig) { }

    @Override
    public void destroy() { }

    @Override
    public void doFilter(ServletRequest sreq, ServletResponse sresp, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) sreq;
        HttpServletResponse resp = (HttpServletResponse) sresp;
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null || !WebsiteDB.isWebsiteUser(s)) {
            chain.doFilter(sreq, sresp);
            return;
        }
        String path = req.getServletPath() + (req.getPathInfo() == null ? "" : req.getPathInfo());
        if (BLOCKED_WEBSITE_PATHS.contains(path)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "This website tool is for Global users only.");
            return;
        }
        if (allowed(path)) {
            // Keep the session's store on the user's own branch, so anything reading "branch" sees the same site.
            Object own = s.getAttribute("assignedBranch");
            if (own != null && !own.equals(s.getAttribute("branch"))) s.setAttribute("branch", own);
            chain.doFilter(sreq, sresp);
            return;
        }
        resp.sendRedirect(req.getContextPath() + WEBSITE_HOME);
    }

    private static boolean allowed(String path) {
        if (ALLOWED_PATHS.contains(path)) return true;
        if (path.startsWith("/website/")) return true;              // Website module (each servlet checks the site)
        if (path.startsWith("/CSS/") || path.startsWith("/assets/")) return true;
        String p = path.toLowerCase(Locale.ROOT);
        return p.endsWith(".css") || p.endsWith(".js") || p.endsWith(".png") || p.endsWith(".jpg")
                || p.endsWith(".jpeg") || p.endsWith(".svg") || p.endsWith(".ico") || p.endsWith(".gif")
                || p.endsWith(".webp") || p.endsWith(".woff") || p.endsWith(".woff2");
    }
}
