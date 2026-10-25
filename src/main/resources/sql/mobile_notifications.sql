-- Apply once to the authentication database (inventory). Push registrations and
-- notification inbox rows are shared across store databases and apps.
USE `inventory`;

CREATE TABLE IF NOT EXISTS `mobile_push_devices` (
    `fcm_token` VARCHAR(2048) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    `user_id` INT NOT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`fcm_token`),
    KEY `idx_mobile_push_user` (`user_id`),
    CONSTRAINT `fk_mobile_push_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mobile_notifications` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `event_id` CHAR(36) NOT NULL,
    `user_id` INT NOT NULL,
    `event_type` VARCHAR(60) NOT NULL,
    `title` VARCHAR(160) NOT NULL,
    `message` VARCHAR(500) NOT NULL,
    `entity_type` VARCHAR(40) NOT NULL,
    `entity_id` VARCHAR(100) NOT NULL,
    `store_code` VARCHAR(60) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `read_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_mobile_notification_event_user` (`event_id`, `user_id`),
    KEY `idx_mobile_notification_user_time` (`user_id`, `id`),
    CONSTRAINT `fk_mobile_notification_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
