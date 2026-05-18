package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.bean.DBUtil4;

public class CategoryDAO {

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // ================= ADD CATEGORY =================

    public boolean addCategory(String categoryName,
                               String description) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "INSERT INTO asset_categories "
                    + "(category_name,description) "
                    + "VALUES(?,?)";

            ps = con.prepareStatement(sql);

            ps.setString(1, categoryName);
            ps.setString(2, description);

            int row = ps.executeUpdate();

            if(row > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // ================= UPDATE CATEGORY =================

    public boolean updateCategory(int categoryId,
                                  String categoryName,
                                  String description) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "UPDATE asset_categories "
                    + "SET category_name=?, "
                    + "description=? "
                    + "WHERE category_id=?";

            ps = con.prepareStatement(sql);

            ps.setString(1, categoryName);
            ps.setString(2, description);
            ps.setInt(3, categoryId);

            int row = ps.executeUpdate();

            if(row > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // ================= DELETE CATEGORY =================

    public boolean deleteCategory(int categoryId) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String subSql =
                    "DELETE FROM asset_subcategories "
                    + "WHERE category_id=?";

            ps = con.prepareStatement(subSql);

            ps.setInt(1, categoryId);

            ps.executeUpdate();

            String sql =
                    "DELETE FROM asset_categories "
                    + "WHERE category_id=?";

            ps = con.prepareStatement(sql);

            ps.setInt(1, categoryId);

            int row = ps.executeUpdate();

            if(row > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // ================= ADD SUBCATEGORY =================

    public boolean addSubcategory(int categoryId,
                                  String subcategoryName,
                                  String description) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "INSERT INTO asset_subcategories "
                    + "(category_id,subcategory_name,description) "
                    + "VALUES(?,?,?)";

            ps = con.prepareStatement(sql);

            ps.setInt(1, categoryId);
            ps.setString(2, subcategoryName);
            ps.setString(3, description);

            int row = ps.executeUpdate();

            if(row > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // ================= UPDATE SUBCATEGORY =================

    public boolean updateSubcategory(int subcategoryId,
                                     String subcategoryName,
                                     String description) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "UPDATE asset_subcategories "
                    + "SET subcategory_name=?, "
                    + "description=? "
                    + "WHERE subcategory_id=?";

            ps = con.prepareStatement(sql);

            ps.setString(1, subcategoryName);
            ps.setString(2, description);
            ps.setInt(3, subcategoryId);

            int row = ps.executeUpdate();

            if(row > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // ================= DELETE SUBCATEGORY =================

    public boolean deleteSubcategory(int subcategoryId) {

        boolean status = false;

        try {

            con = DBUtil4.getConnection();

            String sql =
                    "DELETE FROM asset_subcategories "
                    + "WHERE subcategory_id=?";

            ps = con.prepareStatement(sql);

            ps.setInt(1, subcategoryId);

            int row = ps.executeUpdate();

            if(row > 0) {
                status = true;
            }

        } catch(Exception e) {
            e.printStackTrace();
        }

        return status;
    }
}