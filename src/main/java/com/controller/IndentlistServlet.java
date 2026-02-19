package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;
import com.bean.IndentItemFull;

@WebServlet("/IndentlistServlet")
public class IndentlistServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ---------- Session Check ----------
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");
        String dept = (String) sess.getAttribute("department");

        List<IndentItemFull> list = new ArrayList<>();

        // ---------- Database Query ----------
        try (Connection con = DBUtil.getConnection()) {

            StringBuilder listSql = new StringBuilder();
            listSql.append("SELECT i.*, i.stock AS balance_qty ")
                   .append("FROM indent i ")
                   .append("WHERE 1=1 ");

            // ---------- Department-based filter ----------
            if (!"Global".equalsIgnoreCase(role)
                    && !"Finance".equalsIgnoreCase(dept)
                    && !"Store".equalsIgnoreCase(dept)) {

                if ("Admin".equalsIgnoreCase(role)) {
                    listSql.append(" AND i.department IN ")
                           .append("('Electrical','Housekeeping','Plumbing','Dininghall') ");
                } else {
                    listSql.append(" AND i.department = ? ");
                }
            }

            // ---------- Ordering ----------
            listSql.append("ORDER BY CASE ")
                   .append("WHEN (i.Istatus IS NULL OR TRIM(i.Istatus) = '' OR TRIM(i.Istatus) = 'Pending') THEN 0 ")
                   .append("WHEN TRIM(i.Istatus) = 'Approved' THEN 1 ")
                   .append("WHEN TRIM(i.Istatus) = 'Cancelled' THEN 2 ")
                   .append("ELSE 3 END, ")
                   .append("i.indent_id DESC");

            PreparedStatement ps = con.prepareStatement(listSql.toString());

            if (!"Global".equalsIgnoreCase(role)
                    && !"Admin".equalsIgnoreCase(role)
                    && !"Finance".equalsIgnoreCase(dept)
                    && !"Store".equalsIgnoreCase(dept)) {
                ps.setString(1, dept);
            }

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                IndentItemFull ind = new IndentItemFull();

                ind.setId(rs.getInt("indent_id"));
                ind.setIndentNo(rs.getString("indent_no"));
                ind.setDate(rs.getDate("indent_date"));
                ind.setItemId(rs.getInt("item_id"));
                ind.setItemName(rs.getString("item_name"));
                ind.setQty(rs.getDouble("qty"));
                ind.setUom(rs.getString("UOM"));
                ind.setDepartment(rs.getString("department"));
                ind.setRequestedBy(rs.getString("requested_by"));
                ind.setPurpose(rs.getString("purpose"));
                ind.setIstatus(rs.getString("Istatus"));
                ind.setApprovedBy(rs.getString("IstausApprove"));
                ind.setStatus(rs.getString("status"));
                ind.setIndentNext(rs.getString("Indentnext"));

                // ---------- Dates ----------
                try { ind.setIapprovevdate(rs.getDate("Iapprovedate")); } catch (SQLException ignored) {}
                try { ind.setFapprovevdate(rs.getDate("Fapprovedate")); } catch (SQLException ignored) {}

                // ---------- Stock snapshot from indent ----------
                ind.setBalanceQty(rs.getDouble("balance_qty"));

                list.add(ind);
            }

            rs.close();
            ps.close();

        } catch (Exception e) {
            throw new ServletException("DB error: " + e.getMessage(), e);
        }

        // ---------- Forward ----------
        request.setAttribute("indents", list);
        RequestDispatcher rd = request.getRequestDispatcher("indentList.jsp");
        rd.forward(request, response);
    }
}
