package com.mobile;

/**
 * An error that is safe to show to the mobile user.
 * The HTTP status tells the app what kind of error it is
 * (400 bad input, 401 session expired, 403 not allowed, 404 not found, 409 conflict, 429 too many attempts).
 */
public class ApiException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    private final int status;

    public ApiException(int status, String message) {
        super(message);
        this.status = status;
    }

    public int getStatus() {
        return status;
    }
}
