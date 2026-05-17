package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.bean.DBUtil4;

public class CategoryDAO {

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // ADD CATEGORY
    public boolean addCategory(String categoryName,
                               String subcategoryName,
                               String description) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql = "INSERT INTO asset_categories "
                    + "(category_name, subcategory_name, description) "
                    + "VALUES (?,?,?)";

            ps = con.prepareStatement(sql);

            ps.setString(1, categoryName);
            ps.setString(2, subcategoryName);
            ps.setString(3, description);

            int row = ps.executeUpdate();

            if (row > 0) {
                status = true;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // UPDATE CATEGORY
    public boolean updateCategory(int categoryId,
                                  String categoryName,
                                  String subcategoryName,
                                  String description) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql = "UPDATE asset_categories "
                    + "SET category_name=?, "
                    + "subcategory_name=?, "
                    + "description=? "
                    + "WHERE category_id=?";

            ps = con.prepareStatement(sql);

            ps.setString(1, categoryName);
            ps.setString(2, subcategoryName);
            ps.setString(3, description);
            ps.setInt(4, categoryId);

            int row = ps.executeUpdate();

            if (row > 0) {
                status = true;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // DELETE CATEGORY
    public boolean deleteCategory(int categoryId) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql = "DELETE FROM asset_categories "
                    + "WHERE category_id=?";

            ps = con.prepareStatement(sql);

            ps.setInt(1, categoryId);

            int row = ps.executeUpdate();

            if (row > 0) {
                status = true;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return status;
    }
}