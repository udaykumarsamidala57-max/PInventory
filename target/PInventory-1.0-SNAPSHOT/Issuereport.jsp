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
<html>
<head>
    <title>Stock Issue Report</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/tablestyle.css">

    <style>
        body {
            font-family: 'Poppins', sans-serif;
            background: #f7f9fc;
        }
        .filter-bar {
            margin-bottom: 15px;
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            align-items: center;
        }
        .filter-bar input {
            padding: 6px 10px;
            border: 1px solid #ccc;
            border-radius: 6px;
        }
        .filter-bar button {
            background-color: #007bff;
            color: white;
            border: none;
            padding: 7px 15px;
            border-radius: 6px;
            cursor: pointer;
            transition: 0.3s;
        }
        .filter-bar button:hover {
            background-color: #0056b3;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
            background: white;
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
        tr:hover {
            background-color: #f1f1f1;
        }
    </style>

    <script>
        // ✅ Client-side search filter
        function filterTable() {
            const input = document.getElementById("searchInput").value.toLowerCase();
            const rows = document.querySelectorAll("#issueTable tbody tr");

            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(input) ? "" : "none";
            });
        }

        // ✅ Excel download
        function downloadExcel() {
            const table = document.getElementById("issueTable");
            const html = table.outerHTML.replace(/ /g, '%20');
            const a = document.createElement('a');
            a.href = 'data:application/vnd.ms-excel,' + html;
            a.download = 'Stock_Issue_Report.xls';
            a.click();
        }
    </script>
</head>

<body>
<jsp:include page="header.jsp" />

<div class="main-content">
    <div class="main-section">
        <h2 style="margin-bottom:10px;">Stock Issue Report</h2>

        <!-- 🔍 Filter Section -->
        <div class="filter-bar">
            <form method="get">
                <label>From: </label>
                <input type="date" name="fromDate" value="<%= request.getParameter("fromDate") != null ? request.getParameter("fromDate") : "" %>">
                <label>To: </label>
                <input type="date" name="toDate" value="<%= request.getParameter("toDate") != null ? request.getParameter("toDate") : "" %>">
                <button type="submit"><i class="fa fa-filter"></i> Filter</button>
            </form>

            <input type="text" id="searchInput" placeholder="Search by Item / Issue No..." onkeyup="filterTable()" style="flex:1; min-width:200px;">
            <button onclick="downloadExcel()"><i class="fa fa-file-excel"></i> Download Excel</button>
        </div>

        <table id="issueTable">
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
                        "SELECT si.issue_id, si.issueno, si.item_id, im.Item_name, " +
                        "si.issued_to, si.qty_issued, si.issue_date, si.remarks " +
                        "FROM stock_issues si " +
                        "JOIN item_master im ON si.item_id = im.Item_id "
                    );

                    // ✅ Apply date range filter if provided
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
                    while(rs.next()) {
                        count++;
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
                    if(count == 0) {
                        out.println("<tr><td colspan='7' style='text-align:center;'>No stock issues found.</td></tr>");
                    }
                } catch(Exception e) {
                    out.println("<tr><td colspan='7'>Error: " + e.getMessage() + "</td></tr>");
                } finally {
                    if(rs != null) try { rs.close(); } catch(Exception ignored) {}
                    if(ps != null) try { ps.close(); } catch(Exception ignored) {}
                    if(con != null) try { con.close(); } catch(Exception ignored) {}
                }
            %>
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="Footer.jsp" />
</body>
</html>
