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
            String stageQuery = "SELECT IFNULL(Indentnext,'') AS stage, COUNT(*) FROM indent GROUP BY Indentnext";
            try (PreparedStatement ps = con.prepareStatement(stageQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String stage = rs.getString(1).trim();
                    int cnt = rs.getInt(2);

                    switch (stage) {
                        case "":
                            stage = "Approval-Pending";
                            break;
                        case "PO":
                            stage = "PO";
                            break;
                        case "Issue":
                            stage = "Issue Pending";
                            break;
                        case "Issued":
                            stage = "Issued";
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

        String selectedYear = request.getParameter("year");
        if (selectedYear == null) {
            selectedYear = String.valueOf(Calendar.getInstance().get(Calendar.YEAR));
        }

        String[] monthNames = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};

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
                    departments.add(rs.getString("department"));
                }
            }

            // ✅ Years dropdown
            List<String> years = new ArrayList<>();
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT DISTINCT YEAR(issue_date) AS y FROM stock_issues " +
                            "WHERE issue_date IS NOT NULL ORDER BY y DESC");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    years.add(rs.getString("y"));
                }
            }

            // ✅ Main Data Query
            StringBuilder sql = new StringBuilder(
                    "SELECT department, MONTH(issue_date) AS m, SUM(IFNULL(total_value,0)) AS total_value " +
                            "FROM stock_issues WHERE issue_date IS NOT NULL AND YEAR(issue_date)=? ");
            if (!"All".equalsIgnoreCase(selectedDept)) {
                sql.append("AND department=? ");
            }
            sql.append("GROUP BY department, m ORDER BY department, m");

            try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
                ps.setInt(1, Integer.parseInt(selectedYear));
                if (!"All".equalsIgnoreCase(selectedDept)) {
                    ps.setString(2, selectedDept);
                }

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String dept = rs.getString("department");
                        int month = rs.getInt("m");
                        double val = rs.getDouble("total_value");

                        if (dept == null || dept.trim().isEmpty()) continue;
                        dataMap.putIfAbsent(dept, new double[12]);
                        dataMap.get(dept)[month - 1] = val;
                        grandTotal += val;
                    }
                }
            }

            // ✅ Set attributes for JSP
            request.setAttribute("departments", departments);
            request.setAttribute("years", years);
            request.setAttribute("dataMap", dataMap);
            request.setAttribute("monthNames", monthNames);
            request.setAttribute("selectedDept", selectedDept);
            request.setAttribute("selectedYear", selectedYear);
            request.setAttribute("grandTotal", grandTotal);
            request.setAttribute("totalRows", dataMap.size());

            // ✅ Forward to Home.jsp
            RequestDispatcher rd = request.getRequestDispatcher("Home.jsp");
            rd.forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
