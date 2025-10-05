<%@ page contentType="text/html; charset=UTF-8" language="java" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Navigation</title>
<style>
/* Left-side navigation styling */

.nav-container {
    width: 200px;
    background-color: white;
    padding: 15px;
    box-sizing: border-box;
    font-family: Arial, sans-serif;
   border: 2px solid #F07A05;
    border-radius: 15px;
    
    position: absolute;   /* relative to parent container */
    top: 50%;             /* move top to middle */
    transform: translateY(-50%); /* shift upwards by half its height */
  
}

.nav-container a {
    display: block;
    padding: 10px 15px;
    margin-bottom: 10px;
    color: black;
    
    
    border-radius: 20px;
    transition: 0.3s;
   
}

.nav-container a:hover {
    background-color: #3498db;
    color: white;
}

</style>
</head>
<body>

<div class="nav-container">
    <a href=""><h3>HOME
    
    </h3></a>
    <a href="IssueServlet"><h3>Issue Items</h3></a>
    <a href="Stock.jsp"><h3>Stock Report</h3></a>
    <a href="Issuereport.jsp"><h3>Issue Report</h3></a>
   
</div>

</body>
</html>
