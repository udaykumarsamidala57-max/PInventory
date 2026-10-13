<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil3" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String role = (String) sess.getAttribute("role");
    String User = (String) sess.getAttribute("username");
%>
<%
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    
    if (request.getParameter("submit") != null) {

        int classId = Integer.parseInt(request.getParameter("class_id"));
        String examName = request.getParameter("exam_name");
        int maxMarks = Integer.parseInt(request.getParameter("max_marks"));

        try {
            con = DBUtil3.getConnection();

            ps = con.prepareStatement(
                "INSERT INTO class_exams(class_id, exam_name, max_marks) VALUES (?, ?, ?)"
            );
            ps.setInt(1, classId);
            ps.setString(2, examName);
            ps.setInt(3, maxMarks);
            ps.executeUpdate();

            out.println("<p style='color:green'>Exam Added Successfully</p>");

        } catch (Exception e) {
            out.println("<p style='color:red'>" + e.getMessage() + "</p>");
        } finally {
            if (ps != null) ps.close();
            if (con != null) con.close();
        }
    }
%>

<html>
<head>
    <title>Create Exams</title>
</head>
<body>

<h2>Create Admission Exams</h2>

<form method="post">
    Class:
    <select name="class_id" required>
        <option value="">-- Select Class --</option>
        <%
            try {
                con = DBUtil3.getConnection();
                ps = con.prepareStatement("SELECT * FROM classes");
                rs = ps.executeQuery();

                while (rs.next()) {
        %>
            <option value="<%= rs.getInt("class_id") %>">
                <%= rs.getString("class_name") %>
            </option>
        <%
                }
            } catch (Exception e) {
                out.println(e.getMessage());
            } finally {
                if (rs != null) rs.close();
                if (ps != null) ps.close();
                if (con != null) con.close();
            }
        %>
    </select>

    <br><br>

    Exam Name:
    <input type="text" name="exam_name" required>

    <br><br>

    Max Marks:
    <input type="number" name="max_marks" required>

    <br><br>

    <input type="submit" name="submit" value="Add Exam">
</form>

<hr>

<h3>Existing Exams</h3>

<table border="1" cellpadding="8">
    <tr>
        <th>Class</th>
        <th>Exam</th>
        <th>Max Marks</th>
    </tr>

<%
    try {
        con = DBUtil3.getConnection();
        ps = con.prepareStatement(
            "SELECT c.class_name, e.exam_name, e.max_marks " +
            "FROM class_exams e JOIN classes c ON e.class_id = c.class_id"
        );
        rs = ps.executeQuery();

        while (rs.next()) {
%>
    <tr>
        <td><%= rs.getString("class_name") %></td>
        <td><%= rs.getString("exam_name") %></td>
        <td><%= rs.getInt("max_marks") %></td>
    </tr>
<%
        }
    } catch (Exception e) {
        out.println(e.getMessage());
    } finally {
        if (rs != null) rs.close();
        if (ps != null) ps.close();
        if (con != null) con.close();
    }
%>

</table>

</body>
</html>
