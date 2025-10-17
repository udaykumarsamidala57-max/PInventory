<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil" %>
<%
    // ---------- Database Connection ----------
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DBUtil.getConnection();
    } catch(Exception e) {
        out.println("DB Connection Error: " + e);
    }

    // ---------- Handle Category CRUD ----------
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
    } 
    else if ("update".equals(action)) {
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
    }
    else if ("delete".equals(action)) {
        int id = Integer.parseInt(request.getParameter("id"));
        ps = con.prepareStatement("DELETE FROM category WHERE Category_id=?");
        ps.setInt(1, id);
        ps.executeUpdate();
    }

    // ---------- Handle Dept–Category CRUD ----------
    String mapAction = request.getParameter("mapAction");
    if ("insertMap".equals(mapAction)) {
        String dept = request.getParameter("dept");
        String cate = request.getParameter("cate");
        String role =  request.getParameter("role");
        ps = con.prepareStatement("INSERT INTO dept_cate(Department, Category,role) VALUES(?,?,?)");
        ps.setString(1, dept);
        ps.setString(2, cate);
        ps.setString(3, role);
        ps.executeUpdate();
    }
    else if ("updateMap".equals(mapAction)) {
        int mapId = Integer.parseInt(request.getParameter("mapId"));
        String dept = request.getParameter("dept");
        String cate = request.getParameter("cate");
        String role =  request.getParameter("role");
        ps = con.prepareStatement("UPDATE dept_cate SET Department=?, Category=?, role=? WHERE id=?");
        ps.setString(1, dept);
        ps.setString(2, cate);
        ps.setString(3,role);
        ps.setInt(4, mapId);
        ps.executeUpdate();
    }
    else if ("deleteMap".equals(mapAction)) {
        int mapId = Integer.parseInt(request.getParameter("mapId"));
        ps = con.prepareStatement("DELETE FROM dept_cate WHERE id=?");
        ps.setInt(1, mapId);
        ps.executeUpdate();
    }
%>

<html>
<head>
    <title>Category & Mapping Management</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f9f9f9;
            padding: 20px;
        }
        h2 {
            text-align: center;
            margin-bottom: 20px;
        }
        .container {
            display: flex;
            gap: 20px;
        }
        .half {
            flex: 1;
            background: #fff;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.1);
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
        }
        .form-box input[type="submit"]:hover {
            background: #0056b3;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            background: #fff;
            box-shadow: 0 2px 6px rgba(0,0,0,0.1);
        }
        table th, table td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: center;
        }
        table th {
            background: #007BFF;
            color: white;
        }
        .action-btn {
            padding: 5px 10px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        .update-btn {
            background: #28a745;
            color: white;
        }
        .delete-btn {
            background: #dc3545;
            color: white;
        }
    </style>
 <script>
function sortTable(colIndex) {
  let table = document.getElementById("itemsTable");
  let rows = Array.from(table.rows).slice(1); // skip header

  rows.sort((a, b) => {
    let xCell = a.cells[colIndex];
    let yCell = b.cells[colIndex];

    // get text from input if present, else innerText
    let x = xCell.querySelector("input") ? xCell.querySelector("input").value.toLowerCase() : xCell.innerText.toLowerCase();
    let y = yCell.querySelector("input") ? yCell.querySelector("input").value.toLowerCase() : yCell.innerText.toLowerCase();

    return x.localeCompare(y, 'en', {numeric: true});
  });

  rows.forEach(r => table.appendChild(r)); // re-attach in sorted order
}
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
        <input type="text" id="searchBox" placeholder="Search..." onkeyup="searchTable()">
        
        <table id="itemsTable">
            <tr>
                <th onclick="sortTable(0)">ID </th>
                <th onclick="sortTable(1)">Category</th>
                <th onclick="sortTable(2)">Sub Category</th>
                <th onclick="sortTable(3)">Status</th>
                <th onclick="sortTable(4)">Department</th>
                <th onclick="sortTable(5)">Actions</th>
            </tr>
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
                <input type="text" name="role" placeholder="role" required><br>
                <input type="submit" value="Add Mapping">
            </form>
        </div>

        <h3>Mapping Records</h3>
        <table>
            <tr>
                <th>ID</th><th>Department</th><th>Category</th><th>Role</th><th>Actions</th>
            </tr>
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
        </table>
    </div>
</div>
<script>
$(document).ready(function() {
    $('#categoryTable').DataTable();
    $('#mappingTable').DataTable();
});
</script>
</body>
</html>
