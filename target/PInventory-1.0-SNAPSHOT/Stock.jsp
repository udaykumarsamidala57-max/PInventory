<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
%>
<html>
<head>
    <title>Stock Report</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">

    <style>
        body {
            font-family: 'Poppins', sans-serif;
            background: #f7f9fc;
            margin: 0;
            padding: 0;
        }

        h2 {
            margin: 20px;
        }

        .filter-box {
            margin: 20px;
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            align-items: center;
        }

        .filter-box select, .filter-box input {
            padding: 6px 10px;
            border: 1px solid #ccc;
            border-radius: 6px;
        }

        .btn {
            padding: 7px 14px;
            border: none;
            background: #007bff;
            color: white;
            border-radius: 6px;
            cursor: pointer;
            transition: 0.3s;
        }

        .btn:hover { background: #0056b3; }

        .btn-secondary {
            background: #6c757d;
        }

        .main-table {
            width: 98%;
            margin: 0 auto;
            border-collapse: collapse;
            background: #fff;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }

        th {
            background-color: #007bff;
            color: white;
            padding: 10px;
            text-align: left;
        }

        td {
            padding: 8px 10px;
            border-bottom: 1px solid #ddd;
        }

        td.num, th.num {
            text-align: right;
        }

        td.text, th.text {
            text-align: left;
        }

        tr:hover {
            background-color: #f1f1f1;
        }
    </style>
</head>

<body>
<jsp:include page="header.jsp" />



<div class="main-content">
    <div class="card">
<h1>📊 Stock Report</h1>
        <div class="filter-box">
            <label>Category:</label>
            <select id="categoryFilter">
                <option value="">-- All --</option>
                <%
                    Set<String> categories = new HashSet<>();
                    try (Connection con = DBUtil.getConnection();
                         PreparedStatement ps = con.prepareStatement("SELECT DISTINCT Category FROM item_master");
                         ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            categories.add(rs.getString("Category"));
                        }
                    } catch (Exception e) { e.printStackTrace(); }

                    for (String cat : categories) {
                %>
                    <option value="<%= cat %>"><%= cat %></option>
                <% } %>
            </select>

            <label>Item Name:</label>
            <input type="text" id="searchBox" placeholder="Search item name...">
            <button class="btn" onclick="filterTable()">Filter</button>
            <button class="btn btn-secondary" onclick="resetFilter()">Reset</button>
            <button class="btn" style="background:#28a745;" onclick="downloadExcel()">Download Excel</button>
        </div>

        <table class="main-table" id="stockTable">
            <thead>
                <tr>
                    <th class="num">Item ID</th>
                    <th class="text">Item Name</th>
                    <th class="text">Category</th>
                    <th class="text">Sub Category</th>
                    <th class="text">UOM</th>
                    <th class="num">Total Received</th>
                    <th class="num">Total Issued</th>
                    <th class="num">Balance Qty</th>
                    <th class="num">Unit Price (₹)</th>
                    <th class="num">Total Value (₹)</th>
                    <th class="text">Last Updated</th>
                </tr>
            </thead>
            <tbody>
            <%
                try (Connection con = DBUtil.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                        "SELECT s.item_id, i.Item_name, i.Category, i.Sub_Category, i.UOM, " +
                        "s.total_received, s.total_issued, s.balance_qty, s.last_price, s.last_updated " +
                        "FROM stock s JOIN item_master i ON s.item_id = i.Item_id " +
                        "ORDER BY i.Item_name")) {

                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            double balance = rs.getDouble("balance_qty");
                            double unitPrice = rs.getDouble("last_price");
                            double totalValue = balance * unitPrice;
            %>
                <tr>
                    <td class="text"><%= rs.getInt("item_id") %></td>
                    <td class="text"><%= rs.getString("Item_name") %></td>
                    <td class="text"><%= rs.getString("Category") %></td>
                    <td class="text"><%= rs.getString("Sub_Category") %></td>
                    <td class="text"><%= rs.getString("UOM") %></td>
                    <td class="num"><%= String.format("%.2f", rs.getDouble("total_received")) %></td>
                    <td class="num"><%= String.format("%.2f", rs.getDouble("total_issued")) %></td>
                    <td class="num"><%= String.format("%.2f", balance) %></td>
                    <td class="num"><%= String.format("%.2f", unitPrice) %></td>
                    <td class="num"><%= String.format("%.2f", totalValue) %></td>
                    <td class="num"><%= rs.getTimestamp("last_updated") %></td>
                </tr>
            <%
                        }
                    }
                } catch (Exception e) {
                    out.println("<tr><td colspan='11'>Error: " + e.getMessage() + "</td></tr>");
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

        row.style.display = (matchesCategory && matchesSearch) ? "" : "none";
    });
}

function resetFilter() {
    document.getElementById("categoryFilter").value = "";
    document.getElementById("searchBox").value = "";
    filterTable();
}

function downloadExcel() {
    const table = document.getElementById('stockTable');
    let csv = [];

    const rows = table.querySelectorAll('tr');
    rows.forEach(row => {
        let cols = row.querySelectorAll('th, td');
        let rowData = [];
        cols.forEach(cell => {
            let text = cell.innerText.replace(/\n/g, ' ').replace(/"/g, '""').trim();
            rowData.push('"' + text + '"');
        });
        csv.push(rowData.join(','));
    });

    const csvString = csv.join('\n');
    const blob = new Blob([csvString], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);

    link.setAttribute('href', url);
    link.setAttribute('download', 'Stock_Report.csv');
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}
</script>

</body>
</html>
