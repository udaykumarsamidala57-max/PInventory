package com.bean;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil {

	private static final String URL = "mysql://root:vSZVibKCzvcovcGjaLlxrTddrjiNPVQn@mysql.railway.internal:3306/inventory";
	private static final String USER = "root";
	private static final String PASSWORD = "vSZVibKCzvcovcGjaLlxrTddrjiNPVQn";
    

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}