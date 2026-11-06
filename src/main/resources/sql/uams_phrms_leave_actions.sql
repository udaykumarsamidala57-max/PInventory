-- =====================================================================================
-- UAMS: PHRMS Staff Leave (part 2 of Staff Management).
-- Run in MySQL Workbench against the `inventory` database AFTER access_control.sql and uams.sql.
-- Safe to run again.
--
--   Staff Leave page buttons (start with exactly the permissions of the Staff Leave page, so nobody gains or loses):
--     phrms.leave.apply    Enter leave for staff
--     phrms.leave.approve  Approve / reject / cancel approved leave
--     phrms.leave.setup    Leave types, rules, opening balances, corrections, closing the year
--   New page (starts with NO permissions; grant it in UAMS to the roles of staff who apply for themselves):
--     phrms.leave.my       My Leave - staff apply for their own leave and see their balances.
--     The user's Employee ID in UAMS > Users & Roles must equal the Employee ID in PHRMS Staff Details.
--     Staff also need the PInventory page "HR & Payroll (sign-in link)" (phrms.link) to open PHRMS.
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
  ('phrms.leave.apply',   'phrms.leave', 'ADD',     'Enter leave for staff',
   'Record a leave application on behalf of a staff member.', 1),
  ('phrms.leave.approve', 'phrms.leave', 'APPROVE', 'Approve / reject leave',
   'Approve or reject pending leave, and cancel approved leave (the days go back).', 2),
  ('phrms.leave.setup',   'phrms.leave', NULL,      'Leave types, rules and balances',
   'Leave year, leave types, branch / department rules, opening balances, corrections, closing a leave year.', 3);

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

-- My Leave: a page of its own in the Staff Leave module (no permissions to start with).
INSERT IGNORE INTO access_permission (perm_key, app, module, kind, action_code, parent_key, label, description, paths, sort_order, defaults_applied)
SELECT 'phrms.leave.my', p.app, p.module, 'PAGE', NULL, NULL, 'My Leave (staff self-service)',
       'Staff apply for their own leave and see their own balances. Needs the Employee ID set in UAMS.', NULL, p.sort_order + 5, 1
FROM access_permission p WHERE p.perm_key = 'phrms.leave';

-- Check
SELECT perm_key, kind, label, (SELECT COUNT(*) FROM access_grant g WHERE g.perm_key = a.perm_key) AS permissions
FROM access_permission a WHERE perm_key LIKE 'phrms.leave%' ORDER BY sort_order;
