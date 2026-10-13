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
    String branch = (String) sess.getAttribute("branch");
    if (!"Global".equalsIgnoreCase(role) && !"Finance".equalsIgnoreCase(dept)) {
        out.println("<h3 style='color:#ba0517;text-align:center;margin-top:100px;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto;'>Access Denied! You are not authorized to view this resource.</h3>");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Vendor Master </title>
<style>
    /* Salesforce SLDS Core Variables & Base Styling */
    :root {
        --slds-brand: #0176D3;
        --slds-brand-hover: #014486;
        --slds-bg-app: #F3F3F9;
        --slds-bg-card: #FFFFFF;
        --slds-text-main: #181818;
        --slds-text-sub: #444444;
        --slds-text-muted: #747474;
        --slds-border: #DDDBDA;
        --slds-border-radius: 4px;
        --slds-font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    }

    * {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
    }

    body {
        font-family: var(--slds-font-family);
        background-color: var(--slds-bg-app);
        color: var(--slds-text-main);
        font-size: 13px;
        line-height: 1.5;
        padding-bottom: 40px;
    }

    .slds-container {
        max-width: 1320px;
        margin: 20px auto;
        padding: 0 20px;
    }

    /* Page Header Card */
    .slds-page-header {
        background-color: var(--slds-bg-card);
        border: 1px solid var(--slds-border);
        border-radius: var(--slds-border-radius);
        padding: 16px 24px;
        margin-bottom: 16px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 16px;
    }

    .slds-page-header__title {
        font-size: 18px;
        font-weight: 700;
        color: #080707;
        display: flex;
        align-items: center;
        gap: 8px;
    }

    .slds-page-header__subtitle {
        font-size: 12px;
        color: var(--slds-text-muted);
        margin-top: 2px;
    }

    /* Input Controls & Search Bar */
    .slds-search-input {
        width: 280px;
        padding: 7px 12px;
        font-size: 13px;
        border: 1px solid var(--slds-border);
        border-radius: var(--slds-border-radius);
        background-color: #FFFFFF;
        outline: none;
        transition: border-color 0.15s ease, box-shadow 0.15s ease;
    }

    .slds-search-input:focus {
        border-color: var(--slds-brand);
        box-shadow: 0 0 3px rgba(1, 118, 211, 0.5);
    }

    /* Cards */
    .slds-card {
        background-color: var(--slds-bg-card);
        border: 1px solid var(--slds-border);
        border-radius: var(--slds-border-radius);
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.02);
        margin-bottom: 16px;
        overflow: hidden;
    }

    .slds-card__header {
        padding: 14px 20px;
        border-bottom: 1px solid var(--slds-border);
        background-color: #FAFAFA;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .slds-card__header h3 {
        font-size: 14px;
        font-weight: 600;
        color: var(--slds-text-sub);
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }

    .slds-card__body {
        padding: 20px;
    }

    /* Form Design */
    .slds-form-grid {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 16px 24px;
    }

    .slds-form-element {
        display: flex;
        flex-direction: column;
    }

    .slds-form-element--full {
        grid-column: span 2;
    }

    .slds-form-element__label {
        font-size: 12px;
        font-weight: 600;
        color: var(--slds-text-sub);
        margin-bottom: 4px;
    }

    .slds-form-element__label .required {
        color: #ba0517;
        margin-left: 2px;
    }

    .slds-input, .slds-textarea {
        width: 100%;
        padding: 8px 12px;
        font-size: 13px;
        font-family: inherit;
        color: var(--slds-text-main);
        border: 1px solid var(--slds-border);
        border-radius: var(--slds-border-radius);
        outline: none;
        transition: all 0.15s ease-in-out;
    }

    .slds-textarea {
        resize: vertical;
        min-height: 72px;
    }

    .slds-input:focus, .slds-textarea:focus {
        border-color: var(--slds-brand);
        box-shadow: 0 0 0 1px var(--slds-brand);
    }

    /* Buttons */
    .slds-button {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        padding: 8px 16px;
        font-size: 13px;
        font-weight: 600;
        border-radius: var(--slds-border-radius);
        border: 1px solid transparent;
        cursor: pointer;
        transition: background-color 0.15s ease, border-color 0.15s ease;
        text-decoration: none;
    }

    .slds-button--brand {
        background-color: var(--slds-brand);
        color: #FFFFFF;
    }

    .slds-button--brand:hover {
        background-color: var(--slds-brand-hover);
    }

    .slds-button--neutral {
        background-color: #FFFFFF;
        border-color: var(--slds-border);
        color: var(--slds-brand);
    }

    .slds-button--neutral:hover {
        background-color: #F3F3F9;
    }

    /* SLDS Data Table */
    .slds-table-container {
        overflow-x: auto;
    }

    .slds-table {
        width: 100%;
        border-collapse: collapse;
        text-align: left;
    }

    .slds-table th {
        background-color: #FAFAFA;
        color: var(--slds-text-sub);
        font-size: 11px;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        padding: 10px 16px;
        border-bottom: 2px solid var(--slds-border);
        white-space: nowrap;
    }

    .slds-table td {
        padding: 12px 16px;
        border-bottom: 1px solid var(--slds-border);
        color: var(--slds-text-main);
        vertical-align: middle;
    }

    .slds-table tbody tr:hover {
        background-color: #F3F3F9;
    }

    .slds-badge {
        display: inline-block;
        padding: 2px 8px;
        font-size: 11px;
        font-weight: 600;
        border-radius: 12px;
        background-color: #E0E5EE;
        color: #444444;
    }

    .action-link {
        color: var(--slds-brand);
        font-weight: 600;
        text-decoration: none;
        margin-right: 12px;
    }

    .action-link:hover {
        text-decoration: underline;
    }

    .action-link--delete {
        color: #ba0517;
    }

    @media (max-width: 768px) {
        .slds-form-grid {
            grid-template-columns: 1fr;
        }
        .slds-form-element--full {
            grid-column: span 1;
        }
        .slds-search-input {
            width: 100%;
        }
    }
</style>
</head>
<body>

<jsp:include page="header.jsp" />

<div class="slds-container">

  <%
  Connection con = null;
  try {
      con = DBUtil.getConnection(branch);

      // --- ACTION: INSERT VENDOR ---
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
          response.sendRedirect("VendorMaster.jsp");
          return;
      }

      // --- ACTION: DELETE VENDOR ---
      if (request.getParameter("deleteId") != null) {
          int id = Integer.parseInt(request.getParameter("deleteId"));
          PreparedStatement ps = con.prepareStatement("DELETE FROM vendors WHERE id=?");
          ps.setInt(1, id);
          ps.executeUpdate();
          ps.close();
          response.sendRedirect("VendorMaster.jsp");
          return;
      }

      // --- ACTION: UPDATE VENDOR ---
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

  <!-- PAGE HEADER BAR -->
  <div class="slds-page-header">
    <div>
      <h2 class="slds-page-header__title">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#0176D3" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
        Vendor Master
      </h2>
      <p class="slds-page-header__subtitle">Manage Vendors</p>
    </div>
    <div style="display: flex; gap: 10px; align-items: center;">
      <input type="text" id="searchInput" class="slds-search-input" placeholder="Search vendors...">
      <button class="slds-button slds-button--brand" onclick="toggleAddCard()">+ New Vendor</button>
    </div>
  </div>

  <!-- EDIT VENDOR FORM CARD (Conditional Display) -->
  <%
      if (request.getParameter("editId") != null) {
          int editId = Integer.parseInt(request.getParameter("editId"));
          PreparedStatement psEdit = con.prepareStatement("SELECT * FROM vendors WHERE id=?");
          psEdit.setInt(1, editId);
          ResultSet rsEdit = psEdit.executeQuery();
          if (rsEdit.next()) {
  %>
  <div class="slds-card" id="editVendorCard">
    <div class="slds-card__header">
      <h3>Edit Vendor Records (ID: <%= rsEdit.getInt("id") %>)</h3>
      <a href="VendorMaster.jsp" class="slds-button slds-button--neutral" style="padding: 4px 10px; font-size: 11px;">Cancel</a>
    </div>
    <div class="slds-card__body">
      <form method="post" class="slds-form-grid">
        <input type="hidden" name="id" value="<%= rsEdit.getInt("id") %>">

        <div class="slds-form-element">
          <label class="slds-form-element__label">Vendor Name <span class="required">*</span></label>
          <input type="text" name="vendorName" class="slds-input" value="<%= rsEdit.getString("name") %>" required>
        </div>
        <div class="slds-form-element">
          <label class="slds-form-element__label">GSTIN <span class="required">*</span></label>
          <input type="text" name="gstin" class="slds-input" value="<%= rsEdit.getString("GSTIN") %>" required>
        </div>
        <div class="slds-form-element">
          <label class="slds-form-element__label">Contact Number <span class="required">*</span></label>
          <input type="text" name="contact" class="slds-input" value="<%= rsEdit.getString("contact") %>" required>
        </div>
        <div class="slds-form-element">
          <label class="slds-form-element__label">Email Address <span class="required">*</span></label>
          <input type="email" name="email" class="slds-input" value="<%= rsEdit.getString("email") %>" required>
        </div>
        <div class="slds-form-element slds-form-element--full">
          <label class="slds-form-element__label">Address <span class="required">*</span></label>
          <textarea name="address" class="slds-textarea" required><%= rsEdit.getString("address") %></textarea>
        </div>
        <div class="slds-form-element slds-form-element--full" style="display: flex; gap: 8px;">
          <input type="submit" name="update" value="Save Changes" class="slds-button slds-button--brand">
          <a href="VendorMaster.jsp" class="slds-button slds-button--neutral">Cancel</a>
        </div>
      </form>
    </div>
  </div>
  <%
          }
          rsEdit.close();
          psEdit.close();
      }
  %>

  <!-- ADD VENDOR FORM CARD -->
  <div class="slds-card" id="addVendorCard" style="<%= (request.getParameter("editId") != null) ? "display:none;" : "" %>">
    <div class="slds-card__header">
      <h3>Add New Vendor</h3>
    </div>
    <div class="slds-card__body">
      <form method="post" class="slds-form-grid">
        <div class="slds-form-element">
          <label class="slds-form-element__label">Vendor Name <span class="required">*</span></label>
          <input type="text" name="vendorName" class="slds-input" placeholder="e.g. Acme Corporation" required>
        </div>
        <div class="slds-form-element">
          <label class="slds-form-element__label">GSTIN <span class="required">*</span></label>
          <input type="text" name="gstin" class="slds-input" placeholder="22AAAAA0000A1Z5" required>
        </div>
        <div class="slds-form-element">
          <label class="slds-form-element__label">Contact Number <span class="required">*</span></label>
          <input type="text" name="contact" class="slds-input" placeholder="+91 00000 00000" required>
        </div>
        <div class="slds-form-element">
          <label class="slds-form-element__label">Email Address <span class="required">*</span></label>
          <input type="email" name="email" class="slds-input" placeholder="vendor@domain.com" required>
        </div>
        <div class="slds-form-element slds-form-element--full">
          <label class="slds-form-element__label">Billing/Operational Address <span class="required">*</span></label>
          <textarea name="address" class="slds-textarea" placeholder="Street, City, State, Postal Code" required></textarea>
        </div>
        <div class="slds-form-element slds-form-element--full">
          <input type="submit" name="add" value="Create Vendor Record" class="slds-button slds-button--brand">
        </div>
      </form>
    </div>
  </div>

  <!-- VENDOR DATA TABLE CARD -->
  <div class="slds-card">
    <div class="slds-card__header">
      <h3>Vendor Directory</h3>
    </div>
    <div class="slds-table-container">
      <table class="slds-table" id="vendorTable">
        <thead>
          <tr>
            <th>ID</th>
            <th>Vendor Name</th>
            <th>GSTIN</th>
            <th>Contact</th>
            <th>Email</th>
            <th>Address</th>
            <th style="text-align: right;">Actions</th>
          </tr>
        </thead>
        <tbody>
  <%
      Statement st = con.createStatement();
      ResultSet rs = st.executeQuery("SELECT * FROM vendors ORDER BY id DESC");
      while (rs.next()) {
  %>
          <tr>
            <td><span class="slds-badge"><%= rs.getInt("id") %></span></td>
            <td style="font-weight: 600; color: #0176D3;"><%= rs.getString("name") %></td>
            <td><code><%= rs.getString("GSTIN") %></code></td>
            <td><%= rs.getString("contact") %></td>
            <td><a href="mailto:<%= rs.getString("email") %>" style="color: inherit; text-decoration: none;"><%= rs.getString("email") %></a></td>
            <td style="max-width: 250px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"><%= rs.getString("address") %></td>
            <td style="text-align: right;">
              <a class="action-link" href="VendorMaster.jsp?editId=<%= rs.getInt("id") %>">Edit</a>
              <a class="action-link action-link--delete" href="VendorMaster.jsp?deleteId=<%= rs.getInt("id") %>" onclick="return confirm('Are you sure you want to delete this vendor record?')">Delete</a>
            </td>
          </tr>
  <%
      }
      rs.close();
      st.close();
  } catch (Exception e) {
      out.println("<tr><td colspan='7' style='color:#ba0517; text-align:center;'>Database Error: " + e.getMessage() + "</td></tr>");
  } finally {
      if (con != null) try { con.close(); } catch (SQLException ex) { ex.printStackTrace(); }
  }
  %>
        </tbody>
      </table>
    </div>
  </div>

</div>

<script>
// Live Search Filtering
document.getElementById('searchInput').addEventListener('keyup', function() {
    let filter = this.value.toLowerCase();
    let rows = document.querySelectorAll('#vendorTable tbody tr');
    
    rows.forEach(row => {
        let textContent = row.textContent.toLowerCase();
        row.style.display = textContent.includes(filter) ? '' : 'none';
    });
});

// Toggle Add Form Display
function toggleAddCard() {
    let card = document.getElementById('addVendorCard');
    if (card.style.display === 'none') {
        card.style.display = 'block';
        card.scrollIntoView({ behavior: 'smooth' });
    } else {
        card.style.display = 'none';
    }
}
</script>

</body>
</html>