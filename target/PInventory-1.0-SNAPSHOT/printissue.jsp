<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
    String indentNo = request.getParameter("indentNo");
    if (indentNo == null || indentNo.trim().isEmpty()) {
        out.println("Invalid Indent Number.");
        return;
    }

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String issuedTo = "";
    String department = "";
    Timestamp issueDate = null;
    double grandTotal = 0.0;
%>
<!DOCTYPE html>
<html>
<head>
    <title>Stock Issue Voucher - <%= indentNo %></title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #181818;
        }
        .voucher-card {
            border: 1px solid #ccc;
            padding: 24px;
            max-width: 750px;
            margin: 0 auto;
            background: #fff;
        }
        .header {
            text-align: center;
            border-bottom: 2px solid #000;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        .header h2 { margin: 0; font-size: 20px; text-transform: uppercase; }
        .meta-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-bottom: 20px;
            font-size: 13px;
        }
        .meta-item strong { display: inline-block; width: 110px; }
        table.items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
            font-size: 13px;
        }
        table.items-table th, table.items-table td {
            border: 1px solid #747472;
            padding: 8px;
            text-align: left;
        }
        table.items-table th {
            background-color: #f3f3f3;
            text-transform: uppercase;
            font-size: 11px;
        }
        .num { text-align: right; }
        .total-row td { font-weight: bold; background-color: #fafaf9; }
        .signatures {
            display: flex;
            justify-content: space-between;
            margin-top: 50px;
            font-size: 12px;
        }
        .sig-box {
            border-top: 1px solid #000;
            width: 30%;
            text-align: center;
            padding-top: 5px;
        }
        @media print {
            .no-print { display: none; }
            .voucher-card { border: none; padding: 0; }
        }
    </style>
</head>
<body onload="window.print()">

<div class="voucher-card">
    <div class="header">
        <h2>Stock Issue Voucher</h2>
    </div>

    <%
        try {
            con = DBUtil.getConnection();
            String sql = "SELECT si.indent_no, si.item_id, im.Item_name, si.issued_to, " +
                         "si.department, si.qty_issued, si.unit_price, si.total_value, si.issue_date, si.remarks " +
                         "FROM stock_issues si JOIN item_master im ON si.item_id = im.Item_id " +
                         "WHERE si.indent_no = ? ORDER BY si.item_id ASC";
            
            ps = con.prepareStatement(sql);
            ps.setString(1, indentNo);
            rs = ps.executeQuery();

            boolean headerCaptured = false;
    %>

    <div class="items-container">
        <table class="items-table">
            <thead>
                <tr>
                    <th>S.No</th>
                    <th>Item ID</th>
                    <th>Item Name</th>
                    <th class="num">Qty Issued</th>
                    <th class="num">Unit Price (₹)</th>
                    <th class="num">Total Value (₹)</th>
                </tr>
            </thead>
            <tbody>
            <%
                int sno = 0;
                while (rs.next()) {
                    sno++;
                    if (!headerCaptured) {
                        issuedTo = rs.getString("issued_to");
                        department = rs.getString("department");
                        issueDate = rs.getTimestamp("issue_date");
                        headerCaptured = true;
                    }

                    double qty = rs.getDouble("qty_issued");
                    double price = rs.getDouble("unit_price");
                    double val = rs.getDouble("total_value");
                    grandTotal += val;
            %>
                <tr>
                    <td><%= sno %></td>
                    <td><%= rs.getInt("item_id") %></td>
                    <td><%= rs.getString("Item_name") %></td>
                    <td class="num"><%= qty %></td>
                    <td class="num"><%= String.format("%.2f", price) %></td>
                    <td class="num"><%= String.format("%.2f", val) %></td>
                </tr>
            <%
                }
                if (sno == 0) {
            %>
                <tr><td colspan="6" style="text-align:center; color:red;">No records found for Indent No: <%= indentNo %></td></tr>
            <%
                }
            %>
            </tbody>
            <tfoot>
                <tr class="total-row">
                    <td colspan="5" class="num">Grand Total (₹):</td>
                    <td class="num"><%= String.format("%.2f", grandTotal) %></td>
                </tr>
            </tfoot>
        </table>
    </div>

    <div class="meta-grid">
        <div class="meta-item"><strong>Indent No:</strong> <%= indentNo %></div>
        <div class="meta-item"><strong>Issue Date:</strong> <%= issueDate != null ? issueDate : "-" %></div>
        <div class="meta-item"><strong>Issued To:</strong> <%= issuedTo != null ? issuedTo : "-" %></div>
        <div class="meta-item"><strong>Department:</strong> <%= department != null ? department : "-" %></div>
    </div>

    <div class="signatures">
        <div class="sig-box">Issued By</div>
        <div class="sig-box">Received By</div>
        <div class="sig-box">Authorised Signatory</div>
    </div>

    <%
        } catch (Exception e) {
            out.println("<p style='color:red;'>Error fetching voucher details: " + e.getMessage() + "</p>");
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception ignored) {}
            if (ps != null) try { ps.close(); } catch (Exception ignored) {}
            if (con != null) try { con.close(); } catch (Exception ignored) {}
        }
    %>

    <div style="margin-top:25px; text-align:center;" class="no-print">
        <button onclick="window.print()" style="padding: 8px 16px; cursor:pointer;">Print Again</button>
    </div>
</div>

</body>
</html>