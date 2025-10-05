<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Stock Report</title>
    <link rel="stylesheet" type="text/css" href="indent.css">
</head>
<body>
<jsp:include page="nav.jsp" />
<table style="width:100%; border-collapse: collapse; border: 2px solid grey;">
<tr>
<td style="vertical-align: top;">
<h2>📊 Stock Report</h2>

<div class="filter-box">
    <form method="get" action="stockReport.jsp">
        Category:
        <select name="category">
            <option value="">-- All --</option>
            <%
                try (Connection con = DBUtil.getConnection();
                     PreparedStatement ps = con.prepareStatement("SELECT DISTINCT Category FROM item_master");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String cat = rs.getString("Category");
                        String selected = request.getParameter("category") != null 
                                          && request.getParameter("category").equals(cat) ? "selected" : "";
                        out.println("<option value='" + cat + "' " + selected + ">" + cat + "</option>");
                    }
                } catch (Exception e) { e.printStackTrace(); }
            %>
        </select>

        Item Name:
        <input type="text" name="search" value="<%= request.getParameter("search") != null ? request.getParameter("search") : "" %>">

        <button type="submit" class="btn">Filter</button>
    </form>
</div>

<table>
    <tr>
        <th>Item ID</th>
        <th>Item Name</th>
        <th>Category</th>
        <th>Sub Category</th>
        <th>UOM</th>
        <th>Total Received</th>
        <th>Total Issued</th>
        <th>Balance Qty</th>
        <th>Last Updated</th>
    </tr>

    <%
        String category = request.getParameter("category");
        String search = request.getParameter("search");

        String sql = "SELECT s.item_id, i.Item_name, i.Category, i.Sub_Category, i.UOM, " +
                     "s.total_received, s.total_issued, s.balance_qty, s.last_updated " +
                     "FROM stock s JOIN item_master i ON s.item_id = i.Item_id WHERE 1=1 ";

        if (category != null && !category.isEmpty()) {
            sql += " AND i.Category = ? ";
        }
        if (search != null && !search.isEmpty()) {
            sql += " AND i.Item_name LIKE ? ";
        }

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            int idx = 1;
            if (category != null && !category.isEmpty()) {
                ps.setString(idx++, category);
            }
            if (search != null && !search.isEmpty()) {
                ps.setString(idx++, "%" + search + "%");
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
    %>
    <tr>
        <td><%= rs.getInt("item_id") %></td>
        <td><%= rs.getString("Item_name") %></td>
        <td><%= rs.getString("Category") %></td>
        <td><%= rs.getString("Sub_Category") %></td>
        <td><%= rs.getString("UOM") %></td>
        <td><%= rs.getDouble("total_received") %></td>
        <td><%= rs.getDouble("total_issued") %></td>
        <td><%= rs.getDouble("balance_qty") %></td>
        <td><%= rs.getTimestamp("last_updated") %></td>
    </tr>
    <%
                }
            }
        } catch (Exception e) {
            out.println("<tr><td colspan='9'>Error: " + e.getMessage() + "</td></tr>");
        }
    %>
</table>
</td>
<td style="vertical-align: top; width: 220px;">
    <jsp:include page="Issuenav.jsp" />
</td>
</tr>
</table>

<jsp:include page="Footer.jsp" />
</body>
</html>
