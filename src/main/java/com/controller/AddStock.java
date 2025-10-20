package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import com.bean.DBUtil;
import java.math.BigDecimal;

@WebServlet("/AddStock")
public class AddStock extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        try (Connection con = DBUtil.getConnection()) {

            List<Map<String, String>> items = new ArrayList<>();
            String sql = "SELECT Item_id, Category, Sub_Category, Item_name, UOM FROM item_master";
            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> item = new HashMap<>();
                    item.put("id", String.valueOf(rs.getInt("Item_id")));
                    item.put("category", rs.getString("Category"));
                    item.put("subcategory", rs.getString("Sub_Category"));
                    item.put("name", rs.getString("Item_name"));
                    item.put("UOM", rs.getString("UOM"));
                    items.add(item);
                }
            }

            Map<String, Object> masterData = new HashMap<>();
            masterData.put("items", items);
            request.setAttribute("masterData", masterData);

            request.getRequestDispatcher("Addstock.jsp").forward(request, response);

        } catch (SQLException e) {
            throw new ServletException("Database error: " + e.getMessage(), e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String itemIds = request.getParameter("itemIds");
        String quantities = request.getParameter("quantities");

        String[] idsArr = itemIds.split(",");
        String[] qtyArr = quantities.split(",");

        try (Connection con = DBUtil.getConnection()) {
            con.setAutoCommit(false);

            // 1️⃣ Insert into stock table
            String insertStockSql = "INSERT INTO stock (item_id, total_received, total_issued, balance_qty, last_updated) "
                    + "VALUES (?, ?, 0.00, ?, CURRENT_TIMESTAMP) "
                    + "ON DUPLICATE KEY UPDATE "
                    + "total_received = total_received + VALUES(total_received), "
                    + "balance_qty = balance_qty + VALUES(balance_qty), "
                    + "last_updated = CURRENT_TIMESTAMP";

            // 2️⃣ Insert into stock_ledger
            String insertLedgerSql = "INSERT INTO stock_ledger (item_id, trans_type, qty, trans_date, running_balance, remarks) "
                    + "VALUES (?, 'RECEIPT', ?, CURRENT_DATE, ?, ?)";

            try (PreparedStatement psStock = con.prepareStatement(insertStockSql);
                 PreparedStatement psLedger = con.prepareStatement(insertLedgerSql)) {

                for (int i = 0; i < idsArr.length; i++) {
                    int itemId = Integer.parseInt(idsArr[i]);
                    BigDecimal qty = new BigDecimal(qtyArr[i]);

                    // 🔹 Update stock
                    psStock.setInt(1, itemId);
                    psStock.setBigDecimal(2, qty);
                    psStock.setBigDecimal(3, qty);
                    psStock.addBatch();

                    // 🔹 Get latest running balance for this item
                    BigDecimal newBalance = qty;
                    try (PreparedStatement psGetBalance = con.prepareStatement(
                            "SELECT running_balance FROM stock_ledger WHERE item_id = ? ORDER BY ledger_id DESC LIMIT 1")) {
                        psGetBalance.setInt(1, itemId);
                        try (ResultSet rs = psGetBalance.executeQuery()) {
                            if (rs.next()) {
                                newBalance = rs.getBigDecimal("running_balance").add(qty);
                            }
                        }
                    }

                    // 🔹 Insert ledger record
                    psLedger.setInt(1, itemId);
                    psLedger.setBigDecimal(2, qty);
                    psLedger.setBigDecimal(3, newBalance);
                    psLedger.setString(4, "Stock added manually");
                    psLedger.addBatch();
                }

                psStock.executeBatch();
                psLedger.executeBatch();

                con.commit();
            } catch (SQLException e) {
                con.rollback();
                throw e;
            }

            response.sendRedirect("AddStock?success=1");

        } catch (SQLException e) {
            throw new ServletException("Error inserting stock: " + e.getMessage(), e);
        }
    }
}
