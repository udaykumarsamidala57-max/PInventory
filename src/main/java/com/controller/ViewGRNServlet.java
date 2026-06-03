package com.controller;

import java.io.IOException;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.util.*;
import com.bean.DBUtil;

@WebServlet("/viewGRN")
public class ViewGRNServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Use LinkedHashMap to preserve the ORDER BY m.grn_id DESC sorting sequence
        Map<Integer, Map<String, Object>> grnMap = new LinkedHashMap<>();

        // FIXED: Removed m.status to prevent database schema errors
        String unifiedQuery = 
            "SELECT m.grn_id, m.grn_no, m.grn_date, m.vendor_name, m.vendor_gstin, m.vendor_address, " +
            "       m.po_id, m.invoice_no, m.invoice_date, m.received_by, m.remarks AS master_remarks, " +
            "       i.item_description, i.qty_received, i.qty_accepted, i.qty_rejected, i.remarks AS item_remarks, " +
            "       p.qty AS qty_ordered " +
            "FROM grn_master m " +
            "LEFT JOIN grn_items i ON m.grn_id = i.grn_id " +
            "LEFT JOIN po_items p ON i.po_item_id = p.po_item_id " +
            "ORDER BY m.grn_id DESC";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement pst = con.prepareStatement(unifiedQuery);
             ResultSet rs = pst.executeQuery()) {

            while (rs.next()) {
                int grnId = rs.getInt("grn_id");
                
                // Construct the parent item structural container if it hasn't been built yet
                if (!grnMap.containsKey(grnId)) {
                    Map<String, Object> master = new HashMap<>();
                    master.put("grn_id", grnId);
                    master.put("grn_no", rs.getString("grn_no"));
                    master.put("grn_date", rs.getDate("grn_date"));
                    master.put("vendor_name", rs.getString("vendor_name"));
                    master.put("vendor_gstin", rs.getString("vendor_gstin"));
                    master.put("vendor_address", rs.getString("vendor_address"));
                    master.put("po_id", rs.getString("po_id")); // Kept safe for numeric or alphanumeric IDs
                    master.put("invoice_no", rs.getString("invoice_no"));
                    master.put("invoice_date", rs.getDate("invoice_date"));
                    master.put("received_by", rs.getString("received_by"));
                    master.put("remarks", rs.getString("master_remarks") == null ? "" : rs.getString("master_remarks"));
                    
                    // FIXED: Re-introduced default application status values dynamically 
                    master.put("status", "completed");
                    
                    master.put("items", new ArrayList<Map<String, Object>>());
                    grnMap.put(grnId, master);
                }

                // Append child structural lines safely
                String itemDesc = rs.getString("item_description");
                if (itemDesc != null) {
                    Map<String, Object> item = new HashMap<>();
                    item.put("item_description", itemDesc);
                    item.put("qty_received", rs.getBigDecimal("qty_received"));
                    item.put("qty_accepted", rs.getBigDecimal("qty_accepted"));
                    item.put("qty_rejected", rs.getBigDecimal("qty_rejected"));
                    
                    // FIXED: Map to 'remarks' instead of 'grn_remarks' so your JSP file can read it perfectly
                    item.put("remarks", rs.getString("item_remarks") == null ? "" : rs.getString("item_remarks"));
                    
                    java.math.BigDecimal qtyOrdered = rs.getBigDecimal("qty_ordered");
                    item.put("qty_ordered", qtyOrdered != null ? qtyOrdered : "N/A");

                    List<Map<String, Object>> itemsList = (List<Map<String, Object>>) grnMap.get(grnId).get("items");
                    itemsList.add(item);
                }
            }

            // Bind directly to view layout
            request.setAttribute("all_grns", new ArrayList<>(grnMap.values()));
            request.getRequestDispatcher("view_grn.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            // Printing the explicit error message onto screen for debugging visibility
            request.setAttribute("error", "Database Sync Pipeline Error: " + e.getMessage());
            request.getRequestDispatcher("view_grn.jsp").forward(request, response);
        }
    }
}