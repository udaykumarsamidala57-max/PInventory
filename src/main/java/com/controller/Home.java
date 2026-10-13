package com.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil;

@WebServlet("/Home")
public class Home extends HttpServlet {
    private static final long serialVersionUID = 1L;

    /** Financial year runs April → March[cite: 1]. */
    private static final String[] MONTH_NAMES = {
            "Apr", "May", "Jun", "Jul", "Aug", "Sep",
            "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"
    };

    /** Accepts "2026-27" or "2026-2027"[cite: 1]. */
    private static final Pattern FY_PATTERN = Pattern.compile("^(\\d{4})-(\\d{2}|\\d{4})$");

    /** Format start year to label like "2026-27"[cite: 1] */
    private static String fyLabel(int startYear) {
        return startYear + "-" + String.format("%02d", (startYear + 1) % 100);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        String branch = (String) sess.getAttribute("branch");

        // ===================== FILTERS & DATA COLLECTION =====================
        List<String> departments = new ArrayList<>();
        TreeSet<String> yearSet = new TreeSet<>(Collections.reverseOrder());
        Map<String, double[]> dataMap = new LinkedHashMap<>();
        double grandTotal = 0;

        Map<String, Double> todayDeptMap = new LinkedHashMap<>();
        double todayTotal = 0;
        Map<String, Double> last7DaysDeptMap = new LinkedHashMap<>();
        double last7DaysTotal = 0;
        Map<String, Double> last30DaysDeptMap = new LinkedHashMap<>();
        double last30DaysTotal = 0;
        Map<String, Double> last6MonthsDeptMap = new LinkedHashMap<>();
        double last6MonthsTotal = 0;
        Map<String, Double> thisYearDeptMap = new LinkedHashMap<>();
        double thisYearTotal = 0;

        try (Connection con = DBUtil.getConnection(branch)) {

            LocalDate today = LocalDate.now(ZoneId.of("Asia/Kolkata"));
            LocalDate startDate7 = today.minusDays(6);
            LocalDate startDate30 = today.minusDays(29);
            LocalDate startDate6M = today.minusMonths(6);
            // "This Year" = current financial year: 1 April → today
            int fyStartYr = (today.getMonthValue() < 4) ? today.getYear() - 1 : today.getYear();
            LocalDate startThisYear = LocalDate.of(fyStartYr, 4, 1);
            request.setAttribute("thisYearFrom", "1 Apr " + fyStartYr);

            // Today's cost by department (independent of filters)[cite: 1]
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT IFNULL(NULLIF(TRIM(department),''),'Unassigned') AS dept, " +
                    "SUM(IFNULL(total_value,0)) AS v FROM stock_issues " +
                    "WHERE DATE(issue_date) = ? " +
                    "GROUP BY dept ORDER BY v DESC")) {
                ps.setDate(1, java.sql.Date.valueOf(today));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        double v = rs.getDouble("v");
                        todayDeptMap.put(rs.getString("dept"), v);
                        todayTotal += v;
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            // Last 7 days' cost by department (independent of filters)
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT IFNULL(NULLIF(TRIM(department),''),'Unassigned') AS dept, " +
                    "SUM(IFNULL(total_value,0)) AS v FROM stock_issues " +
                    "WHERE DATE(issue_date) >= ? AND DATE(issue_date) <= ? " +
                    "GROUP BY dept ORDER BY v DESC")) {
                ps.setDate(1, java.sql.Date.valueOf(startDate7));
                ps.setDate(2, java.sql.Date.valueOf(today));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        double v = rs.getDouble("v");
                        last7DaysDeptMap.put(rs.getString("dept"), v);
                        last7DaysTotal += v;
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            // Last 30 days' cost by department
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT IFNULL(NULLIF(TRIM(department),''),'Unassigned') AS dept, " +
                    "SUM(IFNULL(total_value,0)) AS v FROM stock_issues " +
                    "WHERE DATE(issue_date) >= ? AND DATE(issue_date) <= ? " +
                    "GROUP BY dept ORDER BY v DESC")) {
                ps.setDate(1, java.sql.Date.valueOf(startDate30));
                ps.setDate(2, java.sql.Date.valueOf(today));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        double v = rs.getDouble("v");
                        last30DaysDeptMap.put(rs.getString("dept"), v);
                        last30DaysTotal += v;
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            // Last 6 months' cost by department
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT IFNULL(NULLIF(TRIM(department),''),'Unassigned') AS dept, " +
                    "SUM(IFNULL(total_value,0)) AS v FROM stock_issues " +
                    "WHERE DATE(issue_date) >= ? AND DATE(issue_date) <= ? " +
                    "GROUP BY dept ORDER BY v DESC")) {
                ps.setDate(1, java.sql.Date.valueOf(startDate6M));
                ps.setDate(2, java.sql.Date.valueOf(today));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        double v = rs.getDouble("v");
                        last6MonthsDeptMap.put(rs.getString("dept"), v);
                        last6MonthsTotal += v;
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            // This year's cost by department (FY: April 1 to today)
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT IFNULL(NULLIF(TRIM(department),''),'Unassigned') AS dept, " +
                    "SUM(IFNULL(total_value,0)) AS v FROM stock_issues " +
                    "WHERE DATE(issue_date) >= ? AND DATE(issue_date) <= ? " +
                    "GROUP BY dept ORDER BY v DESC")) {
                ps.setDate(1, java.sql.Date.valueOf(startThisYear));
                ps.setDate(2, java.sql.Date.valueOf(today));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        double v = rs.getDouble("v");
                        thisYearDeptMap.put(rs.getString("dept"), v);
                        thisYearTotal += v;
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            // Departments dropdown[cite: 1]
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT DISTINCT department FROM stock_issues " +
                    "WHERE department IS NOT NULL AND department<>'' ORDER BY department");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    departments.add(rs.getString(1));
                }
            }

            // Financial Year dropdown (Apr–Mar), label like 2026-27[cite: 1]
            String fyQuery =
                "SELECT DISTINCT " +
                "CASE WHEN MONTH(issue_date) >= 4 " +
                "  THEN CONCAT(YEAR(issue_date), '-', RIGHT(CAST(YEAR(issue_date)+1 AS CHAR), 2)) " +
                "  ELSE CONCAT(YEAR(issue_date)-1, '-', RIGHT(CAST(YEAR(issue_date) AS CHAR), 2)) " +
                "END AS fy " +
                "FROM stock_issues WHERE issue_date IS NOT NULL";
            try (PreparedStatement ps = con.prepareStatement(fyQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    yearSet.add(rs.getString("fy"));
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        // Determine default financial year dynamically from available data
        int currentYear = LocalDate.now(ZoneId.of("Asia/Kolkata")).getYear();
        int defaultFyStart = (LocalDate.now(ZoneId.of("Asia/Kolkata")).getMonthValue() < 4) ? currentYear - 1 : currentYear;
        String defaultFY = fyLabel(defaultFyStart);

        if (!yearSet.isEmpty()) {
            defaultFY = yearSet.first();
        } else {
            yearSet.add(defaultFY);
        }

        String selectedFY = defaultFY;
        int fyStartYear = Integer.parseInt(selectedFY.substring(0, 4));

        String selectedDept = request.getParameter("department");
        if (selectedDept == null || selectedDept.trim().isEmpty()) {
            selectedDept = "All";
        }

        String yearParam = request.getParameter("year");
        if (yearParam != null) {
            Matcher m = FY_PATTERN.matcher(yearParam.trim());
            if (m.matches()) {
                fyStartYear = Integer.parseInt(m.group(1));
                selectedFY = fyLabel(fyStartYear);
            }
        }

        java.sql.Date fyStart = java.sql.Date.valueOf(LocalDate.of(fyStartYear, 4, 1));
        java.sql.Date fyEndExclusive = java.sql.Date.valueOf(LocalDate.of(fyStartYear + 1, 4, 1));

        // ===================== MONTH-WISE DATA QUERY =====================
        try (Connection con = DBUtil.getConnection(branch)) {
            StringBuilder sql = new StringBuilder(
                "SELECT department, MONTH(issue_date) AS m, SUM(IFNULL(total_value,0)) AS v " +
                "FROM stock_issues WHERE issue_date >= ? AND issue_date < ? "
            );
            boolean allDepts = "All".equalsIgnoreCase(selectedDept);
            if (!allDepts) {
                sql.append("AND department=? ");
            }
            sql.append("GROUP BY department, MONTH(issue_date) ORDER BY department");

            try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
                ps.setDate(1, fyStart);
                ps.setDate(2, fyEndExclusive);
                if (!allDepts) {
                    ps.setString(3, selectedDept);
                }
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String dept = rs.getString("department");
                        if (dept == null) continue;

                        int dbMonth = rs.getInt("m");
                        double val = rs.getDouble("v");

                        // Calendar month -> FY index (Apr=0 ... Mar=11)[cite: 1]
                        int index = (dbMonth >= 4) ? (dbMonth - 4) : (dbMonth + 8);

                        dataMap.computeIfAbsent(dept, k -> new double[12])[index] += val;
                        grandTotal += val;
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // ===================== FORWARD =====================[cite: 1]
        request.setAttribute("todayDeptMap", todayDeptMap);
        request.setAttribute("todayTotal", todayTotal);
        request.setAttribute("last7DaysDeptMap", last7DaysDeptMap);
        request.setAttribute("last7DaysTotal", last7DaysTotal);
        request.setAttribute("last30DaysDeptMap", last30DaysDeptMap);
        request.setAttribute("last30DaysTotal", last30DaysTotal);
        request.setAttribute("last6MonthsDeptMap", last6MonthsDeptMap);
        request.setAttribute("last6MonthsTotal", last6MonthsTotal);
        request.setAttribute("thisYearDeptMap", thisYearDeptMap);
        request.setAttribute("thisYearTotal", thisYearTotal);

        request.setAttribute("departments", departments);
        request.setAttribute("years", new ArrayList<>(yearSet));
        request.setAttribute("dataMap", dataMap);
        request.setAttribute("monthNames", MONTH_NAMES);
        request.setAttribute("selectedDept", selectedDept);
        request.setAttribute("selectedYear", selectedFY);
        request.setAttribute("grandTotal", grandTotal);
        request.setAttribute("totalRows", dataMap.size());

        request.getRequestDispatcher("/Home.jsp").forward(request, response);
    }
}
