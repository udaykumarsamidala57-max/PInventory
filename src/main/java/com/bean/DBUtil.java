package com.bean;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

public class DBUtil {

    private static final String HOST = "shuttle.proxy.rlwy.net";
    private static final String PORT = "26985";
    private static final String USER = "root";
    private static final String PASSWORD = "vSZVibKCzvcovcGjaLlxrTddrjiNPVQn";

    // Store-code whitelist follows OFFICE_CENTRAL_ERP; user access is loaded from SQL.
    private static final Map<String, String> DATABASES = Map.of(
            "SRS", "inventory",
            "SANPOLY BOYS", "SANPOLY_INVENTORY",
            "SANPOLY GIRLS", "SANPOLY_INVENTORY2",
            "SRS_HOSTEL", "SRS_HOSTEL",
            // Existing PInventory assignment codes are aliases for the ERP store labels above.
            "Sanpoly", "SANPOLY_INVENTORY",
            "Sanpoly2", "SANPOLY_INVENTORY2");

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ExceptionInInitializerError(e);
        }
    }

    public static Connection getConnection(String storeCode) throws SQLException {
        String canonical = canonicalBranch(storeCode);
        String database = DATABASES.get(canonical);
        String url = "jdbc:mysql://" + HOST + ":" + PORT + "/" + database
                + "?useSSL=false&allowPublicKeyRetrieval=true"
                + "&serverTimezone=UTC&tcpKeepAlive=true";
        return DriverManager.getConnection(url, USER, PASSWORD);
    }

    /** Uses the fixed SRS inventory database for authentication and user access assignments. */
    public static Connection getAuthConnection() throws SQLException {
        return getConnection("SRS");
    }

    public static List<String> getSupportedBranches() {
        return List.copyOf(DATABASES.keySet());
    }

    public static String canonicalBranch(String storeCode) throws SQLException {
        if (storeCode != null) {
            for (String supported : DATABASES.keySet()) {
                if (supported.equalsIgnoreCase(storeCode.trim())) return supported;
            }
        }
        throw new SQLException("Unsupported store selection.");
    }
}
