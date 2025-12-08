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

        Connection con = null;

        try {
            con = DBUtil.getConnection();

            String queryGRN = "SELECT * FROM grn_master ORDER BY grn_id DESC";
            PreparedStatement pstGRN = con.prepareStatement(queryGRN);
            ResultSet rsGRN = pstGRN.executeQuery();

            List<Map<String, Object>> grnList = new ArrayList<>();

            while (rsGRN.next()) {

                Map<String, Object> master = new HashMap<>();
                master.put("grn_id", rsGRN.getInt("grn_id"));
                master.put("grn_no", rsGRN.getString("grn_no"));
                master.put("grn_date", rsGRN.getDate("grn_date"));
                master.put("vendor_name", rsGRN.getString("vendor_name"));
                master.put("vendor_gstin", rsGRN.getString("vendor_gstin"));
                master.put("vendor_address", rsGRN.getString("vendor_address"));
                master.put("po_id", rsGRN.getInt("po_id"));
                master.put("invoice_no", rsGRN.getString("invoice_no"));
                master.put("invoice_date", rsGRN.getDate("invoice_date"));
                master.put("received_by", rsGRN.getString("received_by"));
                master.put("remarks", rsGRN.getString("remarks"));

                PreparedStatement pstItems = con.prepareStatement(
                        "SELECT * FROM grn_items WHERE grn_id = ?");
                pstItems.setInt(1, rsGRN.getInt("grn_id"));
                ResultSet rsItems = pstItems.executeQuery();

                List<Map<String, Object>> items = new ArrayList<>();

                while (rsItems.next()) {

                    Map<String, Object> item = new HashMap<>();
                    int po_item_id = rsItems.getInt("po_item_id");

                    item.put("item_description", rsItems.getString("item_description"));
                    item.put("qty_received", rsItems.getBigDecimal("qty_received"));
                    item.put("qty_accepted", rsItems.getBigDecimal("qty_accepted"));
                    item.put("qty_rejected", rsItems.getBigDecimal("qty_rejected"));
                    item.put("grn_remarks", rsItems.getString("remarks"));

                    // ⏬ NEW: Fetch ordered quantity from po_items
                    PreparedStatement pstPOItem = con.prepareStatement(
                            "SELECT qty FROM po_items WHERE po_item_id = ?");
                    pstPOItem.setInt(1, po_item_id);
                    ResultSet rsPO = pstPOItem.executeQuery();

                    if (rsPO.next()) {
                        item.put("qty_ordered", rsPO.getBigDecimal("qty"));
                    } else {
                        item.put("qty_ordered", "N/A");
                    }

                    items.add(item);
                }

                master.put("items", items);
                grnList.add(master);
            }

            request.setAttribute("all_grns", grnList);
            request.getRequestDispatcher("view_grn.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error while loading GRN data");
            request.getRequestDispatcher("view_grn.jsp").forward(request, response);
        }
    }
}
