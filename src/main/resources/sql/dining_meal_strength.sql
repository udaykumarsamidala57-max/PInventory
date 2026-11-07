-- =====================================================================================
-- Dining Hall: strength per session and meal cost per head.
-- PART A: run on EVERY branch inventory database that has Dining Hall consumption
--         (the database that has the table dining_hall_consumption). Safe to run again.
-- =====================================================================================

-- Strength of one session on one day (shared by all issues of that date + session)
CREATE TABLE IF NOT EXISTS dining_meal_strength (
  id                     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  meal_date              DATE          NOT NULL,
  session                VARCHAR(50)   NOT NULL,
  boarding_students      INT UNSIGNED  NOT NULL DEFAULT 0,
  day_boarding_students  INT UNSIGNED  NOT NULL DEFAULT 0,
  day_scholars           INT UNSIGNED  NOT NULL DEFAULT 0,
  staff                  INT UNSIGNED  NOT NULL DEFAULT 0,
  total_strength         INT UNSIGNED  AS (boarding_students + day_boarding_students + day_scholars + staff) STORED,
  created_by             VARCHAR(100)  NOT NULL,
  created_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by             VARCHAR(100)  NOT NULL,
  updated_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_dining_strength_day_session (meal_date, session),
  CONSTRAINT chk_dining_strength_limits CHECK (boarding_students <= 100000 AND day_boarding_students <= 100000
                                               AND day_scholars <= 100000 AND staff <= 100000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Every change of a strength (audit trail)
CREATE TABLE IF NOT EXISTS dining_meal_strength_log (
  id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  strength_id        INT UNSIGNED    NULL,
  meal_date          DATE            NOT NULL,
  session            VARCHAR(50)     NOT NULL,
  old_boarding       INT UNSIGNED    NULL,
  old_day_boarding   INT UNSIGNED    NULL,
  old_day_scholars   INT UNSIGNED    NULL,
  old_staff          INT UNSIGNED    NULL,
  new_boarding       INT UNSIGNED    NOT NULL,
  new_day_boarding   INT UNSIGNED    NOT NULL,
  new_day_scholars   INT UNSIGNED    NOT NULL,
  new_staff          INT UNSIGNED    NOT NULL,
  changed_by         VARCHAR(100)    NOT NULL,
  changed_at         TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_dining_strength_log_day (meal_date, session)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Speeds up the meal cost report (skip if this index already exists)
-- CREATE INDEX idx_dhc_date_session ON dining_hall_consumption (issue_date, session);


-- =====================================================================================
-- PART B: run ONCE on the `inventory` database (UAMS), only if Access Management (UAMS) is in use.
-- Adds the page "Meal Cost per Head" with the same permissions as the Dining Dashboard.
-- =====================================================================================
USE inventory;

INSERT IGNORE INTO access_permission (perm_key, app, module, kind, parent_key, label, description, paths, sort_order, defaults_applied)
SELECT 'din.meal-cost', p.app, p.module, 'PAGE', NULL, 'Meal Cost per Head',
       'Strength and meal cost per head, session-wise and day-wise.', '/meal-cost', p.sort_order + 1, 0
FROM access_permission p WHERE p.perm_key = 'din.dashboard';

INSERT IGNORE INTO access_grant (perm_key, subject_type, subject, effect, granted_by)
SELECT 'din.meal-cost', g.subject_type, g.subject, g.effect, 'uams-default'
FROM access_grant g
JOIN access_permission a ON a.perm_key = 'din.meal-cost' AND a.defaults_applied = 0
WHERE g.perm_key = 'din.dashboard';

UPDATE access_permission SET defaults_applied = 1 WHERE perm_key = 'din.meal-cost';

-- Check
SELECT a.perm_key, a.label, a.paths, COUNT(g.perm_key) AS permissions
FROM access_permission a LEFT JOIN access_grant g ON g.perm_key = a.perm_key
WHERE a.perm_key IN ('din.dashboard', 'din.meal-cost')
GROUP BY a.perm_key, a.label, a.paths;
