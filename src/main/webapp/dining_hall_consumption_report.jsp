<%@page import="java.util.*, java.util.stream.*"%>
<%
    List<Map<String,Object>> reportList = (List<Map<String,Object>>)request.getAttribute("reportList");
    if(reportList == null) reportList = new ArrayList<>();

    Map<String, Map<String, List<Map<String, Object>>>> groupedData = reportList.stream()
        .collect(Collectors.groupingBy(
            r -> (String)r.get("issue_day"),
            LinkedHashMap::new,
            Collectors.groupingBy(r -> (String)r.get("session"), LinkedHashMap::new, Collectors.toList())
        ));
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dining Hall Consumption Report</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/design-system/2.17.6/styles/salesforce-lightning-design-system.min.css" />
    <style>
        body{
            background:#f4f6f9;
            font-family:"Salesforce Sans", Arial, sans-serif;
            color:#181818;
        }

        /* Page */
        .page-container{
            width:92%;
            margin:25px auto;
        }

        /* Card */
        .slds-card{
            border:1px solid #d8dde6;
            border-radius:8px;
            overflow:hidden;
            background:#fff;
            box-shadow:0 2px 8px rgba(0,0,0,0.08);
        }

        .slds-card__header{
            background:linear-gradient(to right,#ffffff,#f7f9fb);
            border-bottom:1px solid #d8dde6;
            padding:1.2rem 1.5rem;
        }

        .slds-card__header h2{
            font-size:1.25rem;
            font-weight:700;
            color:#16325c;
        }

        .slds-card__header p{
            color:#54698d;
        }

        /* Body */
        .slds-card__body{
            background:#fff;
            padding:1.5rem;
        }

        /* Filter Section */
        form{
            background:#fafbfc;
            border:1px solid #d8dde6;
            border-radius:8px;
            padding:1rem;
            margin-bottom:1.5rem;
        }

        .slds-form-element__label{
            font-weight:600;
            color:#3e3e3c;
        }

        .slds-input,
        .slds-select{
            border-radius:6px;
            border:1px solid #c9c7c5;
        }

        .slds-input:focus,
        .slds-select:focus{
            border-color:#0176d3;
            box-shadow:0 0 0 2px rgba(1,118,211,.15);
        }

        /* Button */
        .slds-button_brand{
            border-radius:6px;
            font-weight:600;
            padding:0 20px;
        }

        /* Main Table */
        .slds-table{
            border:1px solid #d8dde6;
            border-radius:8px;
            overflow:hidden;
        }

        .slds-table thead th{
            background:#f3f5f7;
            color:#16325c;
            font-weight:700;
            font-size:13px;
            text-transform:uppercase;
            letter-spacing:.5px;
            border-bottom:2px solid #d8dde6;
        }

        /* Date Header */
        .date-row{
            background:linear-gradient(to right,#eef4ff,#f8fbff);
            font-weight:700;
            color:#16325c;
        }

        .date-row td{
            padding:14px;
            border-top:2px solid #0176d3;
            font-size:15px;
        }

        /* Session Trigger Row Styles */
        .session-trigger {
            cursor: pointer;
            padding: 8px 6px;
            display: flex;
            align-items: center;
            border-radius: 4px;
            transition: background 0.2s ease;
        }

        .session-trigger:hover {
            background: #f4f6f9;
        }

        .session-trigger::before {
            content: "\25B6";
            display: inline-block;
            margin-right: 8px;
            color: #54698d;
            font-size: 0.75rem;
            transition: color 0.2s ease;
        }

        .session-trigger:hover::before {
            color: #0176d3;
        }

        /* Session Link */
        .slds-text-link{
            color:#0176d3;
            font-weight:700;
            text-decoration:none;
        }

        .slds-text-link:hover{
            text-decoration:underline;
        }

        /* Custom Modal Popup Framework Styles */
        .custom-modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(8, 7, 7, 0.6);
            z-index: 9999;
            justify-content: center;
            align-items: center;
            backdrop-filter: blur(2px);
        }

        .custom-modal.is-open {
            display: flex;
        }

        .custom-modal-content {
            background: #ffffff;
            border-radius: 8px;
            width: 600px;
            max-width: 90%;
            box-shadow: 0 4px 24px rgba(0, 0, 0, 0.24);
            animation: modalSlideUp 0.25s cubic-bezier(0.1, 0.8, 0.3, 1);
            overflow: hidden;
        }

        @keyframes modalSlideUp {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .custom-modal-header {
            background: #f3f5f7;
            padding: 1rem 1.5rem;
            border-bottom: 1px solid #d8dde6;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .custom-modal-header h3 {
            font-size: 1.1rem;
            font-weight: 700;
            color: #16325c;
            margin: 0;
        }

        .close-modal-btn {
            background: none;
            border: none;
            font-size: 1.5rem;
            font-weight: 300;
            color: #54698d;
            cursor: pointer;
            line-height: 1;
            padding: 0 4px;
        }

        .close-modal-btn:hover {
            color: #c23934;
        }

        .custom-modal-body {
            padding: 1.5rem;
            max-height: 65vh;
            overflow-y: auto;
        }

        .nested-table-wrapper {
            margin-top: 0;
            border: 1px solid #d8dde6;
        }

        .nested-table-wrapper td:last-child {
            font-weight: 600;
            color: #0b5cab;
        }

        /* Grand Total */
        .grand-total-row{
            background:#f3f5f7;
            font-weight:700;
        }

        .grand-total-row td{
            border-top:3px solid #0176d3;
            padding:14px;
            font-size:16px;
            color:#16325c;
        }

        /* Scrollable Large Tables */
        .table-responsive{
            overflow-x:auto;
        }

        /* Responsive */
        @media(max-width:768px){
            .page-container{
                width:98%;
            }
            .slds-card__body{
                padding:1rem;
            }
        }
        .slds-table{
    width:100%;
    table-layout:fixed;
}

.slds-table td{
    vertical-align:top;
}
/* Filter Panel */
.filter-panel{
    background:#ffffff;
    border:1px solid #d8dde6;
    border-radius:10px;
    padding:18px;
    margin-bottom:20px;
    box-shadow:0 2px 6px rgba(0,0,0,.05);
}

.filter-grid{
    display:grid;
    grid-template-columns:
        220px
        220px
        220px
        150px;
    gap:16px;
    align-items:end;
}

.filter-item label{
    display:block;
    margin-bottom:6px;
    font-weight:600;
    color:#16325c;
}

.filter-button{
    display:flex;
    align-items:flex-end;
}

.filter-button button{
    width:100%;
    height:40px;
    font-weight:600;
}

/* Responsive */
@media(max-width:900px){

    .filter-grid{
        grid-template-columns:1fr;
    }

    .filter-button button{
        width:100%;
    }
}
    </style>
</head>
<body>
<%@ include file="header.jsp" %>
<div class="slds-scope page-container">
    <article class="slds-card">
        

        <div class="slds-card__body slds-card__body_inner">
            <form method="get"
      action="DiningHallConsumptionReportServlet"
      class="filter-panel">

    <div class="filter-grid">

        <div class="filter-item">
            <label class="slds-form-element__label">From Date</label>
            <input type="date"
                   name="from_date"
                   class="slds-input"
                   value="<%= request.getParameter("from_date") != null ? request.getParameter("from_date") : "" %>">
        </div>

        <div class="filter-item">
            <label class="slds-form-element__label">To Date</label>
            <input type="date"
                   name="to_date"
                   class="slds-input"
                   value="<%= request.getParameter("to_date") != null ? request.getParameter("to_date") : "" %>">
        </div>

        <div class="filter-item">
            <label class="slds-form-element__label">Session</label>
            <select name="session" class="slds-select">
                <option value="">All Sessions</option>
                <% for(String s : Arrays.asList("BREAKFAST","LUNCH","SNACKS","DINNER")) { %>
                    <option value="<%= s %>"
                        <%= s.equals(request.getParameter("session")) ? "selected" : "" %>>
                        <%= s %>
                    </option>
                <% } %>
            </select>
        </div>

        <div class="filter-button">
            <button type="submit"
                    class="slds-button slds-button_brand">
                Run Report
            </button>
        </div>

    </div>

</form>

            <table class="slds-table slds-table_cell-buffer slds-table_bordered">
                <thead>
                    <tr class="slds-text-title_caps">
                        <th scope="col" colspan="4"><div class="slds-truncate">Date wise Breakdown </div></th>
                    </tr>
                </thead>
               <tbody>
<%
double grandTotal = 0;
int count = 0;
int modalCounter = 0;

for(Map.Entry<String, Map<String, List<Map<String, Object>>>> dateEntry : groupedData.entrySet()) {

    double dayTotal = dateEntry.getValue()
            .values()
            .stream()
            .flatMap(List::stream)
            .mapToDouble(i -> ((Number)i.get("value")).doubleValue())
            .sum();

    grandTotal += dayTotal;

    if(count % 4 == 0){
%>
<tr>
<%
    }
%>

<td style="vertical-align:top; width:25%; padding: 8px; border: 1px solid #d8dde6;">

    <div style="font-weight:bold; background:#eef4ff; color:#16325c; padding:8px; border-radius:4px; margin-bottom:8px; display:flex; justify-content:space-between; align-items:center;">
        <span style="font-size:18px;"><%= dateEntry.getKey() %></span>
        <span style="background:#fff; padding:2px 6px; border-radius:10px; font-size:18px; border:1px solid #cbd5e1;"><%= String.format("%.2f", dayTotal) %></span>
    </div>

    <% for(Map.Entry<String, List<Map<String, Object>>> sessionEntry : dateEntry.getValue().entrySet()) {

        List<Map<String, Object>> items = sessionEntry.getValue();

        double sessionTotal = items.stream()
                .mapToDouble(i -> ((Number)i.get("value")).doubleValue())
                .sum();
        
        modalCounter++;
    %>

    <div class="session-trigger" onclick="toggleModal('session-modal-<%= modalCounter %>', true)">
        <span class="slds-text-link" style="font-size:13px;"><%= sessionEntry.getKey() %></span>
        <span style="color: #54698d; font-size: 0.8rem; margin-left: 4px; font-weight: normal;">
            (<%= String.format("%.2f", sessionTotal) %>)
        </span>
    </div>

    <div id="session-modal-<%= modalCounter %>" class="custom-modal" onclick="if(event.target === this) toggleModal('session-modal-<%= modalCounter %>', false)">
        <div class="custom-modal-content">
            <div class="custom-modal-header">
                <h3><%= dateEntry.getKey() %> &mdash; <%= sessionEntry.getKey() %></h3>
                <button type="button" class="close-modal-btn" onclick="toggleModal('session-modal-<%= modalCounter %>', false)">&times;</button>
            </div>
            <div class="custom-modal-body">
                <div class="nested-table-wrapper">
                    <table class="slds-table slds-table_cell-buffer slds-table_bordered">
                        <thead>
                            <tr class="slds-text-title_caps">
                                <th style="padding: 8px 12px;">Item Name</th>
                                <th style="padding: 8px 12px; text-align: center; width: 80px;">Qty</th>
                                <th style="padding: 8px 12px; text-align: right; width: 120px;">Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for(Map<String,Object> item : items){ %>
                            <tr>
                                <td style="padding: 8px 12px; font-weight: 500;"><%= item.get("item_name") %></td>
                                <td style="padding: 8px 12px; text-align: center; font-variant-numeric: tabular-nums;"><%= item.get("qty") %></td>
                                <td style="padding: 8px 12px; text-align: right; font-variant-numeric: tabular-nums;"><%= String.format("%.2f", ((Number)item.get("value")).doubleValue()) %></td>
                            </tr>
                            
                            <% } %>
                            
                        </tbody>
                    </table>
                    <p align="right" style="font-size:18px; color:red;"><b>Grand Total : <%= String.format("%.2f", sessionTotal) %></b></p>
                </div>
            </div>
        </div>
    </div>

    <% } %>

</td>

<%
    count++;

    if(count % 4 == 0){
%>
</tr>
<%
    }
}

if(count % 4 != 0){
    while(count % 4 != 0){
%>
<td style="border: 1px solid #d8dde6; background:#fafbfc;"></td>
<%
        count++;
    }
%>
</tr>
<%
}
%>
</tbody>
               <tfoot class="grand-total-row">
    <tr>
        <td colspan="3" style="text-align:right;font-weight:700;">
            Grand Total
        </td>
        <td class="slds-text-align_right"
            style="font-weight:700;color:#0176d3;">
            <%= String.format("%.2f", grandTotal) %>
        </td>
    </tr>
</tfoot>
            </table>
        </div>
    </article>
</div>

<script>
function toggleModal(modalId, isOpen) {
    const modalTarget = document.getElementById(modalId);
    if (modalTarget) {
        if (isOpen) {
            modalTarget.classList.add('is-open');
            document.body.style.overflow = 'hidden'; // Lock primary container viewport scroll rules
        } else {
            modalTarget.classList.remove('is-open');
            document.body.style.overflow = ''; // Release primary viewport rules
        }
    }
}
</script>
</body>
</html>