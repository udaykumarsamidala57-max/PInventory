package com.officecentral.common.web;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Predicate;
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
 * Server-side access control for screens that change stock or master data.
 *
 * For every request to a protected address (new address, old address and .jsp alias alike):
 *   1. not logged in          → login page
 *   2. role / department rule → 403 when not allowed (the menu only hides links; this is the real check)
 *   3. POST / PUT / DELETE    → must carry the session CSRF token (added automatically by header.jsp)
 *
 * Rules (same as the menu):
 *   Settings Master pages            : Global role or Finance department
 *   Issue Stock                      : Global role or Store department
 *   Dining Hall consumption entry    : Global or Admin role; Finance, Store or Dining Hall department
 *   Dining Hall consumption edit     : Global role or Dining Hall department
 */
@WebFilter(urlPatterns = {
        // Settings Master
        "/settings",
        "/items", "/ItemsMaster.jsp",
        "/item-cost",
        "/add-stock", "/AddStock", "/Addstock.jsp",
        "/wastage",
        "/menu-items", "/MenuItemsServlet", "/menu/menu_items.jsp",
        "/stock-audit", "/StockVerificationServlet", "/stock_verification.jsp",
        "/stock-audit-report", "/StockAuditReportServlet", "/stock_audit_report.jsp",
        // Issue Stock
        "/issue", "/IssueServlet",
        // Dining Hall entry
        "/dining-hall", "/DiningHallServlet",
        // Dining Hall edit
        "/edit-consumption", "/editConsumption.jsp",
        "/dining-consumption", "/FetchConsumptionByDateServlet",
        "/dining-consumption-update", "/UpdateConsumptionByDateServlet"
})
public class AccessFilter implements Filter {

    private static final Logger LOG = Logger.getLogger(AccessFilter.class.getName());

    /** Who may use a group of pages. */
    private static final class Rule {
        final String what;
        final Predicate<HttpSession> allow;
        Rule(String what, Predicate<HttpSession> allow) { this.what = what; this.allow = allow; }
    }

    static boolean isGlobalOrFinance(HttpSession s) {
        return role(s, "Global") || dept(s, "Finance");
    }

    private static final Rule SETTINGS = new Rule("Settings Master", AccessFilter::isGlobalOrFinance);
    private static final Rule ISSUE = new Rule("Issue Stock", s -> role(s, "Global") || dept(s, "Store"));
    private static final Rule DINING_ENTRY = new Rule("Dining Hall consumption entry",
            s -> role(s, "Global") || role(s, "Admin") || dept(s, "Finance") || dept(s, "Store") || dept(s, "Dining Hall"));
    private static final Rule DINING_EDIT = new Rule("Edit Consumption", s -> role(s, "Global") || dept(s, "Dining Hall"));

    private static final Map<String, Rule> RULES = new HashMap<>();
    static {
        for (String p : new String[] {"/settings", "/items", "/ItemsMaster.jsp", "/item-cost", "/add-stock", "/AddStock",
                "/Addstock.jsp", "/wastage", "/menu-items", "/MenuItemsServlet", "/menu/menu_items.jsp", "/stock-audit",
                "/StockVerificationServlet", "/stock_verification.jsp", "/stock-audit-report", "/StockAuditReportServlet",
                "/stock_audit_report.jsp"}) {
            RULES.put(p, SETTINGS);
        }
        RULES.put("/issue", ISSUE);
        RULES.put("/IssueServlet", ISSUE);
        RULES.put("/dining-hall", DINING_ENTRY);
        RULES.put("/DiningHallServlet", DINING_ENTRY);
        for (String p : new String[] {"/edit-consumption", "/editConsumption.jsp", "/dining-consumption",
                "/FetchConsumptionByDateServlet", "/dining-consumption-update", "/UpdateConsumptionByDateServlet"}) {
            RULES.put(p, DINING_EDIT);
        }
    }

    @Override
    public void init(FilterConfig filterConfig) { }

    @Override
    public void destroy() { }

    @Override
    public void doFilter(ServletRequest sreq, ServletResponse sresp, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) sreq;
        HttpServletResponse resp = (HttpServletResponse) sresp;

        // Read form fields as UTF-8 (must be set before the first getParameter call)
        if (req.getCharacterEncoding() == null) req.setCharacterEncoding("UTF-8");

        Rule rule = RULES.get(req.getServletPath());
        if (rule == null) {                       // not a protected address (should not happen)
            chain.doFilter(req, resp);
            return;
        }

        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }
        if (!rule.allow.test(s)) {
            LOG.warning("[access] DENIED " + req.getMethod() + " " + req.getServletPath() + " for user "
                    + s.getAttribute("username") + " (role " + s.getAttribute("role") + ", dept "
                    + s.getAttribute("department") + ")");
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have access to " + rule.what + ".");
            return;
        }
        String m = req.getMethod();
        if (!"GET".equalsIgnoreCase(m) && !"HEAD".equalsIgnoreCase(m) && !"OPTIONS".equalsIgnoreCase(m)) {
            if (!Csrf.valid(req, s)) {
                LOG.warning("[access] CSRF token missing/invalid on " + m + " " + req.getServletPath()
                        + " for user " + s.getAttribute("username"));
                resp.sendError(HttpServletResponse.SC_FORBIDDEN,
                        "This form has expired or did not come from this site. Please reload the page and try again.");
                return;
            }
        }
        chain.doFilter(req, resp);
    }

    private static boolean role(HttpSession s, String r) {
        Object v = s.getAttribute("role");
        return v != null && r.equalsIgnoreCase(String.valueOf(v).trim());
    }

    private static boolean dept(HttpSession s, String d) {
        Object v = s.getAttribute("department");
        return v != null && d.equalsIgnoreCase(String.valueOf(v).trim());
    }
}
