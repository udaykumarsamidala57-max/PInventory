package com.website.bean;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.Map;
import java.util.TimeZone;
import java.util.TreeMap;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/**
 * Photo storage in the Railway bucket (S3-compatible), with no extra libraries.
 *
 * Settings are read from environment variables, the same names Railway gives a bucket:
 *   BUCKET, ACCESS_KEY_ID, SECRET_ACCESS_KEY, ENDPOINT (https://t3.storageapi.dev), REGION (auto)
 *   S3_PATH_STYLE=true  only for old buckets whose Credentials tab says "path style".
 * Keys are never written in the code, so nothing secret goes to GitHub.
 *
 * The bucket is private: photos are shown through short-lived signed links (url()).
 */
public final class PhotoStore {

    private static final String BUCKET   = env("BUCKET", null);
    private static final String KEY_ID   = env("ACCESS_KEY_ID", null);
    private static final String SECRET   = env("SECRET_ACCESS_KEY", null);
    private static final String REGION   = env("REGION", "auto");
    private static final String ENDPOINT = env("ENDPOINT", "https://t3.storageapi.dev");
    private static final boolean PATH_STYLE = "true".equalsIgnoreCase(env("S3_PATH_STYLE", "false"));

    private static final String SCHEME;
    private static final String ENDPOINT_HOST;

    static {
        String e = ENDPOINT.trim();
        if (e.endsWith("/")) e = e.substring(0, e.length() - 1);
        int i = e.indexOf("://");
        SCHEME = i > 0 ? e.substring(0, i) : "https";
        ENDPOINT_HOST = i > 0 ? e.substring(i + 3) : e;
    }

    /** signed links are valid for 1 hour and reused for 50 minutes */
    private static final int LINK_SECONDS = 3600;
    private static final long LINK_REUSE_MS = 50L * 60L * 1000L;
    private static final Map<String, String[]> LINKS = new ConcurrentHashMap<>();

    private PhotoStore() { }

    /** true when the bucket settings are present */
    public static boolean enabled() {
        return BUCKET != null && KEY_ID != null && SECRET != null;
    }

    // =========================================================
    // NAMES
    // =========================================================

    /** e.g. srs/sections/123-1a2b3c4d.jpg */
    public static String newKey(String branch, String kind, long id, String contentType) {
        String b = branch == null ? "site" : branch.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9_-]", "");
        String k = kind == null ? "files" : kind.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9_-]", "");
        return b + "/" + k + "/" + id + "-" + UUID.randomUUID().toString().substring(0, 8) + extension(contentType);
    }

    public static String extension(String contentType) {
        if (contentType == null) return "";
        switch (contentType.toLowerCase(Locale.ROOT).trim()) {
            case "image/jpeg": case "image/jpg": case "image/pjpeg": return ".jpg";
            case "image/png":  return ".png";
            case "image/gif":  return ".gif";
            case "image/webp": return ".webp";
            case "image/svg+xml": return ".svg";
            case "video/mp4":  return ".mp4";
            case "video/webm": return ".webm";
            case "video/quicktime": return ".mov";
            case "application/pdf": return ".pdf";
            default: return "";
        }
    }

    /** content type from the first bytes of a file (head = first 16+ bytes) */
    public static String sniff(byte[] d, String fallback) {
        if (d != null) {
            if (d.length > 2 && (d[0] & 0xFF) == 0xFF && (d[1] & 0xFF) == 0xD8) return "image/jpeg";
            if (d.length > 3 && (d[0] & 0xFF) == 0x89 && d[1] == 'P' && d[2] == 'N' && d[3] == 'G') return "image/png";
            if (d.length > 2 && d[0] == 'G' && d[1] == 'I' && d[2] == 'F') return "image/gif";
            if (d.length > 11 && d[0] == 'R' && d[1] == 'I' && d[2] == 'F' && d[3] == 'F'
                    && d[8] == 'W' && d[9] == 'E' && d[10] == 'B' && d[11] == 'P') return "image/webp";
            if (d.length > 7 && d[4] == 'f' && d[5] == 't' && d[6] == 'y' && d[7] == 'p') return "video/mp4";
            if (d.length > 3 && d[0] == '%' && d[1] == 'P' && d[2] == 'D' && d[3] == 'F') return "application/pdf";
        }
        return fallback;
    }

    // =========================================================
    // UPLOAD / CHECK
    // =========================================================

    /** uploads a file; length must be the exact number of bytes in the stream */
    public static void put(String key, InputStream in, long length, String contentType) throws IOException {
        requireEnabled();
        String amzDate = amzDate(new Date());
        String payload = "UNSIGNED-PAYLOAD";

        HttpURLConnection c = (HttpURLConnection) new URL(objectUrl(key, null)).openConnection();
        c.setRequestMethod("PUT");
        c.setDoOutput(true);
        c.setConnectTimeout(20000);
        c.setReadTimeout(120000);
        c.setFixedLengthStreamingMode(length);
        c.setRequestProperty("Content-Type", contentType == null ? "application/octet-stream" : contentType);
        c.setRequestProperty("x-amz-date", amzDate);
        c.setRequestProperty("x-amz-content-sha256", payload);
        c.setRequestProperty("Authorization", authorization("PUT", key, amzDate, payload));

        try (OutputStream out = c.getOutputStream()) {
            byte[] buf = new byte[65536];
            int n;
            long sent = 0;
            while ((n = in.read(buf)) != -1) {
                out.write(buf, 0, n);
                sent += n;
            }
            if (sent != length) throw new IOException("Stream had " + sent + " bytes, expected " + length);
        }
        int code = c.getResponseCode();
        if (code < 200 || code >= 300) throw new IOException("Upload failed (" + code + "): " + errorBody(c));
        c.disconnect();
    }

    public static void put(String key, byte[] data, String contentType) throws IOException {
        put(key, new java.io.ByteArrayInputStream(data), data.length, contentType);
    }

    /** size of a stored file in bytes, or -1 if it does not exist */
    public static long size(String key) throws IOException {
        requireEnabled();
        String amzDate = amzDate(new Date());
        String payload = "UNSIGNED-PAYLOAD";
        HttpURLConnection c = (HttpURLConnection) new URL(objectUrl(key, null)).openConnection();
        c.setRequestMethod("HEAD");
        c.setConnectTimeout(20000);
        c.setReadTimeout(30000);
        c.setRequestProperty("x-amz-date", amzDate);
        c.setRequestProperty("x-amz-content-sha256", payload);
        c.setRequestProperty("Authorization", authorization("HEAD", key, amzDate, payload));
        int code = c.getResponseCode();
        if (code == 404) return -1;
        if (code < 200 || code >= 300) throw new IOException("Check failed (" + code + ")");
        long len = c.getContentLengthLong();
        c.disconnect();
        return len;
    }

    /** removes a file (used when a photo is replaced or deleted) */
    public static void delete(String key) throws IOException {
        requireEnabled();
        String amzDate = amzDate(new Date());
        String payload = "UNSIGNED-PAYLOAD";
        HttpURLConnection c = (HttpURLConnection) new URL(objectUrl(key, null)).openConnection();
        c.setRequestMethod("DELETE");
        c.setConnectTimeout(20000);
        c.setReadTimeout(30000);
        c.setRequestProperty("x-amz-date", amzDate);
        c.setRequestProperty("x-amz-content-sha256", payload);
        c.setRequestProperty("Authorization", authorization("DELETE", key, amzDate, payload));
        int code = c.getResponseCode();
        if (code != 404 && (code < 200 || code >= 300)) throw new IOException("Delete failed (" + code + ")");
        c.disconnect();
    }

    // =========================================================
    // SIGNED LINK FOR SHOWING A PHOTO
    // =========================================================

    public static String url(String key) {
        requireEnabled();
        long now = System.currentTimeMillis();
        String[] cached = LINKS.get(key);
        if (cached != null && Long.parseLong(cached[1]) > now) return cached[0];

        String link = presign(key, new Date(now), LINK_SECONDS);
        LINKS.put(key, new String[]{link, String.valueOf(now + LINK_REUSE_MS)});
        if (LINKS.size() > 5000) LINKS.clear();
        return link;
    }

    static String presign(String key, Date d, int seconds) {
        String amzDate = amzDate(d);
        String day = amzDate.substring(0, 8);
        String scope = day + "/" + REGION + "/s3/aws4_request";

        Map<String, String> q = new TreeMap<>();
        q.put("X-Amz-Algorithm", "AWS4-HMAC-SHA256");
        q.put("X-Amz-Credential", KEY_ID + "/" + scope);
        q.put("X-Amz-Date", amzDate);
        q.put("X-Amz-Expires", String.valueOf(seconds));
        q.put("X-Amz-SignedHeaders", "host");
        String query = canonicalQuery(q);

        String canonical = "GET\n" + canonicalPath(key) + "\n" + query + "\n"
                + "host:" + host() + "\n\nhost\nUNSIGNED-PAYLOAD";
        String toSign = "AWS4-HMAC-SHA256\n" + amzDate + "\n" + scope + "\n" + hex(sha256(canonical));
        String signature = hex(hmac(signingKey(day), toSign));

        return objectUrl(key, query + "&X-Amz-Signature=" + signature);
    }

    // =========================================================
    // SIGNING (AWS Signature Version 4)
    // =========================================================

    private static String authorization(String method, String key, String amzDate, String payload) {
        String day = amzDate.substring(0, 8);
        String scope = day + "/" + REGION + "/s3/aws4_request";
        String signedHeaders = "host;x-amz-content-sha256;x-amz-date";
        String canonical = method + "\n" + canonicalPath(key) + "\n\n"
                + "host:" + host() + "\n"
                + "x-amz-content-sha256:" + payload + "\n"
                + "x-amz-date:" + amzDate + "\n\n"
                + signedHeaders + "\n" + payload;
        String toSign = "AWS4-HMAC-SHA256\n" + amzDate + "\n" + scope + "\n" + hex(sha256(canonical));
        String signature = hex(hmac(signingKey(day), toSign));
        return "AWS4-HMAC-SHA256 Credential=" + KEY_ID + "/" + scope
                + ", SignedHeaders=" + signedHeaders + ", Signature=" + signature;
    }

    private static byte[] signingKey(String day) {
        byte[] k = hmac(("AWS4" + SECRET).getBytes(StandardCharsets.UTF_8), day);
        k = hmac(k, REGION);
        k = hmac(k, "s3");
        return hmac(k, "aws4_request");
    }

    private static String host() {
        return PATH_STYLE ? ENDPOINT_HOST : BUCKET + "." + ENDPOINT_HOST;
    }

    private static String canonicalPath(String key) {
        String k = encode(key, false);
        return PATH_STYLE ? "/" + encode(BUCKET, true) + "/" + k : "/" + k;
    }

    private static String objectUrl(String key, String query) {
        return SCHEME + "://" + host() + canonicalPath(key) + (query == null ? "" : "?" + query);
    }

    private static String canonicalQuery(Map<String, String> sorted) {
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, String> e : sorted.entrySet()) {
            if (sb.length() > 0) sb.append('&');
            sb.append(encode(e.getKey(), true)).append('=').append(encode(e.getValue(), true));
        }
        return sb.toString();
    }

    /** RFC 3986 encoding; '/' kept as-is in object paths */
    private static String encode(String s, boolean encodeSlash) {
        StringBuilder sb = new StringBuilder();
        for (byte b : s.getBytes(StandardCharsets.UTF_8)) {
            char ch = (char) (b & 0xFF);
            if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9')
                    || ch == '-' || ch == '_' || ch == '.' || ch == '~' || (ch == '/' && !encodeSlash)) {
                sb.append(ch);
            } else {
                sb.append('%').append(String.format("%02X", b & 0xFF));
            }
        }
        return sb.toString();
    }

    private static String amzDate(Date d) {
        SimpleDateFormat f = new SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.ROOT);
        f.setTimeZone(TimeZone.getTimeZone("UTC"));
        return f.format(d);
    }

    private static byte[] hmac(byte[] key, String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(key, "HmacSHA256"));
            return mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private static byte[] sha256(String s) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(s.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private static String hex(byte[] b) {
        StringBuilder sb = new StringBuilder(b.length * 2);
        for (byte x : b) sb.append(String.format("%02x", x & 0xFF));
        return sb.toString();
    }

    private static String errorBody(HttpURLConnection c) {
        try (InputStream e = c.getErrorStream()) {
            if (e == null) return "";
            byte[] b = e.readAllBytes();
            String s = new String(b, StandardCharsets.UTF_8);
            return s.length() > 300 ? s.substring(0, 300) : s;
        } catch (IOException ex) {
            return "";
        }
    }

    private static void requireEnabled() {
        if (!enabled()) throw new IllegalStateException("Bucket settings (BUCKET, ACCESS_KEY_ID, SECRET_ACCESS_KEY) are missing.");
    }

    private static String env(String name, String def) {
        String v = com.bean.AppConfig.get(name);          // env var, -D, or the local settings file
        if (v == null || v.trim().isEmpty()) v = System.getProperty("photostore." + name);
        return (v == null || v.trim().isEmpty()) ? def : v.trim();
    }
}
