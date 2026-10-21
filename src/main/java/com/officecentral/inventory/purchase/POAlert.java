package com.officecentral.inventory.purchase;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import com.officecentral.common.db.InventoryDB;
import com.officecentral.common.mail.Mailer;

/**
 * E-mail alert when a new Purchase Order is created.
 *
 * Who gets it: every user with role "Global" who has a mail address and is assigned to the store the PO was made in
 * (store assignments from user_database_access, or users.branch for users without assignments -
 * the same rule the store selection uses).
 *
 * The mails go out in the background, so saving the PO never waits for, or fails because of, e-mail.
 * Each try is written to pinventory-mail.log in the server user's home folder.
 */
public final class POAlert {

    /** One line of the PO for the mail. */
    public static final class Line {
        final String description;
        final double qty, rate, net;

        public Line(String description, double qty, double rate, double net) {
            this.description = description;
            this.qty = qty;
            this.rate = rate;
            this.net = net;
        }
    }

    private static final ExecutorService SENDER = Executors.newSingleThreadExecutor(r -> {
        Thread t = new Thread(r, "po-mail-alert");
        t.setDaemon(true);
        return t;
    });

    private POAlert() { }

    /**
     * Queues the alert with the PO as a PDF (same layout as the print page). Never throws.
     * headerPng = the school banner (see {@link #headerImage}).
     */
    public static void newPO(String branch, String poNo, String createdBy, String approveUrl, byte[] headerPng) {
        SENDER.submit(() -> {
            try {
                List<String> to = globalUsersOf(branch);
                if (to.isEmpty()) {
                    System.out.println("[mail] New PO " + poNo + ": no Global user with an e-mail is assigned to " + branch);
                    return;
                }
                POPdf.Data d = POPdf.load(branch, poNo);
                if (d == null) {
                    System.err.println("[mail] New PO " + poNo + " not found in " + branch + "; alert not sent");
                    return;
                }
                byte[] pdf = null;
                try {
                    pdf = POPdf.build(d, headerPng);
                } catch (Exception pdfError) {
                    System.err.println("[mail] PO " + poNo + " PDF could not be made, sending without it: " + pdfError);
                }
                List<Line> lines = new ArrayList<>();
                for (String[] r : d.items) {
                    lines.add(new Line(r[0], num(r[2]), num(r[3]), num(r[9])));
                }
                String subject = "New Purchase Order " + poNo + " - " + storeName(branch) + " - awaiting approval";
                String html = body(branch, d.poNumber, d.poDate, d.vendorName, d.total, createdBy, lines, approveUrl,
                        pdf != null);
                String fileName = "PO_" + poNo.replaceAll("[^A-Za-z0-9._-]+", "-") + ".pdf";
                for (String mail : to) {
                    try {
                        Mailer.send(mail, subject, html, pdf == null ? null : fileName, pdf);
                    } catch (Exception e) {
                        // already written to the mail log by Mailer
                    }
                }
            } catch (Exception e) {
                System.err.println("[mail] New PO alert for " + poNo + " not sent: " + e);
            }
        });
    }

    /** The school banner used at the top of the PO print (webapp/Header.png), or null. */
    public static byte[] headerImage(javax.servlet.ServletContext ctx) {
        try (java.io.InputStream in = ctx.getResourceAsStream("/Header.png")) {
            return in == null ? null : in.readAllBytes();
        } catch (Exception e) {
            return null;
        }
    }

    private static double num(String s) {
        try {
            return Double.parseDouble(s);
        } catch (Exception e) {
            return 0;
        }
    }

    /** Mail addresses of Global users assigned to this store. */
    static List<String> globalUsersOf(String branch) throws SQLException {
        String store = InventoryDB.canonicalBranch(branch);
        Map<Integer, String[]> users = new LinkedHashMap<>();          // id -> {mail, users.branch}
        Map<Integer, Set<String>> assigned = new HashMap<>();

        try (Connection con = InventoryDB.getAuthConnection()) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT id, mail, branch FROM users WHERE LOWER(TRIM(role)) = 'global' "
                    + "AND mail IS NOT NULL AND TRIM(mail) <> ''");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) users.put(rs.getInt("id"), new String[] { rs.getString("mail").trim(), rs.getString("branch") });
            }
            if (users.isEmpty()) return new ArrayList<>();

            try (PreparedStatement ps = con.prepareStatement("SELECT user_id, database_code FROM user_database_access");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int id = rs.getInt("user_id");
                    if (!users.containsKey(id)) continue;
                    try {
                        assigned.computeIfAbsent(id, k -> new LinkedHashSet<>())
                                .add(InventoryDB.canonicalBranch(rs.getString("database_code")));
                    } catch (SQLException ignored) {
                        // unknown store code
                    }
                }
            } catch (SQLException noAssignmentTable) {
                // older databases: fall back to users.branch below
            }
        }

        Set<String> mails = new LinkedHashSet<>();
        for (Map.Entry<Integer, String[]> u : users.entrySet()) {
            Set<String> stores = assigned.get(u.getKey());
            boolean forThisStore;
            if (stores != null && !stores.isEmpty()) {
                forThisStore = stores.contains(store);
            } else {
                String own = u.getValue()[1];
                try {
                    forThisStore = own != null && InventoryDB.canonicalBranch(own).equals(store);
                } catch (SQLException e) {
                    forThisStore = false;
                }
            }
            if (forThisStore) mails.add(u.getValue()[0].toLowerCase(Locale.ROOT));
        }
        return new ArrayList<>(mails);
    }

    /** Link to the PO approval page, as seen from the browser (works behind Railway's proxy too). */
    public static String approveUrl(javax.servlet.http.HttpServletRequest req) {
        String proto = req.getHeader("X-Forwarded-Proto");
        String host = req.getHeader("X-Forwarded-Host");
        if (proto == null || proto.isEmpty()) proto = req.getScheme();
        if (host == null || host.isEmpty()) {
            int port = req.getServerPort();
            boolean normal = ("http".equals(proto) && port == 80) || ("https".equals(proto) && port == 443);
            host = req.getServerName() + (normal ? "" : ":" + port);
        }
        return proto + "://" + host + req.getContextPath() + "/approve-po";
    }

    private static String storeName(String branch) {
        try {
            return InventoryDB.canonicalBranch(branch);
        } catch (SQLException e) {
            return String.valueOf(branch);
        }
    }

    private static String body(String branch, String poNo, String poDate, String vendor, double total,
                               String createdBy, List<Line> lines, String approveUrl, boolean withPdf) {
        NumberFormat inr = NumberFormat.getNumberInstance(new Locale("en", "IN"));
        inr.setMinimumFractionDigits(2);
        inr.setMaximumFractionDigits(2);

        StringBuilder rows = new StringBuilder();
        int n = 1;
        for (Line l : lines) {
            rows.append("<tr>")
                .append(td(String.valueOf(n++), "center"))
                .append(td(esc(l.description), "left"))
                .append(td(inr.format(l.qty), "right"))
                .append(td(inr.format(l.rate), "right"))
                .append(td(inr.format(l.net), "right"))
                .append("</tr>");
        }

        return "<div style='font-family:Segoe UI,Arial,sans-serif;color:#1f2937;max-width:680px;'>"
            + "<div style='background:#032d60;color:#fff;padding:14px 18px;border-radius:8px 8px 0 0;'>"
            + "<div style='font-size:12px;opacity:.8;'>PInventory &middot; " + esc(storeName(branch)) + "</div>"
            + "<div style='font-size:18px;font-weight:700;'>New Purchase Order created</div></div>"
            + "<div style='border:1px solid #dddbda;border-top:0;padding:16px 18px;border-radius:0 0 8px 8px;'>"
            + "<table style='font-size:14px;border-collapse:collapse;margin-bottom:14px;'>"
            + info("PO number", esc(poNo)) + info("PO date", esc(poDate)) + info("Vendor", esc(vendor))
            + info("Total amount", "&#8377; " + inr.format(total)) + info("Created by", esc(createdBy))
            + info("Status", "Pending approval")
            + "</table>"
            + (lines.isEmpty() ? "" :
               "<table style='width:100%;border-collapse:collapse;font-size:13px;'>"
               + "<tr style='background:#f3f3f3;'>" + th("#") + th("Item") + th("Qty") + th("Rate") + th("Net amount") + "</tr>"
               + rows + "</table>")
            + (approveUrl == null ? "" :
               "<p style='margin:18px 0 4px;'><a href='" + esc(approveUrl) + "' style='background:#0176d3;color:#fff;"
               + "padding:9px 16px;border-radius:6px;text-decoration:none;font-weight:600;'>Open PO approval</a></p>")
            + (withPdf ? "<p style='font-size:13px;margin:14px 0 0;'>The Purchase Order is attached as a PDF.</p>" : "")
            + "<p style='font-size:12px;color:#6b7280;margin-top:16px;'>Automatic alert from PInventory. "
            + "You get this because you are a Global user of " + esc(storeName(branch)) + ".</p>"
            + "</div></div>";
    }

    private static String info(String label, String value) {
        return "<tr><td style='padding:3px 16px 3px 0;color:#6b7280;'>" + label + "</td>"
             + "<td style='padding:3px 0;font-weight:600;'>" + value + "</td></tr>";
    }

    private static String th(String s) {
        return "<th style='text-align:left;padding:7px 8px;border-bottom:1px solid #dddbda;'>" + s + "</th>";
    }

    private static String td(String s, String align) {
        return "<td style='text-align:" + align + ";padding:6px 8px;border-bottom:1px solid #eee;'>" + s + "</td>";
    }

    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
}
