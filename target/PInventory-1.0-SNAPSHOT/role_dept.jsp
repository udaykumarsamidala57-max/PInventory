<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="com.bean.DBUtil" %>

<%
    String action = request.getParameter("action");
    String id = request.getParameter("id");
    String role = request.getParameter("role");
    String dept = request.getParameter("dept");

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DBUtil.getConnection();

        if ("add".equals(action)) {
            ps = con.prepareStatement("INSERT INTO role_dept (Role, Department) VALUES (?, ?)");
            ps.setString(1, role);
            ps.setString(2, dept);
            ps.executeUpdate();
        } else if ("update".equals(action) && id != null) {
            ps = con.prepareStatement("UPDATE role_dept SET Role=?, Department=? WHERE no=?");
            ps.setString(1, role);
            ps.setString(2, dept);
            ps.setInt(3, Integer.parseInt(id));
            ps.executeUpdate();
        } else if ("delete".equals(action) && id != null) {
            ps = con.prepareStatement("DELETE FROM role_dept WHERE no=?");
            ps.setInt(1, Integer.parseInt(id));
            ps.executeUpdate();
        }

        // fetch all records
        ps = con.prepareStatement("SELECT * FROM role_dept ORDER BY no DESC");
        rs = ps.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
    <title>Role & Department Management</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
</head>
<body class="bg-light">

<div class="container mt-5">
    <h2 class="text-center mb-4">Role & Department Management</h2>

    <!-- Add New -->
    <div class="card shadow p-4 mb-4">
        <h5>Add New Role & Department</h5>
        <form method="post" action="role_dept.jsp">
            <input type="hidden" name="action" value="add">
            <div class="row">
                <div class="col-md-4">
                    <input type="text" name="role" class="form-control" placeholder="Role" required>
                </div>
                <div class="col-md-4">
                    <input type="text" name="dept" class="form-control" placeholder="Department" required>
                </div>
                <div class="col-md-4">
                    <button type="submit" class="btn btn-success">Add</button>
                </div>
            </div>
        </form>
    </div>

    <!-- Display Table -->
    <div class="card shadow p-3">
        <h5>Existing Roles & Departments</h5>
        <table class="table table-bordered table-striped text-center mt-3">
            <thead class="table-dark">
                <tr>
                    <th>ID</th>
                    <th>Role</th>
                    <th>Department</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
            <%
                while (rs.next()) {
            %>
                <tr>
                    <td><%= rs.getInt("no") %></td>
                    <td><%= rs.getString("Role") %></td>
                    <td><%= rs.getString("Department") %></td>
                    <td>
                        <!-- Edit form inline -->
                        <form action="role_dept.jsp" method="post" style="display:inline-block;">
                            <input type="hidden" name="id" value="<%= rs.getInt("no") %>">
                            <input type="hidden" name="action" value="update">
                            <input type="text" name="role" value="<%= rs.getString("Role") %>" required>
                            <input type="text" name="dept" value="<%= rs.getString("Department") %>" required>
                            <button type="submit" class="btn btn-primary btn-sm">Update</button>
                        </form>
                        
                        <!-- Delete -->
                        <a href="role_dept.jsp?action=delete&id=<%= rs.getInt("no") %>" 
                           class="btn btn-danger btn-sm"
                           onclick="return confirm('Are you sure you want to delete this record?');">
                           Delete
                        </a>
                    </td>
                </tr>
            <%
                }
            %>
            </tbody>
        </table>
    </div>
</div>

</body>
</html>

<%
    } catch (Exception e) {
        out.println("<p style='color:red'>Error: " + e.getMessage() + "</p>");
    } finally {
        if (rs != null) rs.close();
        if (ps != null) ps.close();
        if (con != null) con.close();
    }
%>
