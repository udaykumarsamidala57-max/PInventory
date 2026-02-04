<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.bean.DBUtil" %>
<%
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

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: #eef2f7;
    margin: 0;
    padding: 0;
    color: #333;
}

.container {
    max-width: 1200px;
    margin: 40px auto;
    padding: 20px 30px;
}


h2 {
    text-align: center;
    font-size: 28px;
    font-weight: 600;
    color: #0d6efd;
    margin-bottom: 30px;
}

h3 {
    font-size: 20px;
    color: #555;
    margin-bottom: 20px;
}


.form-card, .edit-box {
    background: #fff;
    padding: 25px 30px;
    border-radius: 12px;
    box-shadow: 0 4px 15px rgba(0,0,0,0.1);
    margin-bottom: 40px;
}

.form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px 30px;
}

.form-grid label {
    display: block;
    font-weight: 500;
    margin-bottom: 5px;
    font-size: 14px;
}

.form-grid input[type=text],
.form-grid textarea {
    width: 100%;
    padding: 10px 12px;
    border: 1px solid #ccc;
    border-radius: 8px;
    font-size: 14px;
    transition: all 0.2s ease;
}

.form-grid input[type=text]:focus,
.form-grid textarea:focus {
    border-color: #0d6efd;
    box-shadow: 0 0 5px rgba(13,110,253,0.3);
    outline: none;
}

textarea {
    resize: vertical;
    min-height: 70px;
}

input[type=submit] {
    background: linear-gradient(90deg, #0d6efd, #0b5ed7);
    color: #fff;
    font-size: 15px;
    font-weight: 500;
    border: none;
    border-radius: 8px;
    padding: 12px;
    margin-top: 20px;
    cursor: pointer;
    transition: all 0.3s ease;
}

input[type=submit]:hover {
    background: #084298;
    box-shadow: 0 4px 12px rgba(0,0,0,0.2);
}


#searchInput {
    padding: 8px 12px; 
    border-radius: 8px; 
    border: 1px solid #ccc; 
    width: 250px;
    font-size: 14px;
    margin-bottom: 15px;
    float: right;
}


.table-box {
    overflow-x: 85%;
    background: #fff;
    border-radius: 12px;
    box-shadow: 0 4px 15px rgba(0,0,0,0.05);
    padding: 20px;
}

table {
    width: 100%;
    border-collapse: collapse;
    font-size: 14px;
}

th, td {
    padding: 12px 15px;
    text-align: left;
    vertical-align: middle;
}

th {
    background: linear-gradient(90deg, #0d6efd, #0b5ed7);
    color: #fff;
    font-weight: 600;
}

tr:nth-child(even) {
    background-color: #f8f9fa;
}

tr:hover {
    background-color: #e2e6f0;
}

a.action-link {
    color: #0d6efd;
    font-weight: 500;
    text-decoration: none;
    margin-right: 10px;
}

a.action-link:hover {
    text-decoration: underline;
}


@media (max-width: 768px) {
    .form-grid {
        grid-template-columns: 1fr;
    }
    #searchInput {
        width: 100%;
        margin-bottom: 20px;
        float: none;
    }
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

      
      if (request.getParameter("deleteId") != null) {
          int id = Integer.parseInt(request.getParameter("deleteId"));
          PreparedStatement ps = con.prepareStatement("DELETE FROM vendors WHERE id=?");
          ps.setInt(1, id);
          ps.executeUpdate();
          ps.close();
      }

    
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

  
  <div class="form-card">
  <br><br><br>
    <h3>Add New Vendor</h3>
    <form method="post" class="form-grid">
      <div>
        <label>Vendor Name</label>
        <input type="text" name="vendorName" placeholder="Enter vendor name" required>
      </div>
      <div>
        <label>GSTIN</label>
        <input type="text" name="gstin" placeholder="Enter GSTIN" required>
      </div>
      <div>
        <label>Contact</label>
        <input type="text" name="contact" placeholder="Enter contact number" required>
      </div>
      <div>
        <label>Email</label>
        <input type="text" name="email" placeholder="Enter email address" required>
      </div>
      <div style="grid-column: span 2;">
        <label>Address</label>
        <textarea name="address" placeholder="Enter address" required></textarea>
      </div>
      <div style="grid-column: span 2;">
        <input type="submit" name="add" value="Add Vendor">
      </div>
    </form>
  </div>

 
  <h3>Vendor List</h3>

 
  <input type="text" id="searchInput" placeholder="Search vendors...">
<br>
<br>
  <div class="table-box">
    <table id="vendorTable">
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
          <a class="action-link" href="VendorMaster.jsp?editId=<%= rs.getInt("id") %>">Edit</a>
          <a class="action-link" href="VendorMaster.jsp?deleteId=<%= rs.getInt("id") %>" onclick="return confirm('Delete this vendor?')">Delete</a>
        </td>
      </tr>
  <%
      }
      rs.close();
      st.close();

     
      if (request.getParameter("editId") != null) {
          int editId = Integer.parseInt(request.getParameter("editId"));
          PreparedStatement ps = con.prepareStatement("SELECT * FROM vendors WHERE id=?");
          ps.setInt(1, editId);
          ResultSet rsEdit = ps.executeQuery();
          if (rsEdit.next()) {
  %>
  <div class="edit-box">
    <h3>Edit Vendor</h3>
    <form method="post" class="form-grid">
      <input type="hidden" name="id" value="<%= rsEdit.getInt("id") %>">

      <div>
        <label>Vendor Name</label>
        <input type="text" name="vendorName" value="<%= rsEdit.getString("name") %>" required>
      </div>
      <div>
        <label>GSTIN</label>
        <input type="text" name="gstin" value="<%= rsEdit.getString("GSTIN") %>" required>
      </div>
      <div>
        <label>Contact</label>
        <input type="text" name="contact" value="<%= rsEdit.getString("contact") %>" required>
      </div>
      <div>
        <label>Email</label>
        <input type="text" name="email" value="<%= rsEdit.getString("email") %>" required>
      </div>
      <div style="grid-column: span 2;">
        <label>Address</label>
        <textarea name="address" required><%= rsEdit.getString("address") %></textarea>
      </div>
      <div style="grid-column: span 2;">
        <input type="submit" name="update" value="Update Vendor">
      </div>
    </form>
  </div>
  <%
          }
          rsEdit.close();
          ps.close();
      }
  } catch (Exception e) {
      out.println("<p style='color:red; text-align:center;'>Error: " + e.getMessage() + "</p>");
  } finally {
      if (con != null) try { con.close(); } catch (SQLException ex) { ex.printStackTrace(); }
  }
  %>
    </table>
  </div>
</div>


<script>
document.getElementById('searchInput').addEventListener('keyup', function() {
    let filter = this.value.toLowerCase();
    let rows = document.querySelectorAll('#vendorTable tr:not(:first-child)');
    
    rows.forEach(row => {
        let cells = row.querySelectorAll('td');
        let match = false;
        cells.forEach(cell => {
            if(cell.textContent.toLowerCase().includes(filter)) {
                match = true;
            }
        });
        row.style.display = match ? '' : 'none';
    });
});
</script>

</body>
</html>
