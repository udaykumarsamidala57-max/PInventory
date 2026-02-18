<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.bean.IndentItems" %>
<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Purchase Order</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">
    <style>
       
        body {
            margin: 0;
            padding: 0;
            font-family: 'Poppins', sans-serif;
            background-color: #f8f9fa;
        }

        .main-content {
            margin: 0;
            padding: 0;
            width: 100%;
            display: flex;
            justify-content: center;
            align-items: flex-start;
            min-height: calc(100vh - 60px); /* Adjust for header height */
        }

        .card {
            width: 95%;
            background: #fff;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            padding: 15px;
            margin-top: 0; /* No top gap */
        }

        h1 {
            text-align: center;
            color: #333;
            margin: 10px 0 20px 0;
        }

        table.main-table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }
        thead{
            background:   #0f2a4d; 
        }

        th, td {
            text-align: center;
            padding: 10px;
            border-bottom: 1px solid #ddd;
        }

        th {
            
            color: white;
        }

        tr:hover {
            background-color: #f1f1f1;
        }

        input[type="submit"] {
            background-color: #007bff;
            border: none;
            color: white;
            padding: 10px 16px;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 600;
        }

        input[type="submit"]:hover {
            background-color: #0056b3;
        }

        @media (max-width: 768px) {
            .card {
                width: 98%;
                padding: 10px;
            }

            th, td {
                font-size: 13px;
                padding: 8px;
            }
        }
    </style>
</head>
<body>
<%@ include file="header.jsp" %>

<div class="main-content">
    <div class="card">
        <h1>Create Purchase Order</h1>

        <form method="get" action="<%=request.getContextPath()%>/PurchaseOrderServlet">
            <table class="main-table">
                <thead>
                    <tr>
                        <th>Select</th>
                        <th>ID</th>
                        <th>Indent No</th>
                        <th>Date</th>
                        <th>Item</th>
                        <th>Quantity</th>
                        <th>Department</th>
                        <th>Requested By</th>
                        <th>Purpose</th>
                        <th>Istatus</th>
                        <th>Approved By</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                <%
                List<IndentItems> indentList = (List<IndentItems>) request.getAttribute("indentList");
                if (indentList != null && !indentList.isEmpty()) {
                    for (IndentItems ind : indentList) {
                %>
                <tr>
                    <td><input type="checkbox" name="selectedIds" value="<%= ind.getId() %>"></td>
                    <td><%= ind.getId() %></td>
                    <td><%= ind.getIndentNo() %></td>
                    <td><%= ind.getIndentDate() %></td>
                    <td><%= ind.getItemName() %></td>
                    <td><%= ind.getQty() %></td>
                    <td><%= ind.getDepartment() %></td>
                    <td><%= ind.getRequestedBy() %></td>
                    <td><%= ind.getPurpose() %></td>
                    <td><%= ind.getIstatus() %></td>
                    <td><%= ind.getIstatusApprove() %></td>
                    <td><%= ind.getStatus() %></td>
                </tr>
                <%
                    }
                } else {
                %>
                <tr>
                    <td colspan="13" style="color:red; text-align:center;">No records found</td>
                </tr>
                <%
                }
                %>
                </tbody>
                <tr>
                    <td colspan="13" style="text-align:center;">
                        <input type="submit" value="Process Selected Indents">
                    </td>
                </tr>
            </table>
        </form>
    </div>
</div>

</body>
</html>
