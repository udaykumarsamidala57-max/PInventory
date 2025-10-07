package com.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.bean.DBUtil;
import com.bean.PO;
import com.bean.POItems;

@WebServlet("/POListServlet")

public class POListServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String deleteId = request.getParameter("delete_id");
        String approveId = request.getParameter("Approve_id");

        // ✅ Handle deletion
        if (deleteId != null) {
            try (Connection con = DBUtil.getConnection();
                 PreparedStatement ps1 = con.prepareStatement("DELETE FROM po_items WHERE po_no=?");
                 PreparedStatement ps2 = con.prepareStatement("DELETE FROM po_master WHERE po_number=?")) {

                ps1.setString(1, deleteId);
                ps1.executeUpdate();

                ps2.setString(1, deleteId);
                ps2.executeUpdate();

            } catch (Exception e) {
                e.printStackTrace();
            }
            response.sendRedirect("PO/POListServlet");
            return;
        }

        // ✅ Handle approval
        if (approveId != null) {
            try (Connection con = DBUtil.getConnection();
                 PreparedStatement ps = con.prepareStatement(
                         "UPDATE po_master SET Approval=? WHERE po_number=?")) {

                ps.setString(1, "Approved");
                ps.setString(2, approveId);
                ps.executeUpdate();

            } catch (Exception e) {
                e.printStackTrace();
            }
            response.sendRedirect("POListServlet");
            return;
        }

        // ✅ Fetch Purchase Orders and their related items
        List<PO> poList = new ArrayList<>();

        try (Connection con = DBUtil.getConnection();
             Statement stmt = con.createStatement();
             ResultSet rs = stmt.executeQuery(
                     "SELECT * FROM po_master WHERE po_status = 'Open' OR po_status = 'Partially Received' ORDER BY po_date DESC")) {

            while (rs.next()) {
                PO po = new PO();
                int poId = rs.getInt("PO_id");
                String poNumber = rs.getString("po_number");

                po.setPoNumber(poNumber);
                po.setPoDate(rs.getString("po_date")); // ✅ Use lowercase if column name is po_date
                po.setVendorName(rs.getString("vendor_name"));
                po.setTotalAmount(rs.getDouble("total_amount"));
                po.setApproval(rs.getString("Approval"));

                // ✅ Fetch related PO items with balance and received quantities
                List<POItems> items = new ArrayList<>();
                try (PreparedStatement ps2 = con.prepareStatement(
                        "SELECT i.*, s.balance_qty, " +
                        "COALESCE((SELECT SUM(g.qty_received) " +
                        "          FROM grn_items g " +
                        "          WHERE g.po_item_id = i.po_item_id), 0) AS received_qty " +
                        "FROM po_items i " +
                        "LEFT JOIN stock s ON i.item_id = s.item_id " +
                        "WHERE i.PO_id = ?")) {

                    ps2.setInt(1, poId);

                    try (ResultSet rs2 = ps2.executeQuery()) {
                        while (rs2.next()) {
                            POItems item = new POItems();
                            item.setId(rs2.getInt("po_item_id"));
                            item.setItemId(rs2.getInt("item_id"));
                            item.setIndentNo(rs2.getString("po_no"));
                            item.setItemName(rs2.getString("description"));
                            item.setQty(rs2.getDouble("qty"));
                            item.setReceivedQty(rs2.getDouble("received_qty"));
                            item.setRate(rs2.getDouble("rate"));
                            item.setDiscountPercent(rs2.getDouble("discount_percent"));
                            item.setGstPercent(rs2.getDouble("gst_percent"));
                            item.setBalanceQty(rs2.getDouble("balance_qty"));
                            items.add(item);
                        }
                    }
                }
                po.setItems(items);
                poList.add(po);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        // ✅ Forward PO list to JSP
        request.setAttribute("poList", poList);
        RequestDispatcher rd = request.getRequestDispatcher("PO/POlist.jsp");
        rd.forward(request, response);
    }
}
