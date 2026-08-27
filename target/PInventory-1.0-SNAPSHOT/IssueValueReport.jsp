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
    String branch = (String) sess.getAttribute("branch");

    if (!"Global".equalsIgnoreCase(role) &&
        !"Incharge".equalsIgnoreCase(role) &&
        !"Finance".equalsIgnoreCase(deptss)) {
        response.setContentType("text/html");
        response.getWriter().println("<h3 style='color:red;'>Access Denied</h3>");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Department Monthly Issue Value Report</title>
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

    <style>
        :root {
            --surface-bg: #f8fafc;
            --card-bg: #ffffff;
            --navy-primary: #0f172a;
            --navy-accent: #1e3a8a;
            --text-heading: #0f172a;
            --text-body: #334155;
            --text-muted: #64748b;
            --border-light: #e2e8f0;
            --border-strong: #cbd5e1;
        }

        body {
            background-color: var(--surface-bg);
            font-family: 'Inter', system-ui, -apple-system, sans-serif;
            color: var(--text-body);
            margin: 0;
            padding: 0;
            -webkit-font-smoothing: antialiased;
        }

        .report-wrapper {
            width: 95%;
            max-width: 1380px;
            margin: 32px auto;
        }

        /* Page Header */
        .page-header {
            margin-bottom: 24px;
        }

        .page-header h1 {
            font-size: 22px;
            font-weight: 700;
            color: var(--navy-primary);
            margin: 0 0 6px 0;
            letter-spacing: -0.02em;
        }

        .page-header p {
            font-size: 14px;
            color: var(--text-muted);
            margin: 0;
        }

        /* Metrics Bar */
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }

        .metric-card {
            background: var(--card-bg);
            border: 1px solid var(--border-light);
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
        }

        .metric-card .label {
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--text-muted);
            margin-bottom: 8px;
        }

        .metric-card .value {
            font-size: 24px;
            font-weight: 700;
            color: var(--navy-primary);
            font-variant-numeric: tabular-nums;
        }

        /* Filter Form */
        .filter-card {
            background: var(--card-bg);
            border: 1px solid var(--border-light);
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 24px;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
        }

        .filter-form {
            display: flex;
            align-items: flex-end;
            gap: 20px;
            flex-wrap: wrap;
        }

        .form-field {
            display: flex;
            flex-direction: column;
            gap: 6px;
            min-width: 200px;
        }

        .form-field label {
            font-size: 13px;
            font-weight: 600;
            color: var(--text-body);
        }

        .form-select {
            height: 40px;
            padding: 0 12px;
            border: 1px solid var(--border-strong);
            border-radius: 6px;
            background-color: var(--card-bg);
            color: var(--text-heading);
            font-size: 14px;
            font-family: inherit;
            outline: none;
            transition: border-color 0.15s ease;
        }

        .form-select:focus {
            border-color: var(--navy-accent);
        }

        .btn-submit {
            height: 40px;
            padding: 0 24px;
            background-color: var(--navy-primary);
            color: #ffffff;
            font-size: 14px;
            font-weight: 600;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            transition: background-color 0.15s ease;
        }

        .btn-submit:hover {
            background-color: var(--navy-accent);
        }

        /* Data Table */
        .table-card {
            background: var(--card-bg);
            border: 1px solid var(--border-light);
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
        }

        .table-wrapper {
            width: 100%;
            overflow-x: auto;
        }

        .report-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
            text-align: right;
        }

        .report-table th {
            background-color: #f1f5f9;
            color: var(--text-heading);
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.03em;
            padding: 12px 14px;
            border-bottom: 2px solid var(--border-strong);
            white-space: nowrap;
        }

        .report-table th:first-child {
            text-align: left;
            padding-left: 20px;
        }

        .report-table th:last-child {
            background-color: #e2e8f0;
        }

        .report-table td {
            padding: 12px 14px;
            border-bottom: 1px solid var(--border-light);
            color: var(--text-body);
            font-variant-numeric: tabular-nums;
            white-space: nowrap;
        }

        .report-table td:first-child {
            text-align: left;
            font-weight: 600;
            color: var(--navy-primary);
            padding-left: 20px;
        }

        .report-table td:last-child {
            font-weight: 700;
            color: var(--navy-primary);
            background-color: #f8fafc;
        }

        .report-table tr:hover td {
            background-color: #f1f5f9;
        }

        .text-zero {
            color: #94a3b8;
        }

        .no-records {
            text-align: center !important;
            color: var(--text-muted);
            font-style: italic;
            padding: 24px !important;
        }
    </style>
</head>
<body>
<%@ include file="header.jsp" %>

<div class="report-wrapper">

   

    <!-- Filter Toolbar -->
    <div class="filter-card">
        <form method="get" class="filter-form">
            <div class="form-field">
                <label for="department">Department</label>
                <select id="department" name="department" class="form-select">
                    <option value="All">All Departments</option>
                    <%
                        String selectedDept = request.getParameter("department");
                        if (selectedDept == null) selectedDept = "All";
                        try (Connection con = DBUtil.getConnection(branch);
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
                            out.println("<option disabled>Error loading departments</option>");
                        }
                    %>
                </select>
            </div>

            <div class="form-field">
                <label for="year">Year</label>
                <select id="year" name="year" class="form-select">
                    <%
                        String selectedYear = request.getParameter("year");
                        if (selectedYear == null)
                            selectedYear = String.valueOf(Calendar.getInstance().get(Calendar.YEAR));

                        try (Connection con = DBUtil.getConnection(branch);
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
                            out.println("<option disabled>Error loading years</option>");
                        }
                    %>
                </select>
            </div>

            <button type="submit" class="btn-submit">Generate Report</button>
        </form>
    </div>

    <%
        String[] monthNames = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
        Map<String,double[]> dataMap = new LinkedHashMap<>();
        double grandTotal = 0;

        try (Connection con = DBUtil.getConnection(branch)) {
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

    <!-- Metric Summaries -->
    <div class="metrics-grid">
        <div class="metric-card">
            <div class="label">Total Departments</div>
            <div class="value"><%= totalRows %></div>
        </div>
        <div class="metric-card">
            <div class="label">Total Issue Value (₹)</div>
            <div class="value">₹<%= String.format("%.2f", grandTotal) %></div>
        </div>
    </div>

    <!-- Data Table Card -->
    <div class="table-card">
        <div class="table-wrapper">
            <table class="report-table">
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
                                <td class="<%= v == 0 ? "text-zero" : "" %>">
                                    <%= String.format("%.2f", v) %>
                                </td>
                            <% } %>
                            <td><%= String.format("%.2f", total) %></td>
                        </tr>
                    <%
                            }
                        } else {
                    %>
                        <tr>
                            <td colspan="14" class="no-records">No issue data found for the specified filters.</td>
                        </tr>
                    <%
                        }
                    %>
                </tbody>
            </table>
        </div>
    </div>

</div>
</body>
</html>