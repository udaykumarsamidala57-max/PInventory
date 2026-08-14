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
        String branch = (String) sess.getAttribute("branch");

        try (Connection con = DBUtil.getConnection(branch)) {
            // ✅ Next issue number
            int nextIssueNo = 1;
            String sqlNext = "SELECT COALESCE(MAX(CAST(SUBSTRING(issueno, 4) AS UNSIGNED)), 0) + 1 AS next_no FROM dining_hall_consumption";
            try (PreparedStatement ps = con.prepareStatement(sqlNext);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) nextIssueNo = rs.getInt("next_no");
            }
            String formattedIssueNo = "ISS" + nextIssueNo;
            request.setAttribute("nextIssueNo", formattedIssueNo);

            // ✅ Department list
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

            // ✅ Items with stock (consolidated balance check)
            List<Map<String, String>> items = new ArrayList<>();
            String itemSql = "SELECT im.Item_id, im.Item_name, im.UOM, im.Category, im.Sub_Category, " +
                             "COALESCE(s.balance_qty, 0) AS stock " +
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
                    i.put("stock", String.valueOf(rs.getDouble("stock")));
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
        
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        String branch = (String) sess.getAttribute("branch");

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

        Connection con = null;
        try {
            con = DBUtil.getConnection(branch);
            con.setAutoCommit(false);

            for (int i = 0; i < itemIds.length; i++) {
                // Ignore blank/empty entries submitted from dynamic form rows
                if (itemIds[i] == null || itemIds[i].trim().isEmpty() || 
                    qtys[i] == null || qtys[i].trim().isEmpty()) {
                    continue;
                }

                int itemId = Integer.parseInt(itemIds[i].trim());
                double qtyIssued = Double.parseDouble(qtys[i].trim());
                String remarks = (remarksArr != null && i < remarksArr.length) ? remarksArr[i] : "";

                if (qtyIssued <= 0) continue;

                double currentBalance = 0.0;
                double unitPrice = 0.0;

                // ✅ 1. Get real-time stock balance & last price directly from stock table
                String stockSql = "SELECT COALESCE(balance_qty, 0) AS balance, COALESCE(last_price, 0) AS last_price " +
                                  "FROM stock WHERE item_id = ?";
                try (PreparedStatement psStock = con.prepareStatement(stockSql)) {
                    psStock.setInt(1, itemId);
                    try (ResultSet rs = psStock.executeQuery()) {
                        if (rs.next()) {
                            currentBalance = rs.getDouble("balance");
                            unitPrice = rs.getDouble("last_price");
                        }
                    }
                }

                // 🚫 If requested quantity exceeds available stock, skip processing
                if (qtyIssued > currentBalance) {
                    System.err.println("Skipping Item ID " + itemId + ": Requested (" + qtyIssued + ") > Available (" + currentBalance + ")");
                    continue;
                }

                // ✅ 2. Get latest Purchase Order price if available
                String poSql = "SELECT net_amount, qty FROM po_items WHERE item_id = ? AND qty > 0 ORDER BY po_id DESC LIMIT 1";
                try (PreparedStatement psPO = con.prepareStatement(poSql)) {
                    psPO.setInt(1, itemId);
                    try (ResultSet rs = psPO.executeQuery()) {
                        if (rs.next()) {
                            double netAmt = rs.getDouble("net_amount");
                            double poQty = rs.getDouble("qty");
                            if (poQty > 0) unitPrice = netAmt / poQty;
                        }
                    }
                }

                double totalValue = qtyIssued * unitPrice;
                double newBalance = currentBalance - qtyIssued;

                // ✅ 3. Insert into dining_hall_consumption
                String insConsumption = "INSERT INTO dining_hall_consumption " +
                        "(issueno, item_id, department, issued_to, qty_issued, remarks, unit_price, total_value, session, issue_date) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                try (PreparedStatement ps1 = con.prepareStatement(insConsumption)) {
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

                // ✅ 4. Insert into stock_issues
                int issueId = 0;
                String insIssues = "INSERT INTO stock_issues " +
                        "(issueno, item_id, department, issued_to, qty_issued, remarks, unit_price, total_value, issue_date) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
                try (PreparedStatement ps2 = con.prepareStatement(insIssues, Statement.RETURN_GENERATED_KEYS)) {
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

                // ✅ 5. Insert into stock_ledger
                String insLedger = "INSERT INTO stock_ledger " +
                        "(item_id, trans_type, trans_id, trans_date, qty, running_balance, remarks) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?)";
                try (PreparedStatement ps3 = con.prepareStatement(insLedger)) {
                    ps3.setInt(1, itemId);
                    ps3.setString(2, "ISSUE");
                    ps3.setInt(3, issueId);
                    ps3.setString(4, issueDate);
                    ps3.setDouble(5, qtyIssued);
                    ps3.setDouble(6, newBalance);
                    ps3.setString(7, remarks);
                    ps3.executeUpdate();
                }

                // ✅ 6. Update master stock table
                String upStock = "UPDATE stock SET total_issued = total_issued + ?, balance_qty = balance_qty - ?, last_price = ? WHERE item_id = ?";
                try (PreparedStatement psUpdate = con.prepareStatement(upStock)) {
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
            if (con != null) {
                try {
                    con.rollback(); // 👈 Rollback transaction on failure
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
            response.sendRedirect("error.jsp");
        } finally {
            if (con != null) {
                try {
                    con.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}