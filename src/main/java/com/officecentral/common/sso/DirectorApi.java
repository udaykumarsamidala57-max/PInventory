package com.officecentral.common.sso;

import java.io.IOException;
import java.io.InputStream;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Logger;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.Gson;
import com.officecentral.common.config.AppConfig;
import com.officecentral.common.db.InventoryDB;

/**
 * Server-to-server calls from the Director Portal (approvals). Each call is signed with HMAC-SHA256 using its own key
 * DIRECTOR_PINVENTORY_API_SECRET (not the PHRMS / School Operations keys). Canonical text, same as the portal:
 *     "DIRECTOR>PINVENTORY\n" + timestamp + "\n" + METHOD + "\n" + request URI (+ "?" + query) + "\n" + body
 * Timestamp must be within ±60 s. Body = URL-encoded name=value text. No session, no cookies.
 * The servlet then applies PInventory's own permission rules for the named user and runs the existing code.
 */
public final class DirectorApi {

    private static final Logger LOG = Logger.getLogger(DirectorApi.class.getName());
    static final String AUDIENCE = "DIRECTOR>PINVENTORY";
    static final long WINDOW_SECONDS = 60;
    static final int MAX_BODY = 16 * 1024;

    /** A PInventory user as stored in users (password never read). */
    public static final class User {
        public final int id;
        public final String username, role, department;
        User(int id, String username, String role, String department) {
            this.id = id; this.username = username; this.role = role; this.department = department;
        }
        public boolean global() { return role != null && "Global".equalsIgnoreCase(role.trim()); }
    }

    private DirectorApi() { }

    /** Reads and checks the signed request; returns its fields, or null after sending 401/413/503. */
    public static Map<String, String> verified(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String secret = AppConfig.get("DIRECTOR_PINVENTORY_API_SECRET");
        if (secret == null || !secret.matches("[0-9a-fA-F]{64}")) {
            resp.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE, "Director Portal connection is not configured.");
            return null;
        }
        byte[] body;
        try (InputStream in = req.getInputStream()) {
            body = in.readNBytes(MAX_BODY + 1);
        }
        if (body.length > MAX_BODY) {
            resp.sendError(HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE);
            return null;
        }
        String text = new String(body, StandardCharsets.UTF_8);
        String path = req.getRequestURI() + (req.getQueryString() == null ? "" : "?" + req.getQueryString());
        if (!verify(secret, req.getMethod(), path, req.getHeader("X-Director-Timestamp"), req.getHeader("X-Director-Signature"),
                text, System.currentTimeMillis() / 1000L)) {
            LOG.warning("[director-api] rejected unsigned/invalid " + req.getMethod() + " " + req.getRequestURI() + " from " + req.getRemoteAddr());
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return null;
        }
        return form(text);
    }

    static boolean verify(String secret, String method, String path, String timestamp, String signature, String body, long now) {
        if (timestamp == null || signature == null || !signature.matches("[0-9a-fA-F]{64}")) return false;
        try {
            long issuedAt = Long.parseLong(timestamp);
            if (Math.abs(now - issuedAt) > WINDOW_SECONDS) return false;
            String canonical = AUDIENCE + "\n" + timestamp + "\n" + method.toUpperCase(Locale.ROOT) + "\n" + path + "\n" + body;
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(HexFormat.of().parseHex(secret), "HmacSHA256"));
            byte[] expected = HexFormat.of().formatHex(mac.doFinal(canonical.getBytes(StandardCharsets.UTF_8)))
                    .getBytes(StandardCharsets.US_ASCII);
            return MessageDigest.isEqual(expected, signature.toLowerCase(Locale.ROOT).getBytes(StandardCharsets.US_ASCII));
        } catch (RuntimeException | GeneralSecurityException e) {
            return false;
        }
    }

    static Map<String, String> form(String body) {
        Map<String, String> out = new LinkedHashMap<>();
        if (body == null || body.isEmpty()) return out;
        for (String pair : body.split("&")) {
            int eq = pair.indexOf('=');
            String k = URLDecoder.decode(eq < 0 ? pair : pair.substring(0, eq), StandardCharsets.UTF_8);
            String v = eq < 0 ? "" : URLDecoder.decode(pair.substring(eq + 1), StandardCharsets.UTF_8);
            out.putIfAbsent(k, v);
        }
        return out;
    }

    /** The user named in the call, or null when not found. */
    public static User user(String username) throws SQLException {
        if (username == null || username.isBlank() || username.length() > 50) return null;
        try (Connection c = InventoryDB.getAuthConnection();
             PreparedStatement ps = c.prepareStatement("SELECT id, username, role, department FROM users WHERE username = ?")) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? new User(rs.getInt(1), rs.getString(2), rs.getString(3), rs.getString(4)) : null;
            }
        }
    }

    /** Store access as on the store selection page: Global users all stores, others their assigned stores. */
    public static boolean hasStore(User u, String storeCode) throws SQLException {
        if (u.global()) return true;
        try (Connection c = InventoryDB.getAuthConnection();
             PreparedStatement ps = c.prepareStatement("SELECT 1 FROM user_database_access WHERE user_id = ? AND database_code = ?")) {
            ps.setInt(1, u.id);
            ps.setString(2, storeCode);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public static void reply(HttpServletResponse resp, int status, boolean ok, String message) throws IOException {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("ok", ok);
        out.put("message", message);
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        resp.getWriter().write(new Gson().toJson(out));
    }
}
