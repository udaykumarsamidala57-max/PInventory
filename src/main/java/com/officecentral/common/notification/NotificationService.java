package com.officecentral.common.notification;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.officecentral.common.config.AppConfig;
import com.officecentral.common.db.InventoryDB;
import com.officecentral.common.db.ServiceDB;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.Predicate;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Persistent in-app notifications with Firebase Cloud Messaging delivery. */
public final class NotificationService {
    private static final Logger LOG = Logger.getLogger(NotificationService.class.getName());
    private static final ExecutorService SENDER = Executors.newSingleThreadExecutor(r -> {
        Thread t = new Thread(r, "pinventory-push");
        t.setDaemon(true);
        return t;
    });
    private static final String ADMIN_DEPTS = "Electrical|Housekeeping|Plumbing|Dining Hall|RO Plant|Store|Dhobi";
    private static volatile FirebaseApp firebaseApp;

    private NotificationService() { }

    public static void registerDevice(int userId, String token) throws SQLException {
        String value = clean(token, 2048);
        if (userId <= 0 || value.isEmpty()) throw new IllegalArgumentException("Invalid push registration.");
        try (Connection con = InventoryDB.getAuthConnection();
             PreparedStatement ps = con.prepareStatement(
                     "INSERT INTO mobile_push_devices(fcm_token,user_id,active,updated_at) VALUES(?,?,1,NOW()) "
                     + "ON DUPLICATE KEY UPDATE user_id=VALUES(user_id),active=1,updated_at=NOW()")) {
            ps.setString(1, value);
            ps.setInt(2, userId);
            ps.executeUpdate();
        }
    }

    public static void unregisterDevice(int userId, String token) throws SQLException {
        if (userId <= 0) return;
        try (Connection con = InventoryDB.getAuthConnection();
             PreparedStatement ps = con.prepareStatement("DELETE FROM mobile_push_devices WHERE fcm_token=? AND user_id=?")) {
            ps.setString(1, clean(token, 2048));
            ps.setInt(2, userId);
            ps.executeUpdate();
        }
    }

    public static List<Map<String, Object>> list(int userId, int limit) throws SQLException {
        List<Map<String, Object>> rows = new ArrayList<>();
        int safeLimit = Math.max(1, Math.min(limit, 100));
        try (Connection con = InventoryDB.getAuthConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT id,event_type,title,message,entity_type,entity_id,store_code,created_at,read_at "
                     + "FROM mobile_notifications WHERE user_id=? ORDER BY id DESC LIMIT ?")) {
            ps.setInt(1, userId);
            ps.setInt(2, safeLimit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> n = new LinkedHashMap<>();
                    n.put("id", rs.getLong("id"));
                    n.put("eventType", rs.getString("event_type"));
                    n.put("title", rs.getString("title"));
                    n.put("message", rs.getString("message"));
                    n.put("entityType", rs.getString("entity_type"));
                    n.put("entityId", rs.getString("entity_id"));
                    n.put("store", rs.getString("store_code"));
                    n.put("createdAt", rs.getTimestamp("created_at").toString());
                    n.put("read", rs.getTimestamp("read_at") != null);
                    rows.add(n);
                }
            }
        }
        return rows;
    }

    public static void markRead(int userId, long notificationId) throws SQLException {
        try (Connection con = InventoryDB.getAuthConnection();
             PreparedStatement ps = con.prepareStatement(
                     "UPDATE mobile_notifications SET read_at=COALESCE(read_at,NOW()) WHERE id=? AND user_id=?")) {
            ps.setLong(1, notificationId);
            ps.setInt(2, userId);
            ps.executeUpdate();
        }
    }

    public static void indentSubmitted(String branch, int requesterId, String indentNo, String department, String type) {
        Event e = new Event("INDENT_SUBMITTED", "Indent needs approval",
                indentMessage(branch, indentNo, "Indent " + indentNo + " is waiting for department approval."),
                "indent", indentNo, branch);
        Set<Integer> targets = storeUsers(branch, u -> {
            if ("Incharge".equalsIgnoreCase(u.role) && eq(u.department, department)) return true;
            if (isGlobal(u.role) && !eq(department, "Dining Hall")) return true;
            return "Admin".equalsIgnoreCase(u.role) && isAdminDepartment(department);
        });
        targets.remove(requesterId);
        publish(targets, e);
    }

    public static void indentDecision(String branch, String requester, String department, String indentNo,
                                      String type, boolean levelOne, boolean approved) {
        String stage = levelOne ? "department" : "final";
        String result = approved ? "approved" : "rejected";
        String title = levelOne ? "Indent " + result : "Final indent " + result;
        Event e = new Event(levelOne ? "INDENT_LEVEL1_" + (approved ? "APPROVED" : "REJECTED")
                : "INDENT_LEVEL2_" + (approved ? "APPROVED" : "REJECTED"), title,
                indentMessage(branch, indentNo, "Indent " + indentNo + " was " + result
                        + " at the " + stage + " approval stage."),
                "indent", indentNo, branch);
        Set<Integer> requesterIds = userIds(java.util.Arrays.asList(requester));
        publish(requesterIds, e);
        if (levelOne && approved) {
            Set<Integer> next = storeUsers(branch, u -> isGlobal(u.role)
                    && !eq(department, "Dining Hall"));
            publish(next, new Event("INDENT_AWAITING_FINAL", "Indent needs final approval",
                    indentMessage(branch, indentNo, "Indent " + indentNo
                            + " has department approval and is ready for final review."),
                    "indent", indentNo, branch));
        }
        if (!levelOne && approved && "Issue".equalsIgnoreCase(type)) {
            Set<Integer> store = storeUsers(branch, u -> "Store".equalsIgnoreCase(u.department)
                    || "Store".equalsIgnoreCase(u.role));
            publish(store, new Event("ISSUE_READY", "Approved issue is ready",
                    indentMessage(branch, indentNo, "Issue indent " + indentNo
                            + " is approved and ready for the store to issue."),
                    "indent", indentNo, branch));
        }
    }

    /** Used by legacy web approval screens after their database update has committed. */
    public static void indentDecisionForId(String branch, int indentId, boolean levelOne, boolean approved) {
        try (Connection con = InventoryDB.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(
                     "SELECT indent_no,requested_by,department,PurchaseorIssue FROM indent WHERE indent_id=?")) {
            ps.setInt(1, indentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) indentDecision(branch, rs.getString("requested_by"), rs.getString("department"),
                        rs.getString("indent_no"), rs.getString("PurchaseorIssue"), levelOne, approved);
            }
        } catch (SQLException ex) {
            LOG.log(Level.WARNING, "Could not create indent approval notification", ex);
        }
    }

    public static void purchaseOrderCreated(String branch, String poNumber) {
        publish(storeUsers(branch, u -> isGlobal(u.role)),
                new Event("PO_CREATED", "Purchase order created", "Purchase order " + poNumber + " was created.",
                        "purchase_order", poNumber, branch));
    }

    public static void purchaseOrderApproved(String branch, String poNumber) {
        publish(storeUsers(branch, u -> "Finance".equalsIgnoreCase(u.department)),
                new Event("PO_APPROVED", "Purchase order approved", "Purchase order " + poNumber + " was approved.",
                        "purchase_order", poNumber, branch));
    }

    public static void complaintCreated(String branch, String requestNo, String requester) {
        publish(adminUsers(branch), new Event("SERVICE_CREATED", "New complaint", "Service request " + requestNo
                + " was raised and needs attention.", "service_request", requestNo, branch));
    }

    public static void serviceUpdated(String branch, String requestNo, String requester, String assignee,
                                      String actor, String status) {
        Event e = new Event("SERVICE_UPDATED", "Service request updated", "Request " + requestNo
                + " was updated. Current status: " + clean(status, 60) + ".", "service_request", requestNo, branch);
        Set<Integer> people = userIds(java.util.Arrays.asList(requester, assignee));
        people.removeAll(userIds(java.util.Arrays.asList(actor)));
        people.addAll(adminUsers(branch));
        publish(people, e);
    }

    /** Reads the committed service-request state and notifies the requester, assigned staff and admins. */
    public static void serviceChanged(String branch, int requestId, String actor) {
        try (Connection con = ServiceDB.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(
                     "SELECT sr.request_no,sr.requested_by,di.incharge_name,sr.status FROM service_requests sr "
                     + "LEFT JOIN department_incharge di ON sr.assigned_to=di.id WHERE sr.id=?")) {
            ps.setInt(1, requestId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) serviceUpdated(branch, rs.getString("request_no"), rs.getString("requested_by"),
                        rs.getString("incharge_name"), actor, rs.getString("status"));
            }
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Could not create service-request notification", e);
        }
    }

    public static void stockIssued(String branch, String indentNo, String requester) {
        publish(userIds(java.util.Arrays.asList(requester)), new Event("STOCK_ISSUED", "Stock issued",
                indentMessage(branch, indentNo, "Items for indent " + indentNo
                        + " have been issued by the store."), "indent", indentNo, branch));
    }

    public static void issueReadyForId(String branch, int indentId) {
        try (Connection con = InventoryDB.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(
                     "SELECT indent_no FROM indent WHERE indent_id=?")) {
            ps.setInt(1, indentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) publish(storeUsers(branch, u -> "Store".equalsIgnoreCase(u.department)
                                || "Store".equalsIgnoreCase(u.role)),
                        new Event("ISSUE_READY", "Approved issue is ready",
                                indentMessage(branch, rs.getString("indent_no"), "Issue indent "
                                        + rs.getString("indent_no") + " is approved and ready for the store to issue."),
                                "indent", rs.getString("indent_no"), branch));
            }
        } catch (SQLException ex) {
            LOG.log(Level.WARNING, "Could not create store issue notification", ex);
        }
    }

    /** Adds a short item/quantity summary to every indent-related push and inbox entry. */
    private static String indentMessage(String branch, String indentNo, String message) {
        String items = indentItemSummary(branch, indentNo);
        return items.isEmpty() ? message : message + "\nItems: " + items;
    }

    private static String indentItemSummary(String branch, String indentNo) {
        List<String> items = new ArrayList<>();
        int count = 0;
        try (Connection con = InventoryDB.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(
                     "SELECT item_name,qty,uom FROM indent WHERE indent_no=? ORDER BY item_name")) {
            ps.setString(1, indentNo);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    count++;
                    if (items.size() >= 4) continue;
                    String name = clean(rs.getString("item_name"), 45);
                    String quantity = java.math.BigDecimal.valueOf(rs.getDouble("qty"))
                            .stripTrailingZeros().toPlainString();
                    String unit = clean(rs.getString("uom"), 16);
                    items.add(name + " x " + quantity + (unit.isEmpty() ? "" : " " + unit));
                }
            }
        } catch (SQLException ex) {
            LOG.log(Level.WARNING, "Could not load indent items for notification " + indentNo, ex);
            return "";
        }
        if (items.isEmpty()) return "";
        String summary = String.join(", ", items);
        if (count > items.size()) summary += " (plus " + (count - items.size()) + " more)";
        return summary;
    }

    private static Set<Integer> adminUsers(String branch) {
        return storeUsers(branch, u -> "Admin".equalsIgnoreCase(u.role) || "Admin12".equalsIgnoreCase(u.role)
                || "A_Veeresh12".equalsIgnoreCase(u.username));
    }

    private static void publish(Collection<Integer> userIds, Event e) {
        if (userIds == null || userIds.isEmpty()) return;
        String eventId = UUID.randomUUID().toString();
        Map<Integer, List<String>> devices = new LinkedHashMap<>();
        try (Connection con = InventoryDB.getAuthConnection()) {
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT IGNORE INTO mobile_notifications(event_id,user_id,event_type,title,message,entity_type,entity_id,store_code,created_at) "
                    + "VALUES(?,?,?,?,?,?,?,?,NOW())")) {
                for (Integer uid : new LinkedHashSet<>(userIds)) {
                    if (uid == null || uid <= 0) continue;
                    ps.setString(1, eventId);
                    ps.setInt(2, uid);
                    ps.setString(3, e.type);
                    ps.setString(4, e.title);
                    ps.setString(5, e.body);
                    ps.setString(6, e.entityType);
                    ps.setString(7, e.entityId);
                    ps.setString(8, e.branch);
                    ps.addBatch();
                }
                ps.executeBatch();
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT fcm_token,user_id FROM mobile_push_devices WHERE active=1 AND user_id IN ("
                    + placeholders(userIds.size()) + ")")) {
                int i = 1;
                for (Integer uid : new LinkedHashSet<>(userIds)) ps.setInt(i++, uid);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) devices.computeIfAbsent(rs.getInt("user_id"), k -> new ArrayList<>())
                            .add(rs.getString("fcm_token"));
                }
            }
        } catch (SQLException ex) {
            LOG.log(Level.WARNING, "Could not save mobile notification " + e.type, ex);
            return;
        }
        if (devices.isEmpty()) return;
        SENDER.submit(() -> send(devices, e));
    }

    private static void send(Map<Integer, List<String>> devices, Event e) {
        try {
            FirebaseMessaging messaging = FirebaseMessaging.getInstance(firebaseApp());
            Map<String, String> data = new LinkedHashMap<>();
            data.put("eventType", e.type);
            data.put("entityType", e.entityType);
            data.put("entityId", e.entityId);
            data.put("store", e.branch);
            for (List<String> tokens : devices.values()) {
                for (String token : tokens) {
                    Message message = Message.builder().setToken(token)
                            .setNotification(Notification.builder().setTitle(e.title).setBody(e.body).build())
                            .setAndroidConfig(AndroidConfig.builder().setPriority(AndroidConfig.Priority.NORMAL).build())
                            .putAllData(data).build();
                    messaging.sendAsync(message).get();
                }
            }
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "FCM delivery failed for " + e.type + ". In-app notifications remain saved.", ex);
        }
    }

    private static FirebaseApp firebaseApp() throws Exception {
        FirebaseApp app = firebaseApp;
        if (app != null) return app;
        synchronized (NotificationService.class) {
            app = firebaseApp;
            if (app != null) return app;
            if (!FirebaseApp.getApps().isEmpty()) return firebaseApp = FirebaseApp.getInstance();
            String json = AppConfig.get("FIREBASE_SERVICE_ACCOUNT_JSON");
            GoogleCredentials credentials;
            if (json != null) {
                credentials = GoogleCredentials.fromStream(new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)));
            } else {
                String file = AppConfig.get("FIREBASE_SERVICE_ACCOUNT_FILE");
                if (file != null) {
                    try (FileInputStream in = new FileInputStream(file)) {
                        credentials = GoogleCredentials.fromStream(in);
                    }
                } else {
                    credentials = GoogleCredentials.getApplicationDefault();
                }
            }
            String projectId = AppConfig.get("FIREBASE_PROJECT_ID");
            if (projectId == null) projectId = "office-central-erp";
            app = FirebaseApp.initializeApp(FirebaseOptions.builder().setCredentials(credentials)
                    .setProjectId(projectId).build());
            firebaseApp = app;
            return app;
        }
    }

    private static Set<Integer> userIds(Collection<String> usernames) {
        Set<Integer> out = new LinkedHashSet<>();
        if (usernames == null || usernames.isEmpty()) return out;
        List<String> cleaned = usernames.stream().map(s -> clean(s, 100)).filter(s -> !s.isEmpty()).distinct().toList();
        if (cleaned.isEmpty()) return out;
        try (Connection con = InventoryDB.getAuthConnection();
             PreparedStatement ps = con.prepareStatement("SELECT id FROM users WHERE UPPER(username) IN ("
                     + placeholders(cleaned.size()) + ")")) {
            for (int i = 0; i < cleaned.size(); i++) ps.setString(i + 1, cleaned.get(i).toUpperCase(Locale.ROOT));
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) out.add(rs.getInt(1)); }
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Could not resolve notification recipients", e);
        }
        return out;
    }

    private static Set<Integer> storeUsers(String branch, Predicate<User> filter) {
        Set<Integer> ids = new LinkedHashSet<>();
        String store;
        try { store = InventoryDB.canonicalBranch(branch); }
        catch (SQLException e) { return ids; }
        Map<Integer, User> users = new LinkedHashMap<>();
        Map<Integer, String> ownBranch = new LinkedHashMap<>();
        Map<Integer, Set<String>> assigned = new LinkedHashMap<>();
        try (Connection con = InventoryDB.getAuthConnection();
             PreparedStatement ps = con.prepareStatement("SELECT id,username,role,department,branch FROM users");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                User u = new User(rs.getInt("id"), rs.getString("username"), rs.getString("role"), rs.getString("department"));
                if (filter.test(u)) { users.put(u.id, u); ownBranch.put(u.id, rs.getString("branch")); }
            }
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Could not resolve store notification recipients", e);
            return ids;
        }
        if (users.isEmpty()) return ids;
        try (Connection con = InventoryDB.getAuthConnection();
             PreparedStatement ps = con.prepareStatement("SELECT user_id,database_code FROM user_database_access");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int id = rs.getInt("user_id");
                if (!users.containsKey(id)) continue;
                try { assigned.computeIfAbsent(id, k -> new LinkedHashSet<>()).add(InventoryDB.canonicalBranch(rs.getString("database_code"))); }
                catch (SQLException ignored) { }
            }
        } catch (SQLException noAssignments) {
            // Older deployments use users.branch as the only store assignment.
        }
        for (User u : users.values()) {
            Set<String> stores = assigned.get(u.id);
            if (stores != null && !stores.isEmpty()) {
                if (stores.contains(store)) ids.add(u.id);
            } else {
                try { if (store.equals(InventoryDB.canonicalBranch(ownBranch.get(u.id)))) ids.add(u.id); }
                catch (SQLException ignored) { }
            }
        }
        return ids;
    }

    private static String placeholders(int size) {
        return String.join(",", java.util.Collections.nCopies(Math.max(1, size), "?"));
    }
    private static boolean eq(String a, String b) { return a != null && b != null && a.trim().equalsIgnoreCase(b.trim()); }
    private static boolean isGlobal(String role) {
        return "Global".equalsIgnoreCase(role) || "Global12".equalsIgnoreCase(role);
    }
    private static boolean isAdminDepartment(String d) {
        for (String allowed : ADMIN_DEPTS.split("\\|")) if (eq(allowed, d)) return true;
        return false;
    }
    private static String clean(String s, int max) {
        String value = s == null ? "" : s.trim();
        return value.length() > max ? value.substring(0, max) : value;
    }

    private static final class User {
        final int id; final String username, role, department;
        User(int id, String username, String role, String department) {
            this.id=id; this.username=username; this.role=role; this.department=department;
        }
    }
    private static final class Event {
        final String type, title, body, entityType, entityId, branch;
        Event(String type, String title, String body, String entityType, String entityId, String branch) {
            this.type=type; this.title=title; this.body=body; this.entityType=entityType;
            this.entityId=entityId; this.branch=branch;
        }
    }
}
