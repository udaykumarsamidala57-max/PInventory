package com.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
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
import javax.servlet.http.HttpSession;

import com.bean.DBUtil;

@WebServlet("/DiningHallServlet")
public class DiningHallServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /* =========================================================
       GET
       ========================================================= */

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);

        if (sess == null ||
            sess.getAttribute("username") == null) {

            response.sendRedirect("login.jsp");
            return;
        }

        String branch =
                (String) sess.getAttribute("branch");

        if (branch == null ||
            branch.trim().isEmpty()) {

            throw new ServletException(
                    "Branch information is missing from session.");
        }

        try (Connection con = DBUtil.getConnection(branch)) {

            /* =====================================================
               NEXT ISSUE NUMBER
               ===================================================== */

            int nextIssueNo = 1;

            String sqlNext =
                    "SELECT COALESCE(" +
                    "MAX(CAST(SUBSTRING(issueno, 4) AS UNSIGNED)), 0" +
                    ") + 1 AS next_no " +
                    "FROM dining_hall_consumption";

            try (PreparedStatement ps =
                         con.prepareStatement(sqlNext);
                 ResultSet rs =
                         ps.executeQuery()) {

                if (rs.next()) {
                    nextIssueNo =
                            rs.getInt("next_no");
                }
            }

            String formattedIssueNo =
                    "ISS" + nextIssueNo;

            request.setAttribute(
                    "nextIssueNo",
                    formattedIssueNo);


            /* =====================================================
               DEPARTMENT
               ===================================================== */

            Map<String, Object> masterData =
                    new HashMap<String, Object>();

            List<Map<String, String>> departments =
                    new ArrayList<Map<String, String>>();

            Map<String, String> singleDept =
                    new HashMap<String, String>();

            singleDept.put(
                    "name",
                    "Dining Hall");

            departments.add(singleDept);


            /* =====================================================
               DINING HALL CATEGORIES
               ===================================================== */

            List<Map<String, String>> categories =
                    new ArrayList<Map<String, String>>();

            String catSql =
                    "SELECT DISTINCT Category, Department " +
                    "FROM dept_cate " +
                    "WHERE Department = 'Dining Hall'";

            try (PreparedStatement ps =
                         con.prepareStatement(catSql);
                 ResultSet rs =
                         ps.executeQuery()) {

                while (rs.next()) {

                    Map<String, String> c =
                            new HashMap<String, String>();

                    c.put(
                            "name",
                            rs.getString("Category"));

                    c.put(
                            "departmentName",
                            rs.getString("Department"));

                    categories.add(c);
                }
            }


            /* =====================================================
               ACTIVE SUBCATEGORIES
               ===================================================== */

            List<Map<String, String>> subcats =
                    new ArrayList<Map<String, String>>();

            String subSql =
                    "SELECT Sub_Category, Category " +
                    "FROM category " +
                    "WHERE Status = 'Active'";

            try (PreparedStatement ps =
                         con.prepareStatement(subSql);
                 ResultSet rs =
                         ps.executeQuery()) {

                while (rs.next()) {

                    Map<String, String> s =
                            new HashMap<String, String>();

                    s.put(
                            "name",
                            rs.getString("Sub_Category"));

                    s.put(
                            "categoryName",
                            rs.getString("Category"));

                    subcats.add(s);
                }
            }


            /* =====================================================
               ITEMS + CURRENT STOCK
               ===================================================== */

            List<Map<String, String>> items =
                    new ArrayList<Map<String, String>>();

            String itemSql =
                    "SELECT " +
                    "im.Item_id, " +
                    "im.Item_name, " +
                    "im.UOM, " +
                    "im.Category, " +
                    "im.Sub_Category, " +
                    "COALESCE(s.balance_qty, 0) AS stock " +
                    "FROM item_master im " +
                    "LEFT JOIN stock s " +
                    "ON im.Item_id = s.item_id";

            try (PreparedStatement ps =
                         con.prepareStatement(itemSql);
                 ResultSet rs =
                         ps.executeQuery()) {

                while (rs.next()) {

                    Map<String, String> i =
                            new HashMap<String, String>();

                    i.put(
                            "id",
                            String.valueOf(
                                    rs.getInt("Item_id")));

                    i.put(
                            "name",
                            rs.getString("Item_name"));

                    i.put(
                            "UOM",
                            rs.getString("UOM"));

                    i.put(
                            "category",
                            rs.getString("Category"));

                    i.put(
                            "subcategory",
                            rs.getString("Sub_Category"));

                    i.put(
                            "stock",
                            String.valueOf(
                                    rs.getDouble("stock")));

                    items.add(i);
                }
            }


            /* =====================================================
               SEND MASTER DATA
               ===================================================== */

            masterData.put(
                    "departments",
                    departments);

            masterData.put(
                    "categories",
                    categories);

            masterData.put(
                    "subcategories",
                    subcats);

            masterData.put(
                    "items",
                    items);

            request.setAttribute(
                    "masterData",
                    masterData);

            request.setAttribute(
                    "selectedDept",
                    "Dining Hall");


            /* =====================================================
               FORWARD
               ===================================================== */

            request.getRequestDispatcher(
                    "dining_hall_form.jsp")
                    .forward(
                            request,
                            response);

        } catch (SQLException e) {

            throw new ServletException(
                    "Database Error: " +
                    e.getMessage(),
                    e);
        }
    }


    /* =========================================================
       POST
       ========================================================= */

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess =
                request.getSession(false);

        /* =====================================================
           LOGIN CHECK
           ===================================================== */

        if (sess == null ||
            sess.getAttribute("username") == null) {

            response.sendRedirect("login.jsp");
            return;
        }


        /* =====================================================
           BRANCH
           ===================================================== */

        String branch =
                (String) sess.getAttribute("branch");

        if (branch == null ||
            branch.trim().isEmpty()) {

            sendError(
                    request,
                    response,
                    "Branch information is missing.");

            return;
        }


        /* =====================================================
           HEADER VALUES
           ===================================================== */

        String issueno =
                trimToEmpty(
                        request.getParameter("issueno"));

        String issuedTo =
                trimToEmpty(
                        request.getParameter("issued_to"));

        String department =
                "Dining Hall";

        String session =
                trimToEmpty(
                        request.getParameter("session"));

        String issueDate =
                trimToEmpty(
                        request.getParameter("issue_date"));


        /* =====================================================
           FORM ITEM ARRAYS
           ===================================================== */

        String[] itemIds =
                request.getParameterValues("item_id");

        String[] qtys =
                request.getParameterValues("qty_issued");

        String[] remarksArr =
                request.getParameterValues("remarks");


        /* =====================================================
           BASIC VALIDATION
           ===================================================== */

        if (itemIds == null ||
            itemIds.length == 0) {

            sendError(
                    request,
                    response,
                    "No items were submitted.");

            return;
        }

        if (qtys == null ||
            qtys.length == 0) {

            sendError(
                    request,
                    response,
                    "No quantities were submitted.");

            return;
        }


        if (itemIds.length != qtys.length) {

            sendError(
                    request,
                    response,
                    "Item and quantity rows are mismatched. " +
                    "Items: " + itemIds.length +
                    ", Quantities: " + qtys.length);

            return;
        }


        /* =====================================================
           HEADER VALIDATION
           ===================================================== */

        if (issueno.isEmpty()) {

            sendError(
                    request,
                    response,
                    "Issue number is missing.");

            return;
        }

        if (issuedTo.isEmpty()) {

            sendError(
                    request,
                    response,
                    "Issued To is required.");

            return;
        }

        if (session.isEmpty()) {

            sendError(
                    request,
                    response,
                    "Session is required.");

            return;
        }

        if (issueDate.isEmpty()) {

            sendError(
                    request,
                    response,
                    "Issue date is missing.");

            return;
        }


        Connection con = null;


        try {

            /* =================================================
               CONNECTION
               ================================================= */

            con =
                    DBUtil.getConnection(branch);


            /* =================================================
               START TRANSACTION
               ================================================= */

            con.setAutoCommit(false);


            /* =================================================
               SQL STATEMENTS
               ================================================= */

            /*
             * Lock stock record while checking availability.
             */
            String stockSql =
                    "SELECT " +
                    "balance_qty, " +
                    "last_price " +
                    "FROM stock " +
                    "WHERE item_id = ? " +
                    "FOR UPDATE";


            /*
             * Get latest PO price.
             */
            String poSql =
                    "SELECT net_amount, qty " +
                    "FROM po_items " +
                    "WHERE item_id = ? " +
                    "AND qty > 0 " +
                    "ORDER BY po_id DESC " +
                    "LIMIT 1";


            /*
             * Dining Hall consumption.
             */
            String insConsumption =
                    "INSERT INTO dining_hall_consumption " +
                    "(issueno, item_id, department, issued_to, " +
                    "qty_issued, remarks, unit_price, total_value, " +
                    "session, issue_date) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";


            /*
             * Stock issue.
             */
            String insIssues =
                    "INSERT INTO stock_issues " +
                    "(issueno, item_id, department, issued_to, " +
                    "qty_issued, remarks, unit_price, total_value, " +
                    "issue_date) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";


            /*
             * Stock ledger.
             *
             * IMPORTANT:
             * Ledger becomes the source of truth.
             */
            String insLedger =
                    "INSERT INTO stock_ledger " +
                    "(item_id, trans_type, trans_id, trans_date, " +
                    "qty, running_balance, remarks) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?)";


            /*
             * =================================================
             * STOCK RECONCILIATION
             * =================================================
             *
             * This is your query.
             *
             * It recalculates stock from the complete ledger.
             *
             * Every successful Dining Hall issue will execute
             * this query before COMMIT.
             */
            String reconcileStockSql =
                    "UPDATE stock s " +
                    "JOIN ( " +
                    "    SELECT " +
                    "        item_id, " +
                    "        SUM(CASE " +
                    "                WHEN trans_type = 'RECEIPT' " +
                    "                THEN qty ELSE 0 " +
                    "            END) AS total_received, " +
                    "        SUM(CASE " +
                    "                WHEN trans_type = 'ISSUE' " +
                    "                THEN qty ELSE 0 " +
                    "            END) AS total_issued, " +
                    "        SUM(CASE " +
                    "                WHEN trans_type = 'RECEIPT' " +
                    "                THEN qty " +
                    "                ELSE -qty " +
                    "            END) AS balance " +
                    "    FROM stock_ledger " +
                    "    GROUP BY item_id " +
                    ") x " +
                    "ON s.item_id = x.item_id " +
                    "SET " +
                    "    s.total_received = x.total_received, " +
                    "    s.total_issued   = x.total_issued, " +
                    "    s.balance_qty    = x.balance";


            /* =================================================
               PREPARE STATEMENTS
               ================================================= */

            try (PreparedStatement psStock =
                         con.prepareStatement(stockSql);

                 PreparedStatement psPO =
                         con.prepareStatement(poSql);

                 PreparedStatement psConsumption =
                         con.prepareStatement(
                                 insConsumption);

                 PreparedStatement psIssues =
                         con.prepareStatement(
                                 insIssues,
                                 Statement.RETURN_GENERATED_KEYS);

                 PreparedStatement psLedger =
                         con.prepareStatement(
                                 insLedger);

                 PreparedStatement psReconcile =
                         con.prepareStatement(
                                 reconcileStockSql)) {


                int processedItems = 0;


                /* =================================================
                   PROCESS EACH ITEM
                   ================================================= */

                for (int i = 0;
                     i < itemIds.length;
                     i++) {


                    /* =============================================
                       FORM VALUES
                       ============================================= */

                    String itemIdText =
                            trimToEmpty(
                                    itemIds[i]);

                    String qtyText =
                            trimToEmpty(
                                    qtys[i]);


                    /*
                     * Ignore completely empty dynamic rows.
                     */
                    if (itemIdText.isEmpty() &&
                        qtyText.isEmpty()) {

                        continue;
                    }


                    /* =============================================
                       ITEM ID
                       ============================================= */

                    if (itemIdText.isEmpty()) {

                        throw new SQLException(
                                "Row " +
                                (i + 1) +
                                ": Item ID is missing.");
                    }


                    /* =============================================
                       QUANTITY
                       ============================================= */

                    if (qtyText.isEmpty()) {

                        throw new SQLException(
                                "Row " +
                                (i + 1) +
                                ": Quantity is missing " +
                                "for Item ID " +
                                itemIdText);
                    }


                    int itemId;

                    try {

                        itemId =
                                Integer.parseInt(
                                        itemIdText);

                    } catch (NumberFormatException e) {

                        throw new SQLException(
                                "Row " +
                                (i + 1) +
                                ": Invalid Item ID: " +
                                itemIdText,
                                e);
                    }


                    double qtyIssued;

                    try {

                        qtyIssued =
                                Double.parseDouble(
                                        qtyText);

                    } catch (NumberFormatException e) {

                        throw new SQLException(
                                "Row " +
                                (i + 1) +
                                ": Invalid quantity '" +
                                qtyText +
                                "' for Item ID " +
                                itemId,
                                e);
                    }


                    if (Double.isNaN(qtyIssued) ||
                        Double.isInfinite(qtyIssued) ||
                        qtyIssued <= 0) {

                        throw new SQLException(
                                "Row " +
                                (i + 1) +
                                ": Quantity must be greater " +
                                "than zero for Item ID " +
                                itemId);
                    }


                    /* =============================================
                       REMARKS
                       ============================================= */

                    String remarks = "";

                    if (remarksArr != null &&
                        i < remarksArr.length &&
                        remarksArr[i] != null) {

                        remarks =
                                remarksArr[i].trim();
                    }


                    /* =============================================
                       1. LOCK STOCK
                       ============================================= */

                    double currentBalance = 0.0;

                    double stockLastPrice = 0.0;

                    int stockRowCount = 0;


                    psStock.clearParameters();

                    psStock.setInt(
                            1,
                            itemId);


                    try (ResultSet rs =
                                 psStock.executeQuery()) {

                        while (rs.next()) {

                            stockRowCount++;


                            if (stockRowCount > 1) {

                                throw new SQLException(
                                        "Multiple stock records " +
                                        "found for Item ID " +
                                        itemId +
                                        ". Please check stock table.");
                            }


                            currentBalance =
                                    rs.getDouble(
                                            "balance_qty");


                            stockLastPrice =
                                    rs.getDouble(
                                            "last_price");
                        }
                    }


                    /* =============================================
                       STOCK RECORD MUST EXIST
                       ============================================= */

                    if (stockRowCount == 0) {

                        throw new SQLException(
                                "No stock record exists for Item ID " +
                                itemId +
                                ". Please create the stock record " +
                                "before issuing this item.");
                    }


                    /* =============================================
                       STOCK VALIDATION
                       ============================================= */

                    if (currentBalance < 0) {

                        throw new SQLException(
                                "Invalid negative stock for Item ID " +
                                itemId +
                                ". Current balance: " +
                                currentBalance);
                    }


                    if (qtyIssued > currentBalance) {

                        throw new SQLException(
                                "Insufficient stock for Item ID " +
                                itemId +
                                ". Requested: " +
                                qtyIssued +
                                ", Available: " +
                                currentBalance);
                    }


                    /* =============================================
                       2. DETERMINE UNIT PRICE
                       ============================================= */

                    double unitPrice =
                            stockLastPrice;


                    psPO.clearParameters();

                    psPO.setInt(
                            1,
                            itemId);


                    try (ResultSet rs =
                                 psPO.executeQuery()) {

                        if (rs.next()) {

                            double netAmt =
                                    rs.getDouble(
                                            "net_amount");

                            double poQty =
                                    rs.getDouble(
                                            "qty");


                            if (poQty > 0) {

                                unitPrice =
                                        netAmt / poQty;
                            }
                        }
                    }


                    /* =============================================
                       PRICE VALIDATION
                       ============================================= */

                    if (Double.isNaN(unitPrice) ||
                        Double.isInfinite(unitPrice)) {

                        throw new SQLException(
                                "Invalid unit price for Item ID " +
                                itemId);
                    }


                    /* =============================================
                       3. CALCULATE
                       ============================================= */

                    double totalValue =
                            qtyIssued *
                            unitPrice;


                    double newBalance =
                            currentBalance -
                            qtyIssued;


                    if (Math.abs(newBalance) < 0.0000001) {

                        newBalance = 0.0;
                    }


                    /* =============================================
                       4. DINING HALL CONSUMPTION
                       ============================================= */

                    psConsumption.clearParameters();

                    psConsumption.setString(
                            1,
                            issueno);

                    psConsumption.setInt(
                            2,
                            itemId);

                    psConsumption.setString(
                            3,
                            department);

                    psConsumption.setString(
                            4,
                            issuedTo);

                    psConsumption.setDouble(
                            5,
                            qtyIssued);

                    psConsumption.setString(
                            6,
                            remarks);

                    psConsumption.setDouble(
                            7,
                            unitPrice);

                    psConsumption.setDouble(
                            8,
                            totalValue);

                    psConsumption.setString(
                            9,
                            session);

                    psConsumption.setString(
                            10,
                            issueDate);


                    int consumptionRows =
                            psConsumption.executeUpdate();


                    if (consumptionRows != 1) {

                        throw new SQLException(
                                "dining_hall_consumption INSERT " +
                                "failed for Item ID " +
                                itemId);
                    }


                    /* =============================================
                       5. STOCK ISSUES
                       ============================================= */

                    psIssues.clearParameters();

                    psIssues.setString(
                            1,
                            issueno);

                    psIssues.setInt(
                            2,
                            itemId);

                    psIssues.setString(
                            3,
                            department);

                    psIssues.setString(
                            4,
                            issuedTo);

                    psIssues.setDouble(
                            5,
                            qtyIssued);

                    psIssues.setString(
                            6,
                            remarks);

                    psIssues.setDouble(
                            7,
                            unitPrice);

                    psIssues.setDouble(
                            8,
                            totalValue);

                    psIssues.setString(
                            9,
                            issueDate);


                    int issueRows =
                            psIssues.executeUpdate();


                    if (issueRows != 1) {

                        throw new SQLException(
                                "stock_issues INSERT failed " +
                                "for Item ID " +
                                itemId);
                    }


                    /* =============================================
                       6. GENERATED STOCK ISSUE ID
                       ============================================= */

                    int issueId = 0;


                    try (ResultSet generatedKeys =
                                 psIssues.getGeneratedKeys()) {

                        if (generatedKeys.next()) {

                            issueId =
                                    generatedKeys.getInt(1);
                        }
                    }


                    if (issueId <= 0) {

                        throw new SQLException(
                                "Could not obtain generated " +
                                "stock_issues ID for Item ID " +
                                itemId);
                    }


                    /* =============================================
                       7. STOCK LEDGER
                       ============================================= */

                    psLedger.clearParameters();

                    psLedger.setInt(
                            1,
                            itemId);

                    psLedger.setString(
                            2,
                            "ISSUE");

                    psLedger.setInt(
                            3,
                            issueId);

                    psLedger.setString(
                            4,
                            issueDate);

                    psLedger.setDouble(
                            5,
                            qtyIssued);

                    psLedger.setDouble(
                            6,
                            newBalance);

                    psLedger.setString(
                            7,
                            remarks);


                    int ledgerRows =
                            psLedger.executeUpdate();


                    if (ledgerRows != 1) {

                        throw new SQLException(
                                "stock_ledger INSERT failed " +
                                "for Item ID " +
                                itemId);
                    }


                    /* =============================================
                       ITEM COMPLETED
                       ============================================= */

                    processedItems++;


                    System.out.println(
                            "Dining Hall Issue SUCCESS | " +
                            "Issue No: " +
                            issueno +
                            " | Item ID: " +
                            itemId +
                            " | Qty: " +
                            qtyIssued +
                            " | Old Balance: " +
                            currentBalance +
                            " | New Balance: " +
                            newBalance +
                            " | Unit Price: " +
                            unitPrice +
                            " | Stock Issue ID: " +
                            issueId);
                }


                /* =================================================
                   CHECK PROCESSED ITEMS
                   ================================================= */

                if (processedItems == 0) {

                    throw new SQLException(
                            "No valid item rows were submitted.");
                }


                /* =================================================
                   RECONCILE STOCK FROM LEDGER
                   =================================================
                   
                   IMPORTANT:
                   
                   This executes EVERY TIME a Dining Hall
                   transaction is successfully processed.
                   
                   It recalculates:
                   
                       total_received
                       total_issued
                       balance_qty
                   
                   directly from stock_ledger.
                   
                   Because this is inside the transaction,
                   the newly inserted ISSUE ledger rows are
                   included.
                   ================================================= */

                int reconciledRows =
                        psReconcile.executeUpdate();


                System.out.println(
                        "Stock reconciliation completed | " +
                        "Rows updated: " +
                        reconciledRows);


                /* =================================================
                   COMMIT EVERYTHING
                   ================================================= */

                con.commit();


                System.out.println(
                        "Dining Hall transaction COMMITTED | " +
                        "Issue No: " +
                        issueno +
                        " | Items: " +
                        processedItems +
                        " | Stock rows reconciled: " +
                        reconciledRows);


                /* =================================================
                   REDIRECT
                   ================================================= */

                response.sendRedirect(
                        "DiningHallServlet");
            }


        } catch (Exception e) {


            /* =================================================
               ROLLBACK
               ================================================= */

            if (con != null) {

                try {

                    con.rollback();

                    System.err.println(
                            "Dining Hall transaction ROLLED BACK | " +
                            "Issue No: " +
                            issueno);

                } catch (SQLException rollbackEx) {

                    rollbackEx.printStackTrace();
                }
            }


            /* =================================================
               LOG ERROR
               ================================================= */

            e.printStackTrace();


            /* =================================================
               USER-FRIENDLY ERROR
               ================================================= */

            if (sess != null) {

                String message =
                        "Dining Hall stock transaction failed: " +
                        e.getMessage();

                sess.setAttribute(
                        "errorMessage",
                        message);
            }


            response.sendRedirect(
                    "error.jsp");


        } finally {


            /* =================================================
               CLOSE CONNECTION
               ================================================= */

            if (con != null) {

                try {

                    con.close();

                } catch (SQLException e) {

                    e.printStackTrace();
                }
            }
        }
    }


    /* =========================================================
       HELPER
       ========================================================= */

    private String trimToEmpty(String value) {

        if (value == null) {
            return "";
        }

        return value.trim();
    }


    /* =========================================================
       ERROR HELPER
       ========================================================= */

    private void sendError(HttpServletRequest request,
                           HttpServletResponse response,
                           String message)
            throws IOException {

        HttpSession sess =
                request.getSession(false);

        if (sess != null) {

            sess.setAttribute(
                    "errorMessage",
                    message);
        }

        response.sendRedirect(
                "error.jsp");
    }
}