package com.DAO;

import java.sql.*;
import java.util.*;

import com.bean.DBUtil4;

public class AssetLocationDAO {

    /*
     * Always create fresh connection.
     * Prevents stale / closed connection issues.
     */
    private Connection getConnection() throws Exception {

        return DBUtil4.getConnection();
    }

    /* =========================
       CATEGORY LIST
       ========================= */

    public ArrayList<HashMap<String,Object>> getCategories(){

        ArrayList<HashMap<String,Object>> list =
                new ArrayList<>();

        String sql =
                "SELECT * FROM asset_categories "
              + "ORDER BY category_name";

        try(Connection con = getConnection();
            PreparedStatement ps =
                    con.prepareStatement(sql);
            ResultSet rs =
                    ps.executeQuery()){

            while(rs.next()){

                HashMap<String,Object> map =
                        new HashMap<>();

                map.put(
                        "category_id",
                        rs.getInt("category_id"));

                map.put(
                        "category_name",
                        rs.getString("category_name"));

                list.add(map);
            }

        }catch(Exception e){
            e.printStackTrace();
        }

        return list;
    }

    /* =========================
       SUBCATEGORY LIST
       ========================= */

    public ArrayList<HashMap<String,Object>>
    getSubcategories(String categoryId){

        ArrayList<HashMap<String,Object>> list =
                new ArrayList<>();

        String sql =
                "SELECT * FROM asset_subcategories "
              + "WHERE category_id=? "
              + "ORDER BY subcategory_name";

        try(Connection con = getConnection();
            PreparedStatement ps =
                    con.prepareStatement(sql)){

            ps.setString(1, categoryId);

            try(ResultSet rs = ps.executeQuery()){

                while(rs.next()){

                    HashMap<String,Object> map =
                            new HashMap<>();

                    map.put(
                            "subcategory_id",
                            rs.getInt("subcategory_id"));

                    map.put(
                            "subcategory_name",
                            rs.getString("subcategory_name"));

                    list.add(map);
                }
            }

        }catch(Exception e){
            e.printStackTrace();
        }

        return list;
    }

    /* =========================
       ASSET LIST
       ========================= */

    public ArrayList<HashMap<String,Object>>
    getAssets(String categoryId,
              String subcategoryId){

        ArrayList<HashMap<String,Object>> list =
                new ArrayList<>();

        String sql =
                "SELECT "
              + "a.asset_id, "
              + "a.asset_code, "
              + "a.asset_name, "
              + "l.location_name AS current_location "
              + "FROM assets a "
              + "LEFT JOIN asset_current_location acl "
              + "ON a.asset_id = acl.asset_id "
              + "LEFT JOIN locations l "
              + "ON acl.location_id = l.location_id "
              + "WHERE a.category_id=? "
              + "AND a.subcategory_id=? "
              + "ORDER BY a.asset_name";

        try(Connection con = getConnection();
            PreparedStatement ps =
                    con.prepareStatement(sql)){

            ps.setString(1, categoryId);
            ps.setString(2, subcategoryId);

            try(ResultSet rs = ps.executeQuery()){

                while(rs.next()){

                    HashMap<String,Object> map =
                            new HashMap<>();

                    map.put(
                            "asset_id",
                            rs.getInt("asset_id"));

                    map.put(
                            "asset_code",
                            rs.getString("asset_code"));

                    map.put(
                            "asset_name",
                            rs.getString("asset_name"));

                    map.put(
                            "current_location",
                            rs.getString("current_location"));

                    list.add(map);
                }
            }

        }catch(Exception e){
            e.printStackTrace();
        }

        return list;
    }

    /* =========================
       LOCATION LIST
       ========================= */

    public ArrayList<HashMap<String,Object>>
    getLocations(){

        ArrayList<HashMap<String,Object>> list =
                new ArrayList<>();

        String sql =
                "SELECT * FROM locations "
              + "ORDER BY location_name";

        try(Connection con = getConnection();
            PreparedStatement ps =
                    con.prepareStatement(sql);
            ResultSet rs =
                    ps.executeQuery()){

            while(rs.next()){

                HashMap<String,Object> map =
                        new HashMap<>();

                map.put(
                        "location_id",
                        rs.getInt("location_id"));

                map.put(
                        "location_name",
                        rs.getString("location_name"));

                map.put(
                        "building",
                        rs.getString("building"));

                list.add(map);
            }

        }catch(Exception e){
            e.printStackTrace();
        }

        return list;
    }

    /* =========================
       ASSIGN LOCATION
       ========================= */

    public boolean assignLocation(
            int assetId,
            int newLocationId,
            String user){

        boolean status = false;

        String oldSql =
                "SELECT location_id "
              + "FROM asset_current_location "
              + "WHERE asset_id=?";

        String updateSql =
                "UPDATE asset_current_location "
              + "SET location_id=?, "
              + "assigned_by=?, "
              + "assigned_date=NOW() "
              + "WHERE asset_id=?";

        String insertSql =
                "INSERT INTO asset_current_location "
              + "(asset_id, location_id, assigned_by) "
              + "VALUES(?,?,?)";

        String historySql =
                "INSERT INTO asset_location_history "
              + "(asset_id, from_location_id, "
              + "to_location_id, moved_by) "
              + "VALUES(?,?,?,?)";

        try(Connection con = getConnection()){

            con.setAutoCommit(false);

            int oldLocationId = 0;

            /*
             * CHECK OLD LOCATION
             */

            try(PreparedStatement oldPs =
                        con.prepareStatement(oldSql)){

                oldPs.setInt(1, assetId);

                try(ResultSet rs =
                            oldPs.executeQuery()){

                    if(rs.next()){

                        oldLocationId =
                                rs.getInt("location_id");

                        /*
                         * UPDATE EXISTING
                         */

                        try(PreparedStatement update =
                                    con.prepareStatement(updateSql)){

                            update.setInt(1, newLocationId);
                            update.setString(2, user);
                            update.setInt(3, assetId);

                            update.executeUpdate();
                        }

                    }else{

                        /*
                         * INSERT NEW
                         */

                        try(PreparedStatement insert =
                                    con.prepareStatement(insertSql)){

                            insert.setInt(1, assetId);
                            insert.setInt(2, newLocationId);
                            insert.setString(3, user);

                            insert.executeUpdate();
                        }
                    }
                }
            }

            /*
             * INSERT HISTORY
             */

            try(PreparedStatement hist =
                        con.prepareStatement(historySql)){

                hist.setInt(1, assetId);

                if(oldLocationId == 0){

                    hist.setNull(2, Types.INTEGER);

                }else{

                    hist.setInt(2, oldLocationId);
                }

                hist.setInt(3, newLocationId);

                hist.setString(4, user);

                hist.executeUpdate();
            }

            con.commit();

            status = true;

        }catch(Exception e){

            e.printStackTrace();
        }

        return status;
    }

    /* =========================
       ASSET HISTORY
       ========================= */

    public ArrayList<HashMap<String, Object>>
    getAssetHistory(int assetId) {

        ArrayList<HashMap<String, Object>> list =
                new ArrayList<>();

        String sql =
                "SELECT "
              + "fl.location_name AS from_location, "
              + "tl.location_name AS to_location, "
              + "h.moved_by, "
              + "DATE_FORMAT(h.moved_date, "
              + "'%d-%m-%Y %h:%i %p') "
              + "AS moved_datetime, "
              + "h.remarks "
              + "FROM asset_location_history h "
              + "LEFT JOIN locations fl "
              + "ON h.from_location_id = fl.location_id "
              + "LEFT JOIN locations tl "
              + "ON h.to_location_id = tl.location_id "
              + "WHERE h.asset_id=? "
              + "ORDER BY h.moved_date DESC";

        try(Connection con = getConnection();
            PreparedStatement ps =
                    con.prepareStatement(sql)){

            ps.setInt(1, assetId);

            try(ResultSet rs = ps.executeQuery()){

                while(rs.next()){

                    HashMap<String,Object> map =
                            new HashMap<>();

                    map.put(
                            "from_location",
                            rs.getString("from_location"));

                    map.put(
                            "to_location",
                            rs.getString("to_location"));

                    map.put(
                            "moved_by",
                            rs.getString("moved_by"));

                    map.put(
                            "moved_datetime",
                            rs.getString("moved_datetime"));

                    map.put(
                            "remarks",
                            rs.getString("remarks"));

                    list.add(map);
                }
            }

        }catch(Exception e){
            e.printStackTrace();
        }

        return list;
    }
}