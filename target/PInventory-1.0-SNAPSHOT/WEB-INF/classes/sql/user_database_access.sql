-- Run against the SRS inventory database, which contains the users table.
-- The store-code to database-name whitelist is in DBUtil, as in OFFICE_CENTRAL_ERP.
CREATE TABLE IF NOT EXISTS user_database_access (
    user_id INT NOT NULL,
    database_code VARCHAR(50) NOT NULL,
    PRIMARY KEY (user_id, database_code),
    CONSTRAINT fk_user_database_access_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
);

-- Remove the optional routing-table constraint from the earlier PInventory implementation,
-- if that version of the table was already created.
SET @has_store_assignment_fk = (
    SELECT COUNT(*)
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE()
      AND table_name = 'user_database_access'
      AND constraint_name = 'fk_user_database_access_store'
      AND constraint_type = 'FOREIGN KEY'
);
SET @drop_store_assignment_fk = IF(
    @has_store_assignment_fk > 0,
    'ALTER TABLE user_database_access DROP FOREIGN KEY fk_user_database_access_store',
    'SELECT 1'
);
PREPARE drop_store_assignment_fk_stmt FROM @drop_store_assignment_fk;
EXECUTE drop_store_assignment_fk_stmt;
DEALLOCATE PREPARE drop_store_assignment_fk_stmt;

-- Authorized store codes, matching DBUtil's supported codes:
-- SRS, SANPOLY BOYS, SANPOLY GIRLS, SRS_HOSTEL, Sanpoly, Sanpoly2.
-- Example assignments:
-- INSERT INTO user_database_access (user_id, database_code) VALUES (1, 'SANPOLY BOYS');
-- INSERT INTO user_database_access (user_id, database_code) VALUES (1, 'SANPOLY GIRLS');
-- INSERT INTO user_database_access (user_id, database_code) VALUES (1, 'SRS');
-- INSERT INTO user_database_access (user_id, database_code) VALUES (1, 'SRS_HOSTEL');
-- INSERT INTO user_database_access (user_id, database_code) VALUES (37, 'Sanpoly');
-- INSERT INTO user_database_access (user_id, database_code) VALUES (37, 'Sanpoly2');
