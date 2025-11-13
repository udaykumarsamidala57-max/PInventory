<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
%>
<%
    Connection conn = null;
    PreparedStatement ps = null, psCat = null;
    ResultSet rs = null, rsCat = null;

    String toDate = request.getParameter("toDate");
    String category = request.getParameter("category");

    if (toDate == null || toDate.trim().isEmpty()) {
        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
        toDate = sdf.format(new java.util.Date());
    }

    try {
        conn = DBUtil.getConnection();

        String catSql = "SELECT DISTINCT Category FROM item_master WHERE Category IS NOT NULL AND Category <> '' ORDER BY Category";
        psCat = conn.prepareStatement(catSql);
        rsCat = psCat.executeQuery();

        String sql = "SELECT im.Item_id, im.Item_name, im.Category, " +
                     "COALESCE(SUM(CASE WHEN sl.trans_type = 'RECEIPT' AND sl.trans_date <= ? THEN sl.qty END), 0) AS total_receipts, " +
                     "COALESCE(SUM(CASE WHEN sl.trans_type = 'ISSUE' AND sl.trans_date <= ? THEN sl.qty END), 0) AS total_issues, " +
                     "(COALESCE(SUM(CASE WHEN sl.trans_type = 'RECEIPT' AND sl.trans_date <= ? THEN sl.qty END), 0) - " +
                     "COALESCE(SUM(CASE WHEN sl.trans_type = 'ISSUE' AND sl.trans_date <= ? THEN sl.qty END), 0)) AS closing_balance " +
                     "FROM stock_ledger sl JOIN item_master im ON sl.item_id = im.Item_id ";

        if (category != null && !category.trim().isEmpty() && !category.equals("ALL")) {
            sql += "WHERE im.Category = ? ";
        }

        sql += "GROUP BY im.Item_id, im.Item_name, im.Category ORDER BY im.Category, im.Item_name";

        ps = conn.prepareStatement(sql);
        ps.setString(1, toDate);
        ps.setString(2, toDate);
        ps.setString(3, toDate);
        ps.setString(4, toDate);
        if (category != null && !category.trim().isEmpty() && !category.equals("ALL")) {
            ps.setString(5, category);
        }

        rs = ps.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
    <title>Stock Summary Report</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">

    <style>
        body {
            font-family: 'Poppins', sans-serif;
            background-color: #f7f9fc;
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* ✅ Reset unwanted header spacing */
        header, .header, #header, .topbar {
            margin: 0 !important;
            padding: 0 !important;
        }

        h2 {
            text-align: center;
            color: #333;
            margin: 10px 0 20px 0;
        }

        /* ✅ Remove top & side gap, center perfectly */
        .main-content {
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: flex-start;
            width: 100%;
            padding: 0;
            margin: 0 auto;
            box-sizing: border-box;
        }

        /* ✅ Card full-width centered with no outer gap */
        .card {
            background: #fff;
            border-radius: 8px;
            padding: 15px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            width: 80%;
            min-height: 75vh;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            justify-content: flex-start;
        }

        form {
            text-align: center;
            margin-bottom: 20px;
            display: flex;
            flex-wrap: wrap;
            justify-content: center;
            align-items: center;
            gap: 10px;
        }

        label {
            font-weight: 600;
        }

        input[type="date"], select {
            padding: 6px 10px;
            border-radius: 6px;
            border: 1px solid #ccc;
            background: #fff;
        }

        input[type="submit"] {
            background-color: #007bff;
            color: white;
            border: none;
            padding: 7px 14px;
            border-radius: 6px;
            cursor: pointer;
            transition: 0.3s;
        }

        input[type="submit"]:hover {
            background-color: #0056b3;
        }

        .table-container {
            width: 100%;
            overflow-x: auto;
            flex-grow: 1;
        }

        .main-table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            min-width: 600px;
        }

        th, td {
            padding: 10px;
            border-bottom: 1px solid #ddd;
            text-align: center;
        }

        th {
            background-color: #007bff;
            color: white;
            position: sticky;
            top: 0;
            z-index: 2;
        }

        tr:hover {
            background-color: #f1f1f1;
        }

        /* ✅ Responsive adjustments */
        @media (max-width: 1024px) {
            .card {
                width: 90%;
                padding: 12px;
                min-height: 75vh;
            }
        }

        @media (max-width: 768px) {
            .main-content {
                padding: 0;
            }

            .card {
                width: 95%;
                padding: 10px;
                min-height: 75vh;
            }

            form {
                flex-direction: column;
                align-items: stretch;
            }

            h2 {
                font-size: 18px;
            }

            th, td {
                font-size: 13px;
                padding: 8px;
            }
        }

        @media (max-width: 480px) {
            .card {
                width: 98%;
                padding: 8px;
                min-height: 75vh;
            }

            th, td {
                font-size: 12px;
                padding: 6px;
            }
        }
    </style>
</head>

<body>
<%@ include file="header.jsp" %>

<div class="main-content">
  <div class="card">
    <h2>📊 Stock Summary Report</h2>

    <form method="get" action="stockReport.jsp">
        <label for="toDate">Up to Date:</label>
        <input type="date" id="toDate" name="toDate" value="<%=toDate%>">

        <label for="category">Category:</label>
        <select name="category" id="category">
            <option value="ALL">All Categories</option>
            <%
                while (rsCat.next()) {
                    String cat = rsCat.getString("Category");
                    String selected = (category != null && category.equals(cat)) ? "selected" : "";
            %>
                <option value="<%=cat%>" <%=selected%>><%=cat%></option>
            <%
                }
            %>
        </select>

        <input type="submit" value="View Report">
    </form>

    <div class="table-container">
    <table class="main-table">
        <thead>
            <tr>
                <th>Category</th>
                <th>Item ID</th>
                <th>Item Name</th>
                <th>Total Receipts</th>
                <th>Total Issues</th>
                <th>Closing Balance</th>
            </tr>
        </thead>
        <tbody>
        <%
            boolean hasData = false;
            while (rs.next()) {
                hasData = true;
        %>
        <tr>
            <td><%= rs.getString("Category") %></td>
            <td><%= rs.getInt("Item_id") %></td>
            <td><%= rs.getString("Item_name") %></td>
            <td><%= rs.getBigDecimal("total_receipts") %></td>
            <td><%= rs.getBigDecimal("total_issues") %></td>
            <td><b><%= rs.getBigDecimal("closing_balance") %></b></td>
        </tr>
        <%
            }
            if (!hasData) {
                out.println("<tr><td colspan='6' style='text-align:center;'>No records found for the selected filters.</td></tr>");
            }
        %>
        </tbody>
    </table>
    </div>
  </div>
</div>

<jsp:include page="Footer.jsp" />
</body>
</html>

<%
    } catch (Exception e) {
        out.println("<p style='color:red;text-align:center;'>Error: " + e.getMessage() + "</p>");
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception ignored) {}
        if (ps != null) try { ps.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
%>
