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
        String deptSession = (String) sess.getAttribute("department");
        String selectedDept = request.getParameter("selectedDept");

        try (Connection con = DBUtil.getConnection()) {

            int nextIndentNo = 1;
            String sqlNext = "SELECT next_val + 1 AS next_no FROM id_sequences WHERE seq_name = 'indent_no'";
            try (PreparedStatement ps = con.prepareStatement(sqlNext);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    nextIndentNo = rs.getInt("next_no");
                } else {
                    String sqlFallback = "SELECT COALESCE(MAX(CAST(indent_no AS UNSIGNED)),0)+1 FROM indent";
                    try (Statement st = con.createStatement();
                         ResultSet rs2 = st.executeQuery(sqlFallback)) {
                        if (rs2.next()) nextIndentNo = rs2.getInt(1);
                    }
                }
            }
            request.setAttribute("nextIndentNo", nextIndentNo);

            Map<String, Object> masterData = new HashMap<>();

            List<Map<String, String>> departments = new ArrayList<>();
            if ("Global".equalsIgnoreCase(role)) {
                String deptSql = "SELECT DISTINCT Department FROM dept_cate WHERE Department IS NOT NULL AND Department<>''";
                try (PreparedStatement ps = con.prepareStatement(deptSql);
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, String> d = new HashMap<>();
                        d.put("name", rs.getString("Department"));
                        departments.add(d);
                    }
                }
            } else if (deptSession != null && !deptSession.trim().isEmpty()) {
                Map<String, String> d = new HashMap<>();
                d.put("name", deptSession.trim());
                departments.add(d);
            }

            List<Map<String, String>> categories = new ArrayList<>();
            String catSql = "SELECT DISTINCT Category, Department FROM dept_cate WHERE Category IS NOT NULL AND Category<>''";
            try (PreparedStatement ps = con.prepareStatement(catSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> c = new HashMap<>();
                    c.put("name", rs.getString("Category"));
                    c.put("departmentName", rs.getString("Department"));
                    categories.add(c);
                }
            }

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

            List<Map<String, String>> items = new ArrayList<>();
            String itemSql =
                    "SELECT im.Item_id, im.Item_name, im.UOM, im.Category, im.Sub_Category, " +
                    "COALESCE(s.balance_qty,0) AS stock " +
                    "FROM item_master im LEFT JOIN stock s ON im.Item_id = s.item_id";

            try (PreparedStatement ps = con.prepareStatement(itemSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> i = new HashMap<>();
                    i.put("id", rs.getString("Item_id"));
                    i.put("name", rs.getString("Item_name"));
                    i.put("UOM", rs.getString("UOM"));
                    i.put("category", rs.getString("Category"));
                    i.put("subcategory", rs.getString("Sub_Category"));
                    i.put("stock", rs.getString("stock"));
                    items.add(i);
                }
            }

            masterData.put("departments", departments);
            masterData.put("categories", categories);
            masterData.put("subcategories", subcats);
            masterData.put("items", items);

            request.setAttribute("masterData", masterData);
            request.setAttribute("selectedDept", selectedDept);
            request.getRequestDispatcher("indent.jsp").forward(request, response);

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
        String role = (String) sess.getAttribute("role");
        String deptSession = (String) sess.getAttribute("department");

        String date = request.getParameter("date");
        String department = request.getParameter("department");
        String indentType = request.getParameter("indentType");

        if (!"Global".equalsIgnoreCase(role) && (department == null || department.trim().isEmpty())) {
            department = deptSession;
        }

        String[] itemIds = splitSafe(request.getParameter("itemIds"));
        String[] itemNames = splitSafe(request.getParameter("itemNames"));
        String[] quantities = splitSafe(request.getParameter("quantities"));
        String[] purposes = splitSafe(request.getParameter("purposes"));
        String[] uoms = splitSafe(request.getParameter("uoms"));

        List<IndentItem> itemsList = new ArrayList<>();
        for (int i = 0; i < itemNames.length; i++) {
            try {
                int id = Integer.parseInt(itemIds[i]);
                double qty = Double.parseDouble(quantities[i]);
                if (qty <= 0) continue;

                itemsList.add(new IndentItem(
                        id,
                        itemNames[i],
                        qty,
                        purposes.length > i ? purposes[i] : "",
                        uoms.length > i ? uoms[i] : ""
                ));
            } catch (Exception ignored) {}
        }

        if (itemsList.isEmpty()) {
            sess.setAttribute("message", "❌ Error: At least one valid item is required.");
            response.sendRedirect("IndentServlet");
            return;
        }

        Connection con = null;
        String finalIndentNo = "";

        try {
            con = DBUtil.getConnection();
            con.setAutoCommit(false);

            con.prepareStatement(
                    "UPDATE id_sequences SET next_val = next_val + 1 WHERE seq_name='indent_no'"
            ).executeUpdate();

            ResultSet rs = con.prepareStatement(
                    "SELECT next_val FROM id_sequences WHERE seq_name='indent_no'"
            ).executeQuery();

            if (rs.next()) finalIndentNo = rs.getString(1);

            String insertSql =
                "INSERT INTO indent (" +
                "indent_no, indent_date, item_id, item_name, qty, department, requested_by," +
                "purpose, remarks, uom, PurchaseorIssue, stock" +
                ") VALUES (?,?,?,?,?,?,?,?,?,?,?, " +
                "(SELECT COALESCE(balance_qty,0) FROM stock WHERE stock.item_id = ?))";

            try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                for (IndentItem it : itemsList) {
                    ps.setString(1, finalIndentNo);
                    ps.setString(2, date);
                    ps.setInt(3, it.getItemId());
                    ps.setString(4, it.getName());
                    ps.setDouble(5, it.getQty());
                    ps.setString(6, department);
                    ps.setString(7, user);
                    ps.setString(8, it.getPurpose());
                    ps.setString(9, "");
                    ps.setString(10, it.getUom());
                    ps.setString(11, indentType);
                    ps.setInt(12, it.getItemId()); // for stock subquery
                    ps.addBatch();
                }
                ps.executeBatch();
            }

            con.commit();
            sess.setAttribute("message", "✅ Indent #" + finalIndentNo + " saved successfully!");

        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (SQLException ignored) {}
            sess.setAttribute("message", "❌ Database Error: " + e.getMessage());
        } finally {
            if (con != null) try { con.close(); } catch (SQLException ignored) {}
        }

        response.sendRedirect("Home");
    }

    private String[] splitSafe(String s) {
        return (s != null && !s.isEmpty()) ? s.split(",") : new String[0];
    }
}
