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
</head>
<body>
<%@ include file="header.jsp" %>

<div class="main-content">
    <div class="card">
        <h2 align="center">Issue Stock</h2>

        <h3 align="center">Approved Indents Pending Issue</h3>
        <table class="main-table">
            <thead>
                <tr>
                    <th>Indent No</th>
                    <th>Requested By</th>
                    <th>Department</th>
                    <th>Item</th>
                    <th>Qty Requested</th>
                    <th>UOM</th>
                    <th>Requested By</th>
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
                            <td>${i.UOM}</td>
                            <td>${i.requested_by}</td>
                            <td><input type="number" name="qtyIssued" min="0" max="${i.qty_requested}" step="0.01" required></td>
                            <td>
                                <input type="hidden" name="indentId" value="${i.indent_id}">
                                <input type="hidden" name="itemId" value="${i.item_id}">
                                <input type="submit" class="btn btn-green" value="Issue">
                            </td>
                        </form>
                    </tr>
                </c:forEach>
            </tbody>
        </table>

        <c:if test="${not empty message}">
            <p style="text-align:center; color:green;">${message}</p>
        </c:if>
    </div>
</div>

<jsp:include page="Footer.jsp" />
</body>
</html>
