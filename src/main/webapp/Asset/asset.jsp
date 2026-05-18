<%@page import="java.util.*"%>

<%
HttpSession sess = request.getSession(false);

if (sess == null || sess.getAttribute("username") == null) {

    response.sendRedirect("login.jsp");
    return;
}

String user =
(String) sess.getAttribute("username");

String role =
(String) sess.getAttribute("role");

String dept =
(String) sess.getAttribute("department");

if (!"Global".equalsIgnoreCase(role)
        && !"Finance".equalsIgnoreCase(dept)) {

    out.println(
    "<h3 style='color:red;text-align:center;'>"
    + "Access Denied! You are not authorized."
    + "</h3>");

    return;
}
%>

<%

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

HashMap<String,Object> edit =
(HashMap<String,Object>)
request.getAttribute("asset");

if(list == null){
    list = new ArrayList<>();
}

String assetId = "";
String assetCode = "";
String assetName = "";
String categoryId = "";
String subcategoryId = "";
String vendor_name = "";
String locationId = "";
String brand = "";
String modelNumber = "";
String serialNumber = "";
String purchaseDate = "";
String purchaseCost = "";
String warrantyExpiry = "";
String depreciationMethod = "";
String usefulLifeYears = "";
String salvageValue = "";
String assetStatus = "AVAILABLE";
String qrCode = "";
String description = "";

if(edit != null){

    assetId =
    String.valueOf(edit.get("asset_id"));

    assetCode =
    String.valueOf(edit.get("asset_code"));

    assetName =
    String.valueOf(edit.get("asset_name"));

    categoryId =
    String.valueOf(edit.get("category_id"));

    subcategoryId =
    String.valueOf(edit.get("subcategory_id"));

    vendor_name =
    String.valueOf(edit.get("vendor_name"));

    locationId =
    String.valueOf(edit.get("location_id"));

    brand =
    String.valueOf(edit.get("brand"));

    modelNumber =
    String.valueOf(edit.get("model_number"));

    serialNumber =
    String.valueOf(edit.get("serial_number"));

    purchaseDate =
    edit.get("purchase_date") == null
    ? ""
    : String.valueOf(edit.get("purchase_date"));

    purchaseCost =
    edit.get("purchase_cost") == null
    ? ""
    : String.valueOf(edit.get("purchase_cost"));

    warrantyExpiry =
    edit.get("warranty_expiry") == null
    ? ""
    : String.valueOf(edit.get("warranty_expiry"));

    depreciationMethod =
    String.valueOf(edit.get("depreciation_method"));

    usefulLifeYears =
    edit.get("useful_life_years") == null
    ? ""
    : String.valueOf(edit.get("useful_life_years"));

    salvageValue =
    edit.get("salvage_value") == null
    ? ""
    : String.valueOf(edit.get("salvage_value"));

    assetStatus =
    String.valueOf(edit.get("asset_status"));

    qrCode =
    String.valueOf(edit.get("qr_code"));

    description =
    String.valueOf(edit.get("description"));
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

.table-wrapper{
    overflow-x:auto;
}

table{
    width:100%;
    border-collapse:collapse;
}

table th,
table td{
    padding:10px;
    border:1px solid #ddd;
    vertical-align:top;
}

.form-grid{
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(250px,1fr));
    gap:15px;
}

.form-group{
    display:flex;
    flex-direction:column;
}

.form-group label{
    margin-bottom:6px;
    font-weight:600;
}

.form-group input,
.form-group select,
.form-group textarea{
    padding:8px;
    border:1px solid #ccc;
    border-radius:5px;
}

textarea{
    min-height:80px;
}

.save-btn{
    margin-top:20px;
    padding:10px 20px;
    border:none;
    background:#0d6efd;
    color:white;
    border-radius:5px;
    cursor:pointer;
}

.action-btn{
    padding:6px 10px;
    text-decoration:none;
    color:white;
    border-radius:4px;
    font-size:13px;
}

.edit-btn{
    background:#198754;
}

.delete-btn{
    background:#dc3545;
}

.status-active{
    color:green;
    font-weight:bold;
}

.status-pending{
    color:orange;
    font-weight:bold;
}

.status-warning{
    color:#d39e00;
    font-weight:bold;
}

.status-inactive{
    color:red;
    font-weight:bold;
}

.page-title,
.table-title{
    font-size:22px;
    margin:20px 0;
    font-weight:bold;
}

</style>

</head>

<body>

<%@ include file="../header.jsp" %>

<div class="container">

<div class="page-title">
Asset Management
</div>

<form action="<%=request.getContextPath()%>/AssetController"
method="post">

<input type="hidden"
name="assetId"
value="<%=assetId%>">

<div class="form-grid">

<!-- Asset Code -->

<div class="form-group">

<label>Asset Code</label>

<input type="text"
name="assetCode"
required
value="<%=assetCode%>">

</div>

<!-- Asset Name -->

<div class="form-group">

<label>Asset Name</label>

<input type="text"
name="assetName"
required
value="<%=assetName%>">

</div>

<!-- Category -->

<div class="form-group">

<label>Category</label>

<select name="categoryId"
id="categoryId"
required
onchange="filterSubcategories()">

<option value="">
Select Category
</option>

<%
for(HashMap<String,Object> c : categories){
%>

<option value="<%=c.get("category_id")%>"
<%=String.valueOf(c.get("category_id"))
.equals(categoryId)
? "selected"
: ""%>>

<%=c.get("category_name")%>

</option>

<%
}
%>

</select>

</div>

<!-- Subcategory -->

<div class="form-group">

<label>Subcategory</label>

<select name="subcategoryId"
id="subcategoryId"
required>

<option value="">
Select Subcategory
</option>

<%
for(HashMap<String,Object> s : subcategories){

String subCatId =
String.valueOf(s.get("subcategory_id"));

String parentCatId =
String.valueOf(s.get("category_id"));
%>

<option value="<%=subCatId%>"
data-category="<%=parentCatId%>"
<%=subCatId.equals(subcategoryId)
? "selected"
: ""%>>

<%=s.get("subcategory_name")%>

</option>

<%
}
%>

</select>

</div>

<!-- Vendor -->

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

<option value="<%=v.get("name")%>"
<%=String.valueOf(v.get("name"))
.equals(vendor_name)
? "selected"
: ""%>>

<%=v.get("name")%>

</option>

<%
}
%>

</select>

</div>

<!-- Location -->

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

<option value="<%=l.get("location_id")%>"
<%=String.valueOf(l.get("location_id"))
.equals(locationId)
? "selected"
: ""%>>

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

<!-- Brand -->

<div class="form-group">

<label>Brand</label>

<input type="text"
name="brand"
value="<%=brand%>">

</div>

<!-- Model -->

<div class="form-group">

<label>Model Number</label>

<input type="text"
name="modelNumber"
value="<%=modelNumber%>">

</div>

<!-- Serial -->

<div class="form-group">

<label>Serial Number</label>

<input type="text"
name="serialNumber"
value="<%=serialNumber%>">

</div>

<!-- Purchase Date -->

<div class="form-group">

<label>Purchase Date</label>

<input type="date"
name="purchaseDate"
value="<%=purchaseDate%>">

</div>

<!-- Purchase Cost -->

<div class="form-group">

<label>Purchase Cost</label>

<input type="number"
step="0.01"
name="purchaseCost"
value="<%=purchaseCost%>">

</div>

<!-- Warranty -->

<div class="form-group">

<label>Warranty Expiry</label>

<input type="date"
name="warrantyExpiry"
value="<%=warrantyExpiry%>">

</div>

<!-- Depreciation -->

<div class="form-group">

<label>Depreciation Method</label>

<select name="depreciationMethod">

<option value="">
Select Method
</option>

<option value="STRAIGHT_LINE"
<%="STRAIGHT_LINE".equals(depreciationMethod)
? "selected"
: ""%>>

STRAIGHT LINE

</option>

<option value="WDV"
<%="WDV".equals(depreciationMethod)
? "selected"
: ""%>>

WDV

</option>

</select>

</div>

<!-- Useful Life -->

<div class="form-group">

<label>Useful Life Years</label>

<input type="number"
name="usefulLifeYears"
value="<%=usefulLifeYears%>">

</div>

<!-- Salvage -->

<div class="form-group">

<label>Salvage Value</label>

<input type="number"
step="0.01"
name="salvageValue"
value="<%=salvageValue%>">

</div>

<!-- Status -->

<div class="form-group">

<label>Asset Status</label>

<select name="assetStatus">

<option value="AVAILABLE"
<%="AVAILABLE".equals(assetStatus)
? "selected"
: ""%>>

AVAILABLE

</option>

<option value="ALLOCATED"
<%="ALLOCATED".equals(assetStatus)
? "selected"
: ""%>>

ALLOCATED

</option>

<option value="UNDER_MAINTENANCE"
<%="UNDER_MAINTENANCE".equals(assetStatus)
? "selected"
: ""%>>

UNDER MAINTENANCE

</option>

<option value="SCRAPPED"
<%="SCRAPPED".equals(assetStatus)
? "selected"
: ""%>>

SCRAPPED

</option>

</select>

</div>

<!-- QR -->

<div class="form-group">

<label>QR Code</label>

<input type="text"
name="qrCode"
value="<%=qrCode%>">

</div>

<!-- Description -->

<div class="form-group"
style="grid-column:1/-1;">

<label>Description</label>

<textarea
name="description"><%=description%></textarea>

</div>

</div>

<%

if(edit != null){
%>

<button type="submit"
name="action"
value="update"
class="save-btn">

Update Asset

</button>

<%
}else{
%>

<button type="submit"
name="action"
value="add"
class="save-btn">

Save Asset

</button>

<%
}
%>

</form>

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
<th>Brand / Model / Serial</th>
<th>Purchase Date</th>
<th>Purchase Cost</th>
<th>Warranty</th>
<th>Depreciation</th>
<th>Useful Life</th>
<th>Salvage</th>
<th>Status</th>
<th>QR</th>
<th>Description</th>
<th>Actions</th>

</tr>

<%
for(HashMap<String,Object> a : list){
%>

<tr>

<td><%=a.get("asset_id")%></td>

<td><%=a.get("asset_code")%></td>

<td><%=a.get("asset_name")%></td>

<td><%=a.get("category_name")%></td>

<td><%=a.get("subcategory_name")%></td>

<td><%=a.get("vendor_name")%></td>

<td>

<%=a.get("location_name")%>

</td>

<td>

<b><%=a.get("brand")%></b>

<br>

M:
<%=a.get("model_number")%>

<br>

S:
<%=a.get("serial_number")%>

</td>

<td><%=a.get("purchase_date")%></td>

<td><%=a.get("purchase_cost")%></td>

<td><%=a.get("warranty_expiry")%></td>

<td>

<%

String dep =
String.valueOf(a.get("depreciation_method"));

if("STRAIGHT_LINE".equals(dep)){

    out.print("Straight Line");

}else if("WDV".equals(dep)){

    out.print("Written Down Value");

}else{

    out.print("-");
}

%>

</td>

<td>

<%=a.get("useful_life_years")%> Years

</td>

<td>

<%=a.get("salvage_value")%>

</td>

<td>

<%

String status =
String.valueOf(a.get("asset_status"));

if("AVAILABLE".equals(status)){
%>

<span class="status-active">
AVAILABLE
</span>

<%
}else if("ALLOCATED".equals(status)){
%>

<span class="status-pending">
ALLOCATED
</span>

<%
}else if("UNDER_MAINTENANCE".equals(status)){
%>

<span class="status-warning">
UNDER MAINTENANCE
</span>

<%
}else{
%>

<span class="status-inactive">
SCRAPPED
</span>

<%
}
%>

</td>

<td><%=a.get("qr_code")%></td>

<td style="min-width:200px;">
<%=a.get("description")%>
</td>

<td>

<div style="display:flex;gap:6px;">

<a class="action-btn edit-btn"
href="<%=request.getContextPath()%>/AssetController?action=edit&id=<%=a.get("asset_id")%>">

Edit

</a>

<a class="action-btn delete-btn"
href="<%=request.getContextPath()%>/AssetController?action=delete&id=<%=a.get("asset_id")%>"
onclick="return confirm('Delete Asset?')">

Delete

</a>

</div>

</td>

</tr>

<%
}
%>

</table>

</div>

</div>

<script>

function filterSubcategories(){

    var categoryId =
    document.getElementById("categoryId").value;

    var subcategory =
    document.getElementById("subcategoryId");

    var options =
    subcategory.options;

    for(var i=0; i<options.length; i++){

        var option =
        options[i];

        if(option.value == ""){

            option.style.display = "block";
            continue;
        }

        var parentCategory =
        option.getAttribute("data-category");

        if(parentCategory == categoryId){

            option.style.display = "block";

        }else{

            option.style.display = "none";
        }
    }

    var selectedOption =
    subcategory.options[subcategory.selectedIndex];

    if(selectedOption){

        var selectedParent =
        selectedOption.getAttribute("data-category");

        if(selectedParent != categoryId){

            subcategory.value = "";
        }
    }
}

window.onload = function(){

    filterSubcategories();
};

</script>

</body>

</html>