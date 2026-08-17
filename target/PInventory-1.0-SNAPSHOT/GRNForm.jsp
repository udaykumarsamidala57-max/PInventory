<%@ page import="com.bean.GRNItem, java.util.*" %>
<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
    String poNumber = (String) request.getAttribute("poNumber");
    String vendorName = (String) request.getAttribute("vendorName");
    List<GRNItem> items = (List<GRNItem>) request.getAttribute("items");
    String message = (String) request.getAttribute("message");
    String error   = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create GRN | Goods Received Note</title>

    <!-- Google Fonts & FontAwesome -->
    <link href="https://fonts.googleapis.com/css2?family=Salesforce+Sans,Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="CSS/Form.css">

    <style>
        :root {
            --slds-brand: #0176D3;
            --slds-brand-hover: #014486;
            --slds-bg: #F3F5F7;
            --slds-card-bg: #FFFFFF;
            --slds-text-main: #181B25;
            --slds-text-muted: #514F4D;
            --slds-border: #DDDBDA;
            --slds-border-radius: 6px;
            --slds-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
            --slds-success: #2E844A;
            --slds-error: #EA001E;
        }

        body {
            font-family: 'Poppins', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background-color: var(--slds-bg);
            color: var(--slds-text-main);
            margin: 0;
            padding-bottom: 40px;
        }

        .main-container {
            max-width: 1200px;
            margin: 24px auto;
            padding: 0 16px;
        }

        /* Salesforce Page Header / Banner */
        .page-header {
            background: var(--slds-card-bg);
            border: 1px solid var(--slds-border);
            border-radius: var(--slds-border-radius);
            padding: 16px 24px;
            margin-bottom: 20px;
            box-shadow: var(--slds-shadow);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .page-header-title {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .page-header-icon {
            background-color: #0070D2;
            color: #fff;
            width: 40px;
            height: 40px;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.2rem;
        }

        .page-header h1 {
            font-size: 1.25rem;
            font-weight: 600;
            margin: 0;
            color: var(--slds-text-main);
        }

        /* Alert Toast Banners */
        .alert-toast {
            padding: 12px 16px;
            border-radius: var(--slds-border-radius);
            font-size: 0.9rem;
            font-weight: 500;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .alert-success {
            background-color: #E6F4EA;
            color: var(--slds-success);
            border: 1px solid #B7E1CD;
        }
        .alert-error {
            background-color: #FCE8E6;
            color: var(--slds-error);
            border: 1px solid #F5C6CB;
        }

        /* Card Panels */
        .slds-card {
            background: var(--slds-card-bg);
            border: 1px solid var(--slds-border);
            border-radius: var(--slds-border-radius);
            box-shadow: var(--slds-shadow);
            padding: 24px;
            margin-bottom: 24px;
        }

        /* Simplified Search Bar */
        .search-card {
            padding: 14px 18px;
        }

        .simple-search-form {
            display: flex;
            align-items: center;
            gap: 12px;
            max-width: 600px;
        }

        .search-input-wrapper {
            position: relative;
            flex: 1;
            display: flex;
            align-items: center;
        }

        .search-input-wrapper .search-icon {
            position: absolute;
            left: 12px;
            color: var(--slds-text-muted);
            font-size: 0.9rem;
            pointer-events: none;
        }

        .search-input-wrapper input {
            padding-left: 36px;
        }

        .slds-card-title {
            font-size: 1.05rem;
            font-weight: 600;
            color: var(--slds-text-main);
            margin-top: 0;
            margin-bottom: 18px;
            padding-bottom: 8px;
            border-bottom: 1px solid #EAEAEA;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        /* Form Layouts */
        .form-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 16px;
            margin-bottom: 20px;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .form-group label {
            font-size: 0.8rem;
            font-weight: 600;
            color: var(--slds-text-muted);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .form-control {
            height: 38px;
            padding: 6px 12px;
            font-size: 0.875rem;
            border: 1px solid var(--slds-border);
            border-radius: 4px;
            background-color: #FAFAFA;
            color: var(--slds-text-main);
            transition: all 0.2s ease;
            box-sizing: border-box;
        }

        .form-control:focus {
            outline: none;
            border-color: var(--slds-brand);
            background-color: #FFFFFF;
            box-shadow: 0 0 0 3px rgba(1, 118, 211, 0.15);
        }

        /* Buttons */
        .btn-slds {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            height: 38px;
            padding: 0 18px;
            font-size: 0.875rem;
            font-weight: 600;
            border-radius: 4px;
            border: 1px solid transparent;
            cursor: pointer;
            transition: background-color 0.2s ease, border-color 0.2s ease;
            text-decoration: none;
            white-space: nowrap;
        }

        .btn-brand {
            background-color: var(--slds-brand);
            color: #FFFFFF;
        }
        .btn-brand:hover {
            background-color: var(--slds-brand-hover);
        }

        .btn-success {
            background-color: var(--slds-success);
            color: #FFFFFF;
        }
        .btn-success:hover {
            background-color: #236839;
        }

        /* Data Tables */
        .table-responsive {
            overflow-x: auto;
            border: 1px solid var(--slds-border);
            border-radius: var(--slds-border-radius);
            margin-top: 16px;
        }

        .slds-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.85rem;
            text-align: left;
        }

        .slds-table th {
            background-color: #F8F9FA;
            color: var(--slds-text-muted);
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.75rem;
            letter-spacing: 0.5px;
            padding: 12px 10px;
            border-bottom: 1px solid var(--slds-border);
            white-space: nowrap;
        }

        .slds-table td {
            padding: 8px 10px;
            border-bottom: 1px solid #EAEAEA;
            vertical-align: middle;
            background-color: #FFFFFF;
        }

        .slds-table tr:hover td {
            background-color: #F4F6F9;
        }

        .slds-table input[type="number"],
        .slds-table input[type="text"] {
            width: 100%;
            height: 32px;
            padding: 4px 8px;
            font-size: 0.85rem;
            border: 1px solid var(--slds-border);
            border-radius: 4px;
            box-sizing: border-box;
        }

        .slds-table input:focus {
            border-color: var(--slds-brand);
            outline: none;
        }

        .badge {
            display: inline-block;
            padding: 3px 8px;
            font-size: 0.75rem;
            font-weight: 600;
            border-radius: 12px;
            background-color: #E0E8F5;
            color: var(--slds-brand-hover);
        }

        .action-bar {
            margin-top: 20px;
            display: flex;
            justify-content: flex-end;
        }
    </style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-container">

    <!-- Page Title Header -->
    <div class="page-header">
        <div class="page-header-title">
            <div class="page-header-icon">
                <i class="fa-solid fa-boxes-packing"></i>
            </div>
            <div>
                <h1>Goods Received Note (GRN)</h1>
            </div>
        </div>
    </div>

    <!-- Alert Messaging -->
    <% if(message != null) { %>
        <div class="alert-toast alert-success">
            <i class="fa-solid fa-circle-check"></i>
            <span><%= message %></span>
        </div>
    <% } %>

    <% if(error != null) { %>
        <div class="alert-toast alert-error">
            <i class="fa-solid fa-circle-exclamation"></i>
            <span><%= error %></span>
        </div>
    <% } %>

    <!-- Simplified Inline PO Search -->
    <div class="slds-card search-card">
        <form method="get" action="GRNServlet" class="simple-search-form">
            <div class="search-input-wrapper">
                <i class="fa-solid fa-magnifying-glass search-icon"></i>
                <input name="po_number" class="form-control" placeholder="Search PO Number..." required value="<%= poNumber != null ? poNumber : "" %>">
            </div>
            <button type="submit" class="btn-slds btn-brand">Fetch PO</button>
        </form>
    </div>

    <% if(poNumber != null) { %>
        <!-- Main Form Entry -->
        <form method="post" action="GRNServlet">
            <input type="hidden" name="po_number" value="<%= poNumber %>">

            <div class="slds-card">
                <div class="slds-card-title">
                    <span>
                        <i class="fa-solid fa-file-invoice" style="margin-right: 8px;"></i>
                        GRN Information
                    </span>
                    <span class="badge">PO: <%= poNumber %></span>
                </div>

                <!-- Invoice Meta Grid -->
                <div class="form-grid">
                    <div class="form-group">
                        <label>Vendor Name</label>
                        <input class="form-control" value="<%= vendorName != null ? vendorName : "N/A" %>" readonly style="background-color: #EFEFEF; cursor: not-allowed;">
                    </div>
                    <div class="form-group">
                        <label>Invoice Number <span style="color:red;">*</span></label>
                        <input name="invoice_no" class="form-control" placeholder="e.g. INV-9821" required>
                    </div>
                    <div class="form-group">
                        <label>Invoice Date <span style="color:red;">*</span></label>
                        <input type="date" name="invoice_date" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label>Received By <span style="color:red;">*</span></label>
                        <input name="received_by" class="form-control" placeholder="Receiver name" required>
                    </div>
                    <div class="form-group">
                        <label>GRN Date <span style="color:red;">*</span></label>
                        <input type="date" name="grn_date" class="form-control" value="<%= java.time.LocalDate.now() %>" required>
                    </div>
                </div>

                <!-- Line Items Table Section -->
                <div class="slds-card-title" style="margin-top: 28px; margin-bottom: 12px;">
                    <span><i class="fa-solid fa-list-check" style="margin-right: 8px;"></i>Line Items</span>
                </div>

                <div class="table-responsive">
                    <table class="slds-table">
                        <thead>
                            <tr>
                                <th style="width: 50px;">Sl No</th>
                                <th>Description</th>
                                <th style="width: 100px;">Ordered</th>
                                <th style="width: 130px;">Prev Received</th>
                                <th style="width: 130px;">Qty Received</th>
                                <th style="width: 130px;">Qty Accepted</th>
                                <th style="width: 130px;">Qty Rejected</th>
                                <th>Remarks</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            int i = 0;
                            if (items != null) {
                                for(GRNItem item : items) {
                        %>
                            <tr>
                                <td style="text-align: center; font-weight: 600;"><%= i+1 %></td>
                                <td>
                                    <strong><%= item.getDescription() %></strong>
                                </td>
                                <td><%= item.getOrderedQty() %></td>
                                <td><%= item.getAlreadyReceived() %></td>
                                <td>
                                    <input type="number" name="qty_received_<%=i%>" required min="0" step="0.01" value="0.0" placeholder="Qty Received">
                                </td>
                                <td>
                                    <input type="number" name="qty_accepted_<%=i%>" required min="0" step="0.01" value="0.0" placeholder="Qty Accepted">
                                </td>
                                <td>
                                    <input type="number" name="qty_rejected_<%=i%>" required min="0" step="0.01" value="0.0" placeholder="Qty Rejected">
                                </td>
                                <td>
                                    <input type="text" name="remarks_<%=i%>" value="NA">
                                </td>

                                <!-- Hidden Metadata per Row -->
                                <input type="hidden" name="description_<%=i%>" value="<%= item.getDescription() %>">
                                <input type="hidden" name="po_item_id<%=i%>" value="<%= item.getPoItemId() %>">
                                <input type="hidden" name="item_id<%=i%>" value="<%= item.getItemId() %>">
                            </tr>
                        <%
                                    i++;
                                }
                            }
                        %>
                        </tbody>
                    </table>
                </div>

                <input type="hidden" name="totalItems" value="<%= i %>">

                <div class="action-bar">
                    <button type="submit" class="btn-slds btn-success">
                        <i class="fa-solid fa-floppy-disk"></i> Save GRN Record
                    </button>
                </div>
            </div>
        </form>
    <% } %>

</div>

</body>
</html>