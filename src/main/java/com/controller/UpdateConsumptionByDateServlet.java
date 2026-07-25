package com.controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashSet;
import java.util.Set;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.bean.DBUtil;

@WebServlet("/UpdateConsumptionByDateServlet")
public class UpdateConsumptionByDateServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String selectedDate = request.getParameter("selected_date");
        String[] selectedIssueIds = request.getParameterValues("selected_issue_id");

        // Redirect back if no issues were selected
        if (selectedIssueIds == null || selectedIssueIds.length == 0) {
            response.sendRedirect("FetchConsumptionByDateServlet?selected_date=" + encodeParam(selectedDate));
            return;
        }

        Connection con = null;
        Set<Integer> affectedItemIds = new HashSet<>();

        try {
            con = DBUtil.getConnection();
            con.setAutoCommit(false); // Enable manual transaction management

            // SQL Pre-compilation
            String fetchSql = "SELECT item_id, po_item_id, qty_issued, unit_price "
                            + "FROM dining_hall_consumption WHERE issue_id = ?";

            String updateConsSql = "UPDATE dining_hall_consumption "
                                 + "SET department = ?, issued_to = ?, qty_issued = ?, remarks = ?, total_value = ? "
                                 + "WHERE issue_id = ?";

            String updateLedgerSql = "UPDATE stock_ledger "
                                   + "SET qty = ?, remarks = ? "
                                   + "WHERE consumption_id = ? AND item_id = ? AND UPPER(TRIM(trans_type)) = 'ISSUE'";

            String insertLedgerSql = "INSERT INTO stock_ledger "
                                   + "(consumption_id, item_id, trans_type, qty, remarks, trans_date, running_balance) "
                                   + "VALUES (?, ?, 'ISSUE', ?, ?, CURRENT_DATE, 0.00)";

            String updateStockPoSql = "UPDATE stock "
                                    + "SET total_issued = COALESCE(total_issued, 0) + ?, "
                                    + "    balance_qty = COALESCE(balance_qty, 0) - ? "
                                    + "WHERE item_id = ? AND po_item_id = ?";

            String updateStockFallbackSql = "UPDATE stock "
                                          + "SET total_issued = COALESCE(total_issued, 0) + ?, "
                                          + "    balance_qty = COALESCE(balance_qty, 0) - ? "
                                          + "WHERE item_id = ?";

            try (PreparedStatement psFetch = con.prepareStatement(fetchSql);
                 PreparedStatement psCons = con.prepareStatement(updateConsSql);
                 PreparedStatement psLedger = con.prepareStatement(updateLedgerSql);
                 PreparedStatement psInsertLedger = con.prepareStatement(insertLedgerSql);
                 PreparedStatement psStockPo = con.prepareStatement(updateStockPoSql);
                 PreparedStatement psStockFallback = con.prepareStatement(updateStockFallbackSql)) {

                for (String issueIdStr : selectedIssueIds) {
                    if (issueIdStr == null || issueIdStr.trim().isEmpty()) {
                        continue;
                    }

                    int issueId;
                    try {
                        issueId = Integer.parseInt(issueIdStr.trim());
                    } catch (NumberFormatException e) {
                        continue;
                    }

                    String qtyStr = request.getParameter("qty_issued_" + issueId);
                    String department = request.getParameter("department_" + issueId);
                    String issuedTo = request.getParameter("issued_to_" + issueId);
                    String remark = request.getParameter("remarks_" + issueId);

                    if (qtyStr == null || qtyStr.trim().isEmpty()) {
                        continue;
                    }

                    BigDecimal newQty;
                    try {
                        newQty = new BigDecimal(qtyStr.trim());
                        if (newQty.compareTo(BigDecimal.ZERO) < 0) {
                            throw new IllegalArgumentException("Issued quantity cannot be negative.");
                        }
                    } catch (NumberFormatException e) {
                        throw new ServletException("Invalid quantity format for issue ID: " + issueId, e);
                    }

                    // -------------------------------------------------------------
                    // Step 1: Fetch original record details
                    // -------------------------------------------------------------
                    int itemId = 0;
                    int poItemId = 0;
                    BigDecimal oldQty = BigDecimal.ZERO;
                    BigDecimal unitPrice = BigDecimal.ZERO;

                    psFetch.setInt(1, issueId);
                    try (ResultSet rs = psFetch.executeQuery()) {
                        if (rs.next()) {
                            itemId = rs.getInt("item_id");
                            poItemId = rs.getInt("po_item_id");
                            oldQty = rs.getBigDecimal("qty_issued");
                            unitPrice = rs.getBigDecimal("unit_price");
                        }
                    }

                    if (itemId == 0) {
                        throw new SQLException("Record with issue_id=" + issueId + " not found in dining_hall_consumption.");
                    }

                    if (oldQty == null) oldQty = BigDecimal.ZERO;
                    if (unitPrice == null) unitPrice = BigDecimal.ZERO;

                    affectedItemIds.add(itemId);
                    BigDecimal difference = newQty.subtract(oldQty);

                    // -------------------------------------------------------------
                    // Step 2: UPDATE Table 1 - dining_hall_consumption
                    // -------------------------------------------------------------
                    psCons.setString(1, department);
                    psCons.setString(2, issuedTo);
                    psCons.setBigDecimal(3, newQty);
                    psCons.setString(4, remark);
                    psCons.setBigDecimal(5, newQty.multiply(unitPrice));
                    psCons.setInt(6, issueId);
                    psCons.executeUpdate();

                    // -------------------------------------------------------------
                    // Step 3: UPDATE / INSERT Table 2 - stock_ledger
                    // -------------------------------------------------------------
                    psLedger.setBigDecimal(1, newQty);
                    psLedger.setString(2, remark);
                    psLedger.setInt(3, issueId);
                    psLedger.setInt(4, itemId);

                    int rowsLedger = psLedger.executeUpdate();

                    // Fallback: Insert if missing (includes running_balance default)
                    if (rowsLedger == 0) {
                        psInsertLedger.setInt(1, issueId);
                        psInsertLedger.setInt(2, itemId);
                        psInsertLedger.setBigDecimal(3, newQty);
                        psInsertLedger.setString(4, remark);
                        psInsertLedger.executeUpdate();
                    }

                    // -------------------------------------------------------------
                    // Step 4: UPDATE Table 3 - stock
                    // -------------------------------------------------------------
                    int rowsStock = 0;

                    if (poItemId > 0) {
                        psStockPo.setBigDecimal(1, difference);
                        psStockPo.setBigDecimal(2, difference);
                        psStockPo.setInt(3, itemId);
                        psStockPo.setInt(4, poItemId);
                        rowsStock = psStockPo.executeUpdate();
                    }

                    if (rowsStock == 0) {
                        psStockFallback.setBigDecimal(1, difference);
                        psStockFallback.setBigDecimal(2, difference);
                        psStockFallback.setInt(3, itemId);
                        rowsStock = psStockFallback.executeUpdate();
                    }

                    if (rowsStock == 0) {
                        throw new SQLException("Failed to update stock for item_id: " + itemId);
                    }
                }
            }

            // -------------------------------------------------------------
            // Step 5: Recalculate Ledger Running Balances (Batch Mode)
            // -------------------------------------------------------------
            for (Integer itemId : affectedItemIds) {
                recalculateLedger(con, itemId);
            }

            con.commit(); // Commit transaction

            response.sendRedirect("FetchConsumptionByDateServlet?selected_date=" 
                    + encodeParam(selectedDate) + "&msg=updated");

        } catch (Exception e) {
            if (con != null) {
                try {
                    con.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
            throw new ServletException("Database update failed. Transaction rolled back.", e);
        } finally {
            if (con != null) {
                try {
                    con.setAutoCommit(true);
                    con.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    private void recalculateLedger(Connection con, int itemId) throws SQLException {
        String selectSql = "SELECT ledger_id, trans_type, qty FROM stock_ledger "
                         + "WHERE item_id = ? ORDER BY trans_date ASC, ledger_id ASC";
        String updateSql = "UPDATE stock_ledger SET running_balance = ? WHERE ledger_id = ?";

        try (PreparedStatement psSelect = con.prepareStatement(selectSql);
             PreparedStatement psUpdate = con.prepareStatement(updateSql)) {

            psSelect.setInt(1, itemId);
            try (ResultSet rs = psSelect.executeQuery()) {
                BigDecimal balance = BigDecimal.ZERO;
                int batchCount = 0;

                while (rs.next()) {
                    int ledgerId = rs.getInt("ledger_id");
                    String type = rs.getString("trans_type");
                    BigDecimal qty = rs.getBigDecimal("qty");

                    if (qty == null) {
                        qty = BigDecimal.ZERO;
                    }

                    if ("RECEIPT".equalsIgnoreCase(type != null ? type.trim() : "")) {
                        balance = balance.add(qty);
                    } else {
                        balance = balance.subtract(qty);
                    }

                    psUpdate.setBigDecimal(1, balance);
                    psUpdate.setInt(2, ledgerId);
                    psUpdate.addBatch();
                    batchCount++;
                }

                if (batchCount > 0) {
                    psUpdate.executeBatch();
                }
            }
        }
    }

    private String encodeParam(String param) {
        if (param == null) return "";
        try {
            return URLEncoder.encode(param.trim(), StandardCharsets.UTF_8.name());
        } catch (Exception e) {
            return param.trim();
        }
    }
}