package com.officecentral.inventory.purchase;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.officecentral.common.db.InventoryDB;
import com.officecentral.common.notification.NotificationService;
import com.officecentral.inventory.model.PO;
import com.officecentral.inventory.model.POItems;
import com.officecentral.inventory.stock.ItemCostDAO;

/**
 * Purchase Order list with Approve / Delete.
 *
 * GET  /approve-po  → list only. It never changes data (old ?Approve_id= / ?delete_id= links are ignored).
 * POST /approve-po  → action=approve | delete, with the page's CSRF token. Checked on the server:
 *     approve : Global role only; only a PO that is not yet approved.
 *     delete  : Global role, Finance or Store department (same users who see this page in the menu);
 *               only a PO that is NOT approved and has NO goods received (GRN) against it.
 * Every approve / delete is written to the server log with user, store and PO number.
 */
@WebServlet(urlPatterns = {"/approve-po", "/POListServlet"})   // second one = old address, kept so old links still work
public class ApprovePOServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(ApprovePOServlet.class.getName());

    static final String CSRF = "approvePoCsrf";
    static final String FLASH = "approvePoMessage";
    private static final SecureRandom RANDOM = new SecureRandom();

    static boolean canApprove(HttpSession s) {
        return "Global".equalsIgnoreCase(trim((String) s.getAttribute("role")));
    }

    static boolean canDelete(HttpSession s) {
        String dept = trim((String) s.getAttribute("department"));
        return canApprove(s) || "Finance".equalsIgnoreCase(dept) || "Store".equalsIgnoreCase(dept);
    }

    // ------------------------------------------------------------------ GET: list only

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        if (!canDelete(sess)) {   // canDelete = everyone allowed to see this page
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Purchase Orders are available only to Global, Finance and Store users.");
            return;
        }
        // Old links (?Approve_id= / ?delete_id=) no longer change anything
        if (request.getParameter("Approve_id") != null || request.getParameter("delete_id") != null) {
            sess.setAttribute(FLASH, "Please use the Approve / Delete buttons on this page.");
            response.sendRedirect("approve-po");
            return;
        }

        String branch = (String) sess.getAttribute("branch");
        List<PO> poList = new ArrayList<>();

        try (Connection con = InventoryDB.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(
                     "SELECT * FROM po_master WHERE po_status IN ('Open', 'Partially Received') ORDER BY po_date DESC");
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                PO po = new PO();
                int poId = rs.getInt("PO_id");

                po.setPoNumber(rs.getString("po_number"));
                po.setPoDate(rs.getString("po_date"));
                po.setVendorName(rs.getString("vendor_name"));
                po.setTotalAmount(rs.getDouble("total_amount"));
                po.setApproval(rs.getString("Approval"));

                List<POItems> items = new ArrayList<>();
                try (PreparedStatement ps2 = con.prepareStatement(
                        "SELECT i.*, s.balance_qty, " +
                        "COALESCE((SELECT SUM(g.qty_received) FROM grn_items g WHERE g.po_item_id = i.po_item_id), 0) AS received_qty " +
                        "FROM po_items i LEFT JOIN stock s ON i.item_id = s.item_id WHERE i.PO_id = ?")) {
                    ps2.setInt(1, poId);
                    try (ResultSet rs2 = ps2.executeQuery()) {
                        while (rs2.next()) {
                            POItems item = new POItems();
                            item.setId(rs2.getInt("po_item_id"));
                            item.setItemId(rs2.getInt("item_id"));
                            item.setIndentNo(rs2.getString("po_no"));
                            item.setItemName(rs2.getString("description"));
                            item.setQty(rs2.getDouble("qty"));
                            item.setReceivedQty(rs2.getDouble("received_qty"));
                            item.setRate(rs2.getDouble("rate"));
                            item.setDiscountPercent(rs2.getDouble("discount_percent"));
                            item.setGstPercent(rs2.getDouble("gst_percent"));
                            item.setBalanceQty(rs2.getDouble("balance_qty"));
                            items.add(item);
                        }
                    }
                }
                po.setItems(items);
                poList.add(po);
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "PO list load failed", e);
            request.setAttribute("poMessage", "Could not load Purchase Orders. Please try again.");
        }

        Object flash = sess.getAttribute(FLASH);
        if (flash != null) {
            sess.removeAttribute(FLASH);
            request.setAttribute("poMessage", flash);
        }
        request.setAttribute("poList", poList);
        request.setAttribute("poCsrf", token(sess));
        request.setAttribute("canApprove", canApprove(sess));
        request.setAttribute("canDelete", canDelete(sess));
        RequestDispatcher rd = request.getRequestDispatcher("/WEB-INF/views/inventory/purchase/POlist.jsp");
        rd.forward(request, response);
    }

    // ------------------------------------------------------------------ POST: approve / delete

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        String expected = (String) sess.getAttribute(CSRF);
        String given = request.getParameter("csrf");
        if (expected == null || given == null
                || !MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), given.getBytes(StandardCharsets.UTF_8))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Form expired. Please reload the page and try again.");
            return;
        }

        String branch = (String) sess.getAttribute("branch");
        String user = String.valueOf(sess.getAttribute("username"));
        String action = trim(request.getParameter("action"));
        String poNumber = trim(request.getParameter("poNumber"));
        if (poNumber.isEmpty() || poNumber.length() > 50) {
            sess.setAttribute(FLASH, "Select a Purchase Order.");
            response.sendRedirect("approve-po");
            return;
        }

        String message;
        if ("approve".equals(action)) {
            if (!canApprove(sess)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Only Global users can approve Purchase Orders.");
                return;
            }
            message = approve(branch, poNumber, user);
        } else if ("delete".equals(action)) {
            if (!canDelete(sess)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You are not allowed to delete Purchase Orders.");
                return;
            }
            message = delete(branch, poNumber, user);
        } else {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Unknown action.");
            return;
        }
        sess.setAttribute(FLASH, message);
        response.sendRedirect("approve-po");
    }

    private String approve(String branch, String poNumber, String user) {
        int changed;
        try (Connection con = InventoryDB.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(
                     "UPDATE po_master SET Approval = 'Approved' WHERE po_number = ?"
                     + " AND (Approval IS NULL OR TRIM(Approval) <> 'Approved')")) {
            ps.setString(1, poNumber);
            changed = ps.executeUpdate();
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "PO approve failed: " + poNumber, e);
            return "PO " + poNumber + " was not approved. Please try again.";
        }
        if (changed == 0) return "PO " + poNumber + " is already approved or no longer exists.";

        LOG.info("[PO] APPROVED " + poNumber + " by " + user + " in " + branch);
        try {
            NotificationService.purchaseOrderApproved(branch, poNumber);
        } catch (RuntimeException e) {
            LOG.log(Level.WARNING, "PO approval notification failed", e);
        }
        // Item Cost master: take the cost (incl. GST) of this PO's items – automatically, every approval.
        int costs = ItemCostDAO.afterPoApproved(branch, poNumber, user);
        if (costs < 0) {
            return "PO " + poNumber + " approved. Item Cost could not be updated now; it will be updated "
                    + "automatically the next time the Item Cost page is opened.";
        }
        return "PO " + poNumber + " approved. Item Cost updated for " + costs + " item(s).";
    }

    private String delete(String branch, String poNumber, String user) {
        try (Connection con = InventoryDB.getConnection(branch)) {
            boolean auto = con.getAutoCommit();
            con.setAutoCommit(false);
            try {
                String approval;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT Approval FROM po_master WHERE po_number = ? FOR UPDATE")) {
                    ps.setString(1, poNumber);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            con.rollback();
                            return "PO " + poNumber + " no longer exists.";
                        }
                        approval = trim(rs.getString(1));
                    }
                }
                if ("Approved".equalsIgnoreCase(approval)) {
                    con.rollback();
                    return "PO " + poNumber + " is approved and cannot be deleted.";
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT COUNT(*) FROM grn_items g JOIN po_items i ON i.po_item_id = g.po_item_id"
                        + " WHERE i.po_no = ?")) {
                    ps.setString(1, poNumber);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0) {
                            con.rollback();
                            return "PO " + poNumber + " has goods received (GRN) and cannot be deleted.";
                        }
                    }
                }
                try (PreparedStatement ps1 = con.prepareStatement("DELETE FROM po_items WHERE po_no = ?");
                     PreparedStatement ps2 = con.prepareStatement("DELETE FROM po_master WHERE po_number = ?")) {
                    ps1.setString(1, poNumber);
                    ps1.executeUpdate();
                    ps2.setString(1, poNumber);
                    ps2.executeUpdate();
                }
                con.commit();
            } catch (SQLException | RuntimeException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(auto);
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "PO delete failed: " + poNumber, e);
            return "PO " + poNumber + " was not deleted. Please try again.";
        }
        LOG.info("[PO] DELETED " + poNumber + " by " + user + " in " + branch);
        return "PO " + poNumber + " deleted.";
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

    private static String trim(String s) {
        return s == null ? "" : s.trim();
    }
}
