package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;
import com.bean.IndentItemFull;

@WebServlet("/IssueApprove")
public class IssueApprove extends HttpServlet {
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
        if (!"Global".equalsIgnoreCase(role)) {
            response.setContentType("text/html");
            response.getWriter().println("<h3 style='color:red;'>Access Denied</h3>");
            return;
        }

        List<IndentItemFull> indentList = new ArrayList<>();

        // ✅ Corrected SQL to fetch indents ready for issue
        String sql = "SELECT i.*, s.balance_qty " +
                "FROM indent i " +
                "INNER JOIN stock s ON i.item_id = s.item_id " + // ✅ INNER JOIN (only items present in stock)
                "WHERE TRIM(i.Istatus) = 'Approved' " +          // main approval
                "AND TRIM(i.status) = 'Pending' " +              // still pending overall
                "AND (i.Indentnext IS NULL OR TRIM(i.Indentnext) = '' OR TRIM(i.Indentnext) = 'PO') " +
                "AND s.balance_qty >= i.qty " +                  // ✅ stock must have enough quantity
                "ORDER BY i.indent_id DESC";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                // Debug output for verification
                System.out.println("[DEBUG] Fetched indent_id: " + rs.getInt("indent_id") +
                        ", Item: " + rs.getString("item_name") +
                        ", Qty: " + rs.getDouble("qty") +
                        ", Balance: " + rs.getDouble("balance_qty") +
                        ", Istatus: " + rs.getString("Istatus") +
                        ", status: " + rs.getString("status") +
                        ", Indentnext: " + rs.getString("Indentnext"));

                IndentItemFull ind = new IndentItemFull();
                ind.setId(rs.getInt("indent_id"));
                ind.setIndentNo(rs.getString("indent_no"));
                ind.setDateStr(rs.getString("indent_date"));
                ind.setItemName(rs.getString("item_name"));
                ind.setQty(rs.getDouble("qty"));
                ind.setBalanceQty(rs.getDouble("balance_qty"));
                ind.setDepartment(rs.getString("department"));
                ind.setIstatus(rs.getString("Istatus"));
                ind.setApprovedBy(rs.getString("IstausApprove"));
                ind.setStatus(rs.getString("status"));
                ind.setIndentNext(rs.getString("Indentnext"));
                indentList.add(ind);
            }

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMsg", "Database Error: " + e.getMessage());
        }

        request.setAttribute("role", role);
        request.setAttribute("indents", indentList);
        request.getRequestDispatcher("IssueApprove.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");
        if (!"Global".equalsIgnoreCase(role)) {
            response.sendRedirect("login.jsp");
            return;
        }

        String action = request.getParameter("action");
        String idStr = request.getParameter("id");
        java.sql.Date today = new java.sql.Date(System.currentTimeMillis());

        if ("approve".equalsIgnoreCase(action) && idStr != null) {
            try (Connection con = DBUtil.getConnection()) {
                String sql = "UPDATE indent " +
                             "SET status = 'Approved', " +
                             "Indentnext = 'Issue', " +
                             "Fapprovedate = ? " +
                             "WHERE indent_id = ?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, today.toString());
                    ps.setInt(2, Integer.parseInt(idStr));
                    ps.executeUpdate();
                    System.out.println("[DEBUG] Updated indent_id " + idStr + " -> Issue Approved");
                }
            } catch (SQLException e) {
                e.printStackTrace();
                request.setAttribute("errorMsg", "Database Error: " + e.getMessage());
            }
        }

        // Redirect back to the servlet to refresh the list
        response.sendRedirect("IssueApprove");
    }
}
