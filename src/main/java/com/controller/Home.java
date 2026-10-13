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

        // ===================== ACCESS CONTROL =====================
        // Dashboard: Finance department, or Global / Admin role only.
        // RHM -> Book a Service Request; everyone else -> Indent.
        String role = (String) sess.getAttribute("role");
        String department = (String) sess.getAttribute("department");
        role = role == null ? "" : role.trim();
        department = department == null ? "" : department.trim();

        boolean canSeeDashboard = "Finance".equalsIgnoreCase(department)
                || "Global".equalsIgnoreCase(role)
                || "Admin".equalsIgnoreCase(role);

        if (!canSeeDashboard) {
            String target = "RHM".equalsIgnoreCase(role) ? "/RequestBookingServlet" : "/IndentServlet";
            response.sendRedirect(request.getContextPath() + target);
            return;
        }

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
        Map<String, Double> last60DaysDeptMap = new LinkedHashMap<>();
        double last60DaysTotal = 0;
        Map<String, Double> thisYearDeptMap = new LinkedHashMap<>();
        double thisYearTotal = 0;

        // Top 3 consumed items per department, per period: dept -> [ {itemName, uom, qty, value}, ... ]
        Map<String, List<Object[]>> topYear = new LinkedHashMap<>();
        Map<String, List<Object[]>> top60 = new LinkedHashMap<>();
        Map<String, List<Object[]>> top30 = new LinkedHashMap<>();
        Map<String, List<Object[]>> top7 = new LinkedHashMap<>();
        Map<String, List<Object[]>> topToday = new LinkedHashMap<>();
        Map<String, List<Object[]>> topYearQ = new LinkedHashMap<>();
        Map<String, List<Object[]>> top60Q = new LinkedHashMap<>();
        Map<String, List<Object[]>> top30Q = new LinkedHashMap<>();
        Map<String, List<Object[]>> top7Q = new LinkedHashMap<>();
        Map<String, List<Object[]>> topTodayQ = new LinkedHashMap<>();

        // Vendor-wise purchase orders: vendor -> {total value, PO count}
        Map<String, double[]> poTodayMap = new LinkedHashMap<>();
        Map<String, double[]> po30Map = new LinkedHashMap<>();
        Map<String, double[]> po7Map = new LinkedHashMap<>();
        Map<String, double[]> po60Map = new LinkedHashMap<>();
        Map<String, double[]> poYearMap = new LinkedHashMap<>();

        try (Connection con = DBUtil.getConnection(branch)) {

            LocalDate today = LocalDate.now(ZoneId.of("Asia/Kolkata"));
            LocalDate startDate7 = today.minusDays(6);
            LocalDate startDate30 = today.minusDays(29);
            // "This Year" = current financial year: 1 April → today
            int fyStartYr = (today.getMonthValue() < 4) ? today.getYear() - 1 : today.getYear();
            LocalDate startThisYear = LocalDate.of(fyStartYr, 4, 1);
            request.setAttribute("thisYearFrom", "1 Apr " + fyStartYr);
            // Last 60 days, but never earlier than 1 April of the current FY
            LocalDate startDate60 = today.minusDays(59);
            if (startDate60.isBefore(startThisYear)) startDate60 = startThisYear;

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

            // Last 60 days' cost by department
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT IFNULL(NULLIF(TRIM(department),''),'Unassigned') AS dept, " +
                    "SUM(IFNULL(total_value,0)) AS v FROM stock_issues " +
                    "WHERE DATE(issue_date) >= ? AND DATE(issue_date) <= ? " +
                    "GROUP BY dept ORDER BY v DESC")) {
                ps.setDate(1, java.sql.Date.valueOf(startDate60));
                ps.setDate(2, java.sql.Date.valueOf(today));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        double v = rs.getDouble("v");
                        last60DaysDeptMap.put(rs.getString("dept"), v);
                        last60DaysTotal += v;
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

            // Vendor-wise PO value (same periods as consumption; 60 days and Year never before 1 April)
            loadVendorPOs(con, today, startDate7, startDate30, startDate60, startThisYear,
                          poTodayMap, po7Map, po30Map, po60Map, poYearMap);

            // Vendor price comparison: 10 items bought from 2+ vendors in the last 12 months
            request.setAttribute("priceCompareByCat", loadPriceCompare(con, today.minusMonths(12), today));

            // Top 3 most consumed items in each department - ranked by value and by quantity
            loadTopItems(con, startThisYear, today, topYear, topYearQ);
            loadTopItems(con, startDate60, today, top60, top60Q);
            loadTopItems(con, startDate30, today, top30, top30Q);
            loadTopItems(con, startDate7, today, top7, top7Q);
            loadTopItems(con, today, today, topToday, topTodayQ);

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
        request.setAttribute("last60DaysDeptMap", last60DaysDeptMap);
        request.setAttribute("last60DaysTotal", last60DaysTotal);
        request.setAttribute("thisYearDeptMap", thisYearDeptMap);
        request.setAttribute("thisYearTotal", thisYearTotal);
        request.setAttribute("poTodayMap", poTodayMap);
        request.setAttribute("po30Map", po30Map);
        request.setAttribute("po7Map", po7Map);
        request.setAttribute("po60Map", po60Map);
        request.setAttribute("poYearMap", poYearMap);
        request.setAttribute("topYear", topYear);
        request.setAttribute("top60", top60);
        request.setAttribute("top30", top30);
        request.setAttribute("top7", top7);
        request.setAttribute("topToday", topToday);
        request.setAttribute("topYearQ", topYearQ);
        request.setAttribute("top60Q", top60Q);
        request.setAttribute("top30Q", top30Q);
        request.setAttribute("top7Q", top7Q);
        request.setAttribute("topTodayQ", topTodayQ);

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

    /** Date formats seen in po_master.PO_date (stored as VARCHAR). */
    private static final java.time.format.DateTimeFormatter[] PO_DATE_FORMATS = {
        java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd"),
        java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy"),
        java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"),
        java.time.format.DateTimeFormatter.ofPattern("yyyy/MM/dd"),
        java.time.format.DateTimeFormatter.ofPattern("d-M-yyyy"),
        java.time.format.DateTimeFormatter.ofPattern("d/M/yyyy")
    };

    private static LocalDate parsePoDate(String raw) {
        if (raw == null) return null;
        String t = raw.trim();
        if (t.length() > 10 && t.charAt(4) == '-') t = t.substring(0, 10);   // "2026-10-13 00:00:00"
        for (java.time.format.DateTimeFormatter f : PO_DATE_FORMATS) {
            try { return LocalDate.parse(t, f); } catch (Exception ignore) { }
        }
        return null;
    }

    private static void addPo(Map<String, double[]> m, String vendor, double amt) {
        double[] a = m.computeIfAbsent(vendor, k -> new double[2]);
        a[0] += amt;
        a[1] += 1;
    }

    /** Sorts a vendor map by value, highest first. */
    private static void sortByValue(Map<String, double[]> m) {
        List<Map.Entry<String, double[]>> list = new ArrayList<>(m.entrySet());
        list.sort((x, y) -> Double.compare(y.getValue()[0], x.getValue()[0]));
        m.clear();
        for (Map.Entry<String, double[]> e : list) m.put(e.getKey(), e.getValue());
    }

    /**
     * Vendor-wise PO value for Today / last 7 / 30 / 60 days / this FY.
     * PO_date and total_amount are VARCHAR, so rows are read once and parsed in Java
     * (handles yyyy-MM-dd from the PO form as well as older dd-MM-yyyy / dd/MM/yyyy rows).
     */
    private static void loadVendorPOs(Connection con, LocalDate today, LocalDate from7, LocalDate from30,
                                      LocalDate from60, LocalDate fromYear,
                                      Map<String, double[]> todayMap, Map<String, double[]> map7,
                                      Map<String, double[]> map30, Map<String, double[]> map60,
                                      Map<String, double[]> mapYear) {
        LocalDate earliest = fromYear.isBefore(from60) ? fromYear : from60;
        int rows = 0, unparsed = 0;
        Map<String, String> vendorNames = new java.util.HashMap<>();   // UPPER-CASE key -> display name (first spelling seen)
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT vendor_name, PO_date, total_amount FROM po_master");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows++;
                LocalDate d = parsePoDate(rs.getString("PO_date"));
                if (d == null) { unparsed++; continue; }
                if (d.isBefore(earliest) || d.isAfter(today)) continue;

                String vendor = rs.getString("vendor_name");
                vendor = (vendor == null || vendor.trim().isEmpty()) ? "Unknown vendor"
                       : vendorNames.computeIfAbsent(vendorKey(vendor), k -> cleanVendor(rs, "vendor_name"));

                double amt = 0;
                String amtRaw = rs.getString("total_amount");
                if (amtRaw != null) {
                    try { amt = Double.parseDouble(amtRaw.replace(",", "").replace("\u20B9", "").trim()); }
                    catch (NumberFormatException ignore) { }
                }

                if (d.equals(today))          addPo(todayMap, vendor, amt);
                if (!d.isBefore(from7))       addPo(map7, vendor, amt);
                if (!d.isBefore(from30))      addPo(map30, vendor, amt);
                if (!d.isBefore(from60))      addPo(map60, vendor, amt);
                if (!d.isBefore(fromYear))    addPo(mapYear, vendor, amt);
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        sortByValue(todayMap); sortByValue(map7); sortByValue(map30); sortByValue(map60); sortByValue(mapYear);
        System.out.println("[Home] po_master rows=" + rows + ", unparsed dates=" + unparsed
                + ", vendors this year=" + mapYear.size());
    }

    /**
     * Top 3 most consumed items per department between from and to (inclusive).
     * outByValue ranks by issued value (Rs.), outByQty ranks by issued quantity.
     * Each entry: { String itemName, String uom, Double qty, Double value }.
     */
    private static void loadTopItems(Connection con, LocalDate from, LocalDate to,
                                     Map<String, List<Object[]>> outByValue,
                                     Map<String, List<Object[]>> outByQty) {
        String sql =
            "SELECT IFNULL(NULLIF(TRIM(si.department),''),'Unassigned') AS dept, " +
            "       COALESCE(im.Item_name, CONCAT('Item #', si.item_id)) AS item_name, " +
            "       IFNULL(im.UOM,'') AS uom, " +
            "       SUM(IFNULL(si.qty_issued,0)) AS q, " +
            "       SUM(IFNULL(si.total_value,0)) AS v " +
            "FROM stock_issues si LEFT JOIN item_master im ON im.Item_id = si.item_id " +
            "WHERE DATE(si.issue_date) >= ? AND DATE(si.issue_date) <= ? " +
            "GROUP BY dept, si.item_id, im.Item_name, im.UOM";
        Map<String, List<Object[]>> all = new LinkedHashMap<>();
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setDate(1, java.sql.Date.valueOf(from));
            ps.setDate(2, java.sql.Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    all.computeIfAbsent(rs.getString("dept"), k -> new ArrayList<>())
                       .add(new Object[] { rs.getString("item_name"), rs.getString("uom"),
                                           rs.getDouble("q"), rs.getDouble("v") });
                }
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        for (Map.Entry<String, List<Object[]>> e : all.entrySet()) {
            List<Object[]> byV = new ArrayList<>(e.getValue());
            byV.sort((x, y) -> Double.compare((Double) y[3], (Double) x[3]));
            outByValue.put(e.getKey(), new ArrayList<>(byV.subList(0, Math.min(3, byV.size()))));

            List<Object[]> byQ = new ArrayList<>(e.getValue());
            byQ.sort((x, y) -> Double.compare((Double) y[2], (Double) x[2]));
            outByQty.put(e.getKey(), new ArrayList<>(byQ.subList(0, Math.min(3, byQ.size()))));
        }
    }

    /**
     * Compares unit prices of the same item across vendors, from po_items + po_master.
     * Unit price = (amount - discount_value) / qty  -> after discount, before GST.
     * (po_items.net_amount includes GST, so it is not used here.)
     * Vendor names are matched ignoring capitals and extra spaces. Keeps items bought from at least
     * 2 different vendors between from..to and shows 20 of them a day, rotating daily.
     * Items are ordered most widely purchased first (number of POs, then purchase value).
     * Returns category -> list of { String itemName, String uom, Double totalValue, List<Object[]> vendors, Integer poCount, String category },
     * starting with "All Categories"; each list holds 20 items for today (rotating daily).
     * where each vendor is { String vendor, Double avgRate, Double lastRate, Double qty, Integer poCount, String lastDate },
     * vendors sorted cheapest (avgRate) first.
     */
    private static Map<String, List<Object[]>> loadPriceCompare(Connection con, LocalDate from, LocalDate to) {
        String sql =
            "SELECT pi.item_id, " +
            "       COALESCE(im.Item_name, pi.description, CONCAT('Item #', pi.item_id)) AS item_name, " +
            "       IFNULL(im.UOM,'') AS uom, " +
            "       IFNULL(NULLIF(TRIM(im.Category),''),'Uncategorised') AS category, " +
            "       pm.vendor_name, pm.PO_date, pm.PO_id, " +
            "       IFNULL(pi.qty,0) AS qty, IFNULL(pi.rate,0) AS rate, " +
            "       pi.amount, pi.discount_value, IFNULL(pi.discount_percent,0) AS discount_percent " +
            "FROM po_items pi JOIN po_master pm ON pm.PO_id = pi.PO_id " +
            "LEFT JOIN item_master im ON im.Item_id = pi.item_id " +
            "WHERE pi.item_id IS NOT NULL";

        // itemKey -> {name, uom, vendor -> accumulators}
        Map<Integer, String[]> itemInfo = new LinkedHashMap<>();
        Map<Integer, Map<String, double[]>> acc = new LinkedHashMap<>();   // {sumValue, sumQty, lastRate, lastDateEpochDay, poCount}
        Map<Integer, Map<String, java.util.Set<Integer>>> poSets = new LinkedHashMap<>();
        Map<String, String> vendorNames = new java.util.HashMap<>();

        try (PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                LocalDate d = parsePoDate(rs.getString("PO_date"));
                if (d == null || d.isBefore(from) || d.isAfter(to)) continue;
                String vendorRaw = rs.getString("vendor_name");
                if (vendorRaw == null || vendorRaw.trim().isEmpty()) continue;
                // same vendor regardless of capitals / extra spaces
                String vendor = vendorNames.computeIfAbsent(vendorKey(vendorRaw), k -> cleanVendor(vendorRaw));

                int itemId = rs.getInt("item_id");
                double qty = rs.getDouble("qty");
                double rate = rs.getDouble("rate");
                if (qty <= 0) continue;
                // Price after discount, before GST:  amount (qty x rate) - discount
                double amount = rs.getDouble("amount");
                if (rs.wasNull() || amount <= 0) amount = qty * rate;
                double disc = rs.getDouble("discount_value");
                if (rs.wasNull()) disc = amount * rs.getDouble("discount_percent") / 100.0;
                double value = amount - disc;
                if (value <= 0) continue;
                double unit = value / qty;

                itemInfo.putIfAbsent(itemId, new String[] { rs.getString("item_name"), rs.getString("uom"), rs.getString("category") });
                double[] a = acc.computeIfAbsent(itemId, k -> new LinkedHashMap<>())
                                .computeIfAbsent(vendor, k -> new double[] { 0, 0, 0, Long.MIN_VALUE, 0 });
                a[0] += value;
                a[1] += qty;
                if (d.toEpochDay() >= a[3]) { a[3] = d.toEpochDay(); a[2] = unit; }
                poSets.computeIfAbsent(itemId, k -> new LinkedHashMap<>())
                      .computeIfAbsent(vendor, k -> new java.util.HashSet<>()).add(rs.getInt("PO_id"));
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }

        List<Object[]> items = new ArrayList<>();
        for (Map.Entry<Integer, Map<String, double[]>> e : acc.entrySet()) {
            if (e.getValue().size() < 2) continue;   // needs at least 2 vendors to compare
            double total = 0;
            List<Object[]> vendors = new ArrayList<>();
            for (Map.Entry<String, double[]> v : e.getValue().entrySet()) {
                double[] a = v.getValue();
                total += a[0];
                vendors.add(new Object[] { v.getKey(), a[0] / a[1], a[2], a[1],
                        poSets.get(e.getKey()).get(v.getKey()).size(),
                        LocalDate.ofEpochDay((long) a[3]).format(java.time.format.DateTimeFormatter.ofPattern("dd MMM yy")) });
            }
            vendors.sort((x, y) -> Double.compare((Double) x[1], (Double) y[1]));
            String[] info = itemInfo.get(e.getKey());
            int poCount = 0;   // each PO has one vendor, so the per-vendor PO sets don't overlap
            for (java.util.Set<Integer> set : poSets.get(e.getKey()).values()) poCount += set.size();
            items.add(new Object[] { info[0], info[1], total, vendors, poCount, info[2] });
        }
        // Most widely purchased first: bought on more purchase orders, then higher purchase value.
        java.util.Comparator<Object[]> widelyUsed = (x, y) -> {
            int c = Integer.compare((Integer) y[4], (Integer) x[4]);
            if (c == 0) c = Double.compare((Double) y[2], (Double) x[2]);
            return c;
        };
        // "All Categories" first, then each category (largest purchase value first); 20 items each, rotating daily.
        Map<String, List<Object[]>> byCat = new java.util.HashMap<>();
        Map<String, Double> catValue = new java.util.HashMap<>();
        for (Object[] it : items) {
            String cat = String.valueOf(it[5]);
            byCat.computeIfAbsent(cat, k -> new ArrayList<>()).add(it);
            catValue.merge(cat, (Double) it[2], Double::sum);
        }
        List<String> cats = new ArrayList<>(byCat.keySet());
        cats.sort((x, y) -> Double.compare(catValue.get(y), catValue.get(x)));

        Map<String, List<Object[]>> out = new LinkedHashMap<>();
        out.put("All Categories", dailyPick(items, widelyUsed, to));
        for (String c : cats) out.put(c, dailyPick(byCat.get(c), widelyUsed, to));
        return out;
    }

    /** Up to 20 items for today: whole list if 20 or fewer, otherwise a window that moves on each day. */
    private static List<Object[]> dailyPick(List<Object[]> items, java.util.Comparator<Object[]> order, LocalDate day) {
        final int PER_DAY = 20;
        List<Object[]> sorted = new ArrayList<>(items);
        sorted.sort(order);
        if (sorted.size() <= PER_DAY) return sorted;
        int n = sorted.size();
        int start = (int) ((day.toEpochDay() * PER_DAY) % n);
        List<Object[]> pick = new ArrayList<>();
        for (int i = 0; i < PER_DAY; i++) pick.add(sorted.get((start + i) % n));
        pick.sort(order);
        return pick;
    }

    /** Key for matching vendor names: trimmed, single-spaced, upper case. */
    private static String vendorKey(String v) {
        return v.trim().replaceAll("\\s+", " ").toUpperCase(java.util.Locale.ROOT);
    }

    /** Display form of a vendor name: trimmed and single-spaced (keeps the first spelling seen). */
    private static String cleanVendor(String v) {
        return v.trim().replaceAll("\\s+", " ");
    }

    private static String cleanVendor(ResultSet rs, String col) {
        try { return cleanVendor(rs.getString(col)); } catch (Exception e) { return "Unknown vendor"; }
    }
}
