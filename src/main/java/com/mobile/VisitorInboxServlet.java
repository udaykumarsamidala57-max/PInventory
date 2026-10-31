package com.mobile;

import java.io.IOException;
import java.io.Reader;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.officecentral.common.web.Csrf;

/**
 * "Visitors for you" on the PInventory web dashboard. Uses the same signed School Operations calls as the
 * Android app, always as the signed-in web user, so School Operations decides what that user may see and do
 * (their own visitors; the Secretary's too for the Secretary's delegate).
 *
 *   GET  /visitor-inbox/mine                 visitors waiting for / with this user
 *   GET  /visitor-inbox/photo?visitorId=1    small photo (base64 JSON)
 *   POST /visitor-inbox/decision             {visitorId, decision: APPROVE|WAIT|REJECT, reason}
 *   POST /visitor-inbox/complete             {visitorId}
 */
@WebServlet("/visitor-inbox/*")
public class VisitorInboxServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(VisitorInboxServlet.class.getName());
    private static final Gson GSON = new Gson();
    private static final int MAX_BODY = 4096;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        handle(req, resp, false);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        handle(req, resp, true);
    }

    private void handle(HttpServletRequest req, HttpServletResponse resp, boolean post) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        resp.setHeader("X-Content-Type-Options", "nosniff");
        try {
            HttpSession s = req.getSession(false);
            Object uid = s == null ? null : s.getAttribute("userId");
            if (!(uid instanceof Integer) || s.getAttribute("username") == null) {
                throw new ApiException(401, "Session expired. Please log in again.");
            }
            int userId = (Integer) uid;
            if (post && !Csrf.valid(req, s)) throw new ApiException(403, "This page has expired. Please reload it.");
            String path = req.getPathInfo() == null ? "" : req.getPathInfo();
            String body;
            if (!post && "/mine".equals(path)) {
                body = SchoolOperationsMobileClient.visitors("mine", userId, null);
            } else if (!post && "/photo".equals(path)) {
                body = SchoolOperationsMobileClient.visitors("photo", userId, Map.of("visitorId", positive(req.getParameter("visitorId"))));
            } else if (post && "/decision".equals(path)) {
                JsonObject in = readJson(req);
                long visitorId = positive(text(in, "visitorId"));
                String decision = text(in, "decision").toUpperCase(Locale.ROOT);
                if (!decision.equals("APPROVE") && !decision.equals("WAIT") && !decision.equals("REJECT")) {
                    throw new ApiException(400, "Unknown visitor decision.");
                }
                String reason = text(in, "reason");
                if (reason.length() > 500) throw new ApiException(400, "Reason must be 500 characters or fewer.");
                body = GSON.toJson(SchoolOperationsMobileClient.decide(userId, visitorId, decision, reason));
            } else if (post && "/complete".equals(path)) {
                Map<String, Object> fields = new LinkedHashMap<>();
                fields.put("visitorId", positive(text(readJson(req), "visitorId")));
                body = SchoolOperationsMobileClient.visitors("complete", userId, fields);
            } else {
                throw new ApiException(404, "Unknown request.");
            }
            resp.getWriter().write(body);
        } catch (ApiException e) {
            resp.setStatus(e.getStatus());
            resp.getWriter().write(GSON.toJson(Map.of("message", e.getMessage())));
        } catch (RuntimeException e) {
            LOG.log(Level.WARNING, "Visitor inbox request failed", e);
            resp.setStatus(500);
            resp.getWriter().write(GSON.toJson(Map.of("message", "Could not complete the visitor request. Try again.")));
        }
    }

    private static JsonObject readJson(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        char[] buf = new char[1024];
        try (Reader r = req.getReader()) {
            int n;
            while ((n = r.read(buf)) != -1) {
                sb.append(buf, 0, n);
                if (sb.length() > MAX_BODY) throw new ApiException(400, "Request is too large.");
            }
        }
        try {
            return JsonParser.parseString(sb.toString()).getAsJsonObject();
        } catch (RuntimeException e) {
            throw new ApiException(400, "Invalid request data.");
        }
    }

    private static String text(JsonObject o, String key) {
        return o.has(key) && !o.get(key).isJsonNull() ? o.get(key).getAsString().trim() : "";
    }

    private static long positive(String value) {
        try {
            long v = Long.parseLong(value == null ? "" : value.trim());
            if (v > 0) return v;
        } catch (NumberFormatException ignored) { }
        throw new ApiException(400, "Invalid visitorId.");
    }
}
