package com.officecentral.common.web;

import com.officecentral.common.access.AccessControl;
import com.officecentral.common.config.AppConfig;
import com.officecentral.common.sso.PhrmsSsoToken;
import java.io.IOException;
import java.net.URI;
import java.security.GeneralSecurityException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/** Turns a signed-in PInventory session into a one-use POST ticket for PHRMS (HR & Payroll). */
@WebServlet("/phrms/sso")
public class PhrmsSsoServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final String DEFAULT_BASE_URL = "http://localhost:8084/";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
        HttpSession session = request.getSession(false);
        Object signedInUsername = session == null ? null : session.getAttribute("username");
        if (!(signedInUsername instanceof String username) || username.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        // Server-side check (the menu only hides the link). Default before Access Control is set up: Global only.
        if (!AccessControl.show(session, "phrms.link", "Global".equalsIgnoreCase(String.valueOf(session.getAttribute("role"))))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have access to HR & Payroll.");
            return;
        }

        try {
            String token = PhrmsSsoToken.issue(username, AppConfig.require("PHRMS_SSO_SECRET"));
            String action = ssoEndpoint(AppConfig.get("PHRMS_BASE_URL"));
            response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
            response.setHeader("Pragma", "no-cache");
            response.setHeader("Referrer-Policy", "no-referrer");
            response.setHeader("X-Content-Type-Options", "nosniff");
            response.setContentType("text/html;charset=UTF-8");
            response.getWriter().write("<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">"
                    + "<meta name=\"referrer\" content=\"no-referrer\"><title>Opening HR &amp; Payroll</title></head><body>"
                    + "<p>Opening HR &amp; Payroll…</p><form id=\"sso\" method=\"post\" action=\"" + escapeHtml(action) + "\">"
                    + "<input type=\"hidden\" name=\"token\" value=\"" + escapeHtml(token) + "\">"
                    + "<noscript><button type=\"submit\">Continue to HR &amp; Payroll</button></noscript></form>"
                    + "<script>document.getElementById('sso').submit();</script></body></html>");
        } catch (IllegalStateException | IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                    "HR & Payroll single sign-on is not configured. Contact your administrator.");
        } catch (GeneralSecurityException e) {
            throw new ServletException("Could not create PHRMS sign-on ticket.", e);
        }
    }

    private static String ssoEndpoint(String configuredBaseUrl) {
        String base = configuredBaseUrl == null || configuredBaseUrl.isBlank()
                ? DEFAULT_BASE_URL : configuredBaseUrl.trim();
        URI uri = URI.create(base.endsWith("/") ? base : base + "/");
        String scheme = uri.getScheme();
        String host = uri.getHost();
        boolean loopback = "localhost".equalsIgnoreCase(host) || "127.0.0.1".equals(host) || "[::1]".equals(host);
        if (host == null || uri.getUserInfo() != null || uri.getRawQuery() != null || uri.getRawFragment() != null
                || !("https".equalsIgnoreCase(scheme) || ("http".equalsIgnoreCase(scheme) && loopback))) {
            throw new IllegalArgumentException("PHRMS must use HTTPS, except for local loopback development.");
        }
        return uri.resolve("sso/login").toASCIIString();
    }

    private static String escapeHtml(String value) {
        return value.replace("&", "&amp;").replace("\"", "&quot;").replace("<", "&lt;").replace(">", "&gt;");
    }
}
