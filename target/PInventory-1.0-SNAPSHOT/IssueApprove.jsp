<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.*, com.bean.IndentItemFull" %>
<!DOCTYPE html>
<html>
<head>
    <title>Issue Approve</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <!-- Google Font -->
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">

    <!-- Internal Modern Table CSS -->
    <style>
        body {
            font-family: 'Poppins', sans-serif;
            background: #f7f9fc;
            color: #333;
        }

        .page-content {
            padding: 30px;
            margin-left: 240px; /* space for sidebar from header.jsp */
        }

        h2.page-title {
            font-size: 22px;
            font-weight: 600;
            color: #1f2937;
            margin-bottom: 25px;
            text-align: left;
        }

        /* ===== Table Styling ===== */
        table {
            width: 100%;
            border-collapse: collapse;
            background: #ffffff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
        }

        th {
            background: #2563eb;
            color: #fff;
            padding: 12px 10px;
            text-align: left;
            font-weight: 600;
            font-size: 14px;
        }

        td {
            padding: 12px 10px;
            border-bottom: 1px solid #e5e7eb;
            font-size: 14px;
            color: #374151;
        }

        tr:hover {
            background: #f1f5f9;
            transition: background 0.3s;
        }

        /* ===== Buttons ===== */
        .btn {
            background: #16a34a;
            color: white;
            border: none;
            padding: 7px 14px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 500;
            transition: background 0.3s;
        }

        .btn:hover {
            background: #15803d;
        }

        .btn:disabled {
            background: #9ca3af;
            cursor: not-allowed;
        }

        /* ===== Error Message ===== */
        .error-msg {
            color: #dc2626;
            font-weight: 500;
            margin-bottom: 15px;
        }

        /* ===== Responsive ===== */
        @media (max-width: 768px) {
            .page-content {
                margin-left: 0;
                padding: 15px;
            }

            table, th, td {
                font-size: 13px;
            }

            h2.page-title {
                font-size: 18px;
                text-align: center;
            }
        }
    </style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="page-content">
    <h2 class="page-title">Approved Indents Ready for Issue</h2>

    <% 
        String errorMsg = (String) request.getAttribute("errorMsg");
        if (errorMsg != null) { 
    %>
        <p class="error-msg"><%= errorMsg %></p>
    <% } %>

    <table>
        <tr>
            <th>Indent No</th>
            <th>Date</th>
            <th>Item Name</th>
            <th>Balance Qty</th>
            <th>Required Qty</th>
            <th>Department</th>
            <th>Approved By</th>
            <th>Status</th>
            <th>Next</th>
            <th>Action</th>
        </tr>

        <%
            List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
            if (indents != null && !indents.isEmpty()) {
                for (IndentItemFull ind : indents) {
        %>
        <tr>
            <td><%= ind.getIndentNo() %></td>
            <td><%= ind.getDateStr() %></td>
            <td><%= ind.getItemName() %></td>
            <td><%= ind.getBalanceQty() %></td>
            <td><%= ind.getQty() %></td>
            <td><%= ind.getDepartment() %></td>
            <td><%= ind.getApprovedBy() %></td>
            <td><%= ind.getStatus() %></td>
            <td><%= ind.getIndentNext() %></td>
            <td>
                <form method="post" action="IssueApprove">
                    <input type="hidden" name="id" value="<%= ind.getId() %>">
                    <input type="hidden" name="action" value="approve">
                    <button type="submit" class="btn"
                        <%= "Issue".equalsIgnoreCase(ind.getIndentNext()) ? "disabled" : "" %>>Approve</button>
                </form>
            </td>
        </tr>
        <% } } else { %>
        <tr>
            <td colspan="10" style="text-align:center; padding:20px;">No records found</td>
        </tr>
        <% } %>
    </table>
</div>

<%@ include file="Footer.jsp" %>
</body>
</html>
