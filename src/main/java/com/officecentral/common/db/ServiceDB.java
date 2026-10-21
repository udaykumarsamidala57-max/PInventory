package com.officecentral.common.db;

import com.officecentral.common.config.AppConfig;

import java.sql.Connection;
import java.sql.SQLException;

/** Service-request database per branch. Server, user and password come from the settings (see AppConfig). */
public class ServiceDB {

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    public static Connection getConnection(String branch) throws SQLException {
        if ("SRS".equalsIgnoreCase(branch))     return AppConfig.connect("MYSQL", "Service_request");
        if ("Sanpoly".equalsIgnoreCase(branch)) return AppConfig.connect("MYSQL", "Sanploy_Service");
        throw new SQLException("Invalid Branch: " + branch);
    }
}
