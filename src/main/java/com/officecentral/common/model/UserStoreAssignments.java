package com.officecentral.common.model;

import java.util.LinkedHashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

public class UserStoreAssignments {
    private final int userId;
    private final String username;
    private final String role;
    private final String department;
    private final Set<String> storeCodes = new LinkedHashSet<>();

    public UserStoreAssignments(int userId, String username, String role, String department) {
        this.userId = userId;
        this.username = username;
        this.role = role;
        this.department = department;
    }

    public int getUserId() { return userId; }
    public String getUsername() { return username; }
    public String getRole() { return role; }
    public String getDepartment() { return department; }
    public Set<String> getStoreCodes() { return storeCodes; }
    public Map<String, Boolean> getStoreCodeFlags() {
        Map<String, Boolean> flags = new LinkedHashMap<>();
        for (String code : storeCodes) flags.put(code, Boolean.TRUE);
        return flags;
    }
}
