package com.officecentral.inventory.dining;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.officecentral.common.db.InventoryDB;
import com.officecentral.inventory.stock.ItemCostDAO;
import com.officecentral.inventory.stock.StockEntryRules;

/**
 * Edit Dining Hall consumption (quantity, department, issued to, remarks) – all selected rows in ONE transaction.
 *
 * For every edited row:
 *   - only consumption dated today or up to 10 days back can be edited
 *   - stock row is locked; an increase is rejected when the extra quantity is not in stock (never below zero)
 *   - price: the price recorded on the day is kept; old rows without a price take the Item Cost master price
 *   - the same change is written to dining_hall_consumption, stock_issues (its twin row), stock_ledger and stock
 *   - stock_ledger running balances are recalculated from the consumption date
 * Any problem = nothing is saved; the reason is shown on the page.
 */
@WebServlet(urlPatterns = {"/dining-consumption-update", "/UpdateConsumptionByDateServlet"})   // second one = old address, kept so old links still work
public class ConsumptionUpdateServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(ConsumptionUpdateServlet.class.getName());

    /** Session key for the error shown on editConsumption.jsp (read by ?msg=error). */
    public static final String ERROR_KEY = "consumptionError";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        String branch = (String) sess.getAttribute("branch");

        request.setCharacterEncoding("UTF-8");
        String selectedDate = request.getParameter("selected_date");
        String[] selectedIssueIds = request.getParameterValues("selected_issue_id");

        if (selectedIssueIds == null || selectedIssueIds.length == 0) {
            response.sendRedirect("dining-consumption?selected_date=" + encodeParam(selectedDate));
            return;
        }

        try {
            save(branch, request, selectedIssueIds);
            response.sendRedirect("dining-consumption?selected_date=" + encodeParam(selectedDate) + "&msg=updated");
        } catch (StockEntryRules.EntryError | ItemCostDAO.NoCostException e) {
            fail(sess, response, selectedDate, "Nothing was saved. " + e.getMessage());
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Consumption update failed", e);
            fail(sess, response, selectedDate, "Nothing was saved because of a database error. Please try again.");
        }
    }

    private void save(String branch, HttpServletRequest request, String[] ids)
            throws SQLException, StockEntryRules.EntryError {

        try (Connection con = InventoryDB.getConnection(branch)) {
            boolean auto = con.getAutoCommit();
            con.setAutoCommit(false);
            Map<Integer, LocalDate> recalcFrom = new LinkedHashMap<>();   // item -> earliest date touched
            try {
                for (String idStr : ids) {
                    int issueId;
                    try {
                        issueId = Integer.parseInt(trim(idStr));
                    } catch (NumberFormatException e) {
                        continue;
                    }
                    String qtyStr = trim(request.getParameter("qty_issued_" + issueId));
                    if (qtyStr.isEmpty()) continue;
                    BigDecimal newQty;
                    try {
                        newQty = new BigDecimal(qtyStr);
                    } catch (NumberFormatException e) {
                        throw new StockEntryRules.EntryError("Invalid quantity '" + qtyStr + "'.");
                    }
                    if (newQty.signum() < 0 || newQty.scale() > 2) {
                        throw new StockEntryRules.EntryError("Quantity must be 0 or more, with at most 2 decimals.");
                    }
                    editOne(con, request, issueId, newQty, recalcFrom);
                }
                for (Map.Entry<Integer, LocalDate> e : recalcFrom.entrySet()) {
                    StockEntryRules.recalcRunningBalance(con, e.getKey(), e.getValue());
                }
                con.commit();
            } catch (SQLException | StockEntryRules.EntryError | RuntimeException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(auto);
            }
        }
    }

    private void editOne(Connection con, HttpServletRequest request, int issueId, BigDecimal newQty,
                         Map<Integer, LocalDate> recalcFrom) throws SQLException, StockEntryRules.EntryError {

        // 1. The consumption row (locked)
        int itemId;
        String issueNo, itemName, oldDept, oldTo, oldRemarks;
        BigDecimal oldQty, unitPrice;
        LocalDate day;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT d.item_id, d.issueno, d.qty_issued, d.unit_price, d.issue_date, d.department, d.issued_to,"
                + " d.remarks, im.Item_name FROM dining_hall_consumption d"
                + " LEFT JOIN item_master im ON im.Item_id = d.item_id WHERE d.issue_id = ? FOR UPDATE")) {
            ps.setInt(1, issueId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new StockEntryRules.EntryError("A selected consumption entry no longer exists. Reload the page.");
                itemId = rs.getInt("item_id");
                issueNo = rs.getString("issueno");
                oldQty = nz(rs.getBigDecimal("qty_issued"));
                unitPrice = rs.getBigDecimal("unit_price");
                java.sql.Timestamp ts = rs.getTimestamp("issue_date");
                if (ts == null) throw new StockEntryRules.EntryError("Consumption " + issueNo + " has no date and cannot be edited.");
                day = ts.toLocalDateTime().toLocalDate();
                oldDept = rs.getString("department");
                oldTo = rs.getString("issued_to");
                oldRemarks = rs.getString("remarks");
                itemName = rs.getString("Item_name") == null ? "Item " + itemId : rs.getString("Item_name");
            }
        }
        StockEntryRules.checkWindow(day, itemName + " (" + issueNo + ") dated");

        String dept = param(request, "department_" + issueId, oldDept, 45);
        String issuedTo = param(request, "issued_to_" + issueId, oldTo, 100);
        String remarks = param(request, "remarks_" + issueId, oldRemarks, 255);
        if (issuedTo == null || issuedTo.isEmpty()) issuedTo = oldTo;      // issued_to is NOT NULL

        // 2. Price: keep the price recorded on the day; old rows without a price use the Item Cost master
        if (unitPrice == null || unitPrice.signum() == 0) unitPrice = ItemCostDAO.requireCost(con, itemId);
        BigDecimal total = newQty.multiply(unitPrice).setScale(2, RoundingMode.HALF_UP);
        BigDecimal diff = newQty.subtract(oldQty);          // > 0 = more stock goes out

        // 3. Stock (locked): an increase needs the extra quantity in stock
        BigDecimal balance;
        try (PreparedStatement ps = con.prepareStatement("SELECT balance_qty FROM stock WHERE item_id = ? FOR UPDATE")) {
            ps.setInt(1, itemId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new StockEntryRules.EntryError(itemName + ": no stock record exists.");
                balance = nz(rs.getBigDecimal(1));
            }
        }
        if (diff.signum() > 0 && balance.compareTo(diff) < 0) {
            throw new StockEntryRules.EntryError("Not enough stock of " + itemName + " to increase " + issueNo
                    + " by " + plain(diff) + ". Available " + plain(balance) + ".");
        }

        // 4. dining_hall_consumption
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE dining_hall_consumption SET department = ?, issued_to = ?, qty_issued = ?, remarks = ?,"
                + " unit_price = ?, total_value = ? WHERE issue_id = ?")) {
            ps.setString(1, dept);
            ps.setString(2, issuedTo);
            ps.setBigDecimal(3, newQty);
            ps.setString(4, remarks);
            ps.setBigDecimal(5, unitPrice);
            ps.setBigDecimal(6, total);
            ps.setInt(7, issueId);
            if (ps.executeUpdate() != 1) throw new SQLException("dining_hall_consumption not updated: " + issueId);
        }

        // 5. stock_issues twin row: found through the ledger link, else by issue number + item
        Integer stockIssueId = null;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT si.issue_id FROM stock_ledger sl JOIN stock_issues si ON si.issue_id = sl.trans_id"
                + " AND si.item_id = sl.item_id WHERE sl.consumption_id = ? AND sl.item_id = ? AND sl.trans_type = 'ISSUE'"
                + " LIMIT 1")) {
            ps.setInt(1, issueId);
            ps.setInt(2, itemId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) stockIssueId = rs.getInt(1);
            }
        }
        if (stockIssueId == null) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT issue_id FROM stock_issues WHERE issueno = ? AND item_id = ? ORDER BY issue_id LIMIT 1")) {
                ps.setString(1, issueNo);
                ps.setInt(2, itemId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) stockIssueId = rs.getInt(1);
                }
            }
        }
        if (stockIssueId != null) {
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE stock_issues SET department = ?, issued_to = ?, qty_issued = ?, remarks = ?,"
                    + " unit_price = ?, total_value = ? WHERE issue_id = ?")) {
                ps.setString(1, dept);
                ps.setString(2, issuedTo);
                ps.setBigDecimal(3, newQty);
                ps.setString(4, remarks);
                ps.setBigDecimal(5, unitPrice);
                ps.setBigDecimal(6, total);
                ps.setInt(7, stockIssueId);
                ps.executeUpdate();
            }
        } else {
            // Older entry saved without its stock_issues row: add it so issue reports include this consumption
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO stock_issues (issueno, item_id, department, issued_to, qty_issued, remarks,"
                    + " unit_price, total_value, issue_date) VALUES (?,?,?,?,?,?,?,?,?)",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, issueNo);
                ps.setInt(2, itemId);
                ps.setString(3, dept);
                ps.setString(4, issuedTo);
                ps.setBigDecimal(5, newQty);
                ps.setString(6, remarks);
                ps.setBigDecimal(7, unitPrice);
                ps.setBigDecimal(8, total);
                ps.setDate(9, java.sql.Date.valueOf(day));
                ps.executeUpdate();
                try (ResultSet k = ps.getGeneratedKeys()) {
                    if (k.next()) stockIssueId = k.getInt(1);
                }
            }
        }

        // 6. stock_ledger: the ISSUE row of this consumption carries the full (new) quantity
        int rows;
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE stock_ledger SET qty = ?, remarks = ? WHERE consumption_id = ? AND item_id = ? AND trans_type = 'ISSUE'")) {
            ps.setBigDecimal(1, newQty);
            ps.setString(2, remarks);
            ps.setInt(3, issueId);
            ps.setInt(4, itemId);
            rows = ps.executeUpdate();
        }
        if (rows == 0) {
            // Missing ledger row: add it with the consumption's own date and its stock_issues id
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO stock_ledger (item_id, trans_type, trans_id, trans_date, qty, running_balance, remarks,"
                    + " consumption_id) VALUES (?, 'ISSUE', ?, ?, ?, 0, ?, ?)")) {
                ps.setInt(1, itemId);
                if (stockIssueId == null) ps.setNull(2, java.sql.Types.INTEGER); else ps.setInt(2, stockIssueId);
                ps.setDate(3, java.sql.Date.valueOf(day));
                ps.setBigDecimal(4, newQty);
                ps.setString(5, remarks);
                ps.setInt(6, issueId);
                ps.executeUpdate();
            }
        }

        // 7. stock: only the difference (guarded so the balance never goes below zero)
        if (diff.signum() != 0) {
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE stock SET total_issued = COALESCE(total_issued, 0) + ?, balance_qty = COALESCE(balance_qty, 0) - ?"
                    + " WHERE item_id = ? AND COALESCE(balance_qty, 0) - ? >= 0")) {
                ps.setBigDecimal(1, diff);
                ps.setBigDecimal(2, diff);
                ps.setInt(3, itemId);
                ps.setBigDecimal(4, diff);
                if (ps.executeUpdate() != 1) {
                    throw new StockEntryRules.EntryError("Stock of " + itemName + " changed while saving. Please try again.");
                }
            }
        }

        LocalDate prev = recalcFrom.get(itemId);
        if (prev == null || day.isBefore(prev)) recalcFrom.put(itemId, day);
    }

    private static void fail(HttpSession sess, HttpServletResponse response, String selectedDate, String message)
            throws IOException {
        sess.setAttribute(ERROR_KEY, message);
        response.sendRedirect("dining-consumption?selected_date=" + encodeParam(selectedDate) + "&msg=error");
    }

    /** Submitted value (trimmed, cut to max); the stored value when the field was not sent. */
    private static String param(HttpServletRequest r, String name, String current, int max) {
        String v = r.getParameter(name);
        if (v == null) return current;
        v = v.trim();
        return v.length() > max ? v.substring(0, max) : v;
    }

    private static BigDecimal nz(BigDecimal b) {
        return b == null ? BigDecimal.ZERO : b;
    }

    private static String plain(BigDecimal b) {
        return b.stripTrailingZeros().toPlainString();
    }

    private static String trim(String s) {
        return s == null ? "" : s.trim();
    }

    private static String encodeParam(String param) {
        if (param == null) return "";
        return URLEncoder.encode(param.trim(), StandardCharsets.UTF_8);
    }
}
