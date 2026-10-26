-- Android app access by role + department (created automatically on first use; kept here for reference).
-- Run against the login database (the one with the users table).
CREATE TABLE IF NOT EXISTS mobile_app_access (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role VARCHAR(50) NOT NULL,          -- '*' = all roles
    department VARCHAR(100) NOT NULL,   -- '*' = all departments
    feature VARCHAR(40) NOT NULL,       -- app.login, indent.view, indent.create, indent.approve,
                                        -- stock.view, service.view, service.create, service.update
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    updated_by VARCHAR(100) NULL,
    updated_on DATETIME NULL,
    UNIQUE KEY uq_mobile_access (role, department, feature)
);
