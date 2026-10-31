package com.officecentral.inventory.stock;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

/**
 * Rules shared by every screen that moves stock out (Issue Stock, Dining Hall consumption and its edit).
 *
 * <ul>
 *   <li>Entry date: today or up to {@link #BACKDATE_DAYS} days back (India time). No future dates.</li>
 *   <li>Running balance in stock_ledger is recalculated from the entry date onwards, so back-dated
 *       entries keep the balances in date order (RECEIPT adds; ISSUE and WASTAGE subtract).</li>
 * </ul>
 */
public final class StockEntryRules {

    /** How many days back an issue / consumption may be dated or edited. */
    public static final int BACKDATE_DAYS = 90;

    private static final DateTimeFormatter DMY = DateTimeFormatter.ofPattern("dd-MM-yyyy");

    private StockEntryRules() { }

    /** Problem with the entry that is safe to show to the user. */
    public static final class EntryError extends Exception {
        private static final long serialVersionUID = 1L;
        public EntryError(String m) { super(m); }
    }

    /** Earliest allowed entry date. */
    public static LocalDate earliestDate() {
        return StockLedgerDAO.today().minusDays(BACKDATE_DAYS);
    }

    /** Latest allowed entry date (today). */
    public static LocalDate latestDate() {
        return StockLedgerDAO.today();
    }

    /**
     * Parses a yyyy-MM-dd date (a time part, if any, is ignored) and checks the allowed window.
     * @throws EntryError with a message for the user
     */
    public static LocalDate checkEntryDate(String raw) throws EntryError {
        if (raw == null || raw.trim().isEmpty()) throw new EntryError("Select the date.");
        String s = raw.trim();
        if (s.length() > 10) s = s.substring(0, 10);
        LocalDate d;
        try {
            d = LocalDate.parse(s);
        } catch (DateTimeParseException e) {
            throw new EntryError("Invalid date.");
        }
        checkWindow(d, "Date");
        return d;
    }

    /** Throws when the date is in the future or more than BACKDATE_DAYS days back. */
    public static void checkWindow(LocalDate d, String what) throws EntryError {
        if (d.isAfter(latestDate())) throw new EntryError(what + " cannot be in the future.");
        if (d.isBefore(earliestDate())) {
            throw new EntryError(what + " " + d.format(DMY) + " is more than " + BACKDATE_DAYS
                    + " days back. Only entries from " + earliestDate().format(DMY) + " to today are allowed.");
        }
    }

    /**
     * Recalculates stock_ledger.running_balance for one item from {@code fromDate} onwards
     * (opening = all entries before that date). Only rows whose balance changes are written.
     * Must run inside the caller's transaction.
     */
    public static void recalcRunningBalance(Connection con, int itemId, LocalDate fromDate) throws SQLException {
        BigDecimal bal;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COALESCE(SUM(CASE WHEN trans_type = 'RECEIPT' THEN qty ELSE -qty END), 0)"
                + " FROM stock_ledger WHERE item_id = ? AND trans_date < ?")) {
            ps.setInt(1, itemId);
            ps.setDate(2, java.sql.Date.valueOf(fromDate));
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                bal = nz(rs.getBigDecimal(1));
            }
        }
        try (PreparedStatement sel = con.prepareStatement(
                     "SELECT ledger_id, trans_type, qty, running_balance FROM stock_ledger"
                     + " WHERE item_id = ? AND trans_date >= ? ORDER BY trans_date, ledger_id");
             PreparedStatement upd = con.prepareStatement(
                     "UPDATE stock_ledger SET running_balance = ? WHERE ledger_id = ?")) {
            sel.setInt(1, itemId);
            sel.setDate(2, java.sql.Date.valueOf(fromDate));
            int pending = 0;
            try (ResultSet rs = sel.executeQuery()) {
                while (rs.next()) {
                    BigDecimal q = nz(rs.getBigDecimal("qty"));
                    String type = rs.getString("trans_type");
                    bal = "RECEIPT".equalsIgnoreCase(type == null ? "" : type.trim()) ? bal.add(q) : bal.subtract(q);
                    BigDecimal stored = rs.getBigDecimal("running_balance");
                    if (stored == null || stored.compareTo(bal) != 0) {
                        upd.setBigDecimal(1, bal);
                        upd.setInt(2, rs.getInt("ledger_id"));
                        upd.addBatch();
                        if (++pending % 500 == 0) upd.executeBatch();
                    }
                }
            }
            if (pending % 500 != 0) upd.executeBatch();
        }
    }

    private static BigDecimal nz(BigDecimal b) {
        return b == null ? BigDecimal.ZERO : b;
    }
}
