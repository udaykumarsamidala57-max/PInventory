-- =====================================================================================
-- UAMS: buttons (actions) of the Indent, Purchase Order and GRN pages in PInventory.
-- Run in MySQL Workbench against the `inventory` database AFTER access_control.sql and uams.sql.
--
-- Safe to run again. New buttons start with exactly today's access, so nobody gains or loses anything:
--   * "same as page"  - a copy of the page's current permissions (old rules and UAMS roles alike)
--   * "Global only"   - no permissions, because today only Global users can do it
-- After that, change who may use each button in PInventory > Access Management (UAMS) > Roles & Permissions.
-- Filters and Excel downloads are not controlled separately (they follow page access).
-- =====================================================================================
USE inventory;

DROP TEMPORARY TABLE IF EXISTS uams_new_action;
CREATE TEMPORARY TABLE uams_new_action (
  perm_key    VARCHAR(80)  NOT NULL PRIMARY KEY,
  parent_key  VARCHAR(80)  NOT NULL,
  action_code VARCHAR(10)  NULL,               -- one of the 8 standard actions, or NULL = named option
  label       VARCHAR(120) NOT NULL,
  description VARCHAR(255) NULL,
  copy_page   TINYINT(1)   NOT NULL,           -- 1 = start with the page's permissions, 0 = Global only
  sort_add    INT          NOT NULL
);

INSERT INTO uams_new_action VALUES
  -- Item Requisition Form
  ('inv.indent.add',                   'inv.indent',               'ADD',     'Save indent',                     'Save button on the Item Requisition Form (website and Android app use separate checks).', 1, 1),
  -- Indent Report
  ('inv.indent-report.print',          'inv.indent-report',        'PRINT',   'Print indent',                    'View / Print button of an indent.', 1, 1),
  -- Approve Indent: first level (Incharge) and final level
  ('inv.approve-indent.approve',       'inv.approve-indent',       'APPROVE', 'First approval (Incharge)',       'Approve button of the first level, website and Android app.', 1, 1),
  ('inv.approve-indent.reject',        'inv.approve-indent',       'REJECT',  'First rejection (Incharge)',      'Reject button of the first level, website and Android app.', 1, 2),
  ('inv.approve-indent.final',         'inv.approve-indent',       NULL,      'Final decision: Issue / PO / Reject', 'Second-level buttons after the first approval. Today: Global only.', 0, 3),
  ('inv.approve-indent.edit',          'inv.approve-indent',       'EDIT',    'Change quantity / purpose',       'Edit an indent line before approval. Today: Global only.', 0, 4),
  ('inv.approve-indent.delete',        'inv.approve-indent',       'DELETE',  'Cancel indent line',              'Cancel an indent line. Today: Global only.', 0, 5),
  -- Approve Dining Indent (same buttons)
  ('inv.approve-dining-indent.approve','inv.approve-dining-indent','APPROVE', 'First approval (Incharge)',       'Approve button of the first level.', 1, 1),
  ('inv.approve-dining-indent.reject', 'inv.approve-dining-indent','REJECT',  'First rejection (Incharge)',      'Reject button of the first level.', 1, 2),
  ('inv.approve-dining-indent.final',  'inv.approve-dining-indent',NULL,      'Final decision: Issue / PO / Reject', 'Second-level buttons after the first approval. Today: Global only.', 0, 3),
  ('inv.approve-dining-indent.edit',   'inv.approve-dining-indent','EDIT',    'Change quantity / purpose',       'Edit an indent line before approval. Today: Global only.', 0, 4),
  ('inv.approve-dining-indent.delete', 'inv.approve-dining-indent','DELETE',  'Cancel indent line',              'Cancel an indent line. Today: Global only.', 0, 5),
  -- Create Purchase Order
  ('pur.create-po.add',                'pur.create-po',            'ADD',     'Create purchase order',           'Save button that raises a PO from approved indents.', 1, 1),
  -- Approve PO
  ('pur.approve-po.approve',           'pur.approve-po',           'APPROVE', 'Approve PO',                      'Approve button. Today: Global only.', 0, 1),
  ('pur.approve-po.delete',            'pur.approve-po',           'DELETE',  'Delete PO',                       'Delete button of a PO that is not approved yet.', 1, 2),
  ('pur.approve-po.print',             'pur.approve-po',           'PRINT',   'View / Print PO',                 'View / Print button.', 1, 3),
  ('pur.approve-po.mail',              'pur.approve-po',           NULL,      'Send PO by e-mail',               'Send Mail button.', 1, 4),
  -- PO Report
  ('pur.po-report.print',              'pur.po-report',            'PRINT',   'View / Print PO',                 'View / Print button.', 1, 1),
  -- GRN
  ('grn.entry.add',                    'grn.entry',                'ADD',     'Save GRN',                        'Save button of the GRN entry, and the GRN button on Approve PO.', 1, 1),
  ('grn.report.print',                 'grn.report',               'PRINT',   'Print GRN',                       'Print button of a GRN.', 1, 1);

-- 1. Catalogue rows (module and order taken from the page). Existing rows are left as they are.
INSERT IGNORE INTO access_permission (perm_key, app, module, kind, action_code, parent_key, label, description, paths, sort_order, defaults_applied)
SELECT n.perm_key, p.app, p.module, 'ACTION', n.action_code, n.parent_key, n.label, n.description, NULL, p.sort_order + n.sort_add, 0
FROM uams_new_action n JOIN access_permission p ON p.perm_key = n.parent_key AND p.kind = 'PAGE';

-- 2. Starting permissions, only for rows added just now (defaults_applied = 0): copy the page's permissions.
INSERT IGNORE INTO access_grant (perm_key, subject_type, subject, effect, granted_by)
SELECT n.perm_key, g.subject_type, g.subject, g.effect, 'uams-default'
FROM uams_new_action n
JOIN access_permission a ON a.perm_key = n.perm_key AND a.defaults_applied = 0
JOIN access_grant g ON g.perm_key = n.parent_key
WHERE n.copy_page = 1;

UPDATE access_permission a JOIN uams_new_action n ON n.perm_key = a.perm_key SET a.defaults_applied = 1;
DROP TEMPORARY TABLE uams_new_action;

-- Check: the new buttons and who has them
SELECT a.parent_key AS page, a.label AS button, COALESCE(a.action_code, 'option') AS action,
       COUNT(g.perm_key) AS permissions
FROM access_permission a LEFT JOIN access_grant g ON g.perm_key = a.perm_key
WHERE a.kind = 'ACTION' AND a.app = 'PINVENTORY'
GROUP BY a.perm_key, a.parent_key, a.label, a.action_code, a.sort_order
ORDER BY a.sort_order;
