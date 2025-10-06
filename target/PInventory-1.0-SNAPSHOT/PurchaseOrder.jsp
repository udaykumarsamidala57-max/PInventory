<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.bean.POItems" %>

<html>
<head>
    <title>Create Purchase Order</title>
    
    <style>
        body {
            font-family: "Segoe UI", Arial, sans-serif;
            background: #f5f7fa;
            margin: 20px;
            color: #333;
        }
        h2 {
            text-align: center;
            color: #2c3e50;
            margin-bottom: 20px;
        }
        form {
            background: #fff;
            padding: 20px 30px;
            border-radius: 12px;
            max-width: 1100px;
            margin: auto;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 25px;
        }
        table th, table td {
            border: 1px solid #ddd;
            padding: 10px 12px;
            text-align: center;
        }
        table th {
            background: #2c3e50;
            color: #fff;
            font-weight: 600;
        }
        table tr:nth-child(even) {
            background: #f9f9f9;
        }
        table tr:hover {
            background: #f1f7ff;
        }
        input[type="text"], input[type="number"], input[type="date"], textarea, select {
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
        input[type="submit"] {
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
        input[type="submit"]:hover {
            background: #2c80b4;
        }
    </style>
</head>
<body>
<h2>Create Purchase Order</h2>

<%
List<POItems> indentList = (List<POItems>) request.getAttribute("indentList");
Map<String,String[]> vendorMap = (Map<String,String[]>) request.getAttribute("vendorMap");
String nextPONumber = (String) request.getAttribute("nextPONumber");
%>

<form method="post" action="<%=request.getContextPath()%>/PurchaseOrderServlet">
    <!-- Indent Items -->
    <table>
        <tr>
            <th>Sl No</th><th>Indent No</th><th>Item</th><th>Qty</th>
            <th>Rate</th><th>Discount %</th><th>GST %</th>
        </tr>
        <%
        int sl = 1;
        if(indentList != null){
            for(POItems item: indentList){
        %>
        <tr>
            <td><input type="text" name="slNo" value="<%=sl++%>" readonly></td>
            <td><input type="text" name="indentNo" value="<%=item.getIndentNo()%>" readonly></td>
            <input type="hidden" name="itemId" value="<%=item.getItemId()%>">
            <td><input type="text" name="itemName" value="<%=item.getItemName()%>" readonly></td>
            <td><input type="number" step="any" name="qty" value="<%=item.getQty()%>" readonly></td>

            <td><input type="number" step="0.01" name="rate"></td>
            <td><input type="number" step="0.01" name="discPercent"></td>
            <td><input type="number" step="0.01" name="gstPercent"></td>
        </tr>
        <%
            }
        }
        %>
    </table>

    <!-- Vendor & PO Details -->
    <table class="form-section">
        <tr>
            <td><strong>Vendor:</strong></td>
            <td>
                <select id="vendorDropdown" name="vendorName" onchange="loadVendorDetails()">
                    <option value="">-- Select Vendor --</option>
                    <% for(String v: vendorMap.keySet()){ %>
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
            <td><strong>Quotation No:</strong></td>
            <td><input type="text" name="quotationNo"></td>
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
            <td><strong>Billing Address:</strong></td>
            <td><input type="text" name="billingAddress"></td>
        </tr>
        <tr>
            <td><strong>Terms:</strong></td>
            <td><textarea name="termsConditions"></textarea></td>
        </tr>
        <tr>
            <td><strong>General Conditions:</strong></td>
            <td><textarea name="generalConditions"></textarea></td>
        </tr>
        <tr>
            <td colspan="2" style="text-align:center;">
                <input type="submit" value="Submit PO">
            </td>
        </tr>
    </table>
</form>

<script type="text/javascript">
var vendorData = {
<%
int count=0,size=vendorMap.size();
for(Map.Entry<String,String[]> e: vendorMap.entrySet()){
String name=e.getKey().replace("\"","\\\"");
String gst=e.getValue()[0].replace("\"","\\\"");
String addr=e.getValue()[1].replace("\"","\\\"");
%>
"<%=name%>":["<%=gst%>","<%=addr%>"]<%= (++count<size)?",":""%>
<% } %>
};

function loadVendorDetails(){
    var selected = document.getElementById("vendorDropdown").value;
    if(vendorData[selected]){
        document.getElementById("vendorGSTIN").value = vendorData[selected][0];
        document.getElementById("vendorAddress").value = vendorData[selected][1];
    } else {
        document.getElementById("vendorGSTIN").value = "";
        document.getElementById("vendorAddress").value = "";
    }
}
</script>
</body>
</html>
