package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

@WebServlet("/StockAuditReportServlet")
public class StockAuditReportServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        ArrayList<String> availableMonths = new ArrayList<String>();
        List<Map<String, Object>> reportList = new ArrayList<Map<String, Object>>();

        try {

            con = DBUtil.getConnection();

            // Load available months
            String monthSql =
                    "SELECT DISTINCT DATE_FORMAT(verification_date,'%Y-%m') month_value " +
                    "FROM stock_verification " +
                    "ORDER BY month_value DESC";

            ps = con.prepareStatement(monthSql);
            rs = ps.executeQuery();

            while (rs.next()) {
                availableMonths.add(rs.getString("month_value"));
            }

            rs.close();
            ps.close();

            String selectedMonth = request.getParameter("month");

            if (selectedMonth != null && !selectedMonth.trim().equals("")) {

                String sql =
                        "SELECT " +
                        "sv.verification_id, " +
                        "DATE_FORMAT(sv.verification_date,'%d %M %Y') verification_date, " +
                        "sv.verified_by, " +
                        "sv.status, " +
                        "svd.system_qty, " +
                        "svd.physical_qty, " +
                        "svd.variance_qty, " +
                        "svd.remarks detail_remarks, " +
                        "im.Category, " +
                        "im.Sub_Category, " +
                        "im.Item_name, " +
                        "im.UOM " +
                        "FROM stock_verification sv " +
                        "INNER JOIN stock_verification_details svd " +
                        "ON sv.verification_id = svd.verification_id " +
                        "INNER JOIN item_master im " +
                        "ON svd.item_id = im.Item_id " +
                        "WHERE DATE_FORMAT(sv.verification_date,'%Y-%m')=? " +
                        "ORDER BY sv.verification_date DESC, im.Item_name";

                ps = con.prepareStatement(sql);
                ps.setString(1, selectedMonth);

                rs = ps.executeQuery();

                while (rs.next()) {

                    Map<String, Object> row =
                            new HashMap<String, Object>();

                    row.put("verificationId",
                            rs.getInt("verification_id"));

                    row.put("verificationDate",
                            rs.getString("verification_date"));

                    row.put("verifiedBy",
                            rs.getString("verified_by"));

                    row.put("status",
                            rs.getString("status"));

                    row.put("category",
                            rs.getString("Category"));

                    row.put("subCategory",
                            rs.getString("Sub_Category"));

                    row.put("itemName",
                            rs.getString("Item_name"));

                    row.put("uom",
                            rs.getString("UOM"));

                    row.put("systemQty",
                            rs.getBigDecimal("system_qty"));

                    row.put("physicalQty",
                            rs.getBigDecimal("physical_qty"));

                    row.put("varianceQty",
                            rs.getBigDecimal("variance_qty"));

                    row.put("remarks",
                            rs.getString("detail_remarks"));

                    reportList.add(row);
                }
            }

            request.setAttribute("availableMonths", availableMonths);
            request.setAttribute("reportList", reportList);
            request.setAttribute("selectedMonth", selectedMonth);

            request.getRequestDispatcher("stock_audit_report.jsp")
                   .forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
        } finally {

            try { if(rs!=null) rs.close(); } catch(Exception e){}
            try { if(ps!=null) ps.close(); } catch(Exception e){}
            try { if(con!=null) con.close(); } catch(Exception e){}
        }
    }
}