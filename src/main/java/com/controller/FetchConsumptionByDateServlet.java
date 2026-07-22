package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

@WebServlet("/FetchConsumptionByDateServlet")
public class FetchConsumptionByDateServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String selectedDate = request.getParameter("selected_date");

        if (selectedDate == null || selectedDate.trim().isEmpty()) {
            response.sendRedirect("editConsumption.jsp");
            return;
        }

        List<Map<String, Object>> list = new ArrayList<>();
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBUtil.getConnection();

            String sql = "SELECT d.issue_id, d.issueno, d.item_id, d.po_item_id, "
                       + "d.department, d.issued_to, d.qty_issued, d.issue_date, "
                       + "d.remarks, d.unit_price, d.total_value, i.Item_name, i.UOM "
                       + "FROM dining_hall_consumption d "
                       + "LEFT JOIN item_master i ON d.item_id = i.Item_id "
                       + "WHERE DATE(d.issue_date) = ? "
                       + "ORDER BY d.issue_id ASC";

            ps = con.prepareStatement(sql);
            ps.setString(1, selectedDate);
            rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("issue_id", rs.getInt("issue_id"));
                map.put("issueno", rs.getString("issueno"));
                map.put("item_id", rs.getInt("item_id"));
                map.put("po_item_id", rs.getInt("po_item_id"));
                map.put("item_name", rs.getString("Item_name"));
                map.put("uom", rs.getString("UOM"));
                map.put("department", rs.getString("department"));
                map.put("issued_to", rs.getString("issued_to"));
                map.put("qty_issued", rs.getBigDecimal("qty_issued"));
                map.put("unit_price", rs.getBigDecimal("unit_price"));
                map.put("total_value", rs.getBigDecimal("total_value"));
                map.put("remarks", rs.getString("remarks"));
                list.add(map);
            }

            if (list.isEmpty()) {
                response.sendRedirect("editConsumption.jsp?msg=notfound&selected_date=" + selectedDate);
                return;
            }

            request.setAttribute("selected_date", selectedDate);
            request.setAttribute("consumption_list", list);

            RequestDispatcher rd = request.getRequestDispatcher("editConsumption.jsp");
            rd.forward(request, response);

        } catch (Exception e) {
            throw new ServletException(e);
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception e) {}
            try { if (ps != null) ps.close(); } catch (Exception e) {}
            try { if (con != null) con.close(); } catch (Exception e) {}
        }
    }
}