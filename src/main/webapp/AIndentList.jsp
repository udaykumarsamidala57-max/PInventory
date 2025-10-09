<%@ page import="java.util.*, com.bean.IndentItemFull" %>
<%@ page import="javax.servlet.http.HttpSession" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String user = (String) sess.getAttribute("username");
    String role = (String) sess.getAttribute("role");
    Map<Integer, Double> pendingMap = (Map<Integer, Double>) request.getAttribute("pendingPerItem");
    if (pendingMap == null) pendingMap = new HashMap<>();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Indent List</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">
    <style>
        body { font-family: 'Poppins', sans-serif; }

        .highlight-cell { background-color: #fff3cd; }
        .btn-orange { background-color: #ff9800; color: white; border: none; padding: 6px 10px; border-radius: 4px; cursor: pointer; }

        /* Modern centered popup modal */
        .modal-overlay {
            position: fixed;
            top: 0; left: 0;
            width: 100%; height: 100%;
            background: rgba(0,0,0,0.5);
            display: none;
            justify-content: center;
            align-items: center;
            z-index: 1000;
        }

        .modal {
            background: white;
            border-radius: 12px;
            width: 460px;
            padding: 20px;
            text-align: center;
            box-shadow: 0 8px 25px rgba(0,0,0,0.2);
            animation: fadeIn 0.25s ease;
        }

        .modal h3 {
            color: #333;
            font-weight: 600;
            margin-bottom: 18px;
        }

        .modal p {
            color: #555;
            font-size: 24px;
            margin-bottom: 20px;
        }

        .modal button {
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 6px;
            padding: 8px 18px;
            font-weight: 500;
            cursor: pointer;
            transition: background 0.3s ease;
        }

        .modal button:hover {
            background-color: #0056b3;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: scale(0.9); }
            to { opacity: 1; transform: scale(1); }
        }
    </style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-content">
    <div class="card">
        <h2>Indent List</h2>

        <% String errorMsg = (String) request.getAttribute("errorMsg");
           if (errorMsg != null) { %>
            <script>
                document.addEventListener("DOMContentLoaded", function() {
                    showPopup("<%= errorMsg.replace("\"","\\\"") %>");
                });
            </script>
        <% } %>

        <table class="main-table">
            <thead>
                <tr>
                    <th>ID</th><th>Indent No</th><th>Date</th><th>Item</th><th>Qty</th><th>Available Qty</th>
                    <th>UOM</th><th>Department</th><th>Requested By</th><th>Purpose</th>
                    <th>In-Charge Action</th><th>In-Charge Status</th>
                    <th>L1 Approved By</th><th>L1 Approved Date</th>
                    <th>Status</th><th>Final Approved Date</th><th>Next Step</th><th>Actions</th><th>View/Print</th>
                </tr>
            </thead>
            <tbody>
            <%
                List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
                if (indents != null && !indents.isEmpty()) {
                    for (IndentItemFull ind : indents) {
                        String status = ind.getStatus() != null ? ind.getStatus().trim() : "";
                        String I_Status = ind.getIstatus() != null ? ind.getIstatus().trim() : "";
                        String next = ind.getIndentNext() != null ? ind.getIndentNext().trim() : "";
                        Integer itemId = ind.getItemId();
                        double pending = 0.0;
                        if (itemId != null && pendingMap.get(itemId) != null) pending = pendingMap.get(itemId);
            %>
                <tr>
                    <td><%= ind.getId() %></td>
                    <td><%= ind.getIndentNo() %></td>
                    <td><%= ind.getDate() %></td>
                    <td><%= ind.getItemName() %></td>
                    <td><%= ind.getQty() %></td>
                    <td><%= ind.getBalanceQty() %></td>
                    <td><%= ind.getUom() %></td>
                    <td><%= ind.getDepartment() %></td>
                    <td><%= ind.getRequestedBy() %></td>
                    <td><%= ind.getPurpose() %></td>

                    <!-- In-Charge -->
                    <td>
                        <% if (("Incharge".equalsIgnoreCase(role) || "Global".equalsIgnoreCase(role)) &&
                            !"Approved".equalsIgnoreCase(I_Status) && !"Approved".equalsIgnoreCase(status)) { %>
                            <form action="AIndentListServlet" method="post">
                                <input type="hidden" name="id" value="<%= ind.getId() %>">
                                <input type="hidden" name="action" value="Iapprove">
                                <button class="btn btn-green" type="submit">Approve</button>
                            </form>
                        <% } %>
                    </td>

                    <td><%= I_Status %></td>
                    <td><%= ind.getApprovedBy() %></td>
                    <td><%= ind.getIapprovevdate() %></td>
                    <td><%= status %></td>
                    <td><%= ind.getFapprovevdate() %></td>
                    <td><%= next %></td>

                    <!-- Final Approval -->
                    <td class="<%= (!"Issue".equalsIgnoreCase(next) && !"Approved".equalsIgnoreCase(status)) ? "highlight-cell" : "" %>">
                        <% if ("Global".equalsIgnoreCase(role) && "Approved".equalsIgnoreCase(I_Status)
                                && !"Approved".equalsIgnoreCase(status)) { %>
                            <form action="AIndentListServlet" method="post"
                                  data-qty="<%= ind.getQty() %>"
                                  data-balance="<%= ind.getBalanceQty() %>"
                                  data-pending="<%= pending %>"
                                  onsubmit="return validateApprovalForm(this)">
                                <input type="hidden" name="id" value="<%= ind.getId() %>">
                                <input type="hidden" name="action" value="approve">

                                <select name="indentnext" required>
                                    <option value="">--Select Next Step--</option>
                                    <option value="Issue" <%= "Issue".equalsIgnoreCase(next)?"selected":"" %>>Issue</option>
                                    <option value="PO" <%= "PO".equalsIgnoreCase(next)?"selected":"" %>>PO</option>
                                    <option value="Management Note" <%= "Management Note".equalsIgnoreCase(next)?"selected":"" %>>Management Note</option>
                                </select>
                                <button class="btn-orange" type="submit">Final Approve</button>
                            </form>
                        <% } %>
                    </td>

                    <td>
                        <form action="PrintIndent.jsp" method="get">
                            <input type="hidden" name="IndentNumber" value="<%= ind.getIndentNo() %>">
                            <button class="btn btn-info" type="submit">View/Print</button>
                        </form>
                    </td>
                </tr>
            <% } } else { %>
                <tr><td colspan="19" style="text-align:center;">No records found</td></tr>
            <% } %>
            </tbody>
        </table>
    </div>
</div>

<%@ include file="Footer.jsp" %>

<!-- Modern Modal Popup -->
<div class="modal-overlay" id="popupOverlay">
  <div class="modal" id="popupBox">
    <h3 id="popupTitle">Notice</h3>
    <p id="popupMessage"></p>
    <button id="popupOkBtn">OK</button>
  </div>
</div>


<script>
let formToSubmit = null; // hold which form to submit after OK

function showPopup(msg, form = null) {
    document.getElementById("popupMessage").innerText = msg;
    document.getElementById("popupOverlay").style.display = "flex";
    formToSubmit = form;
}

function closePopup() {
    document.getElementById("popupOverlay").style.display = "none";
    if (formToSubmit) {
        formToSubmit.submit();
        formToSubmit = null;
    }
}

/* Attach OK button click event */
document.getElementById("popupOkBtn").addEventListener("click", closePopup);

/* Handles validation + popup display */
function validateApprovalForm(form) {
    const qty = parseFloat(form.dataset.qty) || 0;
    const balance = parseFloat(form.dataset.balance) || 0;
    const pending = parseFloat(form.dataset.pending) || 0;
    const next = form.querySelector('select[name="indentnext"]').value;

    if (next === "Issue") {
        if ((pending + qty) > balance) {
            showPopup(
                "Stock not available.\n\nAvailable: " + balance +
                "\nPending issue qty: " + pending +
                "\nRequested: " + qty
            );
            return false;
        } else {
            showPopup("Indent moved to Issue section and will be approved.", form);
            return false;
        }
    } else if (next === "PO") {
        showPopup("Indent moved to Purchase Order section.", form);
        return false;
    } else if (next === "Management Note") {
        showPopup("Indent moved to Management Note section.", form);
        return false;
    } else {
        showPopup("Please select next step.");
        return false;
    }
}
</script>

</body>
</html>
