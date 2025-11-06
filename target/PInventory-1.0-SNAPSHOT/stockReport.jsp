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

    // Default date = today
    if (toDate == null || toDate.trim().isEmpty()) {
        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
        toDate = sdf.format(new java.util.Date());
    }

    try {
        conn = DBUtil.getConnection();

        // ✅ Fetch category list
        String catSql = "SELECT DISTINCT Category FROM item_master WHERE Category IS NOT NULL AND Category <> '' ORDER BY Category";
        psCat = conn.prepareStatement(catSql);
        rsCat = psCat.executeQuery();

        // ✅ Base SQL with optional category filter
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
    <style>
        body { font-family: 'Poppins', sans-serif; margin: 30px; background-color: #f7f9fc; }
        h2 { text-align: center; color: #333; }
        form { text-align: center; margin-bottom: 20px; }
       
        input[type="submit"] {
            background-color: #007bff;
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 4px;
            cursor: pointer;
        }
        input[type="submit"]:hover {
            background-color: #0056b3;
        }
    </style>
  
     <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="CSS/tablestyle.css">
   
</head>
<body>

<%@ include file="header.jsp" %>
<div class="main-content">
  <div class="card">
    <h2>Stock Summary Report</h2>

    <form method="get" action="stockReport.jsp">
        <label for="toDate"><b>Up to Date:</b></label>
        <input type="date" id="toDate" name="toDate" value="<%=toDate%>">

        <label for="category"><b>Category:</b></label>
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

    <table  class="main-table">
        <tr>
        <thead>
            <th>Category</th>
            <th>Item ID</th>
            <th>Item Name</th>
            <th>Total Receipts</th>
            <th>Total Issues</th>
            <th>Closing Balance</th>
            </thead>
        </tr>
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
    </table>
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
