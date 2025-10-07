<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
    <title>Stock Issue Report</title>
    <head>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">
</head>
</head>
<body>
<jsp:include page="header.jsp" />

<div class="main-content">
    <div class="main-section">

    <table>
    <thead>
        <tr>
            <th>Issue No</th>
            <th>Item ID</th>
            <th>Item Name</th>
            
            <th>Issued To</th>
            <th>Quantity Issued</th>
            <th>Issue Date</th>
            <th>Remarks</th>
        </tr>
</thead>
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
</div>
</div>
<jsp:include page="Footer.jsp" />
</body>
</html>
