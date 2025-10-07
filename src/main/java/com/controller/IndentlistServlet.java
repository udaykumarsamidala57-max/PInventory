package com.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil;
import com.bean.Indentlist;

@WebServlet("/IndentlistServlet")
public class IndentlistServlet extends HttpServlet {

    @Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);

        // Check login
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");
        String dept = (String) sess.getAttribute("department");

        List<Indentlist> list = new ArrayList<>();

        try (Connection con = DBUtil.getConnection()) {
            PreparedStatement ps;

            if ("Global".equalsIgnoreCase(role) || "Finance".equalsIgnoreCase(dept) || "Global".equalsIgnoreCase(dept)) {
                ps = con.prepareStatement(
                    "SELECT * FROM indent ORDER BY indent_id DESC"
                );
            } else  {
                ps = con.prepareStatement(
                    "SELECT * FROM indent WHERE department=?  ORDER BY indent_id DESC"
                );
                ps.setString(1, dept);
            }

            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Indentlist ind = new Indentlist();
                ind.setIndentId(rs.getInt("indent_id"));
                ind.setIndentNo(rs.getString("indent_no"));
                ind.setIndentDate(rs.getDate("indent_date"));
                ind.setItemName(rs.getString("item_name"));
                ind.setQty(rs.getDouble("qty"));
                ind.setUom(rs.getString("UOM"));
                ind.setDepartment(rs.getString("department"));
                ind.setRequestedBy(rs.getString("requested_by"));
                ind.setPurpose(rs.getString("purpose"));
                ind.setStatus(rs.getString("status"));

                list.add(ind);
            }
        } catch (Exception e) {
            throw new ServletException("DB error: " + e.getMessage(), e);
        }

        // Send data to JSP
        request.setAttribute("indents", list);
        RequestDispatcher rd = request.getRequestDispatcher("Indent/indentList.jsp");
        rd.forward(request, response);
    }
}
