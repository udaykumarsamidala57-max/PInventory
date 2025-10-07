<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%
    String poNumber = request.getParameter("poNumber"); // comes from button click
%>
<html>
<head>
    <title>Print Purchase Order</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h2, h3,h6 { text-align: center; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid black; padding: 8px; text-align: right; }
        .right { text-align: right; }
        .print-btn { margin: 20px 0; padding: 10px 20px; background: #4CAF50; color: white; border: none; cursor: pointer; }
         .tab {
            display: inline-block;
            margin-left: 300px;
        }
        .tabb {
            display: inline-block;
            margin-left: 300px;
            text-align: left;
        }
    </style>
</head>
<body>
    

    <%
        if(poNumber != null){
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con =  DBUtil.getConnection();

            PreparedStatement pst = con.prepareStatement(
                "SELECT po_number, po_date, vendor_name, vendor_address,total_gst,total_dis, total_amount,terms_conditions,general_conditions " +
                "FROM po_master WHERE po_number=?");
            pst.setString(1, poNumber);
            ResultSet rsPO = pst.executeQuery();

            if(rsPO.next()){
    %>
        <h2>Sandur Residential School</h2>
        <h6>Palace Road,Shivapur, Sandur 583119, Ballari (Dist.), Karnataka<br>
(a Unit of Shivapur Shikshana Samiti, Affiliated to the Council for the Indian School Certificate Examinations, New Delhi, School Code: KA071)</h6>
        
       <h6> Website: www.sandurschool.edu.in</h6>												
        <h6 >E-mail: srsadmin@sandurschool.com	<span class="tab"></span> 08395-260246</h6>
        
        
        
        <h3>Purchase Order</h3>
        

        <table>
            <tr>
                <td><b>PO Number:</b> <%=rsPO.getString("po_number")%></td>
                <td><b>Date:</b> <%=rsPO.getString("po_date")%></td>
            </tr>
            <tr>
                <td><b>Vendor:</b> <%=rsPO.getString("vendor_name")%></td>
                <td><b>Address:</b> <%=rsPO.getString("vendor_address")%></td>
            </tr>
        </table>

        <%
            PreparedStatement pstItems = con.prepareStatement(
                "SELECT description, qty, rate, amount, discount_percent,discount_value,gst_percent,gst_value,net_amount " +
                "FROM po_items WHERE po_no=?");
            pstItems.setString(1, poNumber);
            ResultSet rsItems = pstItems.executeQuery();
        %>

        <table>
            <tr>
                <th>Sl.No</th>
                <th>Item Description</th>
                <th>Qty</th>
                <th>Rate</th>
                <th>Amount</th>
                <th>Discount Percent</th>
                <th>Discount Value</th>
                <th>GST %</th>
                <th>GST Value</th>
                <th>Net Amount</th>
            </tr>
            <%
                int sl = 1;
                while(rsItems.next()){
            %>
            <tr>
                <td><%=sl++%></td>
                <td><%=rsItems.getString("description")%></td>
                <td><%=rsItems.getInt("qty")%></td>
                <td><%=rsItems.getDouble("rate")%></td>
                <td><%=rsItems.getDouble("amount")%></td>
                <td><%=rsItems.getDouble("discount_percent")%></td>
                <td><%=rsItems.getDouble("discount_value")%></td>
                <td><%=rsItems.getDouble("gst_percent")%></td>
                <td><%=rsItems.getDouble("gst_value")%></td>
                <td><%=rsItems.getDouble("net_amount")%></td>
                
            </tr>
           
            <% } 
            
            
            
            %>
            <tr>
            <td colspan="5">Toatl Discount
            </td>
            <td colspan="5"><%=rsPO.getString("total_dis")%>
            </td>
            </tr>
            <tr>
            <td colspan="5">Total GST
            </td>
            <td colspan="5"><%=rsPO.getString("total_gst")%>
            </td>
            </tr>
            <tr>
            <td colspan="5">Total Amount
            </td>
            <td colspan="5"><%=rsPO.getString("total_amount")%>
            </td>
            </tr>
            <tr>
            <td colspan="1"><h4>Terms And Conditions</h4>
            </td>
            
            <td colspan="9" ><p align="left"><%=rsPO.getString("terms_conditions")%></p>
            </td>
            </tr>
            <tr>
            <td colspan="1"><h4>General Conditions</h4>
            </td>
            <td colspan="9" ><p align="left"><%=rsPO.getString("general_conditions")%></p>
            </td>
            </p>
            </tr>
        </table>

        
    <%
            } else {
                out.println("<p>No PO Found!</p>");
            }
            con.close();
        }
    %>
    <h4>for SANDUR RESIDENTIAL SCHOOL</h4>				
    
    <br><br><br>
    <h4>Authorised Signatory</h4>
    
   <p align="right"> <button class="print-btn" onclick="window.print()" >Print / Save as PDF</button></p>
</body>
</html>
