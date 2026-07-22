package com.controller;

import java.io.IOException;
import java.math.BigDecimal;
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

            for (String issueIdStr : selectedIssueIds) {
                if (issueIdStr == null || issueIdStr.trim().isEmpty()) {
                    continue;
                }

                int issueId;
                try {
                    issueId = Integer.parseInt(issueIdStr.trim());
                } catch (NumberFormatException e) {
                    continue; // Skip invalid issue IDs
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
                // Step 1: Fetch original record details & unit_price
                // -------------------------------------------------------------
                int itemId = 0;
                int poItemId = 0;
                BigDecimal oldQty = BigDecimal.ZERO;
                BigDecimal unitPrice = BigDecimal.ZERO;

                String fetchSql = "SELECT item_id, po_item_id, qty_issued, unit_price "
                                + "FROM dining_hall_consumption WHERE issue_id = ?";

                try (PreparedStatement psOld = con.prepareStatement(fetchSql)) {
                    psOld.setInt(1, issueId);
                    try (ResultSet rs = psOld.executeQuery()) {
                        if (rs.next()) {
                            itemId = rs.getInt("item_id");
                            poItemId = rs.getInt("po_item_id");
                            oldQty = rs.getBigDecimal("qty_issued");
                            unitPrice = rs.getBigDecimal("unit_price");
                        }
                    }
                }

                if (itemId == 0) {
                    throw new SQLException("Record with issue_id=" + issueId + " not found in dining_hall_consumption.");
                }

                if (unitPrice == null) {
                    unitPrice = BigDecimal.ZERO;
                }

                affectedItemIds.add(itemId);
                BigDecimal difference = newQty.subtract(oldQty);

                // -------------------------------------------------------------
                // Step 2: UPDATE Table 1 - dining_hall_consumption
                // -------------------------------------------------------------
                String updateConsSql = "UPDATE dining_hall_consumption "
                                     + "SET department = ?, "
                                     + "    issued_to = ?, "
                                     + "    qty_issued = ?, "
                                     + "    remarks = ?, "
                                     + "    total_value = ? "
                                     + "WHERE issue_id = ?";

                try (PreparedStatement psCons = con.prepareStatement(updateConsSql)) {
                    psCons.setString(1, department);
                    psCons.setString(2, issuedTo);
                    psCons.setBigDecimal(3, newQty);
                    psCons.setString(4, remark);

                    BigDecimal total = newQty.multiply(unitPrice);
                    psCons.setBigDecimal(5, total);
                    psCons.setInt(6, issueId);

                    psCons.executeUpdate();
                }

                // -------------------------------------------------------------
                // Step 3: UPDATE Table 2 - stock_ledger
                // -------------------------------------------------------------
                String updateLedgerSql = "UPDATE stock_ledger "
                                       + "SET qty = ?, remarks = ? "
                                       + "WHERE consumption_id = ? "
                                       + "  AND item_id = ? "
                                       + "  AND trans_type = 'ISSUE'";

                try (PreparedStatement psLedger = con.prepareStatement(updateLedgerSql)) {
                    psLedger.setBigDecimal(1, newQty);
                    psLedger.setString(2, remark);
                    psLedger.setInt(3, issueId);
                    psLedger.setInt(4, itemId);

                    int rowsLedger = psLedger.executeUpdate();
                    System.out.println("[DEBUG] stock_ledger updated rows: " + rowsLedger);

                    if (rowsLedger == 0) {
                        throw new SQLException("Failed to update stock_ledger for consumption_id=" 
                                + issueId + ", item_id=" + itemId);
                    }
                }

                // -------------------------------------------------------------
                // Step 4: UPDATE Table 3 - stock
                // -------------------------------------------------------------
                int rowsStock = 0;

                // Primary Attempt: Try updating with both item_id and po_item_id
                if (poItemId > 0) {
                    String updateStockPoSql = "UPDATE stock "
                                            + "SET total_issued = COALESCE(total_issued, 0) + ?, "
                                            + "    balance_qty = COALESCE(balance_qty, 0) - ? "
                                            + "WHERE item_id = ? AND po_item_id = ?";

                    try (PreparedStatement psStock = con.prepareStatement(updateStockPoSql)) {
                        psStock.setBigDecimal(1, difference);
                        psStock.setBigDecimal(2, difference);
                        psStock.setInt(3, itemId);
                        psStock.setInt(4, poItemId);
                        rowsStock = psStock.executeUpdate();
                    }
                }

                // Fallback Attempt: Update using item_id only if po_item_id was 0 or row not matched
                if (rowsStock == 0) {
                    String updateStockFallbackSql = "UPDATE stock "
                                                  + "SET total_issued = COALESCE(total_issued, 0) + ?, "
                                                  + "    balance_qty = COALESCE(balance_qty, 0) - ? "
                                                  + "WHERE item_id = ?";

                    try (PreparedStatement psStockFallback = con.prepareStatement(updateStockFallbackSql)) {
                        psStockFallback.setBigDecimal(1, difference);
                        psStockFallback.setBigDecimal(2, difference);
                        psStockFallback.setInt(3, itemId);
                        rowsStock = psStockFallback.executeUpdate();
                    }
                }

                System.out.println("[DEBUG] stock updated rows: " + rowsStock);

                if (rowsStock == 0) {
                    throw new SQLException("Failed to update stock for item_id: " + itemId);
                }
            }

            // -------------------------------------------------------------
            // Step 5: Recalculate Ledger Running Balances (Batch Mode)
            // -------------------------------------------------------------
            for (Integer itemId : affectedItemIds) {
                recalculateLedger(con, itemId);
            }

            // Commit transaction if all steps succeeded
            con.commit();

            response.sendRedirect("FetchConsumptionByDateServlet?selected_date=" 
                    + encodeParam(selectedDate) + "&msg=updated");

        } catch (Exception e) {
            // Roll back the entire transaction if any update fails
            if (con != null) {
                try {
                    con.rollback();
                    System.err.println("[TRANSACTION ROLLED BACK] Reason: " + e.getMessage());
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

    /**
     * Recalculates running balances chronologically for a specific item_id.
     * Uses JDBC Batch Execution for optimized performance.
     */
    private void recalculateLedger(Connection con, int itemId) throws SQLException {
        String selectSql = "SELECT ledger_id, trans_type, qty FROM stock_ledger "
                         + "WHERE item_id = ? ORDER BY trans_date ASC, ledger_id ASC";
        String updateSql = "UPDATE stock_ledger SET running_balance = ? WHERE ledger_id = ?";

        try (PreparedStatement psSelect = con.prepareStatement(selectSql);
             PreparedStatement psUpdate = con.prepareStatement(updateSql)) {

            psSelect.setInt(1, itemId);
            try (ResultSet rs = psSelect.executeQuery()) {
                BigDecimal balance = BigDecimal.ZERO;

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
                    psUpdate.addBatch(); // Batch execution to prevent N+1 DB trips
                }
                psUpdate.executeBatch();
            }
        }
    }

    /**
     * Utility method to prevent NullPointerException during parameter encoding in redirects.
     */
    private String encodeParam(String param) {
        return (param != null) ? param.trim() : "";
    }
}