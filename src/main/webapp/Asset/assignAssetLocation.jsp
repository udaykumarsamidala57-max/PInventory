<%@page import="java.util.*"%>

<%

ArrayList<HashMap<String,Object>> categories =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("categories");

ArrayList<HashMap<String,Object>> subcategories =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("subcategories");

ArrayList<HashMap<String,Object>> assets =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("assets");

ArrayList<HashMap<String,Object>> locations =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("locations");

String selectedCategory =
request.getParameter("category_id");

String selectedSubcategory =
request.getParameter("subcategory_id");

if(selectedCategory == null){
    selectedCategory = "";
}

if(selectedSubcategory == null){
    selectedSubcategory = "";
}
%>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<title>Asset Location</title>

<style>

body{
font-family:Arial;
margin:20px;
}

table{
width:100%;
border-collapse:collapse;
margin-top:20px;
}

table,th,td{
border:1px solid #ccc;
}

th,td{
padding:10px;
text-align:left;
}

select,button{
padding:7px;
}

.filter-box{
margin-bottom:20px;
}

</style>

<script>

function loadSubcategories(){

    let category =
    document.getElementById(
    "category").value;

    window.location =
    "AssetLocationController"
    + "?action=load"
    + "&category_id="
    + category;
}

function loadAssets(){

    let category =
    document.getElementById(
    "category").value;

    let subcategory =
    document.getElementById(
    "subcategory").value;

    window.location =
    "AssetLocationController"
    + "?action=load"
    + "&category_id="
    + category
    + "&subcategory_id="
    + subcategory;
}

</script>

</head>

<body>

<h2>
Assign / Change Asset Location
</h2>

<div class="filter-box">

<label>Category :</label>

<select id="category"
onchange="loadSubcategories()">

<option value="">
Select Category
</option>

<%
if(categories != null){

for(HashMap<String,Object> c
        : categories){
%>

<option

value="<%=c.get("category_id")%>"

<%=selectedCategory.equals(
String.valueOf(
c.get("category_id")))
? "selected" : ""%>>

<%=c.get("category_name")%>

</option>

<%
}
}
%>

</select>

&nbsp;&nbsp;

<label>Subcategory :</label>

<select id="subcategory"
onchange="loadAssets()">

<option value="">
Select Subcategory
</option>

<%
if(subcategories != null){

for(HashMap<String,Object> s
        : subcategories){
%>

<option

value="<%=s.get(
"subcategory_id")%>"

<%=selectedSubcategory.equals(
String.valueOf(
s.get("subcategory_id")))
? "selected" : ""%>>

<%=s.get(
"subcategory_name")%>

</option>

<%
}
}
%>

</select>

</div>

<table>

<tr>

<th>Asset Code</th>

<th>Asset Name</th>

<th>Current Location</th>

<th>New Location</th>

<th>Action</th>

</tr>

<%
if(assets != null
&& assets.size() > 0){

for(HashMap<String,Object> a
        : assets){
%>

<tr>

<form action=
"AssetLocationController"
method="post">

<td>

<%=a.get("asset_code")%>

<input type="hidden"
name="asset_id"

value="<%=a.get(
"asset_id")%>">

<input type="hidden"
name="category_id"

value="<%=selectedCategory%>">

<input type="hidden"
name="subcategory_id"

value="<%=selectedSubcategory%>">

<input type="hidden"
name="action"
value="assign">

</td>

<td>

<%=a.get("asset_name")%>

</td>

<td>

<%=a.get("current_location")
== null

? "Not Assigned"

: a.get("current_location")%>

</td>

<td>

<select
name="location_id"
required>

<option value="">
Select Location
</option>

<%
if(locations != null){

for(HashMap<String,Object> l
        : locations){
%>

<option value=
"<%=l.get(
"location_id")%>">

<%=l.get(
"location_name")%>

-

<%=l.get("building")%>

</option>

<%
}
}
%>

</select>

</td>

<td>

<button type="submit">

Assign

</button>

</td>

</form>

</tr>

<%
}

}else{
%>

<tr>

<td colspan="5">

No Assets Found

</td>

</tr>

<%
}
%>

</table>

</body>
</html>