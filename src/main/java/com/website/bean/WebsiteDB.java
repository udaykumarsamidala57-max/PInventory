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

    /** Website pages are for users with role Global only (same rule as the Website menu). */
    public static boolean allowed(HttpSession sess) {
        if (sess == null || sess.getAttribute("username") == null) return false;
        String role = (String) sess.getAttribute("role");
        return role != null && "Global".equalsIgnoreCase(role.trim());
    }

    /**
     * Deleting pages, sections, photos, news or events is only for these users (comma separated).
     * Default: udaykumar. Can be changed with the setting WEBSITE_DELETE_USERS (Railway variable / pinventory.properties).
     */
    public static boolean canDelete(HttpSession sess) {
        if (!allowed(sess)) return false;
        String user = String.valueOf(sess.getAttribute("username")).trim();
        String list = com.officecentral.common.config.AppConfig.get("WEBSITE_DELETE_USERS");
        if (list == null) list = "udaykumar";
        for (String u : list.split(",")) {
            if (u.trim().equalsIgnoreCase(user)) return true;
        }
        return false;
    }

    /** Stops a delete for everyone else. Returns false (and answers 403) when this user may not delete. */
    public static boolean guardDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (canDelete(req.getSession(false))) return true;
        resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Deleting on the website is not allowed for your user.");
        return false;
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
