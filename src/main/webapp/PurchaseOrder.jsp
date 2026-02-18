<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.bean.POItems" %>
<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
%>
<html>
<head>
    <title>Create Purchase Order</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: "Segoe UI", Arial, sans-serif;
            background: linear-gradient(135deg, #dbe8ff 0%, #e6d7ff 25%, #ffd6e0 50%, #d9faff 100%);
            margin: 0;
            padding: 0;
            color: #333;
        }

        h2 {
            text-align: center;
            color: #2c3e50;
            margin: 20px 0;
            font-size: 1.8em;
        }

        form {
            background: #fff;
            padding: 20px 30px;
            border-radius: 12px;
            max-width: 1100px;
            margin: 10px auto 30px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 25px;
        }

        table td, table th {
            border: 1px solid #ddd;
            padding: 10px 12px;
            text-align: center;
            vertical-align: middle;
        }

        thead {
            background:  #0f2a4d; 
        }

        th {
            color: #fff;
            font-weight: 600;
            text-align: center;
            padding: 10px 8px;
        }

        table tr:nth-child(even) {
            background: #f9f9f9;
        }

        table tr:hover {
            background: #f1f7ff;
        }

        input[type="text"],
        input[type="number"],
        input[type="date"],
        textarea,
        select {
            width: 95%;
            padding: 6px 8px;
            border: 1px solid #ccc;
            border-radius: 6px;
            font-size: 14px;
            box-sizing: border-box;
        }

        textarea {
            resize: vertical;
            min-height: 60px;
        }

        .form-section {
            margin-bottom: 15px;
        }

        .form-section td {
            padding: 8px 10px;
        }

        input[type="submit"], .submit-btn {
            background: #3498db;
            color: white;
            border: none;
            padding: 10px 18px;
            font-size: 15px;
            font-weight: bold;
            border-radius: 8px;
            cursor: pointer;
            transition: 0.3s;
        }

        input[type="submit"]:hover, .submit-btn:hover {
            background: #2c80b4;
        }

        /* Calculation Summary Styling */
        .summary-container {
            margin-top: 20px;
            background: #fcfcfc;
            padding: 15px;
            border-radius: 8px;
            border: 1px solid #eee;
            width: 350px;
            margin-left: auto;
        }
        .summary-line {
            display: flex;
            justify-content: space-between;
            padding: 5px 0;
            font-size: 15px;
        }
        .grand-total-line {
            border-top: 2px solid #333;
            margin-top: 10px;
            padding-top: 10px;
            font-weight: bold;
            font-size: 1.1em;
            color: #e67e22;
        }

        @media (max-width: 1024px) {
            form {
                padding: 15px 20px;
                width: 95%;
            }
            h2 {
                font-size: 1.6em;
            }
        }

        @media (max-width: 768px) {
            form {
                padding: 15px;
                width: 95%;
                margin: 10px auto;
            }

            h2 {
                font-size: 1.4em;
            }

            table, thead, tbody, th, td, tr {
                display: block;
            }

            thead tr {
                display: none;
            }

            table tr {
                margin-bottom: 15px;
                background: #fff;
                border-radius: 10px;
                box-shadow: 0 2px 6px rgba(0,0,0,0.1);
                overflow: hidden;
            }

            table td {
                border: none;
                border-bottom: 1px solid #eee;
                text-align: left;
                padding: 10px;
                display: flex;
                justify-content: space-between;
                align-items: center;
                font-size: 14px;
            }

            table td:before {
                content: attr(data-label);
                flex: 1;
                font-weight: 600;
                color: #333;
                text-transform: capitalize;
            }

            input[type="text"], input[type="number"], input[type="date"], textarea, select {
                width: 100%;
                font-size: 13px;
            }

            input[type="submit"] {
                width: 100%;
                font-size: 16px;
                padding: 12px;
            }
        }
    </style>
</head>
<body>
<h2>Create Purchase Order</h2>

<%
List<POItems> indentList = (List<POItems>) request.getAttribute("indentList");
Map<String,String[]> vendorMap = (Map<String,String[]>) request.getAttribute("vendorMap");
String nextPONumber = (String) request.getAttribute("nextPONumber");
if(vendorMap == null) vendorMap = new LinkedHashMap<>();
%>

<form method="post" action="<%=request.getContextPath()%>/PurchaseOrderServlet">
    <table class="form-section">
        <tr>
            <td><strong>Vendor:</strong></td>
            <td>
                <select id="vendorDropdown" name="vendorName" onchange="loadVendorDetails()" required>
                    <option value="">-- Select Vendor --</option>
                    <% for(String v : vendorMap.keySet()){ %>
                    <option value="<%=v%>"><%=v%></option>
                    <% } %>
                </select>
            </td>
        </tr>
        <tr>
            <td><strong>Vendor GSTIN:</strong></td>
            <td><input type="text" name="vendorGSTIN" id="vendorGSTIN" readonly></td>
        </tr>
        <tr>
            <td><strong>Vendor Address:</strong></td>
            <td><input type="text" name="vendorAddress" id="vendorAddress" readonly></td>
        </tr>
        <tr>
            <td><strong>PO Number:</strong></td>
            <td><input type="text" name="poNumber" value="<%=nextPONumber%>" readonly></td>
        </tr>
        <tr>
            <td><strong>PO Date:</strong></td>
            <td><input type="date" name="poDate" value="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>"></td>
        </tr>
        <tr>
            <td><strong>Service Charge:</strong></td>
            <td><input type="number" step="0.01" id="serviceCharge" name="serviceCharge" value="0" oninput="calculateTotals()"></td>
        </tr>
        <tr>
            <td><strong>Service GST %:</strong></td>
            <td><input type="number" step="0.01" id="serviceGst" name="serviceGst" value="18" oninput="calculateTotals()"></td>
        </tr>
    </table>

    <table id="poItemsTable">
        <thead>
            <tr>
                <th>Sl No</th>
                <th>Indent No</th>
                <th>Item</th>
                <th>Qty</th>
                <th>UOM</th>
                <th>Rate</th>
                <th>Discount %</th>
                <th>GST %</th>
            </tr>
        </thead>
        <tbody>
        <%
        int sl = 1;
        if(indentList != null && !indentList.isEmpty()){
            for(POItems item : indentList){
        %>
        <tr class="item-row">
            <td><%=sl++%></td>
            <td><%=item.getIndentNo()%><input type="hidden" name="indentId" value="<%=item.getId()%>"></td>
            <td><input type="text" name="itemName" value="<%=item.getItemName()%>" readonly></td>
            <td><input type="number" step="0.01" name="qty" value="<%=item.getQty()%>" oninput="calculateTotals()"></td>
            <td><input type="text" name="UOM" value="<%=item.getUOM()%>" readonly></td>
            <td><input type="number" step="0.01" name="rate" value="0" oninput="calculateTotals()" required></td>
            <td><input type="number" step="0.01" name="discPercent" value="0" oninput="calculateTotals()"></td>
            <td><input type="number" step="0.01" name="gstPercent" value="18" oninput="calculateTotals()"></td>
            <input type="hidden" name="itemId" value="<%=item.getItemId()%>">
        </tr>
        <%
            }
        } else {
        %>
        <tr><td colspan="8" style="color:red;">No Items Found</td></tr>
        <% } %>
        </tbody>
    </table>

    <div class="summary-container">
        <div class="summary-line">
            <span>Total Price (Base):</span>
            <span id="totalPrice">0.00</span>
        </div>
        <div class="summary-line">
            <span>Total GST Amount:</span>
            <span id="totalGst">0.00</span>
        </div>
        <div class="summary-line">
            <span>Service Total (With GST):</span>
            <span id="totalService">0.00</span>
        </div>
        <div class="summary-line grand-total-line">
            <span>Grand Total:</span>
            <span id="grandTotal">0.00</span>
        </div>
    </div>

    <div style="text-align:center; margin-top:20px;">
        <input type="submit" class="submit-btn" value="Submit Purchase Order">
    </div>
</form>

<script type="text/javascript">

var vendorData = {
<%
int count = 0;
int size = vendorMap.size();
for (Map.Entry<String, String[]> e : vendorMap.entrySet()) {
    String name = e.getKey();
    String[] details = e.getValue();
    
    // 1. Handle Nulls
    String gst = (details[0] != null) ? details[0] : "";
    String addr = (details[1] != null) ? details[1] : "";

    // 2. Clean the data for JavaScript
    name = name.replace("'", "\\'").replaceAll("[\\n\\r]", " ");
    gst = gst.replace("'", "\\'").replaceAll("[\\n\\r]", " ");
    addr = addr.replace("'", "\\'").replaceAll("[\\n\\r]", " ");
%>
    '<%=name%>': ['<%=gst%>', '<%=addr%>']<%= (++count < size) ? "," : "" %>
<% } %>
};

function loadVendorDetails() {
    var selected = document.getElementById("vendorDropdown").value;
    if (vendorData[selected]) {
        document.getElementById("vendorGSTIN").value = vendorData[selected][0];
        document.getElementById("vendorAddress").value = vendorData[selected][1];
    } else {
        document.getElementById("vendorGSTIN").value = "";
        document.getElementById("vendorAddress").value = "";
    }
}

function calculateTotals() {
    let totalPriceBase = 0;
    let totalGstAmt = 0;

    // Calculate Items
    const rows = document.querySelectorAll('.item-row');
    rows.forEach(row => {
        const qty = parseFloat(row.querySelector('[name="qty"]').value) || 0;
        const rate = parseFloat(row.querySelector('[name="rate"]').value) || 0;
        const discP = parseFloat(row.querySelector('[name="discPercent"]').value) || 0;
        const gstP = parseFloat(row.querySelector('[name="gstPercent"]').value) || 0;

        const baseValue = qty * rate;
        const discountedValue = baseValue - (baseValue * (discP / 100));
        const gstValue = discountedValue * (gstP / 100);

        totalPriceBase += discountedValue;
        totalGstAmt += gstValue;
    });

    // Calculate Service Charge
    const svcCharge = parseFloat(document.getElementById('serviceCharge').value) || 0;
    const svcGstP = parseFloat(document.getElementById('serviceGst').value) || 0;
    const svcGstAmt = svcCharge * (svcGstP / 100);
    const svcTotalWithGst = svcCharge + svcGstAmt;

    const finalGrandTotal = totalPriceBase + totalGstAmt + svcTotalWithGst;

    // Update Display
    document.getElementById('totalPrice').innerText = totalPriceBase.toFixed(2);
    document.getElementById('totalGst').innerText = (totalGstAmt + svcGstAmt).toFixed(2);
    document.getElementById('totalService').innerText = svcTotalWithGst.toFixed(2);
    document.getElementById('grandTotal').innerText = finalGrandTotal.toFixed(2);
}

// Initial calculation on load
window.onload = calculateTotals;

</script>
</body>
</html>