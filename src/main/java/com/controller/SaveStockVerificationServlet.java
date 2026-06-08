package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

@WebServlet("/StockVerificationServlet")
public class SaveStockVerificationServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Connection con = null;

        try {

            con = DBUtil.getConnection();

            String category =
                    request.getParameter("category");

            String subCategory =
                    request.getParameter("subcategory");

            // Categories
            List<String> categoryList =
                    new ArrayList<String>();

            PreparedStatement psCat =
                    con.prepareStatement(
                            "SELECT DISTINCT Category " +
                            "FROM item_master " +
                            "ORDER BY Category");

            ResultSet rsCat =
                    psCat.executeQuery();

            while (rsCat.next()) {

                categoryList.add(
                        rsCat.getString("Category"));
            }

            request.setAttribute(
                    "categoryList",
                    categoryList);

            // Sub Categories

            List<String> subCategoryList =
                    new ArrayList<String>();

            String subSql =
                    "SELECT DISTINCT Sub_Category " +
                    "FROM item_master ";

            if (category != null
                    && !category.trim().equals("")) {

                subSql +=
                        "WHERE Category=? ";
            }

            subSql +=
                    "ORDER BY Sub_Category";

            PreparedStatement psSub =
                    con.prepareStatement(subSql);

            if (category != null
                    && !category.trim().equals("")) {

                psSub.setString(1, category);
            }

            ResultSet rsSub =
                    psSub.executeQuery();

            while (rsSub.next()) {

                subCategoryList.add(
                        rsSub.getString(
                                "Sub_Category"));
            }

            request.setAttribute(
                    "subCategoryList",
                    subCategoryList);

            // Stock Items

            String sql =
                    "SELECT " +
                    "s.item_id," +
                    "im.Item_name," +
                    "im.Category," +
                    "im.Sub_Category," +
                    "im.UOM," +
                    "s.balance_qty " +
                    "FROM stock s " +
                    "INNER JOIN item_master im " +
                    "ON s.item_id=im.Item_id " +
                    "WHERE 1=1 ";

            if (category != null
                    && !category.trim().equals("")) {

                sql +=
                        "AND im.Category=? ";
            }

            if (subCategory != null
                    && !subCategory.trim().equals("")) {

                sql +=
                        "AND im.Sub_Category=? ";
            }

            sql +=
                    "ORDER BY im.Item_name";

            PreparedStatement ps =
                    con.prepareStatement(sql);

            int index = 1;

            if (category != null
                    && !category.trim().equals("")) {

                ps.setString(
                        index++,
                        category);
            }

            if (subCategory != null
                    && !subCategory.trim().equals("")) {

                ps.setString(
                        index++,
                        subCategory);
            }

            ResultSet rs =
                    ps.executeQuery();

            List<Map<String,Object>> itemList =
                    new ArrayList<Map<String,Object>>();

            while(rs.next()) {

                Map<String,Object> row =
                        new HashMap<String,Object>();

                row.put(
                        "item_id",
                        rs.getInt("item_id"));

                row.put(
                        "item_name",
                        rs.getString("Item_name"));

                row.put(
                        "category",
                        rs.getString("Category"));

                row.put(
                        "subcategory",
                        rs.getString("Sub_Category"));

                row.put(
                        "uom",
                        rs.getString("UOM"));

                row.put(
                        "balance_qty",
                        rs.getDouble("balance_qty"));

                itemList.add(row);
            }

            request.setAttribute(
                    "itemList",
                    itemList);

            request.setAttribute(
                    "selectedCategory",
                    category);

            request.setAttribute(
                    "selectedSubCategory",
                    subCategory);

            request.getRequestDispatcher(
                    "stock_verification.jsp")
                    .forward(
                            request,
                            response);

        } catch(Exception e) {

            e.printStackTrace();

        } finally {

            try {
                if(con!=null)
                    con.close();
            } catch(Exception e) {}
        }
    }
    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Connection con = null;
        PreparedStatement psHeader = null;
        PreparedStatement psDetail = null;
        ResultSet rs = null;

        try {

            con = DBUtil.getConnection();

            con.setAutoCommit(false);

            String verifiedBy =
                    request.getParameter("verified_by");

            String overallRemarks =
                    request.getParameter("overall_remarks");

            String headerSql =
                    "INSERT INTO stock_verification " +
                    "(verification_date,verified_by,remarks,status) " +
                    "VALUES(CURDATE(),?,?,?)";

            psHeader =
                    con.prepareStatement(
                            headerSql,
                            Statement.RETURN_GENERATED_KEYS);

            psHeader.setString(1, verifiedBy);
            psHeader.setString(2, overallRemarks);
            psHeader.setString(3, "DRAFT");

            psHeader.executeUpdate();

            rs = psHeader.getGeneratedKeys();

            int verificationId = 0;

            if(rs.next()) {

                verificationId = rs.getInt(1);
            }

            String[] itemIds =
                    request.getParameterValues("item_id");

            String[] systemQtys =
                    request.getParameterValues("system_qty");

            String[] physicalQtys =
                    request.getParameterValues("physical_qty");

            String[] remarks =
                    request.getParameterValues("remarks");

            String detailSql =
                    "INSERT INTO stock_verification_details(" +
                    "verification_id," +
                    "item_id," +
                    "system_qty," +
                    "physical_qty," +
                    "variance_qty," +
                    "remarks) " +
                    "VALUES(?,?,?,?,?,?)";

            psDetail =
                    con.prepareStatement(detailSql);

            for(int i=0;i<itemIds.length;i++) {

                int itemId =
                        Integer.parseInt(itemIds[i]);

                double systemQty =
                        Double.parseDouble(
                                systemQtys[i]);

                double physicalQty =
                        Double.parseDouble(
                                physicalQtys[i]);

                double varianceQty =
                        physicalQty - systemQty;

                String remark = "";

                if(remarks != null &&
                        remarks.length > i &&
                        remarks[i] != null) {

                    remark = remarks[i];
                }

                psDetail.setInt(
                        1,
                        verificationId);

                psDetail.setInt(
                        2,
                        itemId);

                psDetail.setDouble(
                        3,
                        systemQty);

                psDetail.setDouble(
                        4,
                        physicalQty);

                psDetail.setDouble(
                        5,
                        varianceQty);

                psDetail.setString(
                        6,
                        remark);

                psDetail.addBatch();
            }

            psDetail.executeBatch();

            con.commit();

            response.sendRedirect(
                    "stock_verification.jsp?id="
                    + verificationId);

        }
        catch(Exception e) {

            try {

                if(con != null) {

                    con.rollback();
                }

            } catch(Exception ex) {

                ex.printStackTrace();
            }

            e.printStackTrace();

            request.setAttribute(
                    "errorMessage",
                    e.getMessage());

            doGet(request,response);
        }
        finally {

            try {
                if(rs!=null) rs.close();
            } catch(Exception e) {}

            try {
                if(psHeader!=null) psHeader.close();
            } catch(Exception e) {}

            try {
                if(psDetail!=null) psDetail.close();
            } catch(Exception e) {}

            try {
                if(con!=null) con.close();
            } catch(Exception e) {}
        }
    }
}