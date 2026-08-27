<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil5" %>
<%@ page import="java.util.*" %>
<%
HttpSession sess = request.getSession(false);

if(sess == null || sess.getAttribute("username") == null){
    response.sendRedirect(request.getContextPath()+"/login.jsp");
    return;
}

String role = (String)sess.getAttribute("role");
String dept = (String)sess.getAttribute("department");
String branch = (String) sess.getAttribute("branch");

if((!"Global".equalsIgnoreCase(role))
        && (!"Finance".equalsIgnoreCase(dept))
        && (!"Admin".equalsIgnoreCase(role))){
    out.println("<h3 style='text-align:center;color:#ea001e;margin-top:50px;font-family:Segoe UI;'>Access Denied</h3>");
    return;
}

String username = ((String)sess.getAttribute("username")).toUpperCase();
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Closed Service Requests </title>

<style>
body {
    margin: 0;
    font-family: "Salesforce Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: #f3f3f3;
    color: #181818;
}

/* Salesforce Utility Bar / Header */
.header-banner {
    background: #fff;
    padding: 16px 24px;
    border-bottom: 1px solid #dddbda;
    display: flex;
    align-items: center;
    justify-content: space-between;
    box-shadow: 0 2px 2px rgba(0,0,0,0.05);
}

.header-title-area {
    display: flex;
    align-items: center;
    gap: 12px;
}

/* Iconic Salesforce-like square icon placeholder */
.slds-icon {
    background: #4bca81;
    color: white;
    width: 40px;
    height: 40px;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    font-size: 18px;
}

.header-title {
    font-size: 18px;
    font-weight: 700;
    color: #081c3b;
    margin: 0;
}

.header-subtitle {
    font-size: 12px;
    color: #514f4d;
    margin: 0;
}

.container {
    padding: 24px;
    max-width: 1400px;
    margin: 0 auto;
}

/* KPI Metrics Dashboard Grid */
.metrics-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 16px;
    margin-bottom: 24px;
}

.metric-card {
    background: #fff;
    border: 1px solid #dddbda;
    border-radius: 4px;
    padding: 16px;
    display: flex;
    flex-direction: column;
    justify-content: center;
    box-shadow: 0 2px 2px rgba(0,0,0,0.02);
}

.metric-label {
    font-size: 13px;
    color: #514f4d;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 4px;
}

.metric-value {
    font-size: 28px;
    font-weight: 300;
    color: #0176d3; /* Salesforce Blue */
}

/* Main Content Card */
.slds-card {
    background: #fff;
    border: 1px solid #dddbda;
    border-radius: 4px;
    box-shadow: 0 2px 2px rgba(0,0,0,0.02);
    overflow: hidden;
}

.card-header {
    padding: 16px;
    border-bottom: 1px solid #dddbda;
    background: #f9f9fa;
    font-weight: 600;
    font-size: 14px;
}

.table-wrapper {
    overflow-x: auto;
}

.table {
    width: 100%;
    border-collapse: collapse;
    text-align: left;
}

.table th {
    background: #fafaf9;
    color: #444;
    padding: 12px 16px;
    font-size: 13px;
    font-weight: 600;
    border-bottom: 2px solid #dddbda;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.table td {
    padding: 12px 16px;
    border-bottom: 1px solid #dddbda;
    font-size: 13px;
    color: #181818;
}

.table tr:hover {
    background: #f3f3f3;
}

/* Status Badges */
.status-badge {
    background: #e1f5fe;
    color: #0288d1;
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 12px;
    font-weight: 600;
    display: inline-block;
}

.status-badge.closed {
    background: #d8f5e5;
    color: #0b6a3a;
}

.no-data {
    text-align: center;
    padding: 40px;
    color: #747474;
    font-size: 14px;
}
</style>
</head>
<body>

<%@ include file="../header.jsp" %>



<div class="container">

<%
Connection con = null;
PreparedStatement psList = null;
PreparedStatement psDept = null;
ResultSet rsList = null;
ResultSet rsDept = null;

Map<String, Integer> deptCounts = new LinkedHashMap<String, Integer>();
int totalClosed = 0;

try {
    con = DBUtil5.getConnection(branch);

    /* UPDATED QUERY: 
       Performs a LEFT JOIN with your departments table to extract 
       and group metrics using the official 'department_name'.
    */
    String deptSql = "SELECT COALESCE(d.department_name, 'Unassigned') AS dept_name, COUNT(s.id) AS count " +
            "FROM service_requests s " +
            "LEFT JOIN departments d ON s.department_id = d.id " +
            "WHERE s.status='CLOSED' " +
            "GROUP BY d.department_name " +
            "ORDER BY count DESC";
                     
    psDept = con.prepareStatement(deptSql);
    rsDept = psDept.executeQuery();
    
    while(rsDept.next()) {
        String deptName = rsDept.getString("dept_name");
        int count = rsDept.getInt("count");
        deptCounts.put(deptName, count);
        totalClosed += count;
    }
%>

    <div class="metrics-grid">
        <div class="metric-card" style="border-left: 4px solid #0176d3;">
            <span class="metric-label">Total Closed</span>
            <span class="metric-value"><%= totalClosed %></span>
        </div>
        <% 
        if(!deptCounts.isEmpty()) {
            for(Map.Entry<String, Integer> entry : deptCounts.entrySet()) {
        %>
                <div class="metric-card">
                    <span class="metric-label"><%= entry.getKey() %></span>
                    <span class="metric-value"><%= entry.getValue() %></span>
                </div>
        <% 
            }
        } else { 
        %>
            <div class="metric-card">
                <span class="metric-label">Departments</span>
                <span class="metric-value" style="font-size:16px; color:#747474;">No data available</span>
            </div>
        <% } %>
    </div>

    <div class="slds-card">
        <div class="card-header">
            Records (<%= totalClosed %>)
        </div>
        <div class="table-wrapper">
            <table class="table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Request No</th>
                        <th>Request Date</th>
                        <th>Requested By</th>
                        <th>Location</th>
                        <th>Priority</th>
                        <th>Description</th>
                        <th>Status</th>
                        <th>Resolution</th>
                        <th>Resolved By</th>
                        <th>Closed Date</th>
                    </tr>
                </thead>
                <tbody>
<%
    // 2. Fetching the primary data rows
    String listSql =
"SELECT s.*, d.department_name, i.incharge_name " +
"FROM service_requests s " +
"LEFT JOIN departments d ON s.department_id = d.id " +
"LEFT JOIN department_incharge i ON s.department_id = i.department_id " +
"WHERE s.status='CLOSED' " +
"ORDER BY s.closed_date DESC";
    psList = con.prepareStatement(listSql);
    rsList = psList.executeQuery();

    boolean found = false;

    while(rsList.next()){
        found = true;
%>
                    <tr>
                        <td><strong><%= rsList.getInt("id") %></strong></td>
                        <td><%= rsList.getString("request_no") %></td>
                        <td><%= rsList.getString("request_date") %></td>
                        <td><%= rsList.getString("requested_by") %></td>
                        <td><%= rsList.getString("location") %></td>
                        <td><%= rsList.getString("priority") %></td>
                        <td><%= rsList.getString("description") %></td>
                        <td>
                            <span class="status-badge closed">
                                <%= rsList.getString("status") %>
                            </span>
                        </td>
                        <td><%= rsList.getString("resolution") %></td>
                       
                        <td>
    <%= rsList.getString("incharge_name") != null 
        ? rsList.getString("incharge_name") 
        : "Not Assigned" %>
</td>
                        <td><%= rsList.getString("closed_date") %></td>
                    </tr>
<%
    }

    if(!found){
%>
                    <tr>
                        <td colspan="10" class="no-data">
                            No Closed Requests Found
                        </td>
                    </tr>
<%
    }
} catch(Exception e) {
%>
                    <tr>
                        <td colspan="10" style="color:#ea001e; text-align:center; padding: 20px; font-weight: bold;">
                            System Error: <%= e.getMessage() %>
                        </td>
                    </tr>
<%
} finally {
    try {
        if(rsList != null) rsList.close();
        if(psList != null) psList.close();
        if(rsDept != null) rsDept.close();
        if(psDept != null) psDept.close();
        if(con != null) con.close();
    } catch(Exception e) {
        e.printStackTrace();
    }
}
%>
                </tbody>
            </table>
        </div>
    </div>

</div>

</body>
</html>