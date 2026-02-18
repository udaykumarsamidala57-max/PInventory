<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.bean.PO, com.bean.POItems, java.util.*" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String user = (String) sess.getAttribute("username");
    String role = (String) sess.getAttribute("role");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SRS System - Purchase Orders</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #eef3f8;
            margin: 0;
            padding: 0;
        }

        h2 {
            margin: 15px;
            color: #2c3e50;
            text-align: center;
        }

       
        table.main-table {
            width: 98%;
            margin: 0 auto 40px auto;
            border-collapse: collapse;
            border: 2px solid #b0c4de;
            background: #fff;
            box-shadow: 0 3px 10px rgba(0,0,0,0.1);
            border-radius: 6px;
        }
        table.main-table thead {
            background: #0f2a4d;
            color: white;
            font-size: 16px;
        }

        table.main-table td, table.main-table th {
            border: 1px solid #dcdcdc;
            padding: 8px;
            text-align: center;
            font-size: 15px;
        }

        table.main-table tr:nth-child(even) td { background-color: #f2f6fa; }
        table.main-table tr:hover td { background-color: #eaf1fc; }

     
        .items-block {
            width: 94%;
            margin: 12px auto;
            padding: 12px;
            background: linear-gradient(180deg, #fdfdfd 0%, #f5f9ff 100%);
            border-left: 5px solid #3498db;
            border-right: 1px solid #cce3ff;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.07);
            display: none;
            animation: slideDown 0.4s ease;
        }

        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .items-block h4 {
            margin: 0;
            color: #2c3e50;
            font-size: 15px;
            text-align: left;
            border-bottom: 1px solid #b0c4de;
            padding-bottom: 6px;
        }

      
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
            font-size: 13px;
        }

        .items-table th {
            background: linear-gradient(135deg, #dfe9f3, #c8d9eb);
            color: #333;
            padding: 6px;
            border: 1px solid #a9bddb;
        }

        .items-table td {
            border: 1px solid #ccd9ea;
            padding: 6px;
            text-align: center;
        }

        .items-table tr:nth-child(odd) { background: #f8fbff; }
        .items-table tr:nth-child(even) { background: #eef5ff; }
        .items-table tr:hover { background: #e4efff; }

      
        .action-btn {
            margin: 3px 0;
            padding: 6px 10px;
            border: none;
            border-radius: 5px;
            font-weight: bold;
            cursor: pointer;
            font-size: 12px;
            transition: all 0.25s ease;
        }

        .delete-btn { background: #e74c3c; color: white; }
        .delete-btn:hover { background: #c0392b; }

        .approve-btn { background: #28a745; color: white; }
        .approve-btn:hover { background: #1e7e34; }

        .print-btn { background: #17a2b8; color: white; }
        .print-btn:hover { background: #138496; }

        .grn-btn { background: #007bff; color: white; }
        .grn-btn:hover { background: #0056b3; }

        .expand-btn { background: #6c757d; color: white; }
        .expand-btn:hover { background: #5a6268; }

        .disabled {
            background: #ccc !important;
            color: #666 !important;
            cursor: not-allowed;
        }

        .no-data {
            text-align: center;
            color: red;
            padding: 12px;
            font-weight: bold;
            background: #fff5f5;
        }
    </style>

    <script>
        function toggleItems(id) {
            const block = document.getElementById("items-" + id);
            const btn = document.getElementById("btn-" + id);
            if (block.style.display === "none" || block.style.display === "") {
                block.style.display = "block";
                btn.value = "Hide Items";
            } else {
                block.style.display = "none";
                btn.value = "Show Items";
            }
        }
    </script>
</head>

<body>
<jsp:include page="header.jsp" />

<div class="main-content">
    <div class="main-section">
        <h2>Purchase Orders</h2>

        <table class="main-table">
            <thead>
                <tr>
                    <th>PO Number</th>
                    <th>PO Date</th>
                    <th>Vendor Name</th>
                    <th>Total Amount</th>
                    <th>Approval Status</th>
                    <th>Action</th>
                    <th>Print</th>
                    <th>GRN</th>
                    <th>Items</th>
                </tr>
            </thead>
            <tbody>
            <%
                List<PO> list = (List<PO>) request.getAttribute("poList");
                if (list != null && !list.isEmpty()) {
                    for (PO po : list) {
                        String approval = po.getApproval();
                        String poId = po.getPoNumber().replaceAll("\\s+", "_");
            %>
                <tr>
                    <td><%= po.getPoNumber() %></td>
                    <td><%= po.getPoDate() %></td>
                    <td><%= po.getVendorName() %></td>
                    <td><%= po.getTotalAmount() %></td>
                    <td><%= approval %></td>

                    <td>
                       
                        <form action="POListServlet" method="get" style="margin:0;">
                            <input type="hidden" name="delete_id" value="<%= po.getPoNumber() %>">
                            <input type="submit" value="Delete"
                                class="action-btn <%= !"Approved".equalsIgnoreCase(approval) ? "delete-btn" : "disabled" %>"
                                <%= !"Approved".equalsIgnoreCase(approval) ? "" : "disabled" %>
                                onclick="return confirm('Are you sure you want to delete this record?');" />
                        </form>

                        
                        <% if ("Global".equalsIgnoreCase(role)) { %>
                        <form action="POListServlet" method="get" style="margin:0;">
                            <input type="hidden" name="Approve_id" value="<%= po.getPoNumber() %>">
                            <input type="submit" value="Approve"
                                class="action-btn <%= !"Approved".equalsIgnoreCase(approval) ? "approve-btn" : "disabled" %>"
                                <%= (!"Approved".equalsIgnoreCase(approval)) ? "" : "disabled" %>
                                onclick="return confirm('Are you sure you want to approve this record?');">
                        </form>
                        <% } %>
                    </td>

                    
                    <td>
                        <form action="PrintPO.jsp" method="get" target="_blank" style="margin:0;">
                            <input type="hidden" name="poNumber" value="<%= po.getPoNumber() %>">
                            <input type="submit" value="View / Print" class="action-btn print-btn" />
                        </form>
                    </td>

                   
                    <td>
                        <form action="GRNServlet" method="get" style="margin:0;">
                            <input type="hidden" name="po_number" value="<%= po.getPoNumber() %>">
                            <input type="submit" value="GRN"
                                class="action-btn <%= "Approved".equalsIgnoreCase(approval) ? "grn-btn" : "disabled" %>"
                                <%= "Approved".equalsIgnoreCase(approval) ? "" : "disabled" %> />
                        </form>
                    </td>

                   
                    <td>
                        <input type="button" id="btn-<%= poId %>" value="Show Items"
                            class="action-btn expand-btn" onclick="toggleItems('<%= poId %>')">
                    </td>
                </tr>

                
                <tr>
                    <td colspan="9" style="padding:0;">
                        <div class="items-block" id="items-<%= poId %>">
                            <h4>Items for PO: <%= po.getPoNumber() %></h4>
                            <%
                                if (po.getItems() != null && !po.getItems().isEmpty()) {
                            %>
                            <table class="items-table">
                                <tr>
                                    <th>Item ID</th>
                                    <th>Description</th>
                                    <th>PO Quantity</th>
                                    <th>Received Qty</th>
                                    <th>Balance to Receive</th>
                                    <th>Rate</th>
                                    <th>Discount %</th>
                                    <th>GST %</th>
                                </tr>
                                <% for (POItems item : po.getItems()) { %>
                                <tr>
                                    <td><%= item.getItemId() %></td>
                                    <td><%= item.getItemName() %></td>
                                    <td><%= item.getQty() %></td>
                                    <td><%= item.getReceivedQty() %></td>
                                    <td><%= item.gettobeReceivedQty() %></td>
                                    <td><%= item.getRate() %></td>
                                    <td><%= item.getDiscountPercent() %></td>
                                    <td><%= item.getGstPercent() %></td>
                                </tr>
                                <% } %>
                            </table>
                            <% } else { %>
                            <p class="no-data">No items found for this PO.</p>
                            <% } %>
                        </div>
                    </td>
                </tr>
            <% 
                    }
                } else { 
            %>
                <tr>
                    <td colspan="9" class="no-data">No Purchase Orders Found</td>
                </tr>
            <% } %>
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="Footer.jsp" />
</body>
</html>
