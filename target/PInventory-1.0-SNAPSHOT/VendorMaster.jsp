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
    if (!"Global".equalsIgnoreCase(role) && !"Finance".equalsIgnoreCase(dept)) {
        out.println("<h3 style='color:red;text-align:center;margin-top:100px;'>Access Denied! You are not authorized.</h3>");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Vendor Master</title>
<style>
/* ----------- GLOBAL DESIGN ----------- */
body {
  font-family: "Segoe UI", Arial, sans-serif;
  background-color: #f4f6fa;
  margin: 0;
  padding: 0;
}

/* ----------- MAIN CONTAINER ----------- */
.container {
  width: 85%;
  margin: 30px auto;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.08);
  padding: 40px 50px;
}

/* ----------- HEADINGS ----------- */
h2, h3 {
  text-align: center;
  color: #2c3e50;
  margin-bottom: 20px;
}

h2 {
  font-size: 26px;
  font-weight: 600;
}

h3 {
  font-size: 20px;
  margin-top: 30px;
  color: #444;
}

/* ----------- FORM DESIGN ----------- */
form {
  background: #f9fafc;
  padding: 20px 30px;
  border: 1px solid #e0e0e0;
  border-radius: 10px;
  margin-bottom: 40px;
}

label {
  font-weight: 500;
  display: block;
  margin-top: 12px;
  color: #333;
}

input[type=text], textarea {
  width: 100%;
  padding: 10px 12px;
  margin-top: 6px;
  border: 1px solid #ccc;
  border-radius: 6px;
  font-size: 15px;
  transition: 0.2s;
  background-color: #fff;
}

input[type=text]:focus, textarea:focus {
  border-color: #0d6efd;
  box-shadow: 0 0 4px rgba(13,110,253,0.3);
  outline: none;
}

textarea {
  resize: vertical;
  min-height: 60px;
}

input[type=submit] {
  background: linear-gradient(90deg, #0d6efd, #0b5ed7);
  color: white;
  border: none;
  border-radius: 6px;
  padding: 10px 12px;
  font-size: 16px;
  margin-top: 18px;
  cursor: pointer;
  transition: all 0.3s ease;
  width: 100%;
}

input[type=submit]:hover {
  background: #084298;
  box-shadow: 0 3px 6px rgba(0,0,0,0.15);
}

/* ----------- TABLE DESIGN ----------- */
table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 15px;
  font-size: 15px;
}

th {
  background-color: #0d6efd;
  color: #fff;
  padding: 10px 12px;
  text-align: left;
  font-weight: 500;
  letter-spacing: 0.3px;
}

td {
  padding: 9px 12px;
  border-bottom: 1px solid #eee;
  color: #333;
}

tr:nth-child(even) {
  background-color: #f9fbff;
}

tr:hover {
  background-color: #eef4ff;
}

/* ----------- ACTION LINKS ----------- */
a.action-link {
  color: #0d6efd;
  text-decoration: none;
  font-weight: 500;
  margin: 0 4px;
}

a.action-link:hover {
  text-decoration: underline;
}

/* ----------- EDIT BOX ----------- */
.edit-box {
  background-color: #f8f9fa;
  border-radius: 10px;
  padding: 25px 30px;
  margin-top: 25px;
  border: 1px solid #ddd;
  box-shadow: 0 2px 6px rgba(0,0,0,0.05);
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

  <!-- Vendor List Table -->
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
        <a class="action-link" href="VendorMaster.jsp?editId=<%= rs.getInt("id") %>">Edit</a> |
        <a class="action-link" href="VendorMaster.jsp?deleteId=<%= rs.getInt("id") %>" onclick="return confirm('Delete this vendor?')">Delete</a>
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
