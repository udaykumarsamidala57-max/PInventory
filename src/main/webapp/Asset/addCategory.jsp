<%@page import="java.sql.*"%>
<%@page import="com.bean.DBUtil4"%>

<%
HttpSession sess = request.getSession(false);

if (sess == null || sess.getAttribute("username") == null) {

    response.sendRedirect("login.jsp");
    return;
}

String user = (String) sess.getAttribute("username");
String role = (String) sess.getAttribute("role");
String dept = (String) sess.getAttribute("department");

if ((!"Global".equalsIgnoreCase(role)
    && !"Finance".equalsIgnoreCase(dept))) {

    out.println("<h3 style='color:red;text-align:center;'>"
    + "Access Denied! You are not authorized."
    + "</h3>");

    return;
}
%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>Asset Category Management</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/Asset/css/location.css">

<script>

function enableEdit(id){

    document.getElementById("text_"+id).style.display="none";

    document.getElementById("edit_"+id).style.display="table-row";
}

function cancelEdit(id){

    document.getElementById("text_"+id).style.display="table-row";

    document.getElementById("edit_"+id).style.display="none";
}

</script>

</head>

<body>

<%@ include file="../header.jsp" %>

<div class="container">

<!-- SUCCESS / ERROR -->

<%

String msg = request.getParameter("msg");

if("added".equals(msg)){
%>

<div class="success">

    Category Added Successfully

</div>

<%
}

else if("updated".equals(msg)){
%>

<div class="success">

    Category Updated Successfully

</div>

<%
}

else if("deleted".equals(msg)){
%>

<div class="success">

    Category Deleted Successfully

</div>

<%
}

else if("failed".equals(msg)
|| "updatefailed".equals(msg)
|| "deletefailed".equals(msg)
|| "error".equals(msg)){
%>

<div class="error">

    Something went wrong

</div>

<%
}
%>

<!-- ADD FORM -->

<form action="<%=request.getContextPath()%>/CategoryController"
method="post">

<input type="hidden"
name="action"
value="add">

<div class="form-grid">

    <!-- CATEGORY -->

    <div class="form-group">

        <label>Category Name</label>

        <input type="text"
        name="category_name"
        placeholder="Enter Category Name"
        required>

    </div>

    <!-- SUB CATEGORY -->

    <div class="form-group">

        <label>Subcategory Name</label>

        <input type="text"
        name="subcategory_name"
        placeholder="Enter Subcategory Name">

    </div>

</div>

<!-- DESCRIPTION -->

<div class="form-group"
style="margin-top:15px;">

    <label>Description</label>

    <textarea name="description"
    placeholder="Enter Description"></textarea>

</div>

<!-- SAVE BUTTON -->
<% if ("Global".equalsIgnoreCase(role) ) { %>
<button type="submit"
class="save-btn">

    Save Category

</button>
<%} %>
</form>

<!-- TABLE TITLE -->

<div class="table-title">

    Category List

</div>

<!-- TABLE -->

<div class="table-wrapper">

<table>

<tr>

<th>ID</th>
<th>Category</th>
<th>Subcategory</th>
<th>Description</th>
<th width="220">Action</th>

</tr>

<%

try{

    Connection con = DBUtil4.getConnection();

    String sql =
    "SELECT * FROM asset_categories "
    + "ORDER BY category_id DESC";

    PreparedStatement ps =
    con.prepareStatement(sql);

    ResultSet rs = ps.executeQuery();

    while(rs.next()){

        int id =
        rs.getInt("category_id");

%>

<!-- NORMAL VIEW -->

<tr id="text_<%=id%>">

<td>

    <%=id%>

</td>

<td>

    <%=rs.getString("category_name")%>

</td>

<td>

    <%=rs.getString("subcategory_name")%>

</td>

<td>

    <%=rs.getString("description")%>

</td>

<td>
<% if ("Global".equalsIgnoreCase(role) ) { %>
<button type="button"
class="action-btn edit-btn"
onclick="enableEdit('<%=id%>')">

    Edit

</button>

<button type="button"
class="action-btn delete-btn"
onclick="if(confirm('Delete this category?')) 
location.href='<%=request.getContextPath()%>/CategoryController?action=delete&category_id=<%=id%>'">

    Delete

</button>
<%} %>
</td>

</tr>

<!-- EDIT ROW -->

<tr id="edit_<%=id%>"
style="display:none;">

<form action="<%=request.getContextPath()%>/CategoryController"
method="post">

<input type="hidden"
name="action"
value="update">

<input type="hidden"
name="category_id"
value="<%=id%>">

<td>

    <%=id%>

</td>

<!-- CATEGORY -->

<td>

<input type="text"
name="category_name"
class="table-input"
value="<%=rs.getString("category_name")%>"
required>

</td>

<!-- SUBCATEGORY -->

<td>

<input type="text"
name="subcategory_name"
class="table-input"
value="<%=rs.getString("subcategory_name")%>">

</td>

<!-- DESCRIPTION -->

<td>

<input type="text"
name="description"
class="table-input"
value="<%=rs.getString("description")%>">

</td>

<!-- ACTION -->

<td>

<button type="submit"
class="action-btn update-btn">

    Update

</button>

<button type="button"
class="action-btn cancel-btn"
onclick="cancelEdit('<%=id%>')">

    Cancel

</button>

</td>

</form>

</tr>

<%
    }

}catch(Exception e){

    e.printStackTrace();
}
%>

</table>

</div>

</div>

</body>

</html>