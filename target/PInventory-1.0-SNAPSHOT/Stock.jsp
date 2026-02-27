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
<html lang="en">
<head>
    <title>Stock Report</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <style>
       
        body {
            font-family: 'Poppins', sans-serif;
            background: #f7f9fc;
            margin: 0;
            padding: 0;
            overflow-x: hidden;
        }

        .main-content {
            width: 100%;
            margin: 0 auto;
            padding: 10px;
        }

        .card {
            background: #fff;
            border-radius: 10px;
            padding: 20px;
            margin: 10px auto;
            width: 100%;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        h1 {
            margin: 10px 0 20px 0;
            text-align: center;
            color: #333;
        }

      
        .filter-box {
            margin: 10px 0 20px 0;
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            align-items: center;
            justify-content: center;
        }

        .filter-box label {
            font-weight: 500;
        }

        .filter-box select,
        .filter-box input {
            padding: 7px 10px;
            border: 1px solid #ccc;
            border-radius: 6px;
            font-family: inherit;
            font-size: 14px;
        }

        .btn {
            padding: 8px 14px;
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

        .btn-secondary:hover {
            background: #545b62;
        }

        .btn-success {
            background: #28a745;
        }

        .btn-success:hover {
            background: #218838;
        }

       
        .table-container {
            width: 100%;
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 900px;
            background: #fff;
            font-size: 14px;
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
            color: #333;
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

      
        @media (max-width: 1024px) {
            .card {
                padding: 15px;
            }
            table {
                font-size: 13px;
            }
            th, td {
                padding: 8px;
            }
        }

        @media (max-width: 768px) {
            h1 {
                font-size: 20px;
            }

            .filter-box {
                flex-direction: column;
                align-items: stretch;
                gap: 8px;
            }

            .filter-box select,
            .filter-box input,
            .filter-box button {
                width: 100%;
            }

            .table-container {
                overflow-x: auto;
                border-radius: 10px;
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
                box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                padding: 10px;
                background: #fff;
            }

            td {
                text-align: right;
                padding: 8px 10px;
                position: relative;
                border: none;
                border-bottom: 1px solid #eee;
                font-size: 13px;
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
        }

        @media (max-width: 480px) {
            h1 {
                font-size: 18px;
            }

            .btn {
                font-size: 13px;
                padding: 7px;
            }
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
            <button class="btn" onclick="filterTable()"><i class="fa fa-filter"></i> Filter</button>
            <button class="btn btn-secondary" onclick="resetFilter()"><i class="fa fa-rotate-left"></i> Reset</button>
            <button class="btn btn-success" onclick="downloadExcel()"><i class="fa fa-file-excel"></i> Download Excel</button>
        </div>

        <div class="table-container">
            <table id="stockTable">
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
                        <td data-label="Item ID" class="num"><%= rs.getInt("item_id") %></td>
                        <td data-label="Item Name" class="text"><%= rs.getString("Item_name") %></td>
                        <td data-label="Category" class="text"><%= rs.getString("Category") %></td>
                        <td data-label="Sub Category" class="text"><%= rs.getString("Sub_Category") %></td>
                        <td data-label="UOM" class="text"><%= rs.getString("UOM") %></td>
                        <td data-label="Total Received" class="num"><%= String.format("%.2f", rs.getDouble("total_received")) %></td>
                        <td data-label="Total Issued" class="num"><%= String.format("%.2f", rs.getDouble("total_issued")) %></td>
                        <td data-label="Balance Qty" class="num"><%= String.format("%.2f", balance) %></td>
                        <td data-label="Unit Price (₹)" class="num"><%= String.format("%.2f", unitPrice) %></td>
                        <td data-label="Total Value (₹)" class="num"><%= String.format("%.2f", totalValue) %></td>
                        <td data-label="Last Updated" class="text"><%= rs.getTimestamp("last_updated") %></td>
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
