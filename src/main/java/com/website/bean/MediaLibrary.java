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

    /** e.g. "srs/" - everything of this website in the bucket (library + earlier uploads) */
    public static String siteRoot(String site) {
        return root(site).substring(0, root(site).length() - "library/".length());
    }

    /** true for a photo / video of this website anywhere in the bucket (library or earlier uploads) */
    public static boolean inSite(String site, String key) {
        return key != null && key.startsWith(siteRoot(site)) && !key.contains("..") && !key.endsWith("/") && isMedia(key);
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

    /** Result of a move. */
    public static final class MoveResult {
        public int files;          // files moved
        public int rowsUpdated;    // MySQL rows that now point to the new places
        public final List<String> notes = new ArrayList<>();
    }

    private static final String[] PHOTO_TABLES = { "section_images", "latest_news", "upcoming_events" };

    /**
     * Moves files and folders into a library folder, and points every page / news / event row to the new places.
     *   sources: full bucket keys of files ("srs/library/a.jpg", "srs/sections/12-x.jpg")
     *            or full folder prefixes ending in "/" ("srs/library/Events/", "srs/news/")
     *   target:  library folder, relative to the library ("" = top level, "Events/2026/")
     * Order: copy everything -> update MySQL in one transaction -> delete the old files.
     * If MySQL fails, the copies are removed again and nothing changes.
     */
    public static MoveResult move(String site, List<String> sources, String target, Connection conn)
            throws IOException, SQLException {
        String siteRoot = siteRoot(site);
        String targetPrefix = root(site) + cleanFolder(target);
        MoveResult r = new MoveResult();

        // names already used in the target folder
        java.util.Set<String> used = new java.util.HashSet<>();
        PhotoStore.Listing there = PhotoStore.list(targetPrefix);
        for (PhotoStore.Item i : there.files) used.add(i.key);
        for (String f : there.folders) used.add(f);

        java.util.Map<String, String> plan = new java.util.LinkedHashMap<>();   // old key -> new key
        for (String src : sources) {
            if (src == null || !src.startsWith(siteRoot) || src.contains("..") || src.equals(siteRoot)
                    || src.equals(root(site))) {
                r.notes.add("Skipped " + src);
                continue;
            }
            if (src.endsWith("/")) {                                   // a folder
                if (targetPrefix.startsWith(src)) {
                    r.notes.add("A folder cannot be moved into itself: " + shortName(src));
                    continue;
                }
                String parent = src.substring(0, src.substring(0, src.length() - 1).lastIndexOf('/') + 1);
                if (parent.equals(targetPrefix)) { r.notes.add(shortName(src) + " is already there"); continue; }
                String name = shortName(src);
                String dest = targetPrefix + name + "/";
                for (int n = 1; used.contains(dest); n++) dest = targetPrefix + name + "-" + n + "/";
                used.add(dest);
                for (PhotoStore.Item i : PhotoStore.listAll(src)) {
                    plan.put(i.key, dest + i.key.substring(src.length()));
                }
            } else {                                                   // one file
                String parent = src.substring(0, src.lastIndexOf('/') + 1);
                if (parent.equals(targetPrefix)) { r.notes.add(shortName(src) + " is already there"); continue; }
                String name = src.substring(src.lastIndexOf('/') + 1);
                String base = name, ext = "";
                int dot = name.lastIndexOf('.');
                if (dot > 0) { base = name.substring(0, dot); ext = name.substring(dot); }
                String dest = targetPrefix + name;
                for (int n = 1; used.contains(dest); n++) dest = targetPrefix + base + "-" + n + ext;
                used.add(dest);
                plan.put(src, dest);
            }
        }
        if (plan.isEmpty()) return r;
        if (plan.size() > 3000) throw new IllegalStateException("Too many files in one move (" + plan.size() + "). Move smaller folders.");

        // 1) copy
        List<String> copied = new ArrayList<>();
        try {
            for (java.util.Map.Entry<String, String> e : plan.entrySet()) {
                PhotoStore.copy(e.getKey(), e.getValue());
                copied.add(e.getValue());
            }
        } catch (IOException e) {
            for (String k : copied) try { PhotoStore.delete(k); } catch (IOException ignore) { }
            throw new IOException("Moving stopped, nothing was changed: " + e.getMessage(), e);
        }

        // 2) point MySQL rows to the new places (all or nothing)
        boolean auto = conn.getAutoCommit();
        try {
            conn.setAutoCommit(false);
            for (String t : PHOTO_TABLES) {
                if (!PhotoUpload.hasKeyColumn(conn, t)) continue;
                try (PreparedStatement ps = conn.prepareStatement("UPDATE " + t + " SET file_key = ? WHERE file_key = ?")) {
                    for (java.util.Map.Entry<String, String> e : plan.entrySet()) {
                        ps.setString(1, e.getValue());
                        ps.setString(2, e.getKey());
                        ps.addBatch();
                    }
                    for (int n : ps.executeBatch()) if (n > 0) r.rowsUpdated += n;
                }
            }
            conn.commit();
        } catch (SQLException e) {
            try { conn.rollback(); } catch (SQLException ignore) { }
            for (String k : copied) try { PhotoStore.delete(k); } catch (IOException ignore) { }
            throw new SQLException("Moving stopped, nothing was changed (database): " + e.getMessage(), e);
        } finally {
            try { conn.setAutoCommit(auto); } catch (SQLException ignore) { }
        }

        // 3) remove the old files
        for (String oldKey : plan.keySet()) {
            try {
                PhotoStore.delete(oldKey);
            } catch (IOException e) {
                r.notes.add("Old copy left behind: " + oldKey);
            }
        }
        for (String k : plan.keySet()) if (!k.endsWith("/" + MARKER)) r.files++;
        return r;
    }

    private static String shortName(String keyOrPrefix) {
        String s = keyOrPrefix.endsWith("/") ? keyOrPrefix.substring(0, keyOrPrefix.length() - 1) : keyOrPrefix;
        return s.substring(s.lastIndexOf('/') + 1);
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
