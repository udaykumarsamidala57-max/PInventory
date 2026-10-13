<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, com.bean.DBUtil3, java.text.SimpleDateFormat" %>

<%
    String enquiryId = request.getParameter("enquiry_id");
    String applicationNo = request.getParameter("application_no");

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
   
    SimpleDateFormat sdf = new SimpleDateFormat("dd MMMM yyyy");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Hall Ticket</title>
    <style>
        /* A5 Landscape Setup */
        @page { size: A5 landscape; margin: 6mm; }
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f4f4f4; margin: 0; padding: 0; }
        
        .hall-ticket { 
            width: 100%; 
            background: #fff; 
            border: 2px solid #000; 
            padding: 10mm; 
            box-sizing: border-box; 
            margin: auto;
        }

        .header-section { 
            text-align: center; 
            border-bottom: 2px solid #000; 
            padding-bottom: 5px; 
            margin-bottom: 10px; 
        }

        h2 { margin: 0; font-size: 18px; }
        h4 { margin: 2px 0; font-size: 12px; font-weight: normal; }

        table { width: 100%; border-collapse: collapse; margin-top: 5px; }
        td { padding: 6px 10px; border: 1px solid #000; font-size: 13px; }
        
        .label { 
            font-weight: bold; 
            width: 30%; 
            background: #f2f2f2; 
        }

        .print-btn-container { text-align: center; margin-top: 15px; }
        .btn { padding: 8px 20px; cursor: pointer; background: #000; color: #fff; border: none; }

        @media print {
            body { background: #fff; }
            .print-btn-container { display: none; }
            .hall-ticket { border: 2px solid #000; }
        }
    </style>
</head>
<body>

<%
try {
    con = DBUtil3.getConnection();

   
    String sql = "SELECT * FROM admission_enquiry WHERE enquiry_id = ? OR (application_no = ? AND application_no != '') LIMIT 1";
    
    ps = con.prepareStatement(sql);

    int idValue = 0;
    try {
        if (enquiryId != null) idValue = Integer.parseInt(enquiryId.replaceAll("[^0-9]", ""));
    } catch (NumberFormatException e) { idValue = -1; }

    ps.setInt(1, idValue);
    ps.setString(2, (applicationNo != null) ? applicationNo.trim() : "");

    rs = ps.executeQuery();

    if (rs.next()) {
        String appNo = rs.getString("application_no");
        if (appNo == null) appNo = ""; 

       
        Date dobDate = rs.getDate("date_of_birth");
        String formattedDOB = (dobDate != null) ? sdf.format(dobDate).toUpperCase() : "";
%>

<div class="hall-ticket">
    <div class="header-section">
        <h2>SANDUR RESIDENTIAL SCHOOL</h2>
        <h4>EXAM – HALL TICKET(2026-27)</h4>
    </div>

    <table>
        <tr>
            <td class="label">Application No</td>
            <td><%= appNo %></td> 
        </tr>
        <tr>
            <td class="label">Enquiry ID</td>
            <td>E26-<%= rs.getInt("enquiry_id") %></td>
        </tr>
        <tr>
            <td class="label">Student Name</td>
            <td><strong><%= rs.getString("student_name") %></strong></td>
        </tr>
        <tr>
            <td class="label">Gender</td>
            <td><%= rs.getString("gender") %></td>
        </tr>
        <tr>
            <td class="label">Date of Birth</td>
            <td><%= formattedDOB %></td> 
        </tr>
        <tr>
            <td class="label">Class of Admission</td>
            <td><%= rs.getString("class_of_admission") %></td>
        </tr>
        <tr>
            <td class="label">Admission Type</td>
            <td><%= rs.getString("admission_type") %></td>
        </tr>
        <tr>
            <td class="label">Father Name</td>
            <td><%= rs.getString("father_name") %></td>
        </tr>
    </table>

    <div class="print-btn-container">
        <button class="btn" onclick="window.print()">🖨 Print Hall Ticket</button>
    </div>
</div>

<%
    } else {
%>
    <div style="text-align:center; padding: 50px;">
        <h3 style="color:red;">No Student Record Found</h3>
        <p>Search ID: <%= enquiryId %> | App No: <%= applicationNo %></p>
    </div>
<%
    }
} catch (Exception e) {
    out.println("<b>Database Error:</b> " + e.getMessage());
} finally {
    if (rs != null) rs.close();
    if (ps != null) ps.close();
    if (con != null) con.close();
}
%>

</body>
</html>