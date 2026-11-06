-- =====================================================================================
-- Unified Access Management System (UAMS) - phase 1
-- Run in MySQL Workbench against the `inventory` database (the one that holds `users`).
--
-- Safe to run again. It only ADDS tables, columns and catalogue rows; it never deletes or
-- changes existing access rules, users or passwords. Access keeps working exactly as today
-- until a Global user switches PInventory to UAMS roles on the UAMS > Migration tab.
--
-- Run access_control.sql first if it has not been run on this server (it creates the
-- page catalogue). This script then adds:
--   * users.employee_id / users.employee_name
--   * access_role, access_user_role (+ audit)   - several roles per user
--   * PROJECT and MODULE levels in access_permission, action_code on actions
--   * access_setting (UAMS on/off switch) and uams_audit (role / catalogue changes)
-- =====================================================================================
USE inventory;

-- ------------------------------------------------------------------ helpers (dropped at the end)
DROP PROCEDURE IF EXISTS uams_add_column;
DROP PROCEDURE IF EXISTS uams_add_index;
DELIMITER $$
CREATE PROCEDURE uams_add_column(IN t VARCHAR(64), IN c VARCHAR(64), IN ddl VARCHAR(500))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = t AND COLUMN_NAME = c) THEN
    SET @uams_sql = CONCAT('ALTER TABLE `', t, '` ADD COLUMN ', ddl);
    PREPARE uams_st FROM @uams_sql; EXECUTE uams_st; DEALLOCATE PREPARE uams_st;
  END IF;
END$$
CREATE PROCEDURE uams_add_index(IN t VARCHAR(64), IN i VARCHAR(64), IN ddl VARCHAR(500))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.STATISTICS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = t AND INDEX_NAME = i) THEN
    SET @uams_sql = CONCAT('ALTER TABLE `', t, '` ADD ', ddl);
    PREPARE uams_st FROM @uams_sql; EXECUTE uams_st; DEALLOCATE PREPARE uams_st;
  END IF;
END$$
DELIMITER ;

-- ------------------------------------------------------------------ 1. employee details on users
CALL uams_add_column('users', 'employee_id',   '`employee_id` VARCHAR(30) NULL AFTER `username`');
CALL uams_add_column('users', 'employee_name', '`employee_name` VARCHAR(120) NULL AFTER `employee_id`');
CALL uams_add_index('users', 'uk_users_employee_id', 'UNIQUE KEY `uk_users_employee_id` (`employee_id`)');

-- ------------------------------------------------------------------ 2. roles and user-role assignments
CREATE TABLE IF NOT EXISTS access_role (
  role_key   VARCHAR(80)  NOT NULL PRIMARY KEY,
  role_name  VARCHAR(100) NOT NULL,
  created_by VARCHAR(100) NULL,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CALL uams_add_column('access_role', 'description', '`description` VARCHAR(255) NULL AFTER `role_name`');
CALL uams_add_column('access_role', 'updated_at',
     '`updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP');

CREATE TABLE IF NOT EXISTS access_user_role (
  user_id     INT          NOT NULL,
  role_key    VARCHAR(80)  NOT NULL,
  is_primary  TINYINT(1)   NOT NULL DEFAULT 0,
  assigned_by VARCHAR(100) NULL,
  assigned_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, role_key),
  KEY idx_access_user_role_role (role_key),
  CONSTRAINT fk_access_user_role_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_access_user_role_role FOREIGN KEY (role_key) REFERENCES access_role (role_key) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS access_user_role_audit (
  id          BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id     INT          NOT NULL,
  username    VARCHAR(50)  NOT NULL,
  role_key    VARCHAR(80)  NOT NULL,
  change_type VARCHAR(10)  NOT NULL,
  changed_by  VARCHAR(100) NOT NULL,
  changed_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_access_user_role_audit_user (user_id, changed_at),
  KEY idx_access_user_role_audit_changed (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------ 3. settings and audit
CREATE TABLE IF NOT EXISTS access_setting (
  setting_key   VARCHAR(60)  NOT NULL PRIMARY KEY,
  setting_value VARCHAR(255) NOT NULL,
  updated_by    VARCHAR(100) NULL,
  updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- LEGACY = today's rules (role / department / user grants). ROLES = UAMS roles only.
INSERT IGNORE INTO access_setting (setting_key, setting_value, updated_by) VALUES ('uams.mode', 'LEGACY', 'uams.sql');

CREATE TABLE IF NOT EXISTS uams_audit (
  id          BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
  entity      VARCHAR(20)  NOT NULL,                 -- ROLE, CATALOGUE, USER, SETTING, MIGRATION
  entity_key  VARCHAR(80)  NOT NULL,
  change_type VARCHAR(20)  NOT NULL,
  detail      VARCHAR(500) NULL,
  changed_by  VARCHAR(100) NOT NULL,
  changed_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_uams_audit_changed (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------ 4. project / module / page / action levels
-- kind is now PROJECT, MODULE, PAGE or ACTION. A page belongs to the MODULE row with the same app + module text;
-- a module belongs to the PROJECT row of its app; an action belongs to its page (parent_key).
CALL uams_add_column('access_permission', 'action_code', '`action_code` VARCHAR(10) NULL AFTER `kind`');

INSERT IGNORE INTO access_permission (perm_key, app, module, kind, parent_key, label, description, paths, sort_order, defaults_applied)
VALUES ('proj.PINVENTORY', 'PINVENTORY', '', 'PROJECT', NULL, 'PInventory',
        'Inventory, purchase, stores, dining hall, service desk, assets and websites.', NULL, 1, 1),
       ('proj.SCHOOLOPS', 'SCHOOLOPS', '', 'PROJECT', NULL, 'School Operations',
        'Admissions, visitor management and student early release.', NULL, 2, 1),
       ('proj.PHRMS', 'PHRMS', '', 'PROJECT', NULL, 'HR Management',
        'Recruitment, onboarding, staff details and payroll.', NULL, 3, 1);

-- One MODULE row for every module that has pages (new modules added later by access_control.sql are picked up on re-run).
INSERT IGNORE INTO access_permission (perm_key, app, module, kind, parent_key, label, description, paths, sort_order, defaults_applied)
SELECT LEFT(CONCAT('mod.', p.app, '.', REGEXP_REPLACE(UPPER(TRIM(p.module)), '[^A-Z0-9]+', '_')), 80),
       p.app, p.module, 'MODULE', CONCAT('proj.', p.app), p.module, NULL, NULL, MIN(p.sort_order), 1
FROM access_permission p
WHERE p.kind IN ('PAGE', 'ACTION') AND TRIM(p.module) <> ''
GROUP BY p.app, p.module;

-- Standard action codes for the existing buttons whose meaning is clear (others stay as named custom options).
UPDATE access_permission SET action_code = 'APPROVE' WHERE kind = 'ACTION' AND action_code IS NULL AND perm_key LIKE '%.approve';
UPDATE access_permission SET action_code = 'DELETE'  WHERE kind = 'ACTION' AND action_code IS NULL AND perm_key LIKE '%.delete';
UPDATE access_permission SET action_code = 'EDIT'    WHERE kind = 'ACTION' AND action_code IS NULL AND perm_key LIKE '%.edit';
UPDATE access_permission SET action_code = 'ADD'     WHERE kind = 'ACTION' AND action_code IS NULL AND perm_key LIKE '%.upload';

-- ------------------------------------------------------------------ read access for the other projects
-- School Operations and HR (PHRMS) read UAMS with their own read-only MySQL user. Give that user SELECT on:
--   GRANT SELECT ON inventory.users             TO '<read_only_user>'@'%';
--   GRANT SELECT ON inventory.access_permission TO '<read_only_user>'@'%';
--   GRANT SELECT ON inventory.access_grant      TO '<read_only_user>'@'%';
--   GRANT SELECT ON inventory.access_role       TO '<read_only_user>'@'%';
--   GRANT SELECT ON inventory.access_user_role  TO '<read_only_user>'@'%';
--   GRANT SELECT ON inventory.access_setting    TO '<read_only_user>'@'%';
-- (Not needed when they connect with the same MySQL user as PInventory.)

-- ------------------------------------------------------------------ done
DROP PROCEDURE IF EXISTS uams_add_column;
DROP PROCEDURE IF EXISTS uams_add_index;

SELECT 'UAMS tables are ready. Open PInventory > UAMS (Global users) to review the migration.' AS result;
