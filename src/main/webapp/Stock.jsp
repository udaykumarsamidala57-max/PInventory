<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
String branch = (String) sess.getAttribute("branch");
%>
<html lang="en">
<head>
    <title>Stock Report</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <style>
        * { box-sizing: border-box; }
        body {
            font-family: 'Poppins', sans-serif;
            background: #f3f3f3;
            margin: 0;
            padding: 0;
            color: #181818;
            -webkit-tap-highlight-color: transparent;
        }

        .main-content {
            width: 100%;
            max-width: 1440px;
            margin: 0 auto;
            padding: 16px;
        }

        /* Salesforce Style Card Base */
        .card {
            background: #ffffff;
            border-radius: 4px;
            padding: 24px;
            margin: 0 auto;
            width: 100%;
            border: 1px solid #c9c9c9;
            box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
        }

        .header-area {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 20px;
            border-bottom: 1px solid #e5e5e5;
            padding-bottom: 16px;
        }

        .icon-box {
            width: 40px;
            height: 40px;
            border-radius: 4px;
            background: #0176d3;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 18px;
        }

        h1 {
            margin: 0;
            font-size: 20px;
            color: #0176d3;
            font-weight: 700;
        }

        /* Salesforce Filter Toolbar */
        .filter-box {
            background: #fafaf9;
            border: 1px solid #c9c9c9;
            border-radius: 4px;
            padding: 16px;
            margin-bottom: 20px;
            display: flex;
            flex-wrap: wrap;
            gap: 14px;
            align-items: center;
        }

        .filter-group {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .filter-box label {
            font-size: 12px;
            font-weight: 700;
            color: #514f4d;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            white-space: nowrap;
        }

        .filter-box select,
        .filter-box input {
            height: 36px;
            padding: 0 12px;
            border: 1px solid #aeaeae;
            border-radius: 4px;
            font-family: inherit;
            font-size: 13px;
            background: #ffffff;
            outline: none;
            min-width: 200px;
        }

        .filter-box select:focus,
        .filter-box input:focus {
            border-color: #0176d3;
            box-shadow: 0 0 0 2px rgba(1,118,211,0.15);
        }

        .actions-group {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-left: auto;
        }

        /* Salesforce Lightning Action Buttons */
        .btn {
            height: 36px;
            padding: 0 16px;
            border: 1px solid #0176d3;
            background: #0176d3;
            color: white;
            border-radius: 4px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.1s ease;
        }

        .btn:hover { background: #015a9e; border-color: #015a9e; }

        .btn-secondary {
            background: #ffffff;
            border-color: #747472;
            color: #181818;
        }

        .btn-secondary:hover {
            background: #f4f6f9;
            color: #181818;
            border-color: #747472;
        }

        .btn-success {
            background: #2e844a;
            border-color: #2e844a;
        }

        .btn-success:hover {
            background: #1b5e30;
            border-color: #1b5e30;
        }

        /* Data Presentation Layout */
        .table-container {
            width: 100%;
            overflow-x: auto;
            border: 1px solid #c9c9c9;
            border-radius: 4px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 1000px;
            background: #fff;
            font-size: 13px;
        }

        th {
            background-color: #fafaf9;
            color: #514f4d;
            padding: 12px 10px;
            text-align: left;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 2px solid #c9c9c9;
            font-size: 11px;
        }

        td {
            padding: 10px;
            border-bottom: 1px solid #e5e5e5;
            color: #181818;
        }

        td.num, th.num {
            text-align: right;
        }

        td.text, th.text {
            text-align: left;
        }

        tr:hover {
            background-color: #f3f3f3;
        }

        /* Responsive Architecture */
        @media (max-width: 1024px) {
            .filter-box select, .filter-box input { min-width: 160px; }
        }

        @media (max-width: 768px) {
            .main-content { padding: 10px; }
            .card { padding: 16px; }
            
            .header-area { margin-bottom: 16px; padding-bottom: 12px; }

            .filter-box {
                flex-direction: column;
                align-items: stretch;
                gap: 12px;
                padding: 12px;
            }

            .filter-group {
                flex-direction: column;
                align-items: flex-start;
                gap: 4px;
            }

            .filter-box select,
            .filter-box input {
                width: 100%;
                height: 40px;
            }

            .actions-group {
                width: 100%;
                flex-direction: column;
                margin-left: 0;
                gap: 8px;
            }

            .btn {
                width: 100%;
                height: 40px;
            }

            .table-container {
                border: none;
            }

            table, thead, tbody, th, td, tr {
                display: block;
                width: 100%;
            }

            thead tr {
                display: none;
            }

            tr {
                margin-bottom: 12px;
                border: 1px solid #c9c9c9;
                border-radius: 4px;
                box-shadow: 0 1px 2px rgba(0,0,0,0.05);
                padding: 8px 0;
                background: #fff;
            }

            td {
                text-align: right;
                padding: 8px 14px;
                position: relative;
                border: none;
                border-bottom: 1px solid #f3f3f3;
                font-size: 13px;
            }
            
            td:last-child {
                border-bottom: none;
            }

            td:before {
                content: attr(data-label);
                position: absolute;
                left: 14px;
                width: 45%;
                font-weight: 700;
                text-align: left;
                color: #514f4d;
                white-space: nowrap;
                font-size: 11px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            
            td.num, td.text {
                text-align: right;
            }
        }
    </style>
</head>

<body>
<jsp:include page="header.jsp" />

<div class="main-content">
    <div class="card">
        
        <div class="header-area">
            <div class="icon-box"><i class="fa fa-chart-pie"></i></div>
            <h1>Stock Report</h1>
        </div>

        <div class="filter-box">
            <div class="filter-group">
                <label>Category</label>
                <select id="categoryFilter">
                    <option value="">-- All --</option>
                    <%
                        Set<String> categories = new HashSet<>();
                        try (Connection con = DBUtil.getConnection(branch);
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
            </div>

            <div class="filter-group">
                <label>Item Name</label>
                <input type="text" id="searchBox" placeholder="Search item name...">
            </div>
            
            <div class="actions-group">
                <button class="btn" onclick="filterTable()"><i class="fa fa-filter"></i> Filter</button>
                <button class="btn btn-secondary" onclick="resetFilter()"><i class="fa fa-rotate-left"></i> Reset</button>
                <button class="btn btn-success" onclick="downloadExcel()"><i class="fa fa-file-excel"></i> Download Excel</button>
            </div>
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
                    try (Connection con = DBUtil.getConnection(branch);
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
        // Only target browser visible headers/data or base rows, ignoring desktop hidden attributes during evaluation
        if(row.style.display !== 'none') {
            let cols = row.querySelectorAll('th, td');
            let rowData = [];
            cols.forEach(cell => {
                let text = cell.innerText.replace(/\n/g, ' ').replace(/"/g, '""').trim();
                
                // If clean rendering parsed out mobile label definitions, strip them out from final output raw data array
                if (window.innerWidth <= 768 && cell.tagName === 'TD') {
                    const labelText = cell.getAttribute('data-label') || '';
                    if (text.startsWith(labelText)) {
                        text = text.substring(labelText.length).trim();
                    }
                }
                rowData.push('"' + text + '"');
            });
            csv.push(rowData.join(','));
        }
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