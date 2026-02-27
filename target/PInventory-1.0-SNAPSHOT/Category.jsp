<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page session="true" %>
<%
    
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String role = (String) sess.getAttribute("role");
    String dept = (String) sess.getAttribute("department");

    
    if ("Global".equalsIgnoreCase(role)) {
        out.println("<h3 style='color:red;text-align:center;margin-top:30px;'>Access Denied! You are not authorized to view this page.</h3>");
        return;
    }

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        con = DBUtil.getConnection();
    } catch (Exception e) {
        out.println("Database Connection Error: " + e);
    }

    
    String action = request.getParameter("action");
    if ("insert".equals(action)) {
        String category = request.getParameter("category");
        String subCategory = request.getParameter("sub_category");
        String department = request.getParameter("department");
        ps = con.prepareStatement("INSERT INTO category(Category, Sub_Category, Status, department) VALUES(?,?,?,?)");
        ps.setString(1, category);
        ps.setString(2, subCategory);
        ps.setString(3, "Active");
        ps.setString(4, department);
        ps.executeUpdate();
    } else if ("update".equals(action)) {
        int id = Integer.parseInt(request.getParameter("id"));
        String category = request.getParameter("category");
        String subCategory = request.getParameter("sub_category");
        String department = request.getParameter("department");
        String status = request.getParameter("status");
        ps = con.prepareStatement("UPDATE category SET Category=?, Sub_Category=?, Status=?, department=? WHERE Category_id=?");
        ps.setString(1, category);
        ps.setString(2, subCategory);
        ps.setString(3, status);
        ps.setString(4, department);
        ps.setInt(5, id);
        ps.executeUpdate();
    } else if ("delete".equals(action)) {
        int id = Integer.parseInt(request.getParameter("id"));
        ps = con.prepareStatement("DELETE FROM category WHERE Category_id=?");
        ps.setInt(1, id);
        ps.executeUpdate();
    }


    String mapAction = request.getParameter("mapAction");
    if ("insertMap".equals(mapAction)) {
        String deptName = request.getParameter("dept");
        String cate = request.getParameter("cate");
        String mapRole = request.getParameter("role");
        ps = con.prepareStatement("INSERT INTO dept_cate(Department, Category, role) VALUES(?,?,?)");
        ps.setString(1, deptName);
        ps.setString(2, cate);
        ps.setString(3, mapRole);
        ps.executeUpdate();
    } else if ("updateMap".equals(mapAction)) {
        int mapId = Integer.parseInt(request.getParameter("mapId"));
        String deptName = request.getParameter("dept");
        String cate = request.getParameter("cate");
        String mapRole = request.getParameter("role");
        ps = con.prepareStatement("UPDATE dept_cate SET Department=?, Category=?, role=? WHERE id=?");
        ps.setString(1, deptName);
        ps.setString(2, cate);
        ps.setString(3, mapRole);
        ps.setInt(4, mapId);
        ps.executeUpdate();
    } else if ("deleteMap".equals(mapAction)) {
        int mapId = Integer.parseInt(request.getParameter("mapId"));
        ps = con.prepareStatement("DELETE FROM dept_cate WHERE id=?");
        ps.setInt(1, mapId);
        ps.executeUpdate();
    }
%>

<html>
<head>
    <title>Category & Dept–Category Mapping Management</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <!-- ✅ jQuery + DataTables -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js"></script>
    <link rel="stylesheet" href="https://cdn.datatables.net/1.13.6/css/jquery.dataTables.min.css">

    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f3f6fa;
            padding: 20px;
        }
        h2 {
            text-align: center;
            color: #007bff;
        }
        .container {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
        }
        .half {
            flex: 1;
            background: #fff;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.15);
            min-width: 450px;
        }
        .form-box {
            margin-bottom: 20px;
        }
        .form-box input[type="text"], .form-box input[type="submit"] {
            padding: 8px;
            margin: 5px 0;
            width: 95%;
            border: 1px solid #ccc;
            border-radius: 5px;
        }
        .form-box input[type="submit"] {
            background: #007BFF;
            color: white;
            border: none;
            cursor: pointer;
            font-weight: bold;
        }
        .form-box input[type="submit"]:hover {
            background: #0056b3;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            font-size: 14px;
        }
        table th, table td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: center;
        }
        table th {
            background: #007BFF;
            color: white;
            cursor: pointer;
        }
        .action-btn {
            padding: 5px 10px;
            border-radius: 5px;
            border: none;
            cursor: pointer;
            font-size: 13px;
        }
        .update-btn { background: #28a745; color: white; }
        .delete-btn { background: #dc3545; color: white; }
        .searchBox {
            margin-bottom: 10px;
            padding: 8px;
            width: 95%;
            border-radius: 5px;
            border: 1px solid #ccc;
        }
    </style>

    <script>
        function sortTable(colIndex) {
            let table = document.getElementById("categoryTable");
            let rows = Array.from(table.rows).slice(1);
            rows.sort((a, b) => {
                let x = a.cells[colIndex].innerText.toLowerCase();
                let y = b.cells[colIndex].innerText.toLowerCase();
                return x.localeCompare(y, 'en', { numeric: true });
            });
            rows.forEach(r => table.appendChild(r));
        }

        $(document).ready(function() {
            $('#categoryTable').DataTable();
            $('#mappingTable').DataTable();
        });
    </script>
</head>
<body>

<h2>Category & Dept–Category Mapping Management</h2>

<div class="container">
    <!-- ---------- Category Section ---------- -->
    <div class="half">
        <h3>Category Management</h3>
        <div class="form-box">
            <form method="post">
                <input type="hidden" name="action" value="insert">
                <input type="text" name="category" placeholder="Category" required><br>
                <input type="text" name="sub_category" placeholder="Sub Category" required><br>
                <input type="text" name="department" placeholder="Department" required><br>
                <input type="submit" value="Add Category">
            </form>
        </div>

        <h3>Category Records</h3>
        <input type="text" id="searchBox" class="searchBox" placeholder="Search..." onkeyup="searchTable()">

        <table id="categoryTable">
            <thead>
                <tr>
                    <th onclick="sortTable(0)">ID</th>
                    <th onclick="sortTable(1)">Category</th>
                    <th onclick="sortTable(2)">Sub Category</th>
                    <th onclick="sortTable(3)">Status</th>
                    <th onclick="sortTable(4)">Department</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <%
                    ps = con.prepareStatement("SELECT * FROM category");
                    rs = ps.executeQuery();
                    while (rs.next()) {
                        int id = rs.getInt("Category_id");
                %>
                <tr>
                    <form method="post">
                        <td><%= id %><input type="hidden" name="id" value="<%= id %>"></td>
                        <td><input type="text" name="category" value="<%= rs.getString("Category") %>"></td>
                        <td><input type="text" name="sub_category" value="<%= rs.getString("Sub_Category") %>"></td>
                        <td><input type="text" name="status" value="<%= rs.getString("Status") %>"></td>
                        <td><input type="text" name="department" value="<%= rs.getString("department") %>"></td>
                        <td>
                            <input type="hidden" name="action" value="update">
                            <input type="submit" class="action-btn update-btn" value="Update">
                    </form>
                    <form method="post" style="display:inline;">
                        <input type="hidden" name="id" value="<%= id %>">
                        <input type="hidden" name="action" value="delete">
                        <input type="submit" class="action-btn delete-btn" value="Delete" onclick="return confirm('Delete this record?');">
                    </form>
                        </td>
                </tr>
                <%
                    }
                %>
            </tbody>
        </table>
    </div>

    <!-- ---------- Mapping Section ---------- -->
    <div class="half">
        <h3>Dept–Category Mapping</h3>
        <div class="form-box">
            <form method="post">
                <input type="hidden" name="mapAction" value="insertMap">
                <input type="text" name="dept" placeholder="Department" required><br>
                <input type="text" name="cate" placeholder="Category" required><br>
                <input type="text" name="role" placeholder="Role" required><br>
                <input type="submit" value="Add Mapping">
            </form>
        </div>

        <h3>Mapping Records</h3>
        <table id="mappingTable">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Department</th>
                    <th>Category</th>
                    <th>Role</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <%
                    ps = con.prepareStatement("SELECT * FROM dept_cate");
                    rs = ps.executeQuery();
                    while (rs.next()) {
                        int mapId = rs.getInt("id");
                %>
                <tr>
                    <form method="post">
                        <td><%= mapId %><input type="hidden" name="mapId" value="<%= mapId %>"></td>
                        <td><input type="text" name="dept" value="<%= rs.getString("Department") %>"></td>
                        <td><input type="text" name="cate" value="<%= rs.getString("Category") %>"></td>
                        <td><input type="text" name="role" value="<%= rs.getString("role") %>"></td>
                        <td>
                            <input type="hidden" name="mapAction" value="updateMap">
                            <input type="submit" class="action-btn update-btn" value="Update">
                    </form>
                    <form method="post" style="display:inline;">
                        <input type="hidden" name="mapId" value="<%= mapId %>">
                        <input type="hidden" name="mapAction" value="deleteMap">
                        <input type="submit" class="action-btn delete-btn" value="Delete" onclick="return confirm('Delete this mapping?');">
                    </form>
                        </td>
                </tr>
                <%
                    }
                %>
            </tbody>
        </table>
    </div>
</div>

<%
    // Close resources
    if (rs != null) try { rs.close(); } catch(Exception e) {}
    if (ps != null) try { ps.close(); } catch(Exception e) {}
    if (con != null) try { con.close(); } catch(Exception e) {}
%>

</body>
</html>
