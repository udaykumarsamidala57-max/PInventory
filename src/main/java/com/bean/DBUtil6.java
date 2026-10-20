package com.bean;

import java.sql.Connection;
import java.sql.SQLException;

/** Employee database. Server, user and password come from the settings (see AppConfig), not from the code. */
public class DBUtil6 {

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        return AppConfig.connect("MYSQL", "employee");
    }
}
