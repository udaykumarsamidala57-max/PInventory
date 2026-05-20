package com.DAO;

import com.bean.Asset;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import com.bean.DBUtil4;

public class AssetDAO {

    public void insertAsset(Asset asset) throws SQLException {
        String sql = "INSERT INTO assets (asset_code, asset_name, category_id, subcategory_id, vendor_name, brand, model_number, serial_number, purchase_date, purchase_cost, warranty_expiry, depreciation_method, useful_life_years, salvage_value, asset_status, qr_code, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DBUtil4.getConnection(); 
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            setPreparedStatementValues(ps, asset);
            ps.executeUpdate();
        }
    }

    public List<Asset> getAllAssets() throws SQLException {
        List<Asset> list = new ArrayList<>();
        // Updated to target asset_categories and asset_subcategories tables
        String sql = "SELECT a.*, c.category_name, sc.subcategory_name " +
                     "FROM assets a " +
                     "LEFT JOIN asset_categories c ON a.category_id = c.category_id " +
                     "LEFT JOIN asset_subcategories sc ON a.subcategory_id = sc.subcategory_id " +
                     "ORDER BY a.created_at DESC";
        
        try (Connection conn = DBUtil4.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            while (rs.next()) {
                Asset asset = mapResultSetToAsset(rs);
                list.add(asset);
            }
        }
        return list;
    }

    public Asset getAssetById(int id) throws SQLException {
        // Updated to target asset_categories and asset_subcategories tables
        String sql = "SELECT a.*, c.category_name, sc.subcategory_name " +
                     "FROM assets a " +
                     "LEFT JOIN asset_categories c ON a.category_id = c.category_id " +
                     "LEFT JOIN asset_subcategories sc ON a.subcategory_id = sc.subcategory_id " +
                     "WHERE a.asset_id = ?";
        try (Connection conn = DBUtil4.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToAsset(rs);
                }
            }
        }
        return null;
    }

    public void updateAsset(Asset asset) throws SQLException {
        String sql = "UPDATE assets SET asset_code=?, asset_name=?, category_id=?, subcategory_id=?, vendor_name=?, brand=?, model_number=?, serial_number=?, purchase_date=?, purchase_cost=?, warranty_expiry=?, depreciation_method=?, useful_life_years=?, salvage_value=?, asset_status=?, qr_code=?, description=? WHERE asset_id=?";
        
        try (Connection conn = DBUtil4.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            setPreparedStatementValues(ps, asset);
            ps.setInt(18, asset.getAssetId());
            ps.executeUpdate();
        }
    }

    // Helper method to keep code clean and handle potentially null database values
    private void setPreparedStatementValues(PreparedStatement ps, Asset asset) throws SQLException {
        ps.setString(1, asset.getAssetCode());
        ps.setString(2, asset.getAssetName());
        
        if (asset.getCategoryId() != null) ps.setInt(3, asset.getCategoryId()); else ps.setNull(3, Types.INTEGER);
        if (asset.getSubcategoryId() != null) ps.setInt(4, asset.getSubcategoryId()); else ps.setNull(4, Types.INTEGER);
        
        ps.setString(5, asset.getVendorName());
        ps.setString(6, asset.getBrand());
        ps.setString(7, asset.getModelNumber());
        ps.setString(8, asset.getSerialNumber());
        ps.setDate(9, asset.getPurchaseDate());
        ps.setBigDecimal(10, asset.getPurchaseCost());
        ps.setDate(11, asset.getWarrantyExpiry());
        ps.setString(12, asset.getDepreciationMethod());
        
        if (asset.getUsefulLifeYears() != null) ps.setInt(13, asset.getUsefulLifeYears()); else ps.setNull(13, Types.INTEGER);
        
        ps.setBigDecimal(14, asset.getSalvageValue());
        ps.setString(15, asset.getAssetStatus());
        ps.setString(16, asset.getQrCode());
        ps.setString(17, asset.getDescription());
    }

    private Asset mapResultSetToAsset(ResultSet rs) throws SQLException {
        Asset asset = new Asset();
        asset.setAssetId(rs.getInt("asset_id"));
        asset.setAssetCode(rs.getString("asset_code"));
        asset.setAssetName(rs.getString("asset_name"));
        
        int catId = rs.getInt("category_id");
        asset.setCategoryId(rs.wasNull() ? null : catId);
        int subCatId = rs.getInt("subcategory_id");
        asset.setSubcategoryId(rs.wasNull() ? null : subCatId);
        
        asset.setVendorName(rs.getString("vendor_name"));
        asset.setBrand(rs.getString("brand"));
        asset.setModelNumber(rs.getString("model_number"));
        asset.setSerialNumber(rs.getString("serial_number"));
        asset.setPurchaseDate(rs.getDate("purchase_date"));
        asset.setPurchaseCost(rs.getBigDecimal("purchase_cost"));
        asset.setWarrantyExpiry(rs.getDate("warranty_expiry"));
        asset.setDepreciationMethod(rs.getString("depreciation_method"));
        
        int usefulLife = rs.getInt("useful_life_years");
        asset.setUsefulLifeYears(rs.wasNull() ? null : usefulLife);
        
        asset.setSalvageValue(rs.getBigDecimal("salvage_value"));
        asset.setAssetStatus(rs.getString("asset_status"));
        asset.setQrCode(rs.getString("qr_code"));
        asset.setDescription(rs.getString("description"));
        asset.setCreatedAt(rs.getTimestamp("created_at"));
        
        // Map the category_name field securely
        try {
            asset.setCategoryName(rs.getString("category_name"));
        } catch (SQLException e) {
            asset.setCategoryName(null);
        }

        // Map the subcategory_name field securely
        try {
            asset.setSubcategoryName(rs.getString("subcategory_name"));
        } catch (SQLException e) {
            asset.setSubcategoryName(null);
        }
        
        return asset;
    }
}