package com.officecentral.common.mail;

import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Properties;

import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.InternetHeaders;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.officecentral.common.config.AppConfig;

/**
 * Sends the app's e-mails (login OTP, pending indent report).
 *
 * Which way is used depends on the settings (see AppConfig):
 *   BREVO_API_KEY set                     -> Brevo web API  (works on Railway, which blocks normal mail ports)
 *   otherwise GMAIL_USER + GMAIL_APP_PASSWORD set -> straight through Gmail (smtp.gmail.com, port 587)
 * GMAIL_APP_PASSWORD is a 16-letter Google "App password", not the normal Gmail password.
 * MAIL_FROM (optional) is the sender address; it defaults to GMAIL_USER.
 */
public final class Mailer {

    private static final String FROM_NAME = "SRS Central Admin";
    private static final String DEFAULT_FROM = "udaykumarsamidala57@gmail.com";

    private Mailer() { }

    /** Sends one HTML e-mail. attachmentName / attachment may be null. Throws with the reason if it fails. */
    public static void send(String to, String subject, String html, String attachmentName, byte[] attachment)
            throws Exception {
        String via = AppConfig.get("BREVO_API_KEY") != null ? "Brevo"
                   : AppConfig.get("GMAIL_APP_PASSWORD") != null ? "Gmail" : "none";
        try {
            sendNow(to, subject, html, attachmentName, attachment);
            log("SENT via " + via + " from " + from() + " to " + to + " : " + subject);
        } catch (Exception e) {
            log("FAILED via " + via + " from " + from() + " to " + to + " : " + e);
            throw e;
        }
    }

    /**
     * Keeps a short record of every e-mail try (never the key or password) in
     * <user home>/pinventory-mail.log, e.g. C:\\Users\\srsad\\pinventory-mail.log, so a failure reason can be read later.
     */
    private static synchronized void log(String line) {
        try {
            java.nio.file.Path f = java.nio.file.Paths.get(System.getProperty("user.home"), "pinventory-mail.log");
            String row = java.time.LocalDateTime.now().withNano(0) + "  " + line.replace('\n', ' ').replace('\r', ' ')
                    + System.lineSeparator();
            if (java.nio.file.Files.exists(f) && java.nio.file.Files.size(f) > 200_000) java.nio.file.Files.delete(f);
            java.nio.file.Files.write(f, row.getBytes(StandardCharsets.UTF_8),
                    java.nio.file.StandardOpenOption.CREATE, java.nio.file.StandardOpenOption.APPEND);
        } catch (Exception ignored) {
            // logging must never stop an e-mail
        }
        System.out.println("[mail] " + line);
    }

    private static void sendNow(String to, String subject, String html, String attachmentName, byte[] attachment)
            throws Exception {
        if (AppConfig.get("BREVO_API_KEY") != null) {
            sendViaBrevo(to, subject, html, attachmentName, attachment);
        } else if (AppConfig.get("GMAIL_APP_PASSWORD") != null) {
            sendViaGmail(to, subject, html, attachmentName, attachment);
        } else {
            throw new IllegalStateException("No e-mail service is set up. Add BREVO_API_KEY, or GMAIL_USER and "
                    + "GMAIL_APP_PASSWORD, to " + AppConfig.configFile().getAbsolutePath()
                    + " (local server) or to the cloud variables.");
        }
    }

    private static String from() {
        String f = AppConfig.get("MAIL_FROM");
        if (f == null) f = AppConfig.get("GMAIL_USER");
        return f == null ? DEFAULT_FROM : f;
    }

    // ---------------------------------------------------------------- Gmail
    private static void sendViaGmail(String to, String subject, String html, String attachmentName, byte[] attachment)
            throws Exception {
        final String user = AppConfig.require("GMAIL_USER");
        final String appPassword = AppConfig.require("GMAIL_APP_PASSWORD").replace(" ", "");

        Properties p = new Properties();
        p.put("mail.smtp.host", "smtp.gmail.com");
        p.put("mail.smtp.port", "587");
        p.put("mail.smtp.auth", "true");
        p.put("mail.smtp.starttls.enable", "true");
        p.put("mail.smtp.starttls.required", "true");
        p.put("mail.smtp.ssl.protocols", "TLSv1.2 TLSv1.3");
        p.put("mail.smtp.connectiontimeout", "15000");
        p.put("mail.smtp.timeout", "20000");

        Session session = Session.getInstance(p, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(user, appPassword);
            }
        });

        MimeMessage msg = new MimeMessage(session);
        msg.setFrom(new InternetAddress(from(), FROM_NAME, "UTF-8"));
        msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
        msg.setSubject(subject, "UTF-8");

        MimeBodyPart body = new MimeBodyPart();
        body.setContent(html, "text/html; charset=UTF-8");
        MimeMultipart parts = new MimeMultipart();
        parts.addBodyPart(body);
        if (attachment != null) {
            InternetHeaders h = new InternetHeaders();
            h.addHeader("Content-Type", "application/octet-stream");
            h.addHeader("Content-Transfer-Encoding", "base64");
            MimeBodyPart file = new MimeBodyPart(h, Base64.getMimeEncoder().encode(attachment));
            file.setFileName(attachmentName);
            parts.addBodyPart(file);
        }
        msg.setContent(parts);

        Transport.send(msg);
        System.out.println("E-mail sent through Gmail to " + to);
    }

    // ---------------------------------------------------------------- Brevo
    private static void sendViaBrevo(String to, String subject, String html, String attachmentName, byte[] attachment)
            throws Exception {
        JsonObject sender = new JsonObject();
        sender.addProperty("name", FROM_NAME);
        sender.addProperty("email", from());
        JsonObject rcpt = new JsonObject();
        rcpt.addProperty("email", to);
        JsonArray toList = new JsonArray();
        toList.add(rcpt);

        JsonObject body = new JsonObject();
        body.add("sender", sender);
        body.add("to", toList);
        body.addProperty("subject", subject);
        body.addProperty("htmlContent", html);
        if (attachment != null) {
            JsonObject file = new JsonObject();
            file.addProperty("content", Base64.getEncoder().encodeToString(attachment));
            file.addProperty("name", attachmentName);
            JsonArray files = new JsonArray();
            files.add(file);
            body.add("attachment", files);
        }

        HttpURLConnection conn = (HttpURLConnection) new URL("https://api.brevo.com/v3/smtp/email").openConnection();
        try {
            conn.setRequestMethod("POST");
            conn.setRequestProperty("accept", "application/json");
            conn.setRequestProperty("api-key", AppConfig.require("BREVO_API_KEY"));
            conn.setRequestProperty("content-type", "application/json");
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(20000);
            conn.setDoOutput(true);
            try (OutputStream os = conn.getOutputStream()) {
                os.write(body.toString().getBytes(StandardCharsets.UTF_8));
            }
            int code = conn.getResponseCode();
            if (code != 200 && code != 201 && code != 202) {
                InputStream es = conn.getErrorStream();
                String reason = es == null ? "" : new String(es.readAllBytes(), StandardCharsets.UTF_8);
                throw new IllegalStateException("Brevo answered " + code + ": " + reason);
            }
            System.out.println("E-mail sent through Brevo to " + to);
        } finally {
            conn.disconnect();
        }
    }
}
