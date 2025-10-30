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

        try (Connection con = DBUtil.getConnection()) {

            // ✅ Department Pending
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT department, COUNT(*) AS pending_count FROM indent " +
                    "WHERE status='Pending' OR Istatus='Pending' GROUP BY department ORDER BY department");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) deptPendingMap.put(rs.getString(1), rs.getInt(2));
            }

            // ✅ Total Indents by Department
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT department, COUNT(*) AS totalCount FROM indent GROUP BY department ORDER BY department");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) totalDeptMap.put(rs.getString(1), rs.getInt(2));
            }

            // ✅ Indent Stage Counts
            String stageQuery = "SELECT IFNULL(Indentnext,'') AS stage, COUNT(*) FROM indent GROUP BY Indentnext";
            try (PreparedStatement ps = con.prepareStatement(stageQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String stage = rs.getString(1).trim();
                    int cnt = rs.getInt(2);
                    switch (stage) {
                        case "": stage="Approval-Pending"; break;
                        case "PO": stage="PO"; break;
                        case "Issue": stage="Issue Pending"; break;
                        case "Issued": stage="Issued"; break;
                        case "Management Note": stage="Management Note"; break;
                        default: stage="Others"; break;
                    }
                    nextStageCountMap.put(stage, nextStageCountMap.getOrDefault(stage,0)+cnt);
                }
            }
            for(String s:new String[]{"Approval-Pending","PO","Issue Pending","Issued","Management Note"})
                nextStageCountMap.putIfAbsent(s,0);

            // ✅ Top 5 costliest items overall (not category-wise)
            String topCostliestQuery = 
                "SELECT i.Category, i.Item_name, s.last_price " +
                "FROM stock s JOIN item_master i ON s.item_id=i.Item_id " +
                "ORDER BY s.last_price DESC LIMIT 5";
            try (PreparedStatement ps = con.prepareStatement(topCostliestQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String,Object> row = new LinkedHashMap<>();
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
                    Map<String,Object> row = new LinkedHashMap<>();
                    row.put("Item_name", rs.getString("Item_name"));
                    row.put("Category", rs.getString("Category"));
                    row.put("balance_qty", rs.getDouble("balance_qty"));
                    topQty.add(row);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        // ✅ Set attributes for JSP
        request.setAttribute("deptPendingMap", deptPendingMap);
        request.setAttribute("totalDeptMap", totalDeptMap);
        request.setAttribute("nextStageCountMap", nextStageCountMap);
        request.setAttribute("topCostliest", topCostliest);
        request.setAttribute("topQty", topQty);

        RequestDispatcher rd = request.getRequestDispatcher("Home.jsp");
        rd.forward(request, response);
    }
}
