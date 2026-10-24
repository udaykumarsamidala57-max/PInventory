package com.mobile;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.officecentral.common.dao.StoreAccessDAO;
import com.officecentral.common.db.InventoryDB;

/**
 * JSON API for the PInventory Android app: /api/mobile/*
 *
 * Uses the same users table, session attributes (username, userId, role, department,
 * assignedBranch, branch) and store rules as the website, so web and app see the same data.
 *
 * Security:
 *  - Same password check as LoginServlet; session id is renewed at login (no session fixation).
 *  - Failed logins are throttled per username + IP.
 *  - Every POST after login needs the X-CSRF-Token header issued at login.
 *  - A store must be chosen (and allowed for the user) before any data is read or written.
 *  - Errors never expose SQL or stack traces; details go to the server log.
 */
@WebServlet("/api/mobile/*")
public class MobileApiServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(MobileApiServlet.class.getName());

    static final String S_CSRF = "mobileCsrf";
    static final String S_STORE = "mobileStore";

    private static final int SESSION_SECONDS = 30 * 60;
    private static final int MAX_BODY_CHARS = 64 * 1024;

    private static final Gson GSON = new GsonBuilder().serializeNulls().create();
    private static final SecureRandom RANDOM = new SecureRandom();

    private final transient StoreAccessDAO storeAccess = new StoreAccessDAO();
    private final transient MobileIndentDAO indents = new MobileIndentDAO();
    private final transient MobileStockDAO stock = new MobileStockDAO();
    private final transient MobileServiceDAO service = new MobileServiceDAO();

    // ------------------------------------------------------------------ routing

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        handle(req, resp, false);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        handle(req, resp, true);
    }

    private void handle(HttpServletRequest req, HttpServletResponse resp, boolean post) throws IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        resp.setHeader("Pragma", "no-cache");
        resp.setHeader("X-Content-Type-Options", "nosniff");

        String path = req.getPathInfo() == null ? "" : req.getPathInfo();
        Map<String, Object> out;
        try {
            out = post ? routePost(path, req) : routeGet(path, req);
            out.put("ok", Boolean.TRUE);
            write(resp, HttpServletResponse.SC_OK, out);
        } catch (ApiException e) {
            Map<String, Object> err = new LinkedHashMap<>();
            err.put("ok", Boolean.FALSE);
            err.put("message", e.getMessage());
            write(resp, e.getStatus(), err);
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Mobile API error on " + path, e);
            Map<String, Object> err = new LinkedHashMap<>();
            err.put("ok", Boolean.FALSE);
            err.put("message", "Server error. Please try again.");
            write(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, err);
        }
    }

    private Map<String, Object> routeGet(String path, HttpServletRequest req) throws Exception {
        HttpSession s = requireUser(req);
        String branch = requireStore(s);
        Ctx c = new Ctx(s, branch);
        switch (path) {
            case "/indent/list":
                return indents.list(c, req.getParameter("scope"));
            case "/indent/detail":
                return indents.detail(c, intParam(req, "id"));
            case "/indent/items":
                return indents.items(c, req.getParameter("q"));
            case "/indent/meta":
                return indents.meta(c);
            case "/indent/catalog":
                return indents.catalog(c, req.getParameter("department"), req.getParameter("category"),
                        req.getParameter("subcategory"), req.getParameter("q"));
            case "/stock/report":
                return stock.report(c, req.getParameter("q"), req.getParameter("category"),
                        "1".equals(req.getParameter("low")));
            case "/service/categories":
                return service.categories(c);
            case "/service/list":
                return service.list(c);
            default:
                throw new ApiException(404, "Unknown request.");
        }
    }

    private Map<String, Object> routePost(String path, HttpServletRequest req) throws Exception {
        if ("/login".equals(path)) {
            return login(req);
        }
        HttpSession s = requireUser(req);
        checkCsrf(req, s);
        if ("/logout".equals(path)) {
            s.invalidate();
            return new LinkedHashMap<>();
        }
        if ("/store".equals(path)) {
            return selectStore(req, s);
        }
        String branch = requireStore(s);
        Ctx c = new Ctx(s, branch);
        switch (path) {
            case "/indent/create":
                return indents.create(c, readJson(req));
            case "/indent/approve":
                return indents.approve(c, intParam(req, "id"), req.getParameter("action"), req.getParameter("remarks"));
            case "/service/create":
                return service.create(c, req);
            case "/service/followup":
                return service.followup(c, intParam(req, "request_id"), req.getParameter("status"),
                        req.getParameter("remarks"));
            default:
                throw new ApiException(404, "Unknown request.");
        }
    }

    // ------------------------------------------------------------------ login / store

    private Map<String, Object> login(HttpServletRequest req) throws SQLException {
        String username = trim(req.getParameter("username"));
        String password = req.getParameter("password");
        if (username.isEmpty() || password == null || password.isEmpty()) {
            throw new ApiException(400, "Enter username and password.");
        }
        if (username.length() > 100 || password.length() > 200) {
            throw new ApiException(400, "Invalid username or password.");
        }

        String throttleKey = username.toLowerCase() + "|" + req.getRemoteAddr();
        LoginThrottle.check(throttleKey);

        int userId;
        String role, department, branch;
        // Same check as the website's LoginServlet.
        try (Connection con = InventoryDB.getAuthConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT id, role, department, branch FROM users WHERE username=? AND password=?")) {
            ps.setString(1, username);
            ps.setString(2, password);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    LoginThrottle.fail(throttleKey);
                    throw new ApiException(400, "Invalid username or password.");
                }
                userId = rs.getInt("id");
                role = rs.getString("role");
                department = rs.getString("department");
                branch = rs.getString("branch");
            }
        }
        LoginThrottle.reset(throttleKey);

        // New session id on login.
        HttpSession old = req.getSession(false);
        if (old != null) old.invalidate();
        HttpSession s = req.getSession(true);
        s.setMaxInactiveInterval(SESSION_SECONDS);
        s.setAttribute("username", username);
        s.setAttribute("userId", userId);
        s.setAttribute("role", role);
        s.setAttribute("department", department);
        s.setAttribute("assignedBranch", branch);
        s.setAttribute("branch", branch);
        String token = newToken();
        s.setAttribute(S_CSRF, token);

        List<String> codes = storeAccess.findAllowedStores(userId, branch);

        Map<String, Object> user = new LinkedHashMap<>();
        user.put("username", username);
        user.put("role", role);
        user.put("department", department);

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("user", user);
        out.put("stores", storeList(codes));
        out.put("csrfToken", token);
        return out;
    }

    private Map<String, Object> selectStore(HttpServletRequest req, HttpSession s) throws SQLException {
        String requested = trim(req.getParameter("store"));
        if (requested.isEmpty()) throw new ApiException(400, "Select a store.");

        String canonical;
        try {
            canonical = InventoryDB.canonicalBranch(requested);
        } catch (SQLException e) {
            throw new ApiException(403, "You do not have access to that store.");
        }
        int userId = (Integer) s.getAttribute("userId");
        List<String> allowed = storeAccess.findAllowedStores(userId, (String) s.getAttribute("assignedBranch"));
        if (!allowed.contains(canonical)) {
            throw new ApiException(403, "You do not have access to that store.");
        }
        try (Connection ignored = InventoryDB.getConnection(canonical)) {
            // connection test only, same as SelectStoreServlet
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Store connection failed: " + canonical, e);
            throw new ApiException(503, "Could not connect to that store. Please try again.");
        }
        s.setAttribute("branch", canonical);
        s.setAttribute(S_STORE, canonical);

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("store", storeList(List.of(canonical)).get(0));
        return out;
    }

    private static List<Map<String, Object>> storeList(List<String> codes) {
        List<Map<String, Object>> list = new ArrayList<>();
        for (String code : codes) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("code", code);
            m.put("name", code);
            list.add(m);
        }
        return list;
    }

    // ------------------------------------------------------------------ helpers

    /** Logged-in user's details, read from the session. */
    static final class Ctx {
        final String username;
        final String role;
        final String department;
        final String branch;
        final HttpSession session;

        Ctx(HttpSession s, String branch) {
            this.session = s;
            this.username = String.valueOf(s.getAttribute("username")).trim();
            this.role = s.getAttribute("role") == null ? "" : String.valueOf(s.getAttribute("role")).trim();
            this.department = s.getAttribute("department") == null ? "" : String.valueOf(s.getAttribute("department")).trim();
            this.branch = branch;
        }
    }

    private static HttpSession requireUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null || s.getAttribute("userId") == null
                || s.getAttribute(S_CSRF) == null) {
            throw new ApiException(401, "Session expired. Please log in again.");
        }
        return s;
    }

    private static String requireStore(HttpSession s) {
        Object store = s.getAttribute(S_STORE);
        if (store == null) throw new ApiException(409, "Select a store first.");
        return (String) store;
    }

    private static void checkCsrf(HttpServletRequest req, HttpSession s) {
        String expected = (String) s.getAttribute(S_CSRF);
        String given = req.getHeader("X-CSRF-Token");
        if (expected == null || given == null
                || !MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), given.getBytes(StandardCharsets.UTF_8))) {
            throw new ApiException(403, "Request rejected. Please log in again.");
        }
    }

    private static String newToken() {
        byte[] b = new byte[32];
        RANDOM.nextBytes(b);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }

    private static int intParam(HttpServletRequest req, String name) {
        try {
            int v = Integer.parseInt(trim(req.getParameter(name)));
            if (v <= 0) throw new NumberFormatException();
            return v;
        } catch (NumberFormatException e) {
            throw new ApiException(400, "Invalid " + name + ".");
        }
    }

    private static JsonObject readJson(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        char[] buf = new char[4096];
        try (BufferedReader r = req.getReader()) {
            int n;
            while ((n = r.read(buf)) != -1) {
                sb.append(buf, 0, n);
                if (sb.length() > MAX_BODY_CHARS) throw new ApiException(400, "Request too large.");
            }
        }
        try {
            return JsonParser.parseString(sb.toString()).getAsJsonObject();
        } catch (RuntimeException e) {
            throw new ApiException(400, "Invalid request data.");
        }
    }

    static String trim(String s) {
        return s == null ? "" : s.trim();
    }

    private static void write(HttpServletResponse resp, int status, Map<String, Object> body) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json;charset=UTF-8");
        try (PrintWriter w = resp.getWriter()) {
            w.print(GSON.toJson(body));
        }
    }

    /** Blocks a username+IP for 5 minutes after 5 wrong passwords. */
    private static final class LoginThrottle {
        private static final int MAX_FAILS = 5;
        private static final long LOCK_MS = 5 * 60 * 1000L;
        private static final Map<String, long[]> FAILS = new ConcurrentHashMap<>(); // {count, lockedUntil}

        static void check(String key) {
            long[] f = FAILS.get(key);
            if (f != null && f[1] > System.currentTimeMillis()) {
                long mins = Math.max(1, (f[1] - System.currentTimeMillis() + 59_999) / 60_000);
                throw new ApiException(429, "Too many failed attempts. Try again in " + mins + " minute(s).");
            }
        }

        static void fail(String key) {
            if (FAILS.size() > 10_000) FAILS.clear(); // memory guard
            FAILS.compute(key, (k, f) -> {
                long now = System.currentTimeMillis();
                if (f == null || (f[1] != 0 && f[1] <= now)) f = new long[] {0, 0};
                f[0]++;
                if (f[0] >= MAX_FAILS) f[1] = now + LOCK_MS;
                return f;
            });
        }

        static void reset(String key) {
            FAILS.remove(key);
        }
    }
}
