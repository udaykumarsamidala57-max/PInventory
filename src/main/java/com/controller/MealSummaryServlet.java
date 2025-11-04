package com.controller;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

@WebServlet("/MealSummaryServlet")
public class MealSummaryServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String mealDate = request.getParameter("meal_date");
        String session = request.getParameter("session");
        String message = "";

        if (mealDate == null || session == null || mealDate.isEmpty() || session.isEmpty()) {
            message = "⚠️ Please select both date and session.";
            request.setAttribute("message", message);
            request.getRequestDispatcher("meal_summary.jsp").forward(request, response);
            return;
        }

        try (Connection con = DBUtil.getConnection()) {

            // Compute values from dining_hall_consumption
            String sumSql = "SELECT COUNT(DISTINCT item_id) AS total_items, "
                          + "COALESCE(SUM(qty_issued), 0) AS total_qty, "
                          + "COALESCE(SUM(total_value), 0) AS total_cost, "
                          + "MAX(department) AS department "
                          + "FROM dining_hall_consumption "
                          + "WHERE DATE(issue_date) = ? AND session = ?";

            int totalItems = 0;
            double totalQty = 0, totalCost = 0;
            String department = "Dining Hall";

            try (PreparedStatement ps = con.prepareStatement(sumSql)) {
                ps.setString(1, mealDate);
                ps.setString(2, session);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    totalItems = rs.getInt("total_items");
                    totalQty = rs.getDouble("total_qty");
                    totalCost = rs.getDouble("total_cost");
                    if (rs.getString("department") != null)
                        department = rs.getString("department");
                }
            }

            // Check if record exists
            String checkSql = "SELECT COUNT(*) FROM meal_cost_summary WHERE meal_date = ? AND session = ?";
            boolean exists = false;
            try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                ps.setString(1, mealDate);
                ps.setString(2, session);
                ResultSet rs = ps.executeQuery();
                if (rs.next() && rs.getInt(1) > 0)
                    exists = true;
            }

            if (exists) {
                // Update record
                String updateSql = "UPDATE meal_cost_summary SET total_items=?, total_quantity=?, total_cost=?, department=? "
                                 + "WHERE meal_date=? AND session=?";
                try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                    ps.setInt(1, totalItems);
                    ps.setDouble(2, totalQty);
                    ps.setDouble(3, totalCost);
                    ps.setString(4, department);
                    ps.setString(5, mealDate);
                    ps.setString(6, session);
                    ps.executeUpdate();
                }
                message = "✅ Summary updated successfully for " + mealDate + " (" + session + ")";
            } else {
                // Insert record
                String insertSql = "INSERT INTO meal_cost_summary (meal_date, session, department, total_items, total_quantity, total_cost) "
                                 + "VALUES (?, ?, ?, ?, ?, ?)";
                try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                    ps.setString(1, mealDate);
                    ps.setString(2, session);
                    ps.setString(3, department);
                    ps.setInt(4, totalItems);
                    ps.setDouble(5, totalQty);
                    ps.setDouble(6, totalCost);
                    ps.executeUpdate();
                }
                message = "✅ Summary inserted successfully for " + mealDate + " (" + session + ")";
            }

        } catch (Exception e) {
            e.printStackTrace();
            message = "❌ Error: " + e.getMessage();
        }

        request.setAttribute("message", message);
        request.getRequestDispatcher("meal_summary.jsp").forward(request, response);
    }
}
