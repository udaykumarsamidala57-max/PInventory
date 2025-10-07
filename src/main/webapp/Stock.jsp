<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Stock Report</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">
    <style>
        .filter-box {
            margin: 20px 0;
            display: flex;
            gap: 10px;
            align-items: center;
        }
        .filter-box select, .filter-box input {
            padding: 5px 10px;
            border: 1px solid #ccc;
            border-radius: 6px;
        }
        .btn {
            padding: 6px 14px;
            border: none;
            background: #007bff;
            color: white;
            border-radius: 6px;
            cursor: pointer;
        }
        .btn:hover { background: #0056b3; }
    </style>
</head>
<body>
<jsp:include page="header.jsp" />

<h2>📊 Stock Report</h2>

<div class="main-content">
    <div class="card">

        <div class="filter-box">
            Category:
            <select id="categoryFilter">
                <option value="">-- All --</option>
                <%
                    Set<String> categories = new HashSet<>();
                    try (Connection con = DBUtil.getConnection();
                         PreparedStatement ps = con.prepareStatement("SELECT DISTINCT Category FROM item_master");
                         ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            String cat = rs.getString("Category");
                            categories.add(cat);
                        }
                    } catch (Exception e) { e.printStackTrace(); }

                    for (String cat : categories) {
                %>
                    <option value="<%= cat %>"><%= cat %></option>
                <% } %>
            </select>

            Item Name:
            <input type="text" id="searchBox" placeholder="Search item name...">
            <button class="btn" onclick="filterTable()">Filter</button>
            <button class="btn" style="background:#6c757d" onclick="resetFilter()">Reset</button>
        </div>

        <table class="main-table" id="stockTable">
            <thead>
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
            </thead>
            <tbody>
            <%
                try (Connection con = DBUtil.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                        "SELECT s.item_id, i.Item_name, i.Category, i.Sub_Category, i.UOM, " +
                        "s.total_received, s.total_issued, s.balance_qty, s.last_updated " +
                        "FROM stock s JOIN item_master i ON s.item_id = i.Item_id ORDER BY i.Item_name")) {

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
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="Footer.jsp" />

<script>
function filterTable() {
    const category = document.getElementById("categoryFilter").value.toLowerCase();
    const search = document.getElementById("searchBox").value.toLowerCase();
    const rows = document.querySelectorAll("#stockTable tbody tr");

    rows.forEach(row => {
        const cat = row.cells[2].textContent.toLowerCase();
        const item = row.cells[1].textContent.toLowerCase();

        const matchesCategory = !category || cat === category;
        const matchesSearch = !search || item.includes(search);

        if (matchesCategory && matchesSearch) {
            row.style.display = "";
        } else {
            row.style.display = "none";
        }
    });
}

function resetFilter() {
    document.getElementById("categoryFilter").value = "";
    document.getElementById("searchBox").value = "";
    filterTable();
}
</script>

</body>
</html>
