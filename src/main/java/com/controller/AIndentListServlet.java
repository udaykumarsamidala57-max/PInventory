package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;
import com.bean.IndentItemFull;

@WebServlet("/AIndentListServlet")
public class AIndentListServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // -------------------- GET --------------------
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");
        List<IndentItemFull> indentList = new ArrayList<>();
        Map<Integer, Double> pendingPerItem = new HashMap<>();

        // ---------- 1️⃣ Fetch pending qty per item ----------
        String pendingSql =
            "SELECT item_id, COALESCE(SUM(qty),0) AS pending_sum " +
            "FROM indent " +
            "WHERE Indentnext='Issue' AND status='Approved' " +
            "GROUP BY item_id";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(pendingSql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                pendingPerItem.put(rs.getInt("item_id"), rs.getDouble("pending_sum"));
            }

        } catch (SQLException e) {
            request.setAttribute("errorMsg", "DB Error (pending sums): " + e.getMessage());
        }

        // ---------- 2️⃣ Fetch all active indents ----------
        String listSql =
            "SELECT i.*, COALESCE(s.balance_qty,0) AS balance_qty " +
            "FROM indent i " +
            "LEFT JOIN stock s ON i.item_id = s.item_id " +
            "WHERE (TRIM(i.Indentnext) NOT IN ('Issued','Cancelled') OR i.Indentnext IS NULL) " +
            "AND (TRIM(i.status) NOT IN ('Cancelled') OR i.status IS NULL) " +
            "ORDER BY i.indent_id DESC";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(listSql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                IndentItemFull ind = new IndentItemFull();
                ind.setId(rs.getInt("indent_id"));
                ind.setIndentNo(rs.getString("indent_no"));
                ind.setDate(rs.getDate("indent_date"));
                ind.setItemId(rs.getInt("item_id"));
                ind.setItemName(rs.getString("item_name"));
                ind.setQty(rs.getDouble("qty"));
                ind.setBalanceQty(rs.getDouble("balance_qty"));
                ind.setUom(rs.getString("UOM"));
                ind.setDepartment(rs.getString("department"));
                ind.setRequestedBy(rs.getString("requested_by"));
                ind.setPurpose(rs.getString("purpose"));
                ind.setIstatus(rs.getString("istatus"));
                ind.setApprovedBy(rs.getString("IstausApprove"));
                ind.setIapprovevdate(rs.getDate("Iapprovedate"));
                ind.setStatus(rs.getString("status"));
                ind.setFapprovevdate(rs.getDate("Fapprovedate"));
                ind.setIndentNext(rs.getString("Indentnext"));
                indentList.add(ind);
            }

        } catch (SQLException e) {
            request.setAttribute("errorMsg", "DB Error (list): " + e.getMessage());
        }

        // ---------- 3️⃣ Forward data to JSP ----------
        request.setAttribute("role", role);
        request.setAttribute("indents", indentList);
        request.setAttribute("pendingPerItem", pendingPerItem);
        request.getRequestDispatcher("AIndentList.jsp").forward(request, response);
    }

    // -------------------- POST --------------------
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String user = (String) sess.getAttribute("username");
        String action = request.getParameter("action");
        String idStr = request.getParameter("id");

        if (action == null) {
            response.sendRedirect("AIndentListServlet");
            return;
        }

        java.sql.Date today = new java.sql.Date(System.currentTimeMillis());

        try (Connection con = DBUtil.getConnection()) {

            // ---------- 🟢 EDIT ----------
            if ("edit".equalsIgnoreCase(action)) {
                String id = request.getParameter("id");
                String qtyStr = request.getParameter("qty");
                String purpose = request.getParameter("purpose");

                double qty = 0;
                try { qty = Double.parseDouble(qtyStr); } catch (Exception e) { qty = 0; }

                // only if Indentnext is NULL or ''
                String checkSql = "SELECT Indentnext FROM indent WHERE indent_id=?";
                boolean editable = false;
                try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                    ps.setString(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            String nxt = rs.getString("Indentnext");
                            editable = (nxt == null || nxt.trim().isEmpty());
                        }
                    }
                }

                if (editable) {
                    String updateSql = "UPDATE indent SET qty=?, purpose=? WHERE indent_id=?";
                    try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                        ps.setDouble(1, qty);
                        ps.setString(2, purpose);
                        ps.setString(3, id);
                        ps.executeUpdate();
                    }
                } else {
                    request.setAttribute("errorMsg", "Editing not allowed for approved/issued indents.");
                }
            }

            // ---------- 🟢 FIRST-LEVEL APPROVAL ----------
            else if ("Iapprove".equalsIgnoreCase(action)) {
                String id = idStr;
                String sql = "UPDATE indent SET istatus='Approved', IstausApprove=?, Iapprovedate=? WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, user);
                    ps.setDate(2, today);
                    ps.setInt(3, Integer.parseInt(id));
                    ps.executeUpdate();
                }
            }

            // ---------- 🟢 FINAL APPROVAL ----------
            else if ("approve".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(idStr);
                String indentNext = request.getParameter("indentnext");
                if (indentNext == null || indentNext.trim().isEmpty()) indentNext = "Issue";

                int itemId = 0;
                double indentQty = 0, balanceQty = 0;

                String itemSql =
                    "SELECT i.item_id, i.qty, COALESCE(s.balance_qty,0) AS balance_qty " +
                    "FROM indent i " +
                    "LEFT JOIN stock s ON i.item_id = s.item_id " +
                    "WHERE i.indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(itemSql)) {
                    ps.setInt(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            itemId = rs.getInt("item_id");
                            indentQty = rs.getDouble("qty");
                            balanceQty = rs.getDouble("balance_qty");
                        } else {
                            request.setAttribute("errorMsg", "Indent not found.");
                            doGet(request, response);
                            return;
                        }
                    }
                }

                if ("Issue".equalsIgnoreCase(indentNext)) {
                    double sumIssued = 0;
                    String sumSql =
                        "SELECT COALESCE(SUM(qty),0) FROM indent " +
                        "WHERE item_id=? AND Indentnext='Issue' AND status='Approved' AND indent_id<>?";
                    try (PreparedStatement ps = con.prepareStatement(sumSql)) {
                        ps.setInt(1, itemId);
                        ps.setInt(2, id);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) sumIssued = rs.getDouble(1);
                        }
                    }

                    double totalRequired = sumIssued + indentQty;
                    if (totalRequired > balanceQty) {
                        request.setAttribute("errorMsg",
                            "❌ Stock insufficient. Available: " + balanceQty +
                            ", Pending: " + sumIssued +
                            ", Requested: " + indentQty);
                        doGet(request, response);
                        return;
                    }

                    String updateSql =
                        "UPDATE indent SET status='Approved', Fapprovedate=?, Indentnext='Issue' WHERE indent_id=?";
                    try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                        ps.setDate(1, today);
                        ps.setInt(2, id);
                        ps.executeUpdate();
                    }
                } else {
                    String updateSql =
                        "UPDATE indent SET Indentnext=?, Fapprovedate=? WHERE indent_id=?";
                    try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                        ps.setString(1, indentNext);
                        ps.setDate(2, today);
                        ps.setInt(3, id);
                        ps.executeUpdate();
                    }
                }
            }

            // ---------- 🟡 CANCEL ----------
            else if ("delete".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(idStr);
                String sql =
                    "UPDATE indent SET status='Cancelled', Fapprovedate=? WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setDate(1, today);
                    ps.setInt(2, id);
                    ps.executeUpdate();
                }
            }

        } catch (SQLException e) {
            request.setAttribute("errorMsg", "Database Error: " + e.getMessage());
        }

        response.sendRedirect("AIndentListServlet");
    }
}
