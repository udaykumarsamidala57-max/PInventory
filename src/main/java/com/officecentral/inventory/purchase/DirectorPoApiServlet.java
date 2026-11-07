package com.officecentral.inventory.purchase;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.officecentral.common.access.AccessControl;
import com.officecentral.common.access.ButtonAccess;
import com.officecentral.common.db.InventoryDB;
import com.officecentral.common.sso.DirectorApi;

/**
 * POST /api/director/po-approve  (signed by the Director Portal; body: user, store, poNumber)
 * Same checks and code as the Approve button on Approve PO (ApprovePOServlet): the user must have the button
 * pur.approve-po.approve (old rule: Global) and access to the store; ApprovePOServlet.approve() then approves only
 * a PO that is not yet approved, sends the notification and updates Item Cost.
 */
@WebServlet("/api/director/po-approve")
public class DirectorPoApiServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(DirectorPoApiServlet.class.getName());

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Map<String, String> f = DirectorApi.verified(req, resp);
        if (f == null) return;
        String poNumber = f.getOrDefault("poNumber", "").trim();
        String store;
        try {
            store = InventoryDB.canonicalBranch(f.get("store"));
        } catch (SQLException unknownStore) {
            DirectorApi.reply(resp, 400, false, "Unknown store.");
            return;
        }
        if (poNumber.isEmpty() || poNumber.length() > 50) {
            DirectorApi.reply(resp, 400, false, "Select a Purchase Order.");
            return;
        }
        try {
            DirectorApi.User u = DirectorApi.user(f.get("user"));
            if (u == null) {
                DirectorApi.reply(resp, 403, false, "Your Office Central user was not found.");
                return;
            }
            if (!AccessControl.showUser(u.username, u.role, u.department, ButtonAccess.PO_APPROVE, u.global())) {
                DirectorApi.reply(resp, 403, false, "You do not have permission to approve Purchase Orders.");
                return;
            }
            if (!DirectorApi.hasStore(u, store)) {
                DirectorApi.reply(resp, 403, false, "You do not have access to the store " + store + ".");
                return;
            }
            String message = ApprovePOServlet.approve(store, poNumber, u.username + " (Director Portal)");
            boolean ok = message.startsWith("PO " + poNumber + " approved.");
            DirectorApi.reply(resp, ok ? 200 : 409, ok, message);
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Director Portal PO approval failed", e);
            DirectorApi.reply(resp, 500, false, "PO " + poNumber + " was not approved. Please try again.");
        }
    }
}
