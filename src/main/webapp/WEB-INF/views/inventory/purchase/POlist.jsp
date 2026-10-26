<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.officecentral.inventory.model.PO, com.officecentral.inventory.model.POItems, java.util.*" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String user = (String) sess.getAttribute("username");
    String role = (String) sess.getAttribute("role");
    // Set by ApprovePOServlet (/approve-po), which also checks roles and the CSRF token on every action
    String poCsrf = (String) request.getAttribute("poCsrf");
    boolean canApprovePo = Boolean.TRUE.equals(request.getAttribute("canApprove"));
    boolean canDeletePo = Boolean.TRUE.equals(request.getAttribute("canDelete"));
    String poMessage = (String) request.getAttribute("poMessage");
%>
<%!
    private static String escPo(Object o) {
        if (o == null) return "";
        return String.valueOf(o).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Approve Purchase Orders</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <style>
        /* SAP Horizon System Design Tokens */
        :root {
            --sap-background: #edf0f2;
            --sap-card-bg: #ffffff;
            --sap-text-color: #1d2d3e;
            --sap-subtitle-color: #516273;
            --sap-border-color: #d1d5db;
            --sap-primary-btn: #0070f2;
            --sap-primary-btn-hover: #005bc4;
            --sap-secondary-btn: #ffffff;
            --sap-secondary-btn-border: #b3b9c1;
            
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
            padding: 1.5rem 2rem;
            max-width: 1600px;
            margin: 0 auto;
            box-sizing: border-box;
        }

        /* SAP Fiori Object Header Module */
        .sap-object-header {
            background: var(--sap-card-bg);
            padding: 1.25rem 1.5rem;
            border-radius: 0.5rem;
            border: 1px solid var(--sap-border-color);
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.03);
            margin-bottom: 1rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 1rem;
        }

        .sap-header-content {
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

        /* SAP Fiori Filter Bar Component */
        .sap-filter-bar {
            background: var(--sap-card-bg);
            border: 1px solid var(--sap-border-color);
            border-radius: 0.5rem;
            padding: 1rem 1.5rem;
            margin-bottom: 1rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.02);
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            gap: 1.5rem;
        }

        .sap-filter-group {
            display: flex;
            flex-direction: column;
            gap: 0.375rem;
        }

        .sap-filter-group label {
            font-size: 0.75rem;
            font-weight: 600;
            color: var(--sap-subtitle-color);
        }

        .sap-filter-input {
            height: 2.25rem;
            padding: 0 0.5rem;
            border: 1px solid var(--sap-b3b9c1);
            border-radius: 0.25rem;
            font-family: inherit;
            font-size: 0.875rem;
            color: var(--sap-text-color);
            box-sizing: border-box;
            background: #ffffff;
            outline: none;
            min-width: 180px;
        }

        .sap-filter-input:focus {
            border-color: var(--sap-primary-btn);
        }

        /* SAP Fiori Responsive Table Card Layout */
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
            text-align: center;
        }

        table.sap-ui-table th {
            background: #f3f5f7;
            color: var(--sap-text-color);
            font-weight: 600;
            font-size: 0.8125rem;
            height: 2.5rem;
        }

        table.sap-ui-table tbody tr.sap-master-row:hover td {
            background-color: rgba(0, 112, 242, 0.03);
        }

        /* SAP Fiori Layout Buttons */
        .action-btn {
            background: var(--sap-secondary-btn);
            color: var(--sap-primary-btn);
            border: 1px solid var(--sap-primary-btn);
            padding: 0 0.75rem;
            height: 2rem;
            border-radius: 0.25rem;
            cursor: pointer;
            font-size: 0.8125rem;
            font-weight: 600;
            font-family: inherit;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            box-sizing: border-box;
            transition: all 0.1s ease-in-out;
            margin: 2px;
        }

        .action-btn:hover {
            background: #e8f4ff;
        }

        .approve-btn {
            background: var(--sap-primary-btn);
            color: #ffffff;
            border-color: transparent;
        }

        .approve-btn:hover {
            background: var(--sap-primary-btn-hover);
            color: #ffffff;
        }

        .delete-btn {
            color: var(--sap-state-error-text);
            border-color: var(--sap-state-error-text);
        }

        .delete-btn:hover {
            background: var(--sap-state-error-bg);
        }

        .grn-btn {
            color: var(--sap-state-success-text);
            border-color: var(--sap-state-success-text);
        }

        .grn-btn:hover {
            background: var(--sap-state-success-bg);
        }

        .excel-btn {
            background: #107e3e;
            color: #ffffff;
            border-color: transparent;
        }

        .excel-btn:hover {
            background: #0b592b;
            color: #ffffff;
        }

        .expand-btn, .print-btn, .clear-btn {
            color: var(--sap-text-color);
            border-color: var(--sap-secondary-btn-border);
        }

        .expand-btn:hover, .print-btn:hover, .clear-btn:hover {
            background: #f0f2f5;
        }

        .disabled {
            background: #eff1f3 !important;
            border-color: #d1d5db !important;
            color: #a1a8b3 !important;
            cursor: not-allowed !important;
        }

        /* Nested Line Item Allocation Grid */
        .sap-nested-row {
            background: #f8fafc;
        }

        .items-block {
            padding: 1.25rem;
            background: #ffffff;
            border: 1px solid var(--sap-border-color);
            border-left: 4px solid var(--sap-primary-btn);
            border-radius: 0.375rem;
            margin: 0.5rem auto;
            width: 96%;
            box-sizing: border-box;
            display: none;
            animation: slideDown 0.3s ease-out;
        }

        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-5px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .items-block h4 {
            margin: 0 0 0.75rem 0;
            font-size: 0.9375rem;
            color: var(--sap-text-color);
            font-weight: 600;
            text-align: left;
            border-bottom: 1px solid var(--sap-border-color);
            padding-bottom: 0.5rem;
        }

        .items-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.8125rem;
            margin-top: 10px;
        }

        .items-table th {
            background: #f0f2f5;
            color: var(--sap-text-color);
            border: 1px solid var(--sap-border-color);
            height: 2.25rem;
            font-weight: 600;
        }

        .items-table td {
            border: 1px solid var(--sap-border-color);
            padding: 0.625rem 0.875rem;
            background: #ffffff;
            text-align: center;
        }

        .items-table tr:hover td {
            background: #f8fafc;
        }

        .no-data {
            text-align: center;
            color: var(--sap-state-error-text);
            padding: 1.5rem;
            font-weight: 600;
            background: var(--sap-state-error-bg);
            border: 1px dashed var(--sap-state-error-text);
            border-radius: 0.25rem;
            margin: 10px 0;
        }

        .sap-flex-cell {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 4px;
            flex-wrap: wrap;
        }

        /* Responsive Breakpoints Rules */
        @media screen and (max-width: 1024px) {
            .sap-fiori-container { padding: 1rem; }
            .sap-filter-bar { gap: 1rem; }
        }

        @media screen and (max-width: 768px) {
            .sap-object-header { flex-direction: column; align-items: flex-start; }
            .sap-filter-bar { flex-direction: column; align-items: stretch; gap: 0.75rem; }
            .sap-filter-input { min-width: 100%; }
            .sap-flex-cell { width: 100%; justify-content: flex-end; }
            
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
                text-align: right;
            }
            table.sap-ui-table td:last-child { border-bottom: none; }
            table.sap-ui-table td:before {
                content: attr(data-label);
                font-weight: 600;
                color: var(--sap-subtitle-color);
                font-size: 0.75rem;
                float: left;
            }
        }
    </style>

   <script>
    function toggleItems(id) {
        const block = document.getElementById("items-" + id);
        const btn = document.getElementById("btn-" + id);
        const parentRow = document.getElementById("row-nested-" + id);

        if (block.style.display === "none" || block.style.display === "") {
            block.style.display = "block";
            if (parentRow) parentRow.style.display = "";
            btn.value = "Hide Items";
        } else {
            block.style.display = "none";
            if (parentRow) parentRow.style.display = "none";
            btn.value = "Show Items";
        }
    }

    function filterByDates() {

        const fromInput = document.getElementById("filterFromDate").value;
        const toInput = document.getElementById("filterToDate").value;

        if (!fromInput || !toInput) {
            alert("Please select both From and To dates.");
            return;
        }

        const fromDate = new Date(fromInput);
        fromDate.setHours(0, 0, 0, 0);

        const toDate = new Date(toInput);
        toDate.setHours(23, 59, 59, 999);

        if (fromDate > toDate) {
            alert("From Date cannot be greater than To Date.");
            return;
        }

        const rows = document.querySelectorAll(".sap-master-row");
        let visibleCount = 0;

        rows.forEach(row => {

            const rawIsoDateStr = row.getAttribute("data-raw-date");
            const nestedId = row.getAttribute("data-nested-id");
            const nestedRow = document.getElementById("row-nested-" + nestedId);

            if (rawIsoDateStr && rawIsoDateStr !== "") {

                const rowDate = new Date(rawIsoDateStr);
                rowDate.setHours(0, 0, 0, 0);

                if (rowDate >= fromDate && rowDate <= toDate) {

                    row.style.display = "";
                    visibleCount++;

                } else {

                    row.style.display = "none";

                    if (nestedRow)
                        nestedRow.style.display = "none";

                    const itemBtn =
                        document.getElementById("btn-" + nestedId);

                    if (itemBtn)
                        itemBtn.value = "Show Items";

                    const itemBlock =
                        document.getElementById("items-" + nestedId);

                    if (itemBlock)
                        itemBlock.style.display = "none";
                }

            } else {

                row.style.display = "";
                visibleCount++;
            }
        });

        const noDataFallbackRow =
            document.getElementById("js-nodata-fallback");

        if (visibleCount === 0) {

            if (!noDataFallbackRow) {

                const tbody =
                    document.querySelector(".sap-ui-table tbody");

                const fallbackTr =
                    document.createElement("tr");

                fallbackTr.id = "js-nodata-fallback";

                fallbackTr.innerHTML =
                    '<td colspan="9" class="no-data">No Purchase Orders Found within selected dates.</td>';

                tbody.appendChild(fallbackTr);

            } else {

                noDataFallbackRow.style.display = "";
            }

        } else {

            if (noDataFallbackRow)
                noDataFallbackRow.style.display = "none";
        }
    }

    function clearDateFilters() {

        document.getElementById("filterFromDate").value = "";
        document.getElementById("filterToDate").value = "";

        document.querySelectorAll(".sap-master-row").forEach(row => {
            row.style.display = "";
        });

        const noDataFallbackRow =
            document.getElementById("js-nodata-fallback");

        if (noDataFallbackRow)
            noDataFallbackRow.style.display = "none";
    }

    function exportToExcel() {

        let csvContent = "\uFEFF";

        csvContent += "PURCHASE ORDERS EXPORT REPORT\r\n";
        csvContent += "Generated On," +
            new Date().toLocaleString() +
            "\r\n\r\n";

        csvContent +=
            "PO Number,PO Date,Vendor Name,Total Amount,Approval Status,Item ID,Item Description,PO Qty,Received Qty,Balance Qty,Rate,Discount %,GST %\r\n";

        const rows =
            document.querySelectorAll(".sap-master-row");

        if (rows.length === 0) {
            alert("No records found.");
            return;
        }

        let recordCount = 0;

        rows.forEach(row => {

            if (row.style.display === "none")
                return;

            const poNumber =
                '"' + (row.querySelector('[data-label="PO Number"]')?.textContent || '')
                    .trim()
                    .replace(/"/g, '""') + '"';

            const poDate =
                '"' + (row.querySelector('[data-label="PO Date"]')?.textContent || '')
                    .trim()
                    .replace(/"/g, '""') + '"';

            const vendorName =
                '"' + (row.querySelector('[data-label="Vendor Name"]')?.textContent || '')
                    .trim()
                    .replace(/"/g, '""') + '"';

            const totalAmount =
                '"' + (row.querySelector('[data-label="Total Amount"]')?.textContent || '')
                    .trim()
                    .replace(/"/g, '""') + '"';

            const status =
                '"' + (row.querySelector('[data-label="Approval Status"]')?.textContent || '')
                    .trim()
                    .replace(/"/g, '""') + '"';

            const nestedId =
                row.getAttribute("data-nested-id");

            let itemRows = [];

            try {

                itemRows = document.querySelectorAll(
                    '#items-' +
                    CSS.escape(nestedId) +
                    ' .items-table tbody tr'
                );

            } catch (e) {

                itemRows = document.querySelectorAll(
                    '#items-' +
                    nestedId.replace(/([ !"#$%&'()*+,./:;<=>?@[\\\]^`{|}~])/g, '\\$1') +
                    ' .items-table tbody tr'
                );
            }

            if (itemRows.length > 0) {

                itemRows.forEach(itemRow => {

                    const itemId =
                        '"' + (itemRow.cells[0]?.textContent || '')
                            .trim()
                            .replace(/"/g, '""') + '"';

                    const itemDesc =
                        '"' + (itemRow.cells[1]?.textContent || '')
                            .trim()
                            .replace(/"/g, '""') + '"';

                    const qty =
                        '"' + (itemRow.cells[2]?.textContent || '')
                            .trim()
                            .replace(/"/g, '""') + '"';

                    const recQty =
                        '"' + (itemRow.cells[3]?.textContent || '')
                            .trim()
                            .replace(/"/g, '""') + '"';

                    const balQty =
                        '"' + (itemRow.cells[4]?.textContent || '')
                            .trim()
                            .replace(/"/g, '""') + '"';

                    const rate =
                        '"' + (itemRow.cells[5]?.textContent || '')
                            .trim()
                            .replace(/"/g, '""') + '"';

                    const discount =
                        '"' + (itemRow.cells[6]?.textContent || '')
                            .trim()
                            .replace(/"/g, '""') + '"';

                    const gst =
                        '"' + (itemRow.cells[7]?.textContent || '')
                            .trim()
                            .replace(/"/g, '""') + '"';

                    csvContent +=
                        poNumber + "," +
                        poDate + "," +
                        vendorName + "," +
                        totalAmount + "," +
                        status + "," +
                        itemId + "," +
                        itemDesc + "," +
                        qty + "," +
                        recQty + "," +
                        balQty + "," +
                        rate + "," +
                        discount + "," +
                        gst + "\r\n";

                    recordCount++;
                });

            } else {

                csvContent +=
                    poNumber + "," +
                    poDate + "," +
                    vendorName + "," +
                    totalAmount + "," +
                    status +
                    ',"-","-","-","-","-","-","-","-"\r\n';

                recordCount++;
            }
        });

        if (recordCount === 0) {
            alert("No data available for export.");
            return;
        }

        const blob = new Blob(
            [csvContent],
            {
                type: "text/csv;charset=utf-8;"
            }
        );

        const url =
            URL.createObjectURL(blob);

        const link =
            document.createElement("a");

        link.href = url;

        link.download =
            "Purchase_Orders_Report_" +
            new Date().toISOString().substring(0, 10) +
            ".csv";

        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        URL.revokeObjectURL(url);
    }
</script>
</head>

<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />
<% if (poMessage != null && !poMessage.isEmpty()) { %>
<div style="max-width:1400px;margin:12px auto 0;padding:10px 14px;border-radius:6px;font-size:14px;background:#eef4fe;border:1px solid #aacbfa;color:#1d2d3e;" role="status">
    <%= escPo(poMessage) %>
</div>
<% } %>

<div class="sap-fiori-container">
    
    <div class="sap-object-header">
        <div class="sap-header-content">
            <div class="sap-icon-tile">PO</div>
            <div>
                <span class="sap-object-header__subtitle">Procurement Release Workflow</span>
                <h1 class="sap-object-header__title">Purchase Orders</h1>
            </div>
        </div>
        <div>
            <button class="action-btn excel-btn" onclick="exportToExcel()">
                Download Excel Report
            </button>
        </div>
    </div>

    <div class="sap-filter-bar">
        <div class="sap-filter-group">
            <label for="filterFromDate">PO From Date</label>
            <input type="date" id="filterFromDate" class="sap-filter-input">
        </div>
        <div class="sap-filter-group">
            <label for="filterToDate">PO To Date</label>
            <input type="date" id="filterToDate" class="sap-filter-input">
        </div>
        <div class="sap-filter-group" style="flex-direction: row; gap: 8px;">
            <button type="button" class="action-btn approve-btn" onclick="filterByDates()">Apply Filter</button>
            <button type="button" class="action-btn clear-btn" onclick="clearDateFilters()">Clear</button>
        </div>
    </div>

    <div class="sap-card-table">
        <div class="table-responsive-container">
            <table class="sap-ui-table">
                <thead>
                    <tr>
                        <th>PO Number</th>
                        <th>PO Date</th>
                        <th>Vendor Name</th>
                        <th>Total Amount</th>
                        <th>Approval Status</th>
                        <th>Action</th>
                        <th>Print</th>
                        <th>GRN</th>
                        <th>Items</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    List<PO> list = (List<PO>) request.getAttribute("poList");
                    if (list != null && !list.isEmpty()) {
                        
                        // SORTING LOGIC: Moves non-Approved items to the top
                        Collections.sort(list, new Comparator<PO>() {
                            @Override
                            public int compare(PO po1, PO po2) {
                                boolean isApproved1 = "Approved".equalsIgnoreCase(po1.getApproval());
                                boolean isApproved2 = "Approved".equalsIgnoreCase(po2.getApproval());
                                
                                if (!isApproved1 && isApproved2) {
                                    return -1; // Move non-approved po1 up
                                } else if (isApproved1 && !isApproved2) {
                                    return 1;  // Move non-approved po2 up
                                }
                                return 0; // Maintain original order if same status group
                            }
                        });

                        // Array Matrix for database string format parsing checks
                        String[] datePatterns = {"yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss.S", "yyyy-MM-dd HH:mm:ss", "dd-MM-yyyy"};

                        for (PO po : list) {
                            String approval = po.getApproval();
                            String poId = po.getPoNumber().replaceAll("\\s+", "_");
                            
                            String rawIsoDate = "";
                            String displayFormattedDate = "-";
                            
                            if (po.getPoDate() != null && !po.getPoDate().trim().isEmpty()) {
                                String cleanDateStr = po.getPoDate().trim();
                                java.util.Date parsedDate = null;
                                
                                // Cycle through common configurations until match found
                                for (String pattern : datePatterns) {
                                    try {
                                        java.text.SimpleDateFormat parser = new java.text.SimpleDateFormat(pattern);
                                        parser.setLenient(false);
                                        parsedDate = parser.parse(cleanDateStr);
                                        break; 
                                    } catch (Exception e) {
                                        // Continue searching valid configurations
                                    }
                                }
                                
                                if (parsedDate != null) {
                                    java.text.SimpleDateFormat isoFormatter = new java.text.SimpleDateFormat("yyyy-MM-dd");
                                    rawIsoDate = isoFormatter.format(parsedDate);
                                    
                                    java.text.SimpleDateFormat targetFormatter = new java.text.SimpleDateFormat("dd-MMMM-yyyy");
                                    displayFormattedDate = targetFormatter.format(parsedDate);
                                } else {
                                    // Raw string value fallback mapping
                                    displayFormattedDate = cleanDateStr;
                                    rawIsoDate = "";
                                }
                            }
                %>
                    <tr class="sap-master-row" data-raw-date="<%= rawIsoDate %>" data-nested-id="<%= poId %>">
                        <td data-label="PO Number" style="font-weight: 600; color: #0a6ed1;"><%= po.getPoNumber() %></td>
                        <td data-label="PO Date"><%= displayFormattedDate %></td>
                        <td data-label="Vendor Name"><%= po.getVendorName() %></td>
                        <td data-label="Total Amount" style="font-weight: 600;"><%= po.getTotalAmount() %></td>
                        <td data-label="Approval Status" style="font-weight: 600;"><%= approval %></td>

                        <td data-label="Action">
                           <div class="sap-flex-cell">
                            <% if (canDeletePo) { %>
                            <form action="approve-po" method="post" style="margin:0;">
                                <input type="hidden" name="csrf" value="<%= escPo(poCsrf) %>">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="poNumber" value="<%= escPo(po.getPoNumber()) %>">
                                <input type="submit" value="Delete"
                                    class="action-btn <%= !"Approved".equalsIgnoreCase(approval) ? "delete-btn" : "disabled" %>"
                                    <%= !"Approved".equalsIgnoreCase(approval) ? "" : "disabled" %>
                                    onclick="return confirm('Are you sure you want to delete this record?');" />
                            </form>
                            <% } %>

                            <% if (canApprovePo) { %>
                            <form action="approve-po" method="post" style="margin:0;">
                                <input type="hidden" name="csrf" value="<%= escPo(poCsrf) %>">
                                <input type="hidden" name="action" value="approve">
                                <input type="hidden" name="poNumber" value="<%= escPo(po.getPoNumber()) %>">
                                <input type="submit" value="Approve"
                                    class="action-btn <%= !"Approved".equalsIgnoreCase(approval) ? "approve-btn" : "disabled" %>"
                                    <%= (!"Approved".equalsIgnoreCase(approval)) ? "" : "disabled" %>
                                    onclick="return confirm('Are you sure you want to approve this record?');">
                            </form>
                            <% } %>
                           </div>
                        </td>

                        <td data-label="Print">
                            <form action="PrintPO.jsp" method="get" target="_blank" style="margin:0;">
                                <input type="hidden" name="poNumber" value="<%= po.getPoNumber() %>">
                                <input type="submit" value="View / Print" class="action-btn print-btn" />
                            </form>
                            <button type="button" class="action-btn mail-btn"
                                data-po="<%= String.valueOf(po.getPoNumber()).replace("&", "&amp;").replace("\"", "&quot;").replace("<", "&lt;") %>"
                                onclick="openPoMail(this.dataset.po)">Send Mail</button>
                        </td>

                        <td data-label="GRN">
                            <form action="grn" method="get" style="margin:0;">
                                <input type="hidden" name="po_number" value="<%= po.getPoNumber() %>">
                                <input type="submit" value="GRN"
                                    class="action-btn <%= "Approved".equalsIgnoreCase(approval) ? "grn-btn" : "disabled" %>"
                                    <%= "Approved".equalsIgnoreCase(approval) ? "" : "disabled" %> />
                            </form>
                        </td>

                        <td data-label="Items">
                            <input type="button" id="btn-<%= poId %>" value="Show Items"
                                class="action-btn expand-btn" onclick="toggleItems('<%= poId %>')">
                        </td>
                    </tr>

                    <tr class="sap-nested-row" id="row-nested-<%= poId %>" style="display: none;">
                        <td colspan="9" style="padding:0;">
                            <div class="items-block" id="items-<%= poId %>">
                                <h4>Items for PO: <%= po.getPoNumber() %></h4>
                                <%
                                    if (po.getItems() != null && !po.getItems().isEmpty()) {
                                %>
                                <div class="table-responsive-container">
                                    <table class="items-table">
                                        <thead>
                                            <tr>
                                                <th>Item ID</th>
                                                <th>Description</th>
                                                <th>PO Quantity</th>
                                                <th>Received Qty</th>
                                                <th>Balance to Receive</th>
                                                <th>Rate</th>
                                                <th>Discount %</th>
                                                <th>GST %</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% for (POItems item : po.getItems()) { %>
                                            <tr>
                                                <td style="font-weight: 600;"><%= item.getItemId() %></td>
                                                <td style="text-align: left;"><%= item.getItemName() %></td>
                                                <td><%= item.getQty() %></td>
                                                <td><%= item.getReceivedQty() %></td>
                                                <td style="font-weight: 600; color: <%= item.gettobeReceivedQty() > 0 ? "var(--sap-state-warning-text)" : "inherit" %>;"><%= item.gettobeReceivedQty() %></td>
                                                <td><%= item.getRate() %></td>
                                                <td><%= item.getDiscountPercent() %></td>
                                                <td><%= item.getGstPercent() %></td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                                <% } else { %>
                                <p class="no-data">No items found for this PO.</p>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                <% 
                        }
                    } else { 
                %>
                    <tr>
                        <td colspan="9" class="no-data">No Purchase Orders Found</td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- ===== Send PO by mail (Finance / Global / Admin users of this store) ===== -->
<style>
    .mail-btn { margin-top: 6px; color: #0a6ed1; border-color: #0a6ed1; background: #fff; }
    .mail-btn:hover { background: #e8f4ff; }
    .pm-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, .45); display: none; align-items: center;
                  justify-content: center; z-index: 3000; padding: 16px; }
    .pm-overlay.open { display: flex; }
    .pm-box { background: #fff; width: 100%; max-width: 520px; max-height: 90vh; display: flex; flex-direction: column;
              border-radius: 10px; box-shadow: 0 18px 50px rgba(0,0,0,.25); overflow: hidden; }
    .pm-head { padding: 14px 18px; border-bottom: 1px solid #e5e7eb; display: flex; justify-content: space-between; align-items: center; }
    .pm-head h3 { margin: 0; font-size: 16px; color: #1d2d3e; }
    .pm-head small { display: block; color: #516273; font-weight: 400; margin-top: 2px; }
    .pm-x { border: 0; background: none; font-size: 22px; line-height: 1; cursor: pointer; color: #516273; }
    .pm-body { padding: 14px 18px; overflow: auto; }
    .pm-tools { display: flex; justify-content: space-between; align-items: center; font-size: 13px; margin-bottom: 8px; color: #516273; }
    .pm-tools label { white-space: nowrap; margin-left: 10px; cursor: pointer; }
    .pm-list { border: 1px solid #e5e7eb; border-radius: 8px; max-height: 260px; overflow: auto; }
    .pm-item { display: flex; gap: 10px; align-items: flex-start; padding: 9px 12px; border-bottom: 1px solid #f0f2f5; cursor: pointer; }
    .pm-item:last-child { border-bottom: 0; }
    .pm-item:hover { background: #f7f9fb; }
    .pm-item input { margin-top: 3px; width: 16px; height: 16px; }
    .pm-name { font-weight: 600; color: #1d2d3e; font-size: 14px; }
    .pm-meta { font-size: 12px; color: #516273; word-break: break-all; }
    .pm-tag { display: inline-block; font-size: 11px; padding: 1px 7px; border-radius: 10px; background: #e8f4ff; color: #0a6ed1; margin-left: 6px; }
    .pm-note { width: 100%; box-sizing: border-box; margin-top: 12px; min-height: 64px; border: 1px solid #d1d5db; border-radius: 6px;
               padding: 8px 10px; font: inherit; font-size: 13px; resize: vertical; }
    .pm-msg { margin-top: 10px; font-size: 13px; border-radius: 6px; padding: 8px 10px; display: none; white-space: pre-line; }
    .pm-msg.ok { display: block; background: #e5f5ed; color: #107e3e; }
    .pm-msg.err { display: block; background: #ffebeb; color: #bb0000; }
    .pm-msg.info { display: block; background: #e8f4ff; color: #0a6ed1; }
    .pm-foot { padding: 12px 18px; border-top: 1px solid #e5e7eb; display: flex; justify-content: flex-end; gap: 8px; }
    .pm-foot button { height: 36px; padding: 0 18px; border-radius: 6px; font-weight: 600; cursor: pointer; font-size: 14px; }
    .pm-cancel { background: #fff; border: 1px solid #b3b9c1; color: #1d2d3e; }
    .pm-send { background: #0070f2; border: 1px solid #0070f2; color: #fff; }
    .pm-send:disabled { opacity: .55; cursor: not-allowed; }
    @media (max-width: 600px) { .pm-box { max-height: 96vh; } .pm-foot button { flex: 1; } }
</style>

<div class="pm-overlay" id="pmOverlay" role="dialog" aria-modal="true" aria-labelledby="pmTitle">
  <div class="pm-box">
    <div class="pm-head">
      <h3 id="pmTitle">Send Purchase Order<small id="pmSub"></small></h3>
      <button type="button" class="pm-x" onclick="closePoMail()" aria-label="Close">&times;</button>
    </div>
    <div class="pm-body">
      <div class="pm-tools">
        <span>Finance, Global and Admin users of this store</span>
        <label><input type="checkbox" id="pmAll"> Select all</label>
      </div>
      <div class="pm-list" id="pmList"></div>
      <textarea class="pm-note" id="pmNote" maxlength="1000" placeholder="Message (optional) - shown at the top of the mail"></textarea>
      <div class="pm-msg" id="pmMsg"></div>
    </div>
    <div class="pm-foot">
      <button type="button" class="pm-cancel" onclick="closePoMail()">Close</button>
      <button type="button" class="pm-send" id="pmSend" onclick="sendPoMail()" disabled>Send mail</button>
    </div>
  </div>
</div>

<script>
(function () {
  var CTX = '<%= request.getContextPath() %>';
  var current = null;
  var $ = function (id) { return document.getElementById(id); };

  function msg(text, kind) { var m = $('pmMsg'); m.className = 'pm-msg ' + (kind || ''); m.textContent = text || ''; }
  function chosen() { return Array.prototype.slice.call(document.querySelectorAll('#pmList input:checked')); }
  function refresh() {
    var all = document.querySelectorAll('#pmList input'), on = chosen().length;
    $('pmSend').disabled = on === 0;
    $('pmSend').textContent = on > 1 ? 'Send mail (' + on + ')' : 'Send mail';
    $('pmAll').checked = all.length > 0 && on === all.length;
  }
  function esc(s) { var d = document.createElement('div'); d.textContent = s == null ? '' : String(s); return d.innerHTML; }

  window.openPoMail = function (po) {
    current = po;
    $('pmSub').textContent = 'PO ' + po + ' – the PDF of the PO is attached';
    $('pmList').innerHTML = '<div class="pm-item" style="cursor:default">Loading users…</div>';
    $('pmNote').value = '';
    $('pmAll').checked = false;
    msg('');
    refresh();
    $('pmOverlay').classList.add('open');
    fetch(CTX + '/po-mail?poNumber=' + encodeURIComponent(po), { credentials: 'same-origin' })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (d.error) { $('pmList').innerHTML = ''; msg(d.error, 'err'); return; }
        if (!d.users || !d.users.length) {
          $('pmList').innerHTML = '<div class="pm-item" style="cursor:default">No Finance, Global or Admin user with an e-mail address is assigned to this store.</div>';
          return;
        }
        $('pmList').innerHTML = d.users.map(function (u) {
          var tag = u.department && u.department.toLowerCase() === 'finance' ? 'Finance' : u.role;
          return '<label class="pm-item"><input type="checkbox" value="' + u.id + '">' +
                 '<span><span class="pm-name">' + esc(u.name) + '</span><span class="pm-tag">' + esc(tag) + '</span>' +
                 '<div class="pm-meta">' + esc(u.mail) + (u.department ? ' &middot; ' + esc(u.department) : '') + '</div></span></label>';
        }).join('');
        document.querySelectorAll('#pmList input').forEach(function (c) { c.addEventListener('change', refresh); });
        refresh();
      })
      .catch(function () { $('pmList').innerHTML = ''; msg('Could not load the users. Please try again.', 'err'); });
  };

  window.closePoMail = function () { $('pmOverlay').classList.remove('open'); current = null; };

  window.sendPoMail = function () {
    var picks = chosen();
    if (!current || !picks.length) return;
    var body = new URLSearchParams();
    body.append('poNumber', current);
    body.append('note', $('pmNote').value);
    picks.forEach(function (c) { body.append('userId', c.value); });
    $('pmSend').disabled = true;
    $('pmSend').textContent = 'Sending…';
    msg('Sending the PO…', 'info');
    fetch(CTX + '/po-mail', { method: 'POST', credentials: 'same-origin', body: body })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (d.error) { msg(d.error, 'err'); return; }
        var lines = [];
        if (d.sent && d.sent.length) lines.push('Sent to: ' + d.sent.join(', '));
        if (d.failed && d.failed.length) lines.push('Not sent: ' + d.failed.map(function (f) { return f.to + ' (' + f.reason + ')'; }).join('; '));
        msg(lines.join('\n'), d.ok ? 'ok' : 'err');
      })
      .catch(function () { msg('The mail could not be sent. Please try again.', 'err'); })
      .then(function () { refresh(); });
  };

  $('pmAll').addEventListener('change', function () {
    var on = this.checked;
    document.querySelectorAll('#pmList input').forEach(function (c) { c.checked = on; });
    refresh();
  });
  $('pmOverlay').addEventListener('click', function (e) { if (e.target === this) closePoMail(); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && $('pmOverlay').classList.contains('open')) closePoMail(); });
})();
</script>

<jsp:include page="/WEB-INF/views/layout/Footer.jsp" />
</body>
</html>