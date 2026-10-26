package com.officecentral.inventory.stock;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
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

/**
 * Item Cost master – Finance department and Global role only (same rule as Wastage / System Masters menu).
 *
 * GET  /item-cost                 → all items of the selected store with their cost (incl. GST). Any approved PO
 *                                    cost that is not in the master yet is applied automatically first (normally
 *                                    this is already done at the moment the PO is approved).
 * POST /item-cost  action=sync    → same update on request (kept for old bookmarks; no button on the page)
 * POST /item-cost  action=manual  → save a manual cost for an item that has no approved PO
 *
 * Needs sql/item_cost.sql to be run on every store database.
 */
@WebServlet("/item-cost")
public class ItemCostServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(ItemCostServlet.class.getName());

    static final String VIEW = "/WEB-INF/views/inventory/stock/item_cost.jsp";
    static final String CSRF = "itemCostCsrf";
    private static final SecureRandom RANDOM = new SecureRandom();

    /** Logged-in Finance/Global user, else redirect / 403. Returns null when the request was answered. */
    static HttpSession guard(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return null;
        }
        if (!StockLedgerDAO.canChooseYear((String) s.getAttribute("role"), (String) s.getAttribute("department"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Item Cost is available only to Finance and Global users.");
            return null;
        }
        return s;
    }

    // ------------------------------------------------------------------ GET

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession s = guard(req, resp);
        if (s == null) return;
        // Automatic: bring every item up to date with its latest approved PO (no manual button)
        String branch = (String) s.getAttribute("branch");
        try (Connection con = InventoryDB.getConnection(branch)) {
            int n = ItemCostDAO.syncFromPO(con, null, s.getAttribute("username") + " (auto)");
            if (n > 0) req.setAttribute("autoSynced", n);
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Automatic item cost update failed", e);   // page still opens with stored costs
        }
        show(req, resp, s, null, null);
    }

    private void show(HttpServletRequest req, HttpServletResponse resp, HttpSession s,
                      String error, Map<String, Object> form) throws ServletException, IOException {
        String branch = (String) s.getAttribute("branch");
        List<Map<String, Object>> items = new ArrayList<>();
        List<Map<String, Object>> history = new ArrayList<>();
        try (Connection con = InventoryDB.getConnection(branch)) {
            items = ItemCostDAO.list(con);
            history = ItemCostDAO.recentHistory(con, 25);
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Item Cost page load failed", e);
            error = "Could not load item costs. If this is the first use, run sql/item_cost.sql on this store's database.";
        }
        int withPo = 0, manual = 0, none = 0, pending = 0;
        for (Map<String, Object> m : items) {
            if (m.get("cost") == null) none++;
            else if ("PO".equals(m.get("source"))) withPo++;
            else manual++;
            if (Boolean.TRUE.equals(m.get("pending"))) pending++;
        }
        req.setAttribute("items", items);
        req.setAttribute("history", history);
        req.setAttribute("countAll", items.size());
        req.setAttribute("countPo", withPo);
        req.setAttribute("countManual", manual);
        req.setAttribute("countNone", none);
        req.setAttribute("countPending", pending);
        req.setAttribute("bases", ItemCostDAO.BASES);
        req.setAttribute("store", branch);
        req.setAttribute("csrf", token(s));
        req.setAttribute("error", error);
        req.setAttribute("form", form);
        req.setAttribute("saved", req.getParameter("saved"));
        req.setAttribute("synced", req.getParameter("synced"));
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

        String branch = (String) s.getAttribute("branch");
        String user = String.valueOf(s.getAttribute("username"));
        String action = trim(req.getParameter("action"));

        if ("sync".equals(action)) {
            try (Connection con = InventoryDB.getConnection(branch)) {
                int n = ItemCostDAO.syncFromPO(con, null, user);
                resp.sendRedirect(req.getContextPath() + "/item-cost?synced=" + n);
            } catch (SQLException e) {
                LOG.log(Level.SEVERE, "Item cost sync failed", e);
                show(req, resp, s, "Could not update costs from POs. Nothing was changed. Please try again.", null);
            }
            return;
        }

        if (!"manual".equals(action)) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Unknown action.");
            return;
        }

        Map<String, Object> form = new LinkedHashMap<>();
        form.put("itemId", trim(req.getParameter("itemId")));
        form.put("cost", trim(req.getParameter("cost")));
        form.put("basis", trim(req.getParameter("basis")));
        form.put("reference", trim(req.getParameter("reference")));

        int itemId;
        try {
            itemId = Integer.parseInt((String) form.get("itemId"));
            if (itemId <= 0) throw new NumberFormatException();
        } catch (NumberFormatException e) {
            show(req, resp, s, "Select an item from the list.", form);
            return;
        }
        BigDecimal cost;
        try {
            cost = new BigDecimal((String) form.get("cost"));
        } catch (NumberFormatException e) {
            show(req, resp, s, "Enter a valid cost per unit.", form);
            return;
        }
        String reference = (String) form.get("reference");
        if (reference.length() > 255) reference = reference.substring(0, 255);

        try (Connection con = InventoryDB.getConnection(branch)) {
            ItemCostDAO.saveManual(con, itemId, cost, (String) form.get("basis"), reference, user);
            resp.sendRedirect(req.getContextPath() + "/item-cost?saved=" + itemId);
        } catch (ItemCostDAO.CostError e) {
            show(req, resp, s, e.getMessage(), form);
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Manual item cost save failed", e);
            show(req, resp, s, "Could not save the cost. Nothing was changed. Please try again.", form);
        }
    }

    static String trim(String s) {
        return s == null ? "" : s.trim();
    }
}
