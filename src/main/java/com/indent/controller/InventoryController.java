package com.indent.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil;
import com.google.gson.Gson;
import com.indent.bean.InventoryBean;

@WebServlet("/inventory/items")
public class InventoryController extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Please sign in to view inventory.");
            return;
        }

        String branch = (String) session.getAttribute("branch");
        List<InventoryBean> inventory = new ArrayList<>();
        String sql = "SELECT im.Item_id, im.Item_name, im.UOM, COALESCE(s.balance_qty, 0) AS available_qty, "
                + "COALESCE(s.last_price, 0) AS price "
                + "FROM item_master im LEFT JOIN stock s ON s.item_id = im.Item_id "
                + "ORDER BY im.Item_name";

        try (Connection connection = DBUtil.getConnection(branch);
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rows = statement.executeQuery()) {
            while (rows.next()) {
                inventory.add(new InventoryBean(rows.getInt("Item_id"), rows.getString("Item_name"), rows.getString("UOM"),
                        rows.getDouble("available_qty"), rows.getBigDecimal("price")));
            }
        } catch (SQLException ex) {
            getServletContext().log("Could not load indent inventory.", ex);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Inventory could not be loaded.");
            return;
        }

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");
        response.getWriter().write(gson.toJson(inventory));
    }
}
