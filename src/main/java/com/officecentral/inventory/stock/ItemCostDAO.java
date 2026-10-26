package com.officecentral.inventory.stock;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.officecentral.common.db.InventoryDB;

/**
 * Item Cost master: the cost of one unit of each item, INCLUDING GST.
 *
 * <ul>
 *   <li><b>PO</b> cost – taken automatically from the latest <i>approved</i> Purchase Order line of the item:
 *       {@code po_items.net_amount / po_items.qty} (net_amount = amount − discount + GST).
 *       PO-level service charges are not part of an item's cost.</li>
 *   <li><b>MANUAL</b> cost – entered by Finance / Global, allowed only while the item has no approved PO.</li>
 * </ul>
 * Every change is written to item_cost_history. Needs sql/item_cost.sql on every store database.
 * All values are bound parameters; only fixed SQL fragments are concatenated.
 */
public final class ItemCostDAO {

    private static final Logger LOG = Logger.getLogger(ItemCostDAO.class.getName());

    /** Allowed bases for a manual cost (stored in item_cost.rate_basis). */
    public static final Map<String, String> BASES;
    static {
        Map<String, String> m = new LinkedHashMap<>();
        m.put("BILL", "Purchase bill / invoice");
        m.put("LAST_PURCHASE", "Last purchase rate (old records)");
        m.put("MARKET", "Current market rate / quotation");
        m.put("COMMITTEE", "Committee valuation (old stock)");
        m.put("DONATION", "Donation / free supply");
        BASES = java.util.Collections.unmodifiableMap(m);
    }

    /** Largest value DECIMAL(12,2) can hold. */
    static final BigDecimal MAX_COST = new BigDecimal("9999999999.99");

    private ItemCostDAO() { }

    /** A problem the user can fix; shown on the page. */
    public static final class CostError extends Exception {
        private static final long serialVersionUID = 1L;
        CostError(String m) { super(m); }
    }

    /** Cost of an item from its latest approved PO line. */
    static final class PoCost {
        int itemId;
        int poItemId;
        String poNumber, poDate;
        BigDecimal unitCost, gstPercent;
    }

    // ------------------------------------------------------------------ price for issues / consumption

    /** The item has no cost in the Item Cost master; the issue / consumption must not be saved. */
    public static final class NoCostException extends SQLException {
        private static final long serialVersionUID = 1L;
        NoCostException(String m) { super(m); }
    }

    /** Cost of one unit (incl. GST) from the Item Cost master, or null when no cost is set. */
    public static BigDecimal unitCostOrNull(Connection con, int itemId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT unit_cost FROM item_cost WHERE item_id = ?")) {
            ps.setInt(1, itemId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getBigDecimal(1) : null;
            }
        }
    }

    /**
     * Cost of one unit (incl. GST) from the Item Cost master – the ONLY price used when stock is issued
     * or consumed. Never taken from the browser.
     * @throws NoCostException when the item has no cost yet (message names the item, safe to show)
     */
    public static BigDecimal requireCost(Connection con, int itemId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT im.Item_name, ic.unit_cost FROM item_master im"
                + " LEFT JOIN item_cost ic ON ic.item_id = im.Item_id WHERE im.Item_id = ?")) {
            ps.setInt(1, itemId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new SQLException("Item ID " + itemId + " was not found in Item Master.");
                BigDecimal cost = rs.getBigDecimal("unit_cost");
                if (cost == null) {
                    throw new NoCostException(rs.getString("Item_name") + " has no cost in the Item Cost master. "
                            + "Set it in System Masters > Item Cost (or approve its Purchase Order) and try again.");
                }
                return cost;
            }
        }
    }

    // ------------------------------------------------------------------ latest approved PO cost

    private static final String LATEST_PO =
            "SELECT x.item_id, x.po_item_id, x.po_number, x.po_date, x.qty, x.net_amount, x.gst_percent FROM ("
            + " SELECT pi.item_id, pi.po_item_id, pm.po_number, pm.PO_date AS po_date, pi.qty, pi.net_amount,"
            + "        pi.gst_percent,"
            + "        ROW_NUMBER() OVER (PARTITION BY pi.item_id ORDER BY pm.PO_id DESC, pi.po_item_id DESC) AS rn"
            + "   FROM po_items pi JOIN po_master pm ON pm.PO_id = pi.PO_id"
            + "  WHERE pi.item_id IS NOT NULL AND pi.qty > 0 AND pi.net_amount > 0"
            + "    AND TRIM(pm.Approval) = 'Approved'";

    /**
     * Latest approved PO cost per item.
     * @param onlyPoNumber  only items that appear in this PO (null = all items)
     * @param onlyItemId    only this item (null = all items)
     */
    static Map<Integer, PoCost> latestPoCosts(Connection con, String onlyPoNumber, Integer onlyItemId)
            throws SQLException {
        StringBuilder sql = new StringBuilder(LATEST_PO);
        List<Object> params = new ArrayList<>();
        if (onlyPoNumber != null) {
            sql.append(" AND pi.item_id IN (SELECT i2.item_id FROM po_items i2"
                    + " JOIN po_master m2 ON m2.PO_id = i2.PO_id WHERE m2.po_number = ?)");
            params.add(onlyPoNumber);
        }
        if (onlyItemId != null) {
            sql.append(" AND pi.item_id = ?");
            params.add(onlyItemId);
        }
        sql.append(") x WHERE x.rn = 1");

        Map<Integer, PoCost> out = new HashMap<>();
        try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    BigDecimal qty = rs.getBigDecimal("qty");
                    BigDecimal net = rs.getBigDecimal("net_amount");
                    if (qty == null || net == null || qty.signum() <= 0) continue;
                    PoCost c = new PoCost();
                    c.itemId = rs.getInt("item_id");
                    c.poItemId = rs.getInt("po_item_id");
                    c.poNumber = rs.getString("po_number");
                    c.poDate = rs.getString("po_date");
                    c.unitCost = net.divide(qty, 2, RoundingMode.HALF_UP);
                    c.gstPercent = rs.getBigDecimal("gst_percent");
                    out.put(c.itemId, c);
                }
            }
        }
        return out;
    }

    // ------------------------------------------------------------------ page data

    /**
     * Every item with its stored cost and its latest approved PO cost.
     * Row keys: id, name, category, subcategory, uom, cost, source, poNumber, poDate, gst, basis, reference, by, at,
     *           poCost (BigDecimal or null), pending (Boolean: PO cost differs from stored cost).
     */
    static List<Map<String, Object>> list(Connection con) throws SQLException {
        Map<Integer, PoCost> po = latestPoCosts(con, null, null);
        List<Map<String, Object>> rows = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT im.Item_id, im.Item_name, im.Category, im.Sub_Category, im.UOM, ic.unit_cost, ic.cost_source, ic.po_item_id,"
                + " ic.po_number, ic.po_date, ic.gst_percent, ic.rate_basis, ic.reference, ic.updated_by, ic.updated_at"
                + " FROM item_master im LEFT JOIN item_cost ic ON ic.item_id = im.Item_id"
                + " ORDER BY im.Category, im.Sub_Category, im.Item_name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int id = rs.getInt("Item_id");
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("id", id);
                m.put("name", rs.getString("Item_name"));
                m.put("category", rs.getString("Category"));
                m.put("subcategory", rs.getString("Sub_Category"));
                m.put("uom", rs.getString("UOM"));
                BigDecimal cost = rs.getBigDecimal("unit_cost");
                String source = rs.getString("cost_source");
                int poItemId = rs.getInt("po_item_id");
                m.put("cost", cost);
                m.put("source", source);
                m.put("poNumber", rs.getString("po_number"));
                m.put("poDate", rs.getString("po_date"));
                m.put("gst", rs.getBigDecimal("gst_percent"));
                m.put("basis", rs.getString("rate_basis"));
                m.put("reference", rs.getString("reference"));
                m.put("by", rs.getString("updated_by"));
                Timestamp at = rs.getTimestamp("updated_at");
                m.put("at", at == null ? null : at.toLocalDateTime());
                PoCost pc = po.get(id);
                m.put("poCost", pc == null ? null : pc.unitCost);
                m.put("pending", pc != null && differs(cost, source, poItemId, pc));
                rows.add(m);
            }
        }
        return rows;
    }

    /** Last changes for the audit card. */
    static List<Map<String, Object>> recentHistory(Connection con, int limit) throws SQLException {
        List<Map<String, Object>> rows = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT h.item_id, im.Item_name, im.UOM, h.old_cost, h.new_cost, h.cost_source, h.po_number,"
                + " h.rate_basis, h.reference, h.changed_by, h.changed_at FROM item_cost_history h"
                + " JOIN item_master im ON im.Item_id = h.item_id ORDER BY h.history_id DESC LIMIT ?")) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("item", rs.getString("Item_name"));
                    m.put("uom", rs.getString("UOM"));
                    m.put("oldCost", rs.getBigDecimal("old_cost"));
                    m.put("newCost", rs.getBigDecimal("new_cost"));
                    m.put("source", rs.getString("cost_source"));
                    m.put("poNumber", rs.getString("po_number"));
                    m.put("basis", rs.getString("rate_basis"));
                    m.put("reference", rs.getString("reference"));
                    m.put("by", rs.getString("changed_by"));
                    Timestamp at = rs.getTimestamp("changed_at");
                    m.put("at", at == null ? null : at.toLocalDateTime());
                    rows.add(m);
                }
            }
        }
        return rows;
    }

    private static boolean differs(BigDecimal cost, String source, int poItemId, PoCost pc) {
        return cost == null || !"PO".equals(source) || poItemId != pc.poItemId || cost.compareTo(pc.unitCost) != 0;
    }

    // ------------------------------------------------------------------ automatic: from POs

    /**
     * Copies the latest approved PO cost into item_cost wherever it is missing or different.
     * A PO cost replaces a manual cost (the manual cost stays in the history).
     * @param poNumber only the items of this PO (null = all items)
     * @return number of items whose cost was written
     */
    static int syncFromPO(Connection con, String poNumber, String user) throws SQLException {
        boolean auto = con.getAutoCommit();
        con.setAutoCommit(false);
        try {
            Map<Integer, PoCost> po = latestPoCosts(con, poNumber, null);
            int written = 0;
            try (PreparedStatement lock = con.prepareStatement(
                    "SELECT unit_cost, cost_source, po_item_id FROM item_cost WHERE item_id = ? FOR UPDATE")) {
                for (PoCost pc : po.values()) {
                    BigDecimal oldCost = null;
                    String oldSource = null;
                    int oldPoItem = 0;
                    lock.setInt(1, pc.itemId);
                    try (ResultSet rs = lock.executeQuery()) {
                        if (rs.next()) {
                            oldCost = rs.getBigDecimal("unit_cost");
                            oldSource = rs.getString("cost_source");
                            oldPoItem = rs.getInt("po_item_id");
                        }
                    }
                    if (oldCost != null && !differs(oldCost, oldSource, oldPoItem, pc)) continue;
                    write(con, pc.itemId, oldCost, pc.unitCost, "PO", pc.poItemId, pc.poNumber, pc.poDate,
                            pc.gstPercent, null, null, user);
                    written++;
                }
            }
            con.commit();
            return written;
        } catch (SQLException | RuntimeException e) {
            con.rollback();
            throw e;
        } finally {
            con.setAutoCommit(auto);
        }
    }

    /**
     * Called automatically every time a PO is approved: copies the cost (incl. GST) of that PO's items into the
     * Item Cost master. Never throws, so the approval itself is never affected. If it fails, the next opening of
     * the Item Cost page applies the missed costs automatically.
     * @return number of items whose cost changed, or -1 when the update failed
     */
    public static int afterPoApproved(String branch, String poNumber, String user) {
        if (poNumber == null || poNumber.trim().isEmpty()) return 0;
        try (Connection con = InventoryDB.getConnection(branch)) {
            int n = syncFromPO(con, poNumber.trim(), user == null ? "system" : user);
            LOG.info("[item-cost] PO " + poNumber + " approved: cost updated for " + n + " item(s) in " + branch);
            return n;
        } catch (SQLException | RuntimeException e) {
            LOG.log(Level.WARNING, "[item-cost] Cost update after approving PO " + poNumber + " failed in " + branch
                    + " (run sql/item_cost.sql if the table is missing)", e);
            return -1;
        }
    }

    // ------------------------------------------------------------------ manual cost

    /**
     * Saves a manual cost. Allowed only when the item has no approved PO cost.
     * Cost must be &gt; 0, except for DONATION where 0 is allowed.
     */
    static String saveManual(Connection con, int itemId, BigDecimal cost, String basis, String reference, String user)
            throws SQLException, CostError {
        if (!BASES.containsKey(basis)) throw new CostError("Select how the cost was decided.");
        if (cost == null || cost.signum() < 0 || cost.scale() > 2 || cost.compareTo(MAX_COST) > 0) {
            throw new CostError("Enter a valid cost (up to 2 decimals).");
        }
        if (cost.signum() == 0 && !"DONATION".equals(basis)) {
            throw new CostError("Cost must be more than ₹0. A ₹0 cost is allowed only for Donation / free supply.");
        }
        if (reference == null || reference.isEmpty()) {
            throw new CostError("Enter a reference (bill number, quotation or approval note).");
        }

        boolean auto = con.getAutoCommit();
        con.setAutoCommit(false);
        try {
            String name;
            try (PreparedStatement ps = con.prepareStatement("SELECT Item_name FROM item_master WHERE Item_id = ?")) {
                ps.setInt(1, itemId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new CostError("Item not found. Please reload the page.");
                    name = rs.getString(1);
                }
            }
            BigDecimal oldCost = null;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT unit_cost FROM item_cost WHERE item_id = ? FOR UPDATE")) {
                ps.setInt(1, itemId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) oldCost = rs.getBigDecimal(1);
                }
            }
            if (!latestPoCosts(con, null, itemId).isEmpty()) {
                throw new CostError(name + " has an approved Purchase Order, so its cost comes from the PO and "
                        + "cannot be entered manually. It is updated automatically from the PO.");
            }
            write(con, itemId, oldCost, cost, "MANUAL", null, null, null, null, basis, reference, user);
            con.commit();
            return name;
        } catch (SQLException | CostError | RuntimeException e) {
            con.rollback();
            throw e;
        } finally {
            con.setAutoCommit(auto);
        }
    }

    // ------------------------------------------------------------------ write + history

    private static void write(Connection con, int itemId, BigDecimal oldCost, BigDecimal newCost, String source,
                              Integer poItemId, String poNumber, String poDate, BigDecimal gst,
                              String basis, String reference, String user) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO item_cost (item_id, unit_cost, cost_source, po_item_id, po_number, po_date, gst_percent,"
                + " rate_basis, reference, updated_by) VALUES (?,?,?,?,?,?,?,?,?,?)"
                + " ON DUPLICATE KEY UPDATE unit_cost = VALUES(unit_cost), cost_source = VALUES(cost_source),"
                + " po_item_id = VALUES(po_item_id), po_number = VALUES(po_number), po_date = VALUES(po_date),"
                + " gst_percent = VALUES(gst_percent), rate_basis = VALUES(rate_basis), reference = VALUES(reference),"
                + " updated_by = VALUES(updated_by), updated_at = CURRENT_TIMESTAMP")) {
            ps.setInt(1, itemId);
            ps.setBigDecimal(2, newCost);
            ps.setString(3, source);
            if (poItemId == null) ps.setNull(4, Types.INTEGER); else ps.setInt(4, poItemId);
            ps.setString(5, cut(poNumber, 50));
            ps.setString(6, cut(poDate, 50));
            ps.setBigDecimal(7, gst);
            ps.setString(8, basis);
            ps.setString(9, cut(reference, 255));
            ps.setString(10, cut(user, 100));
            ps.executeUpdate();
        }
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO item_cost_history (item_id, old_cost, new_cost, cost_source, po_number, rate_basis,"
                + " reference, changed_by) VALUES (?,?,?,?,?,?,?,?)")) {
            ps.setInt(1, itemId);
            ps.setBigDecimal(2, oldCost);
            ps.setBigDecimal(3, newCost);
            ps.setString(4, source);
            ps.setString(5, cut(poNumber, 50));
            ps.setString(6, basis);
            ps.setString(7, cut(reference, 255));
            ps.setString(8, cut(user, 100));
            ps.executeUpdate();
        }
    }

    private static String cut(String s, int max) {
        if (s == null) return null;
        s = s.trim();
        return s.length() > max ? s.substring(0, max) : s;
    }
}
