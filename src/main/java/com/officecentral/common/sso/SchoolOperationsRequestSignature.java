package com.officecentral.common.sso;

import com.officecentral.common.config.AppConfig;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/** HMAC signing for the narrowly scoped PInventory ↔ School Operations server API. */
public final class SchoolOperationsRequestSignature {
    private SchoolOperationsRequestSignature() { }

    public static String sign(String method, String path, String timestamp, String body)
            throws GeneralSecurityException {
        String configured = AppConfig.require("SCHOOL_OPERATIONS_SSO_SECRET");
        if (!configured.matches("[0-9a-fA-F]{64}")) {
            throw new IllegalStateException("SCHOOL_OPERATIONS_SSO_SECRET must be 64 hexadecimal characters.");
        }
        String canonical = timestamp + "\n" + method + "\n" + path + "\n" + body;
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(HexFormat.of().parseHex(configured), "HmacSHA256"));
        return HexFormat.of().formatHex(mac.doFinal(canonical.getBytes(StandardCharsets.UTF_8)));
    }

    public static boolean verify(String method, String path, String timestamp, String signature, String body) {
        if (timestamp == null || signature == null || body == null || !signature.matches("[0-9a-fA-F]{64}")) return false;
        try {
            long issuedAt = Long.parseLong(timestamp);
            long now = Instant.now().getEpochSecond();
            if (issuedAt < now - 60 || issuedAt > now + 60) return false;
            String expected = sign(method, path, timestamp, body);
            return MessageDigest.isEqual(expected.getBytes(StandardCharsets.US_ASCII),
                    signature.toLowerCase(java.util.Locale.ROOT).getBytes(StandardCharsets.US_ASCII));
        } catch (RuntimeException | GeneralSecurityException ex) {
            return false;
        }
    }
}
