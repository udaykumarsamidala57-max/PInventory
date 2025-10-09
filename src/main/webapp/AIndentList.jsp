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
    String dept = (String) sess.getAttribute("department");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>SRS System - Indent List</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-content">
    <div class="card">
        <h2>Indent List</h2>

        <% String errorMsg = (String) request.getAttribute("errorMsg");
           if (errorMsg != null) { %>
            <p class="error-msg"><%= errorMsg %></p>
        <% } %>

        <table class="main-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Indent No</th>
                    <th>Date</th>
                    <th>Item</th>
                    <th>Qty</th>
                    <th>Available Qty</th>
                    <th>UOM</th>
                    <th>Department</th>
                    <th>Requested By</th>
                    <th>Purpose</th>
                    <th>In-Charge Action</th>
                    <th>In-Charge Status</th>
                    <th>L1 Approved By</th>
                    <th>L1 Approved Date</th>
                    <th>Status</th>
                    <th>Final Approved Date</th>
                    <th>Next Step</th>
                    <th>Actions</th>
                    <th>View / Print</th>
                </tr>
            </thead>
            <tbody>
            <%
                List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
                if (indents != null && !indents.isEmpty()) {
                    for (IndentItemFull ind : indents) {
                        String status = ind.getStatus() != null ? ind.getStatus().trim() : "";
                        String I_Status = ind.getIstatus() != null ? ind.getIstatus().trim() : "";
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

                    <!-- In-Charge Action -->
                    <td>
                        <% if (("Incharge".equalsIgnoreCase(role) || "Global".equalsIgnoreCase(role)) 
                            && !"Approved".equalsIgnoreCase(I_Status) 
                            && !"Approved".equalsIgnoreCase(status)) { %>
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
                    <td><%= ind.getIndentNext() %></td>

                    <!-- Actions -->
                    <td>
                        <% if (!"Approved".equalsIgnoreCase(status) && !"Approved".equalsIgnoreCase(I_Status)) { %>
                            <form action="AIndentListServlet" method="post" style="margin-bottom:5px;">
                                <input type="hidden" name="id" value="<%= ind.getId() %>">
                                <input type="hidden" name="action" value="delete">
                                <button class="btn btn-red" type="submit" onclick="return confirm('Cancel this indent?')">Cancel</button>
                            </form>
                        <% } %>

                        <% if ("Global".equalsIgnoreCase(role) && "Approved".equalsIgnoreCase(I_Status) && !"Approved".equalsIgnoreCase(status)) { %>
                            <form action="AIndentListServlet" method="post">
                                <input type="hidden" name="id" value="<%= ind.getId() %>">
                                <input type="hidden" name="action" value="approve">
                                <select name="indentnext" required>
                                    <option value="">--Select Next Step--</option>
                                    <option value="Issue">Issue</option>
                                    <option value="PO">PO</option>
                                    <option value="Management Note">Management Note</option>
                                </select>
                                <button class="btn btn-green" type="submit">Final Approve</button>
                            </form>
                        <% } %>
                    </td>

                    <!-- View / Print -->
                    <td>
                        <form action="PrintIndent.jsp" method="get">
                            <input type="hidden" name="IndentNumber" value="<%= ind.getIndentNo() %>">
                            <button class="btn btn-info" type="submit">View / Print</button>
                        </form>
                    </td>
                </tr>
            <%
                    }
                } else {
            %>
                <tr>
                    <td colspan="19" style="text-align:center; color:red;">No records found</td>
                </tr>
            <% } %>
            </tbody>
        </table>
    </div>
</div>

<%@ include file="Footer.jsp" %>

</body>
</html>
