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
        List<IndentItemFull> list = new ArrayList<>();
        Map<Integer, Double> pendingPerItem = new HashMap<>();

        // ---------- Pending qty per item ----------
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

        // ---------- Fetch all active indents ----------
        String sql = "SELECT i.*, COALESCE(s.balance_qty,0) AS balance_qty " +
                "FROM indent i LEFT JOIN stock s ON i.item_id = s.item_id " +
                "WHERE (TRIM(i.Indentnext) NOT IN ('Issued', 'Cancelled') OR i.Indentnext IS NULL) " +
                "AND (TRIM(i.status) NOT IN ('Cancelled') OR i.status IS NULL) " +
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

            // ---------- 1st Level Approval ----------
            if ("Iapprove".equalsIgnoreCase(action)) {
                String sql = "UPDATE indent SET istatus='Approved', IstausApprove=?, Iapprovedate=? WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, user);
                    ps.setDate(2, todayDate);
                    ps.setInt(3, id);
                    ps.executeUpdate();
                }
            }

            // ---------- Final Approval ----------
            else if ("approve".equalsIgnoreCase(action)) {

                String indentnext = request.getParameter("indentnext");
                if (indentnext == null || indentnext.trim().isEmpty()) indentnext = "Issue";

                int itemId = 0;
                double indentQty = 0;
                double balanceQty = 0;

                // Fetch item details
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
                    double sumIssued = 0;
                    String sumSql = "SELECT COALESCE(SUM(qty),0) FROM indent " +
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
                                "Stock not available. Available: " + balanceQty +
                                        ", Already Pending: " + sumIssued +
                                        ", Requested: " + indentQty);
                        doGet(request, response);
                        return;
                    }

                    // ✅ Final approval for "Issue"
                    String sql = "UPDATE indent SET status='Approved', Fapprovedate=?, Indentnext=? WHERE indent_id=?";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setDate(1, todayDate);
                        ps.setString(2, "Issue");
                        ps.setInt(3, id);
                        ps.executeUpdate();
                    }

                } else {
                    // ✅ For PO / Cancelled / Management Note — update Indentnext + Fapprovedate
                    String sql = "UPDATE indent SET Indentnext=?, Fapprovedate=? WHERE indent_id=?";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setString(1, indentnext);
                        ps.setDate(2, todayDate);
                        ps.setInt(3, id);
                        ps.executeUpdate();
                    }
                }
            }

            // ---------- Delete / Cancel ----------
            else if ("delete".equalsIgnoreCase(action)) {
                String sql = "UPDATE indent SET status='Cancelled', Fapprovedate=? WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setDate(1, todayDate);
                    ps.setInt(2, id);
                    ps.executeUpdate();
                }
            }

        } catch (SQLException e) {
            request.setAttribute("errorMsg", "Error: " + e.getMessage());
        }

        response.sendRedirect("AIndentListServlet");
    }
}
