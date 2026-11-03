package com.officecentral.common.sso;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/**
 * Issues short-lived, signed, single-use tickets for the PHRMS single sign-on handoff.
 * Same format as SchoolOperationsSsoToken, but a different audience and key, so a ticket for one app
 * can never be used to open the other.
 */
public final class PhrmsSsoToken {
    public static final String AUDIENCE = "pinventory-phrms";
    private static final SecureRandom RANDOM = new SecureRandom();

    private PhrmsSsoToken() { }

    public static String issue(String username, String secret) throws GeneralSecurityException {
        if (username == null || username.isBlank()) throw new IllegalArgumentException("Missing signed-in user.");
        long issuedAt = System.currentTimeMillis() / 1000L;
        byte[] nonce = new byte[32];
        RANDOM.nextBytes(nonce);

        byte[] payload;
        try (ByteArrayOutputStream bytes = new ByteArrayOutputStream();
             DataOutputStream data = new DataOutputStream(bytes)) {
            data.writeByte(1);
            data.writeUTF(AUDIENCE);
            data.writeLong(issuedAt);
            data.writeLong(issuedAt + 60L);
            data.writeUTF(username);
            data.write(nonce);
            data.flush();
            payload = bytes.toByteArray();
        } catch (java.io.IOException impossible) {
            throw new IllegalStateException("Could not create sign-on ticket.", impossible);
        }

        Base64.Encoder enc = Base64.getUrlEncoder().withoutPadding();
        return enc.encodeToString(payload) + "." + enc.encodeToString(hmac(payload, secret));
    }

    private static byte[] hmac(byte[] payload, String secret) throws GeneralSecurityException {
        if (secret == null || !secret.matches("[0-9a-fA-F]{64}")) {
            throw new IllegalArgumentException("PHRMS_SSO_SECRET must be 64 hexadecimal characters.");
        }
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(HexFormat.of().parseHex(secret), "HmacSHA256"));
        return mac.doFinal(payload);
    }
}
