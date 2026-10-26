package com.officecentral.common.web;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/**
 * One CSRF token per login session.
 *
 * header.jsp adds it automatically to every POST form (hidden field {@value #PARAM}) and to every
 * same-site fetch() that changes data (HTTP header {@value #HEADER}). AccessFilter checks it.
 */
public final class Csrf {

    public static final String PARAM = "_csrf";
    public static final String HEADER = "X-CSRF-Token";
    private static final String KEY = "csrfToken";
    private static final SecureRandom RANDOM = new SecureRandom();

    private Csrf() { }

    /** The session's token (created on first use). */
    public static String token(HttpSession s) {
        synchronized (s) {
            Object t = s.getAttribute(KEY);
            if (t == null) {
                byte[] b = new byte[32];
                RANDOM.nextBytes(b);
                t = Base64.getUrlEncoder().withoutPadding().encodeToString(b);
                s.setAttribute(KEY, t);
            }
            return (String) t;
        }
    }

    /**
     * True when the request carries the session's token, in the header (checked first, so a JSON or
     * fetch body is never read here) or in the {@value #PARAM} form field.
     */
    public static boolean valid(HttpServletRequest req, HttpSession s) {
        Object expected = s.getAttribute(KEY);
        if (expected == null) return false;
        String given = req.getHeader(HEADER);
        if (given == null || given.isEmpty()) given = req.getParameter(PARAM);
        return given != null && MessageDigest.isEqual(
                ((String) expected).getBytes(StandardCharsets.UTF_8), given.getBytes(StandardCharsets.UTF_8));
    }
}
