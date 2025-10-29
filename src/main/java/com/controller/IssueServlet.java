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
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        List<Map<String, Object>> indentList = new ArrayList<>();

        try (Connection con = DBUtil.getConnection()) {

            // ✅ Generate next issue number
            String nextNo = "1";
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COALESCE(MAX(CAST(issueno AS UNSIGNED)),0)+1 AS next_no FROM stock_issues");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) nextNo = rs.getString("next_no");
            }

            // ✅ Fetch approved indents pending issue
            String sql = """
                SELECT indent_id, indent_no, requested_by, department, item_id, item_name, qty, UOM, purpose, remarks
                FROM indent
                WHERE status='Approved'
                  AND Indentnext='Issue'
                  AND (Issued_status IS NULL OR Issued_status='Pending')
                ORDER BY indent_id DESC
                """;

            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    int itemId = rs.getInt("item_id");

                    // ✅ Ensure item exists in stock (auto-create if missing)
                    try (PreparedStatement psCheck = con.prepareStatement(
                            "SELECT COUNT(*) FROM stock WHERE item_id=?")) {
                        psCheck.setInt(1, itemId);
                        try (ResultSet rsCheck = psCheck.executeQuery()) {
                            if (rsCheck.next() && rsCheck.getInt(1) == 0) {
                                try (PreparedStatement psInsert = con.prepareStatement(
                                        "INSERT INTO stock (item_id, total_received, total_issued, balance_qty, last_price) VALUES (?, 0, 0, 0, 0)")) {
                                    psInsert.setInt(1, itemId);
                                    psInsert.executeUpdate();
                                }
                            }
                        }
                    }

                    double availableStock = 0;
                    double unitPrice = 0;

                    // ✅ Always try to get latest PO price first
                    try (PreparedStatement psPO = con.prepareStatement(
                            "SELECT net_amount, qty FROM po_items WHERE item_id=? AND qty > 0 ORDER BY po_id DESC LIMIT 1")) {
                        psPO.setInt(1, itemId);
                        try (ResultSet rsPO = psPO.executeQuery()) {
                            if (rsPO.next()) {
                                double netAmount = rsPO.getDouble("net_amount");
                                double qty = rsPO.getDouble("qty");
                                if (qty > 0) {
                                    unitPrice = netAmount / qty;

                                    // ✅ Update stock with latest PO price
                                    try (PreparedStatement psUpd = con.prepareStatement(
                                            "UPDATE stock SET last_price=? WHERE item_id=?")) {
                                        psUpd.setDouble(1, unitPrice);
                                        psUpd.setInt(2, itemId);
                                        psUpd.executeUpdate();
                                    }
                                }
                            }
                        }
                    }

                    // ✅ Get available stock and (if no PO found) fallback to last_price
                    try (PreparedStatement ps2 = con.prepareStatement(
                            "SELECT COALESCE(balance_qty,0) AS balance_qty, COALESCE(last_price,0) AS last_price FROM stock WHERE item_id=?")) {
                        ps2.setInt(1, itemId);
                        try (ResultSet rs2 = ps2.executeQuery()) {
                            if (rs2.next()) {
                                availableStock = rs2.getDouble("balance_qty");
                                if (unitPrice == 0) {
                                    unitPrice = rs2.getDouble("last_price");
                                }
                            }
                        }
                    }

                    // ✅ Add record for display
                    row.put("indent_id", rs.getInt("indent_id"));
                    row.put("indent_no", rs.getString("indent_no"));
                    row.put("requested_by", rs.getString("requested_by"));
                    row.put("department", rs.getString("department"));
                    row.put("item_id", itemId);
                    row.put("item_name", rs.getString("item_name"));
                    row.put("qty_requested", rs.getDouble("qty"));
                    row.put("UOM", rs.getString("UOM"));
                    row.put("purpose", rs.getString("purpose"));
                    row.put("remarks", rs.getString("remarks"));
                    row.put("available_stock", availableStock);
                    row.put("unit_price", unitPrice);
                    indentList.add(row);
                }
            }

            request.setAttribute("nextIssueNo", nextNo);
            request.setAttribute("indentList", indentList);
            request.getRequestDispatcher("issue.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException("Error loading Issue page: " + e.getMessage(), e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String indentId = request.getParameter("indentId");
        String itemId = request.getParameter("itemId");
        String qtyIssuedStr = request.getParameter("qtyIssued");
        String department = request.getParameter("department");
        String unitPriceStr = request.getParameter("unitPrice");

        if (indentId == null || itemId == null || qtyIssuedStr == null || qtyIssuedStr.isEmpty()) {
            request.setAttribute("message", "❌ Missing data for issue process!");
            doGet(request, response);
            return;
        }

        double qtyIssued = Double.parseDouble(qtyIssuedStr);
        double unitPrice = (unitPriceStr != null && !unitPriceStr.isEmpty())
                ? Double.parseDouble(unitPriceStr)
                : 0.0;
        double totalValue = qtyIssued * unitPrice;
        String issueno = "0";

        try (Connection con = DBUtil.getConnection()) {
            con.setAutoCommit(false);

            // ✅ Generate next issue number
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COALESCE(MAX(CAST(issueno AS UNSIGNED)),0)+1 AS next_no FROM stock_issues");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) issueno = rs.getString("next_no");
            }

            // ✅ Ensure stock record exists
            try (PreparedStatement psCheck = con.prepareStatement(
                    "SELECT COUNT(*) FROM stock WHERE item_id=?")) {
                psCheck.setInt(1, Integer.parseInt(itemId));
                try (ResultSet rsCheck = psCheck.executeQuery()) {
                    if (rsCheck.next() && rsCheck.getInt(1) == 0) {
                        try (PreparedStatement psInsert = con.prepareStatement(
                                "INSERT INTO stock (item_id, total_received, total_issued, balance_qty, last_price) VALUES (?, 0, 0, 0, 0)")) {
                            psInsert.setInt(1, Integer.parseInt(itemId));
                            psInsert.executeUpdate();
                        }
                    }
                }
            }

            // ✅ Get issued_to
            String issuedTo = "";
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT requested_by FROM indent WHERE indent_id=?")) {
                ps.setString(1, indentId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) issuedTo = rs.getString("requested_by");
                }
            }

            // ✅ Check available stock
            double available = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COALESCE(balance_qty,0) FROM stock WHERE item_id=?")) {
                ps.setInt(1, Integer.parseInt(itemId));
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) available = rs.getDouble(1);
                }
            }

            if (qtyIssued > available) {
                throw new Exception("Insufficient stock! Available: " + available + ", Requested: " + qtyIssued);
            }

            // ✅ Insert into stock_issues
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO stock_issues (issueno, item_id, issued_to, department, qty_issued, remarks, indent_id, unit_price, total_value, issue_date) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())")) {
                ps.setString(1, issueno);
                ps.setInt(2, Integer.parseInt(itemId));
                ps.setString(3, issuedTo);
                ps.setString(4, department);
                ps.setDouble(5, qtyIssued);
                ps.setString(6, "Issued against indent " + indentId);
                ps.setString(7, indentId);
                ps.setDouble(8, unitPrice);
                ps.setDouble(9, totalValue);
                ps.executeUpdate();
            }

            // ✅ Update stock
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE stock SET total_issued = total_issued + ?, balance_qty = balance_qty - ?, last_price=? WHERE item_id = ?")) {
                ps.setDouble(1, qtyIssued);
                ps.setDouble(2, qtyIssued);
                ps.setDouble(3, unitPrice);
                ps.setInt(4, Integer.parseInt(itemId));
                ps.executeUpdate();
            }

            // ✅ Update indent
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE indent SET Issued_status='Issued', Issued_qty=?, POStatus='Completed', Indentnext='Issued' WHERE indent_id=?")) {
                ps.setDouble(1, qtyIssued);
                ps.setString(2, indentId);
                ps.executeUpdate();
            }

            // ✅ Insert into stock_ledger
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO stock_ledger (item_id, trans_type, trans_id, qty, running_balance, remarks, trans_date) "
                            + "VALUES (?, 'ISSUE', ?, ?, (SELECT balance_qty FROM stock WHERE item_id=?), ?, NOW())")) {
                ps.setInt(1, Integer.parseInt(itemId));
                ps.setString(2, issueno);
                ps.setDouble(3, qtyIssued);
                ps.setInt(4, Integer.parseInt(itemId));
                ps.setString(5, "Issue for indent " + indentId);
                ps.executeUpdate();
            }

            con.commit();
            request.setAttribute("message", "✅ Issued successfully! Indent ID: " + indentId);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("message", "❌ Error: " + e.getMessage());
        }

        doGet(request, response);
    }
}
