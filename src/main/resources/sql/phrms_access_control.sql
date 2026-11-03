-- Register the PHRMS SSO navigation link in the `inventory` database.
-- Safe to run again. Adds no grants: Global users can access by default;
-- a Global user can grant other users from PInventory Access Control.
USE inventory;

INSERT INTO access_permission (perm_key, app, module, kind, parent_key, label, description, paths, sort_order)
VALUES ('phrms.link', 'PINVENTORY', 'School Management', 'PAGE', NULL,
        'HR & Payroll (sign-in link)', 'Opens PHRMS with the PInventory sign-in.', '/phrms/sso', 415)
ON DUPLICATE KEY UPDATE
    app = VALUES(app),
    module = VALUES(module),
    kind = VALUES(kind),
    parent_key = VALUES(parent_key),
    label = VALUES(label),
    description = VALUES(description),
    paths = VALUES(paths),
    sort_order = VALUES(sort_order);
