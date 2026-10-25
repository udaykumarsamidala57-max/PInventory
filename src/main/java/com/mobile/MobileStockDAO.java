package com.mobile;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.officecentral.common.db.InventoryDB;
import com.officecentral.inventory.stock.StockLedgerDAO;

/** Current stock (same data as the website's Stock page: stock + item_master, value = balance x last price). */
final class MobileStockDAO {

    private final StockLedgerDAO ledger = new StockLedgerDAO();

    /** Stock Ledger Report for the app. from/to = yyyy-MM-dd (both blank = all dates). */
    Map<String, Object> ledger(MobileApiServlet.Ctx c, String from, String to, String q, String category,
                               boolean movedOnly) throws SQLException {
        try {
            return ledger.summary(c.branch, StockLedgerDAO.parseRange(from, to), q, category, movedOnly);
        } catch (StockLedgerDAO.BadRequest e) {
            throw new ApiException(400, e.getMessage());
        }
    }

    /** One item's ledger. type = ALL | RECEIPT | ISSUE | OPENING (default ALL). */
    Map<String, Object> itemLedger(MobileApiServlet.Ctx c, int itemId, String type, String from, String to)
            throws SQLException {
        String t = MobileApiServlet.trim(type).isEmpty() ? "ALL" : MobileApiServlet.trim(type);
        try {
            return ledger.detail(c.branch, itemId, t, StockLedgerDAO.parseRange(from, to));
        } catch (StockLedgerDAO.NotFound e) {
            throw new ApiException(404, e.getMessage());
        } catch (StockLedgerDAO.BadRequest e) {
            throw new ApiException(400, e.getMessage());
        }
    }

    Map<String, Object> report(MobileApiServlet.Ctx c, String q, String category, boolean outOfStockOnly)
            throws SQLException {
        String term = MobileApiServlet.trim(q);
        if (term.length() > 60) term = term.substring(0, 60);
        String cat = MobileApiServlet.trim(category);
        if (cat.length() > 100) cat = cat.substring(0, 100);

        StringBuilder sql = new StringBuilder(
                "SELECT s.item_id, i.Item_name, i.Category, i.UOM, s.balance_qty, s.last_price "
                + "FROM stock s JOIN item_master i ON s.item_id = i.Item_id WHERE 1=1 ");
        List<String> params = new ArrayList<>();
        if (!term.isEmpty()) {
            sql.append("AND i.Item_name LIKE ? ");
            params.add("%" + term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%");
        }
        if (!cat.isEmpty()) {
            sql.append("AND i.Category = ? ");
            params.add(cat);
        }
        if (outOfStockOnly) sql.append("AND COALESCE(s.balance_qty,0) <= 0 ");
        sql.append("ORDER BY i.Item_name LIMIT 3000");

        List<Map<String, Object>> items = new ArrayList<>();
        List<String> categories = new ArrayList<>();
        double total = 0;
        try (Connection con = InventoryDB.getConnection(c.branch)) {
            try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
                for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        double qty = rs.getDouble("balance_qty");
                        double rate = rs.getDouble("last_price");
                        double value = Math.round(qty * rate * 100d) / 100d;
                        total += value;
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("itemId", rs.getInt("item_id"));
                        m.put("name", rs.getString("Item_name"));
                        m.put("category", rs.getString("Category"));
                        m.put("unit", rs.getString("UOM"));
                        m.put("qty", qty);
                        m.put("reorderLevel", 0);
                        m.put("rate", rate);
                        m.put("value", value);
                        items.add(m);
                    }
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT DISTINCT Category FROM item_master WHERE Category IS NOT NULL AND Category<>'' ORDER BY Category");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) categories.add(rs.getString(1));
            }
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("items", items);
        res.put("categories", categories);
        res.put("totalValue", Math.round(total * 100d) / 100d);
        return res;
    }
}
