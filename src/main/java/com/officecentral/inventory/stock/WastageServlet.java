package com.officecentral.inventory.stock;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.officecentral.common.db.InventoryDB;

/**
 * Damage / Wastage entry – Finance department and Global role only.
 *
 * GET  /wastage  → entry form + recent entries of the selected store
 * POST /wastage  → saves one wastage entry (one number, one or more items) in ONE transaction:
 *     1. stock_wastage   – one row per item
 *     2. stock           – balance_qty − qty, total_wasted + qty   (row locked, never below zero)
 *     3. stock_ledger    – trans_type 'WASTAGE', trans_id = wastage_id, running balances recalculated
 *     4. id_sequences    – 'wastage_no' → WST/2026-27/0001
 *
 * Rules: date within the current financial year and not in the future; qty &gt; 0 and not more than stock;
 * reason required. Needs database/sql/stock_wastage.sql to be run on every store database.
 */
@WebServlet("/wastage")
public class WastageServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(WastageServlet.class.getName());

    static final String VIEW = "/WEB-INF/views/inventory/stock/wastage.jsp";
    static final String CSRF = "wastageCsrf";
    static final int MAX_LINES = 50;
    static final String[] TYPES = {"DAMAGED", "EXPIRED", "SPOILED", "BROKEN", "LOST", "OTHER"};

    private static final SecureRandom RANDOM = new SecureRandom();

    /** Finance department or Global role – same rule as the menu in header.jsp. */
    static boolean allowed(HttpSession s) {
        return StockLedgerDAO.canChooseYear((String) s.getAttribute("role"), (String) s.getAttribute("department"));
    }

    /** Logged-in Finance/Global user, else redirect / 403. Returns null when the request was answered. */
    static HttpSession guard(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return null;
        }
        if (!allowed(s)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Damage / Wastage is available only to Finance and Global users.");
            return null;
        }
        return s;
    }

    // ------------------------------------------------------------------ GET

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession s = guard(req, resp);
        if (s == null) return;
        show(req, resp, s, null, null);
    }

    private void show(HttpServletRequest req, HttpServletResponse resp, HttpSession s,
                      String error, Map<String, Object> form) throws ServletException, IOException {
        String branch = (String) s.getAttribute("branch");
        List<Map<String, Object>> items = new ArrayList<>();
        List<Map<String, Object>> recent = new ArrayList<>();
        try (Connection con = InventoryDB.getConnection(branch)) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT im.Item_id, im.Item_name, im.Category, im.UOM, "
                    + "COALESCE(st.balance_qty,0) AS balance, COALESCE(ic.unit_cost, st.last_price, 0) AS rate "
                    + "FROM item_master im LEFT JOIN stock st ON st.item_id = im.Item_id "
                    + "LEFT JOIN item_cost ic ON ic.item_id = im.Item_id "
                    + "WHERE COALESCE(st.balance_qty,0) > 0 "
                    + "ORDER BY im.Category, im.Item_name");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", rs.getInt("Item_id"));
                    m.put("name", rs.getString("Item_name"));
                    m.put("category", rs.getString("Category"));
                    m.put("uom", rs.getString("UOM"));
                    m.put("balance", rs.getBigDecimal("balance"));
                    m.put("rate", rs.getBigDecimal("rate"));
                    items.add(m);
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT w.wastage_no, w.wastage_date, w.wastage_type, w.qty, w.total_value, w.reason, "
                    + "w.entered_by, im.Item_name, im.UOM FROM stock_wastage w "
                    + "JOIN item_master im ON im.Item_id = w.item_id "
                    + "ORDER BY w.wastage_id DESC LIMIT 25");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("no", rs.getString("wastage_no"));
                    m.put("date", rs.getDate("wastage_date").toLocalDate());
                    m.put("type", rs.getString("wastage_type"));
                    m.put("item", rs.getString("Item_name"));
                    m.put("uom", rs.getString("UOM"));
                    m.put("qty", rs.getBigDecimal("qty"));
                    m.put("value", rs.getBigDecimal("total_value"));
                    m.put("reason", rs.getString("reason"));
                    m.put("by", rs.getString("entered_by"));
                    recent.add(m);
                }
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Wastage page load failed", e);
            error = "Could not load data. If this is the first use, run sql/stock_wastage.sql on this store's database.";
        }
        req.setAttribute("items", items);
        req.setAttribute("recent", recent);
        req.setAttribute("types", TYPES);
        req.setAttribute("minDate", StockLedgerDAO.yearStart().toString());
        req.setAttribute("maxDate", StockLedgerDAO.today().toString());
        req.setAttribute("csrf", token(s));
        req.setAttribute("error", error);
        req.setAttribute("form", form);
        req.setAttribute("saved", req.getParameter("saved"));
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private static String token(HttpSession s) {
        Object t = s.getAttribute(CSRF);
        if (t == null) {
            byte[] b = new byte[32];
            RANDOM.nextBytes(b);
            t = Base64.getUrlEncoder().withoutPadding().encodeToString(b);
            s.setAttribute(CSRF, t);
        }
        return (String) t;
    }

    // ------------------------------------------------------------------ POST

    /** One validated line of the entry. */
    static final class Line {
        int itemId;
        BigDecimal qty;
        String type;
        String reason;
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        HttpSession s = guard(req, resp);
        if (s == null) return;

        String expected = (String) s.getAttribute(CSRF);
        String given = req.getParameter("csrf");
        if (expected == null || given == null
                || !MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), given.getBytes(StandardCharsets.UTF_8))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Form expired. Please reload the page and try again.");
            return;
        }

        Map<String, Object> form = new LinkedHashMap<>();
        form.put("date", req.getParameter("wastageDate"));
        form.put("department", req.getParameter("department"));

        // ---- validate header ----
        LocalDate date;
        try {
            date = LocalDate.parse(trim(req.getParameter("wastageDate")));
        } catch (DateTimeParseException e) {
            show(req, resp, s, "Select a valid wastage date.", form);
            return;
        }
        if (date.isAfter(StockLedgerDAO.today()) || date.isBefore(StockLedgerDAO.yearStart())) {
            show(req, resp, s, "Wastage date must be between " + StockLedgerDAO.yearStart().format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy"))
                    + " and today (current financial year).", form);
            return;
        }
        String department = trim(req.getParameter("department"));
        if (department.length() > 45) department = department.substring(0, 45);

        // ---- validate lines ----
        String[] itemIds = req.getParameterValues("itemId");
        String[] qtys = req.getParameterValues("qty");
        String[] types = req.getParameterValues("type");
        String[] reasons = req.getParameterValues("reason");
        List<Line> lines = new ArrayList<>();
        Set<Integer> seen = new LinkedHashSet<>();
        int n = itemIds == null ? 0 : itemIds.length;
        if (n == 0 || qtys == null || types == null || reasons == null
                || qtys.length != n || types.length != n || reasons.length != n) {
            show(req, resp, s, "Add at least one item.", form);
            return;
        }
        if (n > MAX_LINES) {
            show(req, resp, s, "Enter at most " + MAX_LINES + " items at a time.", form);
            return;
        }
        for (int i = 0; i < n; i++) {
            if (trim(itemIds[i]).isEmpty() && trim(qtys[i]).isEmpty()) continue; // blank row
            Line l = new Line();
            int row = i + 1;
            try {
                l.itemId = Integer.parseInt(trim(itemIds[i]));
                if (l.itemId <= 0) throw new NumberFormatException();
            } catch (NumberFormatException e) {
                show(req, resp, s, "Row " + row + ": select an item.", form);
                return;
            }
            if (!seen.add(l.itemId)) {
                show(req, resp, s, "Row " + row + ": the same item is entered twice. Combine the quantity in one row.", form);
                return;
            }
            try {
                l.qty = new BigDecimal(trim(qtys[i]));
            } catch (NumberFormatException e) {
                show(req, resp, s, "Row " + row + ": enter a valid quantity.", form);
                return;
            }
            if (l.qty.signum() <= 0 || l.qty.scale() > 2 || l.qty.compareTo(new BigDecimal("99999999")) > 0) {
                show(req, resp, s, "Row " + row + ": quantity must be more than 0 with at most 2 decimals.", form);
                return;
            }
            l.type = trim(types[i]).toUpperCase(java.util.Locale.ROOT);
            if (!java.util.Arrays.asList(TYPES).contains(l.type)) {
                show(req, resp, s, "Row " + row + ": select the wastage type.", form);
                return;
            }
            l.reason = trim(reasons[i]);
            if (l.reason.isEmpty()) {
                show(req, resp, s, "Row " + row + ": enter the reason.", form);
                return;
            }
            if (l.reason.length() > 255) l.reason = l.reason.substring(0, 255);
            lines.add(l);
        }
        if (lines.isEmpty()) {
            show(req, resp, s, "Add at least one item.", form);
            return;
        }

        String branch = (String) s.getAttribute("branch");
        String user = String.valueOf(s.getAttribute("username"));
        try {
            String no = save(branch, date, department, user, lines);
            resp.sendRedirect(req.getContextPath() + "/wastage?saved=" + java.net.URLEncoder.encode(no, "UTF-8"));
        } catch (UserError e) {
            show(req, resp, s, e.getMessage(), form);
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Wastage save failed", e);
            show(req, resp, s, "Could not save the wastage entry. Nothing was changed. Please try again.", form);
        }
    }

    /** A problem the user can fix (shown on the form). The transaction is rolled back. */
    static final class UserError extends Exception {
        private static final long serialVersionUID = 1L;
        UserError(String m) { super(m); }
    }

    /** Saves the whole entry in one transaction. @return the wastage number */
    String save(String branch, LocalDate date, String department, String user, List<Line> lines)
            throws SQLException, UserError {
        try (Connection con = InventoryDB.getConnection(branch)) {
            boolean auto = con.getAutoCommit();
            con.setAutoCommit(false);
            try {
                String no = nextNumber(con);
                Set<Integer> items = new LinkedHashSet<>();
                try (PreparedStatement lock = con.prepareStatement(
                             "SELECT st.balance_qty, COALESCE(ic.unit_cost, st.last_price, 0) AS last_price, im.Item_name, im.UOM "
                             + "FROM stock st JOIN item_master im ON im.Item_id = st.item_id "
                             + "LEFT JOIN item_cost ic ON ic.item_id = st.item_id WHERE st.item_id = ? FOR UPDATE OF st");
                     PreparedStatement insW = con.prepareStatement(
                             "INSERT INTO stock_wastage (wastage_no, item_id, wastage_date, wastage_type, qty, unit_price, "
                             + "total_value, department, reason, entered_by) VALUES (?,?,?,?,?,?,?,?,?,?)",
                             Statement.RETURN_GENERATED_KEYS);
                     PreparedStatement updS = con.prepareStatement(
                             "UPDATE stock SET balance_qty = balance_qty - ?, total_wasted = total_wasted + ? "
                             + "WHERE item_id = ? AND balance_qty >= ?");
                     PreparedStatement insL = con.prepareStatement(
                             "INSERT INTO stock_ledger (item_id, trans_type, trans_id, trans_date, qty, running_balance, remarks) "
                             + "VALUES (?, 'WASTAGE', ?, ?, ?, 0, ?)")) {

                    for (Line l : lines) {
                        BigDecimal balance, rate;
                        String name, uom;
                        lock.setInt(1, l.itemId);
                        try (ResultSet rs = lock.executeQuery()) {
                            if (!rs.next()) throw new UserError("Item " + l.itemId + " has no stock in this store.");
                            balance = nz(rs.getBigDecimal("balance_qty"));
                            rate = nz(rs.getBigDecimal("last_price"));
                            name = rs.getString("Item_name");
                            uom = rs.getString("UOM");
                        }
                        if (l.qty.compareTo(balance) > 0) {
                            throw new UserError(name + ": only " + balance.stripTrailingZeros().toPlainString() + " "
                                    + (uom == null ? "" : uom) + " in stock; cannot write off " + l.qty.toPlainString() + ".");
                        }
                        BigDecimal value = l.qty.multiply(rate).setScale(2, RoundingMode.HALF_UP);

                        insW.setString(1, no);
                        insW.setInt(2, l.itemId);
                        insW.setDate(3, java.sql.Date.valueOf(date));
                        insW.setString(4, l.type);
                        insW.setBigDecimal(5, l.qty);
                        insW.setBigDecimal(6, rate);
                        insW.setBigDecimal(7, value);
                        insW.setString(8, department.isEmpty() ? null : department);
                        insW.setString(9, l.reason);
                        insW.setString(10, user);
                        insW.executeUpdate();
                        int wastageId;
                        try (ResultSet k = insW.getGeneratedKeys()) {
                            if (!k.next()) throw new SQLException("No wastage_id returned");
                            wastageId = k.getInt(1);
                        }

                        updS.setBigDecimal(1, l.qty);
                        updS.setBigDecimal(2, l.qty);
                        updS.setInt(3, l.itemId);
                        updS.setBigDecimal(4, l.qty);
                        if (updS.executeUpdate() != 1) throw new UserError(name + ": stock changed while saving. Please try again.");

                        insL.setInt(1, l.itemId);
                        insL.setInt(2, wastageId);
                        insL.setDate(3, java.sql.Date.valueOf(date));
                        insL.setBigDecimal(4, l.qty);
                        String rem = "Wastage " + no + " - " + l.type + " - " + l.reason;
                        insL.setString(5, rem.length() > 1000 ? rem.substring(0, 1000) : rem);
                        insL.executeUpdate();
                        items.add(l.itemId);
                    }
                }
                // Entries may be back-dated: rebuild running balances of the items touched
                for (int itemId : items) recalculateLedger(con, itemId);
                con.commit();
                return no;
            } catch (SQLException | UserError | RuntimeException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(auto);
            }
        }
    }

    /** WST/2026-27/0001 from id_sequences 'wastage_no' (row-locked by the UPDATE). */
    private static String nextNumber(Connection con) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE id_sequences SET next_val = next_val + 1 WHERE seq_name = 'wastage_no'")) {
            if (ps.executeUpdate() != 1) {
                throw new SQLException("id_sequences row 'wastage_no' missing - run sql/stock_wastage.sql");
            }
        }
        int n;
        try (PreparedStatement ps = con.prepareStatement("SELECT next_val FROM id_sequences WHERE seq_name = 'wastage_no'");
             ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) throw new SQLException("id_sequences row 'wastage_no' missing");
            n = rs.getInt(1);
        }
        return "WST/" + StockLedgerDAO.fyLabel(StockLedgerDAO.currentFy()) + "/" + String.format("%04d", n);
    }

    /** Same rule as ConsumptionUpdateServlet: RECEIPT adds, everything else (ISSUE, WASTAGE) subtracts. */
    static void recalculateLedger(Connection con, int itemId) throws SQLException {
        try (PreparedStatement sel = con.prepareStatement(
                     "SELECT ledger_id, trans_type, qty FROM stock_ledger WHERE item_id = ? ORDER BY trans_date, ledger_id");
             PreparedStatement upd = con.prepareStatement("UPDATE stock_ledger SET running_balance = ? WHERE ledger_id = ?")) {
            sel.setInt(1, itemId);
            BigDecimal bal = BigDecimal.ZERO;
            int count = 0;
            try (ResultSet rs = sel.executeQuery()) {
                while (rs.next()) {
                    BigDecimal q = nz(rs.getBigDecimal("qty"));
                    bal = "RECEIPT".equalsIgnoreCase(trim(rs.getString("trans_type"))) ? bal.add(q) : bal.subtract(q);
                    upd.setBigDecimal(1, bal);
                    upd.setInt(2, rs.getInt("ledger_id"));
                    upd.addBatch();
                    if (++count % 500 == 0) upd.executeBatch();
                }
            }
            if (count % 500 != 0) upd.executeBatch();
        }
    }

    static BigDecimal nz(BigDecimal b) {
        return b == null ? BigDecimal.ZERO : b;
    }

    static String trim(String s) {
        return s == null ? "" : s.trim();
    }
}
