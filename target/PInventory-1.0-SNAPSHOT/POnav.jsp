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
    border-radius: 25px;

    position: absolute;   /* relative to parent container */
    top: 50%;             /* move top to middle */
    transform: translateY(-50%); /* shift upwards by half its height */
  

}

.nav-container a {
    display: block;
    padding: 10px 15px;
    margin-bottom: 10px;
    
    text-decoration: none;
    color: #333;
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
   
    <a href=""><h3>Home</h3></a>
    <a href="IndentPO"><h3>Raise PO</h3></a>
    <a href="POListServlet"><h3>Approve PO</h3></a>
    <a href="GRNServlet"><h3>GRN</h3></a>
   
   
</div>

</body>
</html>
