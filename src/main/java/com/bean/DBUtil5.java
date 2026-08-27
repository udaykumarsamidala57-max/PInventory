package com.bean;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil5 {

    private static final String USER = "root";
    private static final String PASSWORD = "vSZVibKCzvcovcGjaLlxrTddrjiNPVQn";

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    public static Connection getConnection(String branch) throws SQLException {

        String url;

        if ("SRS".equalsIgnoreCase(branch)) {

            url = "jdbc:mysql://shuttle.proxy.rlwy.net:26985/Service_request"
                    + "?useSSL=false"
                    + "&allowPublicKeyRetrieval=true"
                    + "&serverTimezone=UTC"
                    + "&tcpKeepAlive=true";

        } else if ("Sanpoly".equalsIgnoreCase(branch)) {

            url = "jdbc:mysql://shuttle.proxy.rlwy.net:26985/Sanploy_Service"
                    + "?useSSL=false"
                    + "&allowPublicKeyRetrieval=true"
                    + "&serverTimezone=UTC"
                    + "&tcpKeepAlive=true";

        } else {
            throw new SQLException("Invalid Branch: " + branch);
        }

        return DriverManager.getConnection(url, USER, PASSWORD);
    }
}