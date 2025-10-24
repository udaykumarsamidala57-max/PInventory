package com.bean;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil {
    private static Connection connection = null;

    public static Connection getConnection() throws SQLException, ClassNotFoundException {
        if (connection == null || connection.isClosed()) {
            String host = System.getenv("RAILWAY_PRIVATE_DOMAIN"); // ✅ private domain
            if (host == null || host.isEmpty()) host = System.getenv("MYSQLHOST"); // fallback

            String port = System.getenv("MYSQLPORT");
            String dbName = System.getenv("MYSQLDATABASE");
            String user = System.getenv("MYSQLUSER");
            String pass = System.getenv("MYSQLPASSWORD");

            String url = "jdbc:mysql://" + host + ":" + port + "/" + dbName +
                         "?useSSL=false&allowPublicKeyRetrieval=true";

            Class.forName("com.mysql.cj.jdbc.Driver");
            System.out.println("🔗 Connecting to: " + url);
            connection = DriverManager.getConnection(url, user, pass);
            System.out.println("✅ Connected successfully!");
        }
        return connection;
    }
}
