package com.officecentral.inventory.dining;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.officecentral.common.db.InventoryDB;

/**
 * Meal cost report: for every day and session, the strength, the meal cost (value of all Dining Hall issues) and
 * the cost per head; for every day, the day's meal cost and the cost per head per day (sum of its sessions).
 * Read-only. Access: AccessFilter (same people as the Dining Hall entry) and UAMS page din.meal-cost.
 */
@WebServlet(urlPatterns = {"/meal-cost"})
public class MealCostServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final ZoneId IST = ZoneId.of("Asia/Kolkata");
    private static final DateTimeFormatter DMY = DateTimeFormatter.ofPattern("dd-MM-yyyy");
    private static final int MAX_DAYS = 400;
    /** Usual order of the sessions in a day; others follow alphabetically. */
    private static final List<String> ORDER = List.of("Morning Drink", "Break Fast", "Lunch", "Snacks", "Dinner", "Staff Tea",
            "Special Event", "Adjustment");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) { response.sendRedirect("login.jsp"); return; }
        String branch = sess.getAttribute("branch") == null ? "" : String.valueOf(sess.getAttribute("branch")).trim();
        if (branch.isEmpty()) throw new ServletException("Branch information is missing from session.");

        LocalDate today = LocalDate.now(IST);
        LocalDate from = date(request.getParameter("from"), today.withDayOfMonth(1));
        LocalDate to = date(request.getParameter("to"), today);
        String error = null;
        if (to.isBefore(from)) { LocalDate t = from; from = to; to = t; }
        if (from.plusDays(MAX_DAYS).isBefore(to)) {
            from = to.minusDays(MAX_DAYS);
            error = "Showing the last " + MAX_DAYS + " days only. Choose a shorter period.";
        }

        // key = date|session
        Map<String, Row> rows = new LinkedHashMap<>();
        try (Connection con = InventoryDB.getConnection(branch)) {
            try (PreparedStatement ps = con.prepareStatement("SELECT DATE(issue_date) AS d, session, COALESCE(SUM(total_value),0) AS cost, "
                    + "COUNT(DISTINCT issueno) AS issues FROM dining_hall_consumption WHERE issue_date >= ? AND issue_date < ? "
                    + "GROUP BY DATE(issue_date), session")) {
                ps.setString(1, from.toString());
                ps.setString(2, to.plusDays(1).toString());
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Row r = row(rows, rs.getDate("d").toLocalDate(), rs.getString("session"));
                        r.cost = rs.getBigDecimal("cost");
                        r.issues = rs.getInt("issues");
                    }
                }
            }
            try (PreparedStatement ps = con.prepareStatement("SELECT meal_date, session, boarding_students, day_boarding_students, "
                    + "day_scholars, staff FROM dining_meal_strength WHERE meal_date BETWEEN ? AND ?")) {
                ps.setString(1, from.toString());
                ps.setString(2, to.toString());
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Row r = row(rows, rs.getDate("meal_date").toLocalDate(), rs.getString("session"));
                        r.strength = new MealStrength(rs.getInt(3), rs.getInt(4), rs.getInt(5), rs.getInt(6));
                    }
                }
            }
        } catch (SQLException e) {
            error = "The meal cost could not be read: " + e.getMessage()
                    + (e.getMessage() != null && e.getMessage().contains("dining_meal_strength") ? " (run the strength SQL on this branch database)" : "");
        }

        // group by day, sessions in the usual order
        Map<LocalDate, List<Row>> byDay = new java.util.TreeMap<>();
        for (Row r : rows.values()) byDay.computeIfAbsent(r.date, k -> new ArrayList<>()).add(r);
        List<Map<String, Object>> days = new ArrayList<>();
        BigDecimal periodCost = BigDecimal.ZERO, periodPerHeadSum = BigDecimal.ZERO;
        int daysWithPerHead = 0;
        for (Map.Entry<LocalDate, List<Row>> e : byDay.entrySet()) {
            List<Row> list = e.getValue();
            list.sort((a, b) -> {
                int ia = ORDER.indexOf(a.session), ib = ORDER.indexOf(b.session);
                if (ia < 0) ia = 99;
                if (ib < 0) ib = 99;
                return ia != ib ? Integer.compare(ia, ib) : a.session.compareToIgnoreCase(b.session);
            });
            BigDecimal dayCost = BigDecimal.ZERO, dayPerHead = BigDecimal.ZERO;
            boolean anyPerHead = false, missing = false;
            List<Map<String, Object>> sessions = new ArrayList<>();
            for (Row r : list) {
                BigDecimal cost = r.cost == null ? BigDecimal.ZERO : r.cost;
                int people = r.strength == null ? 0 : r.strength.total();
                BigDecimal ph = MealStrength.perHead(cost, people);
                dayCost = dayCost.add(cost);
                if (ph != null && !"Adjustment".equals(r.session)) { dayPerHead = dayPerHead.add(ph); anyPerHead = true; }
                if (ph == null && cost.signum() != 0 && !"Adjustment".equals(r.session)) missing = true;
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("session", r.session);
                m.put("boarding", r.strength == null ? "-" : String.valueOf(r.strength.boarding));
                m.put("dayBoarding", r.strength == null ? "-" : String.valueOf(r.strength.dayBoarding));
                m.put("dayScholars", r.strength == null ? "-" : String.valueOf(r.strength.dayScholars));
                m.put("staff", r.strength == null ? "-" : String.valueOf(r.strength.staff));
                m.put("total", r.strength == null ? "-" : String.valueOf(people));
                m.put("issues", r.issues);
                m.put("cost", MealStrength.rupees(cost));
                m.put("perHead", ph == null ? (cost.signum() == 0 ? "-" : "Strength missing") : MealStrength.rupees(ph));
                m.put("missing", ph == null && cost.signum() != 0);
                sessions.add(m);
            }
            Map<String, Object> d = new LinkedHashMap<>();
            d.put("date", e.getKey().format(DMY));
            d.put("day", e.getKey().getDayOfWeek().getDisplayName(java.time.format.TextStyle.SHORT, java.util.Locale.ENGLISH));
            d.put("sessions", sessions);
            d.put("cost", MealStrength.rupees(dayCost));
            d.put("perHead", anyPerHead ? MealStrength.rupees(dayPerHead) : "-");
            d.put("incomplete", missing);
            days.add(d);
            periodCost = periodCost.add(dayCost);
            if (anyPerHead) { periodPerHeadSum = periodPerHeadSum.add(dayPerHead); daysWithPerHead++; }
        }

        request.setAttribute("from", from.toString());
        request.setAttribute("to", to.toString());
        request.setAttribute("fromText", from.format(DMY));
        request.setAttribute("toText", to.format(DMY));
        request.setAttribute("days", days);
        request.setAttribute("periodCost", MealStrength.rupees(periodCost));
        request.setAttribute("avgPerHeadPerDay", daysWithPerHead == 0 ? "-"
                : MealStrength.rupees(periodPerHeadSum.divide(BigDecimal.valueOf(daysWithPerHead), 2, java.math.RoundingMode.HALF_UP)));
        request.setAttribute("dayCount", days.size());
        request.setAttribute("error", error);
        request.getRequestDispatcher("/WEB-INF/views/inventory/dining/meal_cost_report.jsp").forward(request, response);
    }

    private static final class Row {
        final LocalDate date; final String session;
        BigDecimal cost; int issues; MealStrength strength;
        Row(LocalDate date, String session) { this.date = date; this.session = session; }
    }

    private static Row row(Map<String, Row> rows, LocalDate d, String session) {
        String s = session == null ? "" : session;
        return rows.computeIfAbsent(d + "|" + s, k -> new Row(d, s));
    }

    private static LocalDate date(String v, LocalDate fallback) {
        if (v == null || v.isBlank()) return fallback;
        try { return LocalDate.parse(v.trim()); } catch (DateTimeParseException e) { return fallback; }
    }
}
