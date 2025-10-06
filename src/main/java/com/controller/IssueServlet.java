package com.controller;

import com.bean.DBUtil;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet("/IssueServlet")
public class IssueServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String issueno = request.getParameter("issueno");
        String issuedTo = request.getParameter("issuedTo");
        String remarks = request.getParameter("remarks");

        String[] itemIds = request.getParameter("itemIds").split(",");
        String[] quantities = request.getParameter("quantities").split(",");

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        try (Connection con = DBUtil.getConnection()) {
            con.setAutoCommit(false);

            for (int i = 0; i < itemIds.length; i++) {
                int itemId = Integer.parseInt(itemIds[i].trim());
                double qtyIssued = Double.parseDouble(quantities[i].trim());

                // === Check available qty ===
                double available = 0;
                String sqlCheck = "SELECT balance_qty FROM stock WHERE item_id=?";
                try (PreparedStatement ps = con.prepareStatement(sqlCheck)) {
                    ps.setInt(1, itemId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            available = rs.getDouble("balance_qty");
                        }
                    }
                }

                if (qtyIssued > available) {
                    throw new Exception("Insufficient stock for Item ID " + itemId +
                            ". Available: " + available + ", Requested: " + qtyIssued);
                }

                // === Insert into stock_issues ===
                String sqlIssue = "INSERT INTO stock_issues (issueno, item_id, issued_to, qty_issued, remarks) " +
                        "VALUES (?, ?, ?, ?, ?)";
                try (PreparedStatement ps = con.prepareStatement(sqlIssue)) {
                    ps.setString(1, issueno);
                    ps.setInt(2, itemId);
                    ps.setString(3, issuedTo);
                    ps.setDouble(4, qtyIssued);
                    ps.setString(5, remarks);
                    ps.executeUpdate();
                }

                // === Update stock table ===
                String sqlUpdateStock = "UPDATE stock SET total_issued = total_issued + ?, " +
                        "balance_qty = balance_qty - ?, last_updated = CURRENT_TIMESTAMP WHERE item_id = ?";
                try (PreparedStatement ps = con.prepareStatement(sqlUpdateStock)) {
                    ps.setDouble(1, qtyIssued);
                    ps.setDouble(2, qtyIssued);
                    ps.setInt(3, itemId);
                    ps.executeUpdate();
                }

                // === Insert into stock_ledger ===
                String sqlLedger = "INSERT INTO stock_ledger (item_id, trans_type, trans_id, qty, running_balance, remarks, trans_date) " +
                        "VALUES (?, 'ISSUE', ?, ?, " +
                        "(SELECT balance_qty FROM stock WHERE item_id = ?), ?, NOW())";
                try (PreparedStatement ps = con.prepareStatement(sqlLedger)) {
                    ps.setInt(1, itemId);
                    ps.setString(2, issueno);
                    ps.setDouble(3, qtyIssued);
                    ps.setInt(4, itemId);
                    ps.setString(5, remarks);
                    ps.executeUpdate();
                }
            }

            con.commit();
            request.setAttribute("message", "✅ Stock issued successfully under Issue No: " + issueno);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("message", "❌ Error while issuing stock: " + e.getMessage());
        }

        request.getRequestDispatcher("issue.jsp").forward(request, response);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try (Connection con = DBUtil.getConnection()) {
            // === Load next Issue No ===
            String nextNo = "1";
            String sql = "SELECT COALESCE(MAX(CAST(issueno AS UNSIGNED)),0)+1 AS next_no FROM stock_issues";
            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    nextNo = rs.getString("next_no");
                }
            }

            // === Load Active Categories ===
            List<String> categories = new ArrayList<>();
            try (PreparedStatement ps = con.prepareStatement("SELECT DISTINCT Category FROM item_master");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    categories.add(rs.getString("Category"));
                }
            }

            // === Load Items with available balance ===
            List<Map<String, String>> items = new ArrayList<>();
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT im.Item_id, im.Item_name, im.UOM, im.Category, im.Sub_Category, " +
                            "COALESCE(s.balance_qty,0) AS available_qty " +
                            "FROM item_master im " +
                            "LEFT JOIN stock s ON im.Item_id = s.item_id")) {
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, String> i = new HashMap<>();
                        i.put("id", String.valueOf(rs.getInt("Item_id")));
                        i.put("name", rs.getString("Item_name"));
                        i.put("UOM", rs.getString("UOM"));
                        i.put("category", rs.getString("Category"));
                        i.put("subcategory", rs.getString("Sub_Category"));
                        i.put("available", String.valueOf(rs.getDouble("available_qty")));
                        items.add(i);
                    }
                }
            }

            request.setAttribute("nextIssueNo", nextNo);
            request.setAttribute("categories", categories);
            request.setAttribute("items", items);

            request.getRequestDispatcher("issue.jsp").forward(request, response);
        } catch (Exception e) {
            throw new ServletException("DB Error (GET): " + e.getMessage(), e);
        }
    }
}
