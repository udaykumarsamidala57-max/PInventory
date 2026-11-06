package com.officecentral.common.access;

import java.io.IOException;

import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Button (action) checks for PInventory pages, managed in Access Management (UAMS) > Roles & Permissions.
 *
 * Every state-changing button has a catalogue key (see sql/uams_inventory_actions.sql). Servlets MUST check the
 * key before doing the action, and pages use the same check to show or hide the button.
 *
 * While a key is not in the catalogue yet (SQL not run) the button's old fixed rule applies, so deploying the
 * code before running the SQL changes nothing.
 */
public final class ButtonAccess {

    // Indent
    public static final String INDENT_SAVE = "inv.indent.add";
    public static final String INDENT_PRINT = "inv.indent-report.print";
    // Approve Indent (normal) and Approve Dining Indent: first level, final level, edit, delete
    public static final String APPROVE_INDENT = "inv.approve-indent";
    public static final String APPROVE_DINING = "inv.approve-dining-indent";
    // Purchase orders
    public static final String PO_CREATE = "pur.create-po.add";
    public static final String PO_APPROVE = "pur.approve-po.approve";
    public static final String PO_DELETE = "pur.approve-po.delete";
    public static final String PO_PRINT = "pur.approve-po.print";
    public static final String PO_MAIL = "pur.approve-po.mail";
    public static final String PO_REPORT_PRINT = "pur.po-report.print";
    // GRN
    public static final String GRN_SAVE = "grn.entry.add";
    public static final String GRN_PRINT = "grn.report.print";

    private ButtonAccess() { }

    /** May this user use the button? {@code oldRule} applies only while the key is not in the catalogue. */
    public static boolean allows(HttpSession s, String key, boolean oldRule) {
        if (s == null || s.getAttribute("username") == null) return false;
        return AccessControl.show(s, key, oldRule);
    }

    /** First-level approve / reject, final decision, edit or delete on an indent approval page. */
    public static String indentKey(String page, String action, String status) {
        if (action == null) return null;
        switch (action.trim().toLowerCase(java.util.Locale.ROOT)) {
            case "iapprove":
                boolean reject = "Rejected".equalsIgnoreCase(status) || "Cancelled".equalsIgnoreCase(status);
                return page + (reject ? ".reject" : ".approve");
            case "approve": return page + ".final";
            case "edit":    return page + ".edit";
            case "delete":  return page + ".delete";
            default:        return null;
        }
    }

    public static boolean isGlobal(HttpSession s) {
        Object r = s == null ? null : s.getAttribute("role");
        return r != null && "Global".equalsIgnoreCase(String.valueOf(r).trim());
    }

    /** Old fixed rule of the indent approval pages (until the catalogue has the button keys). */
    public static boolean oldIndentRule(HttpSession s, String key) {
        if (key == null) return false;
        if (key.endsWith(".approve") || key.endsWith(".reject")) {
            Object r = s.getAttribute("role");
            String role = r == null ? "" : String.valueOf(r).trim();
            return "Global".equalsIgnoreCase(role) || "Incharge".equalsIgnoreCase(role) || "Admin".equalsIgnoreCase(role);
        }
        return isGlobal(s);                                   // final decision, edit and delete: Global only
    }

    /** Sends 403 with a plain message (also understood by fetch() callers). */
    public static void refuse(HttpServletResponse resp, String what) throws IOException {
        resp.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to " + what + ".");
    }
}
