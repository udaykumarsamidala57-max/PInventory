package com.officecentral.common.web;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.imageio.ImageIO;
import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;

/**
 * The school header banner used on prints, PDFs and e-mails: webapp/assets/branding/PO and Indent Header.png.
 *
 * Read from INSIDE the web application (ServletContext), so it works however the app is deployed
 * (exploded folder, WAR file, Railway, any context name) – never through a disk path.
 */
public final class Branding {

    private static final Logger LOG = Logger.getLogger(Branding.class.getName());

    /** Path of the banner inside the web application. */
    public static final String HEADER_PATH = "/assets/branding/PO and Indent Header.png";
    /** Same path, URL-encoded, for links in e-mails. */
    private static final String HEADER_URL_PATH = "/assets/branding/PO%20and%20Indent%20Header.png";

    private static volatile byte[] pdfHeaderCache;

    private Branding() { }

    /**
     * The banner as a PNG ready for a PDF: shrunk once to at most 1600 px wide on a white background
     * (the original is about 2480 px), so every PDF stays small. Null when the image cannot be read.
     */
    public static byte[] headerForPdf(ServletContext ctx) {
        byte[] cached = pdfHeaderCache;
        if (cached != null) return cached;
        if (ctx == null) return null;
        try (InputStream in = ctx.getResourceAsStream(HEADER_PATH)) {
            if (in == null) {
                LOG.warning("[branding] header image not found in the web app at " + HEADER_PATH);
                return null;
            }
            BufferedImage src = ImageIO.read(new ByteArrayInputStream(in.readAllBytes()));
            if (src == null) {
                LOG.warning("[branding] " + HEADER_PATH + " is not a readable image");
                return null;
            }
            int w = Math.min(1600, src.getWidth());
            int h = Math.max(1, Math.round(src.getHeight() * (w / (float) src.getWidth())));
            BufferedImage dst = new BufferedImage(w, h, BufferedImage.TYPE_INT_RGB);
            Graphics2D g = dst.createGraphics();
            g.setColor(Color.WHITE);
            g.fillRect(0, 0, w, h);
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            g.drawImage(src, 0, 0, w, h, null);
            g.dispose();
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            ImageIO.write(dst, "png", out);
            pdfHeaderCache = out.toByteArray();
            return pdfHeaderCache;
        } catch (Exception e) {
            LOG.log(Level.WARNING, "[branding] could not load the header image", e);
            return null;
        }
    }

    /** The site's own address as the browser sees it (works behind Railway's proxy too), e.g. https://host/PInventory */
    public static String baseUrl(HttpServletRequest req) {
        String proto = req.getHeader("X-Forwarded-Proto");
        String host = req.getHeader("X-Forwarded-Host");
        if (proto == null || proto.isEmpty()) proto = req.getScheme();
        if (host == null || host.isEmpty()) {
            int port = req.getServerPort();
            boolean normal = ("http".equals(proto) && port == 80) || ("https".equals(proto) && port == 443);
            host = req.getServerName() + (normal ? "" : ":" + port);
        }
        return proto + "://" + host + req.getContextPath();
    }

    /** Full address of the banner, for the top of an e-mail. */
    public static String headerUrl(String baseUrl) {
        return baseUrl == null ? null : baseUrl + HEADER_URL_PATH;
    }

    /**
     * The banner as the first row of an HTML e-mail, or "" when no address is known.
     * An image link (not an attachment), so it shows in Gmail and Outlook with both Gmail and Brevo sending.
     */
    public static String emailHeaderHtml(String baseUrl) {
        String url = headerUrl(baseUrl);
        if (url == null) return "";
        return "<div style='text-align:center;margin:0 0 12px;'><img src='" + url.replace("'", "%27")
                + "' alt='Sandur Residential School' width='680' "
                + "style='display:block;width:100%;max-width:680px;height:auto;border:0;margin:0 auto;'></div>";
    }
}
