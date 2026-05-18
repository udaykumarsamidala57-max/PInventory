<%@page import="java.sql.*"%>
<%@page import="com.bean.DBUtil4"%>

<%
HttpSession sess = request.getSession(false);

if (sess == null || sess.getAttribute("username") == null) {

    response.sendRedirect("login.jsp");
    return;
}

String role = (String) sess.getAttribute("role");
String dept = (String) sess.getAttribute("department");

if ((!"Global".equalsIgnoreCase(role)
    && !"Finance".equalsIgnoreCase(dept))) {

    out.println("<h3 style='color:red;text-align:center;'>"
    + "Access Denied!"
    + "</h3>");

    return;
}
%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>Category & Subcategory Management</title>

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

function enableSubEdit(id){

    document.getElementById("sub_text_"+id).style.display="none";

    document.getElementById("sub_edit_"+id).style.display="table-row";
}

function cancelSubEdit(id){

    document.getElementById("sub_text_"+id).style.display="table-row";

    document.getElementById("sub_edit_"+id).style.display="none";
}

</script>

<style>

.group-title{

    background:#1f4e78;
    color:white;
    font-weight:bold;
    text-align:left;
    padding:12px;
    font-size:16px;
}

.sub-row{

    background:#fafafa;
}

.badge{

    background:#e3f2fd;
    color:#0d47a1;
    padding:4px 10px;
    border-radius:20px;
    font-size:12px;
    font-weight:bold;
    margin-right:10px;
}

.category-row{

    background:#ffffff;
    font-weight:600;
}

.action-flex{

    display:flex;
    gap:6px;
    flex-wrap:wrap;
}

.table-input{

    width:100%;
    padding:8px;
    border:1px solid #ccc;
    border-radius:5px;
}

.action-btn{

    padding:7px 14px;
    border:none;
    border-radius:5px;
    cursor:pointer;
    font-size:13px;
    font-weight:600;
}

.edit-btn{

    background:#2196f3;
    color:white;
}

.delete-btn{

    background:#f44336;
    color:white;
}

.update-btn{

    background:#4caf50;
    color:white;
}

.cancel-btn{

    background:#9e9e9e;
    color:white;
}

</style>

</head>

<body>

<%@ include file="../header.jsp" %>

<div class="container">

<!-- ================= SUCCESS / ERROR ================= -->

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

else if("subadded".equals(msg)){
%>

<div class="success">

Subcategory Added Successfully

</div>

<%
}

else if("subupdated".equals(msg)){
%>

<div class="success">

Subcategory Updated Successfully

</div>

<%
}

else if("subdeleted".equals(msg)){
%>

<div class="success">

Subcategory Deleted Successfully

</div>

<%
}

else if("failed".equals(msg)
|| "updatefailed".equals(msg)
|| "deletefailed".equals(msg)
|| "subfailed".equals(msg)
|| "subupdatefailed".equals(msg)
|| "subdeletefailed".equals(msg)
|| "error".equals(msg)){
%>

<div class="error">

Something Went Wrong

</div>

<%
}
%>

<!-- ================= ADD CATEGORY ================= -->

<div class="table-title">

Add Category

</div>

<form action="<%=request.getContextPath()%>/CategoryController"
method="post">

<input type="hidden"
name="action"
value="add">

<div class="form-grid">

<div class="form-group">

<label>Category Name</label>

<input type="text"
name="category_name"
placeholder="Enter Category Name"
required>

</div>

</div>

<div class="form-group"
style="margin-top:15px;">

<label>Description</label>

<textarea name="description"
placeholder="Enter Description"></textarea>

</div>

<% if ("Global".equalsIgnoreCase(role)) { %>

<button type="submit"
class="save-btn">

Save Category

</button>

<% } %>

</form>

<!-- ================= ADD SUBCATEGORY ================= -->

<div class="table-title"
style="margin-top:40px;">

Add Subcategory

</div>

<form action="<%=request.getContextPath()%>/CategoryController"
method="post">

<input type="hidden"
name="action"
value="addSubcategory">

<div class="form-grid">

<div class="form-group">

<label>Select Category</label>

<select name="category_id" required>

<option value="">Select Category</option>

<%

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try{

    con = DBUtil4.getConnection();

    String sql =
            "SELECT * FROM asset_categories "
            + "ORDER BY category_name";

    ps = con.prepareStatement(sql);

    rs = ps.executeQuery();

    while(rs.next()){

%>

<option value="<%=rs.getInt("category_id")%>">

<%=rs.getString("category_name")%>

</option>

<%
    }

}catch(Exception e){

    e.printStackTrace();
}
%>

</select>

</div>

<div class="form-group">

<label>Subcategory Name</label>

<input type="text"
name="subcategory_name"
placeholder="Enter Subcategory Name"
required>

</div>

</div>

<div class="form-group"
style="margin-top:15px;">

<label>Description</label>

<textarea name="description"
placeholder="Enter Description"></textarea>

</div>

<% if ("Global".equalsIgnoreCase(role)) { %>

<button type="submit"
class="save-btn">

Save Subcategory

</button>

<% } %>

</form>

<!-- ================= CATEGORY TABLE ================= -->

<div class="table-title"
style="margin-top:40px;">

Category & Subcategory List

</div>

<div class="table-wrapper">

<table>

<tr>

<th width="80">ID</th>
<th>Category / Subcategory</th>
<th>Description</th>
<th width="250">Action</th>

</tr>

<%

try{

    con = DBUtil4.getConnection();

    String catSql =
            "SELECT * FROM asset_categories "
            + "ORDER BY category_name";

    PreparedStatement catPs =
            con.prepareStatement(catSql);

    ResultSet catRs =
            catPs.executeQuery();

    while(catRs.next()){

        int categoryId =
                catRs.getInt("category_id");

%>

<!-- CATEGORY TITLE -->

<tr>

<td colspan="4"
class="group-title">

CATEGORY :
<%=catRs.getString("category_name")%>

</td>

</tr>

<!-- CATEGORY DISPLAY -->

<tr id="text_<%=categoryId%>"
class="category-row">

<td>

<%=categoryId%>

</td>

<td>

<span class="badge">

Category

</span>

<%=catRs.getString("category_name")%>

</td>

<td>



</td>

<td>

<% if ("Global".equalsIgnoreCase(role)) { %>

<div class="action-flex">

<button type="button"
class="action-btn edit-btn"
onclick="enableEdit('<%=categoryId%>')">

Edit

</button>

<button type="button"
class="action-btn delete-btn"
onclick="if(confirm('Delete this category and all subcategories?'))
location.href='<%=request.getContextPath()%>/CategoryController?action=delete&category_id=<%=categoryId%>'">

Delete

</button>

</div>

<% } %>

</td>

</tr>

<!-- CATEGORY EDIT -->

<tr id="edit_<%=categoryId%>"
style="display:none;">

<form action="<%=request.getContextPath()%>/CategoryController"
method="post">

<input type="hidden"
name="action"
value="update">

<input type="hidden"
name="category_id"
value="<%=categoryId%>">

<td>

<%=categoryId%>

</td>

<td>

<input type="text"
name="category_name"
class="table-input"
value="<%=catRs.getString("category_name")%>"
required>

</td>

<td>

<input type="text"
name="description"
class="table-input"
value="<%=catRs.getString("description")%>">

</td>

<td>

<div class="action-flex">

<button type="submit"
class="action-btn update-btn">

Update

</button>

<button type="button"
class="action-btn cancel-btn"
onclick="cancelEdit('<%=categoryId%>')">

Cancel

</button>

</div>

</td>

</form>

</tr>

<%

String subSql =
        "SELECT * FROM asset_subcategories "
        + "WHERE category_id=? "
        + "ORDER BY subcategory_name";

PreparedStatement subPs =
        con.prepareStatement(subSql);

subPs.setInt(1, categoryId);

ResultSet subRs =
        subPs.executeQuery();

while(subRs.next()){

    int subId =
            subRs.getInt("subcategory_id");

%>

<!-- SUBCATEGORY DISPLAY -->

<tr id="sub_text_<%=subId%>"
class="sub-row">

<td>

<%=subId%>

</td>

<td style="padding-left:40px;">


<%=subRs.getString("subcategory_name")%>

</td>

<td>

<%=subRs.getString("description")%>

</td>

<td>

<% if ("Global".equalsIgnoreCase(role)) { %>

<div class="action-flex">

<button type="button"
class="action-btn edit-btn"
onclick="enableSubEdit('<%=subId%>')">

Edit

</button>

<button type="button"
class="action-btn delete-btn"
onclick="if(confirm('Delete this subcategory?'))
location.href='<%=request.getContextPath()%>/CategoryController?action=deleteSubcategory&subcategory_id=<%=subId%>'">

Delete

</button>

</div>

<% } %>

</td>

</tr>

<!-- SUBCATEGORY EDIT -->

<tr id="sub_edit_<%=subId%>"
style="display:none;">

<form action="<%=request.getContextPath()%>/CategoryController"
method="post">

<input type="hidden"
name="action"
value="updateSubcategory">

<input type="hidden"
name="subcategory_id"
value="<%=subId%>">

<td>

<%=subId%>

</td>

<td>

<input type="text"
name="subcategory_name"
class="table-input"
value="<%=subRs.getString("subcategory_name")%>"
required>

</td>

<td>

<input type="text"
name="description"
class="table-input"
value="<%=subRs.getString("description")%>">

</td>

<td>

<div class="action-flex">

<button type="submit"
class="action-btn update-btn">

Update

</button>

<button type="button"
class="action-btn cancel-btn"
onclick="cancelSubEdit('<%=subId%>')">

Cancel

</button>

</div>

</td>

</form>

</tr>

<%
        }
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