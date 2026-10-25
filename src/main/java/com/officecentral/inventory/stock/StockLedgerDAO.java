package com.officecentral.inventory.stock;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.officecentral.common.db.InventoryDB;

/**
 * Stock ledger data from the stock_ledger table, shared by the website
 * (Stock Ledger Report pop-up, /stock-ledger-detail) and the mobile app (/api/mobile/stock/ledger...),
 * so both always show the same figures.
 *
 * Date rules are the same as stockReport.jsp:
 *   Opening  = RECEIPT - ISSUE with trans_date &lt; from
 *   Receipts = RECEIPT with trans_date BETWEEN from AND to
 *   Issues   = ISSUE   with trans_date BETWEEN from AND to
 * from/to == null means all dates.
 *
 * Read-only. All values are bound parameters; only fixed SQL fragments are concatenated.
 */
public final class StockLedgerDAO {

    public static final int MAX_DETAIL_ROWS = 5000;
    public static final int MAX_SUMMARY_ROWS = 3000;

    private static final DateTimeFormatter IN_DATE = DateTimeFormatter.ofPattern("dd-MM-yyyy");
    private static final LocalDate MIN = LocalDate.of(1900, 1, 1);
    private static final LocalDate MAX = LocalDate.of(9999, 12, 31);

    /** Input problem that is safe to show to the user. */
    public static class BadRequest extends IllegalArgumentException {
        private static final long serialVersionUID = 1L;
        public BadRequest(String m) { super(m); }
    }

    /** The item does not exist in this store. */
    public static class NotFound extends IllegalArgumentException {
        private static final long serialVersionUID = 1L;
        public NotFound(String m) { super(m); }
    }

    /**
     * Parses optional yyyy-MM-dd dates. Both blank = all dates (returns null).
     * @return {from, to} or null for all dates
     */
    public static LocalDate[] parseRange(String fromParam, String toParam) {
        boolean noFrom = fromParam == null || fromParam.trim().isEmpty();
        boolean noTo = toParam == null || toParam.trim().isEmpty();
        if (noFrom && noTo) return null;
        if (noFrom || noTo) throw new BadRequest("Select both From and To dates.");
        LocalDate from, to;
        try {
            from = LocalDate.parse(fromParam.trim());
            to = LocalDate.parse(toParam.trim());
        } catch (RuntimeException e) {
            throw new BadRequest("Invalid date.");
        }
        if (from.isAfter(to)) throw new BadRequest("From Date cannot be after To Date.");
        return new LocalDate[] {from, to};
    }

    // ------------------------------------------------------------------ item-wise summary

    /**
     * Item-wise Opening / Receipts / Issues / Closing for a period (Stock Ledger Report).
     *
     * @param range      {from,to} or null for all dates
     * @param search     part of item name (optional)
     * @param category   exact category (optional)
     * @param movedOnly  true = only items with a non-zero opening, receipt or issue
     */
    public Map<String, Object> summary(String branch, LocalDate[] range, String search, String category,
                                       boolean movedOnly) throws SQLException {
        LocalDate from = range == null ? MIN : range[0];
        LocalDate to = range == null ? MAX : range[1];

        StringBuilder sql = new StringBuilder(
            "SELECT * FROM ( " +
            " SELECT im.Item_id, im.Item_name, im.Category, im.Sub_Category, im.UOM, " +
            "  COALESCE(s.last_price,0) AS last_price, " +
            "  COALESCE((SELECT SUM(CASE WHEN sl.trans_type='RECEIPT' THEN sl.qty " +
            "                           WHEN sl.trans_type='ISSUE' THEN -sl.qty ELSE 0 END) " +
            "            FROM stock_ledger sl WHERE sl.item_id = im.Item_id AND sl.trans_date < ?),0) AS opening_balance, " +
            "  COALESCE((SELECT SUM(sl.qty) FROM stock_ledger sl WHERE sl.item_id = im.Item_id " +
            "            AND sl.trans_type='RECEIPT' AND sl.trans_date BETWEEN ? AND ?),0) AS receipts, " +
            "  COALESCE((SELECT SUM(sl.qty) FROM stock_ledger sl WHERE sl.item_id = im.Item_id " +
            "            AND sl.trans_type='ISSUE' AND sl.trans_date BETWEEN ? AND ?),0) AS issues " +
            " FROM item_master im LEFT JOIN stock s ON im.Item_id = s.item_id " +
            " WHERE 1=1 ");
        List<String> params = new ArrayList<>();
        params.add(from.toString());
        params.add(from.toString());
        params.add(to.toString());
        params.add(from.toString());
        params.add(to.toString());

        String term = search == null ? "" : search.trim();
        if (term.length() > 60) term = term.substring(0, 60);
        if (!term.isEmpty()) {
            sql.append(" AND im.Item_name LIKE ? ");
            params.add("%" + term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%");
        }
        String cat = category == null ? "" : category.trim();
        if (cat.length() > 100) cat = cat.substring(0, 100);
        if (!cat.isEmpty()) {
            sql.append(" AND im.Category = ? ");
            params.add(cat);
        }
        sql.append(") t ");
        if (movedOnly) sql.append("WHERE (t.opening_balance <> 0 OR t.receipts <> 0 OR t.issues <> 0) ");
        sql.append("ORDER BY t.Category, t.Sub_Category, t.Item_name LIMIT ").append(MAX_SUMMARY_ROWS + 1);

        List<Map<String, Object>> items = new ArrayList<>();
        List<String> categories = new ArrayList<>();
        double totOpen = 0, totIn = 0, totOut = 0, totClose = 0, totValue = 0;
        boolean truncated = false;

        try (Connection con = InventoryDB.getConnection(branch)) {
            try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
                for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        if (items.size() == MAX_SUMMARY_ROWS) { truncated = true; break; }
                        double opening = rs.getDouble("opening_balance");
                        double receipts = rs.getDouble("receipts");
                        double issues = rs.getDouble("issues");
                        double closing = opening + receipts - issues;
                        double rate = rs.getDouble("last_price");
                        double value = round2(closing * rate);
                        totOpen += opening; totIn += receipts; totOut += issues; totClose += closing; totValue += value;

                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("itemId", rs.getInt("Item_id"));
                        m.put("name", rs.getString("Item_name"));
                        m.put("category", rs.getString("Category"));
                        m.put("subCategory", rs.getString("Sub_Category"));
                        m.put("unit", rs.getString("UOM"));
                        m.put("opening", opening);
                        m.put("receipts", receipts);
                        m.put("issues", issues);
                        m.put("closing", closing);
                        m.put("rate", rate);
                        m.put("value", value);
                        items.add(m);
                    }
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT DISTINCT Category FROM item_master WHERE Category IS NOT NULL AND Category<>'' ORDER BY Category");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) categories.add(rs.getString(1));
            }
        }

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("allDates", range == null);
        res.put("fromDate", range == null ? "" : from.format(IN_DATE));
        res.put("toDate", range == null ? "" : to.format(IN_DATE));
        res.put("items", items);
        res.put("categories", categories);
        res.put("totalOpening", round3(totOpen));
        res.put("totalReceipts", round3(totIn));
        res.put("totalIssues", round3(totOut));
        res.put("totalClosing", round3(totClose));
        res.put("totalValue", round2(totValue));
        res.put("truncated", truncated);
        return res;
    }

    // ------------------------------------------------------------------ one item's transactions

    /**
     * Transactions behind one figure.
     *
     * @param type OPENING (before from) | RECEIPT | ISSUE | ALL (period, with opening + running balance)
     * @param range {from,to} or null for all dates
     */
    public Map<String, Object> detail(String branch, int itemId, String type, LocalDate[] range) throws SQLException {
        if (itemId <= 0) throw new BadRequest("Invalid item.");
        if (type == null || !(type.equals("OPENING") || type.equals("RECEIPT")
                || type.equals("ISSUE") || type.equals("ALL"))) {
            throw new BadRequest("Invalid ledger type.");
        }
        boolean allDates = range == null;
        LocalDate from = allDates ? MIN : range[0];
        LocalDate to = allDates ? MAX : range[1];

        StringBuilder sql = new StringBuilder(
            "SELECT sl.ledger_id, sl.trans_date, sl.trans_type, sl.trans_id, sl.qty, sl.remarks, " +
            " CASE WHEN sl.trans_type='RECEIPT' THEN " +
            "   (SELECT gm.grn_no FROM grn_master gm WHERE CAST(gm.grn_id AS CHAR) = sl.trans_id LIMIT 1) " +
            "   ELSE sl.trans_id END AS ref_no, " +
            " CASE WHEN sl.trans_type='RECEIPT' THEN " +
            "   (SELECT gm.vendor_name FROM grn_master gm WHERE CAST(gm.grn_id AS CHAR) = sl.trans_id LIMIT 1) " +
            "   ELSE (SELECT CONCAT_WS(' / ', NULLIF(si.department,''), NULLIF(si.issued_to,'')) " +
            "         FROM stock_issues si WHERE si.issueno = sl.trans_id AND si.item_id = sl.item_id LIMIT 1) " +
            "   END AS party " +
            "FROM stock_ledger sl " +
            "WHERE sl.item_id = ? AND sl.trans_type IN ('RECEIPT','ISSUE') ");
        switch (type) {
            case "OPENING": sql.append("AND sl.trans_date < ? "); break;
            case "RECEIPT": sql.append("AND sl.trans_type='RECEIPT' AND sl.trans_date BETWEEN ? AND ? "); break;
            case "ISSUE":   sql.append("AND sl.trans_type='ISSUE' AND sl.trans_date BETWEEN ? AND ? "); break;
            default:        sql.append("AND sl.trans_date BETWEEN ? AND ? "); break; // ALL
        }
        sql.append("ORDER BY sl.trans_date, sl.ledger_id LIMIT ").append(MAX_DETAIL_ROWS + 1);

        Map<String, Object> result = new LinkedHashMap<>();
        List<Map<String, Object>> rows = new ArrayList<>();

        try (Connection con = InventoryDB.getConnection(branch)) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT Item_name, Category, Sub_Category, UOM FROM item_master WHERE Item_id = ?")) {
                ps.setInt(1, itemId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new NotFound("Item not found.");
                    result.put("itemId", itemId);
                    result.put("itemName", rs.getString("Item_name"));
                    result.put("category", rs.getString("Category"));
                    result.put("subCategory", rs.getString("Sub_Category"));
                    result.put("unit", rs.getString("UOM"));
                }
            }

            double opening = 0;
            if (type.equals("ALL") && !allDates) {
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT COALESCE(SUM(CASE WHEN trans_type='RECEIPT' THEN qty " +
                        "WHEN trans_type='ISSUE' THEN -qty ELSE 0 END),0) " +
                        "FROM stock_ledger WHERE item_id = ? AND trans_date < ?")) {
                    ps.setInt(1, itemId);
                    ps.setString(2, from.toString());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) opening = rs.getDouble(1);
                    }
                }
            }

            try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
                ps.setInt(1, itemId);
                ps.setString(2, from.toString());
                if (!type.equals("OPENING")) ps.setString(3, to.toString());

                double balance = opening, totalIn = 0, totalOut = 0;
                boolean truncated = false;
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        if (rows.size() == MAX_DETAIL_ROWS) { truncated = true; break; }
                        boolean in = "RECEIPT".equals(rs.getString("trans_type"));
                        double qty = rs.getDouble("qty");
                        if (in) { totalIn += qty; balance += qty; } else { totalOut += qty; balance -= qty; }

                        java.sql.Date d = rs.getDate("trans_date");
                        Map<String, Object> r = new LinkedHashMap<>();
                        r.put("date", d == null ? "" : d.toLocalDate().format(IN_DATE));
                        r.put("type", in ? "Receipt" : "Issue");
                        r.put("refNo", nz(rs.getString("ref_no")));
                        r.put("party", nz(rs.getString("party")));
                        r.put("remarks", nz(rs.getString("remarks")));
                        r.put("inQty", in ? qty : 0);
                        r.put("outQty", in ? 0 : qty);
                        r.put("balance", round3(balance));
                        rows.add(r);
                    }
                }
                result.put("opening", round3(opening));
                result.put("totalIn", round3(totalIn));
                result.put("totalOut", round3(totalOut));
                result.put("closing", round3(balance));
                result.put("truncated", truncated);
            }
        }

        result.put("type", type);
        result.put("allDates", allDates);
        result.put("fromDate", allDates ? "" : from.format(IN_DATE));
        result.put("toDate", allDates ? "" : to.format(IN_DATE));
        result.put("rows", rows);
        return result;
    }

    private static String nz(String s) {
        return s == null ? "" : s;
    }

    private static double round2(double v) {
        return Math.round(v * 100d) / 100d;
    }

    private static double round3(double v) {
        return Math.round(v * 1000d) / 1000d;
    }
}
