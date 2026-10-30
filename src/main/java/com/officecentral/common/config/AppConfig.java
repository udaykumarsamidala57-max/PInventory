package com.officecentral.common.config;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Passwords and other secret settings. They are NEVER written in the code, so nothing secret goes to git.
 *
 * Each setting is looked up in this order (first one found wins):
 *   1. environment variable                        - used on the cloud server (Railway variables)
 *   2. Java system property  -Dname=value
 *   3. settings file on this computer              - used on the local Tomcat
 *        PINVENTORY_CONFIG (env / -D) if set, otherwise  <user home>\pinventory.properties
 *        e.g. C:\Users\srsad\pinventory.properties
 *
 * Settings used by the app (database names stay in the code; where and how to log in does not):
 *   MYSQLHOST, MYSQLPORT, MYSQLUSER, MYSQLPASSWORD
 *        inventory / HR / admissions / assets / employee / service-request databases
 *   WEBSITE_SRS_DB_HOST, _PORT, _USER, _PASSWORD          website database (SRS)
 *   WEBSITE_SANPOLY_DB_HOST, _PORT, _USER, _PASSWORD      website database (Sanpoly)
 *   BUCKET, ACCESS_KEY_ID, SECRET_ACCESS_KEY, ENDPOINT, REGION   website photo bucket (optional)
 *   BREVO_API_KEY                 e-mail (OTP, pending indent report) through Brevo - needed on Railway
 *   GMAIL_USER, GMAIL_APP_PASSWORD  e-mail straight through Gmail, used when BREVO_API_KEY is not set
 *   MAIL_FROM (optional)          sender address shown on the e-mails
 *   FIREBASE_PROJECT_ID           Firebase project for Android push, defaults to office-central-erp
 *   FIREBASE_SERVICE_ACCOUNT_JSON (optional) service-account JSON supplied as a protected environment variable
 *   FIREBASE_SERVICE_ACCOUNT_FILE (optional) path to a protected service-account JSON file for local Tomcat
 *   SCHOOL_OPERATIONS_BASE_URL     School Operations app menu link (defaults to http://localhost:8083/)
 *   SCHOOL_OPERATIONS_SSO_SECRET   shared 32-byte HMAC key for sign-on and the signed mobile visitor bridge
 */
public final class AppConfig {

    private static volatile Properties local;

    private AppConfig() { }

    /** The value, or null when it is not set anywhere. */
    public static String get(String name) {
        String v = System.getenv(name);
        if (blank(v)) v = System.getProperty(name);
        if (blank(v)) v = localFile().getProperty(name);
        return blank(v) ? null : v.trim();
    }

    /** The value, or a clear error saying where to set it. */
    public static String require(String name) {
        String v = get(name);
        if (v == null) {
            throw new IllegalStateException(name + " is not set. Add the line  " + name + "=...  to "
                    + configFile().getAbsolutePath() + "  (local server) or set it as an environment variable (cloud).");
        }
        return v;
    }

    /** Same as require(), as an SQLException, for database settings. */
    public static String dbPassword(String name) throws java.sql.SQLException {
        try {
            return require(name);
        } catch (IllegalStateException e) {
            throw new java.sql.SQLException(e.getMessage());
        }
    }

    /**
     * Opens a MySQL connection to the given database, using the settings that start with the prefix:
     * prefix + HOST, PORT, USER, PASSWORD   e.g. connect("MYSQL", "HR") uses MYSQLHOST, MYSQLPORT, MYSQLUSER, MYSQLPASSWORD.
     */
    public static java.sql.Connection connect(String prefix, String database) throws java.sql.SQLException {
        String url = "jdbc:mysql://" + dbPassword(prefix + "HOST") + ":" + dbPassword(prefix + "PORT") + "/" + database
                + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&tcpKeepAlive=true";
        return java.sql.DriverManager.getConnection(url, dbPassword(prefix + "USER"), dbPassword(prefix + "PASSWORD"));
    }

    /** Where the local settings file is expected. */
    public static File configFile() {
        String p = System.getenv("PINVENTORY_CONFIG");
        if (blank(p)) p = System.getProperty("PINVENTORY_CONFIG");
        return blank(p) ? new File(System.getProperty("user.home"), "pinventory.properties") : new File(p.trim());
    }

    private static volatile long localStamp = -1;

    /** The settings file, read again whenever it is changed on disk (no restart needed). */
    private static Properties localFile() {
        File f = configFile();
        long stamp = f.isFile() ? f.lastModified() : 0;
        Properties p = local;
        if (p == null || stamp != localStamp) {
            p = new Properties();
            if (stamp != 0) {
                try (InputStream in = new FileInputStream(f)) {
                    p.load(in);
                } catch (IOException e) {
                    System.err.println("Could not read " + f + ": " + e.getMessage());
                }
            }
            local = p;
            localStamp = stamp;
        }
        return p;
    }

    private static boolean blank(String s) { return s == null || s.trim().isEmpty(); }
}
