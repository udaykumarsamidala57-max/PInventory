package com.officecentral.inventory.purchase;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.officecentral.common.mail.Mailer;

/**
 * "Send mail" on the Purchase Orders (approve-po) page.
 *
 *   GET  /po-mail?poNumber=X              -> the users that may receive it: Finance department, role Global or Admin,
 *                                            with a mail address and assigned to the store you are working in
 *   POST /po-mail  poNumber, userId (1..n), note (optional)
 *                                         -> mails the PO (PDF like the print page) to the chosen users
 *
 * Only users from that list can be chosen; the addresses are always taken from the database, never from the browser.
 */
@WebServlet("/po-mail")
public class POMailServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null) {
            json(resp, 401, error("Your session has ended. Please log in again."));
            return;
        }
        String branch = (String) s.getAttribute("branch");
        try {
            JsonArray users = new JsonArray();
            for (POAlert.Recipient r : POAlert.mailableUsersOf(branch)) {
                JsonObject u = new JsonObject();
                u.addProperty("id", r.id);
                u.addProperty("name", r.username);
                u.addProperty("role", r.role == null ? "" : r.role);
                u.addProperty("department", r.department == null ? "" : r.department);
                u.addProperty("mail", r.mail);
                users.add(u);
            }
            JsonObject out = new JsonObject();
            out.addProperty("store", branch);
            out.add("users", users);
            json(resp, 200, out);
        } catch (Exception e) {
            e.printStackTrace();
            json(resp, 500, error("Could not load the users: " + e.getMessage()));
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("username") == null) {
            json(resp, 401, error("Your session has ended. Please log in again."));
            return;
        }
        String branch = (String) s.getAttribute("branch");
        String sender = (String) s.getAttribute("username");
        String poNumber = trim(req.getParameter("poNumber"));
        String note = trim(req.getParameter("note"));
        if (note.length() > 1000) note = note.substring(0, 1000);
        String[] ids = req.getParameterValues("userId");

        if (poNumber.isEmpty()) {
            json(resp, 400, error("No PO number."));
            return;
        }
        if (ids == null || ids.length == 0) {
            json(resp, 400, error("Choose at least one person."));
            return;
        }

        try {
            // only people from the allowed list for this store
            Map<Integer, POAlert.Recipient> allowed = new LinkedHashMap<>();
            for (POAlert.Recipient r : POAlert.mailableUsersOf(branch)) allowed.put(r.id, r);
            Set<POAlert.Recipient> chosen = new LinkedHashSet<>();
            for (String id : ids) {
                try {
                    POAlert.Recipient r = allowed.get(Integer.parseInt(id.trim()));
                    if (r != null) chosen.add(r);
                } catch (NumberFormatException ignored) {
                    // skip
                }
            }
            if (chosen.isEmpty()) {
                json(resp, 400, error("None of the chosen people can receive mails for this store."));
                return;
            }

            POPdf.Data d = POPdf.load(branch, poNumber);
            if (d == null) {
                json(resp, 404, error("Purchase Order " + poNumber + " was not found in this store."));
                return;
            }
            byte[] pdf = POPdf.build(d, POAlert.headerImage(getServletContext()));
            String store = storeName(branch);
            String subject = "Purchase Order " + d.poNumber + " - " + store;
            String html = POAlert.mailBody("Purchase Order " + d.poNumber, branch, d, sender, "Sent by", note,
                    POAlert.approveUrl(req), true,
                    "Sent from PInventory by " + sender + " (" + store + ").");
            String fileName = "PO_" + d.poNumber.replaceAll("[^A-Za-z0-9._-]+", "-") + ".pdf";

            JsonArray sent = new JsonArray();
            JsonArray failed = new JsonArray();
            Set<String> done = new LinkedHashSet<>();
            for (POAlert.Recipient r : chosen) {
                if (!done.add(r.mail.toLowerCase())) continue;          // same address twice
                try {
                    Mailer.send(r.mail, subject, html, fileName, pdf);
                    sent.add(r.username + " <" + r.mail + ">");
                } catch (Exception e) {
                    JsonObject f = new JsonObject();
                    f.addProperty("to", r.username + " <" + r.mail + ">");
                    f.addProperty("reason", shortReason(e));
                    failed.add(f);
                }
            }
            JsonObject out = new JsonObject();
            out.addProperty("ok", failed.size() == 0);
            out.add("sent", sent);
            out.add("failed", failed);
            json(resp, 200, out);
        } catch (Exception e) {
            e.printStackTrace();
            json(resp, 500, error("Mail not sent: " + shortReason(e)));
        }
    }

    private static String storeName(String branch) {
        try {
            return com.officecentral.common.db.InventoryDB.canonicalBranch(branch);
        } catch (Exception e) {
            return String.valueOf(branch);
        }
    }

    private static String shortReason(Exception e) {
        String m = e.getMessage() == null ? e.toString() : e.getMessage();
        return m.length() > 300 ? m.substring(0, 300) + "..." : m;
    }

    private static String trim(String v) {
        return v == null ? "" : v.trim();
    }

    private static JsonObject error(String message) {
        JsonObject o = new JsonObject();
        o.addProperty("ok", false);
        o.addProperty("error", message);
        return o;
    }

    private static void json(HttpServletResponse resp, int status, JsonObject body) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        resp.getWriter().write(body.toString());
    }
}
