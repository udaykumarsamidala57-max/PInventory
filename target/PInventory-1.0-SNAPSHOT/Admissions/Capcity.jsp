<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil3" %>

<%
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    int grandGirls = 0, grandBoys = 0, grandBoarders = 0, grandDayScholars = 0, grandCapacity = 0;

    String action = request.getParameter("action");

    try {
        con = DBUtil3.getConnection();

        if ("download".equals(action)) {
            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition", "attachment; filename=class_capacity.csv");
            out.println("ID,Class,Boarders (Total),Day Scholars,Girls (Boarders),Boys (Boarders),Total Capacity");

            ps = con.prepareStatement("SELECT * FROM class_capacity ORDER BY id");
            rs = ps.executeQuery();
            while (rs.next()) {
                out.println(rs.getInt("id") + "," + rs.getString("class_name") + "," + rs.getInt("boarders") + "," +
                        rs.getInt("day_scholars") + "," + rs.getInt("boarders_girls") + "," +
                        rs.getInt("boarders_boys") + "," + rs.getInt("total_capacity"));
            }
            return;
        }

        if ("add".equals(action) || "update".equals(action)) {
            int g = Integer.parseInt(request.getParameter("boarders_girls") == null ? "0" : request.getParameter("boarders_girls"));
            int b = Integer.parseInt(request.getParameter("boarders_boys") == null ? "0" : request.getParameter("boarders_boys"));
            int ds = Integer.parseInt(request.getParameter("day_scholars") == null ? "0" : request.getParameter("day_scholars"));
            int totalB = g + b;
            int totalC = totalB + ds;

            if ("add".equals(action)) {
                ps = con.prepareStatement("INSERT INTO class_capacity (class_name, boarders, day_scholars, total_capacity, boarders_girls, boarders_boys) VALUES (?, ?, ?, ?, ?, ?)");
                ps.setString(1, request.getParameter("class_name"));
                ps.setInt(2, totalB); ps.setInt(3, ds); ps.setInt(4, totalC); ps.setInt(5, g); ps.setInt(6, b);
            } else {
                ps = con.prepareStatement("UPDATE class_capacity SET boarders=?, day_scholars=?, total_capacity=?, boarders_girls=?, boarders_boys=? WHERE id=?");
                ps.setInt(1, totalB); ps.setInt(2, ds); ps.setInt(3, totalC); ps.setInt(4, g); ps.setInt(5, b);
                ps.setInt(6, Integer.parseInt(request.getParameter("id")));
            }
            ps.executeUpdate();
            response.sendRedirect(request.getRequestURI());
            return;
        }
    } catch (Exception e) { e.printStackTrace(); }
%>

<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Class Capacity Management</title>
    <style>
        body { font-family: "Inter", "Segoe UI", sans-serif; background: #f4f7fa; padding: 10px; color: #333; margin: 0; }
        
        /* Container to allow horizontal scroll on small screens */
        .table-responsive {
            width: 100%;
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
            margin-bottom: 20px;
        }

        table { 
            width: 100%; 
            max-width: 1100px; /* Limits size on ultra-wide screens */
            margin: 0 auto; 
            background: #fff; 
            border-radius: 8px; 
            border-collapse: collapse; 
            box-shadow: 0 4px 15px rgba(0,0,0,0.05);
            font-size: 13px; /* Slightly smaller font for better fit */
        }

        th { background: #0f2a4d; color: white; padding: 10px 5px; white-space: nowrap; }
        td { padding: 8px 5px; border-bottom: 1px solid #edf2f7; text-align: center; }
        
        /* Compact inputs */
        input { 
            width: 55px; 
            padding: 5px; 
            border-radius: 4px; 
            border: 1px solid #cbd5e1; 
            text-align: center; 
        }

        .btn { padding: 6px 12px; border-radius: 6px; border: none; cursor: pointer; font-weight: 600; font-size: 12px; white-space: nowrap; }
        .add { background: #10b981; color: white; }
        .edit { background: #3b82f6; color: white; }

        .footer-row { background: #f8fafc; font-weight: bold; border-top: 2px solid #cbd5e1; }
        
        /* Highlight labels */
        .sum-label { font-weight: bold; color: #64748b; }
        .capacity-label { font-weight: bold; color: #2563eb; }

        h2 { font-size: 1.5rem; margin: 15px 0; }

        @media screen and (max-width: 600px) {
            input { width: 45px; }
            h2 { font-size: 1.2rem; }
        }
    </style>
</head>
<body>

<jsp:include page="common_header.jsp" />
<h2 align="center">Class Capacity Management</h2>

<div class="table-responsive">
    <form method="post">
        <input type="hidden" name="action" value="add">
        <table>
            <tr>
                <th>Class Name</th>
                <th>Girls(B)</th>
                <th>Boys(B)</th>
                <th>Day Sch.</th>
                <th style="background:#1e293b">Tot. Boarder</th>
                <th style="background:#1e293b">Tot. Cap</th>
                <th>Action</th>
            </tr>
            <tr>
                <td><input type="text" name="class_name" style="width:90px" required></td>
                <td><input type="number" name="boarders_girls" id="ag" value="0" oninput="liveCalc('a')"></td>
                <td><input type="number" name="boarders_boys" id="ab" value="0" oninput="liveCalc('a')"></td>
                <td><input type="number" name="day_scholars" id="ad" value="0" oninput="liveCalc('a')"></td>
                <td id="atb" class="sum-label">0</td>
                <td id="atc" class="capacity-label">0</td>
                <td><button class="btn add">Add</button></td>
            </tr>
        </table>
    </form>
</div>

<div class="table-responsive">
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Class</th>
                <th>Girls(B)</th>
                <th>Boys(B)</th>
                <th>Tot. Boarder</th>
                <th>Day Sch.</th>
                <th>Tot. Cap</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody>
        <%
            try {
                ps = con.prepareStatement("SELECT * FROM class_capacity ORDER BY id");
                rs = ps.executeQuery();
                while (rs.next()) {
                    int id = rs.getInt("id");
                    int g = rs.getInt("boarders_girls");
                    int b = rs.getInt("boarders_boys");
                    int ds = rs.getInt("day_scholars");
                    int tb = g + b;
                    int tc = rs.getInt("total_capacity");

                    grandGirls += g; grandBoys += b; grandBoarders += tb;
                    grandDayScholars += ds; grandCapacity += tc;
        %>
            <form method="post">
            <tr>
                <td><%= id %><input type="hidden" name="id" value="<%= id %>"></td>
                <td><strong><%= rs.getString("class_name") %></strong></td>
                <td><input type="number" name="boarders_girls" id="g_<%=id%>" value="<%= g %>" oninput="liveCalc(<%=id%>)"></td>
                <td><input type="number" name="boarders_boys" id="b_<%=id%>" value="<%= b %>" oninput="liveCalc(<%=id%>)"></td>
                <td id="tb_<%=id%>" class="sum-label"><%= tb %></td>
                <td><input type="number" name="day_scholars" id="d_<%=id%>" value="<%= ds %>" oninput="liveCalc(<%=id%>)"></td>
                <td id="tc_<%=id%>" class="capacity-label"><%= tc %></td>
                <td><button class="btn edit" name="action" value="update">Update</button></td>
            </tr>
            </form>
        <% 
                }
            } catch(Exception e) {} 
        %>
        </tbody>
        <tfoot>
            <tr class="footer-row">
                <th colspan="2">TOTAL</th>
                <th><%= grandGirls %></th>
                <th><%= grandBoys %></th>
                <th><%= grandBoarders %></th>
                <th><%= grandDayScholars %></th>
                <th style="color:#059669"><%= grandCapacity %></th>
                <th>
                    <form method="post"><input type="hidden" name="action" value="download"><button class="btn edit" style="padding:4px 8px">Excel</button></form>
                </th>
            </tr>
        </tfoot>
    </table>
</div>

<script>
function liveCalc(id) {
    const g = parseInt(document.getElementById(id === 'a' ? 'ag' : 'g_' + id).value) || 0;
    const b = parseInt(document.getElementById(id === 'a' ? 'ab' : 'b_' + id).value) || 0;
    const ds = parseInt(document.getElementById(id === 'a' ? 'ad' : 'd_' + id).value) || 0;
    const tb = g + b;
    const tc = tb + ds;
    document.getElementById(id === 'a' ? 'atb' : 'tb_' + id).innerText = tb;
    document.getElementById(id === 'a' ? 'atc' : 'tc_' + id).innerText = tc;
}
</script>

</body>
</html>