package com.controller;
import java.time.YearMonth;
import java.io.IOException;
import java.sql.*;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

@WebServlet("/DiningHallConsumptionReportServlet")
public class DiningHallConsumptionReportServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

    	String reportMonth =
    	        request.getParameter("report_month");

    	String session =
    	        request.getParameter("session");

    	String fromDate = null;
    	String toDate = null;

    	if(reportMonth != null &&
    	        !reportMonth.trim().isEmpty()) {

    	    YearMonth ym =
    	            YearMonth.parse(reportMonth);

    	    fromDate =
    	            ym.atDay(1).toString();

    	    toDate =
    	            ym.atEndOfMonth().toString();
    	}

        List<Map<String,Object>> reportList =
                new ArrayList<Map<String,Object>>();

        // Don't load report initially
        if(reportMonth == null ||
                reportMonth.trim().isEmpty()) {

            request.setAttribute("reportList", reportList);

            request.getRequestDispatcher(
                    "dining_hall_consumption_report.jsp")
                    .forward(request, response);

            return;
        }

        try(Connection con = DBUtil.getConnection()) {

            String sql =
                    "SELECT DATE(d.issue_date) issue_day, " +
                    "d.session, " +
                    "i.Item_name, " +
                    "i.UOM, " +
                    "SUM(d.qty_issued) total_qty, " +
                    "SUM(d.total_value) total_value " +
                    "FROM dining_hall_consumption d " +
                    "INNER JOIN item_master i " +
                    "ON d.item_id=i.Item_id " +
                    "WHERE 1=1 ";

            if(fromDate != null &&
                    !fromDate.trim().isEmpty()) {

                sql += " AND DATE(d.issue_date)>=? ";
            }

            if(toDate != null &&
                    !toDate.trim().isEmpty()) {

                sql += " AND DATE(d.issue_date)<=? ";
            }

            if(session != null &&
                    !session.trim().isEmpty()) {

                sql += " AND d.session=? ";
            }

            sql +=
                    " GROUP BY DATE(d.issue_date), " +
                    " d.session, d.item_id " +
                    " ORDER BY DATE(d.issue_date) DESC, d.session";

            PreparedStatement ps =
                    con.prepareStatement(sql);

            int idx = 1;

            if(fromDate != null &&
                    !fromDate.trim().isEmpty()) {

                ps.setString(idx++, fromDate);
            }

            if(toDate != null &&
                    !toDate.trim().isEmpty()) {

                ps.setString(idx++, toDate);
            }

            if(session != null &&
                    !session.trim().isEmpty()) {

                ps.setString(idx++, session);
            }

            ResultSet rs = ps.executeQuery();

            while(rs.next()) {

                Map<String,Object> row =
                        new HashMap<String,Object>();

                row.put("issue_day",
                        rs.getString("issue_day"));

                row.put("session",
                        rs.getString("session"));

                row.put("item_name",
                        rs.getString("Item_name"));

                row.put("uom",
                        rs.getString("UOM"));

                row.put("qty",
                        rs.getDouble("total_qty"));

                row.put("value",
                        rs.getDouble("total_value"));

                reportList.add(row);
            }

            request.setAttribute(
                    "reportList",
                    reportList);

            request.getRequestDispatcher(
                    "dining_hall_consumption_report.jsp")
                    .forward(request, response);

        } catch(Exception e) {

            e.printStackTrace();

            throw new ServletException(e);
        }
    }
}