package com.controller.Admissions;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.officecentral.common.sso.DirectorApi;

/**
 * POST /api/director/admission-status  (signed by the Director Portal; body: user, enquiryId, status=Selected|Rejected)
 * Same rule and code as the Approve / Reject buttons on Approve Admission: UpdateAdmissionStatusServlet.mayDecide()
 * and UpdateAdmissionStatusServlet.setStatus().
 */
@WebServlet("/api/director/admission-status")
public class DirectorAdmissionApiServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(DirectorAdmissionApiServlet.class.getName());

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Map<String, String> f = DirectorApi.verified(req, resp);
        if (f == null) return;
        String id = f.getOrDefault("enquiryId", "").trim();
        String status = f.get("status");
        if (!id.matches("\\d{1,9}") || !UpdateAdmissionStatusServlet.DECISIONS.contains(status)) {
            DirectorApi.reply(resp, 400, false, "Invalid request.");
            return;
        }
        try {
            DirectorApi.User u = DirectorApi.user(f.get("user"));
            if (u == null || !UpdateAdmissionStatusServlet.mayDecide(u.username, u.role)) {
                DirectorApi.reply(resp, 403, false, "You do not have permission to approve admissions.");
                return;
            }
            int rows = UpdateAdmissionStatusServlet.setStatus(Integer.parseInt(id), status);
            if (rows == 0) {
                DirectorApi.reply(resp, 404, false, "This admission enquiry no longer exists.");
                return;
            }
            LOG.info("[admission] " + status + " enquiry " + id + " by " + u.username + " (Director Portal)");
            DirectorApi.reply(resp, 200, true, "Selected".equals(status) ? "Candidate selected." : "Candidate rejected.");
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Director Portal admission decision failed", e);
            DirectorApi.reply(resp, 500, false, "The decision was not saved. Please try again.");
        }
    }
}
