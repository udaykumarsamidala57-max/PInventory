package com.controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.*;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;
import com.bean.POItems;

@WebServlet("/PO")
public class PO extends HttpServlet {

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

            // --- Generate next PO number ---
            Statement stNext = con.createStatement();
            ResultSet rsNext = stNext.executeQuery("SELECT po_number FROM po_master ORDER BY po_id DESC LIMIT 1");
            if (rsNext.next()) {
                String lastPo = rsNext.getString("po_number");
                String numPart = lastPo.replaceAll("\\D+", "");
                int nextNum = numPart.isEmpty() ? 1 : Integer.parseInt(numPart) + 1;
                nextPONumber = String.format("PO%04d", nextNum);
            }
            rsNext.close();
            stNext.close();

            // --- Load selected indents (include item_id also) ---
            if (selectedIds != null && selectedIds.length > 0) {
                String placeholders = String.join(",", Collections.nCopies(selectedIds.length, "?"));
                String sql = "SELECT indent_id, indent_no, item_id, item_name, qty FROM indent "
                        + "WHERE status='Approved' AND indent_id IN (" + placeholders + ") ORDER BY indent_id DESC";
                PreparedStatement ps = con.prepareStatement(sql);
                for (int i = 0; i < selectedIds.length; i++) {
                    ps.setString(i + 1, selectedIds[i]);
                }
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    POItems item = new POItems();
                    item.setId(rs.getInt("indent_id"));
                    item.setIndentNo(rs.getString("indent_no"));
                    item.setItemId(rs.getInt("item_id"));
                    item.setItemName(rs.getString("item_name"));
                    item.setQty(rs.getDouble("qty"));
                    indentList.add(item);
                }
                rs.close();
                ps.close();
            }

            // --- Load vendors ---
            Statement st2 = con.createStatement();
            ResultSet rs2 = st2.executeQuery("SELECT name,gstin,address FROM vendors ORDER BY name");
            while (rs2.next()) {
                vendorMap.put(rs2.getString("name"),
                        new String[] { rs2.getString("gstin"), rs2.getString("address") });
            }
            rs2.close();
            st2.close();

        } catch (Exception e) {
            throw new ServletException("DB Error: " + e.getMessage(), e);
        }

        request.setAttribute("indentList", indentList);
        request.setAttribute("vendorMap", vendorMap);
        request.setAttribute("nextPONumber", nextPONumber);

        RequestDispatcher rd = request.getRequestDispatcher("PO/PurchaseOrder.jsp");
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
        String[] selectedIds = request.getParameterValues("indentNo");

        String vname = request.getParameter("vendorName");
        String vgstin = request.getParameter("vendorGSTIN");
        String vaddress = request.getParameter("vendorAddress");
        String quotationNo = request.getParameter("quotationNo");
        String poNo = request.getParameter("poNumber");
        String poDate = request.getParameter("poDate");
        String billingAddress = request.getParameter("billingAddress");
        String terms = request.getParameter("termsConditions");
        String general = request.getParameter("generalConditions");

        if (qtys == null || qtys.length == 0) {
            throw new ServletException("PO Creation Error: No items found to process.");
        }

        try (Connection con = DBUtil.getConnection()) {

            // =====================================================
            // STEP 1: CLUB MULTIPLE RECORDS OF SAME ITEM
            // =====================================================
            class MergedItem {
                int itemId;
                String description;
                double qty;
                double rate;
                double discPercent;
                double gstPercent;
            }

            Map<Integer, MergedItem> merged = new LinkedHashMap<>();

            for (int i = 0; i < itemIds.length; i++) {
                int id = Integer.parseInt(itemIds[i]);
                double qty = Double.parseDouble(qtys[i]);
                double rate = Double.parseDouble(rates[i]);
                double discP = Double.parseDouble(discPercents[i]);
                double gstP = Double.parseDouble(gstPercents[i]);

                if (merged.containsKey(id)) {
                    MergedItem m = merged.get(id);
                    m.qty += qty; // add quantities if same item
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

            // =====================================================
            // STEP 2: INSERT INTO po_master (with totals)
            // =====================================================
            double totalGst = 0, totalDis = 0, totalAmount = 0;

            // Calculate totals before inserting master
            for (MergedItem m : merged.values()) {
                double amount = m.qty * m.rate;
                double discVal = (m.discPercent / 100.0) * amount;
                double net = amount - discVal;
                double gstVal = (m.gstPercent / 100.0) * net;
                totalGst += gstVal;
                totalDis += discVal;
                totalAmount += (net + gstVal);
            }

            PreparedStatement psPO = con.prepareStatement(
                    "INSERT INTO po_master(vendor_name,vendor_gstin,vendor_address,po_number,quotation_number,po_date,billing_address,total_gst,total_dis,total_amount,amount_in_words,terms_conditions,general_conditions) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
                    Statement.RETURN_GENERATED_KEYS);

            psPO.setString(1, vname);
            psPO.setString(2, vgstin);
            psPO.setString(3, vaddress);
            psPO.setString(4, poNo);
            psPO.setString(5, quotationNo);
            psPO.setString(6, poDate);
            psPO.setString(7, billingAddress);
            psPO.setDouble(8, totalGst);
            psPO.setDouble(9, totalDis);
            psPO.setDouble(10, totalAmount);
            psPO.setString(11, "");
            psPO.setString(12, terms);
            psPO.setString(13, general);
            psPO.executeUpdate();

            ResultSet rsKey = psPO.getGeneratedKeys();
            int poId = 0;
            if (rsKey.next()) {
                poId = rsKey.getInt(1);
            }
            rsKey.close();
            psPO.close();

            // =====================================================
            // STEP 3: INSERT CLUBBED ITEMS INTO po_items
            // =====================================================
            PreparedStatement psItems = con.prepareStatement(
                    "INSERT INTO po_items(po_id,po_no,sl_no,item_id,description,qty,rate,amount,discount_percent,discount_value,gst_percent,gst_value,net_amount) "
                            + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");

            int slno = 1;
            for (MergedItem m : merged.values()) {
                double amount = m.qty * m.rate;
                double discVal = (m.discPercent / 100.0) * amount;
                double net = amount - discVal;
                double gstVal = (m.gstPercent / 100.0) * net;
                double netAmt = net + gstVal;

                psItems.setInt(1, poId);
                psItems.setString(2, poNo);
                psItems.setInt(3, slno++);
                psItems.setInt(4, m.itemId);
                psItems.setString(5, m.description);
                psItems.setBigDecimal(6, new BigDecimal(m.qty));
                psItems.setBigDecimal(7, new BigDecimal(m.rate));
                psItems.setBigDecimal(8, new BigDecimal(amount));
                psItems.setBigDecimal(9, new BigDecimal(m.discPercent));
                psItems.setBigDecimal(10, new BigDecimal(discVal));
                psItems.setBigDecimal(11, new BigDecimal(m.gstPercent));
                psItems.setBigDecimal(12, new BigDecimal(gstVal));
                psItems.setBigDecimal(13, new BigDecimal(netAmt));
                psItems.addBatch();
            }

            psItems.executeBatch();
            psItems.close();

            // =====================================================
            // STEP 4: UPDATE INDENT STATUS
            // =====================================================
            if (selectedIds != null && selectedIds.length > 0) {
                String placeholders = String.join(",", Collections.nCopies(selectedIds.length, "?"));
                PreparedStatement psUpdate = con.prepareStatement(
                        "UPDATE indent SET POStatus='Raised' WHERE indent_id IN (" + placeholders + ")");
                for (int i = 0; i < selectedIds.length; i++) {
                    psUpdate.setString(i + 1, selectedIds[i]);
                }
                psUpdate.executeUpdate();
                psUpdate.close();
            }

            // =====================================================
            // STEP 5: REDIRECT
            // =====================================================
            response.sendRedirect("POListServlet");

        } catch (Exception e) {
            throw new ServletException("PO Creation Error: " + e.getMessage(), e);
        }
    }
}
