-- Events master (inventory database, one per store/branch)
-- The Events page (EventsServlet) also creates this table automatically if it is missing.

CREATE TABLE IF NOT EXISTS `events` (
  `event_id`    int NOT NULL AUTO_INCREMENT,
  `event_name`  varchar(150) NOT NULL,
  `event_date`  date DEFAULT NULL,
  `description` varchar(500) DEFAULT NULL,
  `status`      enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `created_by`  varchar(50) DEFAULT NULL,
  `created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`event_id`),
  UNIQUE KEY `uq_events_name` (`event_name`),
  KEY `idx_events_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
