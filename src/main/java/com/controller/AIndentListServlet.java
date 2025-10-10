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
        List<IndentItemFull> list = new ArrayList<>();
        Map<Integer, Double> pendingPerItem = new HashMap<>();

        // Step 1: Get total pending quantity per item (Approved + Issue)
        String pendingSql = "SELECT item_id, COALESCE(SUM(qty),0) AS pending_sum " +
                "FROM indent WHERE Indentnext='Issue' AND status='Approved' GROUP BY item_id";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(pendingSql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                pendingPerItem.put(rs.getInt("item_id"), rs.getDouble("pending_sum"));
            }

        } catch (SQLException e) {
            request.setAttribute("errorMsg", "DB Error (pending sums): " + e.getMessage());
        }

        // Step 2: Fetch all indents with stock balance
        String sql = "SELECT i.*, COALESCE(s.balance_qty,0) AS balance_qty " +
                "FROM indent i LEFT JOIN stock s ON i.item_id = s.item_id " +
                "ORDER BY i.indent_id DESC";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
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
                list.add(ind);
            }

        } catch (SQLException e) {
            request.setAttribute("errorMsg", "DB Error (list): " + e.getMessage());
        }

        request.setAttribute("role", role);
        request.setAttribute("indents", list);
        request.setAttribute("pendingPerItem", pendingPerItem);
        request.getRequestDispatcher("AIndentList.jsp").forward(request, response);
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
        String action = request.getParameter("action");
        String idStr = request.getParameter("id");

        if (idStr == null || action == null) {
            response.sendRedirect("AIndentListServlet");
            return;
        }

        int id = Integer.parseInt(idStr);
        java.sql.Date todayDate = new java.sql.Date(System.currentTimeMillis());

        try (Connection con = DBUtil.getConnection()) {

            if ("Iapprove".equalsIgnoreCase(action)) {
                // Incharge Approval
                String sql = "UPDATE indent SET istatus='Approved', IstausApprove=?, Iapprovedate=? WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, user);
                    ps.setDate(2, todayDate);
                    ps.setInt(3, id);
                    ps.executeUpdate();
                }

            } else if ("approve".equalsIgnoreCase(action)) {

                String indentnext = request.getParameter("indentnext");
                if (indentnext == null || indentnext.trim().isEmpty()) {
                    indentnext = "Issue";
                }

                // Fetch current indent details
                int itemId = 0;
                double indentQty = 0;
                double balanceQty = 0;
                String itemSql = "SELECT i.item_id, i.qty, COALESCE(s.balance_qty,0) AS balance_qty " +
                        "FROM indent i LEFT JOIN stock s ON i.item_id = s.item_id WHERE i.indent_id=?";
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

                if ("Issue".equalsIgnoreCase(indentnext)) {
                    // Check if other indents for same item pending under PO or Management Note
                    String pendingSql = "SELECT COUNT(*) FROM indent " +
                            "WHERE item_id=? AND (Indentnext='PO' OR Indentnext='Management Note') " +
                            "AND status<>'Cancelled' AND indent_id<>?";
                    int pendingCount = 0;
                    try (PreparedStatement ps = con.prepareStatement(pendingSql)) {
                        ps.setInt(1, itemId);
                        ps.setInt(2, id);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) pendingCount = rs.getInt(1);
                        }
                    }

                    if (pendingCount > 0) {
                        request.setAttribute("errorMsg",
                                "⚠ Another indent for the same item is pending at PO/Management Note stage. Do you want to proceed?");
                        doGet(request, response);
                        return;
                    }

                    // Check available stock
                    double sumIssuedIndents = 0;
                    String sumSql = "SELECT COALESCE(SUM(qty),0) FROM indent " +
                            "WHERE item_id=? AND Indentnext='Issue' AND status='Approved' AND indent_id<>?";
                    try (PreparedStatement ps = con.prepareStatement(sumSql)) {
                        ps.setInt(1, itemId);
                        ps.setInt(2, id);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) sumIssuedIndents = rs.getDouble(1);
                        }
                    }

                    double totalRequired = sumIssuedIndents + indentQty;
                    if (totalRequired > balanceQty) {
                        request.setAttribute("errorMsg",
                                "Stock not available. Available: " + balanceQty +
                                        ", Already Pending: " + sumIssuedIndents +
                                        ", Requested: " + indentQty);
                        doGet(request, response);
                        return;
                    }

                    // Enough stock → approve and mark for Issue
                    String sql = "UPDATE indent SET status='Approved', Fapprovedate=?, Indentnext=? WHERE indent_id=?";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setDate(1, todayDate);
                        ps.setString(2, "Issue");
                        ps.setInt(3, id);
                        ps.executeUpdate();
                    }

                } else {
                    // PO or Management Note → no stock validation
                    String sql = "UPDATE indent SET Indentnext=?, Fapprovedate=? WHERE indent_id=?";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setString(1, indentnext);
                        ps.setDate(2, todayDate);
                        ps.setInt(3, id);
                        ps.executeUpdate();
                    }
                }

            } else if ("delete".equalsIgnoreCase(action)) {
                // Mark indent as cancelled
                String sql = "UPDATE indent SET status='Cancelled' WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, id);
                    ps.executeUpdate();
                }
            }

        } catch (SQLException e) {
            request.setAttribute("errorMsg", "Error: " + e.getMessage());
        }

        response.sendRedirect("AIndentListServlet");
    }
}
