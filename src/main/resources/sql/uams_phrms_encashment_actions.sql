-- =====================================================================================
-- UAMS: PHRMS Leave Encashment buttons (part 3 of Staff Management).
-- Run in MySQL Workbench against the `inventory` database AFTER access_control.sql and uams.sql. Safe to run again.
-- Each new button starts with exactly the permissions of the Leave Encashment page, so nobody gains or loses anything.
-- =====================================================================================
USE inventory;

DROP TEMPORARY TABLE IF EXISTS uams_new_action;
CREATE TEMPORARY TABLE uams_new_action (
  perm_key    VARCHAR(80)  NOT NULL PRIMARY KEY,
  parent_key  VARCHAR(80)  NOT NULL,
  action_code VARCHAR(10)  NULL,
  label       VARCHAR(120) NOT NULL,
  description VARCHAR(255) NULL,
  sort_add    INT          NOT NULL
);

INSERT INTO uams_new_action VALUES
  ('phrms.encash.add',     'phrms.encash', 'ADD',     'New encashment request', 'Record an encashment request for a staff member.', 1),
  ('phrms.encash.approve', 'phrms.encash', 'APPROVE', 'Approve / reject encashment', 'Approve (days taken from the leave balance) or reject; cancel an approved, unpaid encashment.', 2),
  ('phrms.encash.pay',     'phrms.encash', NULL,      'Record payment', 'Mark an approved encashment as paid (date, mode, reference).', 3),
  ('phrms.encash.setup',   'phrms.encash', NULL,      'Encashment calculation and limits', 'Salary components of the basis, divisor, balance to keep, limits.', 4);

INSERT IGNORE INTO access_permission (perm_key, app, module, kind, action_code, parent_key, label, description, paths, sort_order, defaults_applied)
SELECT n.perm_key, p.app, p.module, 'ACTION', n.action_code, n.parent_key, n.label, n.description, NULL, p.sort_order + n.sort_add, 0
FROM uams_new_action n JOIN access_permission p ON p.perm_key = n.parent_key AND p.kind = 'PAGE';

INSERT IGNORE INTO access_grant (perm_key, subject_type, subject, effect, granted_by)
SELECT n.perm_key, g.subject_type, g.subject, g.effect, 'uams-default'
FROM uams_new_action n
JOIN access_permission a ON a.perm_key = n.perm_key AND a.defaults_applied = 0
JOIN access_grant g ON g.perm_key = n.parent_key;

UPDATE access_permission a JOIN uams_new_action n ON n.perm_key = a.perm_key SET a.defaults_applied = 1;
DROP TEMPORARY TABLE uams_new_action;

SELECT perm_key, kind, label, (SELECT COUNT(*) FROM access_grant g WHERE g.perm_key = a.perm_key) AS permissions
FROM access_permission a WHERE perm_key LIKE 'phrms.encash%' ORDER BY sort_order;
