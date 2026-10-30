package com.officecentral.common.sso;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/** Issues short-lived, signed tickets for the School Operations single sign-on handoff. */
public final class SchoolOperationsSsoToken {
    private static final String AUDIENCE = "pinventory-school-operations";
    private static final SecureRandom RANDOM = new SecureRandom();

    private SchoolOperationsSsoToken() { }

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

        String encodedPayload = Base64.getUrlEncoder().withoutPadding().encodeToString(payload);
        byte[] signature = hmac(payload, secret);
        return encodedPayload + "." + Base64.getUrlEncoder().withoutPadding().encodeToString(signature);
    }

    private static byte[] hmac(byte[] payload, String secret) throws GeneralSecurityException {
        if (secret == null || !secret.matches("[0-9a-fA-F]{64}")) {
            throw new IllegalArgumentException("SCHOOL_OPERATIONS_SSO_SECRET must be 64 hexadecimal characters.");
        }
        byte[] key = HexFormat.of().parseHex(secret);
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(key, "HmacSHA256"));
        return mac.doFinal(payload);
    }
}
