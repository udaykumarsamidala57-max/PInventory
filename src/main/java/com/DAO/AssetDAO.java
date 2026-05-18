package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;

import com.bean.DBUtil;
import com.bean.DBUtil4;

public class AssetDAO {

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // =========================
    // LOAD VENDORS
    // =========================

    public ArrayList<HashMap<String, Object>> getAllVendors() {

        ArrayList<HashMap<String, Object>> list =
                new ArrayList<>();

        try {

            con = DBUtil.getConnection();

            String sql =
                    "SELECT * FROM vendors "
                    + "ORDER BY name";

            ps = con.prepareStatement(sql);

            rs = ps.executeQuery();

            while (rs.next()) {

                HashMap<String, Object> map =
                        new HashMap<>();

                map.put("id",
                        rs.getInt("id"));

                map.put("name",
                        rs.getString("name"));

                list.add(map);
            }

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            closeConnection();
        }

        return list;
    }

    // =========================
    // LOAD CATEGORIES
    // =========================

    public ArrayList<HashMap<String, Object>> getAllCategories() {

        ArrayList<HashMap<String, Object>> list =
                new ArrayList<>();

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "SELECT * FROM asset_categories "
                    + "ORDER BY category_name";

            ps = con.prepareStatement(sql);

            rs = ps.executeQuery();

            while (rs.next()) {

                HashMap<String, Object> map =
                        new HashMap<>();

                map.put("category_id",
                        rs.getInt("category_id"));

                map.put("category_name",
                        rs.getString("category_name"));

                list.add(map);
            }

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            closeConnection();
        }

        return list;
    }

    // =========================
    // LOAD SUBCATEGORIES
    // =========================

    public ArrayList<HashMap<String, Object>> getAllSubCategories() {

        ArrayList<HashMap<String, Object>> list =
                new ArrayList<>();

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "SELECT * FROM asset_subcategories "
                    + "ORDER BY subcategory_name";

            ps = con.prepareStatement(sql);

            rs = ps.executeQuery();

            while (rs.next()) {

                HashMap<String, Object> map =
                        new HashMap<>();

                map.put("subcategory_id",
                        rs.getInt("subcategory_id"));

                map.put("category_id",
                        rs.getInt("category_id"));

                map.put("subcategory_name",
                        rs.getString("subcategory_name"));

                list.add(map);
            }

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            closeConnection();
        }

        return list;
    }

    // =========================
    // LOAD LOCATIONS
    // =========================

    public ArrayList<HashMap<String, Object>> getAllLocations() {

        ArrayList<HashMap<String, Object>> list =
                new ArrayList<>();

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "SELECT * FROM locations "
                    + "ORDER BY location_name";

            ps = con.prepareStatement(sql);

            rs = ps.executeQuery();

            while (rs.next()) {

                HashMap<String, Object> map =
                        new HashMap<>();

                map.put("location_id",
                        rs.getInt("location_id"));

                map.put("location_name",
                        rs.getString("location_name"));

                map.put("building",
                        rs.getString("building"));

                map.put("floor_name",
                        rs.getString("floor_name"));

                map.put("room_number",
                        rs.getString("room_number"));

                map.put("description",
                        rs.getString("description"));

                list.add(map);
            }

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            closeConnection();
        }

        return list;
    }

    // =========================
    // ADD ASSET
    // =========================

    public boolean addAsset(

            String assetCode,
            String assetName,
            int categoryId,
            int subcategoryId,
            String vendorName,
            int locationId,
            String brand,
            String modelNumber,
            String serialNumber,
            String purchaseDate,
            double purchaseCost,
            String warrantyExpiry,
            String depreciationMethod,
            int usefulLifeYears,
            double salvageValue,
            String assetStatus,
            String qrCode,
            String description) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "INSERT INTO assets("
                    + "asset_code,"
                    + "asset_name,"
                    + "category_id,"
                    + "subcategory_id,"
                    + "vendor_name,"
                    + "location_id,"
                    + "brand,"
                    + "model_number,"
                    + "serial_number,"
                    + "purchase_date,"
                    + "purchase_cost,"
                    + "warranty_expiry,"
                    + "depreciation_method,"
                    + "useful_life_years,"
                    + "salvage_value,"
                    + "asset_status,"
                    + "qr_code,"
                    + "description"
                    + ") "
                    + "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

            ps = con.prepareStatement(sql);

            ps.setString(1, assetCode);
            ps.setString(2, assetName);
            ps.setInt(3, categoryId);
            ps.setInt(4, subcategoryId);
            ps.setString(5, vendorName);
            ps.setInt(6, locationId);
            ps.setString(7, brand);
            ps.setString(8, modelNumber);
            ps.setString(9, serialNumber);

            if (purchaseDate == null || purchaseDate.equals("")) {

                ps.setNull(10, java.sql.Types.DATE);

            } else {

                ps.setString(10, purchaseDate);
            }

            ps.setDouble(11, purchaseCost);

            if (warrantyExpiry == null || warrantyExpiry.equals("")) {

                ps.setNull(12, java.sql.Types.DATE);

            } else {

                ps.setString(12, warrantyExpiry);
            }

            ps.setString(13, depreciationMethod);
            ps.setInt(14, usefulLifeYears);
            ps.setDouble(15, salvageValue);
            ps.setString(16, assetStatus);
            ps.setString(17, qrCode);
            ps.setString(18, description);

            int i = ps.executeUpdate();

            if (i > 0) {

                status = true;
            }

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            closeConnection();
        }

        return status;
    }

    // =========================
    // GET ALL ASSETS
    // =========================

    public ArrayList<HashMap<String, Object>> getAllAssets() {

        ArrayList<HashMap<String, Object>> list =
                new ArrayList<>();

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "SELECT "
                    + "a.*, "
                    + "c.category_name, "
                    + "s.subcategory_name, "
                    + "l.location_name, "
                    + "l.building, "
                    + "l.floor_name, "
                    + "l.room_number "
                    + "FROM assets a "
                    + "LEFT JOIN asset_categories c "
                    + "ON a.category_id = c.category_id "
                    + "LEFT JOIN asset_subcategories s "
                    + "ON a.subcategory_id = s.subcategory_id "
                    + "LEFT JOIN locations l "
                    + "ON a.location_id = l.location_id "
                    + "ORDER BY a.asset_id DESC";

            ps = con.prepareStatement(sql);

            rs = ps.executeQuery();

            while (rs.next()) {

                HashMap<String, Object> map =
                        new HashMap<>();

                map.put("asset_id",
                        rs.getInt("asset_id"));

                map.put("asset_code",
                        rs.getString("asset_code"));

                map.put("asset_name",
                        rs.getString("asset_name"));

                map.put("category_id",
                        rs.getInt("category_id"));

                map.put("subcategory_id",
                        rs.getInt("subcategory_id"));

                map.put("vendor_name",
                        rs.getString("vendor_name"));

                map.put("location_id",
                        rs.getInt("location_id"));

                map.put("location_name",
                        rs.getString("location_name"));

                map.put("building",
                        rs.getString("building"));

                map.put("floor_name",
                        rs.getString("floor_name"));

                map.put("room_number",
                        rs.getString("room_number"));

                map.put("brand",
                        rs.getString("brand"));

                map.put("model_number",
                        rs.getString("model_number"));

                map.put("serial_number",
                        rs.getString("serial_number"));

                map.put("purchase_date",
                        rs.getString("purchase_date"));

                map.put("purchase_cost",
                        rs.getDouble("purchase_cost"));

                map.put("warranty_expiry",
                        rs.getString("warranty_expiry"));

                map.put("depreciation_method",
                        rs.getString("depreciation_method"));

                map.put("useful_life_years",
                        rs.getInt("useful_life_years"));

                map.put("salvage_value",
                        rs.getDouble("salvage_value"));

                map.put("asset_status",
                        rs.getString("asset_status"));

                map.put("qr_code",
                        rs.getString("qr_code"));

                map.put("description",
                        rs.getString("description"));

                map.put("category_name",
                        rs.getString("category_name"));

                map.put("subcategory_name",
                        rs.getString("subcategory_name"));

                list.add(map);
            }

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            closeConnection();
        }

        return list;
    }

    // =========================
    // DELETE ASSET
    // =========================

    public boolean deleteAsset(int id) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "DELETE FROM assets "
                    + "WHERE asset_id=?";

            ps = con.prepareStatement(sql);

            ps.setInt(1, id);

            int i = ps.executeUpdate();

            if (i > 0) {

                status = true;
            }

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            closeConnection();
        }

        return status;
    }

    // =========================
    // GET ASSET BY ID
    // =========================

    public HashMap<String, Object> getAssetById(int id) {

        HashMap<String, Object> map =
                new HashMap<>();

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "SELECT * FROM assets "
                    + "WHERE asset_id=?";

            ps = con.prepareStatement(sql);

            ps.setInt(1, id);

            rs = ps.executeQuery();

            if (rs.next()) {

                map.put("asset_id",
                        rs.getInt("asset_id"));

                map.put("asset_code",
                        rs.getString("asset_code"));

                map.put("asset_name",
                        rs.getString("asset_name"));

                map.put("category_id",
                        rs.getInt("category_id"));

                map.put("subcategory_id",
                        rs.getInt("subcategory_id"));

                map.put("vendor_name",
                        rs.getString("vendor_name"));

                map.put("location_id",
                        rs.getInt("location_id"));

                map.put("brand",
                        rs.getString("brand"));

                map.put("model_number",
                        rs.getString("model_number"));

                map.put("serial_number",
                        rs.getString("serial_number"));

                map.put("purchase_date",
                        rs.getString("purchase_date"));

                map.put("purchase_cost",
                        rs.getDouble("purchase_cost"));

                map.put("warranty_expiry",
                        rs.getString("warranty_expiry"));

                map.put("depreciation_method",
                        rs.getString("depreciation_method"));

                map.put("useful_life_years",
                        rs.getInt("useful_life_years"));

                map.put("salvage_value",
                        rs.getDouble("salvage_value"));

                map.put("asset_status",
                        rs.getString("asset_status"));

                map.put("qr_code",
                        rs.getString("qr_code"));

                map.put("description",
                        rs.getString("description"));
            }

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            closeConnection();
        }

        return map;
    }

    // =========================
    // UPDATE ASSET
    // =========================

    public boolean updateAsset(

            int assetId,
            String assetCode,
            String assetName,
            int categoryId,
            int subcategoryId,
            String vendorName,
            int locationId,
            String brand,
            String modelNumber,
            String serialNumber,
            String purchaseDate,
            double purchaseCost,
            String warrantyExpiry,
            String depreciationMethod,
            int usefulLifeYears,
            double salvageValue,
            String assetStatus,
            String qrCode,
            String description) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "UPDATE assets SET "
                    + "asset_code=?,"
                    + "asset_name=?,"
                    + "category_id=?,"
                    + "subcategory_id=?,"
                    + "vendor_name=?,"
                    + "location_id=?,"
                    + "brand=?,"
                    + "model_number=?,"
                    + "serial_number=?,"
                    + "purchase_date=?,"
                    + "purchase_cost=?,"
                    + "warranty_expiry=?,"
                    + "depreciation_method=?,"
                    + "useful_life_years=?,"
                    + "salvage_value=?,"
                    + "asset_status=?,"
                    + "qr_code=?,"
                    + "description=? "
                    + "WHERE asset_id=?";

            ps = con.prepareStatement(sql);

            ps.setString(1, assetCode);
            ps.setString(2, assetName);
            ps.setInt(3, categoryId);
            ps.setInt(4, subcategoryId);
            ps.setString(5, vendorName);
            ps.setInt(6, locationId);
            ps.setString(7, brand);
            ps.setString(8, modelNumber);
            ps.setString(9, serialNumber);

            if (purchaseDate == null || purchaseDate.equals("")) {

                ps.setNull(10, java.sql.Types.DATE);

            } else {

                ps.setString(10, purchaseDate);
            }

            ps.setDouble(11, purchaseCost);

            if (warrantyExpiry == null || warrantyExpiry.equals("")) {

                ps.setNull(12, java.sql.Types.DATE);

            } else {

                ps.setString(12, warrantyExpiry);
            }

            ps.setString(13, depreciationMethod);
            ps.setInt(14, usefulLifeYears);
            ps.setDouble(15, salvageValue);
            ps.setString(16, assetStatus);
            ps.setString(17, qrCode);
            ps.setString(18, description);

            ps.setInt(19, assetId);

            int i = ps.executeUpdate();

            if (i > 0) {

                status = true;
            }

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            closeConnection();
        }

        return status;
    }

    // =========================
    // CLOSE CONNECTION
    // =========================

    private void closeConnection() {

        try {

            if (rs != null) {

                rs.close();
            }

            if (ps != null) {

                ps.close();
            }

            if (con != null) {

                con.close();
            }

        } catch (Exception e) {

            e.printStackTrace();
        }
    }
}