package com.controller;

import java.io.IOException;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

@WebServlet("/DHConsume")
public class DHConsume extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        try (Connection con = DBUtil.getConnection()) {

            // === Next Indent Number ===
            int nextIndentNo = 1;
            String sqlNext = "SELECT COALESCE(MAX(CAST(indent_no AS UNSIGNED)),0)+1 AS next_no FROM indent";
            try (PreparedStatement ps = con.prepareStatement(sqlNext);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) nextIndentNo = rs.getInt("next_no");
            }
            request.setAttribute("nextIndentNo", nextIndentNo);

            // === Categories for Dining Hall ===
            List<Map<String, String>> categories = new ArrayList<>();
            String catSql = "SELECT DISTINCT Category FROM dept_cate WHERE Department='Dining Hall' AND Category<>''";
            try (PreparedStatement ps = con.prepareStatement(catSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> c = new HashMap<>();
                    c.put("name", rs.getString("Category"));
                    categories.add(c);
                }
            }

            // === Subcategories ===
            List<Map<String, String>> subcats = new ArrayList<>();
            String subSql = "SELECT Sub_Category, Category FROM category WHERE Status='Active'";
            try (PreparedStatement ps = con.prepareStatement(subSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> s = new HashMap<>();
                    s.put("name", rs.getString("Sub_Category"));
                    s.put("categoryName", rs.getString("Category"));
                    subcats.add(s);
                }
            }

            // === Items ===
            List<Map<String, String>> items = new ArrayList<>();
            String itemSql =
                    "SELECT im.Item_id, im.Item_name, im.UOM, im.Category, im.Sub_Category, " +
                    "COALESCE(s.balance_qty, 0) AS stock " +
                    "FROM item_master im " +
                    "LEFT JOIN stock s ON im.Item_id = s.item_id " +
                    "WHERE im.Category IN (SELECT DISTINCT Category FROM dept_cate WHERE Department='Dining Hall')";
            try (PreparedStatement ps = con.prepareStatement(itemSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> i = new HashMap<>();
                    i.put("id", String.valueOf(rs.getInt("Item_id")));
                    i.put("name", rs.getString("Item_name"));
                    i.put("UOM", rs.getString("UOM"));
                    i.put("category", rs.getString("Category"));
                    i.put("subcategory", rs.getString("Sub_Category"));
                    i.put("stock", rs.getString("stock"));
                    items.add(i);
                }
            }

            request.setAttribute("categories", categories);
            request.setAttribute("subcategories", subcats);
            request.setAttribute("items", items);
            request.setAttribute("nextIndentNo", nextIndentNo);

            request.getRequestDispatcher("DHConsume.jsp").forward(request, response);

        } catch (SQLException e) {
            throw new ServletException("DB Error: " + e.getMessage(), e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String user = (String) sess.getAttribute("username");
        String indentNumber = request.getParameter("indentNumber");
        String date = request.getParameter("date");

        if (date == null || date.trim().isEmpty()) {
            date = new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
        }

        String[] itemIds = request.getParameter("itemIds").split(",");
        String[] itemNames = request.getParameter("itemNames").split(",");
        String[] quantities = request.getParameter("quantities").split(",");
        String[] purposes = request.getParameter("purposes").split(",");
        String[] uoms = request.getParameter("uoms").split(",");

        try (Connection con = DBUtil.getConnection()) {
            con.setAutoCommit(false);

            String insertSql = "INSERT INTO indent(indent_no, indent_date, item_id, item_name, qty, department, requested_by, purpose, uom, Istatus, IstausApprove, Iapprovedate, status, Fapprovedate, Indentnext, POStatus, Issued_status) " +
                    "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
            try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                String today = new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
                for (int i = 0; i < itemIds.length; i++) {
                    if (itemNames[i].trim().isEmpty() || quantities[i].trim().isEmpty()) continue;
                    ps.setString(1, indentNumber);
                    ps.setString(2, date);
                    ps.setInt(3, Integer.parseInt(itemIds[i]));
                    ps.setString(4, itemNames[i]);
                    ps.setDouble(5, Double.parseDouble(quantities[i]));
                    ps.setString(6, "Dining Hall");
                    ps.setString(7, user);
                    ps.setString(8, purposes[i]);
                    ps.setString(9, uoms[i]);
                    ps.setString(10, "Approved");
                    ps.setString(11, "Approved");
                    ps.setString(12, today);
                    ps.setString(13, "Approved");
                    ps.setString(14, today);
                    ps.setString(15, "Issue");
                    ps.setString(16, null);
                    ps.setString(17, "Pending");
                    ps.addBatch();
                }
                ps.executeBatch();
            }

            con.commit();
            request.setAttribute("message", "✅ Dining Hall Indent saved successfully!");
        } catch (SQLException e) {
            request.setAttribute("message", "❌ Database error: " + e.getMessage());
        }

        doGet(request, response);
    }
}
