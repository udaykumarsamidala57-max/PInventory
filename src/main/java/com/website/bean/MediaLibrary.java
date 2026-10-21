package com.website.bean;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Photo Library: folders of photos / videos in the bucket, used by the Page Builder.
 *
 * Every website has its own library:  srs/library/...   sanpoly/library/...
 * A folder is a name ending in "/" (an empty folder keeps a small ".folder" marker file).
 * Library files are never removed when a page, section or photo is deleted in the Page Builder -
 * only from the Photo Library itself, and only when no page uses them any more.
 */
public final class MediaLibrary {

    public static final String MARKER = ".folder";

    private MediaLibrary() { }

    /** e.g. "srs/library/" */
    public static String root(String site) {
        String s = site == null ? "site" : site.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9_-]", "");
        return s + "/library/";
    }

    /** true for any file inside a Photo Library (such files are protected from automatic clean-up) */
    public static boolean isLibraryKey(String key) {
        return key != null && key.contains("/library/");
    }

    /** true when the key belongs to this site's library */
    public static boolean inLibrary(String site, String key) {
        return key != null && key.startsWith(root(site)) && !key.contains("..") && !key.endsWith("/");
    }

    /**
     * Cleans a folder path typed or clicked in the browser ("Events/Annual Day") into "Events/Annual-Day/".
     * Returns "" for the top level.
     */
    public static String cleanFolder(String path) {
        if (path == null) return "";
        StringBuilder out = new StringBuilder();
        for (String part : path.replace('\\', '/').split("/")) {
            String p = cleanName(part);
            if (p.isEmpty() || p.equals(".") || p.equals("..")) continue;
            out.append(p).append('/');
        }
        return out.toString();
    }

    /** One folder or file name: letters, digits, space-to-dash, dot, dash, underscore; max 80 characters. */
    public static String cleanName(String name) {
        if (name == null) return "";
        String n = name.trim().replaceAll("\\s+", "-").replaceAll("[^A-Za-z0-9._-]", "");
        n = n.replaceAll("-{2,}", "-").replaceAll("^[.-]+", "");
        return n.length() > 80 ? n.substring(0, 80) : n;
    }

    public static String contentTypeOf(String key) {
        String k = key == null ? "" : key.toLowerCase(Locale.ROOT);
        if (k.endsWith(".jpg") || k.endsWith(".jpeg")) return "image/jpeg";
        if (k.endsWith(".png")) return "image/png";
        if (k.endsWith(".gif")) return "image/gif";
        if (k.endsWith(".webp")) return "image/webp";
        if (k.endsWith(".svg")) return "image/svg+xml";
        if (k.endsWith(".mp4")) return "video/mp4";
        if (k.endsWith(".webm")) return "video/webm";
        if (k.endsWith(".mov")) return "video/quicktime";
        return "application/octet-stream";
    }

    public static boolean isMedia(String key) {
        String t = contentTypeOf(key);
        return t.startsWith("image/") || t.startsWith("video/");
    }

    /** Creates a sub-folder inside folder (relative to the library root). Returns its relative path. */
    public static String createFolder(String site, String folder, String name) throws IOException {
        String n = cleanName(name);
        if (n.isEmpty()) throw new IllegalArgumentException("Please type a folder name.");
        String rel = cleanFolder(folder) + n + "/";
        PhotoStore.put(root(site) + rel + MARKER, new byte[0], "application/octet-stream");
        return rel;
    }

    /** Saves one uploaded file into folder; if the name is taken a number is added. Returns the key. */
    public static String upload(String site, String folder, String fileName, InputStream in, long size,
                                String contentType, PhotoStore.Listing existing) throws IOException {
        String name = cleanName(fileName);
        String ext = "";
        int dot = name.lastIndexOf('.');
        if (dot > 0) {
            ext = name.substring(dot).toLowerCase(Locale.ROOT);
            name = name.substring(0, dot);
        }
        String known = PhotoStore.extension(contentType);
        if (!known.isEmpty() && !(known.equals(".jpg") && ext.equals(".jpeg"))) ext = known;
        if (name.isEmpty()) name = "photo";

        String base = root(site) + cleanFolder(folder);
        String key = base + name + ext;
        int n = 1;
        while (taken(existing, key)) key = base + name + "-" + (n++) + ext;
        PhotoStore.put(key, in, size, contentType);
        if (existing != null) existing.files.add(new PhotoStore.Item(key, size, null));
        return key;
    }

    private static boolean taken(PhotoStore.Listing l, String key) {
        if (l == null) return false;
        for (PhotoStore.Item i : l.files) if (i.key.equals(key)) return true;
        return false;
    }

    /** Pages (titles) that still show this library file, at most 5. */
    public static List<String> usedBy(Connection conn, String key) {
        List<String> pages = new ArrayList<>();
        if (!PhotoUpload.hasKeyColumn(conn, "section_images")) return pages;
        try (PreparedStatement p = conn.prepareStatement(
                "SELECT DISTINCT COALESCE(pg.title, CONCAT('Page ', s.page_id)) FROM section_images i "
                + "JOIN sections s ON s.id = i.section_id LEFT JOIN pages pg ON pg.id = s.page_id "
                + "WHERE i.file_key = ? LIMIT 5")) {
            p.setString(1, key);
            try (ResultSet rs = p.executeQuery()) {
                while (rs.next()) pages.add(rs.getString(1));
            }
        } catch (SQLException e) {
            // tables differ: treat as not used
        }
        return pages;
    }
}
