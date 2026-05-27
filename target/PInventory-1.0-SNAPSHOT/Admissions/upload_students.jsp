<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Upload Student CSV</title>
</head>
<body>
    <h2>Upload Student CSV</h2>
    <form action="UploadCSVServlet" method="post" enctype="multipart/form-data">
        <label>Select CSV file:</label>
        <input type="file" name="csvFile" accept=".csv" required />
        <br/><br/>
        <input type="submit" value="Upload CSV" />
    </form>
    <p style="color:gray;">Note: File must be CSV, not Excel (.xlsx). Blank lines are ignored.</p>
</body>
</html>
