package com.website.bean;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.officecentral.common.config.AppConfig;

/**
 * Database for the Website module (the school website content: pages, news, upcoming events).
 * Moved here from the SWebsite project. The website has two databases, SRS and Sanpoly;
 * the PInventory store the user is working in decides which one is used:
 *   SRS, SRS_HOSTEL                                    -> SRS website
 *   SANPOLY BOYS, SANPOLY GIRLS, Sanpoly, Sanpoly2     -> Sanpoly website
 */
public class WebsiteDB {


    // Server, user and password are not kept in the code: see com.officecentral.common.config.AppConfig
    // (WEBSITE_SRS_DB_HOST / _PORT / _USER / _PASSWORD and WEBSITE_SANPOLY_DB_...).

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    /** Website ("SRS" or "Sanpoly") for a PInventory store code. */
    public static String siteOf(String store) {
        return store != null && store.toUpperCase().contains("SANPOLY") ? "Sanpoly" : "SRS";
    }

    /** Website for the store selected in this session. */
    public static String site(HttpSession sess) {
        return siteOf(sess == null ? null : (String) sess.getAttribute("branch"));
    }

    /** Website pages are for role Global / Admin or the Finance department (same as the Website menu). */
    public static boolean allowed(HttpSession sess) {
        if (sess == null || sess.getAttribute("username") == null) return false;
        String role = (String) sess.getAttribute("role");
        String dept = (String) sess.getAttribute("department");
        return "Global".equalsIgnoreCase(role) || "Admin".equalsIgnoreCase(role) || "Finance".equalsIgnoreCase(dept);
    }

    /** Logged in and allowed? Otherwise sends the user to login / Home and returns false. */
    public static boolean guard(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession sess = req.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return false;
        }
        if (!allowed(sess)) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return false;
        }
        return true;
    }

    public static Connection getConnection(String branch) throws SQLException {
        return "SRS".equalsIgnoreCase(siteOf(branch))
                ? AppConfig.connect("WEBSITE_SRS_DB_", "website")
                : AppConfig.connect("WEBSITE_SANPOLY_DB_", "SanWeb");
    }
}
