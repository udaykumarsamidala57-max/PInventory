<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
    <title>Stock Issue Report</title>
    <link rel="stylesheet" type="text/css" href="indent.css">
</head>
<body>
<jsp:include page="nav.jsp" />

<table style="width:100%; border-collapse: collapse; border: 2px solid grey;">
<tr>
<td style="vertical-align: top;">
    <h2>Stock Issue Report</h2>

    <table border="1" style="border-collapse:collapse; width:100%;">
        <tr>
            <th>Issue No</th>
            <th>Item ID</th>
            <th>Item Name</th>
            <th>PO Item ID</th>
            <th>Issued To</th>
            <th>Quantity Issued</th>
            <th>Issue Date</th>
            <th>Remarks</th>
        </tr>

        <%
            Connection con = null;
            Statement stmt = null;
            ResultSet rs = null;

            try {
                con = DBUtil.getConnection();
                stmt = con.createStatement();

                // ✅ Join stock_issues with item_master to fetch item name
                String query = "SELECT si.issue_id, si.issueno, si.item_id, im.Item_name, " +
                               "si.po_item_id, si.issued_to, si.qty_issued, si.issue_date, si.remarks " +
                               "FROM stock_issues si " +
                               "JOIN item_master im ON si.item_id = im.Item_id " +
                               "ORDER BY si.issue_date DESC";
                rs = stmt.executeQuery(query);

                while(rs.next()) {
        %>
        <tr>
            <td><%= rs.getString("issueno") %></td>
            <td><%= rs.getInt("item_id") %></td>
            <td><%= rs.getString("Item_name") %></td>
            <td><%= rs.getString("po_item_id") %></td>
            <td><%= rs.getString("issued_to") %></td>
            <td><%= rs.getBigDecimal("qty_issued") %></td>
            <td><%= rs.getTimestamp("issue_date") %></td>
            <td><%= rs.getString("remarks") %></td>
        </tr>
        <%
                }
            } catch(Exception e) {
                out.println("<tr><td colspan='8'>Error: " + e.getMessage() + "</td></tr>");
            } finally {
                if(rs != null) try { rs.close(); } catch(Exception ignored) {}
                if(stmt != null) try { stmt.close(); } catch(Exception ignored) {}
                if(con != null) try { con.close(); } catch(Exception ignored) {}
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
