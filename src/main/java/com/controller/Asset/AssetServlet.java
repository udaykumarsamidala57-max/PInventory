package com.controller.Asset;

import com.DAO.AssetDAO;
import com.bean.Asset;
import com.bean.DBUtil4;
import com.bean.DBUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/AssetServlet")
public class AssetServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private AssetDAO assetDAO;

    public void init() {
        assetDAO = new AssetDAO();
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String action = request.getParameter("action");
        try {
            if ("edit".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                Asset existingAsset = assetDAO.getAssetById(id);
                // Send the asset back to fill the form for update
                request.setAttribute("editableAsset", existingAsset);
            }
            // Always reload asset list matrix along with category option maps
            loadDashboardData(request, response);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        try {
            String assetIdStr = request.getParameter("assetId");
            Asset asset = new Asset();
            
            // Map parameter entries directly down to our Model data types
            asset.setAssetCode(request.getParameter("assetCode"));
            asset.setAssetName(request.getParameter("assetName"));
            asset.setCategoryId(getIntegerParameter(request, "categoryId"));
            asset.setSubcategoryId(getIntegerParameter(request, "subcategoryId"));
            asset.setVendorName(request.getParameter("vendorName"));
            asset.setBrand(request.getParameter("brand"));
            asset.setModelNumber(request.getParameter("modelNumber"));
            asset.setSerialNumber(request.getParameter("serialNumber"));
            asset.setPurchaseDate(getDateParameter(request, "purchaseDate"));
            asset.setPurchaseCost(getBigDecimalParameter(request, "purchaseCost"));
            asset.setWarrantyExpiry(getDateParameter(request, "warrantyExpiry"));
            asset.setDepreciationMethod(request.getParameter("depreciationMethod"));
            asset.setUsefulLifeYears(getIntegerParameter(request, "usefulLifeYears"));
            asset.setSalvageValue(getBigDecimalParameter(request, "salvageValue"));
            asset.setAssetStatus(request.getParameter("assetStatus"));
            asset.setQrCode(request.getParameter("qrCode"));
            asset.setDescription(request.getParameter("description"));

            if (assetIdStr == null || assetIdStr.trim().isEmpty()) {
                // If ID is missing, create a new record
                assetDAO.insertAsset(asset);
            } else {
                // If ID is present, update the existing record
                asset.setAssetId(Integer.parseInt(assetIdStr));
                assetDAO.updateAsset(asset);
            }
            
            // PRG Pattern: Redirect to prevent form resubmission duplicate bugs
            response.sendRedirect("AssetServlet");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    private void loadDashboardData(HttpServletRequest request, HttpServletResponse response) 
            throws SQLException, ServletException, IOException {
        // 1. Fetch our main asset listing records
        List<Asset> assetList = assetDAO.getAllAssets();
        request.setAttribute("assetList", assetList);
        
        // 2. Dynamic Fetch: Extract all system categories using corrected table name
        List<Map<String, Object>> categoriesList = new ArrayList<>();
        String catSql = "SELECT category_id, category_name FROM asset_categories ORDER BY category_name ASC";
        
        try (Connection conn = DBUtil4.getConnection();
             PreparedStatement ps = conn.prepareStatement(catSql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> categoryMap = new HashMap<>();
                categoryMap.put("id", rs.getInt("category_id"));
                categoryMap.put("name", rs.getString("category_name"));
                categoriesList.add(categoryMap);
            }
        } catch (Exception e) {
            System.err.println("Notice: Could not load asset_categories list directly: " + e.getMessage());
        }
        request.setAttribute("categoriesList", categoriesList);

        // 3. Dynamic Fetch: Extract subcategories to populate subcategory dropdown elements
        List<Map<String, Object>> subcategoriesList = new ArrayList<>();
        String subCatSql = "SELECT subcategory_id, subcategory_name, category_id FROM asset_subcategories ORDER BY subcategory_name ASC";
        
        try (Connection conn = DBUtil4.getConnection();
             PreparedStatement ps = conn.prepareStatement(subCatSql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> subCategoryMap = new HashMap<>();
                subCategoryMap.put("id", rs.getInt("subcategory_id"));
                subCategoryMap.put("name", rs.getString("subcategory_name"));
                subCategoryMap.put("categoryId", rs.getInt("category_id")); 
                subcategoriesList.add(subCategoryMap);
            }
        } catch (Exception e) {
            System.err.println("Notice: Could not load asset_subcategories list directly: " + e.getMessage());
        }
        request.setAttribute("subcategoriesList", subcategoriesList);

        // 4. New Dynamic Fetch: Extract vendors (ID and Name only) for the form dropdown
        List<Map<String, Object>> vendorsList = new ArrayList<>();
        // Assuming your table is named 'vendors' based on your schema structure
        String vendorSql = "SELECT id, name FROM vendors ORDER BY name ASC";
        
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        String role = (String) sess.getAttribute("role");
        String dept = (String) sess.getAttribute("department");
        String branch = (String) sess.getAttribute("branch");
        
        try (Connection conn = DBUtil.getConnection(branch);
             PreparedStatement ps = conn.prepareStatement(vendorSql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> vendorMap = new HashMap<>();
               
                vendorMap.put("name", rs.getString("name"));
                vendorsList.add(vendorMap);
            }
        } catch (Exception e) {
            System.err.println("Notice: Could not load vendors list directly: " + e.getMessage());
        }
        request.setAttribute("vendorsList", vendorsList);
        
        // 5. Forward control structure cleanly to your dedicated folder view
        request.getRequestDispatcher("/Asset/asset.jsp").forward(request, response);
    }

    // Safely handles empty string conversions for alternate DB data types
    private Integer getIntegerParameter(HttpServletRequest r, String p) {
        String val = r.getParameter(p);
        return (val != null && !val.trim().isEmpty()) ? Integer.parseInt(val) : null;
    }

    private Date getDateParameter(HttpServletRequest r, String p) {
        String val = r.getParameter(p);
        return (val != null && !val.trim().isEmpty()) ? Date.valueOf(val) : null;
    }

    private BigDecimal getBigDecimalParameter(HttpServletRequest r, String p) {
        String val = r.getParameter(p);
        return (val != null && !val.trim().isEmpty()) ? new BigDecimal(val) : null;
    }
}