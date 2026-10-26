package com.officecentral.inventory.dining;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.*;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.officecentral.common.db.InventoryDB;
import com.officecentral.inventory.stock.ItemCostDAO;
import com.officecentral.inventory.stock.StockEntryRules;
import java.time.LocalDate;

/**
 * Dining Hall consumption.
 *
 * POST saves one issue as a single all-or-nothing transaction. For every item it must write
 *   1. dining_hall_consumption   2. stock_issues   3. stock_ledger   4. stock (balance update)
 * and every statement must affect exactly one row. If any check or write fails, everything is
 * rolled back and nothing is saved in any table.
 */
@WebServlet(urlPatterns = {"/dining-hall", "/DiningHallServlet"})   // second one = old address, kept so old links still work
public class DiningHallServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final String DEPARTMENT = "Dining Hall";

    /** One validated form row. */
    private static final class Line {
        final int itemId; final BigDecimal qty; final String remarks;
        Line(int itemId, BigDecimal qty, String remarks) { this.itemId = itemId; this.qty = qty; this.remarks = remarks; }
    }

    // ============================================================ GET: form + master data
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) { response.sendRedirect("login.jsp"); return; }

        String branch = trim((String) sess.getAttribute("branch"));
        if (branch.isEmpty()) throw new ServletException("Branch information is missing from session.");

        try (Connection con = InventoryDB.getConnection(branch)) {
            String nextNo = "ISS1";
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COALESCE(MAX(CAST(SUBSTRING(issueno, 4) AS UNSIGNED)), 0) + 1 FROM dining_hall_consumption");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) nextNo = "ISS" + rs.getInt(1);
            }

            Map<String, Object> master = new HashMap<>();
            master.put("departments", Collections.singletonList(row("name", DEPARTMENT)));
            master.put("categories", query(con,
                    "SELECT DISTINCT Category, Department FROM dept_cate WHERE Department = ? ORDER BY Category",
                    new String[] { "name", "Category", "departmentName", "Department" }, DEPARTMENT));
            master.put("subcategories", query(con,
                    "SELECT Sub_Category, Category FROM category WHERE Status = 'Active' ORDER BY Category, Sub_Category",
                    new String[] { "name", "Sub_Category", "categoryName", "Category" }));
            master.put("items", query(con,
                    "SELECT im.Item_id, im.Item_name, im.UOM, im.Category, im.Sub_Category, COALESCE(s.balance_qty, 0) AS stock " +
                    "FROM item_master im LEFT JOIN stock s ON im.Item_id = s.item_id " +
                    "ORDER BY im.Category, im.Sub_Category, im.Item_name",
                    new String[] { "id", "Item_id", "name", "Item_name", "UOM", "UOM", "category", "Category",
                                   "subcategory", "Sub_Category", "stock", "stock" }));

            request.setAttribute("nextIssueNo", nextNo);
            request.setAttribute("masterData", master);
            request.setAttribute("selectedDept", DEPARTMENT);
            request.setAttribute("minDate", StockEntryRules.earliestDate().toString());
            request.setAttribute("maxDate", StockEntryRules.latestDate().toString());
            request.getRequestDispatcher("/WEB-INF/views/inventory/dining/dining_hall_form.jsp").forward(request, response);
        } catch (SQLException e) {
            throw new ServletException("Database Error: " + e.getMessage(), e);
        }
    }

    // ============================================================ POST: save issue (all or nothing)
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) { response.sendRedirect("login.jsp"); return; }

        String branch   = trim((String) sess.getAttribute("branch"));
        String issueNo  = trim(request.getParameter("issueno"));
        String issuedTo = trim(request.getParameter("issued_to"));
        String session  = trim(request.getParameter("session"));
        String date     = trim(request.getParameter("issue_date"));

        // ---- 1. Validate everything BEFORE touching the database
        List<Line> lines;
        LocalDate issueDay;
        try {
            if (branch.isEmpty())   throw new IllegalArgumentException("Branch information is missing.");
            if (issueNo.isEmpty())  throw new IllegalArgumentException("Issue number is missing.");
            if (issuedTo.isEmpty()) throw new IllegalArgumentException("Issued To is required.");
            if (session.isEmpty())  throw new IllegalArgumentException("Session is required.");
            if (date.isEmpty())     throw new IllegalArgumentException("Issue date is required.");
            try {
                issueDay = StockEntryRules.checkEntryDate(date);      // today .. 10 days back
            } catch (StockEntryRules.EntryError e) {
                throw new IllegalArgumentException("Issue date: " + e.getMessage());
            }
            lines = readLines(request);
        } catch (IllegalArgumentException e) {
            finish(sess, response, false, e.getMessage());
            return;
        }

        // ---- 2. One transaction: every item goes into all four tables, or nothing is saved
        boolean ok = false;
        String message;
        try (Connection con = InventoryDB.getConnection(branch)) {
            if (con == null) throw new SQLException("Unable to connect to the database.");
            con.setAutoCommit(false);
            try {
                saveIssue(con, issueNo, issuedTo, session, issueDay.toString(), lines);
                // back-dated entries: keep stock_ledger running balances in date order
                for (Line ln : lines) StockEntryRules.recalcRunningBalance(con, ln.itemId, issueDay);
                con.commit();
                ok = true;
                message = "Issue " + issueNo + " saved: " + lines.size() + " item(s).";
                System.out.println("[DiningHall] COMMITTED " + issueNo + " (" + lines.size() + " items)");
            } catch (Exception e) {
                con.rollback();
                System.err.println("[DiningHall] ROLLED BACK " + issueNo + ": " + e.getMessage());
                e.printStackTrace();
                message = "Nothing was saved. " + e.getMessage();
            } finally {
                try { con.setAutoCommit(true); } catch (SQLException ignore) { }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            message = "Nothing was saved. Database error: " + e.getMessage();
        }

        finish(sess, response, ok, message);
    }

    /** Writes the whole issue. Throws on the first problem; the caller rolls back. */
    private void saveIssue(Connection con, String issueNo, String issuedTo, String session,
                           String date, List<Line> lines) throws SQLException {

        try (PreparedStatement ps = con.prepareStatement(
                "SELECT 1 FROM dining_hall_consumption WHERE issueno = ? LIMIT 1 FOR UPDATE")) {
            ps.setString(1, issueNo);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) throw new SQLException("Issue number " + issueNo + " already exists. Please reload the form.");
            }
        }

        try (PreparedStatement psStock  = con.prepareStatement(
                     "SELECT balance_qty FROM stock WHERE item_id = ? FOR UPDATE");
             PreparedStatement psCons   = con.prepareStatement(
                     "INSERT INTO dining_hall_consumption (issueno, item_id, department, issued_to, qty_issued, remarks, " +
                     "unit_price, total_value, session, issue_date) VALUES (?,?,?,?,?,?,?,?,?,?)",
                     Statement.RETURN_GENERATED_KEYS);
             PreparedStatement psIssue  = con.prepareStatement(
                     "INSERT INTO stock_issues (issueno, item_id, department, issued_to, qty_issued, remarks, " +
                     "unit_price, total_value, issue_date) VALUES (?,?,?,?,?,?,?,?,?)",
                     Statement.RETURN_GENERATED_KEYS);
             PreparedStatement psLedger = con.prepareStatement(
                     "INSERT INTO stock_ledger (item_id, trans_type, trans_id, trans_date, qty, running_balance, " +
                     "remarks, consumption_id) VALUES (?, 'ISSUE', ?, ?, ?, ?, ?, ?)");
             PreparedStatement psUpdate = con.prepareStatement(
                     "UPDATE stock SET total_issued = total_issued + ?, balance_qty = balance_qty - ? " +
                     "WHERE item_id = ? AND balance_qty >= ?")) {

            for (Line ln : lines) {
                String tag = "Item ID " + ln.itemId;

                // a. lock the stock row and check availability
                BigDecimal balance;
                psStock.setInt(1, ln.itemId);
                try (ResultSet rs = psStock.executeQuery()) {
                    if (!rs.next()) throw new SQLException(tag + ": no stock record exists.");
                    balance   = nz(rs.getBigDecimal("balance_qty"));
                }
                if (ln.qty.compareTo(balance) > 0)
                    throw new SQLException(tag + ": insufficient stock. Requested " + ln.qty.stripTrailingZeros().toPlainString()
                            + ", available " + balance.stripTrailingZeros().toPlainString() + ".");

                // b. unit price (incl. GST): ONLY from the Item Cost master. No cost = the whole issue is not saved.
                BigDecimal price      = ItemCostDAO.requireCost(con, ln.itemId);
                BigDecimal total      = ln.qty.multiply(price).setScale(2, RoundingMode.HALF_UP);
                BigDecimal newBalance = balance.subtract(ln.qty);

                // c. dining_hall_consumption
                set(psCons, issueNo, ln.itemId, DEPARTMENT, issuedTo, ln.qty, ln.remarks, price, total, session, date);
                int consumptionId = insertAndGetId(psCons, tag + ": dining hall consumption");

                // d. stock_issues
                set(psIssue, issueNo, ln.itemId, DEPARTMENT, issuedTo, ln.qty, ln.remarks, price, total, date);
                int issueId = insertAndGetId(psIssue, tag + ": stock issue");

                // e. stock_ledger (linked to both the issue and the consumption row)
                set(psLedger, ln.itemId, issueId, date, ln.qty, newBalance, ln.remarks, consumptionId);
                if (psLedger.executeUpdate() != 1) throw new SQLException(tag + ": stock ledger was not saved.");

                // f. stock balance for this item (guarded so it can never go negative)
                set(psUpdate, ln.qty, ln.qty, ln.itemId, ln.qty);
                if (psUpdate.executeUpdate() != 1) throw new SQLException(tag + ": stock balance was not updated.");
            }
        }
    }

    // ============================================================ helpers

    /** Reads and validates the item rows. Fully empty rows are skipped. */
    private List<Line> readLines(HttpServletRequest request) {
        String[] ids = request.getParameterValues("item_id");
        String[] qty = request.getParameterValues("qty_issued");
        String[] rem = request.getParameterValues("remarks");
        if (ids == null || qty == null || ids.length == 0) throw new IllegalArgumentException("No items were submitted.");
        if (ids.length != qty.length) throw new IllegalArgumentException("Item and quantity rows do not match.");

        List<Line> lines = new ArrayList<>();
        Set<Integer> seen = new HashSet<>();
        for (int i = 0; i < ids.length; i++) {
            String id = trim(ids[i]), q = trim(qty[i]), row = "Row " + (i + 1) + ": ";
            if (id.isEmpty() && q.isEmpty()) continue;
            if (id.isEmpty()) throw new IllegalArgumentException(row + "item is missing.");
            if (q.isEmpty())  throw new IllegalArgumentException(row + "quantity is missing.");
            int itemId;
            BigDecimal qtyIssued;
            try { itemId = Integer.parseInt(id); }
            catch (NumberFormatException e) { throw new IllegalArgumentException(row + "invalid item."); }
            try { qtyIssued = new BigDecimal(q); }
            catch (NumberFormatException e) { throw new IllegalArgumentException(row + "invalid quantity '" + q + "'."); }
            if (qtyIssued.signum() <= 0) throw new IllegalArgumentException(row + "quantity must be greater than zero.");
            if (!seen.add(itemId)) throw new IllegalArgumentException(row + "this item is already in another row. Keep one row per item.");
            lines.add(new Line(itemId, qtyIssued, rem != null && i < rem.length ? trim(rem[i]) : ""));
        }
        if (lines.isEmpty()) throw new IllegalArgumentException("No valid items were submitted.");
        return lines;
    }

    /** Executes an INSERT that must add exactly one row and returns its generated id. */
    private static int insertAndGetId(PreparedStatement ps, String what) throws SQLException {
        if (ps.executeUpdate() != 1) throw new SQLException(what + " was not saved.");
        try (ResultSet keys = ps.getGeneratedKeys()) {
            if (keys.next() && keys.getInt(1) > 0) return keys.getInt(1);
        }
        throw new SQLException(what + ": could not read the new record id.");
    }

    /** Sets parameters 1..n in order (String, Integer, BigDecimal). */
    private static void set(PreparedStatement ps, Object... values) throws SQLException {
        ps.clearParameters();
        for (int i = 0; i < values.length; i++) {
            Object v = values[i];
            if (v instanceof Integer)         ps.setInt(i + 1, (Integer) v);
            else if (v instanceof BigDecimal) ps.setBigDecimal(i + 1, (BigDecimal) v);
            else                              ps.setString(i + 1, (String) v);
        }
    }

    /** Runs a SELECT and maps columns to keys: pairs of { key, column }. */
    private static List<Map<String, String>> query(Connection con, String sql, String[] keyCol, String... params)
            throws SQLException {
        List<Map<String, String>> out = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setString(i + 1, params[i]);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> m = new HashMap<>();
                    for (int k = 0; k < keyCol.length; k += 2) m.put(keyCol[k], rs.getString(keyCol[k + 1]));
                    out.add(m);
                }
            }
        }
        return out;
    }

    /** Back to the form with a success or error message (shown at the top of the form). */
    private static void finish(HttpSession sess, HttpServletResponse response, boolean ok, String message) throws IOException {
        if (sess != null) sess.setAttribute(ok ? "diningSuccess" : "diningError", message);
        response.sendRedirect("dining-hall");
    }

    private static Map<String, String> row(String k, String v) { Map<String, String> m = new HashMap<>(); m.put(k, v); return m; }
    private static BigDecimal nz(BigDecimal v) { return v == null ? BigDecimal.ZERO : v; }
    private static String trim(String v) { return v == null ? "" : v.trim(); }
}
