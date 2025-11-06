<%@ page contentType="text/html; charset=UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
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
    <title>Issue Stock</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="CSS/Form.css">
    <style>
        body { font-family: 'Poppins', sans-serif; }
        .low-stock { color: red; font-weight: bold; }
        .ok-stock { color: green; font-weight: 600; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; border: 1px solid #ccc; text-align: center; }
        th { background: #4e73df; color: #fff; }
        input[type="number"], input[type="text"] { padding: 5px; text-align: right; }
        .btn-green { background: #1cc88a; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; }
        .btn-green:hover { background: #17a673; }
        .message { text-align:center; font-weight:bold; margin-top:10px; }
    </style>
</head>
<body>
<%@ include file="header.jsp" %>

<div class="main-content">
    <div class="card">
        <h2 align="center">Issue Stock</h2>
        <h3 align="center">Approved Indents Pending Issue</h3>

        <table>
            <thead>
                <tr>
                    <th>Indent No</th>
                    <th>Requested By</th>
                    <th>Department</th>
                    <th>Item</th>
                    <th>Qty Requested</th>
                    <th>Available Stock</th>
                    <th>UOM</th>
                    <th>Unit Price</th>
                    <th>Purpose</th>
                    <th>Qty To Issue</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach var="i" items="${indentList}">
                    <tr>
                        <form action="IssueServlet" method="post">
                            <td>${i.indent_no}</td>
                            <td>${i.requested_by}</td>
                            <td>${i.department}</td>
                            <td>${i.item_name}</td>
                            <td>${i.qty_requested}</td>
                            <td>
                                <c:choose>
                                    <c:when test="${i.available_stock lt i.qty_requested}">
                                        <span class="low-stock">${i.available_stock}</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="ok-stock">${i.available_stock}</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td>${i.UOM}</td>
                            <td><input type="text" name="unitPrice" value="${i.unit_price}"  style="width:80px;"></td>
                            <td>${i.purpose}</td>
                            <td><input type="number" name="qtyIssued" min="0" max="${i.qty_requested}" step="0.01" required></td>
                            <td>
                                <input type="hidden" name="indentId" value="${i.indent_id}">
                                <input type="hidden" name="itemId" value="${i.item_id}">
                                <input type="hidden" name="department" value="${i.department}">
                                <input type="submit" class="btn-green" value="Issue">
                            </td>
                        </form>
                    </tr>
                </c:forEach>
            </tbody>
        </table>

        <c:if test="${not empty message}">
            <p class="message" style="color:${message.startsWith('✅') ? 'green' : 'red'};">${message}</p>
        </c:if>
    </div>
</div>

<jsp:include page="Footer.jsp" />
</body>
</html>
