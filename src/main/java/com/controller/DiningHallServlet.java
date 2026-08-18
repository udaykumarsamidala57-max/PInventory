package com.controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

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

    private static final String DEPARTMENT = "Dining Hall";


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
                trimToEmpty(
                        (String) sess.getAttribute("branch"));

        if (branch.isEmpty()) {

            throw new ServletException(
                    "Branch information is missing from session.");
        }


        try (Connection con =
                     DBUtil.getConnection(branch)) {


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
               MASTER DATA
               ===================================================== */

            Map<String, Object> masterData =
                    new HashMap<String, Object>();


            /* =====================================================
               DEPARTMENT
               ===================================================== */

            List<Map<String, String>> departments =
                    new ArrayList<Map<String, String>>();

            Map<String, String> dept =
                    new HashMap<String, String>();

            dept.put(
                    "name",
                    DEPARTMENT);

            departments.add(dept);


            /* =====================================================
               CATEGORIES
               ===================================================== */

            List<Map<String, String>> categories =
                    new ArrayList<Map<String, String>>();

            String catSql =
                    "SELECT DISTINCT Category, Department " +
                    "FROM dept_cate " +
                    "WHERE Department = ? " +
                    "ORDER BY Category";

            try (PreparedStatement ps =
                         con.prepareStatement(catSql)) {

                ps.setString(
                        1,
                        DEPARTMENT);

                try (ResultSet rs =
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
            }


            /* =====================================================
               ACTIVE SUBCATEGORIES
               ===================================================== */

            List<Map<String, String>> subcategories =
                    new ArrayList<Map<String, String>>();

            String subSql =
                    "SELECT Sub_Category, Category " +
                    "FROM category " +
                    "WHERE Status = 'Active' " +
                    "ORDER BY Category, Sub_Category";

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

                    subcategories.add(s);
                }
            }


            /* =====================================================
               ITEMS + STOCK
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
                    "ON im.Item_id = s.item_id " +
                    "ORDER BY im.Category, " +
                    "im.Sub_Category, " +
                    "im.Item_name";

            try (PreparedStatement ps =
                         con.prepareStatement(itemSql);
                 ResultSet rs =
                         ps.executeQuery()) {

                while (rs.next()) {

                    Map<String, String> item =
                            new HashMap<String, String>();

                    item.put(
                            "id",
                            String.valueOf(
                                    rs.getInt("Item_id")));

                    item.put(
                            "name",
                            rs.getString("Item_name"));

                    item.put(
                            "UOM",
                            rs.getString("UOM"));

                    item.put(
                            "category",
                            rs.getString("Category"));

                    item.put(
                            "subcategory",
                            rs.getString("Sub_Category"));

                    item.put(
                            "stock",
                            rs.getString("stock"));

                    items.add(item);
                }
            }


            /* =====================================================
               SEND DATA TO JSP
               ===================================================== */

            masterData.put(
                    "departments",
                    departments);

            masterData.put(
                    "categories",
                    categories);

            masterData.put(
                    "subcategories",
                    subcategories);

            masterData.put(
                    "items",
                    items);

            request.setAttribute(
                    "masterData",
                    masterData);

            request.setAttribute(
                    "selectedDept",
                    DEPARTMENT);


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
                trimToEmpty(
                        (String) sess.getAttribute("branch"));

        if (branch.isEmpty()) {

            sendError(
                    request,
                    response,
                    "Branch information is missing.");

            return;
        }


        /* =====================================================
           HEADER
           ===================================================== */

        String issueno =
                trimToEmpty(
                        request.getParameter("issueno"));

        String issuedTo =
                trimToEmpty(
                        request.getParameter("issued_to"));

        String session =
                trimToEmpty(
                        request.getParameter("session"));

        String issueDate =
                trimToEmpty(
                        request.getParameter("issue_date"));


        /* =====================================================
           VALIDATE HEADER
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
                    "Issue date is required.");

            return;
        }


        /* =====================================================
           ITEM ARRAYS
           ===================================================== */

        String[] itemIds =
                request.getParameterValues("item_id");

        String[] qtys =
                request.getParameterValues("qty_issued");

        String[] remarksArr =
                request.getParameterValues("remarks");


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
                    "Item and quantity rows are mismatched.");

            return;
        }


        Connection con = null;


        try {

            /* =================================================
               OPEN CONNECTION
               ================================================= */

            con =
                    DBUtil.getConnection(branch);


            if (con == null) {

                throw new SQLException(
                        "Unable to establish database connection.");
            }


            /* =================================================
               IMPORTANT:
               START ONE TRANSACTION
               ================================================= */

            con.setAutoCommit(false);


            System.out.println(
                    "================================================");

            System.out.println(
                    "Dining Hall Transaction STARTED");

            System.out.println(
                    "Issue No : " + issueno);

            System.out.println(
                    "Branch   : " + branch);

            System.out.println(
                    "================================================");


            /* =================================================
               PREVENT DUPLICATE ISSUE NUMBER
               ================================================= */

            String duplicateIssueSql =
                    "SELECT 1 " +
                    "FROM dining_hall_consumption " +
                    "WHERE issueno = ? " +
                    "LIMIT 1 " +
                    "FOR UPDATE";

            try (PreparedStatement ps =
                         con.prepareStatement(
                                 duplicateIssueSql)) {

                ps.setString(
                        1,
                        issueno);

                try (ResultSet rs =
                             ps.executeQuery()) {

                    if (rs.next()) {

                        throw new SQLException(
                                "Issue number " +
                                issueno +
                                " already exists.");
                    }
                }
            }


            /* =================================================
               SQL 1
               LOCK STOCK
               ================================================= */

            String stockSql =
                    "SELECT " +
                    "balance_qty, " +
                    "last_price " +
                    "FROM stock " +
                    "WHERE item_id = ? " +
                    "FOR UPDATE";


            /* =================================================
               SQL 2
               GET LATEST PO PRICE
               ================================================= */

            String poSql =
                    "SELECT net_amount, qty " +
                    "FROM po_items " +
                    "WHERE item_id = ? " +
                    "AND qty > 0 " +
                    "ORDER BY po_id DESC " +
                    "LIMIT 1";


            /* =================================================
               SQL 3
               DINING HALL CONSUMPTION

               10 columns
               10 placeholders
               ================================================= */

            String insConsumption =
                    "INSERT INTO dining_hall_consumption " +
                    "(issueno, item_id, department, issued_to, " +
                    "qty_issued, remarks, unit_price, total_value, " +
                    "session, issue_date) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";


            /* =================================================
               SQL 4
               STOCK ISSUES

               IMPORTANT:
               9 columns
               9 placeholders
               ================================================= */

            String insIssues =
                    "INSERT INTO stock_issues " +
                    "(issueno, item_id, department, issued_to, " +
                    "qty_issued, remarks, unit_price, total_value, " +
                    "issue_date) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";


            /* =================================================
               SQL 5
               STOCK LEDGER
               ================================================= */

            String insLedger =
                    "INSERT INTO stock_ledger " +
                    "(item_id, trans_type, trans_id, trans_date, " +
                    "qty, running_balance, remarks) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?)";


            /* =================================================
               SQL 6
               RECONCILE STOCK

               IMPORTANT:
               This happens ONLY after every issue has been
               successfully inserted into the ledger.
               ================================================= */

            String reconcileStockSql =
                    "UPDATE stock s " +
                    "JOIN ( " +

                    "SELECT " +
                    "item_id, " +

                    "SUM( " +
                    "CASE " +
                    "WHEN trans_type = 'RECEIPT' " +
                    "THEN qty " +
                    "ELSE 0 " +
                    "END " +
                    ") AS total_received, " +

                    "SUM( " +
                    "CASE " +
                    "WHEN trans_type = 'ISSUE' " +
                    "THEN qty " +
                    "ELSE 0 " +
                    "END " +
                    ") AS total_issued, " +

                    "SUM( " +
                    "CASE " +
                    "WHEN trans_type = 'RECEIPT' " +
                    "THEN qty " +
                    "ELSE -qty " +
                    "END " +
                    ") AS balance " +

                    "FROM stock_ledger " +

                    "GROUP BY item_id " +

                    ") x " +

                    "ON s.item_id = x.item_id " +

                    "SET " +
                    "s.total_received = x.total_received, " +
                    "s.total_issued = x.total_issued, " +
                    "s.balance_qty = x.balance";


            /* =================================================
               PREPARE ALL STATEMENTS
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


                /* =================================================
                   TRACK ITEMS
                   ================================================= */

                Set<Integer> processedItemIds =
                        new HashSet<Integer>();


                int processedItems = 0;


                /* =================================================
                   PROCESS EVERY ITEM
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


                    /* =============================================
                       IGNORE COMPLETELY EMPTY ROW
                       ============================================= */

                    if (itemIdText.isEmpty() &&
                        qtyText.isEmpty()) {

                        continue;
                    }


                    /* =============================================
                       ITEM ID VALIDATION
                       ============================================= */

                    if (itemIdText.isEmpty()) {

                        throw new SQLException(
                                "Row " +
                                (i + 1) +
                                ": Item is missing.");
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
                                itemIdText);
                    }


                    /* =============================================
                       PREVENT DUPLICATE ITEM IN SAME ISSUE
                       ============================================= */

                    if (processedItemIds.contains(itemId)) {

                        throw new SQLException(
                                "Item ID " +
                                itemId +
                                " has been selected more than once. " +
                                "Please keep one row per item.");
                    }


                    processedItemIds.add(itemId);


                    /* =============================================
                       QUANTITY VALIDATION
                       ============================================= */

                    if (qtyText.isEmpty()) {

                        throw new SQLException(
                                "Row " +
                                (i + 1) +
                                ": Quantity is missing " +
                                "for Item ID " +
                                itemId);
                    }


                    BigDecimal qtyIssued;

                    try {

                        qtyIssued =
                                new BigDecimal(
                                        qtyText);

                    } catch (NumberFormatException e) {

                        throw new SQLException(
                                "Row " +
                                (i + 1) +
                                ": Invalid quantity: " +
                                qtyText);
                    }


                    if (qtyIssued.compareTo(
                            BigDecimal.ZERO) <= 0) {

                        throw new SQLException(
                                "Row " +
                                (i + 1) +
                                ": Quantity must be greater than zero.");
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
                       1. LOCK STOCK ROW
                       ============================================= */

                    BigDecimal currentBalance =
                            BigDecimal.ZERO;

                    BigDecimal stockLastPrice =
                            BigDecimal.ZERO;

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
                                        "Multiple stock records found " +
                                        "for Item ID " +
                                        itemId);
                            }


                            currentBalance =
                                    rs.getBigDecimal(
                                            "balance_qty");

                            if (currentBalance == null) {

                                currentBalance =
                                        BigDecimal.ZERO;
                            }


                            stockLastPrice =
                                    rs.getBigDecimal(
                                            "last_price");

                            if (stockLastPrice == null) {

                                stockLastPrice =
                                        BigDecimal.ZERO;
                            }
                        }
                    }


                    /* =============================================
                       STOCK RECORD MUST EXIST
                       ============================================= */

                    if (stockRowCount == 0) {

                        throw new SQLException(
                                "No stock record exists for Item ID " +
                                itemId);
                    }


                    /* =============================================
                       NEGATIVE STOCK CHECK
                       ============================================= */

                    if (currentBalance.compareTo(
                            BigDecimal.ZERO) < 0) {

                        throw new SQLException(
                                "Invalid negative stock for Item ID " +
                                itemId +
                                ". Current stock: " +
                                currentBalance);
                    }


                    /* =============================================
                       AVAILABLE STOCK CHECK
                       ============================================= */

                    if (qtyIssued.compareTo(
                            currentBalance) > 0) {

                        throw new SQLException(
                                "Insufficient stock for Item ID " +
                                itemId +
                                ". Requested: " +
                                qtyIssued +
                                ", Available: " +
                                currentBalance);
                    }


                    /* =============================================
                       2. DETERMINE PRICE
                       ============================================= */

                    BigDecimal unitPrice =
                            stockLastPrice;


                    psPO.clearParameters();

                    psPO.setInt(
                            1,
                            itemId);


                    try (ResultSet rs =
                                 psPO.executeQuery()) {

                        if (rs.next()) {

                            BigDecimal netAmount =
                                    rs.getBigDecimal(
                                            "net_amount");

                            BigDecimal poQty =
                                    rs.getBigDecimal(
                                            "qty");


                            if (netAmount != null &&
                                poQty != null &&
                                poQty.compareTo(
                                        BigDecimal.ZERO) > 0) {

                                unitPrice =
                                        netAmount.divide(
                                                poQty,
                                                6,
                                                RoundingMode.HALF_UP);
                            }
                        }
                    }


                    if (unitPrice == null) {

                        unitPrice =
                                BigDecimal.ZERO;
                    }


                    /* =============================================
                       3. CALCULATE TOTAL
                       ============================================= */

                    BigDecimal totalValue =
                            qtyIssued.multiply(
                                    unitPrice);


                    totalValue =
                            totalValue.setScale(
                                    2,
                                    RoundingMode.HALF_UP);


                    BigDecimal newBalance =
                            currentBalance.subtract(
                                    qtyIssued);


                    if (newBalance.abs().compareTo(
                            new BigDecimal("0.000001")) < 0) {

                        newBalance =
                                BigDecimal.ZERO;
                    }


                    /* =============================================
                       4. INSERT DINING HALL CONSUMPTION
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
                            DEPARTMENT);

                    psConsumption.setString(
                            4,
                            issuedTo);

                    psConsumption.setBigDecimal(
                            5,
                            qtyIssued);

                    psConsumption.setString(
                            6,
                            remarks);

                    psConsumption.setBigDecimal(
                            7,
                            unitPrice);

                    psConsumption.setBigDecimal(
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
                                "Dining Hall consumption insert failed " +
                                "for Item ID " +
                                itemId);
                    }


                    /* =============================================
                       5. INSERT STOCK ISSUE
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
                            DEPARTMENT);

                    psIssues.setString(
                            4,
                            issuedTo);

                    psIssues.setBigDecimal(
                            5,
                            qtyIssued);

                    psIssues.setString(
                            6,
                            remarks);

                    psIssues.setBigDecimal(
                            7,
                            unitPrice);

                    psIssues.setBigDecimal(
                            8,
                            totalValue);

                    psIssues.setString(
                            9,
                            issueDate);


                    int issueRows =
                            psIssues.executeUpdate();


                    if (issueRows != 1) {

                        throw new SQLException(
                                "Stock issue insert failed " +
                                "for Item ID " +
                                itemId);
                    }


                    /* =============================================
                       6. GET GENERATED STOCK ISSUE ID
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
                                "Unable to obtain stock issue ID " +
                                "for Item ID " +
                                itemId);
                    }


                    /* =============================================
                       7. INSERT STOCK LEDGER
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

                    psLedger.setBigDecimal(
                            5,
                            qtyIssued);

                    psLedger.setBigDecimal(
                            6,
                            newBalance);

                    psLedger.setString(
                            7,
                            remarks);


                    int ledgerRows =
                            psLedger.executeUpdate();


                    if (ledgerRows != 1) {

                        throw new SQLException(
                                "Stock ledger insert failed " +
                                "for Item ID " +
                                itemId);
                    }


                    /* =============================================
                       ITEM SUCCESSFULLY PROCESSED
                       ============================================= */

                    processedItems++;


                    System.out.println(
                            "Dining Hall Item SUCCESS | " +
                            "Issue No=" + issueno +
                            " | Item ID=" + itemId +
                            " | Qty=" + qtyIssued +
                            " | Old Stock=" + currentBalance +
                            " | New Stock=" + newBalance +
                            " | Price=" + unitPrice +
                            " | Issue ID=" + issueId);
                }


                /* =================================================
                   AT LEAST ONE ITEM REQUIRED
                   ================================================= */

                if (processedItems == 0) {

                    throw new SQLException(
                            "No valid items were submitted.");
                }


                /* =================================================
                   8. RECONCILE STOCK
                   ================================================= */

                int reconciledRows =
                        psReconcile.executeUpdate();


                System.out.println(
                        "Stock reconciliation completed | " +
                        "Rows=" +
                        reconciledRows);


                /* =================================================
                   9. FINAL COMMIT
                   
                   NOTHING is committed before this point.
                   ================================================= */

                con.commit();


                System.out.println(
                        "================================================");

                System.out.println(
                        "Dining Hall Transaction COMMITTED");

                System.out.println(
                        "Issue No : " +
                        issueno);

                System.out.println(
                        "Items    : " +
                        processedItems);

                System.out.println(
                        "================================================");


                /* =================================================
                   SUCCESS
                   ================================================= */

                response.sendRedirect(
                        "DiningHallServlet");

            }


        } catch (Exception e) {


            /* =====================================================
               VERY IMPORTANT
               
               ANY ERROR = ROLLBACK EVERYTHING
               ===================================================== */

            if (con != null) {

                try {

                    con.rollback();

                    System.err.println(
                            "================================================");

                    System.err.println(
                            "Dining Hall Transaction ROLLED BACK");

                    System.err.println(
                            "Issue No : " +
                            issueno);

                    System.err.println(
                            "Reason   : " +
                            e.getMessage());

                    System.err.println(
                            "================================================");

                } catch (SQLException rollbackEx) {

                    System.err.println(
                            "ROLLBACK FAILED!");

                    rollbackEx.printStackTrace();
                }
            }


            /* =====================================================
               LOG ORIGINAL ERROR
               ===================================================== */

            e.printStackTrace();


            /* =====================================================
               USER ERROR
               ===================================================== */

            String message =
                    "Dining Hall transaction failed. " +
                    "No data was saved. ";

            if (e.getMessage() != null &&
                !e.getMessage().trim().isEmpty()) {

                message += e.getMessage();
            }


            if (sess != null) {

                sess.setAttribute(
                        "errorMessage",
                        message);
            }


            response.sendRedirect(
                    "error.jsp");


        } finally {


            /* =====================================================
               CLOSE CONNECTION
               ===================================================== */

            if (con != null) {

                try {

                    /*
                     * Safety:
                     * make sure connection is not left
                     * with autoCommit=false.
                     */
                    con.setAutoCommit(true);

                } catch (SQLException e) {

                    e.printStackTrace();
                }


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