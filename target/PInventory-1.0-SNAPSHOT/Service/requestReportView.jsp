<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Assigned & Completed Requests Report</title>
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght=400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <style>
        :root {
            --slds-g-color-neutral-base-10: #f3f3f3;
            --slds-g-color-neutral-base-100: #ffffff;
            --text-main: #181818;
            --text-secondary: #475569;
            --slds-brand: #0176d3;
            --slds-brand-hover: #015a9e;
            --slds-border: #e5e7eb;
            --slds-row-hover: #f8fafc;
            --badge-bg: #e0f2fe;
            --badge-text: #0369a1;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Inter', system-ui, sans-serif;
            background-color: #f3f4f6;
            color: var(--text-main);
            padding: 24px;
            -webkit-font-smoothing: antialiased;
        }

        .report-container {
            max-width: 1650px;
            margin: 0 auto;
        }

        .slds-page-header {
            background: var(--slds-g-color-neutral-base-100);
            padding: 16px 24px;
            border: 1px solid #d8dde6;
            border-radius: 8px 8px 0 0;
            display: flex;
            align-items: center;
            justify-content: space-between;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }

        .slds-page-header__left {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .slds-icon-wrapper {
            background-color: #4bc076; 
            color: white;
            width: 40px;
            height: 40px;
            border-radius: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
        }

        .slds-page-header__title {
            font-size: 18px;
            font-weight: 700;
            color: var(--text-main);
            line-height: 1.2;
        }

        .slds-btn-excel {
            background-color: #ffffff;
            color: #107c41;
            border: 1px solid #cbd5e1;
            padding: 8px 16px;
            font-size: 13px;
            font-weight: 600;
            border-radius: 4px;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.15s ease;
            box-shadow: 0 1px 2px rgba(0,0,0,0.05);
        }

        .slds-btn-excel:hover {
            background-color: #f0fdf4;
            border-color: #107c41;
            transform: translateY(-1px);
        }

        /* Modern Summary Metrics Layout Styles */
        .summary-dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 16px;
            background: #ffffff;
            border: 1px solid #d8dde6;
            border-top: none;
            padding: 20px 24px;
        }

        .dept-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 14px 16px;
        }

        .dept-card__title {
            font-size: 13px;
            font-weight: 700;
            color: #334155;
            margin-bottom: 10px;
            border-bottom: 1px dashed #cbd5e1;
            padding-bottom: 4px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .dept-card__metrics {
            display: flex;
            justify-content: space-between;
            gap: 12px;
        }

        .metric-sub {
            flex: 1;
            background: #ffffff;
            padding: 8px;
            border-radius: 4px;
            border: 1px solid #e2e8f0;
            text-align: center;
        }

        .metric-sub.active-box { border-left: 3px solid #166534; }
        .metric-sub.closed-box { border-left: 3px solid #475569; }

        .metric-sub label {
            display: block;
            font-size: 11px;
            font-weight: 600;
            color: #64748b;
            text-transform: uppercase;
            margin-bottom: 2px;
        }

        .metric-sub span {
            font-size: 16px;
            font-weight: 700;
            color: var(--text-main);
        }

        .slds-filter-bar {
            background: #ffffff;
            border: 1px solid #d8dde6;
            border-top: none;
            padding: 12px 24px;
            display: flex;
            align-items: center;
            gap: 12px;
            background-color: #f8fafc;
        }

        .slds-filter-label {
            font-size: 12px;
            font-weight: 700;
            color: #475569;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .slds-filter-select {
            min-width: 200px;
            padding: 6px 12px;
            font-size: 13px;
            font-weight: 600;
            color: #334155;
            background-color: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 4px;
            outline: none;
            cursor: pointer;
        }

        .slds-table-container {
            background: var(--slds-g-color-neutral-base-100);
            border: 1px solid #d8dde6;
            border-top: none;
            border-radius: 0 0 8px 8px;
            overflow: hidden;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
        }

        th {
            background-color: #fafafb;
            color: #475569;
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 12px 16px;
            border-bottom: 2px solid #e2e8f0;
        }

        td {
            padding: 14px 16px;
            font-size: 13px;
            color: #334155;
            border-bottom: 1px solid var(--slds-border);
            vertical-align: top;
            line-height: 1.5;
        }

        .request-row {
            cursor: pointer;
            transition: background 0.1s ease;
        }

        .request-row:hover td {
            background-color: var(--slds-row-hover);
        }

        .chevron-icon {
            color: #94a3b8;
            transition: transform 0.2s ease;
            margin-right: 4px;
        }
        
        .request-row.is-expanded .chevron-icon {
            transform: rotate(90deg);
            color: var(--slds-brand);
        }

        .drilldown-row {
            background-color: #f8fafc;
            display: none; 
        }

        .drilldown-row td {
            padding: 0;
            border-bottom: 1px solid #e2e8f0;
        }

        .drilldown-wrapper {
            padding: 16px 24px 24px 52px;
            background: #f8fafc;
            border-left: 4px solid var(--slds-brand);
        }

        .drilldown-title {
            font-size: 12px;
            font-weight: 700;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .followup-table {
            width: 100%;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            box-shadow: inset 0 1px 2px rgba(0,0,0,0.02);
        }

        .followup-table th {
            background-color: #f1f5f9;
            color: #64748b;
            padding: 8px 14px;
            font-size: 11px;
            border-bottom: 1px solid #e2e8f0;
        }

        .followup-table td {
            padding: 10px 14px;
            font-size: 12.5px;
            color: #475569;
            border-bottom: 1px solid #f1f5f9;
        }

        .ticket-link {
            color: var(--slds-brand);
            font-weight: 700;
            text-decoration: none;
        }
        
        .days-badge {
            display: inline-flex;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 700;
            background-color: var(--badge-bg);
            color: var(--badge-text);
        }
        
        .days-badge.unresolved { 
            background-color: #fef3c7; 
            color: #d97706; 
        }
        
        .status-pill {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
        }
        .status-pill.closed { background: #e2e8f0; color: #334155; }
        .status-pill.active { background: #dcfce7; color: #166534; }
        
        .empty-state, .error-message {
            text-align: center;
            padding: 40px 20px;
            color: var(--text-secondary);
        }
    </style>
</head>
<body>

<div class="report-container">
    
    <header class="slds-page-header">
        <div class="slds-page-header__left">
            <div class="slds-icon-wrapper">
                <i class="fas fa-chart-line"></i>
            </div>
            <div>
                <h1 class="slds-page-header__title">Assigned & Completed Requests Report</h1>
            </div>
        </div>
        <div>
            <button type="button" class="slds-btn-excel" onclick="triggerExcelDownload()">
                <i class="fas fa-file-excel"></i> Export Report to Excel
            </button>
        </div>
    </header>

    <div id="summaryDashboard" class="summary-dashboard">
    </div>

    <div class="slds-filter-bar">
        <label class="slds-filter-label" for="statusFilter"><i class="fas fa-filter"></i> Current Status:</label>
        <select id="statusFilter" class="slds-filter-select" onchange="filterReportByStatus()">
            <option value="ALL">All Current Statuses</option>
            <option value="ACTIVE">Active (Unclosed)</option>
            <option value="CLOSED">Closed</option>
        </select>
    </div>

    <div class="slds-table-container">
        <table id="reportTable">
            <thead>
                <tr>
                    <th style="width: 40px;"></th> 
                    <th>Request No</th>
                    <th>Current Status</th>
                    <th>Request Date</th>
                    <th>Requested By</th>
                    <th>Department</th> <th>Location</th>
                    <th>Description</th>
                    <th>Assigned To</th>
                    <th>Closed Date</th>
                    <th>No. Days</th>
                </tr>
            </thead>
            <tbody>
            
            <c:if test="${not empty errorMessage}">
                <tr>
                    <td colspan="11" class="error-message">
                        <i class="fas fa-exclamation-triangle"></i> Execution Exception Error: <c:out value="${errorMessage}"/>
                    </td>
                </tr>
            </c:if>

            <c:if test="${empty errorMessage}">
                <c:choose>
                    <c:when test="${not empty reportDataList && fn:length(reportDataList) > 0}">
                        <c:forEach items="${reportDataList}" var="row" varStatus="status">
                            <tr class="request-row" data-status="${row.currentStatus}" onclick="toggleDrilldown(${status.index})">
                                <td><i class="fas fa-chevron-right chevron-icon" id="chevron-${status.index}"></i></td>
                                <td><a href="javascript:void(0);" class="ticket-link" onclick="event.stopPropagation();"><c:out value="${row.requestNo}" /></a></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${row.currentStatus eq 'CLOSED'}">
                                            <span class="status-pill closed">Closed</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="status-pill active">Active</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td><fmt:formatDate value="${row.requestDate}" pattern="dd MMMM yyyy" /></td>
                                <td><c:out value="${row.requestedBy}" /></td>
                                <td class="row-department"><c:out value="${not empty row.departmentName ? row.departmentName : '-'}" /></td> <td class="row-location"><c:out value="${row.location}" /></td>
                                <td><c:out value="${row.description}" /></td>
                                <td><c:out value="${row.assignedTo}" /></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${not empty row.closedDate}">
                                            <fmt:formatDate value="${row.closedDate}" pattern="dd MMMM yyyy" />
                                        </c:when>
                                        <c:otherwise><span style="color: #94a3b8; font-style: italic;">-</span></c:otherwise>
                                    </c:choose>
                                </td>
                                <td>
                                    <span class="days-badge ${empty row.closedDate ? 'unresolved' : ''}">
                                        <c:out value="${row.daysDifference}" /> Days
                                    </span>
                                </td>
                            </tr>

                            <tr class="drilldown-row" id="drilldown-${status.index}" data-status="${row.currentStatus}">
                                <td colspan="11">
                                    <div class="drilldown-wrapper">
                                        <div class="drilldown-title">
                                            <i class="fas fa-history"></i> Historic Follow-Up Lifecycle Timeline
                                        </div>
                                        <table class="followup-table">
                                           <thead>
                                               <tr>
                                                   <th style="width: 15%;">Updated Date</th>
                                                   <th style="width: 15%;">Status Assigned</th>
                                                   <th style="width: 20%;">Updated By</th>
                                                   <th>Remarks / Actions Taken</th>
                                               </tr>
                                           </thead>
                                           <tbody>
                                           <c:choose>
                                               <c:when test="${not empty row.followUps && fn:length(row.followUps) > 0}">
                                                   <c:forEach items="${row.followUps}" var="fUp">
                                                       <tr class="followup-data-row">
                                                           <td class="fup-date"><strong><fmt:formatDate value="${fUp.updatedOn}" pattern="dd MMMM yyyy" /></strong></td>
                                                           <td class="fup-status"><c:out value="${fUp.status}" /></td>
                                                           <td class="fup-by"><c:out value="${fUp.updatedBy}" /></td>
                                                           <td class="fup-remarks"><c:out value="${not empty fUp.remarks ? fUp.remarks : '-'}" /></td>
                                                       </tr>
                                                   </c:forEach>
                                               </c:when>
                                               <c:otherwise>
                                                   <tr class="no-followup-row">
                                                       <td colspan="4" style="text-align: center; color: #94a3b8; font-style: italic; padding: 12px;">
                                                           No historical follow-up logs posted for this request item.
                                                       </td>
                                                   </tr>
                                               </c:otherwise>
                                           </c:choose>
                                           </tbody>
                                        </table>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                    </c:when>
                    <c:otherwise>
                        <tr id="noDataRow">
                            <td colspan="11" class="empty-state">
                                <i class="fas fa-folder-open" style="font-size: 28px; margin-bottom: 8px; display: block; color: #cbd5e1;"></i>
                                No data matches report generation conditions.
                            </td>
                        </tr>
                    </c:otherwise>
                </c:choose>
            </c:if>

            <tr id="filterEmptyRow" style="display: none;">
                <td colspan="11" class="empty-state">
                    <i class="fas fa-filter" style="font-size: 28px; margin-bottom: 8px; display: block; color: #cbd5e1;"></i>
                    No requests found matching the selected status filter.
                </td>
            </tr>
            </tbody>
        </table>
    </div>
</div>

<script>
// Run metric engine immediately on load
document.addEventListener("DOMContentLoaded", function() {
    calculateDepartmentMetrics();
});

function calculateDepartmentMetrics() {
    const rows = document.querySelectorAll(".request-row");
    const dashboard = document.getElementById("summaryDashboard");
    let summaryMap = {};

    rows.forEach(row => {
        // Evaluate metrics based on visible elements to match the filters accurately
        if (row.style.display === "none") return;

        const cells = row.getElementsByTagName("td");
        if (cells.length < 11) return;

        let status = cells[2].innerText.trim().toUpperCase();
        // Index 5 contains the new Department Name data cell
        let department = cells[5].innerText.trim();

        if (!department || department === "-") department = "Unassigned Department";

        if (!summaryMap[department]) {
            summaryMap[department] = { active: 0, closed: 0 };
        }

        if (status === "CLOSED") {
            summaryMap[department].closed++;
        } else {
            summaryMap[department].active++;
        }
    });

    // Populate UI Component Grid Cards Dynamically
    let cardHTML = "";
    const departments = Object.keys(summaryMap).sort();

    if (departments.length === 0) {
        dashboard.innerHTML = '<div style="color: #64748b; font-style: italic; font-size:13px;">No departmental metrics available for the active view filter criteria.</div>';
        return;
    }

    departments.forEach(dept => {
        cardHTML += `
            <div class="dept-card">
                <div class="dept-card__title"><i class="fas fa-building"></i> \${dept}</div>
                <div class="dept-card__metrics">
                    <div class="metric-sub active-box">
                        <label>Active</label>
                        <span>\${summaryMap[dept].active}</span>
                    </div>
                    <div class="metric-sub closed-box">
                        <label>Closed</label>
                        <span>\${summaryMap[dept].closed}</span>
                    </div>
                </div>
            </div>`;
    });
    dashboard.innerHTML = cardHTML;
}

function toggleDrilldown(index) {
    const mainRow = document.getElementById("chevron-" + index).closest(".request-row");
    const detailRow = document.getElementById("drilldown-" + index);

    if (detailRow.style.display === "table-row") {
        detailRow.style.display = "none";
        mainRow.classList.remove("is-expanded");
    } else {
        detailRow.style.display = "table-row";
        mainRow.classList.add("is-expanded");
    }
}

function filterReportByStatus() {
    const selectedStatus = document.getElementById("statusFilter").value;
    const masterRows = document.querySelectorAll(".request-row");
    const fallbackRow = document.getElementById("filterEmptyRow");
    let visibleRowsCount = 0;

    masterRows.forEach((row) => {
        const rowStatus = row.getAttribute("data-status");
        const linkedDetailRow = row.nextElementSibling;
        
        if (selectedStatus === "ALL" || rowStatus === selectedStatus) {
            row.style.display = "";
            visibleRowsCount++;
        } else {
            row.style.display = "none";
            if(linkedDetailRow && linkedDetailRow.classList.contains("drilldown-row")) {
                linkedDetailRow.style.display = "none";
                row.classList.remove("is-expanded");
            }
        }
    });

    if (fallbackRow) {
        fallbackRow.style.display = (visibleRowsCount === 0 && masterRows.length > 0) ? "" : "none";
    }

    // Keep metrics updated with current dropdown state automatically
    calculateDepartmentMetrics();
}

function triggerExcelDownload() {
    let table = document.getElementById("reportTable");

    let html =
        '<html xmlns:o="urn:schemas-microsoft-com:office:office" ' +
        'xmlns:x="urn:schemas-microsoft-com:office:excel" ' +
        'xmlns="http://www.w3.org/TR/REC-html40">' +
        '<head>' +
        '<meta charset="UTF-8">' +
        '<style>' +
        'table{border-collapse:collapse;width:100%;}' +
        'th,td{border:1px solid #000;padding:5px;font-size:11px;font-family: "Segoe UI", sans-serif;}' +
        'th{background:#d9eaf7;font-weight:bold;}' +
        '.title{background:#0176d3;color:white;font-size:16px;font-weight:bold;text-align:center;}' +
        '.summary-hdr{background:#e2e8f0;font-weight:bold;font-size:12px;}' +
        '</style>' +
        '</head><body>';

    html += '<table>';
    html += '<tr><td colspan="11" class="title">Assigned & Completed Requests Report</td></tr>';
    html += '<tr><td colspan="11" style="height:15px; border:none;"></td></tr>';

    // 1. RE-CALCULATE AND APPEND SUMMARY BLOCKS DIRECTLY INTO THE EXCEL HEADER CONTEXT
    let requestRows = document.querySelectorAll(".request-row");
    let summaryMap = {};
    
    requestRows.forEach(function(row) {
        if (row.style.display === "none") return;
        let td = row.getElementsByTagName("td");
        if (td.length < 11) return;
        let status = td[2].innerText.trim().toUpperCase();
        let dept = td[5].innerText.trim();
        if (!dept || dept === "-") dept = "Unassigned Department";

        if (!summaryMap[dept]) summaryMap[dept] = { active: 0, closed: 0 };
        if (status === "CLOSED") summaryMap[dept].closed++;
        else summaryMap[dept].active++;
    });

    html += '<tr><td colspan="11" class="summary-hdr">Departmental Volume Metrics Summary Breakdown</td></tr>';
    html += '<tr><th colspan="5">Department Name</th><th colspan="3">Active Requests</th><th colspan="3">Closed Requests</th></tr>';
    
    let deptKeys = Object.keys(summaryMap).sort();
    if(deptKeys.length === 0) {
        html += '<tr><td colspan="11" style="font-style:italic; text-align:center;">No dataset entries to generate metric matrices.</td></tr>';
    } else {
        deptKeys.forEach(function(key) {
            html += '<tr>' +
                    '<td colspan="5"><b>' + key + '</b></td>' +
                    '<td colspan="3" style="text-align:center; color:#166534;">' + summaryMap[key].active + '</td>' +
                    '<td colspan="3" style="text-align:center; color:#334155;">' + summaryMap[key].closed + '</td>' +
                    '</tr>';
        });
    }

    html += '<tr><td colspan="11" style="height:25px; border:none;"></td></tr>';

    // 2. PRIMARY OPERATIONAL TRANSACTIONS TABLE
    html += '<tr><td colspan="11" class="summary-hdr">Detailed Request Log Entries</td></tr>';
    html += '<tr>' +
            '<th>Request No</th><th>Status</th><th>Request Date</th><th>Requested By</th>' +
            '<th>Department</th><th>Location</th><th>Description</th><th>Assigned To</th><th>Closed Date</th>' +
            '<th>Turnaround</th><th>Follow-Up Details</th>' +
            '</tr>';

    let dataFound = false;

    requestRows.forEach(function(row) {
        if (row.style.display === "none") return;
        dataFound = true;

        let td = row.getElementsByTagName("td");

        let requestNo   = td[1].innerText.trim();
        let status      = td[2].innerText.trim();
        let requestDate = td[3].innerText.trim();
        let requestedBy = td[4].innerText.trim();
        let department  = td[5].innerText.trim();
        let location    = td[6].innerText.trim();
        let description = td[7].innerText.trim();
        let assignedTo  = td[8].innerText.trim();
        let closedDate  = td[9].innerText.trim();
        let turnaround  = td[10].innerText.trim();

        let followUpText = "";
        let drilldownRow = row.nextElementSibling;

        if (drilldownRow && drilldownRow.classList.contains("drilldown-row")) {
            let followRows = drilldownRow.querySelectorAll(".followup-data-row");

            followRows.forEach(function(fup) {
                let date = fup.querySelector(".fup-date") ? fup.querySelector(".fup-date").innerText.trim() : "";
                let stat = fup.querySelector(".fup-status") ? fup.querySelector(".fup-status").innerText.trim() : "";
                let by = fup.querySelector(".fup-by") ? fup.querySelector(".fup-by").innerText.trim() : "";
                let remarks = fup.querySelector(".fup-remarks") ? fup.querySelector(".fup-remarks").innerText.trim() : "";

                followUpText += date + " | " + stat + " | " + by + " | " + remarks + "\n";
            });
        }

        html += '<tr>';
        html += '<td>' + requestNo + '</td>';
        html += '<td>' + status + '</td>';
        html += '<td>' + requestDate + '</td>';
        html += '<td>' + requestedBy + '</td>';
        html += '<td>' + department + '</td>';
        html += '<td>' + location + '</td>';
        html += '<td>' + description + '</td>';
        html += '<td>' + assignedTo + '</td>';
        html += '<td>' + closedDate + '</td>';
        html += '<td>' + turnaround + '</td>';
        html += '<td>' + followUpText.replace(/\n/g, '<br>') + '</td>';
        html += '</tr>';
    });

    if (!dataFound) {
        html += '<tr><td colspan="11" style="text-align:center;">No records found.</td></tr>';
    }

    html += '</table></body></html>';

    let blob = new Blob([html], { type: "application/vnd.ms-excel;charset=utf-8;" });
    let link = document.createElement("a");

    const months = ["March", "April", "May", "June", "July", "August", "September", "October", "November", "December", "January", "February"];
    const targetDate = new Date();
    const formattedFileDate = targetDate.getDate() + "_" + months[targetDate.getMonth()] + "_" + targetDate.getFullYear();

    let fileName = "Assigned_Completed_Requests_Report_" + formattedFileDate + ".xls";

    link.href = URL.createObjectURL(blob);
    link.download = fileName;

    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
}
</script>
</body>
</html>