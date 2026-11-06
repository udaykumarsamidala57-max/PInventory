package com.officecentral.inventory.indent;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;

/**
 * Indent numbers, shared by the website form (IndentServlet) and the Android app (MobileIndentDAO).
 *
 *  - Databases already in use (id_sequences has the row 'indent_no', or indents already exist): the earlier procedure
 *    is kept - one running number (next_val + 1). If the row is missing but indents exist, it is created from the
 *    highest indent number so numbering simply continues.
 *  - New databases (no 'indent_no' row and no indents yet): two-digit year + four-digit running number that starts
 *    again every calendar year: 260001, 260002 ... then 270001 in 2027 (a 10,000th indent in one year becomes 2610000).
 *    The running number of each year is kept in id_sequences as seq_name 'indent_no_2026', 'indent_no_2027', ...
 *
 * next() must be called inside the transaction that saves the indent: the sequence row stays locked until commit,
 * so two people saving at the same moment never get the same number.
 */
public final class IndentNumbers {

    static final String LEGACY = "indent_no";
    static final String YEARLY_PREFIX = "indent_no_";

    private IndentNumbers() { }

    /** Takes the next indent number (inside the caller's transaction). */
    public static String next(Connection con, LocalDate indentDate) throws SQLException {
        ensureTable(con);
        if (useLegacy(con, false)) {   // no FOR UPDATE here: a gap lock on a missing row would deadlock first indents
            try (PreparedStatement ps = con.prepareStatement("UPDATE id_sequences SET next_val = next_val + 1 WHERE seq_name=?")) {
                ps.setString(1, LEGACY);
                if (ps.executeUpdate() != 1) throw new SQLException("id_sequences row 'indent_no' missing");
            }
            Long v = value(con, LEGACY, false);
            if (v == null) throw new SQLException("id_sequences row 'indent_no' missing");
            return String.valueOf(v);
        }
        int year = (indentDate == null ? LocalDate.now() : indentDate).getYear();
        String name = YEARLY_PREFIX + year;
        // One statement that creates the year's row (1) or adds one to it, holding an exclusive lock: no two
        // transactions can get the same number, and the first indent of a year cannot deadlock.
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO id_sequences (seq_name, next_val) VALUES (?, 1) ON DUPLICATE KEY UPDATE next_val = next_val + 1")) {
            ps.setString(1, name);
            ps.executeUpdate();
        }
        Long seq = value(con, name, false);
        if (seq == null) throw new SQLException("id_sequences row '" + name + "' missing");
        return format(year, seq);
    }

    /** The number the next indent will probably get (shown on the form; nothing is reserved or written). */
    public static String peek(Connection con, LocalDate indentDate) throws SQLException {
        if (tableExists(con)) {
            Long legacy = value(con, LEGACY, false);
            if (legacy != null) return String.valueOf(legacy + 1);
        }
        if (indentCount(con) > 0 && !(tableExists(con) && hasYearlyRows(con))) {
            return String.valueOf(maxNumericIndent(con) + 1);
        }
        int year = (indentDate == null ? LocalDate.now() : indentDate).getYear();
        Long seq = tableExists(con) ? value(con, YEARLY_PREFIX + year, false) : null;
        return format(year, (seq == null ? 0 : seq) + 1);
    }

    /** 2026, 1 -> "260001". */
    static String format(int year, long seq) {
        return String.format("%02d%04d", year % 100, seq);
    }

    // ------------------------------------------------------------------ helpers

    /**
     * true = keep the earlier single running number. Creates the 'indent_no' row from the highest existing indent
     * number when indents exist but the row is missing (and no year rows exist yet).
     */
    private static boolean useLegacy(Connection con, boolean lock) throws SQLException {
        if (value(con, LEGACY, lock) != null) return true;
        if (hasYearlyRows(con)) return false;
        if (indentCount(con) == 0) return false;                       // brand-new database: yearly numbers
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO id_sequences (seq_name, next_val) VALUES (?, ?) ON DUPLICATE KEY UPDATE next_val = next_val")) {
            ps.setString(1, LEGACY);
            ps.setLong(2, maxNumericIndent(con));
            ps.executeUpdate();
        }
        return value(con, LEGACY, lock) != null;
    }

    private static Long value(Connection con, String name, boolean lock) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT next_val FROM id_sequences WHERE seq_name=?" + (lock ? " FOR UPDATE" : ""))) {
            ps.setString(1, name);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong(1) : null;
            }
        }
    }

    private static boolean hasYearlyRows(Connection con) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT 1 FROM id_sequences WHERE seq_name LIKE 'indent\\_no\\_%' LIMIT 1");
             ResultSet rs = ps.executeQuery()) {
            return rs.next();
        }
    }

    private static long indentCount(Connection con) throws SQLException {
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM indent")) {
            return rs.next() ? rs.getLong(1) : 0;
        }
    }

    private static long maxNumericIndent(Connection con) throws SQLException {
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery("SELECT COALESCE(MAX(CAST(indent_no AS UNSIGNED)),0) FROM indent WHERE indent_no REGEXP '^[0-9]+$'")) {
            return rs.next() ? rs.getLong(1) : 0;
        }
    }

    private static boolean tableExists(Connection con) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'id_sequences'");
             ResultSet rs = ps.executeQuery()) {
            return rs.next();
        }
    }

    /** New databases may not have the sequence table yet. */
    private static void ensureTable(Connection con) throws SQLException {
        if (tableExists(con)) return;
        try (Statement st = con.createStatement()) {
            st.executeUpdate("CREATE TABLE IF NOT EXISTS id_sequences (seq_name VARCHAR(50) NOT NULL PRIMARY KEY, next_val BIGINT NOT NULL DEFAULT 0) "
                    + "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        }
    }
}
