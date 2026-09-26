package com.menu;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil;

@WebServlet("/MenuItemsServlet")
public class MenuItemsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);

        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String branch = (String) sess.getAttribute("branch");

        if (branch == null || branch.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Branch not found in session.");
            return;
        }

        String action = request.getParameter("action");

        if ("edit".equals(action)) {
            String id = request.getParameter("menu_item_id");
            if (id != null && !id.trim().isEmpty()) {
                try {
                    loadMenuItemForEdit(request, branch, id);
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Unable to load menu item: " + e.getMessage());
                }
            }
        }

        loadMenus(request, branch);
        loadItems(request, branch);
        loadMenuItems(request, branch);

        request.getRequestDispatcher("/menu/menu_items.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession sess = request.getSession(false);

        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String branch = (String) sess.getAttribute("branch");

        if (branch == null || branch.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Branch not found in session.");
            return;
        }

        String action = request.getParameter("action");
        String activeDay = request.getParameter("day");
        if (activeDay == null || activeDay.trim().isEmpty()) {
            activeDay = "MONDAY";
        }

        try {
            if ("save".equals(action)) {
                saveMultipleMenuItems(request, branch);
            } else if ("update".equals(action)) {
                updateMenuItem(request, branch);
            } else if ("delete".equals(action)) {
                deleteMenuItem(request, branch);
            } else {
                throw new Exception("Invalid action.");
            }

            response.sendRedirect(request.getContextPath() + "/MenuItemsServlet?day=" + activeDay + "&success=1");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", e.getMessage());

            loadMenus(request, branch);
            loadItems(request, branch);
            loadMenuItems(request, branch);

            request.getRequestDispatcher("/menu/menu_items.jsp").forward(request, response);
        }
    }

    private void loadMenuItemForEdit(HttpServletRequest request, String branch, String id) throws Exception {
        int menuItemId;
        try {
            menuItemId = Integer.parseInt(id);
        } catch (NumberFormatException e) {
            throw new Exception("Invalid Menu Item ID.");
        }

        String sql = "SELECT menu_item_id, menu_id, item_id, quantity, sequence_no FROM menu_items WHERE menu_item_id = ?";

        try (Connection con = DBUtil.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, menuItemId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    request.setAttribute("menu_item_id", rs.getInt("menu_item_id"));
                    request.setAttribute("selected_menu_id", rs.getInt("menu_id"));
                    request.setAttribute("selected_item_id", rs.getInt("item_id"));
                    request.setAttribute("quantity", rs.getBigDecimal("quantity"));
                    request.setAttribute("sequence_no", rs.getInt("sequence_no"));
                } else {
                    throw new Exception("Menu item record not found.");
                }
            }
        }
    }

    // ============================================================
    // BATCH SAVE MULTIPLE MENU ITEMS
    // ============================================================
    private void saveMultipleMenuItems(HttpServletRequest request, String branch) throws Exception {
        String menuIdParam = request.getParameter("menu_id");
        String[] itemIds = request.getParameterValues("item_id");
        String[] quantities = request.getParameterValues("quantity");
        String[] sequenceNos = request.getParameterValues("sequence_no");

        if (menuIdParam == null || menuIdParam.trim().isEmpty()) {
            throw new Exception("Please select a menu.");
        }
        if (itemIds == null || itemIds.length == 0) {
            throw new Exception("Please add at least one item to the list.");
        }

        int menuId = Integer.parseInt(menuIdParam);
        String sql = "INSERT INTO menu_items (menu_id, item_id, quantity, sequence_no) VALUES (?, ?, ?, ?)";

        try (Connection con = DBUtil.getConnection(branch)) {
            con.setAutoCommit(false);
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                for (int i = 0; i < itemIds.length; i++) {
                    if (itemIds[i] == null || itemIds[i].trim().isEmpty()) continue;

                    int itemId = Integer.parseInt(itemIds[i]);
                    double qty = (quantities != null && i < quantities.length && !quantities[i].trim().isEmpty()) 
                                 ? Double.parseDouble(quantities[i]) : 1.0;
                    int seq = (sequenceNos != null && i < sequenceNos.length && !sequenceNos[i].trim().isEmpty()) 
                              ? Integer.parseInt(sequenceNos[i]) : 1;

                    if (qty <= 0 || seq <= 0) {
                        throw new Exception("Quantity and Sequence number must be greater than zero.");
                    }

                    ps.setInt(1, menuId);
                    ps.setInt(2, itemId);
                    ps.setDouble(3, qty);
                    ps.setInt(4, seq);
                    ps.addBatch();
                }
                ps.executeBatch();
                con.commit();
            } catch (Exception e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    private void updateMenuItem(HttpServletRequest request, String branch) throws Exception {
        String menuItemIdParam = request.getParameter("menu_item_id");
        String menuIdParam = request.getParameter("menu_id");
        String itemIdParam = request.getParameter("item_id");
        String quantityParam = request.getParameter("quantity");
        String sequenceParam = request.getParameter("sequence_no");

        if (menuItemIdParam == null || menuItemIdParam.trim().isEmpty()) {
            throw new Exception("Menu Item ID is missing.");
        }

        int menuItemId = Integer.parseInt(menuItemIdParam);
        int menuId = Integer.parseInt(menuIdParam);
        int itemId = Integer.parseInt(itemIdParam);

        double quantity = Double.parseDouble(quantityParam);
        int sequenceNo = Integer.parseInt(sequenceParam);

        if (quantity <= 0 || sequenceNo <= 0) {
            throw new Exception("Quantity and sequence number must be greater than zero.");
        }

        String sql = "UPDATE menu_items SET menu_id = ?, item_id = ?, quantity = ?, sequence_no = ? WHERE menu_item_id = ?";

        try (Connection con = DBUtil.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, menuId);
            ps.setInt(2, itemId);
            ps.setDouble(3, quantity);
            ps.setInt(4, sequenceNo);
            ps.setInt(5, menuItemId);

            int rows = ps.executeUpdate();
            if (rows == 0) {
                throw new Exception("Menu item record not found.");
            }
        }
    }

    private void deleteMenuItem(HttpServletRequest request, String branch) throws Exception {
        String id = request.getParameter("menu_item_id");

        if (id == null || id.trim().isEmpty()) {
            throw new Exception("Menu Item ID is missing.");
        }

        int menuItemId = Integer.parseInt(id);

        String sql = "DELETE FROM menu_items WHERE menu_item_id = ?";

        try (Connection con = DBUtil.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, menuItemId);
            int rows = ps.executeUpdate();
            if (rows == 0) {
                throw new Exception("Menu item record not found.");
            }
        }
    }

    private void loadMenus(HttpServletRequest request, String branch) {
        List<Map<String, Object>> menus = new ArrayList<>();

        String sql = "SELECT menu_id, day_of_week, session, menu_name FROM menu_master WHERE active = 1 "
                   + "ORDER BY FIELD(day_of_week, 'MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'), "
                   + "FIELD(session, 'BREAKFAST','LUNCH','SNACKS','DINNER'), menu_id";

        try (Connection con = DBUtil.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> menu = new HashMap<>();
                menu.put("menu_id", rs.getInt("menu_id"));
                menu.put("day_of_week", rs.getString("day_of_week"));
                menu.put("session", rs.getString("session"));
                menu.put("menu_name", rs.getString("menu_name"));
                menus.add(menu);
            }
            request.setAttribute("menus", menus);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Unable to load menus: " + e.getMessage());
        }
    }

    private void loadItems(HttpServletRequest request, String branch) {
        List<Map<String, Object>> items = new ArrayList<>();

        String sql = "SELECT Item_id, Category, Sub_Category, Item_name, UOM FROM item_master ORDER BY Category, Sub_Category, Item_name";

        try (Connection con = DBUtil.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("item_id", rs.getInt("Item_id"));
                item.put("category", rs.getString("Category") != null ? rs.getString("Category") : "");
                item.put("sub_category", rs.getString("Sub_Category") != null ? rs.getString("Sub_Category") : "");
                item.put("item_name", rs.getString("Item_name"));
                item.put("uom", rs.getString("UOM") != null ? rs.getString("UOM") : "");
                items.add(item);
            }
            request.setAttribute("items", items);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Unable to load items: " + e.getMessage());
        }
    }

    private void loadMenuItems(HttpServletRequest request, String branch) {
        List<Map<String, Object>> menuItems = new ArrayList<>();

        String sql = "SELECT mi.menu_item_id, mi.menu_id, mi.item_id, mi.quantity, mi.sequence_no, "
                   + "mm.day_of_week, mm.session, mm.menu_name, "
                   + "im.Item_name, im.Category, im.Sub_Category, im.UOM "
                   + "FROM menu_items mi "
                   + "INNER JOIN menu_master mm ON mi.menu_id = mm.menu_id "
                   + "INNER JOIN item_master im ON mi.item_id = im.Item_id "
                   + "ORDER BY FIELD(mm.day_of_week, 'MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'), "
                   + "FIELD(mm.session, 'BREAKFAST','LUNCH','SNACKS','DINNER'), "
                   + "mi.sequence_no, mi.menu_item_id";

        try (Connection con = DBUtil.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("menu_item_id", rs.getInt("menu_item_id"));
                row.put("menu_id", rs.getInt("menu_id"));
                row.put("item_id", rs.getInt("item_id"));
                row.put("quantity", rs.getBigDecimal("quantity"));
                row.put("sequence_no", rs.getInt("sequence_no"));
                row.put("day_of_week", rs.getString("day_of_week"));
                row.put("session", rs.getString("session"));
                row.put("menu_name", rs.getString("menu_name"));
                row.put("item_name", rs.getString("Item_name"));
                row.put("category", rs.getString("Category"));
                row.put("sub_category", rs.getString("Sub_Category"));
                row.put("uom", rs.getString("UOM"));
                menuItems.add(row);
            }
            request.setAttribute("menuItems", menuItems);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Unable to load menu items: " + e.getMessage());
        }
    }
}