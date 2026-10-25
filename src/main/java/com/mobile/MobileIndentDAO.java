package com.mobile;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.servlet.http.HttpSession;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.officecentral.common.db.InventoryDB;
import com.officecentral.common.notification.NotificationService;

/**
 * Indent process for the mobile app. Follows the website's rules exactly:
 *  - IndentServlet: indent number from id_sequences, one indent row per item.
 *  - ApproveIndentServlet / AIndentList.jsp:
 *      Level 1 (Global, Incharge, Admin): istatus = Approved / Cancelled.
 *      Level 2 (Global only, after level 1): status = Approved and Indentnext = Issue or PO,
 *      with the same stock check for Issue.
 *    Departments each approver role may see are the same as on the website.
 * The mobile API additionally checks role and department on every approval (server side).
 */
final class MobileIndentDAO {

    private static final double MAX_QTY = 100000;
    private static final int MAX_LINES = 50;

    private static final String ADMIN_DEPTS =
            "('Electrical','Housekeeping','Plumbing','Dining Hall','RO Plant','Store','Dhobi')";
    private static final String[] ADMIN_DEPT_LIST =
            {"Electrical", "Housekeeping", "Plumbing", "Dining Hall", "RO Plant", "Store", "Dhobi"};

    /** Same "still pending" filter as ApproveIndentServlet. */
    private static final String PENDING_SQL =
            " (TRIM(i.Indentnext) NOT IN ('Issue','PO','Issued','Cancelled','PO Raised') OR i.Indentnext IS NULL)"
            + " AND (TRIM(i.status) NOT IN ('Cancelled') OR i.status IS NULL) ";

    private static final String LINE_SELECT =
            "SELECT i.*, COALESCE(s.balance_qty,0) AS balance_qty FROM indent i "
            + "LEFT JOIN stock s ON i.item_id = s.item_id ";

    // ------------------------------------------------------------------ roles

    static boolean isGlobal(String role) {
        return "Global".equalsIgnoreCase(role);
    }

    static boolean isApprover(String role) {
        return isGlobal(role) || "Incharge".equalsIgnoreCase(role) || "Admin".equalsIgnoreCase(role);
    }

    /** SQL department filter for an approver, same as the website's approval page. */
    private static String scopeSql(MobileApiServlet.Ctx c, List<Object> params) {
        if (isGlobal(c.role)) return " AND i.department <> 'Dining Hall' ";
        if ("Admin".equalsIgnoreCase(c.role)) return " AND i.department IN " + ADMIN_DEPTS + " ";
        params.add(c.department);
        return " AND i.department = ? ";
    }

    private static boolean inScope(MobileApiServlet.Ctx c, String dept) {
        String d = MobileApiServlet.trim(dept);
        if (isGlobal(c.role)) return !"Dining Hall".equalsIgnoreCase(d);
        if ("Admin".equalsIgnoreCase(c.role)) {
            for (String a : ADMIN_DEPT_LIST) if (a.equalsIgnoreCase(d)) return true;
            return false;
        }
        if ("Incharge".equalsIgnoreCase(c.role)) return d.equalsIgnoreCase(c.department);
        return false;
    }

    // ------------------------------------------------------------------ line model

    private static final class Line {
        int id;
        String indentNo, date, department, requestedBy, purpose, remarks;
        int itemId;
        String itemName, uom;
        double qty, balance;
        String istatus, l1By, l1Date, status, l2Date, next, type;

        static Line read(ResultSet rs) throws SQLException {
            Line l = new Line();
            l.id = rs.getInt("indent_id");
            l.indentNo = rs.getString("indent_no");
            l.date = rs.getString("indent_date");
            l.department = rs.getString("department");
            l.requestedBy = rs.getString("requested_by");
            l.purpose = rs.getString("purpose");
            l.remarks = rs.getString("remarks");
            l.itemId = rs.getInt("item_id");
            l.itemName = rs.getString("item_name");
            l.uom = rs.getString("uom");
            l.qty = rs.getDouble("qty");
            l.balance = rs.getDouble("balance_qty");
            l.istatus = t(rs.getString("istatus"));
            l.l1By = rs.getString("IstausApprove");
            l.l1Date = rs.getString("Iapprovedate");
            l.status = t(rs.getString("status"));
            l.l2Date = rs.getString("Fapprovedate");
            l.next = t(rs.getString("Indentnext"));
            l.type = t(rs.getString("PurchaseorIssue"));
            return l;
        }

        boolean stillPending() {
            return !in(next, "Issue", "PO", "Issued", "Cancelled", "PO Raised") && !"Cancelled".equalsIgnoreCase(status);
        }

        /** Website shows level-1 buttons when istatus is neither Approved nor Rejected. */
        boolean level1Open() {
            return !in(istatus, "Approved", "Rejected", "Cancelled");
        }

        /** Website shows level-2 buttons (Global) under these conditions. */
        boolean level2Open() {
            return "Approved".equalsIgnoreCase(istatus) && !in(status, "Approved", "Rejected", "Issue", "PO", "Cancelled");
        }

        String nextStep() {
            return "Issue".equalsIgnoreCase(type) ? "Issue" : "PO";
        }

        String displayStatus() {
            if (in(status, "Cancelled") || in(istatus, "Cancelled", "Rejected") || in(next, "Cancelled")) return "REJECTED";
            if (in(next, "Issued")) return "ISSUED";
            if (in(next, "PO Raised")) return "PO RAISED";
            if (in(status, "Approved")) return "APPROVED";
            if (in(istatus, "Approved")) return "INCHARGE APPROVED";
            return "PENDING";
        }
    }

    private static final class ApprovalEvent {
        final Line line;
        final boolean levelOne;
        ApprovalEvent(Line line, boolean levelOne) { this.line = line; this.levelOne = levelOne; }
    }

    private static boolean canAct(MobileApiServlet.Ctx c, Line l) {
        if (!isApprover(c.role) || !l.stillPending() || !inScope(c, l.department)) return false;
        return l.level1Open() || (isGlobal(c.role) && l.level2Open());
    }

    private static String t(String s) {
        return s == null ? "" : s.trim();
    }

    private static boolean in(String v, String... options) {
        for (String o : options) if (o.equalsIgnoreCase(v)) return true;
        return false;
    }

    // ------------------------------------------------------------------ list / detail

    Map<String, Object> list(MobileApiServlet.Ctx c, String scope) throws SQLException {
        boolean approval = "approval".equalsIgnoreCase(scope);
        List<Object> params = new ArrayList<>();
        String sql;
        if (approval) {
            if (!isApprover(c.role)) throw new ApiException(403, "You do not have permission to approve indents.");
            sql = LINE_SELECT + "WHERE " + PENDING_SQL + scopeSql(c, params) + "ORDER BY i.indent_id DESC LIMIT 3000";
        } else {
            sql = LINE_SELECT + "WHERE i.requested_by = ? ORDER BY i.indent_id DESC LIMIT 1500";
            params.add(c.username);
        }

        Map<String, List<Line>> groups = new LinkedHashMap<>();
        try (Connection con = InventoryDB.getConnection(c.branch);
             PreparedStatement ps = con.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) ps.setString(i + 1, (String) params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Line l = Line.read(rs);
                    groups.computeIfAbsent(groupKey(l), k -> new ArrayList<>()).add(l);
                }
            }
        }

        List<Map<String, Object>> out = new ArrayList<>();
        for (List<Line> lines : groups.values()) {
            Map<String, Object> m = summary(c, lines);
            if (approval && !Boolean.TRUE.equals(m.get("canApprove"))) continue;
            out.add(m);
            if (out.size() >= 200) break;
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("indents", out);
        return res;
    }

    Map<String, Object> detail(MobileApiServlet.Ctx c, int indentId) throws SQLException {
        List<Line> lines;
        try (Connection con = InventoryDB.getConnection(c.branch)) {
            lines = loadIndent(con, indentId, false);
        }
        boolean mine = false, approverCanSee = false;
        for (Line l : lines) {
            if (c.username.equalsIgnoreCase(t(l.requestedBy))) mine = true;
            if (isApprover(c.role) && inScope(c, l.department)) approverCanSee = true;
        }
        if (!mine && !approverCanSee) throw new ApiException(404, "Indent not found.");

        Map<String, Object> indent = summary(c, lines);
        List<Map<String, Object>> items = new ArrayList<>();
        for (Line l : lines) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("itemId", l.itemId);
            m.put("itemName", l.itemName);
            m.put("unit", l.uom);
            m.put("qty", l.qty);
            String st = l.displayStatus();
            boolean approved = in(st, "APPROVED", "ISSUED", "PO RAISED");
            m.put("approvedQty", approved ? l.qty : 0);
            m.put("availableQty", l.balance);
            m.put("status", st);
            m.put("nextStep", l.nextStep());
            m.put("purpose", l.purpose);
            items.add(m);
        }
        indent.put("items", items);

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("indent", indent);
        return res;
    }

    /** Lines that belong together on the website share indent_no. */
    private static String groupKey(Line l) {
        String no = t(l.indentNo);
        return no.isEmpty() ? "#" + l.id : no;
    }

    /** All rows of the indent that contains row indentId. */
    private static List<Line> loadIndent(Connection con, int indentId, boolean forUpdate) throws SQLException {
        String no = null;
        try (PreparedStatement ps = con.prepareStatement("SELECT indent_no FROM indent WHERE indent_id=?")) {
            ps.setInt(1, indentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new ApiException(404, "Indent not found.");
                no = t(rs.getString(1));
            }
        }
        String lock = forUpdate ? " FOR UPDATE" : "";
        String sql = no.isEmpty()
                ? LINE_SELECT + "WHERE i.indent_id = ?" + lock
                : LINE_SELECT + "WHERE i.indent_no = ? ORDER BY i.indent_id" + lock;
        List<Line> lines = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            if (no.isEmpty()) ps.setInt(1, indentId); else ps.setString(1, no);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lines.add(Line.read(rs));
            }
        }
        if (lines.isEmpty()) throw new ApiException(404, "Indent not found.");
        return lines;
    }

    private static Map<String, Object> summary(MobileApiServlet.Ctx c, List<Line> lines) {
        Line first = lines.get(0);
        int minId = first.id;
        boolean anyPending = false, anyL1 = false, allRejected = true, allIssued = true, canApprove = false;
        boolean samePurpose = true;
        String approvedBy = null, approvedOn = null, remarks = null;
        for (Line l : lines) {
            minId = Math.min(minId, l.id);
            String st = l.displayStatus();
            if ("PENDING".equals(st)) anyPending = true;
            if ("INCHARGE APPROVED".equals(st)) anyL1 = true;
            if (!"REJECTED".equals(st)) allRejected = false;
            if (!"ISSUED".equals(st)) allIssued = false;
            if (canAct(c, l)) canApprove = true;
            if (!t(l.purpose).equalsIgnoreCase(t(first.purpose))) samePurpose = false;
            if (!t(l.l1By).isEmpty()) { approvedBy = l.l1By; approvedOn = l.l1Date; }
            if (!t(l.remarks).isEmpty()) remarks = l.remarks;
        }
        String status = anyPending ? "PENDING" : anyL1 ? "INCHARGE APPROVED"
                : allRejected ? "REJECTED" : allIssued ? "ISSUED" : "APPROVED";

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", minId);
        m.put("indentNo", first.indentNo);
        m.put("date", first.date);
        m.put("department", first.department);
        m.put("requestedBy", first.requestedBy);
        m.put("purpose", samePurpose ? first.purpose : "Multiple (see items)");
        m.put("type", "Issue".equalsIgnoreCase(first.type) ? "Issue" : "Purchase");
        m.put("status", status);
        m.put("itemCount", lines.size());
        m.put("approvedBy", approvedBy);
        m.put("approvedOn", approvedOn);
        m.put("remarks", remarks);
        m.put("canApprove", canApprove);
        m.put("approvalLevel", !canApprove ? null
                : lines.stream().anyMatch(l -> canAct(c, l) && l.level1Open()) ? "Level 1 (Incharge)" : "Level 2 (Final)");
        return m;
    }

    // ------------------------------------------------------------------ approve / reject

    Map<String, Object> approve(MobileApiServlet.Ctx c, int indentId, String action, String remarks) throws SQLException {
        if (!isApprover(c.role)) throw new ApiException(403, "You do not have permission to approve indents.");
        boolean approve = "APPROVE".equalsIgnoreCase(action);
        if (!approve && !"REJECT".equalsIgnoreCase(action)) throw new ApiException(400, "Invalid action.");
        String note = MobileApiServlet.trim(remarks);
        if (note.length() > 500) throw new ApiException(400, "Remarks are too long (max 500 characters).");
        if (!approve && note.isEmpty()) throw new ApiException(400, "Remarks are required to reject.");

        java.sql.Date today = new java.sql.Date(System.currentTimeMillis());
        int done = 0;
        List<ApprovalEvent> events = new ArrayList<>();
        try (Connection con = InventoryDB.getConnection(c.branch)) {
            con.setAutoCommit(false);
            try {
                List<Line> lines = loadIndent(con, indentId, true);
                for (Line l : lines) {
                    if (!canAct(c, l)) continue;
                    boolean levelOne = l.level1Open();
                    if (levelOne) {
                        level1(con, l, approve, c.username, today);
                    } else {
                        level2(con, l, approve, today);
                    }
                    events.add(new ApprovalEvent(l, levelOne));
                    if (!note.isEmpty()) addRemark(con, l.id, (approve ? "Approved by " : "Rejected by ") + c.username + ": " + note);
                    done++;
                }
                if (done == 0) throw new ApiException(409, "Nothing in this indent is waiting for your approval.");
                con.commit();
            } catch (SQLException | RuntimeException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
        Set<String> sent = new HashSet<>();
        for (ApprovalEvent event : events) {
            Line line = event.line;
            String key = line.indentNo + "|" + line.department + "|" + line.requestedBy + "|" + event.levelOne;
            if (sent.add(key)) NotificationService.indentDecision(c.branch, line.requestedBy, line.department,
                    line.indentNo, line.type, event.levelOne, approve);
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("message", done + (done == 1 ? " item " : " items ") + (approve ? "approved." : "rejected."));
        return res;
    }

    private static void level1(Connection con, Line l, boolean approve, String user, java.sql.Date today) throws SQLException {
        String sql = approve
                ? "UPDATE indent SET istatus='Approved', IstausApprove=?, Iapprovedate=? WHERE indent_id=?"
                : "UPDATE indent SET istatus='Cancelled', status='Cancelled', IstausApprove=?, Iapprovedate=? WHERE indent_id=?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, user);
            ps.setDate(2, today);
            ps.setInt(3, l.id);
            ps.executeUpdate();
        }
    }

    private static void level2(Connection con, Line l, boolean approve, java.sql.Date today) throws SQLException {
        if (!approve) {
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE indent SET status='Cancelled', Fapprovedate=? WHERE indent_id=?")) {
                ps.setDate(1, today);
                ps.setInt(2, l.id);
                ps.executeUpdate();
            }
            return;
        }
        String next = l.nextStep();
        if ("Issue".equals(next)) {
            double pending = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COALESCE(SUM(qty),0) FROM indent WHERE item_id=? AND Indentnext='Issue' AND status='Approved' AND indent_id<>?")) {
                ps.setInt(1, l.itemId);
                ps.setInt(2, l.id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) pending = rs.getDouble(1);
                }
            }
            if (pending + l.qty > l.balance) {
                throw new ApiException(409, "Stock insufficient for " + l.itemName + ". Available: " + fmt(l.balance)
                        + ", Pending: " + fmt(pending) + ", Requested: " + fmt(l.qty));
            }
        }
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE indent SET status='Approved', Fapprovedate=?, Indentnext=? WHERE indent_id=?")) {
            ps.setDate(1, today);
            ps.setString(2, next);
            ps.setInt(3, l.id);
            ps.executeUpdate();
        }
    }

    private static void addRemark(Connection con, int id, String text) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE indent SET remarks = LEFT(CONCAT_WS(' | ', NULLIF(remarks,''), ?), 1000) WHERE indent_id=?")) {
            ps.setString(1, text);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    private static String fmt(double d) {
        return d == Math.rint(d) ? String.valueOf((long) d) : String.valueOf(d);
    }

    // ------------------------------------------------------------------ raise indent

    Map<String, Object> meta(MobileApiServlet.Ctx c) throws SQLException {
        Map<String, Object> res = new LinkedHashMap<>();
        boolean choose = isGlobal(c.role);
        res.put("canChooseDepartment", choose);
        res.put("department", c.department);
        res.put("departments", choose ? departments(c) : List.of());
        res.put("types", List.of("Purchase", "Issue"));
        return res;
    }

    private static List<String> departments(MobileApiServlet.Ctx c) throws SQLException {
        List<String> list = new ArrayList<>();
        try (Connection con = InventoryDB.getConnection(c.branch);
             PreparedStatement ps = con.prepareStatement(
                     "SELECT DISTINCT Department FROM dept_cate WHERE Department IS NOT NULL AND Department <> '' ORDER BY Department ASC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(rs.getString(1));
        }
        return list;
    }

    /** Only Global users may work for another department; everyone else always uses their own. */
    private String resolveDepartment(MobileApiServlet.Ctx c, String requested) throws SQLException {
        String department = c.department;
        String req = MobileApiServlet.trim(requested);
        if (isGlobal(c.role) && !req.isEmpty()) {
            department = null;
            for (String d : departments(c)) if (d.equalsIgnoreCase(req)) { department = d; break; }
            if (department == null) throw new ApiException(400, "Invalid department.");
        }
        if (department == null || department.isEmpty()) throw new ApiException(400, "Your account has no department.");
        return department;
    }

    /** Categories shown on the website's indent form: the department's own + Common; Global sees all. */
    private static List<String> allowedCategories(Connection con, MobileApiServlet.Ctx c, String department)
            throws SQLException {
        String sql = "SELECT DISTINCT Category FROM dept_cate WHERE Category IS NOT NULL AND Category <> '' "
                + (isGlobal(c.role) ? "" : "AND (Department = ? OR LOWER(TRIM(Department)) = 'common') ")
                + "ORDER BY Category";
        List<String> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            if (!isGlobal(c.role)) ps.setString(1, department);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(rs.getString(1));
            }
        }
        return list;
    }

    private static boolean containsIgnoreCase(List<String> list, String v) {
        String t = t(v);
        for (String s : list) if (t(s).equalsIgnoreCase(t)) return true;
        return false;
    }

    /**
     * Category → Sub-category → Item, as on the website's indent form.
     * GET indent/catalog?department=&category=&subcategory=
     *   always: categories; with category: subcategories; with both: items.
     */
    Map<String, Object> catalog(MobileApiServlet.Ctx c, String deptReq, String category, String subcategory,
                                String query) throws SQLException {
        String department = resolveDepartment(c, deptReq);
        String cat = MobileApiServlet.trim(category);
        String sub = MobileApiServlet.trim(subcategory);
        String q = MobileApiServlet.trim(query);
        if (cat.length() > 100 || sub.length() > 100) throw new ApiException(400, "Invalid category.");
        if (q.length() > 40) q = q.substring(0, 40);

        Map<String, Object> res = new LinkedHashMap<>();
        try (Connection con = InventoryDB.getConnection(c.branch)) {
            List<String> cats = allowedCategories(con, c, department);
            res.put("department", department);
            res.put("categories", cats);
            if (q.length() >= 2) {
                res.put("items", searchItems(con, cats, q));
                return res;
            }
            if (cat.isEmpty()) return res;
            if (!containsIgnoreCase(cats, cat)) throw new ApiException(400, "Category not allowed for " + department + ".");

            List<String> subs = new ArrayList<>();
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT DISTINCT Sub_Category FROM category WHERE Status='Active' AND Category=? "
                    + "AND Sub_Category IS NOT NULL AND Sub_Category <> '' ORDER BY Sub_Category")) {
                ps.setString(1, cat);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) subs.add(rs.getString(1));
                }
            }
            res.put("subcategories", subs);
            if (sub.isEmpty()) return res;
            if (!containsIgnoreCase(subs, sub)) throw new ApiException(400, "Invalid sub category.");

            List<Map<String, Object>> list = new ArrayList<>();
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT im.Item_id, im.Item_name, im.UOM, im.Category, im.Sub_Category, COALESCE(s.balance_qty,0) AS stock "
                    + "FROM item_master im LEFT JOIN stock s ON im.Item_id = s.item_id "
                    + "WHERE im.Category=? AND im.Sub_Category=? ORDER BY im.Item_name LIMIT 1000")) {
                ps.setString(1, cat);
                ps.setString(2, sub);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) list.add(itemJson(rs));
                }
            }
            res.put("items", list);
        }
        return res;
    }

    private static Map<String, Object> itemJson(ResultSet rs) throws SQLException {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("itemId", rs.getInt("Item_id"));
        m.put("name", rs.getString("Item_name"));
        m.put("unit", rs.getString("UOM"));
        m.put("category", rs.getString("Category"));
        m.put("subCategory", rs.getString("Sub_Category"));
        m.put("availableQty", rs.getDouble("stock"));
        return m;
    }

    /** Item name search limited to the categories the department may indent. */
    private static List<Map<String, Object>> searchItems(Connection con, List<String> cats, String q) throws SQLException {
        List<Map<String, Object>> list = new ArrayList<>();
        if (cats.isEmpty()) return list;
        StringBuilder in = new StringBuilder();
        for (int i = 0; i < cats.size(); i++) in.append(i == 0 ? "?" : ",?");
        String like = "%" + q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT im.Item_id, im.Item_name, im.UOM, im.Category, im.Sub_Category, COALESCE(s.balance_qty,0) AS stock "
                + "FROM item_master im LEFT JOIN stock s ON im.Item_id = s.item_id "
                + "WHERE im.Item_name LIKE ? AND im.Category IN (" + in + ") ORDER BY im.Item_name LIMIT 100")) {
            ps.setString(1, like);
            for (int i = 0; i < cats.size(); i++) ps.setString(i + 2, cats.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(itemJson(rs));
            }
        }
        return list;
    }

    Map<String, Object> items(MobileApiServlet.Ctx c, String q) throws SQLException {
        String term = MobileApiServlet.trim(q);
        if (term.length() > 60) term = term.substring(0, 60);
        String like = "%" + term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection con = InventoryDB.getConnection(c.branch);
             PreparedStatement ps = con.prepareStatement(
                     "SELECT im.Item_id, im.Item_name, im.UOM, im.Category, COALESCE(s.balance_qty,0) AS stock "
                     + "FROM item_master im LEFT JOIN stock s ON im.Item_id = s.item_id "
                     + "WHERE im.Item_name LIKE ? ORDER BY im.Item_name LIMIT 50")) {
            ps.setString(1, like);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("itemId", rs.getInt("Item_id"));
                    m.put("name", rs.getString("Item_name"));
                    m.put("unit", rs.getString("UOM"));
                    m.put("category", rs.getString("Category"));
                    m.put("availableQty", rs.getDouble("stock"));
                    list.add(m);
                }
            }
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("items", list);
        return res;
    }

    Map<String, Object> create(MobileApiServlet.Ctx c, JsonObject body) throws SQLException {
        String clientRef = str(body, "clientRef", 64);
        String purpose = str(body, "purpose", 200);
        String remarks = str(body, "remarks", 500);
        String type = str(body, "indentType", 20);
        String deptReq = str(body, "department", 100);

        if (purpose.isEmpty()) throw new ApiException(400, "Enter the purpose.");
        if (!"Purchase".equals(type) && !"Issue".equals(type)) throw new ApiException(400, "Choose indent type: Purchase or Issue.");

        String department = resolveDepartment(c, deptReq);

        // Same request sent twice (e.g. network retry) → return the indent already saved.
        HttpSession s = c.session;
        @SuppressWarnings("unchecked")
        Map<String, String> refs = (Map<String, String>) s.getAttribute("mobileIndentRefs");
        if (refs == null) {
            refs = java.util.Collections.synchronizedMap(new LinkedHashMap<>());
            s.setAttribute("mobileIndentRefs", refs);
        }
        if (!clientRef.isEmpty() && refs.containsKey(clientRef)) {
            Map<String, Object> res = new LinkedHashMap<>();
            res.put("indentNo", refs.get(clientRef));
            return res;
        }

        // Validate lines
        JsonElement el = body.get("items");
        if (el == null || !el.isJsonArray()) throw new ApiException(400, "Add at least one item.");
        JsonArray arr = el.getAsJsonArray();
        if (arr.size() == 0) throw new ApiException(400, "Add at least one item.");
        if (arr.size() > MAX_LINES) throw new ApiException(400, "Too many items (max " + MAX_LINES + ").");
        List<int[]> ids = new ArrayList<>();
        List<Double> qtys = new ArrayList<>();
        Set<Integer> seen = new HashSet<>();
        for (JsonElement e : arr) {
            int itemId;
            double qty;
            try {
                JsonObject o = e.getAsJsonObject();
                itemId = o.get("itemId").getAsInt();
                qty = o.get("qty").getAsDouble();
            } catch (RuntimeException ex) {
                throw new ApiException(400, "Invalid item data.");
            }
            if (itemId <= 0 || !seen.add(itemId)) throw new ApiException(400, "Invalid or duplicate item.");
            if (!(qty > 0) || qty > MAX_QTY) throw new ApiException(400, "Quantity must be between 0 and " + (long) MAX_QTY + ".");
            ids.add(new int[] {itemId});
            qtys.add(Math.round(qty * 1000d) / 1000d);
        }

        String indentNo = "";
        try (Connection con = InventoryDB.getConnection(c.branch)) {
            con.setAutoCommit(false);
            try {
                // Item names/UOM/stock come from item_master, not from the phone.
                List<String> names = new ArrayList<>(), uoms = new ArrayList<>();
                List<String> allowedCats = allowedCategories(con, c, department);
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT im.Item_name, im.UOM, im.Category, COALESCE(s.balance_qty,0) AS stock FROM item_master im "
                        + "LEFT JOIN stock s ON im.Item_id = s.item_id WHERE im.Item_id=?")) {
                    for (int i = 0; i < ids.size(); i++) {
                        ps.setInt(1, ids.get(i)[0]);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) throw new ApiException(400, "Item not found (ID " + ids.get(i)[0] + ").");
                            // Same rule as the website form: only categories mapped to the department (or Common).
                            if (!containsIgnoreCase(allowedCats, rs.getString("Category"))) {
                                throw new ApiException(400, rs.getString("Item_name") + " is not allowed for department "
                                        + department + ".");
                            }
                            names.add(rs.getString("Item_name"));
                            uoms.add(rs.getString("UOM"));
                            double stockQty = rs.getDouble("stock");
                            if ("Issue".equals(type) && qtys.get(i) > stockQty) {
                                throw new ApiException(400, "Not enough stock to issue " + rs.getString("Item_name")
                                        + ". Available: " + fmt(stockQty));
                            }
                        }
                    }
                }

                // Indent number: same sequence as the website.
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE id_sequences SET next_val = next_val + 1 WHERE seq_name='indent_no'")) {
                    if (ps.executeUpdate() != 1) throw new SQLException("id_sequences row 'indent_no' missing");
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT next_val FROM id_sequences WHERE seq_name='indent_no'");
                     ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) indentNo = rs.getString(1);
                }

                String today = java.time.LocalDate.now().toString(); // yyyy-MM-dd, as the web form sends
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO indent (indent_no, indent_date, item_id, item_name, qty, department, requested_by, "
                        + "purpose, remarks, uom, PurchaseorIssue, stock) VALUES (?,?,?,?,?,?,?,?,?,?,?, "
                        + "(SELECT COALESCE(balance_qty,0) FROM stock WHERE stock.item_id = ?))")) {
                    for (int i = 0; i < ids.size(); i++) {
                        int itemId = ids.get(i)[0];
                        ps.setString(1, indentNo);
                        ps.setString(2, today);
                        ps.setInt(3, itemId);
                        ps.setString(4, names.get(i));
                        ps.setDouble(5, qtys.get(i));
                        ps.setString(6, department);
                        ps.setString(7, c.username);
                        ps.setString(8, purpose);
                        ps.setString(9, remarks);
                        ps.setString(10, uoms.get(i));
                        ps.setString(11, type);
                        ps.setInt(12, itemId);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }
                con.commit();
            } catch (SQLException | RuntimeException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
        if (!clientRef.isEmpty()) {
            if (refs.size() > 100) refs.clear();
            refs.put(clientRef, indentNo);
        }
        NotificationService.indentSubmitted(c.branch, c.userId, indentNo, department, type);
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("indentNo", indentNo);
        return res;
    }

    private static String str(JsonObject o, String key, int max) {
        JsonElement e = o.get(key);
        if (e != null && !e.isJsonNull() && !e.isJsonPrimitive()) throw new ApiException(400, "Invalid " + key + ".");
        String v = (e == null || e.isJsonNull()) ? "" : e.getAsString().trim();
        if (v.length() > max) throw new ApiException(400, key + " is too long (max " + max + " characters).");
        return v;
    }
}
