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
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght=400;500;600;700&family=Poppins:wght=500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <style>
        :root {
            --slds-g-color-neutral-base-10: #f3f3f3;
            --slds-g-color-neutral-base-100: #ffffff;
            --text-main: #000000; 
            --text-secondary: #1e293b; /* Deep slate */
            --text-muted: #475569;
            --slds-brand: #0176d3;
            --slds-brand-hover: #015a9e;
            --slds-border: #cbd5e1; 
            --slds-row-hover: #f1f5f9;
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
            background-color: #e2e8f0; 
            color: var(--text-main);
            padding: 24px;
            -webkit-font-smoothing: antialiased;
        }

        .report-container {
            max-width: 1650px;
            margin: 0 auto;
            margin-bottom: 40px;
        }

        /* Re-structured Page Header Layout */
        .slds-page-header {
            background: var(--slds-g-color-neutral-base-100);
            padding: 20px 24px;
            border: 1px solid var(--slds-border);
            border-radius: 8px 8px 0 0;
            display: flex;
            align-items: center;
            justify-content: space-between;
            box-shadow: 0 2px 4px rgba(0,0,0,0.06);
        }

        .slds-page-header__left {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .slds-icon-wrapper {
            background-color: #107c41; 
            color: white;
            width: 44px;
            height: 44px;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
        }

        .slds-page-header__title {
            font-family: 'Poppins', sans-serif;
            font-size: 22px;
            font-weight: 700;
            color: var(--text-main);
            line-height: 1.2;
            letter-spacing: -0.3px;
        }

        .slds-btn-excel {
            font-family: 'Poppins', sans-serif;
            background-color: #107c41;
            color: #ffffff;
            border: 1px solid #0e6b37;
            padding: 10px 20px;
            font-size: 13px;
            font-weight: 600;
            border-radius: 6px;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.15s ease;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            letter-spacing: 0.3px;
        }

        .slds-btn-excel:hover {
            background-color: #0b592e;
            transform: translateY(-1px);
            box-shadow: 0 4px 6px rgba(0,0,0,0.15);
        }

        .summary-dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 16px;
            background: #ffffff;
            border: 1px solid var(--slds-border);
            border-top: none;
            padding: 24px;
        }

        .dept-card {
            background: #f8fafc;
            border: 1px solid var(--slds-border);
            border-radius: 6px;
            padding: 16px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }

        .dept-card__title {
            font-family: 'Poppins', sans-serif;
            font-size: 13px;
            font-weight: 700;
            color: var(--text-secondary);
            margin-bottom: 12px;
            border-bottom: 2px dashed var(--slds-border);
            padding-bottom: 6px;
            text-transform: uppercase;
            letter-spacing: 0.7px;
        }

        .dept-card__metrics {
            display: flex;
            justify-content: space-between;
            gap: 12px;
        }

        .metric-sub {
            flex: 1;
            background: #ffffff;
            padding: 10px;
            border-radius: 4px;
            border: 1px solid var(--slds-border);
            text-align: center;
        }

        .metric-sub.active-box { border-left: 4px solid #166534; }
        .metric-sub.closed-box { border-left: 4px solid #4a5568; }

        .metric-sub label {
            font-family: 'Poppins', sans-serif;
            display: block;
            font-size: 11px;
            font-weight: 600;
            color: var(--text-muted);
            text-transform: uppercase;
            margin-bottom: 4px;
            letter-spacing: 0.5px;
        }

        .metric-sub span {
            font-family: 'Poppins', sans-serif;
            font-size: 20px;
            font-weight: 700;
            color: var(--text-main);
        }

        .slds-filter-bar {
            background: #f1f5f9;
            border: 1px solid var(--slds-border);
            border-top: none;
            padding: 16px 24px;
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 24px;
        }

        .filter-group {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .slds-filter-label {
            font-family: 'Poppins', sans-serif;
            font-size: 11px;
            font-weight: 700;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.8px;
        }

        .slds-filter-select {
            font-family: 'Inter', sans-serif;
            min-width: 240px;
            padding: 8px 12px;
            font-size: 13px;
            font-weight: 600;
            color: var(--text-main);
            background-color: #ffffff;
            border: 1px solid var(--slds-border);
            border-radius: 4px;
            outline: none;
            cursor: pointer;
            box-shadow: inset 0 1px 2px rgba(0,0,0,0.05);
        }
        
        .slds-filter-select:focus {
            border-color: var(--slds-brand);
            box-shadow: 0 0 0 2px rgba(1, 118, 211, 0.2);
        }

        .slds-table-container {
            background: var(--slds-g-color-neutral-base-100);
            border: 1px solid var(--slds-border);
            border-top: none;
            border-radius: 0 0 8px 8px;
            overflow: hidden;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
        }

        th {
            font-family: 'Poppins', sans-serif;
            background-color: #f8fafc;
            color: var(--text-secondary);
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.8px;
            padding: 14px 16px;
            border-bottom: 2px solid var(--slds-border);
        }

        td {
            font-family: 'Inter', sans-serif;
            padding: 14px 16px;
            font-size: 13.5px;
            color: var(--text-main);
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
        
        .request-row.is-expanded td {
            background-color: #f0fdf4;
            border-bottom-color: transparent;
        }

        .chevron-icon {
            color: #64748b;
            transition: transform 0.2s ease;
            margin-right: 4px;
            font-size: 14px;
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
            border-bottom: 2px solid var(--slds-border);
        }

        .drilldown-wrapper {
            padding: 20px 24px 24px 52px;
            background: #f8fafc;
            border-left: 4px solid var(--slds-brand);
        }

        .drilldown-title {
            font-family: 'Poppins', sans-serif;
            font-size: 12px;
            font-weight: 700;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.6px;
            margin-bottom: 14px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .followup-table {
            width: 100%;
            background: #ffffff;
            border: 1px solid var(--slds-border);
            border-radius: 6px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }

        .followup-table th {
            font-family: 'Poppins', sans-serif;
            background-color: #edf2f7;
            color: var(--text-secondary);
            padding: 10px 14px;
            font-size: 11px;
            font-weight: 600;
            border-bottom: 1px solid var(--slds-border);
            letter-spacing: 0.5px;
        }

        .followup-table td {
            font-family: 'Inter', sans-serif;
            padding: 12px 14px;
            font-size: 13px;
            color: var(--text-main);
            border-bottom: 1px solid #edf2f7;
        }

        .ticket-link {
            color: var(--slds-brand);
            font-weight: 700;
            text-decoration: underline;
        }
        
        .days-badge {
            font-family: 'Poppins', sans-serif;
            display: inline-flex;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 13px;
            font-weight: 700;
            background-color: var(--badge-bg);
            color: var(--badge-text);
            border: 1px solid #bae6fd;
        }
        
        .days-badge.unresolved { 
            background-color: #fef3c7; 
            color: #b45309; 
            border: 1px solid #fde68a;
        }
        
        .status-pill {
            font-family: 'Poppins', sans-serif;
            display: inline-block;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border: 1px solid transparent;
        }
        .status-pill.closed { background: #e2e8f0; color: #1a202c; border-color: #cbd5e1; }
        .status-pill.active { background: #c6f6d5; color: #22543d; border-color: #9ae6b4; }
        
        .empty-state, .error-message {
            font-family: 'Poppins', sans-serif;
            text-align: center;
            padding: 48px 20px;
            font-size: 15px;
            font-weight: 600;
            color: var(--text-secondary);
        }
        .error-message {
            color: #c53030;
            background-color: #fff5f5;
        }
    </style>
</head>
<body>
<%@ include file="../header.jsp" %>

<div class="report-container">
    
<button type="button" class="slds-btn-excel" onclick="triggerExcelDownload()">
                <i class="fas fa-file-excel"></i> Export Report to Excel
            </button>
    <div id="summaryDashboard" class="summary-dashboard"></div>

    <div class="slds-filter-bar">
        <div class="filter-group">
            <label class="slds-filter-label" for="statusFilter"><i class="fas fa-filter"></i> Current Status:</label>
            <select id="statusFilter" class="slds-filter-select" onchange="runParallelFilters()">
                <option value="ALL">All Current Statuses</option>
                <option value="ACTIVE">Active (Unclosed)</option>
                <option value="CLOSED">Closed</option>
            </select>
        </div>
        
        <div class="filter-group">
            <label class="slds-filter-label" for="departmentFilter"><i class="fas fa-building"></i> Department:</label>
            <select id="departmentFilter" class="slds-filter-select" onchange="runParallelFilters()">
                <option value="ALL">All Departments</option>
            </select>
        </div>
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
                    <th>Department</th> 
                    <th>Location</th>
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
                            <tr class="request-row" 
                                data-status="${row.currentStatus}" 
                                data-department="${not empty row.departmentName ? row.departmentName : 'Unassigned Department'}"
                                onclick="toggleDrilldown(${status.index})">
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
                                <td><strong><fmt:formatDate value="${row.requestDate}" pattern="dd MMMM yyyy" /></strong></td>
                                <td><c:out value="${row.requestedBy}" /></td>
                                <td class="row-department"><strong><c:out value="${not empty row.departmentName ? row.departmentName : '-'}" /></strong></td> 
                                <td class="row-location"><c:out value="${row.location}" /></td>
                                <td><c:out value="${row.description}" /></td>
                                <td><c:out value="${row.assignedTo}" /></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${not empty row.closedDate}">
                                            <strong><fmt:formatDate value="${row.closedDate}" pattern="dd MMMM yyyy" /></strong>
                                        </c:when>
                                        <c:otherwise><span style="color: #718096; font-style: italic;">-</span></c:otherwise>
                                    </c:choose>
                                </td>
                                <td>
                                    <span class="days-badge ${empty row.closedDate ? 'unresolved' : ''}">
                                        <c:out value="${row.daysDifference}" /> 
                                    </span>
                                </td>
                            </tr>

                            <tr class="drilldown-row" id="drilldown-${status.index}">
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
                                                           <td class="fup-status"><strong><c:out value="${fUp.status}" /></strong></td>
                                                           <td class="fup-by"><c:out value="${fUp.updatedBy}" /></td>
                                                           <td class="fup-remarks"><c:out value="${not empty fUp.remarks ? fUp.remarks : '-'}" /></td>
                                                       </tr>
                                                   </c:forEach>
                                               </c:when>
                                               <c:otherwise>
                                                   <tr class="no-followup-row">
                                                       <td colspan="4" style="text-align: center; color: #4a5568; font-style: italic; padding: 14px;">
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
                                <i class="fas fa-folder-open" style="font-size: 32px; margin-bottom: 12px; display: block; color: #a0aec0;"></i>
                                No data matches report generation conditions.
                            </td>
                        </tr>
                    </c:otherwise>
                </c:choose>
            </c:if>

            <tr id="filterEmptyRow" style="display: none;">
                <td colspan="11" class="empty-state">
                    <i class="fas fa-filter" style="font-size: 32px; margin-bottom: 12px; display: block; color: #a0aec0;"></i>
                    No requests found matching the selected filter layout criteria.
                </td>
            </tr>
            </tbody>
        </table>
    </div>
</div>



<script>
document.addEventListener("DOMContentLoaded", function() {
    populateDepartmentDropdown();
    calculateDepartmentMetrics();
});

function populateDepartmentDropdown() {
    const rows = document.querySelectorAll(".request-row");
    const deptFilter = document.getElementById("departmentFilter");
    let departments = new Set();

    rows.forEach(row => {
        let dept = row.getAttribute("data-department");
        if (dept) {
            departments.add(dept.trim());
        }
    });

    let sortedDepts = Array.from(departments).sort();
    sortedDepts.forEach(dept => {
        let opt = document.createElement("option");
        opt.value = dept;
        opt.innerText = dept;
        deptFilter.appendChild(opt);
    });
}

function calculateDepartmentMetrics() {
    const rows = document.querySelectorAll(".request-row");
    const dashboard = document.getElementById("summaryDashboard");
    let summaryMap = {};

    rows.forEach(row => {
        if (row.style.display === "none") return;

        let status = row.getAttribute("data-status").toUpperCase();
        let department = row.getAttribute("data-department");

        if (!department) department = "Unassigned Department";

        if (!summaryMap[department]) {
            summaryMap[department] = { active: 0, closed: 0 };
        }

        if (status === "CLOSED") {
            summaryMap[department].closed++;
        } else {
            summaryMap[department].active++;
        }
    });

    let cardHTML = "";
    const departments = Object.keys(summaryMap).sort();

    if (departments.length === 0) {
        dashboard.innerHTML = '<div style="color: #000000; font-style: italic; font-size:14px; font-weight:700;">No metrics match current selections.</div>';
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

function runParallelFilters() {
    const selectedStatus = document.getElementById("statusFilter").value;
    const selectedDept = document.getElementById("departmentFilter").value;
    const masterRows = document.querySelectorAll(".request-row");
    const fallbackRow = document.getElementById("filterEmptyRow");
    let visibleRowsCount = 0;

    masterRows.forEach((row) => {
        const rowStatus = row.getAttribute("data-status");
        const rowDept = row.getAttribute("data-department");
        const linkedDetailRow = row.nextElementSibling;
        
        const matchesStatus = (selectedStatus === "ALL" || rowStatus === selectedStatus);
        const matchesDept = (selectedDept === "ALL" || rowDept === selectedDept);

        if (matchesStatus && matchesDept) {
            row.style.display = "";
            visibleRowsCount++;
        } else {
            row.style.display = "none";
            if (linkedDetailRow && linkedDetailRow.classList.contains("drilldown-row")) {
                linkedDetailRow.style.display = "none";
                row.classList.remove("is-expanded");
            }
        }
    });

    if (fallbackRow) {
        fallbackRow.style.display = (visibleRowsCount === 0 && masterRows.length > 0) ? "" : "none";
    }

    calculateDepartmentMetrics();
}

function triggerExcelDownload() {
    let html =
        '<html xmlns:o="urn:schemas-microsoft-com:office:office" ' +
        'xmlns:x="urn:schemas-microsoft-com:office:excel" ' +
        'xmlns="http://www.w3.org/TR/REC-html40">' +
        '<head>' +
        '<meta charset="UTF-8">' +
        '<style>' +
        'table{border-collapse:collapse;width:100%;}' +
        'th,td{border:1px solid #000;padding:6px;font-size:11px;font-family: "Segoe UI", sans-serif;color:#000000;}' +
        'th{background:#cfebd6;font-weight:bold;}' +
        '.title{background:#107c41;color:white;font-size:16px;font-weight:bold;text-align:center;}' +
        '.summary-hdr{background:#e2e8f0;font-weight:bold;font-size:12px;}' +
        '</style>' +
        '</head><body>';

    html += '<table>';
    html += '<tr><td colspan="11" class="title">Assigned & Completed Requests Report</td></tr>';
    html += '<tr><td colspan="11" style="height:15px; border:none;"></td></tr>';

    let requestRows = document.querySelectorAll(".request-row");
    let summaryMap = {};
    
    requestRows.forEach(function(row) {
        if (row.style.display === "none") return;
        let status = row.getAttribute("data-status").toUpperCase();
        let dept = row.getAttribute("data-department");
        if (!dept) dept = "Unassigned Department";

        if (!summaryMap[dept]) summaryMap[dept] = { active: 0, closed: 0 };
        if (status === "CLOSED") summaryMap[dept].closed++;
        else summaryMap[dept].active++;
    });

    html += '<tr><td colspan="11" class="summary-hdr">Departmental Volume Metrics Summary Breakdown</td></tr>';
    html += '<tr><th colspan="5">Department Name</th><th colspan="3">Active Requests</th><th colspan="3">Closed Requests</th></tr>';
    
    let deptKeys = Object.keys(summaryMap).sort();
    if(deptKeys.length === 0) {
        html += '<tr><td colspan="11" style="font-style:italic; text-align:center;">No dataset entries to generate metrics maps.</td></tr>';
    } else {
        deptKeys.forEach(function(key) {
            html += '<tr>' +
                    '<td colspan="5"><b>' + key + '</b></td>' +
                    '<td colspan="3" style="text-align:center; color:#166534; font-weight:bold;">' + summaryMap[key].active + '</td>' +
                    '<td colspan="3" style="text-align:center; color:#2d3748; font-weight:bold;">' + summaryMap[key].closed + '</td>' +
                    '</tr>';
        });
    }

    html += '<tr><td colspan="11" style="height:25px; border:none;"></td></tr>';
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
        html += '<td><b>' + requestNo + '</b></td>';
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
        html += '<tr><td colspan="11" style="text-align:center;">No records match your selected view filters.</td></tr>';
    }

    html += '</table></body></html>';

    let blob = new Blob([html], { type: "application/vnd.ms-excel;charset=utf-8;" });
    let link = document.createElement("a");

    const months = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"];
    const targetDate = new Date();
    const formattedFileDate = targetDate.getDate() + "_" + months[targetDate.getMonth()] + "_" + targetDate.getFullYear();
    let fileName = "Filtered_Requests_Report_" + formattedFileDate + ".xls";

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