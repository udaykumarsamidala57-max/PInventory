package com.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil;
import com.bean.IndentItemFull;

@WebServlet("/AIndentListServlet")
public class AIndentListServlet extends HttpServlet {
    private String user;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");
        user = (String) sess.getAttribute("username");
        List<IndentItemFull> list = new ArrayList<>();

        String sql = "SELECT i.*, s.balance_qty " +
                     "FROM indent i " +
                     "LEFT JOIN stock s ON i.item_id = s.item_id " +
                     "ORDER BY i.indent_id DESC";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                IndentItemFull ind = new IndentItemFull();
                ind.setId(rs.getInt("indent_id"));
                ind.setIndentNo(rs.getString("indent_no"));
                ind.setDate(rs.getDate("indent_date"));
                ind.setItemName(rs.getString("item_name"));
                ind.setQty(rs.getDouble("qty"));
                ind.setBalanceQty(rs.getDouble("balance_qty"));
                ind.setUom(rs.getString("UOM")); // FIXED
                ind.setDepartment(rs.getString("department"));
                ind.setRequestedBy(rs.getString("requested_by"));
                ind.setPurpose(rs.getString("purpose"));
                ind.setIstatus(rs.getString("istatus"));
                ind.setApprovedBy(rs.getString("IstausApprove"));
                ind.setStatus(rs.getString("status"));
                list.add(ind);
            }

        } catch (Exception e) {
            request.setAttribute("errorMsg", "DB Error: " + e.getMessage());
        }

        request.setAttribute("role", role);
        request.setAttribute("indents", list);
        request.getRequestDispatcher("AIndentList.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        String idStr = request.getParameter("id");

        if (idStr == null || action == null) {
            response.sendRedirect("AIndentListServlet");
            return;
        }

        int id = Integer.parseInt(idStr);

        try (Connection con = DBUtil.getConnection()) {

            if ("update".equalsIgnoreCase(action)) {
                String itemName = request.getParameter("itemName");
                double qty = Double.parseDouble(request.getParameter("qty"));
                String purpose = request.getParameter("purpose");

                String sql = "UPDATE indent SET item_name=?, qty=?, purpose=? WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, itemName);
                    ps.setDouble(2, qty);
                    ps.setString(3, purpose);
                    ps.setInt(4, id);
                    ps.executeUpdate();
                }

            } else if ("Iapprove".equalsIgnoreCase(action)) {
                String sql = "UPDATE indent SET istatus='Approved', IstausApprove=? WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, user);
                    ps.setInt(2, id);
                    ps.executeUpdate();
                }

            } else if ("approve".equalsIgnoreCase(action)) {
                String sql = "UPDATE indent SET status='Approved' WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, id);
                    ps.executeUpdate();
                }

            } else if ("delete".equalsIgnoreCase(action)) {
                String sql = "UPDATE indent SET status='Cancelled' WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, id);
                    ps.executeUpdate();
                }
            }

        } catch (Exception e) {
            request.setAttribute("errorMsg", e.getMessage());
        }

        response.sendRedirect("AIndentListServlet"); // Refresh list
    }
}
