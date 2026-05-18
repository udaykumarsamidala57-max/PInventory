<%@page import="java.util.*"%>

<%

ArrayList<HashMap<String,Object>> list =
(ArrayList<HashMap<String,Object>>)
request.getAttribute("assetList");

HashMap<String,Object> edit =
(HashMap<String,Object>)
request.getAttribute("asset");

String assetId = "";
String assetCode = "";
String assetName = "";
String vendorId = "";
String brand = "";

if(edit != null){

    assetId =
    String.valueOf(edit.get("asset_id"));

    assetCode =
    String.valueOf(edit.get("asset_code"));

    assetName =
    String.valueOf(edit.get("asset_name"));

    vendorId =
    String.valueOf(edit.get("vendor_id"));

    brand =
    String.valueOf(edit.get("brand"));
}

if(list == null){
    list = new ArrayList<>();
}

%>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<title>Asset Management</title>

<style>

body{
    font-family:Arial;
    background:#f4f6f9;
    padding:30px;
}

.container{
    width:95%;
    margin:auto;
}

.form-box,
.table-box{
    background:white;
    padding:20px;
    border-radius:8px;
    margin-bottom:25px;
}

input{
    padding:10px;
    margin:5px;
    width:220px;
}

button{
    padding:10px 18px;
    border:none;
    background:#007bff;
    color:white;
    cursor:pointer;
}

table{
    width:100%;
    border-collapse:collapse;
}

table th{
    background:#007bff;
    color:white;
}

table th,
table td{
    border:1px solid #ddd;
    padding:10px;
    text-align:center;
}

.edit-btn{
    background:green;
    color:white;
    padding:6px 10px;
    text-decoration:none;
}

.delete-btn{
    background:red;
    color:white;
    padding:6px 10px;
    text-decoration:none;
}

</style>

</head>

<body>

<div class="container">

<h2>Asset Management</h2>

<div class="form-box">

<form action="<%=request.getContextPath()%>/AssetController"
method="post">

<input type="hidden"
name="assetId"
value="<%=assetId%>">

<input type="text"
name="assetCode"
placeholder="Asset Code"
required
value="<%=assetCode%>">

<input type="text"
name="assetName"
placeholder="Asset Name"
required
value="<%=assetName%>">

<input type="number"
name="vendorId"
placeholder="Vendor ID"
required
value="<%=vendorId%>">

<input type="text"
name="brand"
placeholder="Brand"
value="<%=brand%>">

<%

if(edit != null){

%>

<button type="submit"
name="action"
value="update">

Update Asset

</button>

<%

}else{

%>

<button type="submit"
name="action"
value="add">

Add Asset

</button>

<%

}

%>

</form>

</div>

<div class="table-box">

<table>

<tr>

<th>ID</th>
<th>Asset Code</th>
<th>Asset Name</th>
<th>Vendor</th>
<th>Brand</th>
<th>Status</th>
<th>Actions</th>

</tr>

<%

for(HashMap<String,Object> a : list){

%>

<tr>

<td><%=a.get("asset_id")%></td>

<td><%=a.get("asset_code")%></td>

<td><%=a.get("asset_name")%></td>

<td><%=a.get("vendor_name")%></td>

<td><%=a.get("brand")%></td>

<td><%=a.get("asset_status")%></td>

<td>

<a class="edit-btn"
href="<%=request.getContextPath()%>/AssetController?action=edit&id=<%=a.get("asset_id")%>">

Edit

</a>

<a class="delete-btn"
href="<%=request.getContextPath()%>/AssetController?action=delete&id=<%=a.get("asset_id")%>"
onclick="return confirm('Delete Asset?')">

Delete

</a>

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