package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.bean.DBUtil4;

public class LocationDAO {

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // INSERT LOCATION

    public boolean addLocation(
            String locationName,
            String building,
            String floorName,
            String roomNumber,
            String description) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql =
                "INSERT INTO locations "
              + "(location_name,building,"
              + "floor_name,room_number,description) "
              + "VALUES(?,?,?,?,?)";

            ps = con.prepareStatement(sql);

            ps.setString(1, locationName);
            ps.setString(2, building);
            ps.setString(3, floorName);
            ps.setString(4, roomNumber);
            ps.setString(5, description);

            int rows = ps.executeUpdate();

            if(rows > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // VIEW ALL LOCATIONS

    public ResultSet getLocations() {

        try {

            con = DBUtil4.getConnection();

            String sql =
            	    "SELECT * FROM locations "
            	  + "ORDER BY building ASC, "
            	  + "floor_name ASC, "
            	  + "room_number ASC";

            ps = con.prepareStatement(sql);

            rs = ps.executeQuery();

        } catch(Exception e) {
            e.printStackTrace();
        }

        return rs;
    }

    // GET SINGLE LOCATION

    public ResultSet getLocationById(int locationId) {

        try {

            con = DBUtil4.getConnection();

            String sql =
                "SELECT * FROM locations "
              + "WHERE location_id=?";

            ps = con.prepareStatement(sql);

            ps.setInt(1, locationId);

            rs = ps.executeQuery();

        } catch(Exception e) {
            e.printStackTrace();
        }

        return rs;
    }

    // UPDATE LOCATION

    public boolean updateLocation(
            int locationId,
            String locationName,
            String building,
            String floorName,
            String roomNumber,
            String description) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql =
                "UPDATE locations SET "
              + "location_name=?,"
              + "building=?,"
              + "floor_name=?,"
              + "room_number=?,"
              + "description=? "
              + "WHERE location_id=?";

            ps = con.prepareStatement(sql);

            ps.setString(1, locationName);
            ps.setString(2, building);
            ps.setString(3, floorName);
            ps.setString(4, roomNumber);
            ps.setString(5, description);
            ps.setInt(6, locationId);

            int rows = ps.executeUpdate();

            if(rows > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // DELETE LOCATION

    public boolean deleteLocation(int locationId) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql =
                "DELETE FROM locations "
              + "WHERE location_id=?";

            ps = con.prepareStatement(sql);

            ps.setInt(1, locationId);

            int rows = ps.executeUpdate();

            if(rows > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }
}