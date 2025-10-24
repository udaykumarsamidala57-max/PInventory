package com.bean;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil {

    private static final String HOST = System.getenv("MYSQLHOST");
    private static final String PORT = System.getenv("MYSQLPORT");
    private static final String DB = System.getenv("MYSQLDATABASE");
    private static final String USER = System.getenv("MYSQLUSER");
    private static final String PASSWORD = System.getenv("MYSQLPASSWORD");

    private static final String URL = "jdbc:mysql://" + HOST + ":" + PORT + "/" + DB
            + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            System.out.println("✅ MySQL Driver Loaded Successfully!");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        System.out.println("🔗 Connecting to DB: " + URL);
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
