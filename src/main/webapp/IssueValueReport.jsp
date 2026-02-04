<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, com.bean.DBUtil" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String user = (String) sess.getAttribute("username");
    String role = (String) sess.getAttribute("role");
    String deptss = (String) sess.getAttribute("department");

    if (!"Global".equalsIgnoreCase(role) &&
        !"Incharge".equalsIgnoreCase(role) &&
        !"Finance".equalsIgnoreCase(deptss)) {
        response.setContentType("text/html");
        response.getWriter().println("<h3 style='color:red;'>Access Denied</h3>");
        return;
    }
    %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Department-wise Monthly Issue Value Report</title>
<style>
    body {
        font-family:'Segoe UI',sans-serif;
        background: linear-gradient(135deg,#e0e7ff,#f9fafb);
        margin:0; padding:0;
    }
    .container {
        max-width:1250px;
        margin:40px auto;
        background:#ffffff;
        padding:35px;
        border-radius:15px;
        box-shadow:0 5px 20px rgba(0,0,0,0.12);
    }
    h1 {
        text-align:center;
        color:#1e40af;
        font-size:26px;
        margin-bottom:30px;
        letter-spacing:0.5px;
    }
    form {
        display:flex;
        justify-content:center;
        align-items:center;
        gap:15px;
        flex-wrap:wrap;
        margin-bottom:30px;
    }
    label {
        font-size:15px;
        font-weight:600;
        color:#374151;
    }
    select, button {
        padding:10px 14px;
        border-radius:8px;
        border:1px solid #cbd5e1;
        font-size:14px;
        background:#f8fafc;
        color:#111827;
        transition:all 0.2s ease;
    }
    select:focus, button:focus {
        outline:none;
        box-shadow:0 0 0 2px #93c5fd;
    }
    button {
        background:#2563eb;
        color:white;
        border:none;
        cursor:pointer;
        font-weight:600;
    }
    button:hover {
        background:#1e3a8a;
    }
    .dashboard {
        display:flex;
        justify-content:center;
        gap:20px;
        flex-wrap:wrap;
        margin-bottom:30px;
    }
    .card {
        flex:1 1 260px;
        background:linear-gradient(135deg,#4f46e5,#3b82f6);
        color:BLACK;
        border-radius:12px;
        padding:25px;
        text-align:center;
        box-shadow:0 4px 12px rgba(0,0,0,0.15);
        transition:transform 0.2s ease;
    }
    .card:hover { transform: translateY(-4px); }
    .card h3 {
        margin:0;
        font-size:16px;
        opacity:0.85;
        letter-spacing:0.3px;
    }
    .card p {
        margin-top:10px;
        font-size:26px;
        font-weight:700;
    }
    table {
        width:100%;
        border-collapse:collapse;
        font-size:14px;
        margin-top:15px;
        text-align:center;
    }
    th, td {
        border:1px solid #e2e8f0;
        padding:8px;
    }
    th {
        background:linear-gradient(135deg,#9333ea,#f97316);
        color:white;
        font-size:15px;
        letter-spacing:0.3px;
    }
    tr:nth-child(even) { background:#f9fafb; }
    tr:hover { background:#eef2ff; }
    td { color:#111827; }
    .no-data {
        text-align:center;
        color:#6b7280;
        font-style:italic;
        padding:15px 0;
    }
</style>
</head>
<body>
<%@ include file="header.jsp" %>
<br><br><br>
<div class="container">
    <h1>Department-wise Monthly Issue Value Report</h1>

    <!-- Filter Section -->
    <form method="get">
        <label>Department:</label>
        <select name="department">
            <option value="All">All</option>
            <%
                String selectedDept = request.getParameter("department");
                if (selectedDept == null) selectedDept = "All";
                try (Connection con = DBUtil.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "SELECT DISTINCT department FROM stock_issues WHERE department IS NOT NULL AND department<>'' ORDER BY department");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String dept = rs.getString("department");
                        boolean sel = dept != null && dept.equals(selectedDept);
            %>
                <option value="<%=dept%>" <%=sel ? "selected" : ""%>><%=dept%></option>
            <%
                    }
                } catch (Exception e) {
                    out.println("<option disabled>Error</option>");
                }
            %>
        </select>

        <label>Year:</label>
        <select name="year">
            <%
                String selectedYear = request.getParameter("year");
                if (selectedYear == null)
                    selectedYear = String.valueOf(Calendar.getInstance().get(Calendar.YEAR));

                try (Connection con = DBUtil.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "SELECT DISTINCT YEAR(issue_date) AS y FROM stock_issues WHERE issue_date IS NOT NULL ORDER BY y DESC");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String y = rs.getString("y");
                        boolean sel = y.equals(selectedYear);
            %>
                <option value="<%=y%>" <%=sel ? "selected" : ""%>><%=y%></option>
            <%
                    }
                } catch (Exception e) {
                    out.println("<option disabled>Error</option>");
                }
            %>
        </select>
        <button type="submit">Show Report</button>
    </form>

    <%
        
        String[] monthNames = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
        Map<String,double[]> dataMap = new LinkedHashMap<>();
        double grandTotal = 0;

        try (Connection con = DBUtil.getConnection()) {
            StringBuilder sql = new StringBuilder(
                "SELECT department, MONTH(issue_date) AS m, SUM(IFNULL(total_value,0)) AS total_value " +
                "FROM stock_issues WHERE issue_date IS NOT NULL AND YEAR(issue_date)=? ");
            if (!"All".equalsIgnoreCase(selectedDept)) {
                sql.append("AND department=? ");
            }
            sql.append("GROUP BY department, m ORDER BY department, m");

            PreparedStatement ps = con.prepareStatement(sql.toString());
            ps.setInt(1, Integer.parseInt(selectedYear));
            if (!"All".equalsIgnoreCase(selectedDept))
                ps.setString(2, selectedDept);

            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String dept = rs.getString("department");
                int month = rs.getInt("m");
                double val = rs.getDouble("total_value");

                if (dept == null || dept.trim().isEmpty()) continue;
                dataMap.putIfAbsent(dept, new double[12]);
                dataMap.get(dept)[month - 1] = val;
                grandTotal += val;
            }
            rs.close();
            ps.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        int totalRows = dataMap.size();
    %>

  
    <div class="dashboard">
        <div class="card">
            <h3>Total Departments</h3>
            <p><%= totalRows %></p>
        </div>
        <div class="card">
            <h3>Total Issue Value (₹)</h3>
            <p><%= String.format("%.2f", grandTotal) %></p>
        </div>
       
    </div>

 
    <table>
        <thead>
            <tr>
                <th>Department</th>
                <% for (String m : monthNames) { %>
                    <th><%= m %></th>
                <% } %>
                <th>Total (₹)</th>
            </tr>
        </thead>
        <tbody>
            <%
                if (!dataMap.isEmpty()) {
                    for (Map.Entry<String,double[]> entry : dataMap.entrySet()) {
                        String dept = entry.getKey();
                        double[] vals = entry.getValue();
                        double total = 0;
            %>
                <tr>
                    <td><%= dept %></td>
                    <% for (double v : vals) { total += v; %>
                        <td><%= String.format("%.2f", v) %></td>
                    <% } %>
                    <td><%= String.format("%.2f", total) %></td>
                </tr>
            <%
                    }
                } else {
            %>
                <tr>
                    <td colspan="14" class="no-data">No data available for the selected filters.</td>
                </tr>
            <%
                }
            %>
        </tbody>
    </table>
</div>
</body>
</html>
