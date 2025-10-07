package com.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil;
import com.bean.IndentItem;

@WebServlet("/IndentServlet")
public class IndentServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");
        String user = (String) sess.getAttribute("username");

        try (Connection con = DBUtil.getConnection()) {

            // ===== Next Indent Number =====
            int nextIndentNo = 1;
            String sqlNext = "SELECT COALESCE(MAX(CAST(indent_no AS UNSIGNED)),0)+1 AS next_no FROM indent";
            try (PreparedStatement ps = con.prepareStatement(sqlNext);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    nextIndentNo = rs.getInt("next_no");
                }
            }
            request.setAttribute("nextIndentNo", nextIndentNo);

            // ===== Master Data =====
            Map<String, Object> masterData = new HashMap<>();

            List<Map<String,String>> departments = new ArrayList<>();
            try (Statement stmt = con.createStatement()) {
                String deptQuery;
                if ("Global".equalsIgnoreCase(role)) {
                    deptQuery = "SELECT DISTINCT Department FROM dept_cate";
                } else {
                    deptQuery = "SELECT DISTINCT Department FROM dept_cate WHERE role='" + role + "'";
                }
                try (ResultSet rs = stmt.executeQuery(deptQuery)) {
                    while (rs.next()) {
                        Map<String,String> d = new HashMap<>();
                        d.put("name", rs.getString("Department"));
                        departments.add(d);
                    }
                }
            }

            // Categories
            List<Map<String,String>> categories = new ArrayList<>();
            try (Statement stmt = con.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT DISTINCT Category, Department FROM dept_cate")) {
                while (rs.next()) {
                    Map<String,String> c = new HashMap<>();
                    c.put("name", rs.getString("Category"));
                    c.put("departmentName", rs.getString("Department"));
                    categories.add(c);
                }
            }

            // Subcategories
            List<Map<String,String>> subcats = new ArrayList<>();
            try (Statement stmt = con.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT Sub_Category, Category FROM category WHERE Status='Active'")) {
                while (rs.next()) {
                    Map<String,String> s = new HashMap<>();
                    s.put("name", rs.getString("Sub_Category"));
                    s.put("categoryName", rs.getString("Category"));
                    subcats.add(s);
                }
            }

            // Items
            List<Map<String,String>> items = new ArrayList<>();
            try (Statement stmt = con.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT Item_id, Item_name, UOM, Category, Sub_Category FROM item_master")) {
                while (rs.next()) {
                    Map<String,String> i = new HashMap<>();
                    i.put("id", String.valueOf(rs.getInt("Item_id")));
                    i.put("name", rs.getString("Item_name"));
                    i.put("UOM", rs.getString("UOM"));
                    i.put("category", rs.getString("Category"));
                    i.put("subcategory", rs.getString("Sub_Category"));
                    items.add(i);
                }
            }

            masterData.put("departments", departments);
            masterData.put("categories", categories);
            masterData.put("subcategories", subcats);
            masterData.put("items", items);

            request.setAttribute("masterData", masterData);
            request.getRequestDispatcher("indent.jsp").forward(request, response);

        } catch (Exception e) {
            throw new ServletException("DB Error (GET): " + e.getMessage(), e);
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
        String date        = request.getParameter("date");
        String department  = request.getParameter("department");
        String indentedBy  = user;

        String[] itemIds    = splitSafe(request.getParameter("itemIds"));
        String[] itemNames  = splitSafe(request.getParameter("itemNames"));
        String[] quantities = splitSafe(request.getParameter("quantities"));
        String[] purposes   = splitSafe(request.getParameter("purposes"));
        String[] uoms       = splitSafe(request.getParameter("uoms"));

        List<IndentItem> items = new ArrayList<>();
        for (int i = 0; i < itemNames.length; i++) {
            try {
                int id = Integer.parseInt(itemIds[i].trim());
                // ✅ FIX: allow decimal quantities
                double qty = Double.parseDouble(quantities[i].trim());
                items.add(new IndentItem(id,itemNames[i].trim(),
                        qty,
                        purposes[i].trim(),
                        uoms[i].trim()
                ));
            } catch (Exception ignored) { }
        }

        try (Connection con = DBUtil.getConnection()) {

            // Check duplicate indent number
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM indent WHERE indent_no=?")) {
                ps.setString(1, indentNumber);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    if (rs.getInt(1) > 0) {
                        request.setAttribute("message", "Indent Number already exists!");
                        doGet(request, response);
                        return;
                    }
                }
            }

            // Insert items
            String sql = "INSERT INTO indent(indent_no, indent_date, item_id, item_name, qty, department," +
                    "requested_by, purpose, remarks, uom) VALUES(?,?,?,?,?,?,?,?,?,?)";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                for (IndentItem it : items) {
                    ps.setString(1, indentNumber);
                    ps.setString(2, date);
                    ps.setInt(3, it.getItemId());
                    ps.setString(4, it.getName());
                    ps.setDouble(5, it.getQty());   // ✅ this now accepts decimal
                    ps.setString(6, department);
                    ps.setString(7, indentedBy);
                    ps.setString(8, it.getPurpose());
                    ps.setString(9, user); // remarks is current user
                    ps.setString(10, it.getUom());
                    ps.addBatch();
                }
                ps.executeBatch();
            }

            request.setAttribute("message",
                    "Indent saved successfully! Items added: " + items.size());

        } catch (Exception e) {
            request.setAttribute("message", "Error while saving indent: " + e.getMessage());
        }

        doGet(request, response);
    }

    private String[] splitSafe(String s) {
        return (s != null && !s.isEmpty()) ? s.split(",") : new String[0];
    }
}
