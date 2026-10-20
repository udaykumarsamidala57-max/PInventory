package com.website.servlet;

import com.website.bean.WebsiteDB;
import com.website.bean.PhotoStore;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * ONE-TIME MOVE: photos stored inside MySQL -> Railway bucket.
 *
 * Open  /admin/move-photos  while logged in to the admin (role Global or Admin).
 *  - Shows how many photos each table has and how many are already moved.
 *  - "Move photos" copies them in small batches; the page continues by itself.
 *  - Nothing is deleted. Each photo is checked in the bucket (size must match)
 *    before its place is written to the new column file_key.
 *  - Safe to stop and run again: photos that already have a file_key are skipped.
 * Global users can switch branch with ?branch=SRS or ?branch=Sanpoly.
 */
@WebServlet("/website/move-photos")
public class PhotoMoveServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** table, id column, photo column, type column (or null), folder name */
    private static final String[][] TABLES = {
            {"section_images", "id", "image_data", "image_type", "sections"},
            {"latest_news", "id", "image", null, "news"},
            {"upcoming_events", "id", "image_blob", null, "events"},
    };

    /** stop a batch after this many seconds so the page never times out */
    private static final long BATCH_MS = 20000;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession sess = req.getSession(false);
        String role = sess == null ? null : (String) sess.getAttribute("role");
        if (sess == null || sess.getAttribute("username") == null
                || !("Global".equalsIgnoreCase(role) || "Admin".equalsIgnoreCase(role))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Please log in as an admin first.");
            return;
        }

        String branch = WebsiteDB.site(sess);
        String asked = req.getParameter("branch");
        if (asked != null && "Global".equalsIgnoreCase(role)
                && ("SRS".equalsIgnoreCase(asked) || "Sanpoly".equalsIgnoreCase(asked))) {
            branch = asked;
        }
        if (branch == null) branch = "SRS";

        boolean run = "1".equals(req.getParameter("run"));

        resp.setContentType("text/html; charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        PrintWriter out = resp.getWriter();

        List<String> log = new ArrayList<>();
        int movedNow = 0;
        boolean timeUp = false;
        String fatal = null;

        @SuppressWarnings("unchecked")
        Set<String> failed = (Set<String>) sess.getAttribute("photoMoveFailed");
        if (failed == null || "1".equals(req.getParameter("retry"))) {
            failed = new HashSet<>();
            sess.setAttribute("photoMoveFailed", failed);
        }

        List<long[]> counts = new ArrayList<>();

        try (Connection conn = WebsiteDB.getConnection(branch)) {

            if (run) {
                if (!PhotoStore.enabled()) {
                    fatal = "The bucket settings are missing on this server (BUCKET, ACCESS_KEY_ID, SECRET_ACCESS_KEY, ENDPOINT, REGION).";
                } else {
                    long start = System.currentTimeMillis();
                    for (String[] t : TABLES) {
                        if (!tableExists(conn, t[0])) continue;
                        ensureKeyColumn(conn, t[0]);
                        for (long id : pendingIds(conn, t, failed, 200)) {
                            if (System.currentTimeMillis() - start > BATCH_MS) { timeUp = true; break; }
                            try {
                                String key = moveOne(conn, t, id, branch);
                                if (key != null) { movedNow++; log.add("Moved " + t[0] + " #" + id + " &rarr; " + esc(key)); }
                            } catch (Exception e) {
                                failed.add(t[0] + ":" + id);
                                log.add("<b class='bad'>Failed " + t[0] + " #" + id + ": " + esc(String.valueOf(e.getMessage())) + "</b>");
                            }
                        }
                        if (timeUp) break;
                    }
                }
            }

            for (String[] t : TABLES) counts.add(count(conn, t));

        } catch (SQLException e) {
            fatal = "Database error: " + e.getMessage();
        }

        long remaining = 0;
        for (long[] c : counts) remaining += c[2];
        int failedCount = failed.size();
        boolean continueRun = run && fatal == null && remaining > failedCount && (timeUp || movedNow > 0);

        // ---------------- page ----------------
        out.println("<!DOCTYPE html><html><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width,initial-scale=1'>");
        out.println("<title>Move photos to bucket</title>");
        if (continueRun) {
            out.println("<meta http-equiv='refresh' content='1;url=move-photos?run=1&branch=" + esc(branch) + "'>");
        }
        out.println("<style>body{font-family:Georgia,serif;background:#faf6f1;color:#2b1206;margin:0;padding:24px}"
                + "main{max-width:820px;margin:auto;background:#fff;border-top:5px solid #612405;padding:24px 28px;box-shadow:0 10px 30px -18px #0006}"
                + "h1{margin:0 0 6px;font-size:24px}p{line-height:1.6}table{width:100%;border-collapse:collapse;margin:16px 0}"
                + "th,td{text-align:left;padding:9px 10px;border-bottom:1px solid #eadfd3}th{background:#fbf3ea}"
                + ".btn{display:inline-block;background:#612405;color:#fff;padding:11px 18px;text-decoration:none;font-weight:bold;margin-right:8px}"
                + ".btn.alt{background:#e0701b}.ok{color:#2e7d32}.bad{color:#b71c1c}.log{font:13px/1.6 monospace;background:#fbf6f0;padding:12px;max-height:320px;overflow:auto}"
                + "</style></head><body><main>");
        out.println("<h1>Move photos to the bucket</h1>");
        out.println("<p>Branch: <b>" + esc(branch) + "</b>"
                + ("Global".equalsIgnoreCase(role) ? " &nbsp;(<a href='move-photos?branch=SRS'>SRS</a> | <a href='move-photos?branch=Sanpoly'>Sanpoly</a>)" : "")
                + "<br>Bucket settings: " + (PhotoStore.enabled() ? "<span class='ok'>found</span>" : "<span class='bad'>missing on this server</span>") + "</p>");

        if (fatal != null) out.println("<p class='bad'><b>" + esc(fatal) + "</b></p>");

        out.println("<table><tr><th>Photos in</th><th>Total</th><th>Moved</th><th>Still in MySQL</th></tr>");
        for (int i = 0; i < TABLES.length; i++) {
            long[] c = counts.size() > i ? counts.get(i) : new long[]{-1, -1, -1};
            out.println("<tr><td>" + TABLES[i][4] + " <small>(" + TABLES[i][0] + ")</small></td>"
                    + "<td>" + show(c[0]) + "</td><td class='ok'>" + show(c[1]) + "</td><td>" + show(c[2]) + "</td></tr>");
        }
        out.println("</table>");

        if (continueRun) {
            out.println("<p><b>Moving&hellip;</b> " + movedNow + " moved in this step. The page continues by itself &mdash; keep it open.</p>");
        } else if (run && fatal == null) {
            out.println("<p class='ok'><b>Finished this run.</b> " + (failedCount > 0
                    ? "<span class='bad'>" + failedCount + " photo(s) failed &mdash; see below, then use Try failed again.</span>" : "") + "</p>");
        }

        if (!continueRun) {
            out.println("<p><a class='btn' href='move-photos?run=1&branch=" + esc(branch) + "'>Move photos</a>"
                    + (failedCount > 0 ? "<a class='btn alt' href='move-photos?run=1&retry=1&branch=" + esc(branch) + "'>Try failed again</a>" : "")
                    + "</p>");
            out.println("<p><small>Nothing is deleted. Photos stay in MySQL until you decide to clear them later.</small></p>");
        }

        if (!log.isEmpty()) {
            out.println("<div class='log'>");
            for (String l : log) out.println(l + "<br>");
            out.println("</div>");
        }
        out.println("</main><p style='max-width:820px;margin:16px auto 0;text-align:center;font-size:12px;color:#5c5c5c'>Developed and Maintained by : <b>SSS IT - Office Central</b></p></body></html>");
    }

    // =========================================================

    private String moveOne(Connection conn, String[] t, long id, String branch) throws Exception {
        String table = t[0], idCol = t[1], blob = t[2], typeCol = t[3], folder = t[4];

        String sql = "SELECT " + blob + ", OCTET_LENGTH(" + blob + ") AS len"
                + (typeCol != null ? ", " + typeCol : "") + " FROM " + table + " WHERE " + idCol + " = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                long len = rs.getLong("len");
                if (rs.wasNull() || len <= 0) return null;

                String type = typeCol != null ? rs.getString(typeCol) : null;

                try (InputStream raw = rs.getBinaryStream(blob);
                     BufferedInputStream in = new BufferedInputStream(raw, 65536)) {

                    in.mark(32);
                    byte[] head = new byte[16];
                    int n = in.read(head);
                    in.reset();
                    byte[] h = n > 0 ? java.util.Arrays.copyOf(head, n) : new byte[0];

                    byte[] decoded = null;
                    if (type == null || type.trim().isEmpty() || !type.contains("/")) {
                        type = PhotoStore.sniff(h, null);
                        if (type == null) {
                            String start = new String(h, java.nio.charset.StandardCharsets.ISO_8859_1);
                            if (start.startsWith("data:")) {
                                // picture saved as text (data:image/...;base64,....)
                                String text = new String(in.readAllBytes(), java.nio.charset.StandardCharsets.ISO_8859_1).trim();
                                int comma = text.indexOf(',');
                                int semi = text.indexOf(';');
                                type = (semi > 5 && semi < comma) ? text.substring(5, semi) : "image/jpeg";
                                decoded = java.util.Base64.getMimeDecoder().decode(text.substring(comma + 1));
                            } else {
                                throw new IOException("not a picture file (perhaps a file path) - left in MySQL");
                            }
                        }
                    } else {
                        type = type.trim().toLowerCase();
                    }

                    String key = PhotoStore.newKey(branch, folder, id, type);
                    if (decoded != null) {
                        PhotoStore.put(key, decoded, type);
                        len = decoded.length;
                    } else {
                        PhotoStore.put(key, in, len, type);
                    }

                    long stored = PhotoStore.size(key);
                    if (stored != len) throw new IOException("size check failed (" + stored + " of " + len + " bytes)");

                    try (PreparedStatement up = conn.prepareStatement(
                            "UPDATE " + table + " SET file_key = ? WHERE " + idCol + " = ? AND (file_key IS NULL OR file_key = '')")) {
                        up.setString(1, key);
                        up.setLong(2, id);
                        up.executeUpdate();
                    }
                    return key;
                }
            }
        }
    }

    private List<Long> pendingIds(Connection conn, String[] t, Set<String> failed, int max) throws SQLException {
        List<Long> ids = new ArrayList<>();
        String sql = "SELECT " + t[1] + " FROM " + t[0] + " WHERE " + t[2] + " IS NOT NULL AND OCTET_LENGTH(" + t[2] + ") > 0"
                + " AND (file_key IS NULL OR file_key = '') ORDER BY " + t[1];
        try (Statement s = conn.createStatement(); ResultSet rs = s.executeQuery(sql)) {
            while (rs.next() && ids.size() < max) {
                long id = rs.getLong(1);
                if (!failed.contains(t[0] + ":" + id)) ids.add(id);
            }
        }
        return ids;
    }

    /** {total photos, moved, still only in MySQL} */
    private long[] count(Connection conn, String[] t) throws SQLException {
        if (!tableExists(conn, t[0])) return new long[]{0, 0, 0};
        boolean hasKey = columnExists(conn, t[0], "file_key");
        String photo = t[2] + " IS NOT NULL AND OCTET_LENGTH(" + t[2] + ") > 0";
        String moved = hasKey ? "(file_key IS NOT NULL AND file_key <> '')" : "0";
        String sql = "SELECT SUM(CASE WHEN " + photo + " OR " + moved + " THEN 1 ELSE 0 END),"
                + " SUM(CASE WHEN " + moved + " THEN 1 ELSE 0 END),"
                + " SUM(CASE WHEN " + photo + " AND NOT " + moved + " THEN 1 ELSE 0 END) FROM " + t[0];
        try (Statement s = conn.createStatement(); ResultSet rs = s.executeQuery(sql)) {
            rs.next();
            return new long[]{rs.getLong(1), rs.getLong(2), rs.getLong(3)};
        }
    }

    private void ensureKeyColumn(Connection conn, String table) throws SQLException {
        if (columnExists(conn, table, "file_key")) return;
        try (Statement s = conn.createStatement()) {
            s.executeUpdate("ALTER TABLE " + table + " ADD COLUMN file_key VARCHAR(300) NULL");
        }
    }

    private boolean tableExists(Connection conn, String table) throws SQLException {
        try (PreparedStatement p = conn.prepareStatement(
                "SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?")) {
            p.setString(1, table);
            try (ResultSet rs = p.executeQuery()) { return rs.next(); }
        }
    }

    private boolean columnExists(Connection conn, String table, String col) throws SQLException {
        try (PreparedStatement p = conn.prepareStatement(
                "SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?")) {
            p.setString(1, table);
            p.setString(2, col);
            try (ResultSet rs = p.executeQuery()) { return rs.next(); }
        }
    }

    private static String show(long v) { return v < 0 ? "&ndash;" : String.valueOf(v); }

    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("'", "&#39;").replace("\"", "&quot;");
    }
}
