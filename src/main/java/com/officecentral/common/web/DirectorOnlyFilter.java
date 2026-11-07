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
 * Users with role "Director" use only the Director Portal. After login (the store choice) and whenever they open
 * any other Office Central page, they are sent to /director/sso, which signs them in to the Director Portal.
 * Server-side check, not just a hidden menu. Same idea as WebsiteOnlyFilter.
 */
@WebFilter("/*")
public class DirectorOnlyFilter implements Filter {

    static final String DIRECTOR_ROLE = "Director";
    static final String DIRECTOR_HOME = "/director/sso";

    /** Sign in / out pages a Director still needs. */
    private static final Set<String> ALLOWED_PATHS = Set.of(
            "/login", "/LoginServlet", "/login.jsp", "/Logout.jsp",
            "/verify-otp", "/VerifyOtpServlet", "/send-otp", "/SendOTPServlet", DIRECTOR_HOME);

    /** True when the signed-in user's role is Director (non-breaking spaces and case ignored). */
    static boolean isDirector(HttpSession s) {
        Object role = s == null ? null : s.getAttribute("role");
        return role != null && DIRECTOR_ROLE.equalsIgnoreCase(role.toString().replace(' ', ' ').trim());
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
        if (s == null || s.getAttribute("username") == null || !isDirector(s)) {
            chain.doFilter(sreq, sresp);
            return;
        }
        String path = req.getServletPath() + (req.getPathInfo() == null ? "" : req.getPathInfo());
        if (allowed(path)) {
            chain.doFilter(sreq, sresp);
            return;
        }
        ((HttpServletResponse) sresp).sendRedirect(req.getContextPath() + DIRECTOR_HOME);
    }

    private static boolean allowed(String path) {
        if (ALLOWED_PATHS.contains(path)) return true;
        if (path.startsWith("/CSS/") || path.startsWith("/assets/")) return true;   // login page styles and images
        String p = path.toLowerCase(Locale.ROOT);
        return p.endsWith(".css") || p.endsWith(".png") || p.endsWith(".jpg") || p.endsWith(".jpeg")
                || p.endsWith(".svg") || p.endsWith(".ico") || p.endsWith(".gif") || p.endsWith(".webp")
                || p.endsWith(".woff") || p.endsWith(".woff2") || p.endsWith(".js");
    }
}
