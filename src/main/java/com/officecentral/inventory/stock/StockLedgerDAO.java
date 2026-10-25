package com.officecentral.inventory.stock;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Locale;
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
 * Ledger is limited to ONE FINANCIAL / ACADEMIC YEAR (1 April .. 31 March; the current year ends today).
 * Normal users: current year only. Global role or Finance department: may choose a previous year.
 * Earlier transactions are never listed; they only make up the opening balance as on the From date.
 * The limit is applied here on the server, so neither the website nor the app can bypass it.
 *
 * Read-only. All values are bound parameters; only fixed SQL fragments are concatenated.
 */
public final class StockLedgerDAO {

    public static final int MAX_DETAIL_ROWS = 5000;
    public static final int MAX_SUMMARY_ROWS = 3000;

    private static final DateTimeFormatter IN_DATE = DateTimeFormatter.ofPattern("dd-MM-yyyy");
    private static final ZoneId IST = ZoneId.of("Asia/Kolkata");

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

    /** Today in India. */
    public static LocalDate today() {
        return LocalDate.now(IST);
    }

    /** How many earlier financial years Global / Finance users may open. */
    public static final int PAST_YEARS = 5;

    /** Start year of the current financial year (2026 for 2026-27). */
    public static int currentFy() {
        LocalDate t = today();
        return t.getMonthValue() >= 4 ? t.getYear() : t.getYear() - 1;
    }

    /** 1 April of the current academic / financial year. */
    public static LocalDate yearStart() {
        return LocalDate.of(currentFy(), 4, 1);
    }

    /** 1 April of financial year fy. */
    public static LocalDate fyStart(int fy) {
        return LocalDate.of(fy, 4, 1);
    }

    /** 31 March after fy, or today for the current year. */
    public static LocalDate fyEnd(int fy) {
        LocalDate end = LocalDate.of(fy + 1, 3, 31);
        LocalDate t = today();
        return end.isAfter(t) ? t : end;
    }

    /** "2025-26" */
    public static String fyLabel(int fy) {
        return String.format(Locale.ROOT, "%d-%02d", fy, (fy + 1) % 100);
    }

    /** Global role or Finance department may look at previous financial years. */
    public static boolean canChooseYear(String role, String department) {
        return "Global".equalsIgnoreCase(role == null ? "" : role.trim())
                || "Finance".equalsIgnoreCase(department == null ? "" : department.trim());
    }

    /**
     * The financial year to show. Blank = current year. Users who may not choose a year always get
     * the current year, whatever they send.
     */
    public static int resolveFy(String fyParam, boolean canChoose) {
        int current = currentFy();
        if (fyParam == null || fyParam.trim().isEmpty() || !canChoose) return current;
        int fy;
        try {
            fy = Integer.parseInt(fyParam.trim());
        } catch (NumberFormatException e) {
            throw new BadRequest("Invalid financial year.");
        }
        if (fy > current || fy < current - PAST_YEARS) throw new BadRequest("Invalid financial year.");
        return fy;
    }

    /** Current-year limit (kept for callers that have no year choice). */
    public static LocalDate[] currentYear(LocalDate[] range) {
        return limitToYear(range, currentFy());
    }

    /**
     * Limits a period to financial year fy (1 April .. 31 March, or today). null = the whole year.
     * A From date before 1 April becomes 1 April; a To date after the year end becomes the year end.
     */
    public static LocalDate[] limitToYear(LocalDate[] range, int fy) {
        LocalDate min = fyStart(fy), max = fyEnd(fy);
        if (range == null) return new LocalDate[] {min, max};
        LocalDate f = range[0].isBefore(min) ? min : range[0];
        LocalDate t = range[1].isAfter(max) ? max : range[1];
        // Period completely outside this year (e.g. an older year the user may not open): show the whole year.
        if (t.isBefore(min) || f.isAfter(max) || f.isAfter(t)) return new LocalDate[] {min, max};
        return new LocalDate[] {f, t};
    }

    /** Period details every reply carries, so screens can show and limit their date pickers. */
    private static void putPeriod(Map<String, Object> res, int fy, LocalDate from, LocalDate to, boolean clamped) {
        res.put("allDates", false);
        res.put("fy", fy);
        res.put("fyLabel", fyLabel(fy));
        res.put("fromDate", from.format(IN_DATE));
        res.put("toDate", to.format(IN_DATE));
        res.put("fromIso", from.toString());
        res.put("toIso", to.toString());
        res.put("minDate", fyStart(fy).toString());   // earliest date allowed (1 April of that year)
        res.put("maxDate", fyEnd(fy).toString());     // latest date allowed (31 March, or today)
        res.put("clamped", clamped);                   // true = requested dates were moved inside the year
    }

    /** Adds the year choice for the screen: canChooseYear + years [{fy, label}] newest first. */
    public static void putYearChoice(Map<String, Object> res, boolean canChoose) {
        res.put("canChooseYear", canChoose);
        List<Map<String, Object>> years = new ArrayList<>();
        int current = currentFy();
        for (int fy = current; fy >= (canChoose ? current - PAST_YEARS : current); fy--) {
            Map<String, Object> y = new LinkedHashMap<>();
            y.put("fy", fy);
            y.put("label", fyLabel(fy));
            years.add(y);
        }
        res.put("years", years);
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
    public Map<String, Object> summary(String branch, int fy, LocalDate[] range, String search, String category,
                                       boolean movedOnly) throws SQLException {
        LocalDate[] yr = limitToYear(range, fy);
        boolean clamped = range != null && (!yr[0].equals(range[0]) || !yr[1].equals(range[1]));
        LocalDate from = yr[0];
        LocalDate to = yr[1];

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
        putPeriod(res, fy, from, to, clamped);
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
     * @param type ALL (opening as on From + every entry with running balance) | RECEIPT | ISSUE.
     *             OPENING is treated as ALL: entries before 1 April are never listed.
     * @param fy    financial year start (from resolveFy, which applies the role rule)
     * @param range {from,to} or null for the whole year
     */
    public Map<String, Object> detail(String branch, int fy, int itemId, String type, LocalDate[] range)
            throws SQLException {
        if (itemId <= 0) throw new BadRequest("Invalid item.");
        if (type == null || !(type.equals("OPENING") || type.equals("RECEIPT")
                || type.equals("ISSUE") || type.equals("ALL"))) {
            throw new BadRequest("Invalid ledger type.");
        }
        if (type.equals("OPENING")) type = "ALL";
        LocalDate[] yr = limitToYear(range, fy);
        boolean clamped = range != null && (!yr[0].equals(range[0]) || !yr[1].equals(range[1]));
        LocalDate from = yr[0];
        LocalDate to = yr[1];

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
            if (type.equals("ALL")) {
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
                ps.setString(3, to.toString());

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
        putPeriod(result, fy, from, to, clamped);
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
