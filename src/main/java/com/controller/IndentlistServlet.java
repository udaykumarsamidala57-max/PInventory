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

    private static final long serialVersionUID = 1L;

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

        try (Connection con = DBUtil.getConnection()) {

            StringBuilder listSql = new StringBuilder();

            listSql.append("SELECT i.*, i.stock AS balance_qty ")
                   .append("FROM indent i ")
                   .append("WHERE 1=1 ");

            // ---------- Department Filter ----------
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

            // ---------- Latest 500 Records ----------
            listSql.append(" ORDER BY i.indent_id DESC LIMIT 1000");

            try (PreparedStatement ps = con.prepareStatement(listSql.toString())) {

                if (!"Global".equalsIgnoreCase(role)
                        && !"Admin".equalsIgnoreCase(role)
                        && !"Finance".equalsIgnoreCase(dept)
                        && !"Store".equalsIgnoreCase(dept)) {

                    ps.setString(1, dept);
                }

                try (ResultSet rs = ps.executeQuery()) {

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

                        // Approval Dates
                        try {
                            ind.setIapprovevdate(rs.getDate("Iapprovedate"));
                        } catch (Exception ignored) {
                        }

                        try {
                            ind.setFapprovevdate(rs.getDate("Fapprovedate"));
                        } catch (Exception ignored) {
                        }

                        // Stock Snapshot
                        ind.setBalanceQty(rs.getDouble("balance_qty"));

                        list.add(ind);
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException("DB Error: " + e.getMessage(), e);
        }

        // ---------- Forward ----------
        request.setAttribute("indents", list);
        RequestDispatcher rd = request.getRequestDispatcher("indentList.jsp");
        rd.forward(request, response);
    }
}