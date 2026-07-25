<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page contentType="text/html;charset=UTF-8" %>
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
    <title>Stock Issue Report</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <style>
        * { box-sizing: border-box; }
        body {
            font-family: 'Poppins', sans-serif;
            background-color: #f3f3f3;
            margin: 0;
            padding: 0;
            color: #181818;
            -webkit-tap-highlight-color: transparent;
        }

        .main-content {
            width: 100%;
            max-width: 100%;
            margin: 0 auto;
            padding: 20px;
        }

        /* Salesforce Style Card Base */
        .card {
            background: #fff;
            border-radius: 4px;
            padding: 24px;
            width: 100%;
            border: 1px solid #c9c9c9;
            box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
            overflow: visible; 
        }

        .header-area {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 24px;
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

        h2 {
            margin: 0;
            font-size: 20px;
            color: #0176d3;
            font-weight: 700;
            text-align: left;
            display: flex;
            align-items: center;
            justify-content: space-between;
            width: 100%;
            flex-wrap: wrap;
            gap: 12px;
        }

        h2 a {
            font-size: 13px;
            color: #0176d3;
            text-decoration: none;
            background: #ffffff;
            border: 1px solid #747472;
            padding: 6px 12px;
            border-radius: 4px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.1s ease;
        }

        h2 a:hover {
            background: #f4f6f9;
            color: #015a9e;
            border-color: #747472;
            text-decoration: none;
        }

        /* Salesforce Filter Toolbar Grid */
        .filter-bar {
            background: #fafaf9;
            border: 1px solid #c9c9c9;
            border-radius: 4px;
            padding: 16px;
            margin-bottom: 20px;
            display: flex;
            flex-wrap: wrap;
            gap: 14px;
            align-items: flex-end;
        }

        .filter-bar form {
            display: flex;
            flex-wrap: wrap;
            gap: 14px;
            align-items: flex-end;
        }

        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .filter-bar label {
            font-size: 12px;
            font-weight: 700;
            color: #514f4d;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            white-space: nowrap;
        }

        .filter-bar input[type="date"],
        .filter-bar input[type="text"] {
            height: 36px;
            padding: 0 12px;
            border: 1px solid #aeaeae;
            border-radius: 4px;
            font-family: inherit;
            font-size: 13px;
            background: #ffffff;
            outline: none;
            min-width: 160px;
        }

        .filter-bar input:focus {
            border-color: #0176d3;
            box-shadow: 0 0 0 2px rgba(1,118,211,0.15);
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
            white-space: nowrap;
            text-decoration: none;
        }

        .btn:hover { 
            background: #015a9e; 
            border-color: #015a9e; 
        }

        .btn-secondary {
            background: #ffffff;
            border-color: #747472;
            color: #181818;
        }
        .btn-secondary:hover {
            background: #f4f6f9;
            border-color: #747472;
        }

        .btn-print {
            height: 30px;
            padding: 0 10px;
            font-size: 12px;
            background: #0176d3;
            color: #ffffff;
            border: 1px solid #0176d3;
            border-radius: 4px;
        }
        .btn-print:hover {
            background: #015a9e;
        }

        /* Table Container Layout */
        .table-container {
            width: 100%;
            overflow-x: visible;
        }

        .main-table {
            width: 100%;
            border-collapse: collapse;
            background: #fff;
            font-size: 13px;
            table-layout: auto;
        }

        .main-table th {
            background: #fafaf9;
            color: #514f4d;
            padding: 12px 10px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 2px solid #c9c9c9;
            font-size: 11px;
            text-align: left;
            white-space: nowrap;
        }

        .main-table th.num, .main-table td.num { 
            text-align: center; 
        }
        
        .main-table th.text, .main-table td.text { 
            text-align: left; 
        }

        .main-table td {
            padding: 12px 10px;
            border-bottom: 1px solid #e5e5e5;
            color: #181818;
            vertical-align: middle;
            word-break: break-word;
        }

        .main-table tr:last-child td {
            border-bottom: none;
        }

        .main-table tr:hover {
            background-color: #f8fafc;
        }

        /* Structural Laptop Small Screen & Mobile Refactor Engine */
        @media (max-width: 1024px) {
            .card { padding: 16px; }
            
            .filter-bar {
                flex-direction: column;
                align-items: stretch;
                gap: 12px;
                padding: 12px;
            }

            .filter-bar form {
                flex-direction: column;
                align-items: stretch;
                width: 100%;
                gap: 12px;
            }

            .filter-group {
                width: 100%;
            }

            .filter-bar input[type="text"], 
            .filter-bar input[type="date"],
            .btn {
                width: 100%;
                height: 40px;
            }

            table, thead, tbody, th, td, tr {
                display: block;
                width: 100%;
            }

            thead tr {
                display: none;
            }

            .main-table tr {
                border: 1px solid #c9c9c9;
                border-radius: 4px;
                margin-bottom: 16px;
                box-shadow: 0 1px 2px rgba(0,0,0,0.05);
                padding: 10px 0;
                background: #fff;
            }

            .main-table td, 
            .main-table td.num, 
            .main-table td.text {
                text-align: right;
                padding: 8px 16px;
                position: relative;
                border: none;
                border-bottom: 1px solid #f3f3f3;
                font-size: 13px;
            }

            .main-table td:last-child {
                border-bottom: none;
            }

            .main-table td:before {
                content: attr(data-label);
                position: absolute;
                left: 16px;
                width: 45%;
                font-weight: 700;
                text-align: left;
                color: #514f4d;
                white-space: nowrap;
                font-size: 11px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
        }
    </style>

    <script>
        function filterTable() {
            const input = document.getElementById("searchInput").value.toLowerCase();
            const rows = document.querySelectorAll("#issueTable tbody tr");
            rows.forEach(row => {
                if (row.cells.length === 1) return; // Skip "No records found" loops
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(input) ? "" : "none";
            });
        }

        function downloadExcel() {
            const table = document.getElementById("issueTable");
            let csv = [];
            const rows = table.querySelectorAll('tr');
            rows.forEach(row => {
                if (row.style.display !== 'none') {
                    let cols = row.querySelectorAll('th, td');
                    let rowData = [];
                    cols.forEach((cell, index) => {
                        // Skip the last column (Action/Print column) in Excel Export
                        if (index === cols.length - 1) return;

                        let text = cell.innerText.replace(/\n/g, ' ').replace(/"/g, '""').trim();
                        
                        if (window.innerWidth <= 1024 && cell.tagName === 'TD') {
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
            link.setAttribute('download', 'Stock_Issue_Report.csv');
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    </script>
</head>

<body>
<jsp:include page="header.jsp" />

<div class="main-content">
    <div class="card">
        
        <div class="header-area">
            <div class="icon-box"><i class="fa fa-boxes-stacked"></i></div>
            <h2>
                Stock Issue Report
                <a href="IssueValueReport.jsp"><i class="fa fa-chart-bar"></i> Consumption Dashboard</a>
            </h2>
        </div>

        <div class="filter-bar">
            <form method="get">
                <div class="filter-group">
                    <label>From Date</label>
                    <input type="date" name="fromDate" value="<%= request.getParameter("fromDate") != null ? request.getParameter("fromDate") : "" %>">
                </div>
                <div class="filter-group">
                    <label>To Date</label>
                    <input type="date" name="toDate" value="<%= request.getParameter("toDate") != null ? request.getParameter("toDate") : "" %>">
                </div>
                <button type="submit" class="btn"><i class="fa fa-filter"></i> Filter</button>
            </form>

            <div class="filter-group" style="flex:1; min-width:200px;">
                <label>Keyword Search</label>
                <input type="text" id="searchInput" placeholder="Search by Item / Issue No..." onkeyup="filterTable()">
            </div>
            
            <button onclick="downloadExcel()" class="btn btn-secondary"><i class="fa fa-file-excel" style="color: #2e844a;"></i> Download Excel</button>
        </div>

        <div class="table-container">
            <table id="issueTable" class="main-table">
                <thead>
                    <tr>
                        <th class="text">Indent No</th>
                        <th class="text">Item ID</th>
                        <th class="text">Item Name</th>
                        <th class="text">Issued To</th>
                        <th class="text">Department</th>
                        <th class="num">Quantity Issued</th>
                        <th class="num">Unit Price (₹)</th>
                        <th class="num">Total Value (₹)</th>
                        <th class="num">Issue Date</th>
                        <th class="text">Remarks</th>
                        <th class="num">Action</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    Connection con = null;
                    PreparedStatement ps = null;
                    ResultSet rs = null;

                    String fromDate = request.getParameter("fromDate");
                    String toDate = request.getParameter("toDate");

                    try {
                        con = DBUtil.getConnection();
                        StringBuilder query = new StringBuilder(
                            "SELECT si.indent_no, si.issueno, si.item_id, im.Item_name, " +
                            "si.issued_to, si.department, si.qty_issued, si.unit_price, si.total_value, si.issue_date, si.remarks " +
                            "FROM stock_issues si JOIN item_master im ON si.item_id = im.Item_id "
                        );

                        if (fromDate != null && !fromDate.isEmpty() && toDate != null && !toDate.isEmpty()) {
                            query.append("WHERE DATE(si.issue_date) BETWEEN ? AND ? ");
                        }
                        query.append("ORDER BY si.issue_date DESC");

                        ps = con.prepareStatement(query.toString());

                        if (fromDate != null && !fromDate.isEmpty() && toDate != null && !toDate.isEmpty()) {
                            ps.setString(1, fromDate);
                            ps.setString(2, toDate);
                        }

                        rs = ps.executeQuery();
                        int count = 0;
                        while (rs.next()) {
                            count++;
                            String indentNo = rs.getString("indent_no");
                            String itemName = rs.getString("Item_name");
                            Object qty = rs.getBigDecimal("qty_issued");
                            Object unitPrice = rs.getBigDecimal("unit_price") != null ? rs.getBigDecimal("unit_price") : 0;
                            Object totalValue = rs.getBigDecimal("total_value") != null ? rs.getBigDecimal("total_value") : 0;
                %>
                    <tr>
                        <td data-label="Indent No" class="text" style="font-weight: 600; color: #0176d3;"><%= indentNo %></td>
                        <td data-label="Item ID" class="text"><%= rs.getInt("item_id") %></td>
                        <td data-label="Item Name" class="text" style="font-weight: 600;"><%= itemName %></td>
                        <td data-label="Issued To" class="text"><%= rs.getString("issued_to") %></td>
                        <td data-label="Department" class="text"><%= rs.getString("department") %></td>
                        <td data-label="Qty Issued" class="num" style="font-weight: 600;"><%= qty %></td>
                        <td data-label="Unit Price (₹)" class="num"><%= unitPrice %></td>
                        <td data-label="Total Value (₹)" class="num" style="color: #2e844a; font-weight: 700;"><%= totalValue %></td>
                        <td data-label="Issue Date" class="num"><%= rs.getTimestamp("issue_date") %></td>
                        <td data-label="Remarks" class="text"><%= rs.getString("remarks") != null ? rs.getString("remarks") : "-" %></td>
                        <td data-label="Action" class="num">
    <a href="printissue.jsp?indentNo=<%= java.net.URLEncoder.encode(indentNo != null ? indentNo : "", "UTF-8") %>" 
       target="_blank" 
       class="btn btn-print" 
       title="Print Issue Voucher">
        <i class="fa fa-print"></i> Print Voucher
    </a>
</td>
                    </tr>
                <%
                        }
                        if (count == 0) {
                            out.println("<tr><td colspan='11' style='text-align:center; color:#c23934; font-weight:600;'>No stock issues found.</td></tr>");
                        }
                    } catch (Exception e) {
                        out.println("<tr><td colspan='11' style='color:#c23934; font-weight:600;'>Error: " + e.getMessage() + "</td></tr>");
                    } finally {
                        if (rs != null) try { rs.close(); } catch (Exception ignored) {}
                        if (ps != null) try { ps.close(); } catch (Exception ignored) {}
                        if (con != null) try { con.close(); } catch (Exception ignored) {}
                    }
                %>
                </tbody>
            </table>
        </div>
    </div>
</div>
</body>
</html>