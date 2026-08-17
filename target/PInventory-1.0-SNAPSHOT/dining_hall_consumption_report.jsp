<%@page import="java.util.*, java.util.stream.*"%>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.YearMonth" %>
<%@ page import="java.time.DayOfWeek" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%
    // 1. Fetch and group database report data
    List<Map<String,Object>> reportList = (List<Map<String,Object>>)request.getAttribute("reportList");
    if(reportList == null) reportList = new ArrayList<>();

    Map<String, Map<String, List<Map<String, Object>>>> groupedData = reportList.stream()
        .collect(Collectors.groupingBy(
            r -> (String)r.get("issue_day"),
            LinkedHashMap::new,
            Collectors.groupingBy(r -> (String)r.get("session"), LinkedHashMap::new, Collectors.toList())
        ));

    // 2. Parse selected month or fall back to current date
    String reportMonthParam = request.getParameter("report_month");
    YearMonth targetYearMonth;
    try {
        if(reportMonthParam != null && !reportMonthParam.trim().isEmpty()) {
            targetYearMonth = YearMonth.parse(reportMonthParam);
        } else {
            targetYearMonth = YearMonth.now();
        }
    } catch(Exception e) {
        targetYearMonth = YearMonth.now();
    }

    int totalDaysInMonth = targetYearMonth.lengthOfMonth();
    LocalDate firstOfMonth = targetYearMonth.atDay(1);
    
    // DayOfWeek mapping: Sunday=7, Monday=1, Tuesday=2... 
    // Convert so that Sunday = 0, Monday = 1, ..., Saturday = 6
    int dayOfWeekValue = firstOfMonth.getDayOfWeek().getValue(); 
    int leadingEmptyCells = (dayOfWeekValue == 7) ? 0 : dayOfWeekValue; 

    // Instantiate a backing list to store structural information for modal buffer streaming
    List<Map<String, Object>> modalBufferList = new ArrayList<>();
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

        .page-container{
            width:96%;
            margin:25px auto;
        }

        .slds-card{
            border:1px solid #d8dde6;
            border-radius:8px;
            overflow:hidden;
            background:#fff;
            box-shadow:0 2px 8px rgba(0,0,0,0.08);
        }

        .slds-card__body{
            background:#fff;
            padding:1.5rem;
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
            grid-template-columns: 220px 220px 150px;
            gap:16px;
            align-items:end;
        }

        .filter-item label{
            display:block;
            margin-bottom:6px;
            font-weight:600;
            color:#16325c;
        }

        .slds-input, .slds-select{
            border-radius:6px;
            border:1px solid #c9c7c5;
        }

        .slds-button_brand{
            border-radius:6px;
            font-weight:600;
            height: 40px;
            width: 100%;
        }

        /* Calendar Grid Overrides */
        .calendar-table {
            width: 100%;
            table-layout: fixed;
            border-collapse: collapse;
            border: 1px solid #d8dde6;
        }

        .calendar-table th {
            background: #f3f5f7;
            color: #16325c;
            font-weight: 700;
            font-size: 18px;
            text-transform: uppercase;
            text-align: center;
            padding: 12px 8px;
            border: 1px solid #d8dde6;
            width: 14.285%;
        }

        .calendar-table td {
            vertical-align: top;
            height: 120px;
            padding: 6px;
            border: 1px solid #d8dde6;
            background: #fff;
        }

        .calendar-table td.empty-day {
            background: #fafbfc;
        }

        .day-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 6px;
            padding-bottom: 4px;
            border-bottom: 1px solid #eef4ff;
        }

        .day-number {
            font-size: 18px;
            font-weight: bold;
            color: #16325c;
        }

        .day-total {
            background: #eef4ff;
            color: #0176d3;
            padding: 1px 6px;
            border-radius: 10px;
            font-size: 18px;
            font-weight: bold;
        }

        /* Sessions inside days */
        .session-trigger {
            cursor: pointer;
            padding: 4px 6px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-radius: 4px;
            transition: background 0.2s ease;
            margin-bottom: 2px;
        }

        .session-trigger:hover {
            background: #f4f6f9;
        }

        .session-name {
            color: black;
            font-weight: 400;
            font-size: 16px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .session-val {
        font-weight: 400;
            color: #54698d;
            font-size: 16px;
        }

        /* Centered Overlay Stylesheet Fixes */
        .custom-modal {
            display: none;
            position: fixed;
            top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(8, 7, 7, 0.6);
            z-index: 9999;
            justify-content: center;
            align-items: center;
            backdrop-filter: blur(2px);
        }

        .custom-modal.is-open { display: flex; }

        .custom-modal-content {
            background: #ffffff;
            border-radius: 8px;
            width: 550px;
            max-width: 90%;
            box-shadow: 0 4px 24px rgba(0, 0, 0, 0.24);
            animation: modalSlideUp 0.2s ease-out;
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }

        @keyframes modalSlideUp {
            from { opacity: 0; transform: translateY(15px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .custom-modal-header {
            background: #fafbfc;
            padding: 12px 20px;
            border-bottom: 1px solid #d8dde6;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .close-modal-btn {
            background: none; 
            border: none; 
            font-size: 1.75rem; 
            color: #706e6b; 
            cursor: pointer;
            line-height: 1;
            padding: 0;
        }

        .close-modal-btn:hover { color: #c23934; }

        .custom-modal-body { 
            padding: 0; 
            max-height: 60vh; 
            overflow-y: auto; 
        }

        .modal-table {
            width: 100%;
            border-collapse: collapse;
        }

        .modal-table th {
            background: #f3f5f7;
            color: #16325c;
            font-weight: 700;
            font-size: 13px;
            text-transform: uppercase;
            padding: 10px 20px;
            border-bottom: 1px solid #d8dde6;
        }

        .modal-table td {
            padding: 10px 20px;
            border-bottom: 1px solid #eee;
            font-size: 14px;
            color: #3e3e3c;
        }

        .modal-table tr:last-child td {
            border-bottom: none;
        }

        .modal-footer-summary {
            background: #fafbfc;
            padding: 14px 20px;
            border-top: 1px solid #d8dde6;
            display: flex;
            justify-content: flex-end;
            align-items: center;
        }

        .grand-total-banner {
            background: #f3f5f7;
            border-top: 2px solid #d8dde6;
            padding: 5px;
            margin-top: 10px;
            text-align: right;
            border-radius: 6px;
        }

        @media(max-width:900px){
            .filter-grid{ grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
<%@ include file="header.jsp" %>
<div class="slds-scope page-container">
    <article class="slds-card">
        <div class="slds-card__body slds-card__body_inner">
            
            <form method="get" action="DiningHallConsumptionReportServlet" class="filter-panel">
                <div class="filter-grid">
                    <div class="filter-item">
                        <label class="slds-form-element__label">Month</label>
                        <input type="month" name="report_month" class="slds-input" 
                               value="<%= reportMonthParam != null ? reportMonthParam : targetYearMonth.toString() %>">
                    </div>

                    <div class="filter-item">
                        <label class="slds-form-element__label">Session</label>
                        <select name="session" class="slds-select">
                            <option value="">All Sessions</option>
                            <% for(String s : Arrays.asList("BREAKFAST","LUNCH","SNACKS","DINNER")) { %>
                                <option value="<%= s %>" <%= s.equals(request.getParameter("session")) ? "selected" : "" %>><%= s %></option>
                            <% } %>
                        </select>
                    </div>

                    <div class="filter-button">
                        <button type="submit" class="slds-button slds-button_brand">Run Report</button>
                    </div>
                </div>
            </form>

            <table class="calendar-table">
                <thead>
                    <tr>
                        <th>Sun</th>
                        <th>Mon</th>
                        <th>Tue</th>
                        <th>Wed</th>
                        <th>Thu</th>
                        <th>Fri</th>
                        <th>Sat</th>
                    </tr>
                </thead>
                <tbody>
                <tr>
                <%
                double grandTotal = 0;
                int modalCounter = 0;
                int cellCount = 0;

                // 1. Print preceding empty padding blocks for calendar grid alignment
                for (int i = 0; i < leadingEmptyCells; i++) {
                    out.print("<td class='empty-day'></td>");
                    cellCount++;
                }

                // 2. Loop systematically day by day through the target month
                for (int day = 1; day <= totalDaysInMonth; day++) {
                    LocalDate currentDate = targetYearMonth.atDay(day);
                    String dateKey = currentDate.toString();
                    String formattedDate = currentDate.format(DateTimeFormatter.ofPattern("dd MMMM yyyy"));

                    double dayTotal = 0;
                    Map<String, List<Map<String, Object>>> sessionMap = groupedData.get(dateKey);

                    if (sessionMap != null) {
                        dayTotal = sessionMap.values().stream()
                                .flatMap(List::stream)
                                .mapToDouble(i -> ((Number)i.get("value")).doubleValue())
                                .sum();
                    }
                    grandTotal += dayTotal;

                    if (cellCount > 0 && cellCount % 7 == 0) {
                        out.print("</tr><tr>");
                    }
                %>
                <td>
                    <div class="day-header">
                        <span class="day-number"><%= day %></span>
                        <% if(dayTotal > 0) { %>
                            <span class="day-total"><%= String.format("%.2f", dayTotal) %></span>
                        <% } %>
                    </div>

                 <%
if (sessionMap != null) {

    List<String> sessionOrder = Arrays.asList(
        "Morning Drink",
        "Break Fast",
        "Lunch",
        "Snacks",
        "Staff Tea",
        "Dinner"
    );

    for(String sessionName : sessionOrder) {

        List<Map<String, Object>> items = sessionMap.get(sessionName);

        if(items == null || items.isEmpty()) {
            continue;
        }

        double sessionTotal = items.stream()
                .mapToDouble(i -> ((Number)i.get("value")).doubleValue())
                .sum();

        modalCounter++;

        Map<String, Object> modalData = new HashMap<>();
        modalData.put("id", modalCounter);
        modalData.put("title", formattedDate + " &middot; " + sessionName);
        modalData.put("items", items);
        modalData.put("total", sessionTotal);
        modalBufferList.add(modalData);

        String iconClass = "fa-solid fa-utensils text-info";

        if ("Morning Drink".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-mug-saucer text-info";
        } else if ("Break Fast".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-bread-slice text-warning";
        } else if ("Lunch".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-plate-wheat text-success";
        } else if ("Snacks".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-cookie-bite text-warning";
        } else if ("Staff Tea".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-mug-hot text-secondary";
        } else if ("Dinner".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-bowl-rice text-primary";
        }
%>

<div class="session-trigger"
     onclick="toggleModal('session-modal-<%= modalCounter %>', true)">

    <span class="session-name">
        <i class="<%= iconClass %>"></i>
        <%= sessionName %>
    </span>

    <span class="session-val">
        <%= String.format("%.0f", sessionTotal) %>
    </span>

</div>

<%
    }
}
%>
                </td>
                <%
                    cellCount++;
                }

                // 3. Append trailing empty cell blocks to finalize the calendar layout row safely
                while (cellCount % 7 != 0) {
                    out.print("<td class='empty-day'></td>");
                    cellCount++;
                }
                %>
                </tr>
                </tbody>
            </table>

            <div class="grand-total-banner">
                <span style="font-size: 16px; font-weight: 600; color: #54698d; margin-right: 15px;">Grand Total Volume:</span>
                <span style="font-size: 22px; font-weight: 800; color: #0176d3;"><%= String.format("%.2f", grandTotal) %></span>
            </div>

        </div>
    </article>
</div>

<% 
for(Map<String, Object> mBlock : modalBufferList) { 
    int mId = (Integer)mBlock.get("id");
    String mTitle = (String)mBlock.get("title");
    List<Map<String, Object>> mItems = (List<Map<String, Object>>)mBlock.get("items");
    double mTotal = (Double)mBlock.get("total");
%>
<div id="session-modal-<%= mId %>" class="custom-modal" onclick="if(event.target === this) toggleModal('session-modal-<%= mId %>', false)">
    <div class="custom-modal-content">
        <div class="custom-modal-header">
            <h3 style="font-weight: 700; font-size:1.1rem; color: #16325c; margin: 0;"><%= mTitle %></h3>
            <button type="button" class="close-modal-btn" onclick="toggleModal('session-modal-<%= mId %>', false)">&times;</button>
        </div>
        <div class="custom-modal-body">
            <table class="modal-table">
                <thead>
                    <tr>
                        <th style="text-align: left;">Item Name</th>
                        <th style="text-align: center; width: 80px;">Qty</th>
                        <th style="text-align: right; width: 120px;">Value</th>
                    </tr>
                </thead>
                <tbody>
                    <% for(Map<String,Object> item : mItems){ %>
                    <tr>
                        <td style="text-align: left; font-weight: 500;"><%= item.get("item_name") %></td>
                        <td style="text-align: center; font-variant-numeric: tabular-nums;"><%= item.get("qty") %></td>
                        <td style="text-align: right; font-variant-numeric: tabular-nums;"><%= String.format("%.2f", ((Number)item.get("value")).doubleValue()) %></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <div class="modal-footer-summary">
            <span style="font-size: 15px; color: #333;">
                Total Session Cost: <b style="color:#c23934; font-size: 16px; margin-left: 5px;"><%= String.format("%.2f", mTotal) %></b>
            </span>
        </div>
    </div>
</div>
<% } %>

<script>
function toggleModal(modalId, isOpen) {
    const modalTarget = document.getElementById(modalId);
    if (modalTarget) {
        if (isOpen) {
            modalTarget.classList.add('is-open');
            document.body.style.overflow = 'hidden';
        } else {
            modalTarget.classList.remove('is-open');
            document.body.style.overflow = '';
        }
    }
}
</script>
</body>
</html>