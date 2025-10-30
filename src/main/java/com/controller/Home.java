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

        int istatusPending = 0;
        int statusPending = 0;
        Map<String, Integer> deptPendingMap = new LinkedHashMap<>();
        Map<String, Integer> nextStageCountMap = new LinkedHashMap<>();
        Map<String, Integer> totalDeptMap = new LinkedHashMap<>();

        String costliestItem = "N/A", costliestCategory = "";
        double maxPrice = 0.0;
        String maxQtyItem = "N/A", maxQtyCategory = "";
        double maxQty = 0.0;
        List<Map<String, Object>> topCostliest = new ArrayList<>();
        List<Map<String, Object>> topQty = new ArrayList<>();

        try (Connection con = DBUtil.getConnection()) {

            // ----- Pending at In-charge -----
            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM indent WHERE Istatus='Pending'");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) istatusPending = rs.getInt(1);
            }

            // ----- Pending at Secretary -----
            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM indent WHERE status='Pending'");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) statusPending = rs.getInt(1);
            }

            // ----- Pending by Department -----
            String query3 = "SELECT department, COUNT(*) AS pending_count FROM indent " +
                            "WHERE status='Pending' OR Istatus='Pending' GROUP BY department ORDER BY department";
            try (PreparedStatement ps = con.prepareStatement(query3);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    deptPendingMap.put(rs.getString("department"), rs.getInt("pending_count"));
                }
            }

            // ----- Total Indents by Department -----
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT department, COUNT(*) AS totalCount FROM indent GROUP BY department ORDER BY department");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    totalDeptMap.put(rs.getString("department"), rs.getInt("totalCount"));
                }
            }

            // ----- Count by Stage -----
            String stageQuery = "SELECT IFNULL(Indentnext,'') AS stage, COUNT(*) AS cnt FROM indent GROUP BY Indentnext";
            try (PreparedStatement ps = con.prepareStatement(stageQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String stage = rs.getString("stage").trim();
                    int count = rs.getInt("cnt");
                    switch (stage) {
                        case "": stage = "Approval-Pending"; break;
                        case "PO": stage = "PO"; break;
                        case "Issue": stage = "Issue Pending"; break;
                        case "Issued": stage = "Issued"; break;
                        case "Management Note": stage = "Management Note"; break;
                        default: stage = "Others"; break;
                    }
                    nextStageCountMap.put(stage, nextStageCountMap.getOrDefault(stage, 0) + count);
                }
            }
            for (String s : new String[]{"Approval-Pending","PO","Issue Pending","Issued","Management Note"})
                nextStageCountMap.putIfAbsent(s, 0);

            // ✅ Costliest single item
            String costliestQuery = "SELECT i.Item_name, i.Category, s.last_price " +
                                    "FROM stock s JOIN item_master i ON s.item_id=i.Item_id " +
                                    "ORDER BY s.last_price DESC LIMIT 1";
            try (PreparedStatement ps = con.prepareStatement(costliestQuery);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    costliestItem = rs.getString("Item_name");
                    costliestCategory = rs.getString("Category");
                    maxPrice = rs.getDouble("last_price");
                }
            }

            // ✅ Highest stock single item
            String qtyQuery = "SELECT i.Item_name, i.Category, s.balance_qty " +
                              "FROM stock s JOIN item_master i ON s.item_id=i.Item_id " +
                              "ORDER BY s.balance_qty DESC LIMIT 1";
            try (PreparedStatement ps = con.prepareStatement(qtyQuery);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    maxQtyItem = rs.getString("Item_name");
                    maxQtyCategory = rs.getString("Category");
                    maxQty = rs.getDouble("balance_qty");
                }
            }

            // ✅ Top 5 costliest
            String topCostliestQuery = "SELECT i.Item_name, i.Category, s.last_price " +
                                       "FROM stock s JOIN item_master i ON s.item_id=i.Item_id " +
                                       "ORDER BY s.last_price DESC LIMIT 5";
            try (PreparedStatement ps = con.prepareStatement(topCostliestQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("Item_name", rs.getString("Item_name"));
                    row.put("Category", rs.getString("Category"));
                    row.put("last_price", rs.getDouble("last_price"));
                    topCostliest.add(row);
                }
            }

            // ✅ Top 5 highest quantity
            String topQtyQuery = "SELECT i.Item_name, i.Category, s.balance_qty " +
                                 "FROM stock s JOIN item_master i ON s.item_id=i.Item_id " +
                                 "ORDER BY s.balance_qty DESC LIMIT 5";
            try (PreparedStatement ps = con.prepareStatement(topQtyQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("Item_name", rs.getString("Item_name"));
                    row.put("Category", rs.getString("Category"));
                    row.put("balance_qty", rs.getDouble("balance_qty"));
                    topQty.add(row);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        // ----- Attributes for JSP -----
        request.setAttribute("istatusPending", istatusPending);
        request.setAttribute("statusPending", statusPending);
        request.setAttribute("deptPendingMap", deptPendingMap);
        request.setAttribute("totalDeptMap", totalDeptMap);
        request.setAttribute("nextStageCountMap", nextStageCountMap);

        request.setAttribute("costliestItem", costliestItem);
        request.setAttribute("costliestCategory", costliestCategory);
        request.setAttribute("maxPrice", maxPrice);
        request.setAttribute("maxQtyItem", maxQtyItem);
        request.setAttribute("maxQtyCategory", maxQtyCategory);
        request.setAttribute("maxQty", maxQty);

        request.setAttribute("topCostliest", topCostliest);
        request.setAttribute("topQty", topQty);

        RequestDispatcher rd = request.getRequestDispatcher("Home.jsp");
        rd.forward(request, response);
    }
}
