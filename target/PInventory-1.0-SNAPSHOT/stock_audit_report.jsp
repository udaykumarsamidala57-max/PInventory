<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%-- Ensure this JSTL taglib is included --%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<%
ArrayList<String> availableMonths = (ArrayList<String>)request.getAttribute("availableMonths");
List<Map<String,Object>> reportList = (List<Map<String,Object>>)request.getAttribute("reportList");
String selectedMonth = (String)request.getAttribute("selectedMonth");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>📊 Stock Audit Report</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/design-system/2.21.4/styles/salesforce-lightning-design-system.min.css" />
<style>
    body { background-color: #f3f3f3; margin: 0; padding: 0; display: flex; flex-direction: column; min-height: 100vh; }
    .slds-scope.main-content-wrapper { flex: 1 1 auto; min-width: 0; padding: 1rem; }
    .centered-content-block { width: 95%; margin-right: auto; margin-left: auto; }
    .table-container { background: white; border-radius: 0.25rem; }
    .institution-header { border-bottom: 2px solid #1b5ebe; }

    @media print {
        @page { size: A4 landscape; margin: 10mm; }
        .print-exclude, .no-print, form, .slds-button, hr, nav { display: none !important; }
        body, .slds-scope.main-content-wrapper { background: #fff !important; padding: 0 !important; }
        .centered-content-block { width: 100% !important; margin: 0 !important; }
        .slds-card { border: none !important; box-shadow: none !important; padding: 0 !important; }
        .slds-table { width: 100% !important; font-size: 9pt !important; border-collapse: collapse !important; }
        .slds-table th, .slds-table td { padding: 6px 4px !important; }
        .slds-table th { background-color: #f3f3f3 !important; -webkit-print-color-adjust: exact; }
    }
</style>
<script>
function loadReport() { document.getElementById("filterForm").submit(); }
function triggerPrint() { window.print(); }
</script>
</head>
<body>

<div class="print-exclude">
    <%@ include file="header.jsp" %>
</div>

<div class="slds-scope main-content-wrapper">
    <div class="centered-content-block">
        <div class="slds-card slds-p-around_small slds-margin-bottom_small no-print">
            <div class="slds-grid slds-grid_align-spread slds-p-bottom_small">
                <h3 class="slds-text-heading_label slds-text-title_bold">Report Options</h3>
                <button type="button" onclick="triggerPrint()" class="slds-button slds-button_neutral">🖨️ Print View</button>
            </div>
            <form id="filterForm" action="StockAuditReportServlet" method="get">
                <div class="slds-form-element">
                    <label class="slds-form-element__label" for="month-select">Select Month</label>
                    <div class="slds-select_container" style="width: 300px;">
                        <select class="slds-select" id="month-select" name="month" onchange="loadReport()">
                            <option value="">-- Select Month --</option>
                            <c:forEach var="m" items="${availableMonths}">
                                <option value="${m}" ${m == selectedMonth ? 'selected' : ''}>${m}</option>
                            </c:forEach>
                        </select>
                    </div>
                </div>
            </form>
        </div>

        <br>
        <c:if test="${not empty selectedMonth}">
            <div class="slds-p-bottom_medium slds-text-align_center institution-header slds-m-bottom_medium">
                <h1 class="slds-text-heading_large slds-text-title_bold" style="color: #1b5ebe;">SANDUR RESIDENTIAL SCHOOL, SANDUR</h1>
                <h2 class="slds-text-heading_small slds-text-title_bold slds-text-color_weak">Stock Audit Report &mdash; ${selectedMonth}</h2>
            </div>

            <div class="slds-card table-container">
                <table class="slds-table slds-table_cell-buffer slds-table_bordered slds-table_striped slds-table_compact">
                    <thead>
                        <tr>
                            <th>Audit ID</th><th>Date</th><th>Verified By</th><th>Status</th><th>Category</th><th>Item Name</th><th>UOM</th><th>Sys Qty</th><th>Phy Qty</th><th>Var Qty</th><th>Remarks</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty reportList}">
                                <c:forEach var="row" items="${reportList}">
                                    <tr>
                                        <td>${row.verificationId}</td>
                                        <td>${row.verificationDate}</td>
                                        <td>${row.verifiedBy}</td>
                                        <td><span class="slds-badge">${row.status}</span></td>
                                        <td>${row.category}<br>${row.subCategory}</td>
                                        <td>${row.itemName}</td>
                                        <td>${row.uom}</td>
                                        <td>${row.systemQty}</td>
                                        <td>${row.physicalQty}</td>
                                        <td class="${row.varianceQty < 0 ? 'slds-text-color_error' : ''}">
                                            ${row.varianceQty}
                                        </td>
                                        <td>${row.remarks}</td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td colspan="11" class="slds-text-align_center">No records found for this month.</td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </c:if>
    </div> 
</div>
</body>
</html>