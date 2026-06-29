package com.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.bean.DBUtil;

@WebServlet("/StockVerificationServlet")
public class SaveStockVerificationServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String category =
                request.getParameter("category");

        String subCategory =
                request.getParameter("subcategory");

        String filterMonth =
                request.getParameter("filter_month");

        if (filterMonth == null ||
                filterMonth.trim().isEmpty()) {

            filterMonth =
                    java.time.LocalDate.now()
                    .format(
                            java.time.format.DateTimeFormatter
                            .ofPattern("yyyy-MM"));
        }

        java.time.YearMonth ym =
                java.time.YearMonth.parse(filterMonth);

        String fromDate =
                ym.atDay(1).toString();

        String toDate =
                ym.atEndOfMonth().toString();

        try (Connection con = DBUtil.getConnection()) {

            /* --------------------------
             * CATEGORY LIST
             * -------------------------- */

            List<String> categoryList =
                    new ArrayList<String>();

            PreparedStatement psCat =
                    con.prepareStatement(
                            "SELECT DISTINCT Category " +
                            "FROM item_master " +
                            "WHERE Category IS NOT NULL " +
                            "ORDER BY Category");

            ResultSet rsCat =
                    psCat.executeQuery();

            while (rsCat.next()) {

                categoryList.add(
                        rsCat.getString("Category"));
            }

            /* --------------------------
             * SUB CATEGORY LIST
             * -------------------------- */

            List<String> subCategoryList =
                    new ArrayList<String>();

            String subSql =
                    "SELECT DISTINCT Sub_Category " +
                    "FROM item_master " +
                    "WHERE Sub_Category IS NOT NULL ";

            if (category != null &&
                    !category.trim().isEmpty() &&
                    !category.equals("ALL")) {

                subSql +=
                        "AND Category=? ";
            }

            subSql +=
                    "ORDER BY Sub_Category";

            PreparedStatement psSub =
                    con.prepareStatement(subSql);

            if (category != null &&
                    !category.trim().isEmpty() &&
                    !category.equals("ALL")) {

                psSub.setString(1, category);
            }

            ResultSet rsSub =
                    psSub.executeQuery();

            while (rsSub.next()) {

                subCategoryList.add(
                        rsSub.getString(
                                "Sub_Category"));
            }

            /* --------------------------
             * INCORPORATED NEW STOCK QUERY
             * -------------------------- */

            /* --------------------------
             * STOCK QUERY
             * -------------------------- */

            String itemSql =
                "SELECT " +
                "im.Item_id, " +
                "im.Item_name, " +
                "im.Category, " +
                "im.Sub_Category, " +
                "im.UOM, " +

                /* Opening Balance */
                "COALESCE(( " +
                "   SELECT SUM(CASE " +
                "       WHEN sl.trans_type='RECEIPT' THEN sl.qty " +
                "       WHEN sl.trans_type='ISSUE' THEN -sl.qty " +
                "       ELSE 0 END) " +
                "   FROM stock_ledger sl " +
                "   WHERE sl.item_id = im.Item_id " +
                "   AND sl.trans_date < ? " +
                "),0) AS opening_balance, " +

                /* Receipts */
                "COALESCE(( " +
                "   SELECT SUM(sl.qty) " +
                "   FROM stock_ledger sl " +
                "   WHERE sl.item_id = im.Item_id " +
                "   AND sl.trans_type='RECEIPT' " +
                "   AND sl.trans_date BETWEEN ? AND ? " +
                "),0) AS receipts, " +

                /* Issues */
                "COALESCE(( " +
                "   SELECT SUM(sl.qty) " +
                "   FROM stock_ledger sl " +
                "   WHERE sl.item_id = im.Item_id " +
                "   AND sl.trans_type='ISSUE' " +
                "   AND sl.trans_date BETWEEN ? AND ? " +
                "),0) AS issues, " +

                /* Closing Balance */
                "COALESCE(( " +
                "   SELECT SUM(CASE " +
                "       WHEN sl.trans_type='RECEIPT' THEN sl.qty " +
                "       WHEN sl.trans_type='ISSUE' THEN -sl.qty " +
                "       ELSE 0 END) " +
                "   FROM stock_ledger sl " +
                "   WHERE sl.item_id = im.Item_id " +
                "   AND sl.trans_date <= ? " +
                "),0) AS closing_balance " +

                "FROM item_master im " +
                "WHERE 1=1 ";

            if (category != null &&
                !category.trim().isEmpty() &&
                !category.equals("ALL")) {

                itemSql += " AND im.Category=? ";
            }

            if (subCategory != null &&
                !subCategory.trim().isEmpty() &&
                !subCategory.equals("ALL")) {

                itemSql += " AND im.Sub_Category=? ";
            }

            itemSql += " ORDER BY im.Category, im.Item_name";

            PreparedStatement ps =
                    con.prepareStatement(itemSql);

            int idx = 1;

            java.sql.Date fromSqlDate =
                    java.sql.Date.valueOf(fromDate);

            java.sql.Date toSqlDate =
                    java.sql.Date.valueOf(toDate);

            // Set parameters matching your subqueries
            ps.setDate(idx++, fromSqlDate); // opening_balance (< ?)

            ps.setDate(idx++, fromSqlDate); // receipts (BETWEEN ?)
            ps.setDate(idx++, toSqlDate);   // receipts (AND ?)

            ps.setDate(idx++, fromSqlDate); // issues (BETWEEN ?)
            ps.setDate(idx++, toSqlDate);   // issues (AND ?)

            ps.setDate(idx++, toSqlDate);   // closing_balance (<= ?)

            if (category != null && !category.trim().isEmpty() && !category.equals("ALL")) {
                ps.setString(idx++, category);
            }

            if (subCategory != null && !subCategory.trim().isEmpty() && !subCategory.equals("ALL")) {
                ps.setString(idx++, subCategory);
            }

            ResultSet rs =
                    ps.executeQuery();

            List<Map<String, Object>> itemList =
                    new ArrayList<Map<String, Object>>();

            while (rs.next()) {

                double opening = rs.getDouble("opening_balance");
                double purchase = rs.getDouble("receipts");
                double consume = rs.getDouble("issues");
                double balance = rs.getDouble("closing_balance");

                Map<String, Object> row =
                        new HashMap<String, Object>();

                row.put("item_id", rs.getInt("Item_id"));
                row.put("item_name", rs.getString("Item_name"));
                row.put("category", rs.getString("Category"));
                row.put("subcategory", rs.getString("Sub_Category"));
                row.put("uom", rs.getString("UOM"));
                
                // Mapped to existing keys so your UI/JSP doesn't break
                row.put("opening_qty", opening);
                row.put("purchase_qty", purchase);
                row.put("consume_qty", consume);
                row.put("balance_qty", balance); 

                itemList.add(row);
            }

            /* --------------------------
             * JSP ATTRIBUTES
             * -------------------------- */

            request.setAttribute(
                    "categoryList",
                    categoryList);

            request.setAttribute(
                    "subCategoryList",
                    subCategoryList);

            request.setAttribute(
                    "selectedCategory",
                    category);

            request.setAttribute(
                    "selectedSubCategory",
                    subCategory);

            request.setAttribute(
                    "selectedMonth",
                    filterMonth);

            request.setAttribute(
                    "itemList",
                    itemList);

            request.getRequestDispatcher(
                    "stock_verification.jsp")
                    .forward(
                            request,
                            response);

        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {
    	
    	String verifiedBy =
                (String) request.getSession()
                .getAttribute("username");

        String remarks =
                request.getParameter("overall_remarks");

        String[] itemIds =
                request.getParameterValues("item_id");

        String[] systemQtys =
                request.getParameterValues("system_qty");

        String[] physicalQtys =
                request.getParameterValues("physical_qty");

        String[] remarksList =
                request.getParameterValues("remarks");

        try (Connection con = DBUtil.getConnection()) {

            con.setAutoCommit(false);

            String headerSql =
                    "INSERT INTO stock_verification " +
                    "(verification_date,verified_by,remarks,status) " +
                    "VALUES(CURDATE(),?,?,?)";

            int verificationId = 0;

            PreparedStatement psHeader =
                    con.prepareStatement(
                            headerSql,
                            Statement.RETURN_GENERATED_KEYS);

            psHeader.setString(1, verifiedBy);
            psHeader.setString(2, remarks);
            psHeader.setString(3, "DRAFT");

            psHeader.executeUpdate();

            ResultSet rs =
                    psHeader.getGeneratedKeys();

            if (rs.next()) {
                verificationId = rs.getInt(1);
            }

            String detailSql =
                    "INSERT INTO stock_verification_details(" +
                    "verification_id," +
                    "item_id," +
                    "system_qty," +
                    "physical_qty," +
                    "variance_qty," +
                    "remarks) " +
                    "VALUES(?,?,?,?,?,?)";

            PreparedStatement psDetail =
                    con.prepareStatement(detailSql);

            for (int i = 0; i < itemIds.length; i++) {

                double systemQty =
                        Double.parseDouble(
                                systemQtys[i]);

                double physicalQty =
                        Double.parseDouble(
                                physicalQtys[i]);

                psDetail.setInt(1, verificationId);
                psDetail.setInt(2, Integer.parseInt(itemIds[i]));
                psDetail.setDouble(3, systemQty);
                psDetail.setDouble(4, physicalQty);
                psDetail.setDouble(5, physicalQty - systemQty);
                psDetail.setString(6, remarksList != null && remarksList.length > i ? remarksList[i] : "");

                psDetail.addBatch();
            }

            psDetail.executeBatch();
            con.commit();

            response.sendRedirect(
                    "StockVerificationServlet");

        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }
}