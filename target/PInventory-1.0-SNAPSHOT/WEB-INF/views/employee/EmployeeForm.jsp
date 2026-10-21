<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<!DOCTYPE html>

<html>
<head>
<meta charset="UTF-8">
<title>Add Employee</title>

<style>
body{
    font-family: Arial, sans-serif;
    background:#f5f5f5;
    margin:0;
    padding:20px;
}

.container{
    max-width:700px;
    margin:auto;
    background:#fff;
    padding:25px;
    border-radius:8px;
    box-shadow:0 2px 8px rgba(0,0,0,0.1);
}

h2{
    text-align:center;
    margin-bottom:20px;
}

.form-group{
    margin-bottom:15px;
}

label{
    display:block;
    margin-bottom:5px;
    font-weight:bold;
}

input[type="text"],
input[type="email"],
input[type="number"],
select{
    width:100%;
    padding:10px;
    border:1px solid #ccc;
    border-radius:4px;
    box-sizing:border-box;
}

input[type="file"]{
    width:100%;
}

.btn{
    background:#007bff;
    color:white;
    border:none;
    padding:10px 20px;
    border-radius:4px;
    cursor:pointer;
}

.btn:hover{
    background:#0056b3;
}

.success{
    color:green;
    margin-bottom:15px;
}

.error{
    color:red;
    margin-bottom:15px;
}
</style>

</head>
<body>

<div class="container">

```
<h2>Add Employee</h2>

<%
String msg = request.getParameter("msg");

if("success".equals(msg)){
%>
    <div class="success">Employee saved successfully.</div>
<%
} else if("failed".equals(msg)){
%>
    <div class="error">Failed to save employee.</div>
<%
} else if("error".equals(msg)){
%>
    <div class="error">An error occurred while saving employee.</div>
<%
}
%>

<form action="<%=request.getContextPath()%>/EmployeeServlet"
      method="post"
      enctype="multipart/form-data">

    <div class="form-group">
        <label>Employee Code</label>
        <input type="text" name="emp_code" required>
    </div>

    <div class="form-group">
        <label>Employee Name</label>
        <input type="text" name="emp_name" required>
    </div>

    <div class="form-group">
        <label>Designation</label>
        <input type="text" name="designation">
    </div>

    <div class="form-group">
        <label>Department</label>
        <input type="text" name="department">
    </div>

    <div class="form-group">
        <label>Reporting To (Manager Employee ID)</label>
        <input type="number" name="reporting_to">
    </div>

    <div class="form-group">
        <label>Email</label>
        <input type="email" name="email">
    </div>

    <div class="form-group">
        <label>Mobile</label>
        <input type="text" name="mobile">
    </div>

    <div class="form-group">
        <label>Employee Photo</label>
        <input type="file" name="photo" accept="image/*">
    </div>

    <div class="form-group">
        <label>Status</label>
        <select name="status">
            <option value="Active" selected>Active</option>
            <option value="Inactive">Inactive</option>
        </select>
    </div>

    <input type="submit" value="Save Employee" class="btn">

</form>
```

</div>

</body>
</html>
