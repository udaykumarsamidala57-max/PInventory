-- =====================================================================================
-- UAMS: buttons (actions) of the new PHRMS Staff Management pages.
-- Run in MySQL Workbench against the `inventory` database AFTER access_control.sql and uams.sql.
--
-- Safe to run again. Each new button starts with exactly the permissions of its page today
-- (old rules and UAMS roles alike), so nobody gains or loses anything:
--   Staff Details      -> New staff / Excel import, Staff reports
--   Staff Attendance   -> Record manual attendance, Holidays / week offs / vacations
-- After that, change who may use each button in PInventory > Access Management (UAMS) > Roles & Permissions.
-- =====================================================================================
USE inventory;

DROP TEMPORARY TABLE IF EXISTS uams_new_action;
CREATE TEMPORARY TABLE uams_new_action (
  perm_key    VARCHAR(80)  NOT NULL PRIMARY KEY,
  parent_key  VARCHAR(80)  NOT NULL,
  action_code VARCHAR(10)  NULL,               -- one of the 8 standard actions, or NULL = named option
  label       VARCHAR(120) NOT NULL,
  description VARCHAR(255) NULL,
  sort_add    INT          NOT NULL
);

INSERT INTO uams_new_action VALUES
  ('phrms.staff.add',     'phrms.staff', 'ADD',    'New staff / Excel import',
   'Add existing employees one by one or import them from the Excel template.', 1),
  ('phrms.staff.reports', 'phrms.staff', 'EXPORT', 'Staff reports and Excel export',
   'Staff details (choose columns), age and experience reports, with Excel export.', 2),
  ('phrms.att.mark',      'phrms.att',   'EDIT',   'Record manual attendance',
   'Mark Morning / Evening attendance (Present / Absent) and correct it.', 1),
  ('phrms.att.setup',     'phrms.att',   NULL,     'Holidays, week offs and vacations',
   'Add or change branch holidays, department / individual week offs and vacations.', 2);

-- 1. Catalogue rows (module and order taken from the page). Existing rows are left as they are.
INSERT IGNORE INTO access_permission (perm_key, app, module, kind, action_code, parent_key, label, description, paths, sort_order, defaults_applied)
SELECT n.perm_key, p.app, p.module, 'ACTION', n.action_code, n.parent_key, n.label, n.description, NULL, p.sort_order + n.sort_add, 0
FROM uams_new_action n JOIN access_permission p ON p.perm_key = n.parent_key AND p.kind = 'PAGE';

-- 2. Starting permissions, only for rows added just now (defaults_applied = 0): copy the page's permissions.
INSERT IGNORE INTO access_grant (perm_key, subject_type, subject, effect, granted_by)
SELECT n.perm_key, g.subject_type, g.subject, g.effect, 'uams-default'
FROM uams_new_action n
JOIN access_permission a ON a.perm_key = n.perm_key AND a.defaults_applied = 0
JOIN access_grant g ON g.perm_key = n.parent_key;

UPDATE access_permission a JOIN uams_new_action n ON n.perm_key = a.perm_key SET a.defaults_applied = 1;
DROP TEMPORARY TABLE uams_new_action;

-- 3. The attendance page now holds manual attendance as well (biometric to follow). Only the shown name changes.
UPDATE access_permission SET label = 'Staff Attendance (manual and biometric)',
       description = 'Mark attendance, monthly register, holidays, week offs and vacations.'
WHERE perm_key = 'phrms.att' AND label = 'Biometric Attendance';

-- Check: the new buttons and who has them
SELECT a.parent_key AS page, a.label AS button, COALESCE(a.action_code, 'option') AS action,
       COUNT(g.perm_key) AS permissions
FROM access_permission a LEFT JOIN access_grant g ON g.perm_key = a.perm_key
WHERE a.kind = 'ACTION' AND a.app = 'PHRMS'
GROUP BY a.perm_key, a.parent_key, a.label, a.action_code, a.sort_order
ORDER BY a.sort_order;
