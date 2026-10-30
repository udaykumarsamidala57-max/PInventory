package com.mobile;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.officecentral.common.config.AppConfig;
import com.officecentral.common.sso.SchoolOperationsRequestSignature;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/** Calls the School Operations visitor endpoint with the authenticated Android account identity. */
final class SchoolOperationsMobileClient {
    private static final String PATH = "/api/internal/mobile/visitor-decision";
    private static final HttpClient HTTP = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(4)).build();
    private static final ObjectMapper JSON = new ObjectMapper();

    private SchoolOperationsMobileClient() { }

    /** decision is WAIT, APPROVE or REJECT (validated by the caller). */
    static Map<String, Object> decide(int userId, long visitorId, String decision, String rejectionReason) {
        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("userId", userId);
            payload.put("visitorId", visitorId);
            // No "approved" field: an older School Operations build rejects WAIT as incomplete instead of treating it as Reject.
            payload.put("decision", decision);
            payload.put("rejectionReason", rejectionReason == null ? "" : rejectionReason);
            String body = JSON.writeValueAsString(payload);
            String timestamp = String.valueOf(Instant.now().getEpochSecond());
            String signature = SchoolOperationsRequestSignature.sign("POST", PATH, timestamp, body);
            HttpRequest request = HttpRequest.newBuilder(endpoint())
                    .timeout(Duration.ofSeconds(8))
                    .header("Content-Type", "application/json")
                    .header("X-School-Operations-Timestamp", timestamp)
                    .header("X-School-Operations-Signature", signature)
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();
            HttpResponse<String> response = HTTP.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 404 || response.statusCode() == 409) {
                throw new ApiException(404, "This request is no longer waiting or does not belong to your account.");
            }
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new ApiException(503, "School Operations could not process the visitor response. Try again.");
            }
            JsonNode result = JSON.readTree(response.body());
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("status", result.path("status").asText(
                    "APPROVE".equals(decision) ? "APPROVED" : "REJECT".equals(decision) ? "REJECTED" : "WAITING"));
            return out;
        } catch (ApiException ex) {
            throw ex;
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            throw new ApiException(503, "School Operations is unavailable. Try again.");
        } catch (Exception ex) {
            throw new ApiException(503, "School Operations is unavailable. Try again.");
        }
    }

    private static URI endpoint() {
        String base = AppConfig.get("SCHOOL_OPERATIONS_BASE_URL");
        if (base == null || base.isBlank()) base = "http://localhost:8083/";
        if (!base.endsWith("/")) base += "/";
        URI uri = URI.create(base);
        String scheme = uri.getScheme();
        String host = uri.getHost();
        boolean loopback = "localhost".equalsIgnoreCase(host) || "127.0.0.1".equals(host) || "::1".equals(host);
        if (host == null || uri.getUserInfo() != null || uri.getRawQuery() != null || uri.getRawFragment() != null
                || !("https".equalsIgnoreCase(scheme) || ("http".equalsIgnoreCase(scheme) && loopback))) {
            throw new IllegalArgumentException("School Operations must use HTTPS, except for local loopback development.");
        }
        return uri.resolve(PATH.substring(1));
    }
}
