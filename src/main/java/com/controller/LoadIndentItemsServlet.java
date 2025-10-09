package com.controller;

import com.bean.DBUtil;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import javax.servlet.*;
import java.io.*;
import java.sql.*;
import java.util.*;

@WebServlet("/LoadIndentItemsServlet")
public class LoadIndentItemsServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String indentId = request.getParameter("indentId");
        List<Map<String, Object>> items = new ArrayList<>();

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT im.Item_id, im.Category, im.Sub_Category, im.Item_name, ii.qty_requested " +
                 "FROM indent ii JOIN item_master im ON ii.item_id = im.Item_id " +
                 "WHERE ii.indent_id = ?")) {

            ps.setString(1, indentId);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> m = new HashMap<>();
                m.put("item_id", rs.getInt("Item_id"));
                m.put("category", rs.getString("Category"));
                m.put("subcategory", rs.getString("Sub_Category"));
                m.put("item_name", rs.getString("Item_name"));
                m.put("qty", rs.getDouble("qty_requested"));
                items.add(m);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        request.setAttribute("indentItems", items);
        request.setAttribute("indentId", indentId);
        request.getRequestDispatcher("issue.jsp").forward(request, response);
    }
}
