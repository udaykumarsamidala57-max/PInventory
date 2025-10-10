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

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");
        String dept = (String) sess.getAttribute("department");

        List<IndentItemFull> list = new ArrayList<>();

        try (Connection con = DBUtil.getConnection()) {
            PreparedStatement ps;

            // Global/Finance roles can see all
            if ("Global".equalsIgnoreCase(role) || "Finance".equalsIgnoreCase(dept) || "Global".equalsIgnoreCase(dept)) {
                ps = con.prepareStatement(
                    "SELECT * FROM indent ORDER BY indent_id DESC"
                );
            } else {
                ps = con.prepareStatement(
                    "SELECT * FROM indent WHERE department=? ORDER BY indent_id DESC"
                );
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
                ind.setApprovedBy(rs.getString("IstausApprove")); // same column used
                ind.setStatus(rs.getString("status"));
                ind.setIndentNext(rs.getString("Indentnext"));

                // Optional columns — handle safely
                try {
                    ind.setIapprovevdate(rs.getDate("Iapprovedate"));
                } catch (Exception e) {}
                try {
                    ind.setFapprovevdate(rs.getDate("Fapprovedate"));
                } catch (Exception e) {}

                // Balance qty optional (not in indent table)
                try {
                    ind.setBalanceQty(rs.getDouble("Issued_qty"));
                } catch (Exception e) {}

                list.add(ind);
            }

        } catch (Exception e) {
            throw new ServletException("DB error: " + e.getMessage(), e);
        }

        request.setAttribute("indents", list);
        RequestDispatcher rd = request.getRequestDispatcher("indentList.jsp");
        rd.forward(request, response);
    }
}
