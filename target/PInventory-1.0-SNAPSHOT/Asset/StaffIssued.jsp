<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Staff Issued Assets</title>
    <style>
        /* Salesforce-inspired Global Styles */
        body {
            font-family: 'Salesforce Sans', Arial, sans-serif;
            background-color: #f3f3f3;
            color: #181818;
            margin: 0;
            padding: 24px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        /* Salesforce Card Layout */
        .slds-card {
            background-color: #ffffff;
            border: 1px solid #dddbda;
            border-radius: 0.25rem;
            box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.05);
            overflow: hidden;
        }

        /* Card Header styling */
        .slds-card__header {
            padding: 1rem 1.5rem;
            border-bottom: 1px solid #dddbda;
            display: flex;
            align-items: center;
            justify-content: space-between;
            background-color: #fafaf9;
        }

        .slds-card__header-title {
            display: flex;
            align-items: center;
            font-size: 1.125rem;
            font-weight: 700;
            color: #080707;
            margin: 0;
        }

        /* Salesforce Icon Placeholder */
        .slds-icon-container {
            background-color: #0176d3; /* Salesforce Blue */
            color: #ffffff;
            border-radius: 4px;
            width: 32px;
            height: 32px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-right: 12px;
            font-weight: bold;
            font-size: 0.85rem;
        }

        /* Salesforce Data Table Styling */
        .slds-table-container {
            overflow-x: auto;
        }

        .slds-table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
        }

        .slds-table th {
            background-color: #fafaf9;
            color: #444444;
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.0625rem;
            padding: 10px 16px;
            border-bottom: 2px solid #dddbda;
        }

        .slds-table td {
            padding: 12px 16px;
            border-bottom: 1px solid #dddbda;
            color: #2b2826;
            font-size: 0.875rem;
            vertical-align: middle;
        }

        /* Hover effect */
        .slds-table tbody tr:hover {
            background-color: #f3f3f3;
            cursor: default;
        }

        /* Salesforce Badge / Pill */
        .slds-badge {
            display: inline-flex;
            align-items: center;
            background-color: #e0e5ee;
            color: #0176d3;
            padding: 0.25rem 0.75rem;
            border-radius: 15rem;
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
        }

        /* Card Footer */
        .slds-card__footer {
            padding: 0.75rem 1.5rem;
            background-color: #fafaf9;
            border-top: 1px solid #dddbda;
            font-size: 0.875rem;
            color: #444444;
        }
    </style>
</head>

<body>

<div class="container">

    <%
        List<Map<String,Object>> assetList = (List<Map<String,Object>>)request.getAttribute("assetList");
        int i = 1;
    %>

    <div class="slds-card">
        
        <div class="slds-card__header">
            <h2 class="slds-card__header-title">
                <span class="slds-icon-container" title="Assets">AST</span>
                Staff Issued Assets
            </h2>
        </div>

        <div class="slds-table-container">
            <table class="slds-table">
                <thead>
                    <tr>
                        <th style="width: 80px;">Sl No</th>
                        <th>Asset Code</th>
                        <th>Asset Name</th>
                        <th>Brand</th>
                        <th>Staff Name</th>
                        <th>Assigned Date</th>
                        <th>Assigned By</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    if (assetList != null && !assetList.isEmpty()) {
                        for (Map<String,Object> row : assetList) {
                    %>
                    <tr>
                        <td><%=i++%></td>
                        <td style="font-weight: 600; color: #0176d3;"><%=row.get("assetCode")%></td>
                        <td><%=row.get("assetName")%></td>
                        <td><%=row.get("brand")%></td>
                        <td>
                            <span class="slds-badge">
                                <%=row.get("location")%>
                            </span>
                        </td>
                        <td><%=row.get("assignedDate")%></td>
                        <td><%=row.get("assignedBy")%></td>
                    </tr>
                    <%
                        }
                    } else {
                    %>
                    <tr>
                        <td colspan="7" style="text-align: center; color: #747474; padding: 2rem;">
                            No records found.
                        </td>
                    </tr>
                    <%
                    }
                    %>
                </tbody>
            </table>
        </div>

        <div class="slds-card__footer">
            Total Issued Assets: <strong><%=assetList == null ? 0 : assetList.size()%></strong>
        </div>

    </div>

</div>

</body>
</html>