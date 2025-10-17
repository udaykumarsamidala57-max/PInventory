package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

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
            String sql = "INSERT INTO stock (item_id, total_received, total_issued, balance_qty, last_updated) "
                       + "VALUES (?, ?, 0.00, ?, CURRENT_TIMESTAMP)";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                for (int i = 0; i < idsArr.length; i++) {
                    ps.setInt(1, Integer.parseInt(idsArr[i]));
                    ps.setBigDecimal(2, new java.math.BigDecimal(qtyArr[i]));
                    ps.setBigDecimal(3, new java.math.BigDecimal(qtyArr[i]));
                    ps.addBatch();
                }
                ps.executeBatch();
            }

            request.setAttribute("message", "Stock added successfully!");
            response.sendRedirect("AddStock"); // reload the page
        } catch (SQLException e) {
            throw new ServletException("Error inserting stock: " + e.getMessage(), e);
        }
    }
}
