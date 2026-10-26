-- =====================================================================================
-- Item Cost master  (Office Central – Inventory)
-- Run on EACH store database:  inventory, SANPOLY_INVENTORY, SANPOLY_INVENTORY2, SRS_HOSTEL
-- Take a backup first (mysqldump). Only NEW tables are created; nothing existing is changed.
-- Safe to run again: every statement uses CREATE TABLE IF NOT EXISTS (no ALTER statements).
--
--   1. item_cost         : the current cost of one unit of each item, INCLUDING GST
--                          - cost_source 'PO'     : taken automatically from the latest APPROVED Purchase Order
--                          - cost_source 'MANUAL' : entered by Finance / Global when no approved PO exists
--   2. item_cost_history : every change (old cost -> new cost, who, when, why) for audit
-- =====================================================================================

-- ======================== SRS (inventory) ========================
USE inventory;

CREATE TABLE IF NOT EXISTS item_cost (
    item_id       INT            NOT NULL,
    unit_cost     DECIMAL(12,2)  NOT NULL,                 -- per unit, including GST
    cost_source   ENUM('PO','MANUAL') NOT NULL,
    po_item_id    INT            DEFAULT NULL,             -- PO: the po_items row the cost was taken from
    po_number     VARCHAR(50)    DEFAULT NULL,
    po_date       VARCHAR(50)    DEFAULT NULL,
    gst_percent   DECIMAL(10,2)  DEFAULT NULL,
    rate_basis    VARCHAR(20)    DEFAULT NULL,             -- MANUAL: BILL, LAST_PURCHASE, MARKET, COMMITTEE, DONATION
    reference     VARCHAR(255)   DEFAULT NULL,             -- MANUAL: bill number / approval note
    updated_by    VARCHAR(100)   NOT NULL,
    updated_at    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (item_id),
    CONSTRAINT fk_item_cost_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id),
    CONSTRAINT chk_item_cost_nonneg CHECK (unit_cost >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS item_cost_history (
    history_id    INT            NOT NULL AUTO_INCREMENT,
    item_id       INT            NOT NULL,
    old_cost      DECIMAL(12,2)  DEFAULT NULL,             -- NULL = first cost for the item
    new_cost      DECIMAL(12,2)  NOT NULL,
    cost_source   ENUM('PO','MANUAL') NOT NULL,
    po_number     VARCHAR(50)    DEFAULT NULL,
    rate_basis    VARCHAR(20)    DEFAULT NULL,
    reference     VARCHAR(255)   DEFAULT NULL,
    changed_by    VARCHAR(100)   NOT NULL,
    changed_at    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (history_id),
    KEY idx_item_cost_history_item (item_id, changed_at),
    CONSTRAINT fk_item_cost_history_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ======================== SANPOLY BOYS ========================
USE SANPOLY_INVENTORY;

CREATE TABLE IF NOT EXISTS item_cost (
    item_id INT NOT NULL, unit_cost DECIMAL(12,2) NOT NULL, cost_source ENUM('PO','MANUAL') NOT NULL,
    po_item_id INT DEFAULT NULL, po_number VARCHAR(50) DEFAULT NULL, po_date VARCHAR(50) DEFAULT NULL,
    gst_percent DECIMAL(10,2) DEFAULT NULL, rate_basis VARCHAR(20) DEFAULT NULL, reference VARCHAR(255) DEFAULT NULL,
    updated_by VARCHAR(100) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (item_id),
    CONSTRAINT fk_item_cost_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id),
    CONSTRAINT chk_item_cost_nonneg CHECK (unit_cost >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS item_cost_history (
    history_id INT NOT NULL AUTO_INCREMENT, item_id INT NOT NULL,
    old_cost DECIMAL(12,2) DEFAULT NULL, new_cost DECIMAL(12,2) NOT NULL, cost_source ENUM('PO','MANUAL') NOT NULL,
    po_number VARCHAR(50) DEFAULT NULL, rate_basis VARCHAR(20) DEFAULT NULL, reference VARCHAR(255) DEFAULT NULL,
    changed_by VARCHAR(100) NOT NULL, changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (history_id),
    KEY idx_item_cost_history_item (item_id, changed_at),
    CONSTRAINT fk_item_cost_history_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ======================== SANPOLY GIRLS ========================
USE SANPOLY_INVENTORY2;

CREATE TABLE IF NOT EXISTS item_cost (
    item_id INT NOT NULL, unit_cost DECIMAL(12,2) NOT NULL, cost_source ENUM('PO','MANUAL') NOT NULL,
    po_item_id INT DEFAULT NULL, po_number VARCHAR(50) DEFAULT NULL, po_date VARCHAR(50) DEFAULT NULL,
    gst_percent DECIMAL(10,2) DEFAULT NULL, rate_basis VARCHAR(20) DEFAULT NULL, reference VARCHAR(255) DEFAULT NULL,
    updated_by VARCHAR(100) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (item_id),
    CONSTRAINT fk_item_cost_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id),
    CONSTRAINT chk_item_cost_nonneg CHECK (unit_cost >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS item_cost_history (
    history_id INT NOT NULL AUTO_INCREMENT, item_id INT NOT NULL,
    old_cost DECIMAL(12,2) DEFAULT NULL, new_cost DECIMAL(12,2) NOT NULL, cost_source ENUM('PO','MANUAL') NOT NULL,
    po_number VARCHAR(50) DEFAULT NULL, rate_basis VARCHAR(20) DEFAULT NULL, reference VARCHAR(255) DEFAULT NULL,
    changed_by VARCHAR(100) NOT NULL, changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (history_id),
    KEY idx_item_cost_history_item (item_id, changed_at),
    CONSTRAINT fk_item_cost_history_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ======================== SRS HOSTEL ========================
USE SRS_HOSTEL;

CREATE TABLE IF NOT EXISTS item_cost (
    item_id INT NOT NULL, unit_cost DECIMAL(12,2) NOT NULL, cost_source ENUM('PO','MANUAL') NOT NULL,
    po_item_id INT DEFAULT NULL, po_number VARCHAR(50) DEFAULT NULL, po_date VARCHAR(50) DEFAULT NULL,
    gst_percent DECIMAL(10,2) DEFAULT NULL, rate_basis VARCHAR(20) DEFAULT NULL, reference VARCHAR(255) DEFAULT NULL,
    updated_by VARCHAR(100) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (item_id),
    CONSTRAINT fk_item_cost_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id),
    CONSTRAINT chk_item_cost_nonneg CHECK (unit_cost >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS item_cost_history (
    history_id INT NOT NULL AUTO_INCREMENT, item_id INT NOT NULL,
    old_cost DECIMAL(12,2) DEFAULT NULL, new_cost DECIMAL(12,2) NOT NULL, cost_source ENUM('PO','MANUAL') NOT NULL,
    po_number VARCHAR(50) DEFAULT NULL, rate_basis VARCHAR(20) DEFAULT NULL, reference VARCHAR(255) DEFAULT NULL,
    changed_by VARCHAR(100) NOT NULL, changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (history_id),
    KEY idx_item_cost_history_item (item_id, changed_at),
    CONSTRAINT fk_item_cost_history_item FOREIGN KEY (item_id) REFERENCES item_master (Item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ======================== CHECK ========================
-- Expect 16 rows: for each of the 4 databases, item_cost and item_cost_history each have
-- a PRIMARY KEY and a FOREIGN KEY.
SELECT TABLE_SCHEMA, TABLE_NAME, CONSTRAINT_TYPE, CONSTRAINT_NAME
  FROM information_schema.TABLE_CONSTRAINTS
 WHERE TABLE_SCHEMA IN ('inventory','SANPOLY_INVENTORY','SANPOLY_INVENTORY2','SRS_HOSTEL')
   AND TABLE_NAME IN ('item_cost','item_cost_history')
   AND CONSTRAINT_TYPE IN ('PRIMARY KEY','FOREIGN KEY')
 ORDER BY TABLE_SCHEMA, TABLE_NAME, CONSTRAINT_TYPE;

-- Then open  Settings Master -> Item Cost  once in each store: costs from approved POs are filled in automatically.
-- After that, every PO approval updates the Item Cost master by itself.
