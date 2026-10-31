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

/**
 * Receptionists use only Visitor Management. Any other PInventory page sends them to the
 * Visitor Management (School Operations) sign-on. This is a server-side check, not just a hidden menu.
 */
@WebFilter("/*")
public class VisitorOnlyFilter implements Filter {

    /** Role names (any case) that may use only Visitor Management. "Receptionst" is the role name in use. */
    private static final Set<String> RECEPTION_ROLES = Set.of("receptionst", "receptionist", "reception");

    /** Pages a receptionist still needs: sign in / out, the hand-over to Visitor Management, the Android API. */
    private static final Set<String> ALLOWED_PATHS = Set.of(
            "/school-operations/sso", "/login", "/LoginServlet", "/login.jsp", "/Logout.jsp",
            "/verify-otp", "/VerifyOtpServlet", "/SendOTPServlet", "/Androidapp.jsp");

    public static boolean isReceptionist(Object role) {
        return role != null && RECEPTION_ROLES.contains(String.valueOf(role).trim().toLowerCase(Locale.ROOT));
    }

    @Override
    public void init(FilterConfig filterConfig) { }

    @Override
    public void destroy() { }

    @Override
    public void doFilter(ServletRequest sreq, ServletResponse sresp, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) sreq;
        HttpSession s = req.getSession(false);
        if (s == null || !isReceptionist(s.getAttribute("role")) || allowed(req)) {
            chain.doFilter(sreq, sresp);
            return;
        }
        ((HttpServletResponse) sresp).sendRedirect(req.getContextPath() + "/school-operations/sso");
    }

    private static boolean allowed(HttpServletRequest req) {
        String path = req.getServletPath() + (req.getPathInfo() == null ? "" : req.getPathInfo());
        if (ALLOWED_PATHS.contains(path)) return true;
        // Android app API (has its own feature checks), app downloads and static files.
        if (path.startsWith("/api/mobile/") || path.startsWith("/mobile-app/")
                || path.startsWith("/CSS/") || path.startsWith("/assets/")) return true;
        String p = path.toLowerCase(Locale.ROOT);
        return p.endsWith(".css") || p.endsWith(".js") || p.endsWith(".png") || p.endsWith(".jpg")
                || p.endsWith(".jpeg") || p.endsWith(".svg") || p.endsWith(".ico") || p.endsWith(".gif")
                || p.endsWith(".webp") || p.endsWith(".woff") || p.endsWith(".woff2");
    }
}
