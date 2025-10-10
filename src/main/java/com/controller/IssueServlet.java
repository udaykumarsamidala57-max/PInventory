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

        try (Connection con = DBUtil.getConnection()) {
            String nextNo = "1";
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COALESCE(MAX(CAST(issueno AS UNSIGNED)),0)+1 AS next_no FROM stock_issues");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) nextNo = rs.getString("next_no");
            }

            // ✅ Load only indents whose Indentnext='Issue' and not yet issued
            List<Map<String, Object>> indentList = new ArrayList<>();
            String sql = "SELECT indent_id, indent_no, requested_by, department, item_id, item_name, "
                    + "qty, UOM, purpose, remarks "
                    + "FROM indent "
                    + "WHERE status='Approved' "
                    + "AND Indentnext='Issue' "
                    + "AND (Issued_status IS NULL OR Issued_status='Pending') "
                    + "ORDER BY indent_id DESC";
            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("indent_id", rs.getInt("indent_id"));
                    row.put("indent_no", rs.getString("indent_no"));
                    row.put("requested_by", rs.getString("requested_by"));
                    row.put("department", rs.getString("department"));
                    row.put("item_id", rs.getInt("item_id"));
                    row.put("item_name", rs.getString("item_name"));
                    row.put("qty_requested", rs.getDouble("qty"));
                    row.put("UOM", rs.getString("UOM"));
                    row.put("purpose", rs.getString("purpose"));
                    row.put("remarks", rs.getString("remarks"));
                    indentList.add(row);
                }
            }

            request.setAttribute("nextIssueNo", nextNo);
            request.setAttribute("indentList", indentList);
            request.getRequestDispatcher("issue.jsp").forward(request, response);

        } catch (Exception e) {
            throw new ServletException("DB Error (GET): " + e.getMessage(), e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String indentId = request.getParameter("indentId");
        String itemId = request.getParameter("itemId");
        String qtyIssuedStr = request.getParameter("qtyIssued");

        if (indentId == null || itemId == null || qtyIssuedStr == null || qtyIssuedStr.isEmpty()) {
            request.setAttribute("message", "❌ Missing data for issue process!");
            doGet(request, response);
            return;
        }

        double qtyIssued = Double.parseDouble(qtyIssuedStr);
        String issueno = "0";

        try (Connection con = DBUtil.getConnection()) {
            con.setAutoCommit(false);

            // ✅ Get next issue number
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COALESCE(MAX(CAST(issueno AS UNSIGNED)),0)+1 AS next_no FROM stock_issues");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) issueno = rs.getString("next_no");
            }

            // ✅ Get issued_to (requested_by)
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
            try (PreparedStatement ps = con.prepareStatement("SELECT balance_qty FROM stock WHERE item_id=?")) {
                ps.setInt(1, Integer.parseInt(itemId));
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) available = rs.getDouble("balance_qty");
                }
            }

            if (qtyIssued > available) {
                throw new Exception("Insufficient stock! Available: " + available + ", Requested: " + qtyIssued);
            }

            // ✅ Insert into stock_issues
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO stock_issues (issueno, item_id, issued_to, qty_issued, remarks, indent_id, issue_date) VALUES (?, ?, ?, ?, ?, ?, NOW())")) {
                ps.setString(1, issueno);
                ps.setInt(2, Integer.parseInt(itemId));
                ps.setString(3, issuedTo);
                ps.setDouble(4, qtyIssued);
                ps.setString(5, "Issued against indent " + indentId);
                ps.setString(6, indentId);
                ps.executeUpdate();
            }

            // ✅ Update stock table
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE stock SET total_issued = total_issued + ?, balance_qty = balance_qty - ? WHERE item_id = ?")) {
                ps.setDouble(1, qtyIssued);
                ps.setDouble(2, qtyIssued);
                ps.setInt(3, Integer.parseInt(itemId));
                ps.executeUpdate();
            }

            // ✅ Update indent (Issued_qty, Issued_status, POStatus, and Indentnext)
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
