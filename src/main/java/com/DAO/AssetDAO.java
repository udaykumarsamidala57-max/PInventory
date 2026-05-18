package com.DAO;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;

import com.bean.DBUtil;

public class AssetDAO {

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // ADD ASSET
    public boolean addAsset(
            String assetCode,
            String assetName,
            int vendorId,
            String brand) {

        boolean status = false;

        try {

            con = DBUtil.getConnection();

            String sql =
                    "INSERT INTO assets "
                    + "(asset_code,asset_name,vendor_id,brand) "
                    + "VALUES(?,?,?,?)";

            ps = con.prepareStatement(sql);

            ps.setString(1, assetCode);
            ps.setString(2, assetName);
            ps.setInt(3, vendorId);
            ps.setString(4, brand);

            int i = ps.executeUpdate();

            if(i > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // GET ALL ASSETS
    public ArrayList<HashMap<String,Object>> getAllAssets() {

        ArrayList<HashMap<String,Object>> list =
                new ArrayList<>();

        try {

            con = DBUtil.getConnection();

            String sql =
                    "SELECT a.*,v.name vendor_name "
                    + "FROM assets a "
                    + "LEFT JOIN vendors v "
                    + "ON a.vendor_id=v.id "
                    + "ORDER BY a.asset_id DESC";

            ps = con.prepareStatement(sql);

            rs = ps.executeQuery();

            while(rs.next()) {

                HashMap<String,Object> map =
                        new HashMap<>();

                map.put("asset_id",
                        rs.getInt("asset_id"));

                map.put("asset_code",
                        rs.getString("asset_code"));

                map.put("asset_name",
                        rs.getString("asset_name"));

                map.put("vendor_id",
                        rs.getInt("vendor_id"));

                map.put("vendor_name",
                        rs.getString("vendor_name"));

                map.put("brand",
                        rs.getString("brand"));

                map.put("asset_status",
                        rs.getString("asset_status"));

                list.add(map);
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return list;
    }

    // DELETE
    public boolean deleteAsset(int id) {

        boolean status = false;

        try {

            con = DBUtil.getConnection();

            String sql =
                    "DELETE FROM assets "
                    + "WHERE asset_id=?";

            ps = con.prepareStatement(sql);

            ps.setInt(1, id);

            int i = ps.executeUpdate();

            if(i > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // GET BY ID
    public HashMap<String,Object> getAssetById(int id) {

        HashMap<String,Object> map =
                new HashMap<>();

        try {

            con = DBUtil.getConnection();

            String sql =
                    "SELECT * FROM assets "
                    + "WHERE asset_id=?";

            ps = con.prepareStatement(sql);

            ps.setInt(1, id);

            rs = ps.executeQuery();

            if(rs.next()) {

                map.put("asset_id",
                        rs.getInt("asset_id"));

                map.put("asset_code",
                        rs.getString("asset_code"));

                map.put("asset_name",
                        rs.getString("asset_name"));

                map.put("vendor_id",
                        rs.getInt("vendor_id"));

                map.put("brand",
                        rs.getString("brand"));
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return map;
    }

    // UPDATE
    public boolean updateAsset(
            int assetId,
            String assetCode,
            String assetName,
            int vendorId,
            String brand) {

        boolean status = false;

        try {

            con = DBUtil.getConnection();

            String sql =
                    "UPDATE assets SET "
                    + "asset_code=?,"
                    + "asset_name=?,"
                    + "vendor_id=?,"
                    + "brand=? "
                    + "WHERE asset_id=?";

            ps = con.prepareStatement(sql);

            ps.setString(1, assetCode);
            ps.setString(2, assetName);
            ps.setInt(3, vendorId);
            ps.setString(4, brand);
            ps.setInt(5, assetId);

            int i = ps.executeUpdate();

            if(i > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }
}