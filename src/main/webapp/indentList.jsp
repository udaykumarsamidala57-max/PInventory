<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.bean.IndentItemFull" %>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Indent Full Report</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="CSS/tablestyle.css">

<script>
function sortTable(n) {
    var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
    table = document.getElementById("dataTable");
    switching = true;
    dir = "asc";
    while (switching) {
        switching = false;
        rows = table.rows;
        for (i = 1; i < (rows.length - 1); i++) {
            shouldSwitch = false;
            x = rows[i].getElementsByTagName("TD")[n];
            y = rows[i + 1].getElementsByTagName("TD")[n];
            if (dir == "asc") {
                if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
                    shouldSwitch= true;
                    break;
                }
            } else if (dir == "desc") {
                if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
                    shouldSwitch = true;
                    break;
                }
            }
        }
        if (shouldSwitch) {
            rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
            switching = true;
            switchcount++;
        } else {
            if (switchcount == 0 && dir == "asc") {
                dir = "desc";
                switching = true;
            }
        }
    }
}

function filterByItem() {
    var input, filter, table, tr, td, i, txtValue;
    input = document.getElementById("itemFilter");
    filter = input.value.toUpperCase();
    table = document.getElementById("dataTable");
    tr = table.getElementsByTagName("tr");
    for (i = 1; i < tr.length; i++) {
        td = tr[i].getElementsByTagName("td")[3];
        if (td) {
            txtValue = td.textContent || td.innerText;
            tr[i].style.display = (txtValue.toUpperCase().indexOf(filter) > -1) ? "" : "none";
        }       
    }
}

function filterByDate() {
    var fromDate = document.getElementById("fromDate").value;
    var toDate = document.getElementById("toDate").value;
    var table = document.getElementById("dataTable");
    var tr = table.getElementsByTagName("tr");
    for (var i = 1; i < tr.length; i++) {
        var td = tr[i].getElementsByTagName("td")[2];
        if (td) {
            var rowDate = td.innerText || td.textContent;
            if (fromDate && toDate) {
                if (rowDate >= fromDate && rowDate <= toDate) {
                    tr[i].style.display = "";
                } else {
                    tr[i].style.display = "none";
                }
            } else {
                tr[i].style.display = "";
            }
        }
    }
}

function downloadTableAsExcel(tableID, filename = ''){
    var downloadLink;
    var dataType = 'application/vnd.ms-excel';
    var tableSelect = document.getElementById(tableID);
    var tableHTML = tableSelect.outerHTML.replace(/ /g, '%20');
    filename = filename ? filename + '.xls' : 'indent_full_report.xls';
    downloadLink = document.createElement("a");
    document.body.appendChild(downloadLink);
    if (navigator.msSaveOrOpenBlob) {
        var blob = new Blob(['\ufeff', tableHTML], { type: dataType });
        navigator.msSaveOrOpenBlob(blob, filename);
    } else {
        downloadLink.href = 'data:' + dataType + ', ' + tableHTML;
        downloadLink.download = filename;
        downloadLink.click();
    }
}
</script>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-content">
    <div class="card">
        <h2 style="text-align:center;">Indent Full Report</h2>

        <div style="margin-bottom: 20px; display:flex; gap:10px; flex-wrap:wrap;">
            <input type="text" id="itemFilter" onkeyup="filterByItem()" placeholder="Search by Item...">
            <label>From: <input type="date" id="fromDate"></label>
            <label>To: <input type="date" id="toDate"></label>
            <button class="btn btn-info" onclick="filterByDate()">Filter by Date</button>
            <button class="btn btn-info" onclick="downloadTableAsExcel('dataTable')">Download Excel</button>
        </div>

        <table id="dataTable" class="main-table">
            <thead>
                <tr>
                    <th>ID</th><th>Indent No</th><th>Date</th><th>Item</th>
                    <th>Qty</th><th>Issued Qty</th><th>UOM</th><th>Dept</th>
                    <th>Requested By</th><th>Purpose</th><th>IStatus</th>
                    <th>IApproveDate</th><th>Status</th><th>FApproveDate</th>
                    <th>Next</th><th>Issued Status</th>
                    <th>View / Print</th>
                </tr>
            </thead>
            <tbody>
                <%
                    List<IndentItemFull> indents = (List<IndentItemFull>) request.getAttribute("indents");
                    if (indents != null && !indents.isEmpty()) {
                        for (IndentItemFull ind : indents) {
                %>
                <tr>
                    <td><%= ind.getId() %></td>
                    <td><%= ind.getIndentNo() %></td>
                    <td><%= ind.getDate() %></td>
                    <td><%= ind.getItemName() %></td>
                    <td><%= ind.getQty() %></td>
                    <td><%= ind.getBalanceQty() %></td>
                    <td><%= ind.getUom() %></td>
                    <td><%= ind.getDepartment() %></td>
                    <td><%= ind.getRequestedBy() %></td>
                    <td><%= ind.getPurpose() %></td>
                    <td><%= ind.getIstatus() %></td>
                    <td><%= ind.getIapprovevdate() %></td>
                    <td><%= ind.getStatus() %></td>
                    <td><%= ind.getFapprovevdate() %></td>
                    <td><%= ind.getIndentNext() %></td>
                    <td>
                        <%-- Issued_status column directly --%>
                        <%= (ind.getIndentNext() != null && ind.getIndentNext().equalsIgnoreCase("Issue")) ? "Pending" : "" %>
                    </td>
                    <td>
                        <form action="PrintIndent.jsp" method="get">
                            <input type="hidden" name="IndentNumber" value="<%= ind.getIndentNo() %>">
                            <input class="btn btn-info" type="submit" value="View / Print">
                        </form>
                    </td>
                </tr>
                <% } } else { %>
                <tr><td colspan="17" style="text-align:center;color:red;">No records found</td></tr>
                <% } %>
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="Footer.jsp" />
</body>
</html>
