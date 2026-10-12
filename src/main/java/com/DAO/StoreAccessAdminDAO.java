package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.bean.DBUtil;
import com.bean.UserStoreAssignments;

/** Reads and updates per-user store assignments. */
public final class StoreAccessAdminDAO {

    public List<UserStoreAssignments> findAllUsers() throws SQLException {
        String sql = "SELECT u.id, u.username, u.role, u.department, a.database_code "
                + "FROM users u LEFT JOIN user_database_access a ON a.user_id = u.id "
                + "ORDER BY u.username, a.database_code";
        Map<Integer, UserStoreAssignments> users = new LinkedHashMap<>();

        try (Connection connection = DBUtil.getAuthConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rows = statement.executeQuery()) {
            while (rows.next()) {
                int id = rows.getInt("id");
                UserStoreAssignments user = users.get(id);
                if (user == null) {
                    user = new UserStoreAssignments(id, rows.getString("username"),
                            rows.getString("role"), rows.getString("department"));
                    users.put(id, user);
                }
                String code = rows.getString("database_code");
                if (code != null) {
                    try {
                        user.getStoreCodes().add(DBUtil.canonicalBranch(code));
                    } catch (SQLException ignored) {
                        // Display only known, selectable store codes.
                    }
                }
            }
        }
        return new ArrayList<>(users.values());
    }

    public void replaceAssignments(int userId, List<String> storeCodes) throws SQLException {
        String userSql = "SELECT id FROM users WHERE id = ? FOR UPDATE";
        String deleteSql = "DELETE FROM user_database_access WHERE user_id = ?";
        String insertSql = "INSERT INTO user_database_access (user_id, database_code) VALUES (?, ?)";

        try (Connection connection = DBUtil.getAuthConnection()) {
            connection.setAutoCommit(false);
            try {
                try (PreparedStatement verify = connection.prepareStatement(userSql)) {
                    verify.setInt(1, userId);
                    try (ResultSet row = verify.executeQuery()) {
                        if (!row.next()) throw new SQLException("The selected user no longer exists.");
                    }
                }

                try (PreparedStatement delete = connection.prepareStatement(deleteSql)) {
                    delete.setInt(1, userId);
                    delete.executeUpdate();
                }

                try (PreparedStatement insert = connection.prepareStatement(insertSql)) {
                    for (String storeCode : storeCodes) {
                        insert.setInt(1, userId);
                        insert.setString(2, storeCode);
                        insert.addBatch();
                    }
                    if (!storeCodes.isEmpty()) insert.executeBatch();
                }
                connection.commit();
            } catch (SQLException | RuntimeException ex) {
                try {
                    connection.rollback();
                } catch (SQLException rollbackError) {
                    ex.addSuppressed(rollbackError);
                }
                throw ex;
            }
        }
    }
}
