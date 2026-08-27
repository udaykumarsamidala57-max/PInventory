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
    <!-- Modern Typography & Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" />

   <style>
    :root {
        --bg-body: #f8fafc;
        --card-bg: #ffffff;
        --border-subtle: #e2e8f0;
        --border-strong: #cbd5e1;
        
        --text-heading: #0f172a;
        --text-body: #334155;
        --text-muted: #64748b;
        
        --brand-primary: #1e3a8a;
        --brand-accent: #2563eb;
        --brand-light: #eff6ff;
    }

    body {
        background-color: var(--bg-body);
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
        color: var(--text-body);
        margin: 0;
        padding: 0;
        -webkit-font-smoothing: antialiased;
    }

    .dashboard-container {
        width: 95%;
        max-width: 1400px;
        margin: 28px auto;
    }

    /* Top Header Card */
    .report-header-card {
        background: var(--card-bg);
        border: 1px solid var(--border-subtle);
        border-radius: 12px;
        padding: 20px 24px;
        margin-bottom: 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        box-shadow: 0 1px 3px rgba(0,0,0,0.04);
    }

    .header-title-group {
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .header-icon {
        width: 42px;
        height: 42px;
        background: var(--brand-light);
        color: var(--brand-accent);
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 18px;
    }

    .report-header-card h2 {
        margin: 0;
        font-size: 18px;
        font-weight: 700;
        color: var(--text-heading);
        letter-spacing: -0.01em;
    }

    .report-header-card p {
        margin: 2px 0 0 0;
        font-size: 13px;
        color: var(--text-muted);
    }

    /* Filter Panel */
    .filter-panel {
        background: var(--card-bg);
        border: 1px solid var(--border-subtle);
        border-radius: 12px;
        padding: 16px 20px;
        margin-bottom: 24px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.04);
    }

    .filter-grid {
        display: grid;
        grid-template-columns: 200px 200px 140px;
        gap: 16px;
        align-items: end;
    }

    .filter-item label {
        display: block;
        margin-bottom: 6px;
        font-size: 12px;
        font-weight: 700;
        color: var(--text-muted);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .form-input, .form-select {
        width: 100%;
        height: 38px;
        padding: 0 12px;
        border-radius: 6px;
        border: 1px solid var(--border-strong);
        background-color: var(--card-bg);
        color: var(--text-heading);
        font-size: 14px;
        font-family: inherit;
        box-sizing: border-box;
        transition: border-color 0.15s ease, box-shadow 0.15s ease;
    }

    .form-input:focus, .form-select:focus {
        outline: none;
        border-color: var(--brand-accent);
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
    }

    .btn-brand {
        background: var(--brand-primary);
        color: #ffffff;
        border: none;
        border-radius: 6px;
        font-weight: 600;
        font-size: 13px;
        height: 38px;
        width: 100%;
        cursor: pointer;
        transition: background 0.15s ease;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
    }

    .btn-brand:hover {
        background: #1d4ed8;
    }

    /* Modern Calendar Table Grid */
    .calendar-card {
        background: var(--card-bg);
        border: 1px solid var(--border-subtle);
        border-radius: 12px;
        overflow: hidden;
        box-shadow: 0 1px 3px rgba(0,0,0,0.04);
    }

    .calendar-table {
        width: 100%;
        table-layout: fixed;
        border-collapse: collapse;
    }

    .calendar-table th {
        background: #f1f5f9;
        color: var(--text-muted);
        font-weight: 700;
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        text-align: center;
        padding: 12px 8px;
        border-bottom: 1px solid var(--border-subtle);
        border-right: 1px solid var(--border-subtle);
        width: 14.285%;
    }

    .calendar-table th:last-child {
        border-right: none;
    }

    .calendar-table td {
        vertical-align: top;
        height: 115px;
        padding: 8px;
        border-bottom: 1px solid var(--border-subtle);
        border-right: 1px solid var(--border-subtle);
        background: var(--card-bg);
        transition: background-color 0.15s ease;
    }

    .calendar-table td:last-child {
        border-right: none;
    }

    .calendar-table tr:last-child td {
        border-bottom: none;
    }

    .calendar-table td.empty-day {
        background: #fafafa;
    }

    .calendar-table td:not(.empty-day):hover {
        background-color: #f8fafc;
    }

    /* Day Cell Structure */
    .day-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 8px;
    }

    .day-number {
        font-size: 13px;
        font-weight: 700;
        color: var(--text-heading);
    }

    .day-total-badge {
        background: #f1f5f9;
        color: var(--text-heading);
        padding: 2px 6px;
        border-radius: 4px;
        font-size: 14px;
        font-weight: 800;
        font-variant-numeric: tabular-nums;
        border: 1px solid var(--border-subtle);
    }

    /* Sessions - Clean Compact Badges */
    .session-list {
        display: flex;
        flex-direction: column;
        gap: 3px;
    }

    .session-trigger {
        cursor: pointer;
        padding: 3px 6px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        border-radius: 4px;
        transition: all 0.12s ease;
        background: #f8fafc;
        border: 1px solid var(--border-subtle);
    }

    .session-trigger:hover {
        border-color: var(--border-strong);
        transform: translateY(-1px);
    }

    .session-name {
        font-weight: 500;
        font-size: 14px;
        color: var(--text-heading);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        display: flex;
        align-items: center;
        gap: 5px;
    }

    .session-val {
        font-weight: 700;
        font-size: 14px;
        color: var(--text-body);
        font-variant-numeric: tabular-nums;
    }

    /* Minimal Session Color Accents */
    .session-trigger.morning-drink i { color: #0284c7; }
    .session-trigger.break-fast i { color: #d97706; }
    .session-trigger.lunch i { color: #16a34a; }
    .session-trigger.snacks i { color: #e11d48; }
    .session-trigger.staff-tea i { color: #6366f1; }
    .session-trigger.dinner i { color: #0d9488; }

    /* Grand Total Summary Section */
    .summary-card {
        background: var(--card-bg);
        border: 1px solid var(--border-subtle);
        border-radius: 12px;
        padding: 16px 24px;
        margin-top: 20px;
        display: flex;
        justify-content: flex-end;
        align-items: center;
        gap: 16px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.04);
    }

    .summary-label {
        font-size: 12px;
        font-weight: 700;
        color: var(--text-muted);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .summary-value {
        font-size: 20px;
        font-weight: 800;
        color: var(--brand-primary);
        font-variant-numeric: tabular-nums;
    }

    /* ==========================================================================
       PROFESSIONAL ENTERPRISE MODAL STYLING (REDESIGNED)
       ========================================================================== */
    
    .custom-modal {
        display: none;
        position: fixed;
        top: 0; 
        left: 0; 
        width: 100%; 
        height: 100%;
        background: rgba(15, 23, 42, 0.55);
        z-index: 9999;
        justify-content: center;
        align-items: center;
        backdrop-filter: blur(6px);
        opacity: 0;
        transition: opacity 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }

    .custom-modal.is-open { 
        display: flex; 
        opacity: 1;
    }

    .custom-modal-content {
        background: var(--card-bg);
        border-radius: 12px;
        width: 520px;
        max-width: 92%;
        box-shadow: 0 25px 50px -12px rgba(15, 23, 42, 0.25);
        border: 1px solid var(--border-subtle);
        overflow: hidden;
        display: flex;
        flex-direction: column;
        transform: scale(0.96) translateY(8px);
        transition: transform 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }

    .custom-modal.is-open .custom-modal-content {
        transform: scale(1) translateY(0);
    }

    /* Header Structure */
    .custom-modal-header {
        background: #ffffff;
        padding: 18px 24px;
        border-bottom: 1px solid var(--border-subtle);
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
    }

    .modal-title-container {
        display: flex;
        flex-direction: column;
        gap: 4px;
    }

    .modal-preheading {
        font-size: 11px;
        font-weight: 700;
        color: var(--brand-accent);
        text-transform: uppercase;
        letter-spacing: 0.06em;
        display: flex;
        align-items: center;
        gap: 6px;
    }

    .custom-modal-header h3 {
        font-weight: 700;
        font-size: 16px;
        color: var(--text-heading);
        margin: 0;
        letter-spacing: -0.01em;
    }

    .close-modal-btn {
        background: #f1f5f9; 
        border: none; 
        width: 28px;
        height: 28px;
        border-radius: 6px;
        color: var(--text-muted); 
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        font-size: 13px;
        transition: all 0.15s ease;
    }

    .close-modal-btn:hover { 
        background: #fee2e2;
        color: #ef4444; 
    }

    /* Modal Content Body */
    .custom-modal-body { 
        padding: 0; 
        max-height: 52vh; 
        overflow-y: auto; 
    }

    .modal-table {
        width: 100%;
        border-collapse: collapse;
    }

    .modal-table th {
        background: #f8fafc;
        color: var(--text-muted);
        font-weight: 700;
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        padding: 10px 24px;
        border-bottom: 1px solid var(--border-subtle);
        position: sticky;
        top: 0;
        z-index: 2;
    }

    .modal-table td {
        padding: 12px 24px;
        border-bottom: 1px solid var(--border-subtle);
        font-size: 13px;
        color: var(--text-body);
        transition: background-color 0.12s ease;
    }

    .modal-table tr:hover td {
        background-color: #f8fafc;
    }

    .modal-table tr:last-child td {
        border-bottom: none;
    }

    /* Footer Stat Panel */
    .modal-footer-summary {
        background: #f8fafc;
        padding: 16px 24px;
        border-top: 1px solid var(--border-subtle);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .modal-stat-pill {
        display: flex;
        flex-direction: column;
    }

    .modal-stat-label {
        font-size: 10px;
        font-weight: 700;
        color: var(--text-muted);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .modal-stat-val {
        font-size: 18px;
        font-weight: 800;
        color: var(--text-heading);
        font-variant-numeric: tabular-nums;
    }

    .modal-stat-val.highlight {
        color: var(--brand-primary);
    }

    @media(max-width: 850px){
        .filter-grid{ grid-template-columns: 1fr; }
        .report-header-card { flex-direction: column; align-items: flex-start; gap: 12px; }
    }
</style>
</head>
<body>
<%@ include file="header.jsp" %>

<div class="dashboard-container">
    
    <!-- Top Header -->
    <div class="report-header-card">
        <div class="header-title-group">
            <div class="header-icon">
                <i class="fa-solid fa-utensils"></i>
            </div>
            <div>
                <h2>Dining Hall Consumption Report</h2>
                <p>Monthly aggregate and session-wise breakdown</p>
            </div>
        </div>
    </div>

    <!-- Filter Bar -->
    <form method="get" action="DiningHallConsumptionReportServlet" class="filter-panel">
        <div class="filter-grid">
            <div class="filter-item">
                <label>Month</label>
                <input type="month" name="report_month" class="form-input" 
                       value="<%= reportMonthParam != null ? reportMonthParam : targetYearMonth.toString() %>">
            </div>

            <div class="filter-item">
                <label>Session</label>
                <select name="session" class="form-select">
                    <option value="">All Sessions</option>
                    <% for(String s : Arrays.asList("BREAKFAST","LUNCH","SNACKS","DINNER")) { %>
                        <option value="<%= s %>" <%= s.equals(request.getParameter("session")) ? "selected" : "" %>><%= s %></option>
                    <% } %>
                </select>
            </div>

            <div class="filter-button">
                <button type="submit" class="btn-brand"><i class="fa-solid fa-magnifying-glass"></i> Run Report</button>
            </div>
        </div>
    </form>

    <!-- Calendar Card Grid -->
    <div class="calendar-card">
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

            // 1. Empty padding blocks
            for (int i = 0; i < leadingEmptyCells; i++) {
                out.print("<td class='empty-day'></td>");
                cellCount++;
            }

            // 2. Loop through month days
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
                        <span class="day-total-badge"><%= String.format("%.0f", dayTotal) %></span>
                    <% } %>
                </div>

                <div class="session-list">
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

        String iconClass = "fa-solid fa-utensils";
        String colorClass = "";

        if ("Morning Drink".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-mug-saucer";
            colorClass = "morning-drink";
        } else if ("Break Fast".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-bread-slice";
            colorClass = "break-fast";
        } else if ("Lunch".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-plate-wheat";
            colorClass = "lunch";
        } else if ("Snacks".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-cookie-bite";
            colorClass = "snacks";
        } else if ("Staff Tea".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-mug-hot";
            colorClass = "staff-tea";
        } else if ("Dinner".equalsIgnoreCase(sessionName)) {
            iconClass = "fa-solid fa-bowl-rice";
            colorClass = "dinner";
        }
%>

<div class="session-trigger <%= colorClass %>"
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
                </div>
            </td>
            <%
                cellCount++;
            }

            // 3. Trailing empty padding
            while (cellCount % 7 != 0) {
                out.print("<td class='empty-day'></td>");
                cellCount++;
            }
            %>
            </tr>
            </tbody>
        </table>
    </div>

    <!-- Summary Section -->
    <div class="summary-card">
        <span class="summary-label">Grand Total Volume:</span>
        <span class="summary-value"><%= String.format("%.2f", grandTotal) %></span>
    </div>

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
            <h3><i class="fa-solid fa-circle-info" style="color:#2563eb;"></i> <%= mTitle %></h3>
            <button type="button" class="close-modal-btn" onclick="toggleModal('session-modal-<%= mId %>', false)"><i class="fa-solid fa-xmark"></i></button>
        </div>
        <div class="custom-modal-body">
            <table class="modal-table">
                <thead>
                    <tr>
                        <th style="text-align: left;">Item Name</th>
                        <th style="text-align: center; width: 80px;">Qty</th>
                        <th style="text-align: right; width: 110px;">Value</th>
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
            <span>Total Session Cost:</span>
            <b><%= String.format("%.2f", mTotal) %></b>
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