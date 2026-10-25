-- =====================================================================================
-- Damage / Wastage entry  (Office Central – Inventory)
-- Run ONCE on EACH store database. All four have the same structure:
--     inventory, SANPOLY_INVENTORY, SANPOLY_INVENTORY2, SRS_HOSTEL
-- Take a backup first (mysqldump) and run it outside working hours.
--
-- What it does
--   1. stock_ledger.trans_type  : adds 'WASTAGE' to ENUM('RECEIPT','ISSUE')  (existing rows unchanged)
--   2. stock.total_wasted       : running total of wasted qty per item (balance = received - issued - wasted)
--   3. stock_wastage            : one row per damaged / expired / lost item entry
--   4. id_sequences 'wastage_no': numbering for WST/2026-27/0001 ...
-- =====================================================================================

-- ---------- repeat this block for each database ----------
USE inventory;

ALTER TABLE stock_ledger
    MODIFY trans_type ENUM('RECEIPT','ISSUE','WASTAGE') NOT NULL;

ALTER TABLE stock
    ADD COLUMN total_wasted DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER total_issued;

CREATE TABLE IF NOT EXISTS stock_wastage (
    wastage_id    INT           NOT NULL AUTO_INCREMENT,
    wastage_no    VARCHAR(30)   NOT NULL,                 -- WST/2026-27/0001 (one number per entry, may cover several items)
    item_id       INT           NOT NULL,
    wastage_date  DATE          NOT NULL,
    wastage_type  ENUM('DAMAGED','EXPIRED','SPOILED','BROKEN','LOST','OTHER') NOT NULL,
    qty           DECIMAL(10,2) NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL DEFAULT 0.00,    -- stock.last_price at the time of entry
    total_value   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    department    VARCHAR(45)   DEFAULT NULL,
    reason        VARCHAR(255)  NOT NULL,
    entered_by    VARCHAR(100)  NOT NULL,
    created_at    TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (wastage_id),
    KEY idx_wastage_no (wastage_no),
    KEY idx_wastage_date (wastage_date),
    KEY idx_wastage_item (item_id),
    CONSTRAINT fk_stock_wastage_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id),
    CONSTRAINT chk_stock_wastage_qty CHECK (qty > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO id_sequences (seq_name, next_val) VALUES ('wastage_no', 0)
    ON DUPLICATE KEY UPDATE next_val = next_val;

-- ---------- same again for the other stores ----------
USE SANPOLY_INVENTORY;
ALTER TABLE stock_ledger MODIFY trans_type ENUM('RECEIPT','ISSUE','WASTAGE') NOT NULL;
ALTER TABLE stock ADD COLUMN total_wasted DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER total_issued;
CREATE TABLE IF NOT EXISTS stock_wastage LIKE inventory.stock_wastage;
ALTER TABLE stock_wastage ADD CONSTRAINT fk_stock_wastage_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id);
INSERT INTO id_sequences (seq_name, next_val) VALUES ('wastage_no', 0) ON DUPLICATE KEY UPDATE next_val = next_val;

USE SANPOLY_INVENTORY2;
ALTER TABLE stock_ledger MODIFY trans_type ENUM('RECEIPT','ISSUE','WASTAGE') NOT NULL;
ALTER TABLE stock ADD COLUMN total_wasted DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER total_issued;
CREATE TABLE IF NOT EXISTS stock_wastage LIKE inventory.stock_wastage;
ALTER TABLE stock_wastage ADD CONSTRAINT fk_stock_wastage_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id);
INSERT INTO id_sequences (seq_name, next_val) VALUES ('wastage_no', 0) ON DUPLICATE KEY UPDATE next_val = next_val;

USE SRS_HOSTEL;
ALTER TABLE stock_ledger MODIFY trans_type ENUM('RECEIPT','ISSUE','WASTAGE') NOT NULL;
ALTER TABLE stock ADD COLUMN total_wasted DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER total_issued;
CREATE TABLE IF NOT EXISTS stock_wastage LIKE inventory.stock_wastage;
ALTER TABLE stock_wastage ADD CONSTRAINT fk_stock_wastage_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id);
INSERT INTO id_sequences (seq_name, next_val) VALUES ('wastage_no', 0) ON DUPLICATE KEY UPDATE next_val = next_val;

-- (CREATE TABLE ... LIKE does not copy foreign keys, so each store adds its own above.)

-- Check afterwards (each DB):
--   SHOW COLUMNS FROM stock_ledger LIKE 'trans_type';
--   SHOW COLUMNS FROM stock LIKE 'total_wasted';
--   SELECT * FROM id_sequences WHERE seq_name = 'wastage_no';
