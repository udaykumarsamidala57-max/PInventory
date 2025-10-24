package com.bean;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil {

    private static Connection connection = null;

    public static Connection getConnection() throws SQLException {
        if (connection == null || connection.isClosed()) {
            String host = System.getenv("RAILWAY_PRIVATE_DOMAIN");
            if (host == null || host.isEmpty()) host = System.getenv("MYSQLHOST");

            String port = System.getenv("MYSQLPORT");
            String dbName = System.getenv("MYSQLDATABASE");
            String user = System.getenv("MYSQLUSER");
            String pass = System.getenv("MYSQLPASSWORD");

            String url = "jdbc:mysql://" + host + ":" + port + "/" + dbName +
                         "?useSSL=false&allowPublicKeyRetrieval=true";

            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
            } catch (ClassNotFoundException e) {
                throw new SQLException("MySQL Driver not found: " + e.getMessage(), e);
            }

            System.out.println("🔗 Connecting to: " + url);
            connection = DriverManager.getConnection(url, user, pass);
            System.out.println("✅ Connected successfully!");
        }
        return connection;
    }
}
