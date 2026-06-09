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
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Purchase Order List</title>
    <style>
        /* SAP Horizon (Morning Horizon) System Design Tokens */
        :root {
            --sap-background: #f5f6f7;
            --sap-shell-bg: #1c2d42;
            --sap-card-bg: #ffffff;
            --sap-text-color: #1d2d3e;
            --sap-subtitle-color: #6a7b8c;
            --sap-border-color: #e2e5e9;
            --sap-primary-btn: #0070f2;
            --sap-primary-btn-hover: #005bc4;
            --sap-secondary-btn: #ffffff;
            --sap-secondary-btn-border: #b3b9c1;
            --sap-secondary-btn-hover: #f5f6f7;
            --sap-list-hover-bg: #eed0c42; /* Clean 3% dark alpha overlay */
            
            /* SAP Semantic Metric Color Tokens */
            --sap-state-success-bg: #e5f5ed;
            --sap-state-success-text: #107e3e;
            --sap-state-warning-bg: #fef0db;
            --sap-state-warning-text: #b16500;
            --sap-state-error-bg: #ffebeb;
            --sap-state-error-text: #bb0000;
            --sap-state-info-bg: #e8f4ff;
            --sap-state-info-text: #0a6ed1;
        }

        body {
            font-family: "72", "72full", Arial, Helvetica, sans-serif;
            margin: 0;
            padding: 0;
            background-color: var(--sap-background);
            color: var(--sap-text-color);
            font-size: 0.875rem;
            min-height: 100vh;
        }

        .sap-fiori-container {
            padding: 1rem 2rem;
            max-width: 1600px;
            margin: 0 auto;
            box-sizing: border-box;
        }

        /* SAP Fiori Object Header Module blueprint */
        .sap-object-header {
            background: var(--sap-card-bg);
            padding: 1.25rem 1.5rem;
            border-radius: 0.5rem;
            border: 1px solid var(--sap-border-color);
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.03);
            margin-bottom: 1rem;
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .sap-icon-tile {
            background: #e8f4ff;
            color: #0a6ed1;
            width: 3rem;
            height: 3rem;
            border-radius: 0.375rem;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 1.25rem;
            border: 1px solid #cedfe2;
        }

        .sap-object-header__title {
            font-size: 1.25rem;
            font-weight: 600;
            color: var(--sap-text-color);
            margin: 0;
        }

        .sap-object-header__subtitle {
            font-size: 0.75rem;
            color: var(--sap-subtitle-color);
            text-transform: uppercase;
            letter-spacing: 0.05rem;
            display: block;
            margin-bottom: 0.125rem;
        }

        /* SAP Filter Dynamic Filter Bar / Toolbar Component */
        .sap-filter-bar {
            display: flex;
            align-items: center;
            justify-content: flex-start;
            gap: 0.5rem;
            flex-wrap: wrap;
            background: var(--sap-card-bg);
            padding: 0.75rem 1rem;
            border: 1px solid var(--sap-border-color);
            border-radius: 0.375rem;
            margin-bottom: 1rem;
        }

        .sap-filter-bar input, .sap-filter-bar select {
            padding: 0 0.75rem;
            height: 2.25rem;
            border: 1px solid var(--sap-secondary-btn-border);
            border-radius: 0.25rem;
            font-family: inherit;
            font-size: 0.875rem;
            background: var(--sap-card-bg);
            color: var(--sap-text-color);
            box-sizing: border-box;
            transition: border-color 0.1s;
        }

        .sap-filter-bar input:focus, .sap-filter-bar select:focus {
            border-color: var(--sap-primary-btn);
            outline: none;
        }

        .sap-filter-bar input[type="text"] {
            min-width: 280px;
        }

        /* SAP Fiori Responsive Table Module */
        .sap-card-table {
            background: var(--sap-card-bg);
            border: 1px solid var(--sap-border-color);
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.5rem rgba(0,0,0,0.02);
            overflow: hidden;
            padding: 1rem;
        }

        .table-responsive-container {
            overflow-x: auto;
            border: 1px solid var(--sap-border-color);
            border-radius: 0.25rem;
        }

        table.sap-ui-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.875rem;
            text-align: left;
            background: var(--sap-card-bg);
        }

        table.sap-ui-table th, table.sap-ui-table td {
            padding: 0.75rem 1rem;
            border-bottom: 1px solid var(--sap-border-color);
            vertical-align: middle;
        }

        table.sap-ui-table th {
            background: #f7f9fa;
            color: var(--sap-text-color);
            font-weight: 600;
            font-size: 0.8125rem;
            text-transform: none;
            letter-spacing: normal;
            height: 2.5rem;
        }

        table.sap-ui-table tbody tr.sap-master-row:hover td {
            background-color: rgba(0, 112, 242, 0.04);
            cursor: pointer;
        }

        /* SAP Object Status / Badging States */
        .sap-object-status {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0.25rem 0.75rem;
            font-weight: 600;
            font-size: 0.75rem;
            border-radius: 0.25rem;
        }

        .sap-state-approved { background: var(--sap-state-success-bg); color: var(--sap-state-success-text); }
        .sap-state-open { background: var(--sap-state-info-bg); color: var(--sap-state-info-text); }
        .sap-state-pending { background: var(--sap-state-warning-bg); color: var(--sap-state-warning-text); }
        .sap-state-closed { background: #f0f2f5; color: #556b82; }
        .sap-state-rejected, .sap-state-cancelled { background: var(--sap-state-error-bg); color: var(--sap-state-error-text); }

        /* SAP Standard Button Engine Layout controls */
        .sap-btn {
            background: var(--sap-secondary-btn);
            color: var(--sap-primary-btn);
            border: 1px solid var(--sap-primary-btn);
            padding: 0 1rem;
            height: 2.25rem;
            border-radius: 0.25rem;
            cursor: pointer;
            font-size: 0.875rem;
            font-weight: 500;
            font-family: inherit;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            box-sizing: border-box;
            transition: all 0.1s ease-in-out;
        }

        .sap-btn:hover {
            background: #e8f4ff;
            border-color: var(--sap-primary-btn-hover);
        }

        .sap-btn-emphasized {
            background: var(--sap-primary-btn);
            color: #ffffff;
            border-color: transparent;
        }

        .sap-btn-emphasized:hover {
            background: var(--sap-primary-btn-hover);
            color: #ffffff;
        }

        .sap-btn-transparent {
            background: transparent;
            border-color: transparent;
            color: var(--sap-text-color);
        }
        .sap-btn-transparent:hover {
            background: var(--sap-secondary-btn-hover);
            color: var(--sap-primary-btn);
        }

        .sap-action-flex-group {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 0.375rem;
        }

        /* SAP Hierarchical Grid Expandable Sections blueprint */
        .sap-nested-row {
            background: #f8fafc;
        }

        .sap-items-block {
            padding: 1.25rem;
            background: #ffffff;
            border: 1px solid var(--sap-border-color);
            border-radius: 0.375rem;
            margin: 0.5rem 0;
            box-shadow: inset 0 2px 4px rgba(0,0,0,0.01);
        }

        .sap-items-block h4 {
            margin: 0 0 0.75rem 0;
            font-size: 0.9375rem;
            color: var(--sap-text-color);
            font-weight: 600;
        }

        .sap-nested-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.8125rem;
        }

        .sap-nested-table th {
            background: #f0f2f5;
            color: var(--sap-text-color);
            border: 1px solid var(--sap-border-color);
            height: 2.25rem;
        }

        .sap-nested-table td {
            border: 1px solid var(--sap-border-color);
            padding: 0.625rem 0.875rem;
            background: #ffffff;
        }

        /* Responsive UI Design Adjustments */
        @media screen and (max-width: 1024px) {
            .sap-fiori-container { padding: 1rem; }
            .sap-filter-bar { flex-direction: column; align-items: stretch; }
            .sap-filter-bar input, .sap-filter-bar select { width: 100%; }
        }

        @media screen and (max-width: 768px) {
            table.sap-ui-table, table.sap-ui-table thead, table.sap-ui-table tbody, table.sap-ui-table tr, table.sap-ui-table td {
                display: block;
            }
            table.sap-ui-table thead { display: none; }
            table.sap-ui-table tr.sap-master-row {
                margin-bottom: 0.75rem;
                border: 1px solid var(--sap-border-color);
                border-radius: 0.375rem;
                padding: 0.5rem 0;
            }
            table.sap-ui-table td {
                border: none;
                border-bottom: 1px solid #f0f2f5;
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 0.625rem 1rem;
            }
            table.sap-ui-table td:last-child { border-bottom: none; }
            table.sap-ui-table td:before {
                content: attr(data-label);
                font-weight: 600;
                color: var(--sap-subtitle-color);
                font-size: 0.75rem;
            }
            .sap-action-flex-group { width: 100%; justify-content: flex-end; }
        }
    </style>

    <script>
        function toggleItems(poNumber) {
            var block = document.getElementById('items-' + poNumber);
            var btn = document.getElementById('btn-' + poNumber);
            var parentRow = document.getElementById('row-nested-' + poNumber);
            
            if (block.style.display === "none" || block.style.display === "") {
                block.style.display = "block";
                parentRow.style.display = "";
                btn.innerText = "Hide Line Items";
            } else {
                block.style.display = "none";
                parentRow.style.display = "none";
                btn.innerText = "View Line Items";
            }
        }

        function filterTable() {
            let input = document.getElementById("searchInput").value.toLowerCase();
            let statusFilter = document.getElementById("statusFilter").value;
            let approvalFilter = document.getElementById("approvalFilter").value;
            let fromDate = document.getElementById("fromDate").value;
            let toDate = document.getElementById("toDate").value;

            let rows = document.querySelectorAll(".sap-ui-table tbody tr.sap-master-row");

            rows.forEach((row) => {
                let poNum = row.getAttribute("data-ponum").toLowerCase();
                let date = row.getAttribute("data-podate");
                let vendor = row.getAttribute("data-vendor").toLowerCase();
                let approval = row.getAttribute("data-approval");
                let status = row.getAttribute("data-status");
                
                let poDate = new Date(date);
                let include = true;

                if (input && !poNum.includes(input) && !vendor.includes(input)) include = false;
                if (approvalFilter && approval !== approvalFilter) include = false;
                if (statusFilter && status !== statusFilter) include = false;
                if (fromDate && poDate < new Date(fromDate)) include = false;
                if (toDate && poDate > new Date(toDate)) include = false;

                let nestedRow = document.getElementById("row-nested-" + row.getAttribute("data-ponum"));
                if (include) {
                    row.style.display = "";
                } else {
                    row.style.display = "none";
                    if(nestedRow) {
                        nestedRow.style.display = "none";
                        let btn = document.getElementById('btn-' + row.getAttribute("data-ponum"));
                        if(btn) btn.innerText = "View Line Items";
                        let block = document.getElementById('items-' + row.getAttribute("data-ponum"));
                        if(block) block.style.display = "none";
                    }
                }
            });
        }

        function clearFilters() {
            document.getElementById("searchInput").value = "";
            document.getElementById("statusFilter").value = "";
            document.getElementById("approvalFilter").value = "";
            document.getElementById("fromDate").value = "";
            document.getElementById("toDate").value = "";
            filterTable();
        }

        function downloadExcel() {
            let table = document.querySelector(".sap-ui-table").outerHTML;
            let blob = new Blob(["\ufeff" + table], { type: "application/vnd.ms-excel" });
            let link = document.createElement("a");
            link.href = URL.createObjectURL(blob);
            link.download = "PO_List_SAP_Format.xls";
            link.click();
        }
    </script>
</head>

<body>

<jsp:include page="header.jsp" />

<div class="sap-fiori-container">

    <!-- Object Header -->
    <div class="sap-object-header">
        <div class="sap-icon-tile">DH</div>
        <div>
            <span class="sap-object-header__subtitle">
                Dining Operations
            </span>
            <h1 class="sap-object-header__title">
                Dining Hall Consumption Report
            </h1>
        </div>
    </div>

    <!-- Filter Bar -->
    <form method="get"
          action="DiningHallConsumptionReportServlet"
          class="sap-filter-bar">

        <input type="date"
               name="from_date"
               value="<%= request.getParameter("from_date") != null ? request.getParameter("from_date") : "" %>">

        <input type="date"
               name="to_date"
               value="<%= request.getParameter("to_date") != null ? request.getParameter("to_date") : "" %>">

        <select name="session">
            <option value="">All Sessions</option>

            <% for(String s : Arrays.asList("BREAKFAST","LUNCH","SNACKS","DINNER")) { %>

                <option value="<%= s %>"
                    <%= s.equals(request.getParameter("session")) ? "selected" : "" %>>
                    <%= s %>
                </option>

            <% } %>
        </select>

        <button type="submit"
                class="sap-btn sap-btn-emphasized">
            Run Report
        </button>

    </form>

    <!-- Main Card -->
    <div class="sap-card-table">

        <div class="table-responsive-container">

            <table class="sap-ui-table">

                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Session</th>
                        <th>Total Consumption Value</th>
                        <th style="text-align:right;">
                            Actions
                        </th>
                    </tr>
                </thead>

                <tbody>

                <%
                double grandTotal = 0;
                int rowNo = 1;

                for(Map.Entry<String,
                        Map<String,List<Map<String,Object>>>> dateEntry
                        : groupedData.entrySet()) {

                    for(Map.Entry<String,List<Map<String,Object>>> sessionEntry
                            : dateEntry.getValue().entrySet()) {

                        List<Map<String,Object>> items =
                                sessionEntry.getValue();

                        double sessionTotal =
                                items.stream()
                                .mapToDouble(r ->
                                    ((Number)r.get("value"))
                                    .doubleValue())
                                .sum();

                        grandTotal += sessionTotal;

                        String rowId = "ROW" + rowNo++;
                %>

                <tr class="sap-master-row">

                    <td data-label="Date"
                        style="font-weight:600;color:#0a6ed1;">
                        <%= dateEntry.getKey() %>
                    </td>

                    <td data-label="Session">
                        <%= sessionEntry.getKey() %>
                    </td>

                    <td data-label="Total Value">

                        <span class="sap-object-status sap-state-approved">
                            ₹ <%= String.format("%.2f", sessionTotal) %>
                        </span>

                    </td>

                    <td data-label="Actions"
                        style="text-align:right;">

                        <div class="sap-action-flex-group">

                            <button
                                type="button"
                                class="sap-btn sap-btn-transparent"
                                id="btn-<%= rowId %>"
                                onclick="toggleItems('<%= rowId %>')">

                                View Items

                            </button>

                        </div>

                    </td>

                </tr>

                <!-- Nested Row -->

                <tr class="sap-nested-row"
                    id="row-nested-<%= rowId %>"
                    style="display:none;">

                    <td colspan="4"
                        style="padding:0 1rem;">

                        <div class="sap-items-block"
                             id="items-<%= rowId %>"
                             style="display:none;">

                            <h4>
                                Consumption Items
                                [<%= dateEntry.getKey() %> -
                                <%= sessionEntry.getKey() %>]
                            </h4>

                            <div class="table-responsive-container">

                                <table class="sap-nested-table">

                                    <thead>
                                        <tr>
                                            <th>Item Name</th>
                                            <th>UOM</th>
                                            <th>Quantity</th>
                                            <th>Value</th>
                                        </tr>
                                    </thead>

                                    <tbody>

                                    <% for(Map<String,Object> item : items) { %>

                                        <tr>
                                            <td>
                                                <%= item.get("item_name") %>
                                            </td>

                                            <td>
                                                <%= item.get("uom") %>
                                            </td>

                                            <td>
                                                <%= item.get("qty") %>
                                            </td>

                                            <td>
                                                ₹ <%= item.get("value") %>
                                            </td>
                                        </tr>

                                    <% } %>

                                    </tbody>

                                </table>

                            </div>

                        </div>

                    </td>

                </tr>

                <% } } %>

                </tbody>

                <tfoot>

                    <tr style="
                        background:#f7f9fa;
                        font-weight:700;">

                        <td colspan="2">
                            Grand Total
                        </td>

                        <td colspan="2"
                            style="text-align:right;">

                            <span class="sap-object-status sap-state-open">
                                ₹ <%= String.format("%.2f", grandTotal) %>
                            </span>

                        </td>

                    </tr>

                </tfoot>

            </table>

        </div>

    </div>

</div>

<script>

function toggleItems(id) {

    var block =
        document.getElementById('items-' + id);

    var row =
        document.getElementById('row-nested-' + id);

    var btn =
        document.getElementById('btn-' + id);

    if(block.style.display === "none" ||
       block.style.display === "") {

        block.style.display = "block";
        row.style.display = "";

        btn.innerText = "Hide Items";

    } else {

        block.style.display = "none";
        row.style.display = "none";

        btn.innerText = "View Items";
    }
}

</script>

<jsp:include page="Footer.jsp" />

</body>
</html>