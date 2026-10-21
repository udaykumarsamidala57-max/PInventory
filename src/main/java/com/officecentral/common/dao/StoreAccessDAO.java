package com.officecentral.common.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import com.officecentral.common.db.InventoryDB;

/** Loads the store database assignments for a signed-in user. */
public final class StoreAccessDAO {

    public List<String> findAllowedStores(int userId, String assignedBranch) throws SQLException {
        List<String> allowed = new ArrayList<>();
        String sql = "SELECT database_code FROM user_database_access "
                + "WHERE user_id = ? ORDER BY database_code";

        try (Connection connection = InventoryDB.getAuthConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            try (ResultSet rows = statement.executeQuery()) {
                while (rows.next()) {
                    try {
                        String canonical = InventoryDB.canonicalBranch(rows.getString("database_code"));
                        if (!allowed.contains(canonical)) allowed.add(canonical);
                    } catch (SQLException ignored) {
                        // Ignore stale assignment codes that are not in the application whitelist.
                    }
                }
            }
        } catch (SQLException accessTableUnavailable) {
            // The original users.branch remains available when the optional assignment table
            // has not yet been installed; in that case only that one store is selectable.
        }

        // Keep existing users working before assignments have been configured; their users.branch
        // value authorizes only their existing store.
        if (allowed.isEmpty() && assignedBranch != null) {
            try {
                allowed.add(InventoryDB.canonicalBranch(assignedBranch));
            } catch (SQLException ignored) {
                // No valid assigned store is available.
            }
        }
        return allowed;
    }
}
