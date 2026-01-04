package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

@WebServlet("/Home")
public class Home extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Map<String, Integer> deptPendingMap = new LinkedHashMap<>();
        Map<String, Integer> totalDeptMap = new LinkedHashMap<>();
        Map<String, Integer> nextStageCountMap = new LinkedHashMap<>();

        List<Map<String, Object>> topCostliest = new ArrayList<>();
        List<Map<String, Object>> topQty = new ArrayList<>();

        // ===================== DASHBOARD COUNTS =====================
        try (Connection con = DBUtil.getConnection()) {

            // ✅ Department Pending
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT department, COUNT(*) AS pending_count FROM indent " +
                            "WHERE status='Pending' OR Istatus='Pending' " +
                            "GROUP BY department ORDER BY department");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    deptPendingMap.put(rs.getString(1), rs.getInt(2));
                }
            }

            // ✅ Total Indents by Department
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT department, COUNT(*) AS totalCount FROM indent " +
                            "GROUP BY department ORDER BY department");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    totalDeptMap.put(rs.getString(1), rs.getInt(2));
                }
            }

            // ✅ Indent Stage Counts
            String stageQuery = "SELECT IFNULL(TRIM(Indentnext),'') AS stage, COUNT(*) " +
                    "FROM indent GROUP BY IFNULL(TRIM(Indentnext),'')";
            try (PreparedStatement ps = con.prepareStatement(stageQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String stage = rs.getString(1).trim();
                    int cnt = rs.getInt(2);
                    if (stage == null) {
                        stage = "";
                    }

                    switch (stage) {
                        case "":
                            stage = "Approval Pending";
                            break;
                        case "PO":
                            stage = "PO";
                            break;
                        case "Issue":
                            stage = "Issue Pending";
                            break;
                        
                        case "Management Note":
                            stage = "Management Note";
                            break;
                        default:
                            stage = "Others";
                            break;
                    }
                    nextStageCountMap.put(stage, nextStageCountMap.getOrDefault(stage, 0) + cnt);
                }
            }

            // Fill missing stages with zero
            for (String s : new String[]{"Approval-Pending", "PO", "Issue Pending", "Issued", "Management Note"}) {
                nextStageCountMap.putIfAbsent(s, 0);
            }

            // ✅ Top 5 costliest items overall
            String topCostliestQuery =
                    "SELECT i.Category, i.Item_name, s.last_price " +
                            "FROM stock s JOIN item_master i ON s.item_id=i.Item_id " +
                            "ORDER BY s.last_price DESC LIMIT 5";
            try (PreparedStatement ps = con.prepareStatement(topCostliestQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("Category", rs.getString("Category"));
                    row.put("Item_name", rs.getString("Item_name"));
                    row.put("last_price", rs.getDouble("last_price"));
                    topCostliest.add(row);
                }
            }

            // ✅ Top 5 Highest Quantity Items Overall
            String topQtyQuery =
                    "SELECT i.Item_name, i.Category, s.balance_qty " +
                            "FROM stock s JOIN item_master i ON s.item_id=i.Item_id " +
                            "ORDER BY s.balance_qty DESC LIMIT 5";
            try (PreparedStatement ps = con.prepareStatement(topQtyQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("Item_name", rs.getString("Item_name"));
                    row.put("Category", rs.getString("Category"));
                    row.put("balance_qty", rs.getDouble("balance_qty"));
                    topQty.add(row);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        // Set dashboard data
        request.setAttribute("deptPendingMap", deptPendingMap);
        request.setAttribute("totalDeptMap", totalDeptMap);
        request.setAttribute("nextStageCountMap", nextStageCountMap);
        request.setAttribute("topCostliest", topCostliest);
        request.setAttribute("topQty", topQty);

        // ===================== CHART FILTER & DATA =====================
        String selectedDept = request.getParameter("department");
        if (selectedDept == null) selectedDept = "All";

        String selectedFY = request.getParameter("year");
        if (selectedFY == null) {
            int y = Calendar.getInstance().get(Calendar.YEAR);
            selectedFY = (y - 1) + "-" + y;
        }

        // Parse FY
        String[] fyParts = selectedFY.split("-");
        int fyStartYear = Integer.parseInt(fyParts[0]);
        int fyEndYear = Integer.parseInt(fyParts[1]);

        java.sql.Date fyStart = java.sql.Date.valueOf(fyStartYear + "-03-01");
        java.sql.Date fyEnd = java.sql.Date.valueOf(fyEndYear + "-02-28");

        // FY Month Order
        String[] monthNames = {
                "Mar","Apr","May","Jun","Jul","Aug",
                "Sep","Oct","Nov","Dec","Jan","Feb"
        };

        Map<String, double[]> dataMap = new LinkedHashMap<>();
        double grandTotal = 0;

        try (Connection con = DBUtil.getConnection()) {

            // ✅ Departments dropdown
            List<String> departments = new ArrayList<>();
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT DISTINCT department FROM stock_issues " +
                    "WHERE department IS NOT NULL AND department<>'' ORDER BY department");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    departments.add(rs.getString(1));
                }
            }

            // ✅ Financial Year dropdown
            List<String> years = new ArrayList<>();

            String fyQuery =
                "SELECT DISTINCT " +
                "CASE " +
                " WHEN MONTH(issue_date) >= 3 " +
                " THEN CONCAT(YEAR(issue_date), '-', YEAR(issue_date)+1) " +
                " ELSE CONCAT(YEAR(issue_date)-1, '-', YEAR(issue_date)) " +
                "END AS fy " +
                "FROM stock_issues " +
                "ORDER BY fy DESC";

            try (PreparedStatement ps = con.prepareStatement(fyQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    years.add(rs.getString("fy"));
                }
            }

            // ✅ Main FY Data Query
            StringBuilder sql = new StringBuilder(
                "SELECT department, MONTH(issue_date) m, SUM(IFNULL(total_value,0)) v " +
                "FROM stock_issues WHERE issue_date BETWEEN ? AND ? "
            );
            if (!"All".equalsIgnoreCase(selectedDept)) {
                sql.append("AND department=? ");
            }
            sql.append("GROUP BY department, m");

            try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
                ps.setDate(1, fyStart);
                ps.setDate(2, fyEnd);
                if (!"All".equalsIgnoreCase(selectedDept)) {
                    ps.setString(3, selectedDept);
                }

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String dept = rs.getString("department");
                        int dbMonth = rs.getInt("m");
                        double val = rs.getDouble("v");

                        if (dept == null) continue;

                        // Convert Calendar Month → FY Index
                        int index = (dbMonth >= 3) ? (dbMonth - 3) : (dbMonth + 9);

                        dataMap.putIfAbsent(dept, new double[12]);
                        dataMap.get(dept)[index] += val;
                        grandTotal += val;
                    }
                }
            }

            // Set Attributes
            request.setAttribute("departments", departments);
            request.setAttribute("years", years);
            request.setAttribute("dataMap", dataMap);
            request.setAttribute("monthNames", monthNames);
            request.setAttribute("selectedDept", selectedDept);
            request.setAttribute("selectedYear", selectedFY);
            request.setAttribute("grandTotal", grandTotal);
            request.setAttribute("totalRows", dataMap.size());

            RequestDispatcher rd = request.getRequestDispatcher("Home.jsp");
            rd.forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
        }

    }
}
