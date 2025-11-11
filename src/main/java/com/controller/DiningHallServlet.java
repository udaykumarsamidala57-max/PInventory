package com.controller;

import java.io.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.sql.*;
import java.util.*;
import com.bean.DBUtil;

@WebServlet("/DiningHallServlet")
public class DiningHallServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        try (Connection con = DBUtil.getConnection()) {
            // ✅ Next issue number
            int nextIssueNo = 1;
            String sqlNext = "SELECT COALESCE(MAX(CAST(SUBSTRING(issueno, 4) AS UNSIGNED)), 0) + 1 AS next_no FROM dining_hall_consumption";
            try (PreparedStatement ps = con.prepareStatement(sqlNext);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) nextIssueNo = rs.getInt("next_no");
            }
            String formattedIssueNo = "ISS" + nextIssueNo;
            request.setAttribute("nextIssueNo", formattedIssueNo);

            // ✅ Fixed department list
            Map<String, Object> masterData = new HashMap<>();
            List<Map<String, String>> departments = new ArrayList<>();
            Map<String, String> singleDept = new HashMap<>();
            singleDept.put("name", "Dining Hall");
            departments.add(singleDept);

            // ✅ Dining Hall Categories
            List<Map<String, String>> categories = new ArrayList<>();
            String catSql = "SELECT DISTINCT Category, Department FROM dept_cate WHERE Department = 'Dining Hall'";
            try (PreparedStatement ps = con.prepareStatement(catSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> c = new HashMap<>();
                    c.put("name", rs.getString("Category"));
                    c.put("departmentName", rs.getString("Department"));
                    categories.add(c);
                }
            }

            // ✅ Active Subcategories
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

            // ✅ Items with stock
            List<Map<String, String>> items = new ArrayList<>();
            String itemSql = "SELECT im.Item_id, im.Item_name, im.UOM, im.Category, im.Sub_Category, COALESCE(s.balance_qty, 0) AS stock " +
                             "FROM item_master im LEFT JOIN stock s ON im.Item_id = s.item_id";
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

            masterData.put("departments", departments);
            masterData.put("categories", categories);
            masterData.put("subcategories", subcats);
            masterData.put("items", items);

            request.setAttribute("masterData", masterData);
            request.setAttribute("selectedDept", "Dining Hall");

            request.getRequestDispatcher("dining_hall_form.jsp").forward(request, response);

        } catch (SQLException e) {
            throw new ServletException("Database Error: " + e.getMessage(), e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String issueno = request.getParameter("issueno");
        String issuedTo = request.getParameter("issued_to");
        String department = "Dining Hall";
        String session = request.getParameter("session");
        String issueDate = request.getParameter("issue_date");

        String[] itemIds = request.getParameterValues("item_id");
        String[] qtys = request.getParameterValues("qty_issued");
        String[] remarksArr = request.getParameterValues("remarks");

        if (itemIds == null || itemIds.length == 0) {
            response.sendRedirect("error.jsp");
            return;
        }

        try (Connection con = DBUtil.getConnection()) {
            con.setAutoCommit(false);

            for (int i = 0; i < itemIds.length; i++) {
                int itemId = Integer.parseInt(itemIds[i]);
                double qtyIssued = Double.parseDouble(qtys[i]);
                String remarks = remarksArr[i];

                double unitPrice = 0.0;
                double currentBalance = 0.0;

                // ✅ Get current stock & price
                try (PreparedStatement psStock = con.prepareStatement(
                        "SELECT COALESCE(balance_qty,0), COALESCE(last_price,0) FROM stock WHERE item_id=?")) {
                    psStock.setInt(1, itemId);
                    try (ResultSet rs = psStock.executeQuery()) {
                        if (rs.next()) {
                            currentBalance = rs.getDouble(1);
                            unitPrice = rs.getDouble(2);
                        }
                    }
                }

                // 🚫 If no stock, skip this item (do not insert anywhere)
                if (currentBalance <= 0) {
                    System.out.println("Skipping item ID " + itemId + " due to zero or negative stock.");
                    continue;
                }

                // 🚫 If requested quantity exceeds available stock, skip
                if (qtyIssued > currentBalance) {
                    System.out.println("Skipping item ID " + itemId + " because issued qty (" + qtyIssued + ") exceeds stock (" + currentBalance + ").");
                    continue;
                }

                // ✅ Get latest PO price if available
                try (PreparedStatement psPO = con.prepareStatement(
                        "SELECT net_amount, qty FROM po_items WHERE item_id=? AND qty>0 ORDER BY po_id DESC LIMIT 1")) {
                    psPO.setInt(1, itemId);
                    try (ResultSet rs = psPO.executeQuery()) {
                        if (rs.next()) {
                            double netAmt = rs.getDouble("net_amount");
                            double qty = rs.getDouble("qty");
                            if (qty > 0) unitPrice = netAmt / qty;
                        }
                    }
                }

                double totalValue = qtyIssued * unitPrice;
                double newBalance = currentBalance - qtyIssued;

                // ✅ Insert into dining_hall_consumption
                try (PreparedStatement ps1 = con.prepareStatement(
                        "INSERT INTO dining_hall_consumption (issueno,item_id,department,issued_to,qty_issued,remarks,unit_price,total_value,session,issue_date) VALUES (?,?,?,?,?,?,?,?,?,?)")) {
                    ps1.setString(1, issueno);
                    ps1.setInt(2, itemId);
                    ps1.setString(3, department);
                    ps1.setString(4, issuedTo);
                    ps1.setDouble(5, qtyIssued);
                    ps1.setString(6, remarks);
                    ps1.setDouble(7, unitPrice);
                    ps1.setDouble(8, totalValue);
                    ps1.setString(9, session);
                    ps1.setString(10, issueDate);
                    ps1.executeUpdate();
                }

                // ✅ Insert into stock_issues
                int issueId = 0;
                try (PreparedStatement ps2 = con.prepareStatement(
                        "INSERT INTO stock_issues (issueno,item_id,department,issued_to,qty_issued,remarks,unit_price,total_value,issue_date) VALUES (?,?,?,?,?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps2.setString(1, issueno);
                    ps2.setInt(2, itemId);
                    ps2.setString(3, department);
                    ps2.setString(4, issuedTo);
                    ps2.setDouble(5, qtyIssued);
                    ps2.setString(6, remarks);
                    ps2.setDouble(7, unitPrice);
                    ps2.setDouble(8, totalValue);
                    ps2.setString(9, issueDate);
                    ps2.executeUpdate();

                    try (ResultSet rs = ps2.getGeneratedKeys()) {
                        if (rs.next()) issueId = rs.getInt(1);
                    }
                }

                // ✅ Ledger entry
                try (PreparedStatement ps3 = con.prepareStatement(
                        "INSERT INTO stock_ledger (item_id,trans_type,trans_id,trans_date,qty,running_balance,remarks) VALUES (?,?,?,CURRENT_DATE(),?,?,?)")) {
                    ps3.setInt(1, itemId);
                    ps3.setString(2, "ISSUE");
                    ps3.setInt(3, issueId);
                    ps3.setDouble(4, qtyIssued);
                    ps3.setDouble(5, newBalance);
                    ps3.setString(6, remarks);
                    ps3.executeUpdate();
                }

                // ✅ Update stock
                try (PreparedStatement psUpdate = con.prepareStatement(
                        "UPDATE stock SET total_issued = total_issued + ?, balance_qty = balance_qty - ?, last_price = ? WHERE item_id = ?")) {
                    psUpdate.setDouble(1, qtyIssued);
                    psUpdate.setDouble(2, qtyIssued);
                    psUpdate.setDouble(3, unitPrice);
                    psUpdate.setInt(4, itemId);
                    psUpdate.executeUpdate();
                }
            }

            con.commit();
            response.sendRedirect("DiningHallServlet");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("Home");
        }
    }
}
