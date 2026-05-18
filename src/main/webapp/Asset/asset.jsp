<%@page import="java.util.*"%>

<%

HttpSession sess = request.getSession(false);

if(sess == null || sess.getAttribute("username") == null){

    response.sendRedirect("login.jsp");
    return;
}

String user =
(String)sess.getAttribute("username");

String role =
(String)sess.getAttribute("role");

String dept =
(String)sess.getAttribute("department");

if(!"Global".equalsIgnoreCase(role)
        && !"Finance".equalsIgnoreCase(dept)){

    out.println(
    "<h3 style='color:red;text-align:center;'>"
    + "Access Denied! You are not authorized."
    + "</h3>");

    return;
}

ArrayList<HashMap<String,Object>> list =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("assetList");

ArrayList<HashMap<String,Object>> vendors =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("vendorList");

ArrayList<HashMap<String,Object>> categories =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("categoryList");

ArrayList<HashMap<String,Object>> subcategories =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("subcategoryList");

ArrayList<HashMap<String,Object>> locations =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("locationList");

if(list == null){
    list = new ArrayList<>();
}

%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>Asset Management</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/Asset/css/location.css">

<style>

body{
    background:#f5f7fb;
    font-family:Arial,sans-serif;
}

.container{
    width:98%;
    margin:auto;
    padding:10px;
}

.page-title{
    font-size:28px;
    font-weight:bold;
    margin:15px 0;
    color:#1e293b;
}

.top-form{
    background:#fff;
    padding:20px;
    border-radius:10px;
    margin-bottom:20px;
    box-shadow:0 2px 8px rgba(0,0,0,0.08);
}

.form-grid{
    display:grid;
    grid-template-columns:
    repeat(auto-fit,minmax(240px,1fr));
    gap:15px;
}

.form-group{
    display:flex;
    flex-direction:column;
}

.form-group label{
    font-size:14px;
    font-weight:600;
    margin-bottom:6px;
}

.form-group input,
.form-group select,
.form-group textarea{
    padding:10px;
    border:1px solid #d1d5db;
    border-radius:6px;
    font-size:14px;
}

textarea{
    min-height:80px;
}

.save-btn{
    margin-top:18px;
    padding:11px 22px;
    background:#0d6efd;
    color:#fff;
    border:none;
    border-radius:6px;
    cursor:pointer;
    font-size:15px;
    font-weight:600;
}

.save-btn:hover{
    background:#0b5ed7;
}

.table-title{
    font-size:24px;
    font-weight:bold;
    margin:20px 0 12px;
}

.table-wrapper{
    overflow-x:auto;
    background:#fff;
    border-radius:10px;
    box-shadow:0 2px 8px rgba(0,0,0,0.08);
}

table{
    width:100%;
    border-collapse:collapse;
}

table th{
    background:#0f172a;
    color:white;
    padding:12px;
    font-size:14px;
    white-space:nowrap;
}

table td{
    border-bottom:1px solid #e5e7eb;
    padding:10px;
    vertical-align:top;
    font-size:14px;
}

table tr:hover{
    background:#f8fafc;
}

.table-input{
    width:100%;
    padding:7px;
    border:1px solid #cbd5e1;
    border-radius:5px;
    font-size:13px;
}

.action-btn{
    padding:6px 12px;
    border:none;
    border-radius:5px;
    color:white;
    cursor:pointer;
    font-size:12px;
    text-decoration:none;
}

.edit-btn{
    background:#198754;
}

.update-btn{
    background:#0d6efd;
}

.cancel-btn{
    background:#6c757d;
}

.delete-btn{
    background:#dc3545;
}

.editRow{
    display:none;
    background:#f8fafc;
}

.edit-container{
    padding:15px;
    background:#f8fafc;
    border-radius:8px;
}

</style>

<script>

function enableEdit(id){

    document.getElementById("view_"+id)
    .style.display = "none";

    document.getElementById("edit_"+id)
    .style.display = "table-row";
}

function cancelEdit(id){

    document.getElementById("view_"+id)
    .style.display = "table-row";

    document.getElementById("edit_"+id)
    .style.display = "none";
}

</script>

</head>

<body>

<%@ include file="../header.jsp" %>

<div class="container">

<div class="page-title">
Asset Management
</div>

<!-- ADD FORM -->

<div class="top-form">

<form action="<%=request.getContextPath()%>/AssetController"
method="post">

<div class="form-grid">

<div class="form-group">

<label>Asset Code</label>

<input type="text"
name="assetCode"
required>

</div>

<div class="form-group">

<label>Asset Name</label>

<input type="text"
name="assetName"
required>

</div>

<div class="form-group">

<label>Category</label>

<select name="categoryId"
required>

<option value="">
Select Category
</option>

<%
for(HashMap<String,Object> c : categories){
%>

<option value="<%=c.get("category_id")%>">

<%=c.get("category_name")%>

</option>

<%
}
%>

</select>

</div>

<div class="form-group">

<label>Subcategory</label>

<select name="subcategoryId"
required>

<option value="">
Select Subcategory
</option>

<%
for(HashMap<String,Object> s : subcategories){
%>

<option value="<%=s.get("subcategory_id")%>">

<%=s.get("subcategory_name")%>

</option>

<%
}
%>

</select>

</div>

<div class="form-group">

<label>Vendor</label>

<select name="vendor_name"
required>

<option value="">
Select Vendor
</option>

<%
for(HashMap<String,Object> v : vendors){
%>

<option value="<%=v.get("name")%>">

<%=v.get("name")%>

</option>

<%
}
%>

</select>

</div>

<div class="form-group">

<label>Location</label>

<select name="locationId"
required>

<option value="">
Select Location
</option>

<%
for(HashMap<String,Object> l : locations){
%>

<option value="<%=l.get("location_id")%>">

<%=l.get("location_name")%>
-
<%=l.get("building")%>
-
<%=l.get("floor_name")%>
-
Room <%=l.get("room_number")%>

</option>

<%
}
%>

</select>

</div>

<div class="form-group">

<label>Brand</label>

<input type="text"
name="brand">

</div>

<div class="form-group">

<label>Model Number</label>

<input type="text"
name="modelNumber">

</div>

<div class="form-group">

<label>Serial Number</label>

<input type="text"
name="serialNumber">

</div>

<div class="form-group">

<label>Purchase Date</label>

<input type="date"
name="purchaseDate">

</div>

<div class="form-group">

<label>Purchase Cost</label>

<input type="number"
step="0.01"
name="purchaseCost">

</div>

<div class="form-group">

<label>Warranty Expiry</label>

<input type="date"
name="warrantyExpiry">

</div>

<div class="form-group">

<label>Depreciation Method</label>

<select name="depreciationMethod">

<option value="">
Select
</option>

<option value="STRAIGHT_LINE">
STRAIGHT LINE
</option>

<option value="WDV">
WDV
</option>

</select>

</div>

<div class="form-group">

<label>Useful Life Years</label>

<input type="number"
name="usefulLifeYears">

</div>

<div class="form-group">

<label>Salvage Value</label>

<input type="number"
step="0.01"
name="salvageValue">

</div>

<div class="form-group">

<label>Status</label>

<select name="assetStatus">

<option value="AVAILABLE">
AVAILABLE
</option>

<option value="ALLOCATED">
ALLOCATED
</option>

<option value="UNDER_MAINTENANCE">
UNDER MAINTENANCE
</option>

<option value="SCRAPPED">
SCRAPPED
</option>

</select>

</div>

<div class="form-group">

<label>QR Code</label>

<input type="text"
name="qrCode">

</div>

<div class="form-group"
style="grid-column:1/-1;">

<label>Description</label>

<textarea name="description"></textarea>

</div>

</div>

<button type="submit"
name="action"
value="add"
class="save-btn">

Save Asset

</button>

</form>

</div>

<!-- TABLE -->

<div class="table-title">
Asset List
</div>

<div class="table-wrapper">

<table>

<tr>

<th>ID</th>
<th>Code</th>
<th>Name</th>
<th>Category</th>
<th>Subcategory</th>
<th>Vendor</th>
<th>Location</th>
<th>Brand</th>
<th>Model</th>
<th>Serial</th>
<th>Purchase</th>
<th>Cost</th>
<th>Status</th>
<th>Description</th>
<th>Actions</th>

</tr>

<%

for(HashMap<String,Object> a : list){

String aid =
String.valueOf(a.get("asset_id"));

%>

<!-- VIEW ROW -->

<tr id="view_<%=aid%>">

<td><%=aid%></td>

<td><%=a.get("asset_code")%></td>

<td><%=a.get("asset_name")%></td>

<td><%=a.get("category_name")%></td>

<td><%=a.get("subcategory_name")%></td>

<td><%=a.get("vendor_name")%></td>

<td><%=a.get("location_name")%></td>

<td><%=a.get("brand")%></td>

<td><%=a.get("model_number")%></td>

<td><%=a.get("serial_number")%></td>

<td><%=a.get("purchase_date")%></td>

<td><%=a.get("purchase_cost")%></td>

<td><%=a.get("asset_status")%></td>

<td><%=a.get("description")%></td>

<td>

<div style="display:flex;gap:5px;">

<button type="button"
class="action-btn edit-btn"
onclick="enableEdit('<%=aid%>')">

Edit

</button>

<a class="action-btn delete-btn"
href="<%=request.getContextPath()%>/AssetController?action=delete&id=<%=aid%>"
onclick="return confirm('Delete Asset?')">

Delete

</a>

</div>

</td>

</tr>

<!-- EDIT ROW -->

<tr id="edit_<%=aid%>"
class="editRow">

<td colspan="15">

<div class="edit-container">

<form action="<%=request.getContextPath()%>/AssetController"
method="post">

<input type="hidden"
name="assetId"
value="<%=aid%>">

<div class="form-grid">

<div class="form-group">

<label>Asset Code</label>

<input type="text"
name="assetCode"
class="table-input"
value="<%=a.get("asset_code")%>">

</div>

<div class="form-group">

<label>Asset Name</label>

<input type="text"
name="assetName"
class="table-input"
value="<%=a.get("asset_name")%>">

</div>

<div class="form-group">

<label>Category</label>

<select name="categoryId"
class="table-input">

<%

for(HashMap<String,Object> c : categories){

String cid =
String.valueOf(c.get("category_id"));

String acat =
String.valueOf(a.get("category_id"));

%>

<option value="<%=cid%>"
<%=cid.equals(acat)
? "selected"
: ""%>>

<%=c.get("category_name")%>

</option>

<%
}
%>

</select>

</div>

<div class="form-group">

<label>Subcategory</label>

<select name="subcategoryId"
class="table-input">

<%

for(HashMap<String,Object> s : subcategories){

String sid =
String.valueOf(s.get("subcategory_id"));

String asid =
String.valueOf(a.get("subcategory_id"));

%>

<option value="<%=sid%>"
<%=sid.equals(asid)
? "selected"
: ""%>>

<%=s.get("subcategory_name")%>

</option>

<%
}
%>

</select>

</div>

<div class="form-group">

<label>Vendor</label>

<select name="vendor_name"
class="table-input">

<%

for(HashMap<String,Object> v : vendors){

String vname =
String.valueOf(v.get("name"));

String av =
String.valueOf(a.get("vendor_name"));

%>

<option value="<%=vname%>"
<%=vname.equals(av)
? "selected"
: ""%>>

<%=vname%>

</option>

<%
}
%>

</select>

</div>

<div class="form-group">

<label>Location</label>

<select name="locationId"
class="table-input">

<%

for(HashMap<String,Object> l : locations){

String lid =
String.valueOf(l.get("location_id"));

String alid =
String.valueOf(a.get("location_id"));

%>

<option value="<%=lid%>"
<%=lid.equals(alid)
? "selected"
: ""%>>

<%=l.get("location_name")%>

</option>

<%
}
%>

</select>

</div>

<div class="form-group">

<label>Brand</label>

<input type="text"
name="brand"
class="table-input"
value="<%=a.get("brand")%>">

</div>

<div class="form-group">

<label>Model Number</label>

<input type="text"
name="modelNumber"
class="table-input"
value="<%=a.get("model_number")%>">

</div>

<div class="form-group">

<label>Serial Number</label>

<input type="text"
name="serialNumber"
class="table-input"
value="<%=a.get("serial_number")%>">

</div>

<div class="form-group">

<label>Purchase Date</label>

<input type="date"
name="purchaseDate"
class="table-input"
value="<%=a.get("purchase_date")%>">

</div>

<div class="form-group">

<label>Purchase Cost</label>

<input type="number"
step="0.01"
name="purchaseCost"
class="table-input"
value="<%=a.get("purchase_cost")%>">

</div>

<div class="form-group">

<label>Warranty Expiry</label>

<input type="date"
name="warrantyExpiry"
class="table-input"
value="<%=a.get("warranty_expiry")%>">

</div>

<div class="form-group">

<label>Depreciation Method</label>

<select name="depreciationMethod"
class="table-input">

<option value="STRAIGHT_LINE"
<%="STRAIGHT_LINE".equals(
String.valueOf(a.get("depreciation_method")))
? "selected"
: ""%>>

STRAIGHT LINE

</option>

<option value="WDV"
<%="WDV".equals(
String.valueOf(a.get("depreciation_method")))
? "selected"
: ""%>>

WDV

</option>

</select>

</div>

<div class="form-group">

<label>Useful Life Years</label>

<input type="number"
name="usefulLifeYears"
class="table-input"
value="<%=a.get("useful_life_years")%>">

</div>

<div class="form-group">

<label>Salvage Value</label>

<input type="number"
step="0.01"
name="salvageValue"
class="table-input"
value="<%=a.get("salvage_value")%>">

</div>

<div class="form-group">

<label>Status</label>

<select name="assetStatus"
class="table-input">

<option value="AVAILABLE"
<%="AVAILABLE".equals(
String.valueOf(a.get("asset_status")))
? "selected"
: ""%>>

AVAILABLE

</option>

<option value="ALLOCATED"
<%="ALLOCATED".equals(
String.valueOf(a.get("asset_status")))
? "selected"
: ""%>>

ALLOCATED

</option>

<option value="UNDER_MAINTENANCE"
<%="UNDER_MAINTENANCE".equals(
String.valueOf(a.get("asset_status")))
? "selected"
: ""%>>

UNDER MAINTENANCE

</option>

<option value="SCRAPPED"
<%="SCRAPPED".equals(
String.valueOf(a.get("asset_status")))
? "selected"
: ""%>>

SCRAPPED

</option>

</select>

</div>

<div class="form-group">

<label>QR Code</label>

<input type="text"
name="qrCode"
class="table-input"
value="<%=a.get("qr_code")%>">

</div>

<div class="form-group"
style="grid-column:1/-1;">

<label>Description</label>

<textarea name="description"
class="table-input"><%=a.get("description")%></textarea>

</div>

</div>

<div style="margin-top:15px;display:flex;gap:10px;">

<button type="submit"
name="action"
value="update"
class="action-btn update-btn">

Update

</button>

<button type="button"
class="action-btn cancel-btn"
onclick="cancelEdit('<%=aid%>')">

Cancel

</button>

</div>

</form>

</div>

</td>

</tr>

<%
}
%>

</table>

</div>

</div>

</body>

</html>