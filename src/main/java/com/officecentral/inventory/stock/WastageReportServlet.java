package com.officecentral.inventory.stock;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.officecentral.common.db.InventoryDB;

/**
 * Wastage Report – Finance department and Global role only (read-only).
 *
 * GET /wastage-report?from=yyyy-MM-dd&to=yyyy-MM-dd&type=&category=&q=&export=excel
 * Lists stock_wastage rows of the selected store with totals by type. Default period: this month.
 */
@WebServlet("/wastage-report")
public class WastageReportServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(WastageReportServlet.class.getName());
    private static final int MAX_ROWS = 5000;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession s = WastageServlet.guard(req, resp);
        if (s == null) return;
        String branch = (String) s.getAttribute("branch");

        LocalDate today = StockLedgerDAO.today();
        LocalDate from = date(req.getParameter("from"), today.withDayOfMonth(1));
        LocalDate to = date(req.getParameter("to"), today);
        if (from.isAfter(to)) { LocalDate t = from; from = to; to = t; }
        String type = WastageServlet.trim(req.getParameter("type")).toUpperCase(java.util.Locale.ROOT);
        if (!Arrays.asList(WastageServlet.TYPES).contains(type)) type = "";
        String category = WastageServlet.trim(req.getParameter("category"));
        if (category.length() > 45) category = category.substring(0, 45);
        String q = WastageServlet.trim(req.getParameter("q"));
        if (q.length() > 60) q = q.substring(0, 60);

        StringBuilder sql = new StringBuilder(
                "SELECT w.wastage_no, w.wastage_date, w.wastage_type, w.qty, w.unit_price, w.total_value, "
                + "w.department, w.reason, w.entered_by, im.Item_id, im.Item_name, im.Category, im.Sub_Category, im.UOM "
                + "FROM stock_wastage w JOIN item_master im ON im.Item_id = w.item_id "
                + "WHERE w.wastage_date BETWEEN ? AND ? ");
        List<Object> params = new ArrayList<>();
        params.add(java.sql.Date.valueOf(from));
        params.add(java.sql.Date.valueOf(to));
        if (!type.isEmpty()) { sql.append("AND w.wastage_type = ? "); params.add(type); }
        if (!category.isEmpty()) { sql.append("AND im.Category = ? "); params.add(category); }
        if (!q.isEmpty()) {
            sql.append("AND (im.Item_name LIKE ? OR w.wastage_no LIKE ? OR w.reason LIKE ?) ");
            String like = "%" + q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
            params.add(like); params.add(like); params.add(like);
        }
        sql.append("ORDER BY w.wastage_date DESC, w.wastage_id DESC LIMIT ").append(MAX_ROWS + 1);

        List<Map<String, Object>> rows = new ArrayList<>();
        Map<String, BigDecimal> byType = new LinkedHashMap<>();
        List<String> categories = new ArrayList<>();
        BigDecimal total = BigDecimal.ZERO;
        boolean truncated = false;
        String error = null;

        try (Connection con = InventoryDB.getConnection(branch)) {
            try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
                for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        if (rows.size() == MAX_ROWS) { truncated = true; break; }
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("no", rs.getString("wastage_no"));
                        m.put("date", rs.getDate("wastage_date").toLocalDate());
                        m.put("type", rs.getString("wastage_type"));
                        m.put("itemId", rs.getInt("Item_id"));
                        m.put("item", rs.getString("Item_name"));
                        m.put("category", rs.getString("Category"));
                        m.put("subCategory", rs.getString("Sub_Category"));
                        m.put("uom", rs.getString("UOM"));
                        m.put("qty", WastageServlet.nz(rs.getBigDecimal("qty")));
                        m.put("rate", WastageServlet.nz(rs.getBigDecimal("unit_price")));
                        BigDecimal v = WastageServlet.nz(rs.getBigDecimal("total_value"));
                        m.put("value", v);
                        m.put("department", rs.getString("department"));
                        m.put("reason", rs.getString("reason"));
                        m.put("by", rs.getString("entered_by"));
                        rows.add(m);
                        total = total.add(v);
                        byType.merge(rs.getString("wastage_type"), v, BigDecimal::add);
                    }
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT DISTINCT Category FROM item_master WHERE Category IS NOT NULL AND Category<>'' ORDER BY Category");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) categories.add(rs.getString(1));
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Wastage report failed", e);
            error = "Could not load the report. If this is the first use, run sql/stock_wastage.sql on this store's database.";
        }

        req.setAttribute("rows", rows);
        req.setAttribute("byType", byType);
        req.setAttribute("total", total);
        req.setAttribute("truncated", truncated);
        req.setAttribute("categories", categories);
        req.setAttribute("types", WastageServlet.TYPES);
        req.setAttribute("from", from.toString());
        req.setAttribute("to", to.toString());
        req.setAttribute("type", type);
        req.setAttribute("category", category);
        req.setAttribute("q", q);
        req.setAttribute("error", error);
        boolean excel = "excel".equals(req.getParameter("export"));
        if (excel) {
            resp.setContentType("application/vnd.ms-excel; charset=UTF-8");
            resp.setHeader("Content-Disposition", "attachment; filename=Wastage_Report_" + from + "_to_" + to + ".xls");
        }
        req.setAttribute("excel", excel);
        req.getRequestDispatcher("/WEB-INF/views/inventory/stock/wastage_report.jsp").forward(req, resp);
    }

    private static LocalDate date(String v, LocalDate fallback) {
        try {
            return v == null || v.trim().isEmpty() ? fallback : LocalDate.parse(v.trim());
        } catch (DateTimeParseException e) {
            return fallback;
        }
    }
}
