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

        String sql = "SELECT i.*, s.balance_qty FROM indent i "
                   + "LEFT JOIN stock s ON i.item_id = s.item_id "
                   + "ORDER BY i.indent_id DESC";

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

            if ("Iapprove".equalsIgnoreCase(action)) {
                String sql = "UPDATE indent SET istatus='Approved', IstausApprove=?, Iapprovedate=? WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    java.sql.Date todayDate = new java.sql.Date(System.currentTimeMillis());
                    ps.setString(1, user);
                    ps.setDate(2, todayDate);
                    ps.setInt(3, id);
                    ps.executeUpdate();
                }

            } else if ("approve".equalsIgnoreCase(action)) {
                String indentnext = request.getParameter("indentnext");
                if (indentnext == null || indentnext.trim().isEmpty()) indentnext = "Issue";

                String sql = "UPDATE indent SET status='Approved', Fapprovedate=?, Indentnext=? WHERE indent_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    java.sql.Date todayDate = new java.sql.Date(System.currentTimeMillis());
                    ps.setDate(1, todayDate);
                    ps.setString(2, indentnext);
                    ps.setInt(3, id);
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

        response.sendRedirect("AIndentListServlet");
    }
}
