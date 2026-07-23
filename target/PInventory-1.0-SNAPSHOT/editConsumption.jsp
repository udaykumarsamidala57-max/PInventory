<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // 1. Session Check
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // 2. Fetch User attributes
    String user = (String) sess.getAttribute("username");
    String role = (String) sess.getAttribute("role");
    String dept = (String) sess.getAttribute("department"); // or "dept" depending on your session key

    // 3. Access Control Check
    if (!"Global".equalsIgnoreCase(role) && !"Dining Hall".equalsIgnoreCase(dept)) {
        response.setContentType("text/html");
        response.getWriter().println("<h3 style='color:red; font-family:sans-serif; text-align:center; margin-top:20px;'>Access Denied</h3>");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Consumption</title>
    
    <!-- Salesforce Lightning Design System (SLDS) CDN -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/design-system/2.21.0/styles/salesforce-lightning-design-system.min.css" />

    <style>
        body {
            background-color: #f3f3f3;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            color: #181818;
            padding: 0;
            margin: 0;
        }

        .main-content {
            padding: 1.5rem;
        }

        .slds-card {
            border-radius: 0.25rem;
            box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.07);
            border: 1px solid #dddbda;
            background: #ffffff;
        }

        /* Custom styling for inputs inside tables */
        .slds-table input[type="text"], 
        .slds-table input[type="number"] {
            height: 2rem;
            line-height: 2rem;
            padding: 0 0.5rem;
            font-size: 0.8125rem;
            border: 1px solid #dddbda;
            border-radius: 0.25rem;
            background-color: #fff;
            width: 100%;
            transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
        }

        .slds-table input[type="text"]:focus, 
        .slds-table input[type="number"]:focus {
            border-color: #1b96ff;
            box-shadow: 0 0 3px #0176d3;
            outline: none;
        }

        .slds-table input[readonly] {
            background-color: #f3f3f3;
            border-color: #e5e5e5;
            color: #514f4d;
            cursor: not-allowed;
        }

        .action-bar-sticky {
            position: sticky;
            bottom: 0;
            background-color: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(5px);
            border-top: 1px solid #dddbda;
            padding: 0.75rem 1.5rem;
            margin-left: -1.5rem;
            margin-right: -1.5rem;
            margin-bottom: -1.5rem;
            border-bottom-left-radius: 0.25rem;
            border-bottom-right-radius: 0.25rem;
            z-index: 10;
        }
    </style>

    <script>
        function calculateRowTotal(index) {
            var qtyInput = document.getElementById("qty_" + index);
            var priceInput = document.getElementById("price_" + index);
            var totalInput = document.getElementById("total_" + index);

            var qty = parseFloat(qtyInput.value) || 0;
            var price = parseFloat(priceInput.value) || 0;
            totalInput.value = (qty * price).toFixed(2);
            
            // Auto-check row selection when quantity changes
            autoCheckRow(index);
        }

        function autoCheckRow(index) {
            var checkbox = document.getElementById("cb_" + index);
            if (checkbox) {
                checkbox.checked = true;
            }
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
            if (dateInput) {
                dateInput.setAttribute("min", minDate);
                dateInput.setAttribute("max", maxDate);

                if (!dateInput.value) {
                    dateInput.value = maxDate;
                }
            }
        };
    </script>
</head>

<body>
    <!-- SLDS Scope Wrapper wraps everything including header.jsp -->
    <div class="slds-scope">
        
        <!-- Header Include -->
        <jsp:include page="header.jsp" />

        <div class="main-content">
            <!-- Notification Toast -->
            <c:if test="${param.msg == 'updated'}">
                <div class="slds-notify_container slds-is-relative slds-m-bottom_medium">
                    <div class="slds-notify slds-notify_toast slds-theme_success" role="status">
                        <span class="slds-assistive-text">Success</span>
                        <div class="slds-notify__content">
                            <h2 class="slds-text-heading_small">Selected consumption records updated successfully!</h2>
                        </div>
                    </div>
                </div>
            </c:if>
            <c:if test="${param.msg == 'notfound'}">
                <div class="slds-notify_container slds-is-relative slds-m-bottom_medium">
                    <div class="slds-notify slds-notify_toast slds-theme_error" role="status">
                        <span class="slds-assistive-text">Error</span>
                        <div class="slds-notify__content">
                            <h2 class="slds-text-heading_small">No consumption records found for the selected date.</h2>
                        </div>
                    </div>
                </div>
            </c:if>

            <!-- Date Filter Card -->
            <article class="slds-card slds-m-bottom_medium">
                <div class="slds-card__body slds-card__body_inner">
                    <form action="FetchConsumptionByDateServlet" method="get" class="slds-form slds-form_horizontal">
                        <div class="slds-grid slds-gutters slds-grid_vertical-align-center">
                            <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-3">
                                <div class="slds-form-element">
                                    <label class="slds-form-element__label" for="selected_date">
                                        <abbr class="slds-required" title="required">* </abbr>Select Date
                                    </label>
                                    <div class="slds-form-element__control">
                                        <input type="date" id="selected_date" name="selected_date" value="${selected_date}" class="slds-input" required />
                                    </div>
                                </div>
                            </div>
                            <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-3">
                                <button type="submit" class="slds-button slds-button_brand">
                                    Load Records
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </article>

            <!-- Records Table Card -->
            <c:if test="${not empty consumption_list}">
                <article class="slds-card">
                    <form action="UpdateConsumptionByDateServlet" method="post" onsubmit="return validateSelection();">
                        <input type="hidden" name="selected_date" value="${selected_date}">

                        <div class="slds-card__body slds-scrollable_x">
                            <table class="slds-table slds-table_cell-buffer slds-table_bordered slds-table_col-bordered">
                                <thead>
                                    <tr class="slds-line-height_reset">
                                        <th class="slds-text-align_center" scope="col" style="width: 3.25rem;">
                                            <div class="slds-checkbox">
                                                <input type="checkbox" id="selectAll" onclick="toggleSelectAll(this)" />
                                                <label class="slds-checkbox__label" for="selectAll">
                                                    <span class="slds-checkbox_faux"></span>
                                                </label>
                                            </div>
                                        </th>
                                        <th scope="col"><div class="slds-truncate" title="Issue No">Issue No</div></th>
                                        <th scope="col"><div class="slds-truncate" title="Item Name">Item Name</div></th>
                                        <th scope="col" style="width: 80px;"><div class="slds-truncate" title="UOM">UOM</div></th>
                                        <th scope="col"><div class="slds-truncate" title="Department">Department</div></th>
                                        <th scope="col"><div class="slds-truncate" title="Issued To">Issued To</div></th>
                                        <th scope="col" style="width: 110px;"><div class="slds-truncate" title="Quantity">Quantity</div></th>
                                        <th scope="col" style="width: 110px;"><div class="slds-truncate" title="Unit Price">Unit Price</div></th>
                                        <th scope="col" style="width: 120px;"><div class="slds-truncate" title="Total Value">Total Value</div></th>
                                        <th scope="col"><div class="slds-truncate" title="Remarks">Remarks</div></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach var="item" items="${consumption_list}" varStatus="status">
                                        <tr class="slds-hint-parent">
                                            <!-- Selection Checkbox -->
                                            <td class="slds-text-align_center">
                                                <div class="slds-checkbox">
                                                    <input type="checkbox" name="selected_issue_id" value="${item.issue_id}" 
                                                           id="cb_${status.index}" class="select-row" />
                                                    <label class="slds-checkbox__label" for="cb_${status.index}">
                                                        <span class="slds-checkbox_faux"></span>
                                                    </label>
                                                </div>
                                            </td>

                                            <!-- Hidden Inputs -->
                                            <input type="hidden" name="issue_id" value="${item.issue_id}">
                                            <input type="hidden" name="item_id" value="${item.item_id}">
                                            <input type="hidden" name="po_item_id" value="${item.po_item_id}">

                                            <td><input type="text" value="${item.issueno}" readonly tabindex="-1" /></td>
                                            <td><input type="text" value="${item.item_name}" readonly tabindex="-1" /></td>
                                            <td><input type="text" value="${item.uom}" readonly tabindex="-1" /></td>
                                            
                                            <td>
                                                <input type="text" name="department_${item.issue_id}" value="${item.department}" 
                                                       onchange="autoCheckRow(${status.index})" />
                                            </td>
                                            <td>
                                                <input type="text" name="issued_to_${item.issue_id}" value="${item.issued_to}" 
                                                       onchange="autoCheckRow(${status.index})" />
                                            </td>
                                            <td>
                                                <input type="number" step="0.01" id="qty_${status.index}" name="qty_issued_${item.issue_id}"
                                                       value="${item.qty_issued}" onkeyup="calculateRowTotal(${status.index})"
                                                       onchange="calculateRowTotal(${status.index})" required />
                                            </td>
                                            <td>
                                                <input type="text" id="price_${status.index}" value="${item.unit_price}" readonly tabindex="-1" />
                                            </td>
                                            <td>
                                                <input type="text" id="total_${status.index}" value="${item.total_value}" readonly tabindex="-1" />
                                            </td>
                                            <td>
                                                <input type="text" name="remarks_${item.issue_id}" value="${item.remarks}" 
                                                       onchange="autoCheckRow(${status.index})" />
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </div>

                        <!-- Sticky Bottom Footer Action Bar -->
                        <div class="action-bar-sticky slds-grid slds-grid_align-spread slds-grid_vertical-align-center">
                            <span class="slds-text-body_small slds-text-color_weak">Select rows to apply changes to stock and ledger balances.</span>
                            <div>
                                <a href="editConsumption.jsp" class="slds-button slds-button_neutral slds-m-right_small">Reset</a>
                                <button type="submit" class="slds-button slds-button_brand">Update Selected Entries</button>
                            </div>
                        </div>
                    </form>
                </article>
            </c:if>
        </div>
    </div>
</body>
</html>