package com.website.bean;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Admin helpers for photos kept in the Railway bucket.
 *
 * MySQL keeps only the photo's place in the bucket (column file_key);
 * the old picture column is left empty for new uploads.
 *
 * Bucket uploads are used for the SRS branch. Other branches (Sanpoly) keep
 * saving into MySQL until their public website reads from the bucket too.
 */
public final class PhotoUpload {

    private PhotoUpload() { }

    private static final Map<String, Boolean> KEY_COLUMN = new ConcurrentHashMap<>();

    /** true when new uploads for this branch go to the bucket */
    public static boolean on(String branch) {
        return PhotoStore.enabled() && "SRS".equalsIgnoreCase(branch);
    }

    /** does this table have the file_key column (added by /admin/move-photos)? */
    public static boolean hasKeyColumn(Connection conn, String table) {
        String cacheKey;
        try {
            cacheKey = conn.getCatalog() + "." + table;
        } catch (SQLException e) {
            cacheKey = table;
        }
        Boolean known = KEY_COLUMN.get(cacheKey);
        if (Boolean.TRUE.equals(known)) return true;
        boolean has = false;
        try (PreparedStatement p = conn.prepareStatement(
                "SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() "
                        + "AND table_name = ? AND column_name = 'file_key'")) {
            p.setString(1, table);
            try (ResultSet rs = p.executeQuery()) { has = rs.next(); }
        } catch (SQLException e) {
            has = false;
        }
        if (has) KEY_COLUMN.put(cacheKey, true);
        return has;
    }

    /** the photo's place in the bucket, or null */
    public static String keyOf(Connection conn, String table, long id) {
        if (!hasKeyColumn(conn, table)) return null;
        try (PreparedStatement p = conn.prepareStatement("SELECT file_key FROM " + table + " WHERE id = ?")) {
            p.setLong(1, id);
            try (ResultSet rs = p.executeQuery()) {
                if (rs.next()) {
                    String k = rs.getString(1);
                    return (k == null || k.trim().isEmpty()) ? null : k.trim();
                }
            }
        } catch (SQLException e) {
            return null;
        }
        return null;
    }

    /** places of several photos, e.g. all photos of a section before it is deleted */
    public static List<String> keys(Connection conn, String sql, long id) {
        List<String> out = new ArrayList<>();
        try (PreparedStatement p = conn.prepareStatement(sql)) {
            p.setLong(1, id);
            try (ResultSet rs = p.executeQuery()) {
                while (rs.next()) {
                    String k = rs.getString(1);
                    if (k != null && !k.trim().isEmpty()) out.add(k.trim());
                }
            }
        } catch (SQLException e) {
            // column missing or other problem: nothing to clean up
        }
        return out;
    }

    /**
     * Uploads a photo for an existing row: saves it in the bucket, writes file_key,
     * empties the old picture column, then removes the row's previous photo file.
     */
    public static String store(Connection conn, String table, String blobColumn, long id, String branch,
                               String folder, InputStream in, long size, String contentType) throws SQLException {
        String type = (contentType == null || contentType.trim().isEmpty() || !contentType.contains("/"))
                ? "image/jpeg" : contentType.trim().toLowerCase();

        String old = keyOf(conn, table, id);
        String key = PhotoStore.newKey(branch, folder, id, type);
        try {
            PhotoStore.put(key, in, size, type);
        } catch (IOException e) {
            throw new SQLException("Could not save the photo in the bucket: " + e.getMessage(), e);
        }

        try (PreparedStatement p = conn.prepareStatement(
                "UPDATE " + table + " SET file_key = ?, " + blobColumn + " = ? WHERE id = ?")) {
            p.setString(1, key);
            p.setBytes(2, new byte[0]);
            p.setLong(3, id);
            p.executeUpdate();
        }

        if (old != null && !old.equals(key)) deleteFile(old);
        return key;
    }

    /** removes a photo file from the bucket; problems are ignored */
    public static void deleteFile(String key) {
        if (key == null || key.trim().isEmpty() || !PhotoStore.enabled()) return;
        if (MediaLibrary.isLibraryKey(key)) return;      // Photo Library files are only removed from the Photo Library
        try {
            PhotoStore.delete(key.trim());
        } catch (Exception e) {
            System.err.println("PhotoUpload: could not delete " + key + ": " + e.getMessage());
        }
    }

    public static void deleteFiles(List<String> keys) {
        for (String k : keys) deleteFile(k);
    }

    /** removes files only when no row in the table still uses them (e.g. after a delete that did not cascade) */
    public static void deleteFilesIfUnused(Connection conn, String table, List<String> keys) {
        for (String k : keys) {
            boolean used = true;
            try (PreparedStatement p = conn.prepareStatement("SELECT 1 FROM " + table + " WHERE file_key = ?")) {
                p.setString(1, k);
                try (ResultSet rs = p.executeQuery()) { used = rs.next(); }
            } catch (SQLException e) {
                used = true;
            }
            if (!used) deleteFile(k);
        }
    }

    /**
     * src for an <img>: the bucket link when the photo is in the bucket,
     * otherwise the old picture bytes as data:...;base64, otherwise "".
     */
    public static String src(String key, byte[] bytes) {
        if (key != null && !key.trim().isEmpty() && PhotoStore.enabled()) return PhotoStore.url(key.trim());
        if (bytes != null && bytes.length > 0) {
            String type = PhotoStore.sniff(bytes, "image/jpeg");
            return "data:" + type + ";base64," + Base64.getEncoder().encodeToString(bytes);
        }
        return "";
    }
}
