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
 *
 * ONE database ("website") holds every school website. Each page, news item and event row has
 * a "site" column ('srs', 'sanpoly', ...); sections and photos belong to a site through their page.
 * The PInventory store the user is working in decides the website:
 *   SRS, SRS_HOSTEL                                    -> SRS website      (site 'srs',     bucket folder srs/)
 *   SANPOLY BOYS, SANPOLY GIRLS, Sanpoly, Sanpoly2     -> Sanpoly website  (site 'sanpoly', bucket folder SANPOLY-WEBSITE/)
 * Photos are kept ONLY in the bucket; MySQL keeps just the path (file_key).
 * Must match SRSWebsite: src/main/webapp/WEB-INF/sites.properties.
 */
public class WebsiteDB {


    // Server, user and password are not kept in the code: see com.officecentral.common.config.AppConfig
    // (WEBSITE_SRS_DB_HOST / _PORT / _USER / _PASSWORD). All websites use this one database.

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

    /** Value of the "site" column for a website ("SRS" -> "srs", "Sanpoly" -> "sanpoly"). */
    public static String siteKey(String site) {
        return "Sanpoly".equalsIgnoreCase(siteOf(site)) ? "sanpoly" : "srs";
    }

    /** Bucket folder of a website's photos ("SRS" -> "srs", "Sanpoly" -> "SANPOLY-WEBSITE"). */
    public static String folder(String site) {
        return "Sanpoly".equalsIgnoreCase(siteOf(site)) ? "SANPOLY-WEBSITE" : "srs";
    }

    /**
     * Website for this session. Global users: the store they selected.
     * Website-role users: ALWAYS their own branch from the users table (assignedBranch, set at login),
     * so they can never reach another school's website by choosing or faking a store.
     */
    public static String site(HttpSession sess) {
        if (sess == null) return siteOf(null);
        if (isWebsiteUser(sess)) return siteOf((String) sess.getAttribute("assignedBranch"));
        return siteOf((String) sess.getAttribute("branch"));
    }

    /** Role "Website": may use only the Website pages, and only for their own branch's website. */
    public static boolean isWebsiteUser(HttpSession sess) {
        if (sess == null) return false;
        Object role = sess.getAttribute("role");
        return role != null && "Website".equalsIgnoreCase(String.valueOf(role).trim());
    }

    /** Website pages are for role Global, and for role Website when the user has a branch assigned. */
    public static boolean allowed(HttpSession sess) {
        if (sess == null || sess.getAttribute("username") == null) return false;
        String role = (String) sess.getAttribute("role");
        if (role != null && "Global".equalsIgnoreCase(role.trim())) return true;
        if (isWebsiteUser(sess)) {
            Object b = sess.getAttribute("assignedBranch");
            return b != null && !String.valueOf(b).trim().isEmpty();   // no branch = no website
        }
        return false;
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

    /** The one website database (all sites). Rows are kept apart by the "site" column. */
    public static Connection getConnection(String branch) throws SQLException {
        return AppConfig.connect("WEBSITE_SRS_DB_", "website");
    }
}
