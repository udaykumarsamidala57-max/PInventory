package com.officecentral.inventory.stock;

import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;

/**
 * Returns the stock_ledger transactions behind one number on the Stock Ledger report
 * (stockReport.jsp) / Stock Report (Stock.jsp) as JSON, for the drill-down pop-up.
 *
 * GET /stock-ledger-detail?itemId=..&type=OPENING|RECEIPT|ISSUE|ALL&fromDate=yyyy-MM-dd&toDate=yyyy-MM-dd&fy=2025
 * Dates are limited to one financial year. fy (previous years) is honoured only for the Global role
 * or Finance department; everyone else always gets the current year.
 *
 * Data comes from StockLedgerDAO, which the mobile app also uses, so web and app always match.
 * Read-only; uses the logged-in user's store (session "branch").
 */
@WebServlet("/stock-ledger-detail")
public class StockLedgerDetailServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Gson GSON = new Gson();
    private final transient StockLedgerDAO dao = new StockLedgerDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            sendError(response, HttpServletResponse.SC_UNAUTHORIZED, "Session expired. Please log in again.");
            return;
        }
        String branch = (String) sess.getAttribute("branch");
        boolean canChoose = StockLedgerDAO.canChooseYear(
                (String) sess.getAttribute("role"), (String) sess.getAttribute("department"));

        int itemId;
        try {
            itemId = Integer.parseInt(request.getParameter("itemId"));
        } catch (NumberFormatException e) {
            sendError(response, HttpServletResponse.SC_BAD_REQUEST, "Invalid item.");
            return;
        }

        try {
            int fy = StockLedgerDAO.resolveFy(request.getParameter("fy"), canChoose);
            LocalDate[] range = StockLedgerDAO.parseRange(request.getParameter("fromDate"), request.getParameter("toDate"));
            Map<String, Object> result = dao.detail(branch, fy, itemId, request.getParameter("type"), range);
            StockLedgerDAO.putYearChoice(result, canChoose);
            response.getWriter().write(GSON.toJson(result));
        } catch (StockLedgerDAO.NotFound e) {
            sendError(response, HttpServletResponse.SC_NOT_FOUND, e.getMessage());
        } catch (StockLedgerDAO.BadRequest e) {
            sendError(response, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (SQLException e) {
            log("Stock ledger detail failed for item " + itemId, e);
            sendError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not load ledger details.");
        }
    }

    private static void sendError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        Map<String, String> err = new LinkedHashMap<>();
        err.put("error", message);
        response.getWriter().write(GSON.toJson(err));
    }
}
