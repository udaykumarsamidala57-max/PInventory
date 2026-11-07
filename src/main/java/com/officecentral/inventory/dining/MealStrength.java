package com.officecentral.inventory.dining;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Strength (number of people who ate) of one Dining Hall session on one day, and the meal cost per head.
 *
 *   Strength          = Boarding Students + Day Boarding Students + Dayscholars + Staff
 *   Session meal cost = total value of all Dining Hall issues of that date and session
 *   Cost per head     = session meal cost / strength
 *   Day cost per head = sum of the per-head costs of that day's sessions (what one person's meals cost that day)
 *
 * The strength is kept once per date + session (table dining_meal_strength): every issue of the same session
 * shares it. Each change is written to dining_meal_strength_log.
 */
public final class MealStrength {

    public static final int MAX_COUNT = 100000;

    public final int boarding, dayBoarding, dayScholars, staff;

    public MealStrength(int boarding, int dayBoarding, int dayScholars, int staff) {
        this.boarding = boarding;
        this.dayBoarding = dayBoarding;
        this.dayScholars = dayScholars;
        this.staff = staff;
    }

    public int total() { return boarding + dayBoarding + dayScholars + staff; }

    /** Reads the four form fields; blank = 0. Throws IllegalArgumentException with a clear message. */
    public static MealStrength fromForm(String boarding, String dayBoarding, String dayScholars, String staff) {
        return new MealStrength(count("Boarding Students", boarding), count("Day Boarding Students", dayBoarding),
                count("Dayscholars", dayScholars), count("Staff", staff));
    }

    private static int count(String label, String v) {
        String s = v == null ? "" : v.trim();
        if (s.isEmpty()) return 0;
        int n;
        try { n = Integer.parseInt(s); }
        catch (NumberFormatException e) { throw new IllegalArgumentException(label + ": enter a whole number."); }
        if (n < 0 || n > MAX_COUNT) throw new IllegalArgumentException(label + ": enter a number from 0 to " + MAX_COUNT + ".");
        return n;
    }

    /** The saved strength of a date + session, or null. */
    public static MealStrength find(Connection con, String date, String session) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT boarding_students, day_boarding_students, day_scholars, staff "
                + "FROM dining_meal_strength WHERE meal_date = ? AND session = ?")) {
            ps.setString(1, date);
            ps.setString(2, session);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? new MealStrength(rs.getInt(1), rs.getInt(2), rs.getInt(3), rs.getInt(4)) : null;
            }
        }
    }

    /** Saves the strength of a date + session (inside the caller's transaction) and logs any change. */
    public void save(Connection con, String date, String session, String user) throws SQLException {
        MealStrength old = null;
        Integer id = null;
        try (PreparedStatement ps = con.prepareStatement("SELECT id, boarding_students, day_boarding_students, day_scholars, staff "
                + "FROM dining_meal_strength WHERE meal_date = ? AND session = ? FOR UPDATE")) {
            ps.setString(1, date);
            ps.setString(2, session);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    id = rs.getInt(1);
                    old = new MealStrength(rs.getInt(2), rs.getInt(3), rs.getInt(4), rs.getInt(5));
                }
            }
        }
        if (old != null && old.sameAs(this)) return;
        if (old == null) {
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO dining_meal_strength (meal_date, session, boarding_students, "
                    + "day_boarding_students, day_scholars, staff, created_by, updated_by) VALUES (?,?,?,?,?,?,?,?)",
                    java.sql.Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, date);
                ps.setString(2, session);
                ps.setInt(3, boarding);
                ps.setInt(4, dayBoarding);
                ps.setInt(5, dayScholars);
                ps.setInt(6, staff);
                ps.setString(7, user);
                ps.setString(8, user);
                if (ps.executeUpdate() != 1) throw new SQLException("The strength was not saved.");
                try (ResultSet keys = ps.getGeneratedKeys()) { if (keys.next()) id = keys.getInt(1); }
            }
        } else {
            try (PreparedStatement ps = con.prepareStatement("UPDATE dining_meal_strength SET boarding_students=?, day_boarding_students=?, "
                    + "day_scholars=?, staff=?, updated_by=? WHERE id=?")) {
                ps.setInt(1, boarding);
                ps.setInt(2, dayBoarding);
                ps.setInt(3, dayScholars);
                ps.setInt(4, staff);
                ps.setString(5, user);
                ps.setInt(6, id);
                if (ps.executeUpdate() != 1) throw new SQLException("The strength was not updated.");
            }
        }
        try (PreparedStatement ps = con.prepareStatement("INSERT INTO dining_meal_strength_log (strength_id, meal_date, session, "
                + "old_boarding, old_day_boarding, old_day_scholars, old_staff, new_boarding, new_day_boarding, new_day_scholars, new_staff, "
                + "changed_by) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)")) {
            ps.setObject(1, id);
            ps.setString(2, date);
            ps.setString(3, session);
            ps.setObject(4, old == null ? null : old.boarding);
            ps.setObject(5, old == null ? null : old.dayBoarding);
            ps.setObject(6, old == null ? null : old.dayScholars);
            ps.setObject(7, old == null ? null : old.staff);
            ps.setInt(8, boarding);
            ps.setInt(9, dayBoarding);
            ps.setInt(10, dayScholars);
            ps.setInt(11, staff);
            ps.setString(12, user);
            if (ps.executeUpdate() != 1) throw new SQLException("The strength change could not be logged.");
        }
    }

    private boolean sameAs(MealStrength o) {
        return boarding == o.boarding && dayBoarding == o.dayBoarding && dayScholars == o.dayScholars && staff == o.staff;
    }

    /** Total value of all Dining Hall issues of a date + session. */
    public static BigDecimal sessionCost(Connection con, String date, String session) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT COALESCE(SUM(total_value), 0) FROM dining_hall_consumption "
                + "WHERE DATE(issue_date) = ? AND session = ?")) {
            ps.setString(1, date);
            ps.setString(2, session);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getBigDecimal(1) != null ? rs.getBigDecimal(1) : BigDecimal.ZERO;
            }
        }
    }

    /** cost / people, rounded to paise; null when there is no strength. */
    public static BigDecimal perHead(BigDecimal cost, int people) {
        if (people <= 0 || cost == null) return null;
        return cost.divide(BigDecimal.valueOf(people), 2, RoundingMode.HALF_UP);
    }

    /** ₹1,23,456.78 */
    public static String rupees(BigDecimal v) {
        if (v == null) return "-";
        BigDecimal r = v.setScale(2, RoundingMode.HALF_UP);
        boolean neg = r.signum() < 0;
        String s = r.abs().toPlainString();
        int dot = s.indexOf('.');
        String whole = s.substring(0, dot), paise = s.substring(dot);
        StringBuilder b = new StringBuilder();
        int n = whole.length();
        if (n <= 3) b.append(whole);
        else {
            String head = whole.substring(0, n - 3);
            for (int i = 0; i < head.length(); i++) {
                if (i > 0 && (head.length() - i) % 2 == 0) b.append(',');
                b.append(head.charAt(i));
            }
            b.append(',').append(whole.substring(n - 3));
        }
        return (neg ? "-" : "") + "₹" + b + paise;
    }
}
