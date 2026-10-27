package com.officecentral.inventory.purchase;

import java.io.ByteArrayOutputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;


import com.itextpdf.text.BaseColor;
import com.itextpdf.text.Chunk;
import com.itextpdf.text.Document;
import com.itextpdf.text.Element;
import com.itextpdf.text.Font;
import com.itextpdf.text.Image;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.Phrase;
import com.itextpdf.text.Rectangle;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfWriter;

import com.officecentral.common.db.InventoryDB;

/**
 * The Purchase Order as a PDF, laid out like the print page (WEB-INF/views/inventory/purchase/PrintPO.jsp):
 * school header, contact line, title, order / vendor boxes, item table, totals, terms, conditions and signature.
 */
public final class POPdf {

    /** Everything the PDF and the alert mail show, read from po_master / po_items like the print page. */
    public static final class Data {
        String poNumber, poDate, vendorName, vendorAddress, vendorGstin;
        String totalDis, totalGst, totalAmount, serviceCharge, approval, terms, general;
        double total;
        final List<String[]> items = new ArrayList<>();   // description, uom, qty, rate, amount, disc%, disc, gst%, gst, net
    }

    // colours of the print page
    private static final BaseColor BLUE   = new BaseColor(0x01, 0x76, 0xd3);
    private static final BaseColor INK    = new BaseColor(0x18, 0x18, 0x18);
    private static final BaseColor MUTED  = new BaseColor(0x51, 0x4f, 0x4d);
    private static final BaseColor LINE   = new BaseColor(0xe5, 0xe5, 0xe5);
    private static final BaseColor LINE2  = new BaseColor(0xc9, 0xc9, 0xc9);
    private static final BaseColor SHADE  = new BaseColor(0xfa, 0xfa, 0xf9);
    private static final BaseColor GREEN  = new BaseColor(0x2e, 0x84, 0x4a);
    private static final BaseColor GREEN_BG = new BaseColor(0xea, 0xf5, 0xea);


    private POPdf() { }

    /** Reads the PO the same way the print page does. Returns null when the PO is not found. */
    public static Data load(String branch, String poNumber) throws SQLException {
        try (Connection con = InventoryDB.getConnection(branch)) {
            Data d = new Data();
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT po_number, PO_date AS po_date, vendor_name, vendor_address, vendor_gstin, "
                    + "total_gst, total_dis, total_amount, terms_conditions, general_conditions, Servicecharge, Approval "
                    + "FROM po_master WHERE po_number=?")) {
                ps.setString(1, poNumber);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) return null;
                    d.poNumber = rs.getString("po_number");
                    d.poDate = rs.getString("po_date");
                    d.vendorName = rs.getString("vendor_name");
                    d.vendorAddress = rs.getString("vendor_address");
                    d.vendorGstin = rs.getString("vendor_gstin");
                    d.totalGst = rs.getString("total_gst");
                    d.totalDis = rs.getString("total_dis");
                    d.totalAmount = rs.getString("total_amount");
                    d.total = rs.getDouble("total_amount");
                    d.terms = rs.getString("terms_conditions");
                    d.general = rs.getString("general_conditions");
                    d.serviceCharge = rs.getString("Servicecharge");
                    d.approval = rs.getString("Approval");
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT i.description, i.qty, i.rate, i.amount, i.discount_percent, i.discount_value, "
                    + "i.gst_percent, i.gst_value, i.net_amount, m.UOM "
                    + "FROM po_items i LEFT JOIN item_master m ON i.item_id = m.Item_id WHERE i.po_no=?")) {
                ps.setString(1, poNumber);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        d.items.add(new String[] {
                            rs.getString("description"),
                            rs.getString("UOM") != null ? rs.getString("UOM") : "-",
                            f2(rs.getDouble("qty")), f2(rs.getDouble("rate")), f2(rs.getDouble("amount")),
                            f2(rs.getDouble("discount_percent")), f2(rs.getDouble("discount_value")),
                            f2(rs.getDouble("gst_percent")), f2(rs.getDouble("gst_value")), f2(rs.getDouble("net_amount")) });
                    }
                }
            }
            return d;
        }
    }

    /** The PDF bytes. headerPng = the school banner from Branding.headerForPdf(ctx); may be null (no banner). */
    public static byte[] build(Data d, byte[] headerPng) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        float mm = 72f / 25.4f;
        Document doc = new Document(PageSize.A4, 12 * mm, 12 * mm, 12 * mm, 12 * mm);   // @page margin: 12mm
        PdfWriter.getInstance(doc, out);
        doc.addTitle("Purchase Order " + nz(d.poNumber));
        doc.addCreator("PInventory");
        doc.open();

        Font contact  = font(8, Font.NORMAL, MUTED);
        Font contactB = font(8, Font.BOLD, MUTED);
        Font cardHead = font(8, Font.BOLD, BLUE);
        Font label    = font(9, Font.BOLD, MUTED);
        Font value    = font(9, Font.NORMAL, INK);
        Font cell     = font(8.3f, Font.NORMAL, INK);
        Font cellB    = font(8.3f, Font.BOLD, INK);
        Font head     = font(7.2f, Font.BOLD, MUTED);
        Font sumF     = font(9, Font.NORMAL, MUTED);
        Font grandF   = font(10, Font.BOLD, BLUE);
        Font secF     = font(9, Font.BOLD, BLUE);
        Font condF    = font(8.5f, Font.NORMAL, INK);

        // ---- school header banner (assets/branding/PO and Indent Header.png, see Branding.headerForPdf)
        if (headerPng != null) {
            try {
                Image img = Image.getInstance(headerPng);
                img.scaleToFit(doc.right() - doc.left(), 80f);
                img.setAlignment(Element.ALIGN_CENTER);
                img.setSpacingAfter(6f);
                doc.add(img);
            } catch (Exception e) {
                System.err.println("[PDF] PO " + nz(d.poNumber) + ": header image not added: " + e.getMessage());
            }
        }

        // ---- contact line
        Paragraph c = new Paragraph();
        c.setAlignment(Element.ALIGN_CENTER);
        c.add(new Chunk("Website: ", contact));
        c.add(new Chunk("www.sandurschool.edu.in", contactB));
        c.add(new Chunk("  |  Email: ", contact));
        c.add(new Chunk("srsadmin@sandurschool.com", contactB));
        c.add(new Chunk("  |  Ph: ", contact));
        c.add(new Chunk("08395-260246", contactB));
        doc.add(c);
        doc.add(rule(LINE, 0.75f, 6f, 10f));

        // ---- title, blue lines above and below
        PdfPTable title = new PdfPTable(1);
        title.setWidthPercentage(100);
        PdfPCell t = new PdfPCell(new Phrase("PURCHASE ORDER", font(13, Font.BOLD, BLUE)));
        t.setHorizontalAlignment(Element.ALIGN_CENTER);
        t.setBorder(Rectangle.TOP | Rectangle.BOTTOM);
        t.setBorderColor(BLUE);
        t.setBorderWidth(1.5f);
        t.setPaddingTop(4f);
        t.setPaddingBottom(7f);
        title.addCell(t);
        title.setSpacingAfter(14f);
        doc.add(title);

        // ---- order reference / vendor details
        PdfPTable grid = new PdfPTable(new float[] { 1f, 0.06f, 1f });
        grid.setWidthPercentage(100);
        grid.addCell(card("ORDER REFERENCE", cardHead, label, value, new String[][] {
                { "PO Number:", nz(d.poNumber) }, { "Date:", longDate(d.poDate) } }));
        grid.addCell(blank());
        grid.addCell(card("VENDOR DETAILS", cardHead, label, value, new String[][] {
                { "Vendor Name:", nz(d.vendorName) },
                { "GSTIN:", d.vendorGstin != null ? d.vendorGstin : "-" },
                { "Address:", nz(d.vendorAddress) } }));
        grid.setSpacingAfter(12f);
        doc.add(grid);

        Paragraph intro = new Paragraph("We are pleased to place our order for the supply of the below items "
                + "on the terms and conditions mentioned below:", font(9, Font.ITALIC, MUTED));
        intro.setSpacingAfter(9f);
        doc.add(intro);

        // ---- items (discount columns only when some item has a discount, like the print page)
        boolean anyDiscount = false;
        for (String[] r : d.items) {
            if (Math.abs(num(r[5])) > 0.0001 || Math.abs(num(r[6])) > 0.0001) anyDiscount = true;
        }
        String[] heads = anyDiscount
                ? new String[] { "SL.NO", "ITEM DESCRIPTION", "UOM", "QTY", "RATE", "AMOUNT", "DISC %", "DISC VAL",
                                 "GST %", "GST VAL", "NET AMT" }
                : new String[] { "SL.NO", "ITEM DESCRIPTION", "UOM", "QTY", "RATE", "AMOUNT",
                                 "GST %", "GST VAL", "NET AMT" };
        float[] widths = anyDiscount ? new float[] { 5, 25, 8, 8, 9, 9, 7, 9, 6, 8, 10 }
                                     : new float[] { 5, 41, 8, 8, 9, 9, 6, 8, 10 };
        PdfPTable items = new PdfPTable(widths);
        items.setWidthPercentage(100);
        items.setHeaderRows(1);
        for (String h : heads) {
            PdfPCell hc = new PdfPCell(new Phrase(h, head));
            hc.setHorizontalAlignment(Element.ALIGN_CENTER);
            hc.setVerticalAlignment(Element.ALIGN_MIDDLE);
            hc.setBackgroundColor(SHADE);
            hc.setBorderColor(LINE);
            hc.setBorderColorTop(LINE2);
            hc.setBorderColorBottom(LINE2);
            hc.setBorderWidthBottom(1.5f);
            hc.setPadding(5f);
            items.addCell(hc);
        }
        int sl = 1;
        for (String[] r : d.items) {
            BaseColor bg = (sl % 2 == 0) ? SHADE : BaseColor.WHITE;
            items.addCell(td(String.valueOf(sl), cell, Element.ALIGN_CENTER, bg));
            items.addCell(td(nz(r[0]), cell, Element.ALIGN_LEFT, bg));
            items.addCell(td(r[1], cell, Element.ALIGN_CENTER, bg));
            for (int k = 2; k <= 8; k++) {
                if (!anyDiscount && (k == 5 || k == 6)) continue;
                items.addCell(td(r[k], cell, Element.ALIGN_RIGHT, bg));
            }
            items.addCell(td(r[9], cellB, Element.ALIGN_RIGHT, bg));
            sl++;
        }
        items.setSpacingAfter(10f);
        doc.add(items);

        // ---- totals box on the right
        PdfPTable sum = new PdfPTable(2);
        sum.setTotalWidth(210f);
        sum.setLockedWidth(true);
        sum.setHorizontalAlignment(Element.ALIGN_RIGHT);
        if (anyDiscount) sumRow(sum, "Total Discount:", nz(d.totalDis), sumF, false);
        sumRow(sum, "Total GST:", nz(d.totalGst), sumF, false);
        String sc = d.serviceCharge == null ? "" : d.serviceCharge.trim();
        if (!sc.isEmpty() && !sc.equals("0")) sumRow(sum, "Service Charges:", sc, sumF, false);
        sumRow(sum, "Grand Total:", nz(d.totalAmount), grandF, true);
        PdfPTable sumBox = new PdfPTable(1);
        sumBox.setTotalWidth(210f);
        sumBox.setLockedWidth(true);
        sumBox.setHorizontalAlignment(Element.ALIGN_RIGHT);
        PdfPCell box = new PdfPCell(sum);
        box.setBackgroundColor(SHADE);
        box.setBorderColor(LINE);
        box.setPadding(6f);
        sumBox.addCell(box);
        sumBox.setSpacingAfter(8f);
        doc.add(sumBox);

        // ---- terms and conditions
        section(doc, "TERMS AND CONDITIONS", nz(d.terms), secF, condF);
        section(doc, "GENERAL CONDITIONS", nz(d.general), secF, condF);

        // ---- signature (stamp only when approved, like the print page)
        PdfPTable sig = new PdfPTable(new float[] { 1f, 1f });
        sig.setWidthPercentage(100);
        sig.setSpacingBefore(28f);
        PdfPCell left = blank();
        left.setVerticalAlignment(Element.ALIGN_BOTTOM);
        if ("Approved".equalsIgnoreCase(d.approval)) {
            PdfPTable st = new PdfPTable(1);
            st.setTotalWidth(90f);
            st.setLockedWidth(true);
            st.setHorizontalAlignment(Element.ALIGN_LEFT);
            PdfPCell s = new PdfPCell(new Phrase("APPROVED", font(11, Font.BOLD, GREEN)));
            s.setHorizontalAlignment(Element.ALIGN_CENTER);
            s.setBackgroundColor(GREEN_BG);
            s.setBorderColor(GREEN);
            s.setBorderWidth(1.5f);
            s.setPadding(5f);
            st.addCell(s);
            left.addElement(st);
        }
        sig.addCell(left);
        PdfPCell right = blank();
        right.setHorizontalAlignment(Element.ALIGN_RIGHT);
        Paragraph company = new Paragraph("For SANDUR RESIDENTIAL SCHOOL", font(9, Font.BOLD, MUTED));
        company.setAlignment(Element.ALIGN_RIGHT);
        company.setSpacingAfter(34f);
        right.addElement(company);
        Paragraph signLine = new Paragraph();
        signLine.setAlignment(Element.ALIGN_RIGHT);
        Chunk who = new Chunk("Authorized Signatory", font(9, Font.BOLD, INK));
        signLine.add(who);
        right.addElement(rightRule());
        right.addElement(signLine);
        sig.addCell(right);
        sig.setKeepTogether(true);
        doc.add(sig);

        doc.close();
        return out.toByteArray();
    }

    // ------------------------------------------------------------------ helpers

    private static PdfPCell card(String heading, Font headF, Font labelF, Font valueF, String[][] rows) {
        PdfPTable inner = new PdfPTable(new float[] { 0.95f, 2.05f });
        inner.setWidthPercentage(100);
        PdfPCell h = new PdfPCell(new Phrase(heading, headF));
        h.setColspan(2);
        h.setBorder(Rectangle.BOTTOM);
        h.setBorderColor(LINE);
        h.setPaddingBottom(5f);
        h.setPaddingLeft(0);
        inner.addCell(h);
        for (String[] r : rows) {
            PdfPCell l = new PdfPCell(new Phrase(r[0], labelF));
            l.setBorder(Rectangle.NO_BORDER);
            l.setPaddingTop(4f);
            l.setPaddingLeft(0);
            inner.addCell(l);
            PdfPCell v = new PdfPCell(new Phrase(r[1], valueF));
            v.setBorder(Rectangle.NO_BORDER);
            v.setPaddingTop(4f);
            inner.addCell(v);
        }
        PdfPCell outer = new PdfPCell(inner);
        outer.setBackgroundColor(SHADE);
        outer.setBorderColor(LINE);
        outer.setPadding(9f);
        return outer;
    }

    private static PdfPCell td(String s, Font f, int align, BaseColor bg) {
        PdfPCell c = new PdfPCell(new Phrase(s, f));
        c.setHorizontalAlignment(align);
        c.setVerticalAlignment(Element.ALIGN_MIDDLE);
        c.setBorderColor(LINE);
        c.setBackgroundColor(bg);
        c.setPadding(5f);
        return c;
    }

    private static void sumRow(PdfPTable t, String k, String v, Font f, boolean grand) {
        PdfPCell a = new PdfPCell(new Phrase(k, f));
        PdfPCell b = new PdfPCell(new Phrase(v, f));
        b.setHorizontalAlignment(Element.ALIGN_RIGHT);
        for (PdfPCell c : new PdfPCell[] { a, b }) {
            if (grand) {
                c.setBorder(Rectangle.TOP);
                c.setBorderColor(BLUE);
                c.setBorderWidth(1.5f);
            } else {
                c.setBorder(Rectangle.NO_BORDER);
            }
            c.setPaddingTop(grand ? 6f : 3f);
            c.setPaddingBottom(3f);
            c.setPaddingLeft(0);
            c.setPaddingRight(0);
            t.addCell(c);
        }
    }

    private static void section(Document doc, String title, String text, Font titleF, Font textF) throws Exception {
        PdfPTable t = new PdfPTable(1);
        t.setTotalWidth(titleF.getCalculatedBaseFont(false).getWidthPoint(title, titleF.getSize()) + 2f);
        t.setLockedWidth(true);
        t.setHorizontalAlignment(Element.ALIGN_LEFT);
        t.setSpacingBefore(14f);
        PdfPCell c = new PdfPCell(new Phrase(title, titleF));
        c.setBorder(Rectangle.BOTTOM);
        c.setBorderColor(BLUE);
        c.setBorderWidth(0.75f);
        c.setPadding(0);
        c.setPaddingBottom(3f);
        t.addCell(c);
        doc.add(t);
        Paragraph p = new Paragraph(text, textF);         // keeps the line breaks (pre-wrap)
        p.setSpacingBefore(4f);
        p.setLeading(12f);
        doc.add(p);
    }

    private static PdfPCell blank() {
        PdfPCell c = new PdfPCell();
        c.setBorder(Rectangle.NO_BORDER);
        return c;
    }

    private static PdfPTable rule(BaseColor color, float width, float before, float after) {
        PdfPTable t = new PdfPTable(1);
        t.setWidthPercentage(100);
        PdfPCell c = new PdfPCell();
        c.setBorder(Rectangle.BOTTOM);
        c.setBorderColor(color);
        c.setBorderWidth(width);
        c.setFixedHeight(1f);
        t.addCell(c);
        t.setSpacingBefore(before);
        t.setSpacingAfter(after);
        return t;
    }

    private static PdfPTable rightRule() {
        PdfPTable t = new PdfPTable(1);
        t.setTotalWidth(110f);
        t.setLockedWidth(true);
        t.setHorizontalAlignment(Element.ALIGN_RIGHT);
        PdfPCell c = new PdfPCell();
        c.setBorder(Rectangle.TOP);
        c.setBorderColor(INK);
        c.setBorderWidth(0.75f);
        c.setFixedHeight(3f);
        t.addCell(c);
        return t;
    }

    private static Font font(float size, int style, BaseColor color) {
        return new Font(Font.FontFamily.HELVETICA, size, style, color);
    }

    private static double num(String s) {
        try {
            return Double.parseDouble(s);
        } catch (Exception e) {
            return 0;
        }
    }

    private static String f2(double v) {
        return String.format("%.2f", v);
    }

    private static String nz(String s) {
        return s == null ? "" : s;
    }

    private static String longDate(String raw) {
        if (raw == null || raw.trim().isEmpty()) return "-";
        try {
            return LocalDate.parse(raw.trim().length() > 10 ? raw.trim().substring(0, 10) : raw.trim())
                    .format(DateTimeFormatter.ofPattern("dd MMMM yyyy"));
        } catch (Exception e) {
            return raw;
        }
    }
}
