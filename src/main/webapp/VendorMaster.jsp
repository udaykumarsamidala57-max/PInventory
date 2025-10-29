<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.bean.DBUtil" %>
<%

// ---------------- SESSION & ROLE CHECK ----------------
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
String role = (String) sess.getAttribute("role");
String dept = (String) sess.getAttribute("department");
if (!"Global".equalsIgnoreCase(role)&&!"Finance".equalsIgnoreCase(dept) ) {
    out.println("<h3 style='color:red;text-align:center;'>Access Denied! You are not authorized.</h3>");
    return;
}
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Vendor Master</title>
<style>
body {
  font-family: "Segoe UI", Arial, sans-serif;
  background-color: #f5f7fa;
  margin: 0;
  padding: 0;
}

.container {
  width: 85%;
  margin: 30px auto;
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  padding: 25px 40px;
}

h2, h3 {
  color: #333;
  text-align: center;
  margin-bottom: 15px;
}

form {
  margin-bottom: 30px;
}

input[type=text], textarea, select {
  width: 100%;
  padding: 8px 10px;
  margin: 6px 0;
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 15px;
}

input[type=submit] {
  background-color: #007bff;
  color: white;
  padding: 10px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 15px;
  width: 100%;
}

input[type=submit]:hover {
  background-color: #0056b3;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
}

th {
  background-color: #007bff;
  color: white;
  padding: 10px;
  text-align: left;
}

td {
  padding: 8px;
  border-bottom: 1px solid #ddd;
}

tr:hover {
  background-color: #f1f1f1;
}

a {
  text-decoration: none;
  color: #007bff;
  font-weight: 500;
}

a:hover {
  text-decoration: underline;
}

.edit-box {
  background-color: #f8f9fa;
  border-radius: 8px;
  padding: 15px;
  margin-top: 20px;
  border: 1px solid #ddd;
}
</style>
</head>
<body>

<jsp:include page="header.jsp" />

<div class="container">
  <h2>Vendor Master</h2>

  <%
  Connection con = null;
  try {
      con = DBUtil.getConnection();

      // INSERT vendor
      if (request.getParameter("add") != null) {
          String name = request.getParameter("vendorName");
          String gstin = request.getParameter("gstin");
          String address = request.getParameter("address");
          String contact = request.getParameter("contact");
          String email = request.getParameter("email");

          PreparedStatement ps = con.prepareStatement(
              "INSERT INTO vendors(name, GSTIN, address, contact, email) VALUES (?,?,?,?,?)"
          );
          ps.setString(1, name);
          ps.setString(2, gstin);
          ps.setString(3, address);
          ps.setString(4, contact);
          ps.setString(5, email);
          ps.executeUpdate();
          ps.close();
      }

      // DELETE vendor
      if (request.getParameter("deleteId") != null) {
          int id = Integer.parseInt(request.getParameter("deleteId"));
          PreparedStatement ps = con.prepareStatement("DELETE FROM vendors WHERE id=?");
          ps.setInt(1, id);
          ps.executeUpdate();
          ps.close();
      }

      // UPDATE vendor
      if (request.getParameter("update") != null) {
          int id = Integer.parseInt(request.getParameter("id"));
          String name = request.getParameter("vendorName");
          String gstin = request.getParameter("gstin");
          String address = request.getParameter("address");
          String contact = request.getParameter("contact");
          String email = request.getParameter("email");

          PreparedStatement ps = con.prepareStatement(
              "UPDATE vendors SET name=?, GSTIN=?, address=?, contact=?, email=? WHERE id=?"
          );
          ps.setString(1, name);
          ps.setString(2, gstin);
          ps.setString(3, address);
          ps.setString(4, contact);
          ps.setString(5, email);
          ps.setInt(6, id);
          ps.executeUpdate();
          ps.close();
          response.sendRedirect("VendorMaster.jsp");
          return;
      }
  %>

  <!-- Add Vendor Form -->
  <h3>Add New Vendor</h3>
  <form method="post">
    <label>Vendor Name</label>
    <input type="text" name="vendorName" required>

    <label>GSTIN</label>
    <input type="text" name="gstin" required>

    <label>Address</label>
    <textarea name="address" required></textarea>

    <label>Contact</label>
    <input type="text" name="contact" required>

    <label>Email</label>
    <input type="text" name="email" required>

    <input type="submit" name="add" value="Add Vendor">
  </form>

  <h3>Vendor List</h3>
  <table>
    <tr>
      <th>ID</th>
      <th>Name</th>
      <th>GSTIN</th>
      <th>Address</th>
      <th>Contact</th>
      <th>Email</th>
      <th>Actions</th>
    </tr>
  <%
      Statement st = con.createStatement();
      ResultSet rs = st.executeQuery("SELECT * FROM vendors ORDER BY id DESC");
      while (rs.next()) {
  %>
    <tr>
      <td><%= rs.getInt("id") %></td>
      <td><%= rs.getString("name") %></td>
      <td><%= rs.getString("GSTIN") %></td>
      <td><%= rs.getString("address") %></td>
      <td><%= rs.getString("contact") %></td>
      <td><%= rs.getString("email") %></td>
      <td>
        <a href="VendorMaster.jsp?editId=<%= rs.getInt("id") %>">Edit</a> |
        <a href="VendorMaster.jsp?deleteId=<%= rs.getInt("id") %>" onclick="return confirm('Delete this vendor?')">Delete</a>
      </td>
    </tr>
  <%
      }
      rs.close();
      st.close();

      // Edit section
      if (request.getParameter("editId") != null) {
          int editId = Integer.parseInt(request.getParameter("editId"));
          PreparedStatement ps = con.prepareStatement("SELECT * FROM vendors WHERE id=?");
          ps.setInt(1, editId);
          ResultSet rsEdit = ps.executeQuery();
          if (rsEdit.next()) {
  %>
  <div class="edit-box">
    <h3>Edit Vendor</h3>
    <form method="post">
      <input type="hidden" name="id" value="<%= rsEdit.getInt("id") %>">

      <label>Vendor Name</label>
      <input type="text" name="vendorName" value="<%= rsEdit.getString("name") %>" required>

      <label>GSTIN</label>
      <input type="text" name="gstin" value="<%= rsEdit.getString("GSTIN") %>" required>

      <label>Address</label>
      <textarea name="address" required><%= rsEdit.getString("address") %></textarea>

      <label>Contact</label>
      <input type="text" name="contact" value="<%= rsEdit.getString("contact") %>" required>

      <label>Email</label>
      <input type="text" name="email" value="<%= rsEdit.getString("email") %>" required>

      <input type="submit" name="update" value="Update Vendor">
    </form>
  </div>
  <%
          }
          rsEdit.close();
          ps.close();
      }
  } catch (Exception e) {
      out.println("<p style='color:red;'>Error: " + e.getMessage() + "</p>");
  } finally {
      if (con != null) try { con.close(); } catch (SQLException ex) { ex.printStackTrace(); }
  }
  %>
</div>

</body>
</html>
