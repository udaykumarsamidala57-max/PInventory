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
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Issue Stock</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Form.css">
<style>

body {
    font-family: 'Poppins', sans-serif;
    margin: 0;
    padding: 0;
    width: 100%;
    overflow-x: hidden;
    background: #f7f9fc;
}

.low-stock { 
    color: red; 
    font-weight: bold; 
}

.ok-stock { 
    color: green; 
    font-weight: 600; 
}

.main-content {
    width: 95%;
    max-width: 2000px;
    margin: 30px auto;
    padding: 10px;
}

.card {
    background: #fff;
    border-radius: 10px;
    padding: 20px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    width: 100%;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
    overflow-x: auto;
}

.card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 14px rgba(0,0,0,0.15);
}

h2, h3 {
    text-align: center;
    color: #333;
    margin: 10px 0;
}


table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 20px;
    font-size: 14px;
    table-layout: auto;
}

th, td {
    padding: 10px;
    border: 1px solid #ccc;
    text-align: center;
    vertical-align: middle;
    word-wrap: break-word;
}
thead{
background: linear-gradient(135deg, #ff8c00, #8e2de2);
}
th {
    
    color: #fff;
    font-weight: 600;
}

input[type="number"],
input[type="text"] {
    padding: 6px;
    text-align: right;
    width: 90px;
    border: 1px solid #ccc;
    border-radius: 4px;
    font-family: inherit;
    font-size: 13px;
}

.btn-green {
    background: #1cc88a;
    color: white;
    border: none;
    padding: 7px 14px;
    border-radius: 4px;
    cursor: pointer;
    font-family: inherit;
    transition: 0.3s;
}

.btn-green:hover {
    background: #17a673;
}

.message {
    text-align: center;
    font-weight: bold;
    margin-top: 15px;
}


@media (max-width: 1024px) {
    .main-content {
        width: 96%;
        margin: 20px auto;
    }

    table {
        font-size: 13px;
    }

    th, td {
        padding: 8px;
    }

    input[type="number"], input[type="text"] {
        width: 80px;
    }
}


@media (max-width: 768px) {
    .card {
        padding: 15px;
    }

    table, thead, tbody, th, td, tr {
        display: block;
        width: 100%;
    }

    thead tr {
        display: none;
    }

    tr {
        margin-bottom: 15px;
        border: 1px solid #ddd;
        border-radius: 10px;
        background: #fff;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        padding: 10px;
    }

    td {
        text-align: right;
        padding: 8px 10px;
        position: relative;
        border: none;
        border-bottom: 1px solid #eee;
        font-size: 14px;
    }

    td:before {
        content: attr(data-label);
        position: absolute;
        left: 10px;
        width: 50%;
        font-weight: 600;
        text-align: left;
        color: #333;
        white-space: nowrap;
    }

    input[type="number"],
    input[type="text"] {
        width: 100%;
        text-align: right;
        padding: 6px;
        font-size: 14px;
    }

    .btn-green {
        width: 100%;
        padding: 10px;
        font-size: 15px;
        margin-top: 5px;
    }

    .message {
        font-size: 14px;
    }
}


@media (max-width: 480px) {
    body {
        font-size: 13px;
    }

    h2, h3 {
        font-size: 16px;
    }

    td {
        font-size: 13px;
    }

    input[type="number"],
    input[type="text"] {
        font-size: 13px;
        padding: 5px;
    }

    .btn-green {
        font-size: 14px;
        padding: 8px;
    }
}
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-content">
    <div class="card">
        <h2>Issue Stock</h2>
        <h3>Approved Indents Pending Issue</h3>

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
                            <td data-label="Indent No">${i.indent_no}</td>
                            <td data-label="Requested By">${i.requested_by}</td>
                            <td data-label="Department">${i.department}</td>
                            <td data-label="Item">${i.item_name}</td>
                            <td data-label="Qty Requested">${i.qty_requested}</td>
                            <td data-label="Available Stock">
                                <c:choose>
                                    <c:when test="${i.available_stock lt i.qty_requested}">
                                        <span class="low-stock">${i.available_stock}</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="ok-stock">${i.available_stock}</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td data-label="UOM">${i.UOM}</td>
                            <td data-label="Unit Price">
                                <input type="text" name="unitPrice" value="${i.unit_price}">
                            </td>
                            <td data-label="Purpose">${i.purpose}</td>
                            <td data-label="Qty To Issue">
                                <input type="number" name="qtyIssued" min="0" max="${i.qty_requested}" step="0.01" required>
                            </td>
                            <td data-label="Action">
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

</body>
</html>
