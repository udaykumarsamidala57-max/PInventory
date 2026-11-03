package com.website.bean;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.http.HttpServletRequest;

/**
 * All websites share one database. These checks stop a user working in one website
 * (chosen by their PInventory store) from reading or changing another website's rows
 * by changing an id in the URL or form.
 */
public final class WebsiteScope {

    private WebsiteScope() { }

    public static boolean pageInSite(Connection conn, long pageId, String siteKey) throws SQLException {
        return exists(conn, "SELECT 1 FROM pages WHERE id = ? AND site = ?", pageId, siteKey);
    }

    public static boolean sectionInSite(Connection conn, long sectionId, String siteKey) throws SQLException {
        return exists(conn,
                "SELECT 1 FROM sections s JOIN pages p ON p.id = s.page_id WHERE s.id = ? AND p.site = ?",
                sectionId, siteKey);
    }

    public static boolean imageInSite(Connection conn, long imageId, String siteKey) throws SQLException {
        return exists(conn,
                "SELECT 1 FROM section_images i JOIN sections s ON s.id = i.section_id "
              + "JOIN pages p ON p.id = s.page_id WHERE i.id = ? AND p.site = ?",
                imageId, siteKey);
    }

    /** latest_news / upcoming_events row of this website? */
    public static boolean rowInSite(Connection conn, String table, long id, String siteKey) throws SQLException {
        if (!"latest_news".equals(table) && !"upcoming_events".equals(table)) {
            throw new IllegalArgumentException("Unsupported table");
        }
        return exists(conn, "SELECT 1 FROM " + table + " WHERE id = ? AND site = ?", id, siteKey);
    }

    /**
     * Checks every id parameter the Page Builder uses: id / pageId / parentId (pages),
     * sectionId (sections), imageId (photos). Blank parameters are ignored; a value that is
     * not a number, or belongs to another website, fails the check.
     */
    public static boolean pageBuilderParamsAllowed(Connection conn, HttpServletRequest req, String siteKey)
            throws SQLException {
        if (siteKey == null) return false;
        for (String p : new String[] {"id", "pageId", "parentId"}) {
            String raw = req.getParameter(p);
            if (blank(raw)) continue;
            Long v = parse(raw);
            if (v == null || !pageInSite(conn, v, siteKey)) return false;
        }
        String sec = req.getParameter("sectionId");
        if (!blank(sec)) {
            Long v = parse(sec);
            if (v == null || !sectionInSite(conn, v, siteKey)) return false;
        }
        String img = req.getParameter("imageId");
        if (!blank(img)) {
            Long v = parse(img);
            if (v == null || !imageInSite(conn, v, siteKey)) return false;
        }
        return true;
    }

    private static Long parse(String v) {
        try {
            return Long.parseLong(v.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static boolean blank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private static boolean exists(Connection conn, String sql, long id, String siteKey) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.setString(2, siteKey);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }
}
