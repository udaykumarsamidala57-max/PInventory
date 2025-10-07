package com.controller.PO;

import java.io.IOException;
import java.sql.*;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;
import com.bean.GRNItem;

@WebServlet("/GRNServlet")
public class GRNServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String poNumber = request.getParameter("po_number");
        if (poNumber == null || poNumber.isEmpty()) {
            request.getRequestDispatcher("PO/GRNForm.jsp").forward(request, response);
            return;
        }

        try (Connection con = DBUtil.getConnection()) {
            int poId;
            String vendorName;

            // --- Fetch PO Master ---
            try (PreparedStatement psPO = con.prepareStatement(
                    "SELECT po_id, vendor_name FROM po_master WHERE po_number=?")) {
                psPO.setString(1, poNumber);
                try (ResultSet rsPO = psPO.executeQuery()) {
                    if (!rsPO.next()) {
                        request.setAttribute("error", "PO not found!");
                        request.getRequestDispatcher("GRNForm.jsp").forward(request, response);
                        return;
                    }
                    poId = rsPO.getInt("po_id");
                    vendorName = rsPO.getString("vendor_name");
                }
            }

            // --- Already accepted qty per item ---
            Map<Integer, Integer> receivedMap = new HashMap<>();
            try (PreparedStatement psRec = con.prepareStatement(
                "SELECT gi.po_item_id, SUM(gi.qty_accepted) AS rec " +
                "FROM grn_items gi JOIN grn_master gm ON gi.grn_id=gm.grn_id " +
                "WHERE gm.po_id=? GROUP BY gi.po_item_id")) {
                psRec.setInt(1, poId);
                try (ResultSet rsRec = psRec.executeQuery()) {
                    while (rsRec.next()) {
                        receivedMap.put(rsRec.getInt("po_item_id"), rsRec.getInt("rec"));
                    }
                }
            }

            // --- Fetch PO items ---
            List<GRNItem> itemList = new ArrayList<>();
            try (PreparedStatement psItems = con.prepareStatement(
                "SELECT pi.po_item_id, pi.item_id, im.item_name, pi.qty " +
                "FROM po_items pi " +
                "JOIN item_master im ON pi.item_id = im.item_id " +
                "WHERE pi.po_id=?")) {
                psItems.setInt(1, poId);
                try (ResultSet rsItems = psItems.executeQuery()) {
                    while (rsItems.next()) {
                        GRNItem item = new GRNItem();
                        int poItemId = rsItems.getInt("po_item_id");
                        item.setPoItemId(poItemId);
                        item.setItemId(rsItems.getInt("item_id"));
                        item.setDescription(rsItems.getString("item_name"));
                        item.setOrderedQty(rsItems.getDouble("qty"));
                        item.setAlreadyReceived(receivedMap.getOrDefault(poItemId, 0));
                        itemList.add(item);
                    }
                }
            }

            request.setAttribute("poNumber", poNumber);
            request.setAttribute("vendorName", vendorName);
            request.setAttribute("items", itemList);

            request.getRequestDispatcher("PO/GRNForm.jsp").forward(request, response);

        } catch(Exception e) {
            throw new ServletException("DB Error: " + e.getMessage(), e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String poNumber  = request.getParameter("po_number");
        String invoiceNo = request.getParameter("invoice_no");
        String invoiceDate = request.getParameter("invoice_date");
        String receivedBy  = request.getParameter("received_by");

        int totalItems = 0;
        try {
            totalItems = Integer.parseInt(request.getParameter("totalItems"));
        } catch(NumberFormatException nfe) {
            request.setAttribute("error", "Invalid totalItems");
            request.getRequestDispatcher("GRNForm.jsp").forward(request, response);
            return;
        }

        try (Connection con = DBUtil.getConnection()) {
            con.setAutoCommit(false);

            // --- Get PO ID ---
            int poId = 0;
            String vendorName = "";
            try (PreparedStatement psPO = con.prepareStatement(
                "SELECT po_id, vendor_name FROM po_master WHERE po_number=?")) {
                psPO.setString(1, poNumber);
                try (ResultSet rsPO = psPO.executeQuery()) {
                    if (rsPO.next()) {
                        poId = rsPO.getInt("po_id");
                        vendorName = rsPO.getString("vendor_name");
                    } else {
                        throw new SQLException("PO not found for number: " + poNumber);
                    }
                }
            }

            // --- Fetch ordered qty + already accepted for validation ---
            Map<Integer, Double> orderedMap = new HashMap<>();
            Map<Integer, Double> alreadyReceivedMap = new HashMap<>();
            try (PreparedStatement psItems = con.prepareStatement(
                "SELECT pi.po_item_id, pi.qty, IFNULL(SUM(gi.qty_accepted),0) as rec " +
                "FROM po_items pi " +
                "LEFT JOIN grn_items gi ON pi.po_item_id=gi.po_item_id " +
                "LEFT JOIN grn_master gm ON gi.grn_id=gm.grn_id " +
                "WHERE pi.po_id=? GROUP BY pi.po_item_id, pi.qty")) {
                psItems.setInt(1, poId);
                try (ResultSet rs = psItems.executeQuery()) {
                    while (rs.next()) {
                        orderedMap.put(rs.getInt("po_item_id"), rs.getDouble("qty"));
                        alreadyReceivedMap.put(rs.getInt("po_item_id"), rs.getDouble("rec"));
                    }
                }
            }

            // --- Validation: ensure accepted qty not more than remaining ---
            for (int i = 0; i < totalItems; i++) {
                int poItemId   = Integer.parseInt(request.getParameter("po_item_id" + i));
                int qtyAccepted = Integer.parseInt(request.getParameter("qty_accepted_" + i));

                double orderedQty = orderedMap.getOrDefault(poItemId, 0.0);
                double alreadyRec = alreadyReceivedMap.getOrDefault(poItemId, 0.0);
                double remaining  = orderedQty - alreadyRec;

                if (qtyAccepted > remaining) {
                    con.rollback();
                    request.setAttribute("error",
                        "❌ Error: Accepted qty for PO Item " + poItemId +
                        " exceeds remaining balance. Ordered=" + orderedQty +
                        ", Already Accepted=" + alreadyRec +
                        ", Remaining=" + remaining);
                    request.getRequestDispatcher("PO/GRNForm.jsp").forward(request, response);
                    return;
                }
            }

            // --- Insert GRN Master ---
            String grnNo = "GRN" + System.currentTimeMillis();
            int grnId;
            try (PreparedStatement psMaster = con.prepareStatement(
                "INSERT INTO grn_master(grn_no,grn_date,po_id,vendor_name," +
                "invoice_no,invoice_date,received_by,created_at) VALUES(?,CURDATE(),?,?,?,?,?,NOW())",
                Statement.RETURN_GENERATED_KEYS)) {

                psMaster.setString(1, grnNo);
                psMaster.setInt(2, poId);
                psMaster.setString(3, vendorName);
                psMaster.setString(4, invoiceNo);
                psMaster.setString(5, invoiceDate);
                psMaster.setString(6, receivedBy);
                psMaster.executeUpdate();

                try (ResultSet rsKeys = psMaster.getGeneratedKeys()) {
                    if (rsKeys.next()) {
                        grnId = rsKeys.getInt(1);
                    } else {
                        throw new SQLException("Failed to obtain generated GRN id.");
                    }
                }
            }

            // --- Insert GRN Items + Update Stock & Ledger ---
            try (PreparedStatement psItems = con.prepareStatement(
            	    "INSERT INTO grn_items(grn_id,po_item_id,item_id,item_description,qty_received,qty_accepted,qty_rejected,remarks) " +
            	    "VALUES (?,?,?,?,?,?,?,?)");
                 PreparedStatement psStockSel = con.prepareStatement(
                    "SELECT stock_id, total_received, balance_qty FROM stock WHERE item_id=?");
                 PreparedStatement psStockIns = con.prepareStatement(
                    "INSERT INTO stock(item_id, po_item_id, total_received, total_issued, balance_qty, last_updated) " +
                    "VALUES (?, ?, ?, 0, ?, NOW())");
                 PreparedStatement psStockUpd = con.prepareStatement(
                    "UPDATE stock SET total_received=?, balance_qty=?, last_updated=NOW() WHERE stock_id=?");
                 PreparedStatement psLedger = con.prepareStatement(
                    "INSERT INTO stock_ledger(item_id, po_item_id, trans_type, trans_id, trans_date, qty, running_balance, remarks) " +
                    "VALUES (?, ?, 'RECEIPT', ?, CURDATE(), ?, ?, ?)")) {

                for (int i = 0; i < totalItems; i++) {
                    int poItemId   = Integer.parseInt(request.getParameter("po_item_id" + i));
                    int itemId     = Integer.parseInt(request.getParameter("item_id" + i));
                    String description = request.getParameter("description_" + i);
                    int qtyReceived = Integer.parseInt(request.getParameter("qty_received_" + i));
                    int qtyAccepted = Integer.parseInt(request.getParameter("qty_accepted_" + i));
                    int qtyRejected = Integer.parseInt(request.getParameter("qty_rejected_" + i));
                    String remarks  = request.getParameter("remarks_" + i);

                    // --- Insert GRN Item ---
                    psItems.setInt(1, grnId);
                    psItems.setInt(2, poItemId);
                    psItems.setInt(3, itemId);
                    psItems.setString(4, description);
                    psItems.setInt(5, qtyReceived);
                    psItems.setInt(6, qtyAccepted);
                    psItems.setInt(7, qtyRejected);
                    psItems.setString(8, remarks);
                    psItems.executeUpdate();

                    // --- STOCK update ---
                    int stockId = 0;
                    double totalReceivedVal = 0, balanceQty = 0;

                    psStockSel.setInt(1, itemId);
                    try (ResultSet rsStock = psStockSel.executeQuery()) {
                        if (rsStock.next()) {
                            stockId = rsStock.getInt("stock_id");
                            totalReceivedVal = rsStock.getDouble("total_received") + qtyAccepted;
                            balanceQty = rsStock.getDouble("balance_qty") + qtyAccepted;

                            psStockUpd.setDouble(1, totalReceivedVal);
                            psStockUpd.setDouble(2, balanceQty);
                            psStockUpd.setInt(3, stockId);
                            psStockUpd.executeUpdate();
                        } else {
                            totalReceivedVal = qtyAccepted;
                            balanceQty = qtyAccepted;

                            psStockIns.setInt(1, itemId);
                            psStockIns.setInt(2, poItemId);
                            psStockIns.setDouble(3, totalReceivedVal);
                            psStockIns.setDouble(4, balanceQty);
                            psStockIns.executeUpdate();
                        }
                    }

                    // --- LEDGER insert ---
                    psLedger.setInt(1, itemId);
                    psLedger.setInt(2, poItemId);
                    psLedger.setInt(3, grnId);
                    psLedger.setDouble(4, qtyAccepted);
                    psLedger.setDouble(5, balanceQty);
                    psLedger.setString(6, "GRN " + grnNo);
                    psLedger.executeUpdate();
                }
            }

            // --- Check if PO should be Closed or Partially Received ---
            boolean allReceived = true;
            boolean anyReceived = false;

            try (PreparedStatement psCheck = con.prepareStatement(
                "SELECT pi.qty AS ordered, IFNULL(SUM(gi.qty_accepted),0) AS received " +
                "FROM po_items pi " +
                "LEFT JOIN grn_items gi ON pi.po_item_id = gi.po_item_id " +
                "LEFT JOIN grn_master gm ON gi.grn_id = gm.grn_id " +
                "WHERE pi.po_id = ? " +
                "GROUP BY pi.po_item_id, pi.qty")) {

                psCheck.setInt(1, poId);
                try (ResultSet rs = psCheck.executeQuery()) {
                    while (rs.next()) {
                        double ordered = rs.getDouble("ordered");
                        double received = rs.getDouble("received");
                        if (received > 0) anyReceived = true;
                        if (received < ordered) {
                            allReceived = false;
                        }
                    }
                }
            }

            if (allReceived) {
                try (PreparedStatement psClose = con.prepareStatement(
                        "UPDATE po_master SET po_status='Closed' WHERE po_id=?")) {
                    psClose.setInt(1, poId);
                    psClose.executeUpdate();
                }
            } else if (anyReceived) {
                try (PreparedStatement psPartial = con.prepareStatement(
                        "UPDATE po_master SET po_status='Partially Received' WHERE po_id=?")) {
                    psPartial.setInt(1, poId);
                    psPartial.executeUpdate();
                }
            }

            con.commit();
            request.setAttribute("message", "✅ GRN Created Successfully. GRN No: " + grnNo);

        } catch(Exception e){
            e.printStackTrace();
            request.setAttribute("error", "❌ Error: " + e.getMessage());
        }

        request.getRequestDispatcher("PO/GRNForm.jsp").forward(request, response);
    }
}
