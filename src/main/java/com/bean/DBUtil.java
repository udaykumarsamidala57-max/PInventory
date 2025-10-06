package com.bean;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil {

	private static final String URL = "jdbc:mysql://shuttle.proxy.rlw.y.net:26985/inventory";
	private static final String USER = "root";
	private static final String PASSWORD = "AUJrxXyvLxTXfsPDXMnFTTgpLcOaewkO";

    

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