package com.bean;

import java.sql.Connection;
import java.sql.SQLException;

/** Fixed assets database. Server, user and password come from the settings (see AppConfig), not from the code. */
public class DBUtil4 {

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        return AppConfig.connect("MYSQL", "fixed_asset_management");
    }
}
