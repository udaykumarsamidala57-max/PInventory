<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.bean.DBUtil" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = DBUtil.getConnection();

    PreparedStatement ps = null, psItems = null;
    ResultSet rs = null, rsItems = null;

    class POItem {
        int itemId;
        String description;
        double qty, receivedQty, balanceQty, rate, discount, gst;
    }

    class PO {
        int poId;
        String poNumber, poDate, vendorName, approval, status;
        double totalAmount;
        List<POItem> items = new ArrayList<>();
    }

    List<PO> poList = new ArrayList<>();

    try {
        String sql = "SELECT * FROM po_master ORDER BY po_date DESC";
        ps = con.prepareStatement(sql);
        rs = ps.executeQuery();

        while (rs.next()) {
            PO po = new PO();
            po.poId = rs.getInt("PO_id");
            po.poNumber = rs.getString("po_number");
            po.poDate = rs.getString("po_date");
            po.vendorName = rs.getString("vendor_name");
            po.totalAmount = rs.getDouble("total_amount");
            po.approval = rs.getString("Approval");
            po.status = rs.getString("po_status");

            String itemSQL =
                "SELECT i.po_item_id, i.item_id, i.description, i.qty, i.rate, " +
                "i.discount_percent, i.gst_percent, " +
                "COALESCE(SUM(g.qty_received), 0) AS received_qty " +
                "FROM po_items i " +
                "LEFT JOIN grn_items g ON i.po_item_id = g.po_item_id " +
                "WHERE i.PO_id = ? " +
                "GROUP BY i.po_item_id";

            psItems = con.prepareStatement(itemSQL);
            psItems.setInt(1, po.poId);
            rsItems = psItems.executeQuery();

            while (rsItems.next()) {
                POItem item = new POItem();
                item.itemId = rsItems.getInt("item_id");
                item.description = rsItems.getString("description");
                item.qty = rsItems.getDouble("qty");
                item.receivedQty = rsItems.getDouble("received_qty");
                item.balanceQty = item.qty - item.receivedQty;
                item.rate = rsItems.getDouble("rate");
                item.discount = rsItems.getDouble("discount_percent");
                item.gst = rsItems.getDouble("gst_percent");
                po.items.add(item);
            }

            poList.add(po);
            if (rsItems != null) rsItems.close();
            if (psItems != null) psItems.close();
        }

    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (con != null) con.close(); } catch (Exception ex) {}
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Purchase Order List</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #eef3f8;
            margin: 0;
            padding: 0;
        }

        h2 {
            margin: 15px;
            color: #2c3e50;
            text-align: center;
        }

        table.main-table {
            width: 98%;
            margin: 10px auto;
            border-collapse: collapse;
            border: 2px solid #b0c4de;
            background: #fff;
            box-shadow: 0 3px 10px rgba(0,0,0,0.1);
            border-radius: 6px;
        }

        table.main-table thead {
            background: linear-gradient(135deg, #ff8c00, #8e2de2);
            color: white;
            font-size: 16px;
        }

        table.main-table td, th {
            border: 1px solid #dcdcdc;
            padding: 8px;
            text-align: center;
            font-size: 14px;
        }

        .items-block {
            width: 95%;
            margin: 10px auto;
            padding: 10px;
            background: #f9fbff;
            border-left: 4px solid #3498db;
            border-radius: 10px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.08);
            display: none;
        }

        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
            font-size: 13px;
        }

        .items-table th {
            background: #e6f0ff;
            color: #333;
            padding: 6px;
            border: 1px solid #aac4ef;
        }

        .items-table td {
            border: 1px solid #ccd9ea;
            padding: 6px;
            text-align: center;
        }

        .toggle-btn {
            background: #3498db;
            border: none;
            color: white;
            padding: 6px 10px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 13px;
        }

        .toggle-btn:hover {
            background: #2176bd;
        }

        .content {
            margin-left: 240px;
            padding: 20px;
        }

        /* ✅ Toolbar Styling */
        .toolbar {
            width: 98%;
            margin: 10px auto;
            text-align: right;
        }

        .toolbar input, .toolbar select, .toolbar button {
            padding: 6px 10px;
            border-radius: 5px;
            border: 1px solid #bbb;
            margin-left: 5px;
            font-size: 13px;
        }

        .toolbar button {
            background: #28a745;
            color: white;
            border: none;
            cursor: pointer;
        }

        .toolbar button:hover {
            background: #218838;
        }
    </style>

    <script>
        function toggleItems(poNumber) {
            var block = document.getElementById('items-' + poNumber);
            var btn = document.getElementById('btn-' + poNumber);
            if (block.style.display === "none" || block.style.display === "") {
                block.style.display = "block";
                btn.innerText = "Hide Items";
            } else {
                block.style.display = "none";
                btn.innerText = "View Items";
            }
        }

        // ✅ Combined Search + Filters + Date Filter
        function filterTable() {
            let input = document.getElementById("searchInput").value.toLowerCase();
            let statusFilter = document.getElementById("statusFilter").value;
            let approvalFilter = document.getElementById("approvalFilter").value;
            let fromDate = document.getElementById("fromDate").value;
            let toDate = document.getElementById("toDate").value;

            let rows = document.querySelectorAll(".main-table tbody tr");

            rows.forEach((row) => {
                let cells = row.querySelectorAll("td");
                if (cells.length < 7) return; // skip item rows

                let poNum = cells[0].innerText.toLowerCase();
                let date = cells[1].innerText.trim();
                let vendor = cells[2].innerText.toLowerCase();
                let approval = cells[4].innerText;
                let status = cells[5].innerText;

                let poDate = new Date(date);
                let include = true;

                if (input && !poNum.includes(input) && !vendor.includes(input)) include = false;
                if (approvalFilter && approval !== approvalFilter) include = false;
                if (statusFilter && status !== statusFilter) include = false;

                if (fromDate) {
                    let fDate = new Date(fromDate);
                    if (poDate < fDate) include = false;
                }
                if (toDate) {
                    let tDate = new Date(toDate);
                    if (poDate > tDate) include = false;
                }

                row.style.display = include ? "" : "none";
            });
        }

        // ✅ Clear all filters
        function clearFilters() {
            document.getElementById("searchInput").value = "";
            document.getElementById("statusFilter").value = "";
            document.getElementById("approvalFilter").value = "";
            document.getElementById("fromDate").value = "";
            document.getElementById("toDate").value = "";
            filterTable();
        }

        // ✅ Download as Excel
        function downloadExcel() {
            let table = document.querySelector(".main-table").outerHTML;
            let blob = new Blob(["\ufeff" + table], { type: "application/vnd.ms-excel" });
            let link = document.createElement("a");
            link.href = URL.createObjectURL(blob);
            link.download = "PO_List.xls";
            link.click();
        }
    </script>
</head>
<body>
<jsp:include page="header.jsp" />

<h2>Purchase Orders</h2>
<div class="content">

    <!-- ✅ Toolbar -->
    <div class="toolbar">
        <input type="text" id="searchInput" onkeyup="filterTable()" placeholder="Search PO No. or Vendor">
        <input type="date" id="fromDate" onchange="filterTable()">
        <input type="date" id="toDate" onchange="filterTable()">

        <select id="approvalFilter" onchange="filterTable()">
            <option value="">All Approvals</option>
            <option value="Approved">Approved</option>
            <option value="Pending">Pending</option>
            <option value="Rejected">Rejected</option>
        </select>

        <select id="statusFilter" onchange="filterTable()">
            <option value="">All Status</option>
            <option value="Open">Open</option>
            <option value="Closed">Closed</option>
            <option value="Cancelled">Cancelled</option>
        </select>

        <button onclick="filterTable()">Search</button>
        <button onclick="clearFilters()">Clear</button>
        <button onclick="downloadExcel()">Download</button>
    </div>

    <table class="main-table">
        <thead>
            <tr>
                <th>PO Number</th>
                <th>Date</th>
                <th>Vendor</th>
                <th>Total Amount</th>
                <th>Approval</th>
                <th>Status</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody>
        <%
            if (!poList.isEmpty()) {
                for (PO po : poList) {
        %>
            <tr>
                <td><%= po.poNumber %></td>
                <td><%= po.poDate %></td>
                <td><%= po.vendorName %></td>
                <td><%= po.totalAmount %></td>
                <td><%= po.approval %></td>
                <td><%= po.status %></td>
                <td><button class="toggle-btn" id="btn-<%=po.poNumber%>" onclick="toggleItems('<%=po.poNumber%>')">View Items</button></td>
            </tr>
            <tr>
                <td colspan="7">
                    <div class="items-block" id="items-<%=po.poNumber%>">
                        <h4>Items for PO: <%= po.poNumber %></h4>
                        <% if (!po.items.isEmpty()) { %>
                        <table class="items-table">
                            <tr>
                                <th>Item ID</th>
                                <th>Description</th>
                                <th>PO Qty</th>
                                <th>Received Qty</th>
                                <th>Balance</th>
                                <th>Rate</th>
                                <th>Discount %</th>
                                <th>GST %</th>
                            </tr>
                            <% for (POItem item : po.items) { %>
                            <tr>
                                <td><%= item.itemId %></td>
                                <td><%= item.description %></td>
                                <td><%= item.qty %></td>
                                <td><%= item.receivedQty %></td>
                                <td><%= item.balanceQty %></td>
                                <td><%= item.rate %></td>
                                <td><%= item.discount %></td>
                                <td><%= item.gst %></td>
                            </tr>
                            <% } %>
                        </table>
                        <% } else { %>
                        <p style="color:red;">No items found for this PO.</p>
                        <% } %>
                    </div>
                </td>
            </tr>
        <%  } } else { %>
            <tr>
                <td colspan="7" style="text-align:center; color:red;">No Purchase Orders Found</td>
            </tr>
        <% } %>
        </tbody>
    </table>
</div>

<jsp:include page="Footer.jsp" />
</body>
</html>
