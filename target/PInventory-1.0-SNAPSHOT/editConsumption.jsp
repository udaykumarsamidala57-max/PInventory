<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Edit Consumption by Date</title>

<style>
body { font-family: Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
.container { width: 95%; max-width: 1200px; margin: 0 auto; background: #fff; padding: 25px; border-radius: 6px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
.search-card { background: #fafafa; border: 1px solid #e0e0e0; padding: 15px 20px; border-radius: 4px; margin-bottom: 20px; }
.form-inline { display: flex; align-items: center; gap: 15px; }
.form-inline label { font-weight: bold; }
.form-inline input[type="date"] { padding: 8px 12px; border: 1px solid #ccc; border-radius: 4px; font-size: 14px; }
table { width: 100%; border-collapse: collapse; margin-top: 15px; }
th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
th { background-color: #007bff; color: white; font-size: 14px; }
input[type=text], input[type=number] { width: 100%; padding: 6px; box-sizing: border-box; border: 1px solid #ccc; border-radius: 3px; }
input[readonly] { background: #e9ecef; color: #495057; border: 1px solid #ced4da; }
.btn { padding: 9px 18px; border: none; cursor: pointer; color: white; font-size: 14px; border-radius: 4px; transition: background 0.2s; }
.fetch-btn { background: #007bff; }
.fetch-btn:hover { background: #0056b3; }
.save-btn { background: #28a745; margin-right: 10px; }
.save-btn:hover { background: #218838; }
.cancel-btn { background: #dc3545; text-decoration: none; padding: 9px 18px; color: white; border-radius: 4px; display: inline-block; font-size: 14px; }
.cancel-btn:hover { background: #c82333; }
.alert-msg { padding: 10px 15px; border-radius: 4px; margin-bottom: 15px; font-weight: bold; }
.alert-success { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
.alert-danger { background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
</style>

<script>
function calculateRowTotal(index) {
    var qty = parseFloat(document.getElementById("qty_" + index).value) || 0;
    var price = parseFloat(document.getElementById("price_" + index).value) || 0;
    document.getElementById("total_" + index).value = (qty * price).toFixed(2);
}

// Toggle all checkboxes
function toggleSelectAll(selectAllCheckbox) {
    var checkboxes = document.querySelectorAll('.select-row');
    checkboxes.forEach(function(cb) {
        cb.checked = selectAllCheckbox.checked;
    });
}

// Ensure at least one checkbox is selected before form submission
function validateSelection() {
    var selected = document.querySelectorAll('.select-row:checked');
    if (selected.length === 0) {
        alert("Please select at least one record to update.");
        return false;
    }
    return true;
}

window.onload = function () {
    var today = new Date();
    var maxDate = today.toISOString().split('T')[0];

    var min = new Date();
    min.setDate(today.getDate() - 14);
    var minDate = min.toISOString().split('T')[0];

    var dateInput = document.getElementById("selected_date");
    dateInput.setAttribute("min", minDate);
    dateInput.setAttribute("max", maxDate);

    if (dateInput.value === "") {
        dateInput.value = maxDate;
    }
};
</script>
</head>

<body>
<div class="container">
    <h2>Edit Consumption Entries</h2>

    <c:if test="${param.msg == 'updated'}">
        <div class="alert-msg alert-success">Selected consumption records updated successfully!</div>
    </c:if>
    <c:if test="${param.msg == 'notfound'}">
        <div class="alert-msg alert-danger">No consumption records found for the selected date.</div>
    </c:if>

    <!-- Date Search Form -->
    <div class="search-card">
        <form action="FetchConsumptionByDateServlet" method="get" class="form-inline">
            <label for="selected_date">Select Date:</label>
            <input type="date" id="selected_date" name="selected_date" value="${selected_date}" required>
            <button type="submit" class="btn fetch-btn">Load Records</button>
        </form>
    </div>

    <!-- Editable Records Form -->
    <c:if test="${not empty consumption_list}">
        <form action="UpdateConsumptionByDateServlet" method="post" onsubmit="return validateSelection();">
            <input type="hidden" name="selected_date" value="${selected_date}">

            <table>
                <thead>
                    <tr>
                        <th style="width: 40px; text-align: center;">
                            <input type="checkbox" id="selectAll" onclick="toggleSelectAll(this)">
                        </th>
                        <th>Issue No</th>
                        <th>Item Name</th>
                        <th>UOM</th>
                        <th>Department</th>
                        <th>Issued To</th>
                        <th style="width: 100px;">Quantity</th>
                        <th style="width: 100px;">Unit Price</th>
                        <th style="width: 110px;">Total Value</th>
                        <th>Remarks</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="item" items="${consumption_list}" varStatus="status">
                        <tr>
                            <!-- Checkbox passes selected issue_id -->
                            <td style="text-align: center;">
                                <input type="checkbox" name="selected_issue_id" value="${item.issue_id}" class="select-row">
                            </td>

                            <!-- Metadata mapped by issue_id index -->
                            <input type="hidden" name="issue_id" value="${item.issue_id}">
                            <input type="hidden" name="item_id" value="${item.item_id}">
                            <input type="hidden" name="po_item_id" value="${item.po_item_id}">

                            <td><input type="text" value="${item.issueno}" readonly></td>
                            <td><input type="text" value="${item.item_name}" readonly></td>
                            <td><input type="text" value="${item.uom}" readonly></td>
                            <td><input type="text" name="department_${item.issue_id}" value="${item.department}"></td>
                            <td><input type="text" name="issued_to_${item.issue_id}" value="${item.issued_to}"></td>
                            <td>
                                <input type="number" step="0.01" id="qty_${status.index}" name="qty_issued_${item.issue_id}"
                                       value="${item.qty_issued}" onkeyup="calculateRowTotal(${status.index})"
                                       onchange="calculateRowTotal(${status.index})" required>
                            </td>
                            <td>
                                <input type="text" id="price_${status.index}" value="${item.unit_price}" readonly>
                            </td>
                            <td>
                                <input type="text" id="total_${status.index}" value="${item.total_value}" readonly>
                            </td>
                            <td><input type="text" name="remarks_${item.issue_id}" value="${item.remarks}"></td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>

            <br>
            <button class="btn save-btn" type="submit">Update Selected Entries</button>
            <a href="editConsumption.jsp" class="cancel-btn">Reset</a>
        </form>
    </c:if>
</div>
</body>
</html>