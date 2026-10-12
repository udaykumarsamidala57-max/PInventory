package com.indent.controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil;
import com.google.gson.Gson;
import com.indent.bean.IndentBean;
import com.indent.bean.InventoryBean;

@WebServlet(urlPatterns = { "/indent/new", "/indent/create", "/indent/report", "/indent/approve" })
public class IndentController extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (!requireLogin(request, response, session)) return;
        request.setAttribute("csrfToken", csrfToken(session));

        String path = request.getServletPath();
        if ("/indent/new".equals(path)) {
            request.setAttribute("requestedBy", session.getAttribute("username"));
            request.getRequestDispatcher("/Indent/jsp/indent.jsp").forward(request, response);
            return;
        }

        if ("/indent/report".equals(path)) {
            request.setAttribute("indents", loadIndents(session, false));
            request.getRequestDispatcher("/Indent/jsp/indentReport.jsp").forward(request, response);
            return;
        }

        if ("/indent/approve".equals(path)) {
            if (!canApprove(session)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You are not allowed to approve indents.");
                return;
            }
            request.setAttribute("indents", loadIndents(session, true));
            request.getRequestDispatcher("/Indent/jsp/approveIndent.jsp").forward(request, response);
            return;
        }

        response.sendError(HttpServletResponse.SC_NOT_FOUND);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (!requireLogin(request, response, session)) return;
        String submittedToken = request.getParameter("csrfToken");
        Object expectedToken = session.getAttribute("indentCsrfToken");
        if (!(expectedToken instanceof String) || submittedToken == null
                || !MessageDigest.isEqual(((String) expectedToken).getBytes(StandardCharsets.UTF_8),
                        submittedToken.getBytes(StandardCharsets.UTF_8))) {
            writeJson(response, HttpServletResponse.SC_FORBIDDEN, false,
                    "Your session expired. Reload the page and try again.", null);
            return;
        }

        switch (request.getServletPath()) {
            case "/indent/create":
                createIndent(request, response, session);
                break;
            case "/indent/approve":
                approveIndent(request, response, session);
                break;
            default:
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void createIndent(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws IOException {
        int itemId;
        double quantity;
        try {
            itemId = Integer.parseInt(request.getParameter("itemId"));
            quantity = Double.parseDouble(request.getParameter("quantity"));
            if (itemId < 1 || !Double.isFinite(quantity) || quantity <= 0) {
                throw new IllegalArgumentException("Choose an item and enter a quantity above zero.");
            }
        } catch (RuntimeException ex) {
            writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false,
                    ex instanceof IllegalArgumentException ? ex.getMessage() : "Enter a valid item and quantity.", null);
            return;
        }

        String indentType = request.getParameter("indentType");
        if (!"Purchase".equals(indentType) && !"Issue".equals(indentType)) {
            writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false, "Choose Purchase or Issue.", null);
            return;
        }

        String branch = (String) session.getAttribute("branch");
        String username = (String) session.getAttribute("username");
        String department = (String) session.getAttribute("department");
        String purpose = clean(request.getParameter("purpose"), 500);
        Date requestDate = parseDate(request.getParameter("requestDate"));
        if (requestDate == null) {
            writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false, "Enter a valid request date.", null);
            return;
        }

        try (Connection connection = DBUtil.getConnection(branch)) {
            connection.setAutoCommit(false);
            try {
                InventoryBean item = findInventoryItem(connection, itemId);
                if (item == null) {
                    throw new IllegalArgumentException("The selected inventory item no longer exists.");
                }
                if ("Issue".equals(indentType) && quantity > item.getAvailableQuantity()) {
                    throw new IllegalArgumentException("Issue quantity exceeds available stock.");
                }

                int indentNumber = nextIndentNumber(connection);
                String sql = "INSERT INTO indent (indent_no, indent_date, item_id, item_name, qty, department, "
                        + "requested_by, purpose, remarks, uom, PurchaseorIssue, stock, status, Istatus) "
                        + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, '', ?, ?, ?, 'Pending', 'Pending')";
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    statement.setString(1, String.valueOf(indentNumber));
                    statement.setDate(2, requestDate);
                    statement.setInt(3, item.getItemId());
                    statement.setString(4, item.getItemName());
                    statement.setDouble(5, quantity);
                    statement.setString(6, department);
                    statement.setString(7, username);
                    statement.setString(8, purpose);
                    statement.setString(9, item.getUom());
                    statement.setString(10, indentType);
                    statement.setDouble(11, item.getAvailableQuantity());
                    statement.executeUpdate();
                }
                connection.commit();
                writeJson(response, HttpServletResponse.SC_CREATED, true, "Indent submitted.", indentNumber);
            } catch (IllegalArgumentException ex) {
                connection.rollback();
                writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false, ex.getMessage(), null);
            } catch (SQLException ex) {
                connection.rollback();
                throw ex;
            }
        } catch (SQLException ex) {
            getServletContext().log("Could not create indent.", ex);
            writeJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, false,
                    "Indent could not be saved. Contact the administrator.", null);
        }
    }

    private void approveIndent(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws IOException {
        if (!canApprove(session)) {
            writeJson(response, HttpServletResponse.SC_FORBIDDEN, false, "You are not allowed to approve indents.", null);
            return;
        }
        int indentId;
        try {
            indentId = Integer.parseInt(request.getParameter("indentId"));
        } catch (RuntimeException ex) {
            writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false, "Invalid indent selection.", null);
            return;
        }
        String decision = request.getParameter("decision");
        if (!"Approved".equals(decision) && !"Rejected".equals(decision)) {
            writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false, "Choose approve or reject.", null);
            return;
        }

        String sql = "UPDATE indent SET status=?, Istatus=?, IstausApprove=?, Iapprovedate=CURRENT_DATE "
                + "WHERE indent_id=? AND COALESCE(NULLIF(status,''), NULLIF(Istatus,''), 'Pending')='Pending'";
        try (Connection connection = DBUtil.getConnection((String) session.getAttribute("branch"));
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, decision);
            statement.setString(2, decision);
            statement.setString(3, (String) session.getAttribute("username"));
            statement.setInt(4, indentId);
            if (statement.executeUpdate() != 1) {
                writeJson(response, HttpServletResponse.SC_CONFLICT, false,
                        "This indent is no longer pending approval.", null);
                return;
            }
            writeJson(response, HttpServletResponse.SC_OK, true, "Indent " + decision.toLowerCase(Locale.ROOT) + ".", indentId);
        } catch (SQLException ex) {
            getServletContext().log("Could not update indent approval for " + indentId, ex);
            writeJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, false,
                    "The approval decision could not be saved.", null);
        }
    }

    private List<IndentBean> loadIndents(HttpSession session, boolean pendingOnly) throws ServletException {
        List<IndentBean> indents = new ArrayList<>();
        StringBuilder sql = new StringBuilder("SELECT indent_id, indent_no, item_id, item_name, qty, requested_by, "
                + "department, purpose, indent_date, COALESCE(NULLIF(status,''), NULLIF(Istatus,''), 'Pending') AS display_status "
                + "FROM indent WHERE 1=1 ");
        boolean privileged = canApprove(session);
        if (pendingOnly) {
            sql.append("AND COALESCE(NULLIF(status,''), NULLIF(Istatus,''), 'Pending')='Pending' ");
        } else if (!privileged) {
            sql.append("AND requested_by=? ");
        }
        sql.append("ORDER BY indent_id DESC LIMIT 1000");

        try (Connection connection = DBUtil.getConnection((String) session.getAttribute("branch"));
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            if (!pendingOnly && !privileged) statement.setString(1, (String) session.getAttribute("username"));
            try (ResultSet rows = statement.executeQuery()) {
                while (rows.next()) {
                    IndentBean indent = new IndentBean();
                    indent.setIndentId(rows.getInt("indent_id"));
                    indent.setIndentNo(rows.getString("indent_no"));
                    indent.setItemId(rows.getInt("item_id"));
                    indent.setItemName(rows.getString("item_name"));
                    indent.setQuantity(rows.getDouble("qty"));
                    indent.setRequestedBy(rows.getString("requested_by"));
                    indent.setDepartment(rows.getString("department"));
                    indent.setPurpose(rows.getString("purpose"));
                    indent.setStatus(rows.getString("display_status"));
                    indent.setRequestDate(rows.getDate("indent_date"));
                    indents.add(indent);
                }
            }
        } catch (SQLException ex) {
            throw new ServletException("Could not load indents.", ex);
        }
        return indents;
    }

    private InventoryBean findInventoryItem(Connection connection, int itemId) throws SQLException {
        String sql = "SELECT im.Item_id, im.Item_name, im.UOM, COALESCE(s.balance_qty,0) AS available_qty, "
                + "COALESCE(s.last_price,0) AS price FROM item_master im "
                + "LEFT JOIN stock s ON s.item_id=im.Item_id WHERE im.Item_id=?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, itemId);
            try (ResultSet row = statement.executeQuery()) {
                if (!row.next()) return null;
                BigDecimal price = row.getBigDecimal("price");
                return new InventoryBean(row.getInt("Item_id"), row.getString("Item_name"), row.getString("UOM"),
                        row.getDouble("available_qty"), price);
            }
        }
    }

    private int nextIndentNumber(Connection connection) throws SQLException {
        String select = "SELECT next_val FROM id_sequences WHERE seq_name='indent_no' FOR UPDATE";
        try (PreparedStatement statement = connection.prepareStatement(select);
             ResultSet row = statement.executeQuery()) {
            if (row.next()) {
                int next = row.getInt(1) + 1;
                try (PreparedStatement update = connection.prepareStatement(
                        "UPDATE id_sequences SET next_val=? WHERE seq_name='indent_no'")) {
                    update.setInt(1, next);
                    update.executeUpdate();
                }
                return next;
            }
        }

        int next;
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT COALESCE(MAX(CAST(indent_no AS UNSIGNED)),0)+1 FROM indent");
             ResultSet row = statement.executeQuery()) {
            row.next();
            next = row.getInt(1);
        }
        try (PreparedStatement insert = connection.prepareStatement(
                "INSERT INTO id_sequences (seq_name, next_val) VALUES ('indent_no', ?)")) {
            insert.setInt(1, next);
            insert.executeUpdate();
        }
        return next;
    }

    private boolean requireLogin(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws IOException {
        if (session != null && session.getAttribute("username") != null) return true;
        if ("XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"))) {
            writeJson(response, HttpServletResponse.SC_UNAUTHORIZED, false, "Please sign in again.", null);
        } else {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
        }
        return false;
    }

    private boolean canApprove(HttpSession session) {
        String role = (String) session.getAttribute("role");
        String department = (String) session.getAttribute("department");
        return "Global".equalsIgnoreCase(role) || "Admin".equalsIgnoreCase(role)
                || "Finance".equalsIgnoreCase(department) || "Store".equalsIgnoreCase(department);
    }

    private Date parseDate(String value) {
        if (value == null || value.trim().isEmpty()) return Date.valueOf(LocalDate.now());
        try {
            return Date.valueOf(LocalDate.parse(value));
        } catch (RuntimeException ex) {
            return null;
        }
    }

    private String clean(String value, int maxLength) {
        if (value == null) return "";
        String cleaned = value.trim();
        return cleaned.length() <= maxLength ? cleaned : cleaned.substring(0, maxLength);
    }

    private String csrfToken(HttpSession session) {
        Object existing = session.getAttribute("indentCsrfToken");
        if (existing instanceof String) return (String) existing;
        String token = java.util.UUID.randomUUID().toString();
        session.setAttribute("indentCsrfToken", token);
        return token;
    }

    private void writeJson(HttpServletResponse response, int status, boolean success, String message, Integer indentId)
            throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");
        String json = "{\"success\":" + success + ",\"message\":" + gson.toJson(message);
        if (indentId != null) json += ",\"indentId\":" + indentId;
        response.getWriter().write(json + "}");
    }
}
