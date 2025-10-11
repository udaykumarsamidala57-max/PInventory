package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

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
        String deptSession = (String) sess.getAttribute("department");
        String selectedDept = request.getParameter("selectedDept");

        try (Connection con = DBUtil.getConnection()) {

            // ===== Next Indent Number =====
            int nextIndentNo = 1;
            String sqlNext = "SELECT COALESCE(MAX(CAST(indent_no AS UNSIGNED)),0)+1 AS next_no FROM indent";
            try (PreparedStatement ps = con.prepareStatement(sqlNext);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) nextIndentNo = rs.getInt("next_no");
            }
            request.setAttribute("nextIndentNo", nextIndentNo);

            // ===== Master Data Map =====
            Map<String, Object> masterData = new HashMap<>();

            // ===== Departments =====
            List<Map<String, String>> departments = new ArrayList<>();
            String deptSql;

            if ("Global".equalsIgnoreCase(role) || "Global".equalsIgnoreCase(deptSession)) {
                deptSql = "SELECT DISTINCT Department FROM dept_cate WHERE Department IS NOT NULL AND Department<>'' ORDER BY Department";
                try (PreparedStatement ps = con.prepareStatement(deptSql);
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, String> d = new HashMap<>();
                        d.put("name", rs.getString("Department"));
                        departments.add(d);
                    }
                }
            } else {
                if (deptSession != null && !deptSession.trim().isEmpty()) {
                    String validateDept = "SELECT Department FROM dept_cate WHERE Department = ? LIMIT 1";
                    try (PreparedStatement ps = con.prepareStatement(validateDept)) {
                        ps.setString(1, deptSession.trim());
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                Map<String, String> d = new HashMap<>();
                                d.put("name", rs.getString("Department"));
                                departments.add(d);
                            } else {
                                Map<String, String> d = new HashMap<>();
                                d.put("name", deptSession.trim());
                                departments.add(d);
                            }
                        }
                    }
                }
            }

            // ===== Categories =====
            List<Map<String, String>> categories = new ArrayList<>();
            String catSql;
            PreparedStatement psCat;

            if ("Global".equalsIgnoreCase(role) || "Global".equalsIgnoreCase(deptSession)) {
                // Global user → Load all categories
                catSql = "SELECT DISTINCT Category, Department FROM dept_cate WHERE Category IS NOT NULL AND Category<>'' ORDER BY Department, Category";
                psCat = con.prepareStatement(catSql);
            } else if (selectedDept != null && !selectedDept.trim().isEmpty()) {
                catSql = "SELECT DISTINCT Category, Department FROM dept_cate WHERE Department = ? AND Category IS NOT NULL AND Category<>''";
                psCat = con.prepareStatement(catSql);
                psCat.setString(1, selectedDept.trim());
            } else if (deptSession != null && !deptSession.trim().isEmpty()) {
                catSql = "SELECT DISTINCT Category, Department FROM dept_cate WHERE Department = ? AND Category IS NOT NULL AND Category<>''";
                psCat = con.prepareStatement(catSql);
                psCat.setString(1, deptSession.trim());
            } else {
                catSql = "SELECT DISTINCT Category, Department FROM dept_cate WHERE Category IS NOT NULL AND Category<>''";
                psCat = con.prepareStatement(catSql);
            }

            try (ResultSet rs = psCat.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> c = new HashMap<>();
                    c.put("name", rs.getString("Category"));
                    c.put("departmentName", rs.getString("Department"));
                    categories.add(c);
                }
            }

            // ===== Subcategories =====
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

            // ===== Items =====
            List<Map<String, String>> items = new ArrayList<>();
            String itemSql = "SELECT Item_id, Item_name, UOM, Category, Sub_Category FROM item_master";
            try (PreparedStatement ps = con.prepareStatement(itemSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> i = new HashMap<>();
                    i.put("id", String.valueOf(rs.getInt("Item_id")));
                    i.put("name", rs.getString("Item_name"));
                    i.put("UOM", rs.getString("UOM"));
                    i.put("category", rs.getString("Category"));
                    i.put("subcategory", rs.getString("Sub_Category"));
                    items.add(i);
                }
            }

            // ===== Attach All =====
            masterData.put("departments", departments);
            masterData.put("categories", categories);
            masterData.put("subcategories", subcats);
            masterData.put("items", items);

            request.setAttribute("masterData", masterData);
            request.setAttribute("selectedDept", selectedDept);
            request.getRequestDispatcher("indent.jsp").forward(request, response);

        } catch (SQLException e) {
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
        String date = request.getParameter("date");
        String department = request.getParameter("department");
        String indentedBy = user;

        String[] itemIds = splitSafe(request.getParameter("itemIds"));
        String[] itemNames = splitSafe(request.getParameter("itemNames"));
        String[] quantities = splitSafe(request.getParameter("quantities"));
        String[] purposes = splitSafe(request.getParameter("purposes"));
        String[] uoms = splitSafe(request.getParameter("uoms"));

        List<IndentItem> items = new ArrayList<>();
        for (int i = 0; i < itemNames.length; i++) {
            try {
                String idStr = itemIds.length > i ? itemIds[i].trim() : "";
                String qtyStr = quantities.length > i ? quantities[i].trim() : "";
                if (idStr.isEmpty() || qtyStr.isEmpty()) continue;

                int id = Integer.parseInt(idStr);
                double qty = Double.parseDouble(qtyStr);
                String name = itemNames[i] != null ? itemNames[i].trim() : "";
                String purp = purposes.length > i && purposes[i] != null ? purposes[i].trim() : "";
                String uom = uoms.length > i && uoms[i] != null ? uoms[i].trim() : "";

                if (name.isEmpty() || qty <= 0) continue;
                items.add(new IndentItem(id, name, qty, purp, uom));
            } catch (Exception ignored) {}
        }

        if (indentNumber == null || indentNumber.trim().isEmpty()) {
            request.setAttribute("message", "Indent Number is required.");
            doGet(request, response);
            return;
        }
        if (items.isEmpty()) {
            request.setAttribute("message", "At least one valid item is required.");
            doGet(request, response);
            return;
        }

        try (Connection con = DBUtil.getConnection()) {
            con.setAutoCommit(false);
            try {
                // Check duplicate
                String dupSql = "SELECT COUNT(*) FROM indent WHERE indent_no = ?";
                try (PreparedStatement ps = con.prepareStatement(dupSql)) {
                    ps.setString(1, indentNumber);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0) {
                            request.setAttribute("message", "Indent Number already exists!");
                            con.rollback();
                            doGet(request, response);
                            return;
                        }
                    }
                }

                // Insert
                String insertSql = "INSERT INTO indent(indent_no, indent_date, item_id, item_name, qty, department, requested_by, purpose, remarks, uom) VALUES(?,?,?,?,?,?,?,?,?,?)";
                try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                    for (IndentItem it : items) {
                        ps.setString(1, indentNumber);
                        ps.setString(2, date);
                        ps.setInt(3, it.getItemId());
                        ps.setString(4, it.getName());
                        ps.setDouble(5, it.getQty());
                        ps.setString(6, department);
                        ps.setString(7, indentedBy);
                        ps.setString(8, it.getPurpose());
                        ps.setString(9, user);
                        ps.setString(10, it.getUom());
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }

                con.commit();
                request.setAttribute("message", "Indent saved successfully! Items added: " + items.size());
            } catch (SQLException e) {
                con.rollback();
                request.setAttribute("message", "Error while saving indent (DB): " + e.getMessage());
            } finally {
                con.setAutoCommit(true);
            }

        } catch (SQLException e) {
            request.setAttribute("message", "Error while saving indent: " + e.getMessage());
        }

        doGet(request, response);
    }

    private String[] splitSafe(String s) {
        return (s != null && !s.isEmpty()) ? s.split(",") : new String[0];
    }
}
