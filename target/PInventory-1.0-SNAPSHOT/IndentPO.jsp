<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.bean.IndentItems" %>
<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Purchase Order</title>
    <style>
        /* Global Lightning Design Tokens */
        :root {
            --slds-c-brand: #0176d3;
            --slds-c-brand-hover: #014486;
            --slds-g-neutral-10: #f3f3f3;
            --slds-g-neutral-20: #e5e5e5;
            --slds-g-text-10: #181818;
            --slds-g-text-20: #2b2b2b;
            --slds-g-text-30: #444444;
            --slds-error: #ea001e;
            --border-radius-medium: 0.25rem;
            --border-radius-large: 0.5rem;
        }

        body {
            font-family: "Salesforce Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #ffffff;
            color: var(--slds-g-text-10);
            font-size: 0.8125rem;
            min-height: 100vh;
        }

        /* Adjusted layout spacing to accommodate the right side panel floating track */
        .main-content {
            padding: 24px 120px 24px 24px;
            max-width: 1440px;
            margin: 0 auto;
            box-sizing: border-box;
            position: relative;
        }

        /* Page Header - Lightning Layout structure */
        .slds-page-header {
            background: #ffffff;
            padding: 16px 24px;
            border: 1px solid var(--slds-g-neutral-20);
            border-radius: var(--border-radius-large);
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
            margin-bottom: 16px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .slds-page-header__title {
            font-size: 1.125rem;
            font-weight: 700;
            color: var(--slds-g-text-10);
            margin: 0;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        /* Pure CSS Lightning Standard Icon Silhouette */
        .slds-icon-container {
            background: #1b96ff;
            width: 32px;
            height: 32px;
            border-radius: var(--border-radius-medium);
            display: flex;
            align-items: center;
            justify-content: center;
            color: #ffffff;
            font-weight: bold;
        }

        /* Lightning Workspace Card Structural Base */
        .slds-card {
            background: #ffffff;
            border: 1px solid var(--slds-g-neutral-20);
            border-radius: var(--border-radius-large);
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
            overflow: hidden;
            padding: 24px;
        }

        /* Data Table Container */
        .table-container {
            overflow-x: auto;
            border: 1px solid var(--slds-g-neutral-20);
            border-radius: var(--border-radius-medium);
            margin-bottom: 24px;
        }

        /* Data Table Native Structure Blueprint */
        table.main-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.8125rem;
            text-align: left;
        }

        th, td {
            padding: 10px 14px;
            border-bottom: 1px solid var(--slds-g-neutral-20);
            vertical-align: middle;
            color: #000000;
        }

        th {
            background: var(--slds-g-neutral-10);
            color: var(--slds-g-text-20);
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            height: 34px;
        }

        tr:hover td {
            background-color: #f9f9f9;
        }

        /* Checkbox Layout Control */
        input[type="checkbox"] {
            width: 1rem;
            height: 1rem;
            display: inline-block;
            vertical-align: middle;
            margin: 0;
            cursor: pointer;
        }

        /* Persistent Right Side Floating Dock Panel Container */
        .floating-action-dock {
            position: fixed;
            right: 24px;
            top: 50%;
            transform: translateY(-50%);
            z-index: 999;
            background: #ffffff;
            padding: 12px;
            border-radius: var(--border-radius-large);
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
            border: 1px solid var(--slds-g-neutral-20);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        /* Lightning Brand Action Button Style (Vertical stack text alignment presentation) */
        .submit-btn {
            background: var(--slds-c-brand);
            color: #ffffff;
            border: 1px solid transparent;
            padding: 16px 14px;
            width: 44px;
            line-height: 1.4;
            letter-spacing: 0.05em;
            word-wrap: break-word;
            writing-mode: vertical-rl;
            text-transform: uppercase;
            transform: rotate(180deg);
            white-space: nowrap;
            border-radius: var(--border-radius-medium);
            cursor: pointer;
            font-size: 0.75rem;
            font-weight: 700;
            transition: background 0.1s, transform 0.1s;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .submit-btn:hover {
            background: var(--slds-c-brand-hover);
        }

        /* Responsive Mobile Layout Blueprint */
        @media (max-width: 768px) {
            .main-content {
                padding: 12px 12px 80px 12px; /* Pad bottom for mobile view static layout shift */
            }
            
            .slds-card {
                padding: 16px;
            }

            table.main-table, thead, tbody, th, td, tr {
                display: block;
            }

            thead tr {
                display: none;
            }

            table.main-table tr {
                margin-bottom: 12px;
                border: 1px solid var(--slds-g-neutral-20);
                border-radius: var(--border-radius-medium);
                background: #ffffff;
                padding: 6px 0;
            }

            table.main-table td {
                border: none;
                border-bottom: 1px solid var(--slds-g-neutral-10);
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 10px 14px;
                text-align: right;
            }

            table.main-table td:last-child {
                border-bottom: none;
            }

            table.main-table td:before {
                content: attr(data-label);
                font-weight: 700;
                color: var(--slds-g-text-30);
                text-transform: uppercase;
                font-size: 0.75rem;
                float: left;
                text-align: left;
                padding-right: 10px;
            }

            /* Shift dock container to a sticky bottom bar configuration on standard mobile viewports */
            .floating-action-dock {
                position: fixed;
                bottom: 0;
                top: auto;
                left: 0;
                right: 0;
                transform: none;
                width: 100%;
                box-sizing: border-box;
                background: #ffffff;
                padding: 12px 16px;
                border-radius: 0;
                border-top: 1px solid var(--slds-g-neutral-20);
                box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.08);
            }

            .submit-btn {
                writing-mode: horizontal-tb;
                transform: none;
                width: 100%;
                height: 40px;
                font-size: 0.875rem;
                padding: 0;
            }
        }
    </style>
</head>
<body>
<%@ include file="header.jsp" %>

<div class="main-content">

    <div class="slds-page-header">
        <div class="slds-page-header__title">
            <div class="slds-icon-container">PO</div>
            <div>
                <span style="font-size:0.75rem;font-weight:normal;color:var(--slds-g-text-30);display:block;text-transform:uppercase;">Procurement Pipeline</span>
                Create Purchase Order
            </div>
        </div>
    </div>

    <div class="slds-card">
        <form method="get" action="<%=request.getContextPath()%>/PurchaseOrderServlet">
            
            <div class="floating-action-dock">
                <input type="submit" class="submit-btn" value="Process Selected">
            </div>

            <div class="table-container">
                <table class="main-table">
                    <thead>
                        <tr>
                            <th style="width: 5%; text-align: center;">Select</th>
                            <th style="width: 5%;">ID</th>
                            <th style="width: 10%;">Indent No</th>
                            <th style="width: 10%;">Date</th>
                            <th style="width: 15%;">Item</th>
                            <th style="width: 8%;">Quantity</th>
                            <th style="width: 10%;">Department</th>
                            <th style="width: 10%;">Requested By</th>
                            <th style="width: 12%;">Purpose</th>
                            <th style="width: 5%;">Istatus</th>
                            <th style="width: 5%;">Approved By</th>
                            <th style="width: 5%;">Status</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                    List<IndentItems> indentList = (List<IndentItems>) request.getAttribute("indentList");
                    if (indentList != null && !indentList.isEmpty()) {
                        for (IndentItems ind : indentList) {
                    %>
                    <tr>
                        <td data-label="Select" style="text-align: center;"><input type="checkbox" name="selectedIds" value="<%= ind.getId() %>"></td>
                        <td data-label="ID" style="font-weight: 600;"><%= ind.getId() %></td>
                        <td data-label="Indent No"><%= ind.getIndentNo() %></td>
                        <td data-label="Date"><%= ind.getIndentDate() %></td>
                        <td data-label="Item" style="color: var(--slds-c-brand); font-weight: 600;"><%= ind.getItemName() %></td>
                        <td data-label="Quantity"><%= ind.getQty() %></td>
                        <td data-label="Department"><%= ind.getDepartment() %></td>
                        <td data-label="Requested By"><%= ind.getRequestedBy() %></td>
                        <td data-label="Purpose"><%= ind.getPurpose() %></td>
                        <td data-label="Istatus"><%= ind.getIstatus() %></td>
                        <td data-label="Approved By"><%= ind.getIstatusApprove() %></td>
                        <td data-label="Status"><%= ind.getStatus() %></td>
                    </tr>
                    <%
                        }
                    } else {
                    %>
                    <tr>
                        <td colspan="12" style="color: var(--slds-error); text-align: center; padding: 32px; font-weight: bold;">No records found</td>
                    </tr>
                    <%
                    }
                    %>
                    </tbody>
                </table>
            </div>
            
        </form>
    </div>
</div>

</body>
</html>