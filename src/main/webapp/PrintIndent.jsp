<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>

<%
    String IndentNumber = request.getParameter("IndentNumber"); // comes from button click
%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>
<h1 align="center">Sandur Residential School</h1>
<h4 align="center">Shivapur, palace Road, Sandur</h4>
<h2 align="center">Indent</h2>
  <%
    if (IndentNumber != null) {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DBUtil.getConnection();

        PreparedStatement pst = con.prepareStatement(
            "SELECT indent_no, indent_date, item_name, qty, department, requested_by,status, purpose " +
            "FROM indent WHERE indent_no=?");
        pst.setString(1, IndentNumber);
        ResultSet rsPO = pst.executeQuery();

        if (rsPO.next()) {
%>
            <style>
                table {
                    border-collapse: collapse;
                    width: 80%;
                    margin: 20px auto;
                    background: #fff;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                }
                th, td {
                    border: 1px solid #ddd;
                    padding: 10px;
                    text-align: center;
                }
                th {
                    background: #007BFF;
                    color: white;
                }
                tr:nth-child(even) {
                    background: #f9f9f9;
                }
                h3 {
                    text-align: center;
                    color: #333;
                }
            </style>

           
            <table>
                <tr>
                    <th>Indent No</th>
                    <th>Indent Date</th>
                    <th>Item Name</th>
                    <th>Quantity</th>
                    <th>Department</th>
                    <th>Requested By</th>
                    <th>Purpose</th>
                    <th>Final Approve</th>
                </tr>
<%
            do {
%>
                <tr>
                    <td><%= rsPO.getString("indent_no") %></td>
                    <td><%= rsPO.getString("indent_date") %></td>
                    <td><%= rsPO.getString("item_name") %></td>
                    <td><%= rsPO.getString("qty") %></td>
                    <td><%= rsPO.getString("department") %></td>
                    <td><%= rsPO.getString("requested_by") %></td>
                    <td><%= rsPO.getString("purpose") %></td>
                    <td><%= rsPO.getString("status") %></td>
                </tr>
<%
            } while (rsPO.next());
%>
               
            </table>
<%
        } else {
            out.println("<p style='text-align:center;color:red;'>No PO Found!</p>");
        }
        con.close();
    }
%>
<h4>for SANDUR RESIDENTIAL SCHOOL</h4>				
    
    <br><br><br>
    <h4>Authorised Signatory</h4>
</body>
</html>