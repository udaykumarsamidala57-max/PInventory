<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page import="javax.servlet.http.HttpSession" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String grnNo = request.getParameter("grnNo");
%>

<!DOCTYPE html>
<html>
<head>
<title>Goods Receipt Note - Sandur Residential School</title>

<style>
body{
    font-family: "Segoe UI", Tahoma, sans-serif;
    margin: 30px 60px;
    background: #f9fbfd;
    color: #222;
}
header{
    text-align:center;
    border-bottom:3px solid #003366;
    padding-bottom:10px;
}
header img{ height:90px; }
header h6{ margin:4px 0; color:#444; }

h3{
    text-align:center;
    color:#003366;
    margin:15px 0;
    text-transform:uppercase;
    letter-spacing:1px;
}

.info-table{
    width:100%;
    border-collapse:collapse;
    margin-top:15px;
    background:#fff;
}
.info-table td{
    border:1px solid #ccc;
    padding:8px 10px;
    font-size:14px;
}

.items-table{
    width:100%;
    border-collapse:collapse;
    margin-top:20px;
    background:#fff;
    box-shadow:0 2px 6px rgba(0,0,0,.08);
}
.items-table th,
.items-table td{
    border:1px solid #ccc;
    padding:8px;
    font-size:14px;
}
.items-table thead{
    background:linear-gradient(90deg,#003366,#00509e);
    color:#fff;
    text-align:center;
}
.items-table td{
    vertical-align:middle;
}
.text-right{ text-align:right; }
.text-center{ text-align:center; }

.signature{
    margin-top:80px;
    text-align:right;
}
.stamp{
    display:inline-block;
    padding:6px 16px;
    border:2px solid #28a745;
    color:#28a745;
    font-weight:bold;
    font-size:18px;
    transform:rotate(-6deg);
    margin-top:10px;
}

.print-btn{
    display:block;
    margin:40px auto;
    padding:10px 30px;
    background:#003366;
    color:#fff;
    border:none;
    border-radius:6px;
    cursor:pointer;
    font-size:15px;
}
@media print{
    .print-btn{ display:none; }
}
</style>
</head>

<body>

<%
if (grnNo != null && !grnNo.trim().isEmpty()) {
    try (Connection con = DBUtil.getConnection()) {

        // Fetch GRN details with PO number
        PreparedStatement pst = con.prepareStatement(
            "SELECT gm.*, pi.po_no " +
            "FROM grn_master gm " +
            "JOIN po_items pi ON gm.po_id = pi.PO_id " +
            "WHERE gm.grn_no = ? " +
            "LIMIT 1"
        );
        pst.setString(1, grnNo);
        ResultSet rs = pst.executeQuery();

        if (rs.next()) {
%>

<header>
    <img src="Header.png">
    <h6>Website: www.sandurschool.edu.in | Email: srsadmin@sandurschool.com | Ph: 08395-260246</h6>
</header>

<h3>Goods Receipt Note (GRN)</h3>

<table class="info-table">
<tr>
    <td colspan="2"><b>PO No:</b> <%= rs.getString("po_no") %></td>
   </tr>
<tr>
   
    <td><b>GRN No:</b> <%= rs.getString("grn_no") %></td>
    <td><b>GRN Date:</b> <%= rs.getDate("grn_date") %></td>
</tr>
<tr>
    <td><b>Vendor Name:</b> <%= rs.getString("vendor_name") %></td>
    <td><b>GSTIN:</b> <%= rs.getString("vendor_gstin") != null ? rs.getString("vendor_gstin") : "-" %></td>
</tr>
<tr>
    <td colspan="2"><b>Vendor Address:</b> <%= rs.getString("vendor_address") %></td>
</tr>
<tr>
    <td><b>Invoice No:</b> <%= rs.getString("invoice_no") %></td>
    <td><b>Invoice Date:</b> <%= rs.getDate("invoice_date") %></td>
</tr>
<tr>
    <td><b>Received By:</b> <%= rs.getString("received_by") %></td>
    <td><b>Remarks:</b> <%= rs.getString("remarks") != null ? rs.getString("remarks") : "-" %></td>
</tr>
</table>

<%
      
        PreparedStatement pstItems = con.prepareStatement(
            "SELECT * FROM grn_items WHERE grn_id=?"
        );
        pstItems.setInt(1, rs.getInt("grn_id"));
        ResultSet ri = pstItems.executeQuery();
%>

<table class="items-table">
<thead>
<tr>
    <th>Sl.No</th>
    <th>Item Description</th>
    <th>Qty Received</th>
    <th>Qty Accepted</th>
    <th>Qty Rejected</th>
    <th>Remarks</th>
</tr>
</thead>
<tbody>
<%
        int sl = 1;
        while (ri.next()) {
%>
<tr>
    <td class="text-center"><%= sl++ %></td>
    <td><%= ri.getString("item_description") %></td>
    <td class="text-right"><%= ri.getDouble("qty_received") %></td>
    <td class="text-right"><%= ri.getDouble("qty_accepted") %></td>
    <td class="text-right"><%= ri.getDouble("qty_rejected") %></td>
    <td><%= ri.getString("remarks") != null ? ri.getString("remarks") : "-" %></td>
</tr>
<% } %>
</tbody>
</table>

<div class="signature">
    <p><b>Store In-Charge</b></p>
    <br><br>
    <p><b>Authorized Signatory</b></p>
    <div class="stamp">Received</div>
</div>

<%
        } else {
            out.println("<p style='color:red;text-align:center'>GRN Not Found</p>");
        }
    } catch(Exception e) {
        out.println("<p style='color:red'>Error: "+e.getMessage()+"</p>");
    }
}
%>

<button class="print-btn" onclick="window.print()">🖨 Print / Save PDF</button>

</body>
</html>
