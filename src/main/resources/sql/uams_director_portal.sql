-- =====================================================================================
-- Director Portal - access catalogue rows (UAMS). Run once on the `inventory` database.
-- Adds rows to the EXISTING tables access_permission (no new tables). Safe to run again.
--
-- Global users can use everything without this script. Run it to give the Director Portal (or some of its
-- approvals) to other roles: PInventory > Access Management (UAMS) > Roles & Permissions, project "Director Portal".
--
--   dir.link           Director Portal (sign-in link and dashboard)
--   dir.notes.approve  Approve / reject PHRMS management notes      (PHRMS also needs phrms.rec + phrms.rec.approve)
--   dir.po.approve     Approve purchase orders                      (PInventory also needs pur.approve-po.approve)
--   dir.adm.approve    Select / reject admission candidates         (PInventory rule: Global or Tejkumar)
--   dir.sch.approve    Approve / reject KSS scholarships            (KSS portal rule: Global user in KSS users)
--   dir.open.phrms     Header button: open HR & Payroll signed in   (PHRMS page rules still apply)
--   dir.open.highedu   Header buttons: open KSS portal / SSS CSR     (KSS portal rule: Global user in KSS users)
-- The application that owns the record always checks its own rule again.
-- =====================================================================================
USE inventory;

INSERT IGNORE INTO access_permission (perm_key, app, module, kind, action_code, parent_key, label, description, paths, sort_order, defaults_applied)
VALUES ('proj.DIRECTOR', 'DIRECTOR', '', 'PROJECT', NULL, NULL, 'Director Portal',
        'Dashboard of KSS, SSS institutions, HR and purchase, with approvals.', NULL, 4, 1),
       ('mod.DIRECTOR.DIRECTOR_PORTAL', 'DIRECTOR', 'Director Portal', 'MODULE', NULL, 'proj.DIRECTOR', 'Director Portal',
        NULL, NULL, 900, 1),
       ('dir.link', 'DIRECTOR', 'Director Portal', 'PAGE', NULL, NULL, 'Director Portal (sign-in link and dashboard)',
        'Opens the Director Portal with the PInventory sign-in.', '/director/sso', 901, 1),
       ('dir.notes.approve', 'DIRECTOR', 'Director Portal', 'ACTION', 'APPROVE', 'dir.link', 'Approve management notes',
        'PHRMS management notes waiting for this user.', NULL, 902, 1),
       ('dir.po.approve', 'DIRECTOR', 'Director Portal', 'ACTION', NULL, 'dir.link', 'Approve purchase orders',
        'Purchase orders of every store the user may open.', NULL, 903, 1),
       ('dir.adm.approve', 'DIRECTOR', 'Director Portal', 'ACTION', NULL, 'dir.link', 'Admission decisions',
        'Select / reject candidates after the entrance test.', NULL, 904, 1),
       ('dir.sch.approve', 'DIRECTOR', 'Director Portal', 'ACTION', NULL, 'dir.link', 'Approve KSS scholarships',
        'Step 3 final approval of KSS scholarships.', NULL, 905, 1),
       ('dir.open.phrms', 'DIRECTOR', 'Director Portal', 'ACTION', NULL, 'dir.link', 'Open HR & Payroll',
        'One-click sign-in to PHRMS from the Director Portal.', NULL, 906, 1),
       ('dir.open.highedu', 'DIRECTOR', 'Director Portal', 'ACTION', NULL, 'dir.link', 'Open KSS portal / SSS CSR',
        'One-click sign-in to the KSS portal (HighEducation) from the Director Portal.', NULL, 907, 1);

SELECT perm_key, kind, label FROM access_permission WHERE app = 'DIRECTOR' ORDER BY sort_order;
