package com.officecentral.inventory.issue;

import com.officecentral.common.db.InventoryDB;
import com.officecentral.common.notification.NotificationService;
import com.officecentral.inventory.stock.ItemCostDAO;
import com.officecentral.inventory.stock.StockEntryRules;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.*;
import java.time.LocalDate;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Issue Stock against approved indents.
 *
 * GET  /issue  → approved indents waiting for issue (qty, item, department and price are shown read-only)
 * POST /issue  → issues ONE indent in a single transaction, then redirects back (so a page refresh can never
 *                issue it twice). Everything is taken from the database, not from the form:
 *                  item, department, issued-to and quantity  → the indent row (locked; must still be approved and
 *                                                            not yet issued; the full indent quantity is issued)
 *                  unit price (incl. GST)                    → Item Cost master
 *                The only value from the form is the issue date: today or up to 10 days back.
 */
@WebServlet(urlPatterns = {"/issue", "/IssueServlet"})   // second one = old address, kept so old links still work
public class IssueServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(IssueServlet.class.getName());

    private static final String FLASH = "issueMessage";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        String branch = (String) sess.getAttribute("branch");

        List<Map<String, Object>> indentList = new ArrayList<>();

        // One query: indent + current stock + Item Cost price (no writes on GET)
        String sql = """
            SELECT i.indent_id, i.indent_no, i.requested_by, i.department, i.item_id,
                   i.item_name, i.qty, i.UOM, i.purpose, i.remarks,
                   COALESCE(s.balance_qty, 0) AS balance_qty, ic.unit_cost
            FROM indent i
            LEFT JOIN stock s ON s.item_id = i.item_id
            LEFT JOIN item_cost ic ON ic.item_id = i.item_id
            WHERE i.status = 'Approved'
              AND i.Indentnext = 'Issue'
              AND (i.Issued_status IS NULL OR i.Issued_status = 'Pending')
            ORDER BY i.indent_id DESC
            """;

        try (Connection con = InventoryDB.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                BigDecimal qty = rs.getBigDecimal("qty");
                BigDecimal stock = rs.getBigDecimal("balance_qty");
                BigDecimal price = rs.getBigDecimal("unit_cost");
                int itemId = rs.getInt("item_id");
                boolean linked = !rs.wasNull() && itemId > 0;

                row.put("indent_id", rs.getInt("indent_id"));
                row.put("indent_no", rs.getString("indent_no"));
                row.put("requested_by", rs.getString("requested_by"));
                row.put("department", rs.getString("department"));
                row.put("item_id", itemId);
                row.put("item_name", rs.getString("item_name"));
                row.put("qty_requested", qty);
                row.put("UOM", rs.getString("UOM"));
                row.put("purpose", rs.getString("purpose"));
                row.put("remarks", rs.getString("remarks"));
                row.put("available_stock", stock);
                row.put("unit_price", price);
                row.put("has_cost", price != null);
                row.put("total_value", price == null || qty == null ? null
                        : qty.multiply(price).setScale(2, RoundingMode.HALF_UP));
                String block = !linked ? "Item not linked to Item Master"
                        : price == null ? null      // shown separately with a link to Item Cost
                        : (qty == null || stock.compareTo(qty) < 0) ? "Not enough stock" : null;
                row.put("block_reason", block);
                row.put("can_issue", linked && price != null && block == null);
                indentList.add(row);
            }

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Issue page load failed", e);
            request.setAttribute("message", "❌ Could not load the indents. Please try again.");
        }

        Object flash = sess.getAttribute(FLASH);
        if (flash != null) {
            sess.removeAttribute(FLASH);
            request.setAttribute("message", flash);
        }
        request.setAttribute("indentList", indentList);
        request.setAttribute("minDate", StockEntryRules.earliestDate().toString());
        request.setAttribute("maxDate", StockEntryRules.latestDate().toString());
        request.setAttribute("backDays", StockEntryRules.BACKDATE_DAYS);
        request.getRequestDispatcher("/WEB-INF/views/inventory/issue/issue.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        String branch = (String) sess.getAttribute("branch");

        String message;
        try {
            int indentId;
            try {
                indentId = Integer.parseInt(trim(request.getParameter("indentId")));
            } catch (NumberFormatException e) {
                throw new StockEntryRules.EntryError("Select an indent to issue.");
            }
            LocalDate issueDate = StockEntryRules.checkEntryDate(request.getParameter("issueDate"));

            String[] done = issue(branch, indentId, issueDate);   // {indentNo, issuedTo, itemName, qty, issueNo}
            try {
                NotificationService.stockIssued(branch, done[0], done[1]);
            } catch (RuntimeException e) {
                LOG.log(Level.WARNING, "Issue notification failed", e);   // issue is already saved
            }
            message = "✅ Issued " + done[3] + " of " + done[2] + " against indent " + done[0]
                    + " (Issue No " + done[4] + ").";

        } catch (StockEntryRules.EntryError | ItemCostDAO.NoCostException e) {
            message = "❌ Not issued: " + e.getMessage();
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Issue failed", e);
            message = "❌ Not issued. Nothing was saved. Please try again.";
        }

        // Post/Redirect/Get: a refresh only reloads the list, it can never post the issue again
        sess.setAttribute(FLASH, message);
        response.sendRedirect("issue");
    }

    /** Issues one indent in one transaction. @return {indentNo, issuedTo, itemName, qty, issueNo} */
    private String[] issue(String branch, int indentId, LocalDate issueDate)
            throws SQLException, StockEntryRules.EntryError {

        try (Connection con = InventoryDB.getConnection(branch)) {
            boolean auto = con.getAutoCommit();
            con.setAutoCommit(false);
            try {
                // 1. Lock the indent; it must still be approved for issue and not issued yet
                String indentNo, itemName, department, issuedTo, status, next, issued;
                int itemId;
                BigDecimal qty;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT indent_no, item_id, item_name, qty, department, requested_by, status, Indentnext,"
                        + " Issued_status FROM indent WHERE indent_id = ? FOR UPDATE")) {
                    ps.setInt(1, indentId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new StockEntryRules.EntryError("Indent not found. Please reload the page.");
                        indentNo = rs.getString("indent_no");
                        itemId = rs.getInt("item_id");
                        if (rs.wasNull() || itemId <= 0) {
                            throw new StockEntryRules.EntryError("Indent " + indentNo + " is not linked to an item in Item Master.");
                        }
                        itemName = rs.getString("item_name");
                        qty = rs.getBigDecimal("qty");
                        department = rs.getString("department");
                        issuedTo = rs.getString("requested_by");
                        status = trim(rs.getString("status"));
                        next = trim(rs.getString("Indentnext"));
                        issued = trim(rs.getString("Issued_status"));
                    }
                }
                if (!"Approved".equalsIgnoreCase(status) || !"Issue".equalsIgnoreCase(next)
                        || !(issued.isEmpty() || "Pending".equalsIgnoreCase(issued))) {
                    throw new StockEntryRules.EntryError("Indent " + indentNo
                            + " is already issued or is not approved for issue.");
                }
                if (qty == null || qty.signum() <= 0) {
                    throw new StockEntryRules.EntryError("Indent " + indentNo + " has no quantity to issue.");
                }

                // 2. Lock the stock row; the full indent quantity must be available
                BigDecimal balance;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT COALESCE(balance_qty, 0) FROM stock WHERE item_id = ? FOR UPDATE")) {
                    ps.setInt(1, itemId);
                    try (ResultSet rs = ps.executeQuery()) {
                        balance = rs.next() ? rs.getBigDecimal(1) : BigDecimal.ZERO;
                    }
                }
                if (balance.compareTo(qty) < 0) {
                    throw new StockEntryRules.EntryError("Not enough stock of " + itemName + ". Available "
                            + plain(balance) + ", indent " + plain(qty) + ".");
                }

                // 3. Price (incl. GST) from the Item Cost master
                BigDecimal unitPrice = ItemCostDAO.requireCost(con, itemId);
                BigDecimal totalValue = qty.multiply(unitPrice).setScale(2, RoundingMode.HALF_UP);

                // 4. Next issue number
                String issueNo = "1";
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT COALESCE(MAX(CAST(issueno AS UNSIGNED)),0)+1 AS next_no FROM stock_issues");
                     ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) issueNo = rs.getString("next_no");
                }

                // 5. stock_issues
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO stock_issues (issueno, item_id, issued_to, department, qty_issued, remarks,"
                        + " indent_no, unit_price, total_value, issue_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
                    ps.setString(1, issueNo);
                    ps.setInt(2, itemId);
                    ps.setString(3, issuedTo);
                    ps.setString(4, department);
                    ps.setBigDecimal(5, qty);
                    ps.setString(6, "Issued against indent " + indentNo);
                    ps.setString(7, indentNo);
                    ps.setBigDecimal(8, unitPrice);
                    ps.setBigDecimal(9, totalValue);
                    ps.setDate(10, java.sql.Date.valueOf(issueDate));
                    if (ps.executeUpdate() != 1) throw new SQLException("stock_issues row not saved");
                }

                // 6. stock (guarded: never below zero); last_price kept in line with the Item Cost master
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE stock SET total_issued = total_issued + ?, balance_qty = balance_qty - ?, last_price = ?"
                        + " WHERE item_id = ? AND balance_qty >= ?")) {
                    ps.setBigDecimal(1, qty);
                    ps.setBigDecimal(2, qty);
                    ps.setBigDecimal(3, unitPrice);
                    ps.setInt(4, itemId);
                    ps.setBigDecimal(5, qty);
                    if (ps.executeUpdate() != 1) throw new StockEntryRules.EntryError("Stock changed while saving. Please try again.");
                }

                // 7. indent
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE indent SET Issued_status = 'Issued', Issued_qty = ?, POStatus = 'Completed',"
                        + " Indentnext = 'Issued' WHERE indent_id = ?")) {
                    ps.setBigDecimal(1, qty);
                    ps.setInt(2, indentId);
                    if (ps.executeUpdate() != 1) throw new SQLException("indent row not updated");
                }

                // 8. stock_ledger (trans_id = issue number), then running balances from the issue date
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO stock_ledger (item_id, trans_type, trans_id, qty, running_balance, remarks, trans_date)"
                        + " VALUES (?, 'ISSUE', ?, ?, 0, ?, ?)")) {
                    ps.setInt(1, itemId);
                    ps.setInt(2, Integer.parseInt(issueNo));
                    ps.setBigDecimal(3, qty);
                    ps.setString(4, "Issue for indent " + indentNo);
                    ps.setDate(5, java.sql.Date.valueOf(issueDate));
                    if (ps.executeUpdate() != 1) throw new SQLException("stock_ledger row not saved");
                }
                StockEntryRules.recalcRunningBalance(con, itemId, issueDate);

                con.commit();
                return new String[] {indentNo, issuedTo, itemName, plain(qty), issueNo};

            } catch (SQLException | StockEntryRules.EntryError | RuntimeException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(auto);
            }
        }
    }

    private static String plain(BigDecimal b) {
        return b == null ? "0" : b.stripTrailingZeros().toPlainString();
    }

    private static String trim(String s) {
        return s == null ? "" : s.trim();
    }
}
