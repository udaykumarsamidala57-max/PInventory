package com.controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;
import com.bean.POItems;

@WebServlet("/PurchaseOrderServlet")
public class PurchaseOrderServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        List<POItems> indentList = new ArrayList<>();
        Map<String, String[]> vendorMap = new LinkedHashMap<>();
        String nextPONumber = "PO0001";
        String[] selectedIds = request.getParameterValues("selectedIds");

        try (Connection con = DBUtil.getConnection()) {

            // --- 1. Generate next PO number ---
            try (Statement stNext = con.createStatement();
                 ResultSet rsNext = stNext.executeQuery("SELECT po_number FROM po_master ORDER BY po_id DESC LIMIT 1")) {
                if (rsNext.next()) {
                    String lastPo = rsNext.getString("po_number");
                    String numPart = lastPo.replaceAll("\\D+", "");
                    int nextNum = numPart.isEmpty() ? 1 : Integer.parseInt(numPart) + 1;
                    nextPONumber = String.format("PO%04d", nextNum);
                }
            }

            // --- 2. Load selected indents ---
            if (selectedIds != null && selectedIds.length > 0) {
                String placeholders = String.join(",", Collections.nCopies(selectedIds.length, "?"));
                String sql = "SELECT indent_id, indent_no, item_id, item_name, UOM, qty FROM indent "
                        + "WHERE indent_id IN (" + placeholders + ") ORDER BY indent_id DESC";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    for (int i = 0; i < selectedIds.length; i++) {
                        ps.setString(i + 1, selectedIds[i]);
                    }
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            POItems item = new POItems();
                            item.setId(rs.getInt("indent_id"));
                            item.setIndentNo(rs.getString("indent_no"));
                            item.setItemId(rs.getInt("item_id"));
                            item.setItemName(rs.getString("item_name"));
                            item.setUOM(rs.getString("UOM"));
                            item.setQty(rs.getDouble("qty"));
                            indentList.add(item);
                        }
                    }
                }
            }

            // --- 3. Load vendor list (Fixed Column Names) ---
            try (Statement st2 = con.createStatement();
                 ResultSet rs2 = st2.executeQuery("SELECT name, GSTIN, address FROM vendors ORDER BY name")) {
                while (rs2.next()) {
                    // Using Column Names exactly as per your DB schema
                    String name = rs2.getString("name");
                    String gstin = (rs2.getString("GSTIN") != null) ? rs2.getString("GSTIN") : "";
                    String addr = (rs2.getString("address") != null) ? rs2.getString("address") : "";
                    vendorMap.put(name, new String[]{gstin, addr});
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException("DB Error: " + e.getMessage(), e);
        }

        request.setAttribute("indentList", indentList);
        request.setAttribute("vendorMap", vendorMap);
        request.setAttribute("nextPONumber", nextPONumber);

        RequestDispatcher rd = request.getRequestDispatcher("PurchaseOrder.jsp");
        rd.forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String[] itemNames = request.getParameterValues("itemName");
        String[] itemIds = request.getParameterValues("itemId");
        String[] qtys = request.getParameterValues("qty");
        String[] rates = request.getParameterValues("rate");
        String[] discPercents = request.getParameterValues("discPercent");
        String[] gstPercents = request.getParameterValues("gstPercent");
        String[] selectedIds = request.getParameterValues("indentId");

        String vname = request.getParameter("vendorName");
        String vgstin = request.getParameter("vendorGSTIN");
        String vaddress = request.getParameter("vendorAddress");
        String quotationNo = request.getParameter("quotationNo");
        String poNo = request.getParameter("poNumber");
        String poDate = request.getParameter("poDate");
        String billingAddress = request.getParameter("billingAddress");
        String terms = request.getParameter("termsConditions");
        String general = request.getParameter("generalConditions");

        // ✅ new fields for service charge
        double serviceCharge = 0.0;
        double serviceGstPercent = 0.0;

        try {
            String s1 = request.getParameter("serviceCharge");
            String s2 = request.getParameter("serviceGst");
            if (s1 != null && !s1.trim().isEmpty()) serviceCharge = Double.parseDouble(s1);
            if (s2 != null && !s2.trim().isEmpty()) serviceGstPercent = Double.parseDouble(s2);
        } catch (Exception ignored) {}

        if (qtys == null || qtys.length == 0) {
            throw new ServletException("PO Creation Error: No items found to process.");
        }

        Connection con = null;
        try {
            con = DBUtil.getConnection();
            con.setAutoCommit(false); // ✅ Transaction start

            // STEP 1: Club same items
            class MergedItem {
                int itemId;
                String description;
                double qty, rate, discPercent, gstPercent;
            }

            Map<Integer, MergedItem> merged = new LinkedHashMap<>();
            for (int i = 0; i < itemIds.length; i++) {
                int id = Integer.parseInt(itemIds[i]);
                double qty = Double.parseDouble(qtys[i]);
                double rate = Double.parseDouble(rates[i]);
                double discP = Double.parseDouble(discPercents[i]);
                double gstP = Double.parseDouble(gstPercents[i]);

                if (merged.containsKey(id)) {
                    merged.get(id).qty += qty;
                } else {
                    MergedItem m = new MergedItem();
                    m.itemId = id;
                    m.description = itemNames[i];
                    m.qty = qty;
                    m.rate = rate;
                    m.discPercent = discP;
                    m.gstPercent = gstP;
                    merged.put(id, m);
                }
            }

            // STEP 2: Calculate totals (2-decimal precision)
            double totalGst = 0, totalDis = 0, totalAmount = 0;
            for (MergedItem m : merged.values()) {
                double amount = m.qty * m.rate;
                double discVal = (m.discPercent / 100.0) * amount;
                double net = amount - discVal;
                double gstVal = (m.gstPercent / 100.0) * net;

                amount = roundToTwo(amount);
                discVal = roundToTwo(discVal);
                gstVal = roundToTwo(gstVal);
                net = roundToTwo(net);

                totalGst += gstVal;
                totalDis += discVal;
                totalAmount += (net + gstVal);
            }

            // ✅ STEP 2A: Add Service charge and GST (2-decimal)
            double serviceGstVal = (serviceGstPercent / 100.0) * serviceCharge;
            serviceGstVal = roundToTwo(serviceGstVal);
            double serviceTotal = roundToTwo(serviceCharge + serviceGstVal);

            totalGst += serviceGstVal;
            totalAmount += serviceTotal;

            // ✅ STEP 2B: Round only totalAmount to nearest rupee
            totalAmount = Math.round(totalAmount);

            // STEP 3: Insert into po_master
            String insertMaster = "INSERT INTO po_master(vendor_name,vendor_gstin,vendor_address,po_number,"
                    + "quotation_number,po_date,billing_address,total_gst,total_dis,total_amount,"
                    + "amount_in_words,terms_conditions,general_conditions,po_status,Approval,Servicecharge) "
                    + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,'Open','Pending',?)";

            int poId = 0;
            try (PreparedStatement psPO = con.prepareStatement(insertMaster, Statement.RETURN_GENERATED_KEYS)) {
                psPO.setString(1, vname);
                psPO.setString(2, vgstin);
                psPO.setString(3, vaddress);
                psPO.setString(4, poNo);
                psPO.setString(5, quotationNo);
                psPO.setString(6, poDate);
                psPO.setString(7, billingAddress);
                psPO.setDouble(8, roundToTwo(totalGst));
                psPO.setDouble(9, roundToTwo(totalDis));
                psPO.setDouble(10, totalAmount); // ✅ Rounded to rupee
                psPO.setString(11, "");
                psPO.setString(12, terms);
                psPO.setString(13, general);
                psPO.setDouble(14, serviceTotal); // ✅ total service charge incl GST
                psPO.executeUpdate();
                try (ResultSet rsKey = psPO.getGeneratedKeys()) {
                    if (rsKey.next()) {
                        poId = rsKey.getInt(1);
                    }
                }
            }

            // STEP 4: Insert into po_items
            String insertItems = "INSERT INTO po_items(po_id,po_no,sl_no,item_id,description,qty,rate,amount,"
                    + "discount_percent,discount_value,gst_percent,gst_value,net_amount) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)";

            try (PreparedStatement psItems = con.prepareStatement(insertItems)) {
                int slno = 1;
                for (MergedItem m : merged.values()) {
                    double amount = roundToTwo(m.qty * m.rate);
                    double discVal = roundToTwo((m.discPercent / 100.0) * amount);
                    double net = roundToTwo(amount - discVal);
                    double gstVal = roundToTwo((m.gstPercent / 100.0) * net);
                    double netAmt = roundToTwo(net + gstVal);

                    psItems.setInt(1, poId);
                    psItems.setString(2, poNo);
                    psItems.setInt(3, slno++);
                    psItems.setInt(4, m.itemId);
                    psItems.setString(5, m.description);
                    psItems.setBigDecimal(6, BigDecimal.valueOf(m.qty));
                    psItems.setBigDecimal(7, BigDecimal.valueOf(m.rate));
                    psItems.setBigDecimal(8, BigDecimal.valueOf(amount));
                    psItems.setBigDecimal(9, BigDecimal.valueOf(m.discPercent));
                    psItems.setBigDecimal(10, BigDecimal.valueOf(discVal));
                    psItems.setBigDecimal(11, BigDecimal.valueOf(m.gstPercent));
                    psItems.setBigDecimal(12, BigDecimal.valueOf(gstVal));
                    psItems.setBigDecimal(13, BigDecimal.valueOf(netAmt));
                    psItems.addBatch();
                }
                psItems.executeBatch();
            }

            // STEP 5: Update indent table
            if (selectedIds != null && selectedIds.length > 0) {
                String placeholders = String.join(",", Collections.nCopies(selectedIds.length, "?"));
                String sql = "UPDATE indent SET POStatus='Raised' WHERE indent_id IN (" + placeholders + ")";
                try (PreparedStatement psUpdate = con.prepareStatement(sql)) {
                    for (int i = 0; i < selectedIds.length; i++) {
                        psUpdate.setString(i + 1, selectedIds[i]);
                    }
                    psUpdate.executeUpdate();
                }
            }

            con.commit(); // ✅ Transaction success
            response.sendRedirect("POListServlet");

        } catch (Exception e) {
            try {
                if (con != null) con.rollback();
            } catch (SQLException ignored) {}
            throw new ServletException("PO Creation Error: " + e.getMessage(), e);
        } finally {
            try {
                if (con != null) con.setAutoCommit(true);
            } catch (SQLException ignored) {}
        }
    }

    // ✅ Helper for rounding to 2 decimals
    private double roundToTwo(double val) {
        return Math.round(val * 100.0) / 100.0;
    }
}
