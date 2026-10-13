<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Meal Cost Summary</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
<style>
body {
  font-family: 'Poppins', sans-serif;
  background-color: #f4f7f8;
  margin: 0;
  padding: 0;
}
.container {
  max-width: 700px;
  background: white;
  margin: 60px auto;
  padding: 30px;
  border-radius: 12px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}
label {
  font-weight: 600;
}
input, select {
  padding: 8px;
  width: 100%;
  margin-bottom: 15px;
  border: 1px solid #ccc;
  border-radius: 5px;
}
button {
  background-color: #2e8b57;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
}
button:hover {
  background-color: #256d46;
}
.result {
  margin-top: 20px;
  padding: 10px;
  background: #f1f1f1;
  border-radius: 8px;
}
</style>
</head>
<body>

<div class="container">
  <h2 align="center">Meal Cost Summary Refresh</h2>

  <form action="MealSummaryServlet" method="post">
    <label>Select Date:</label>
    <input type="date" name="meal_date" required>

    <label>Select Session:</label>
    <select name="session" required>
      <option value="">-- Select --</option>
      <option value="Morning">Morning</option>
      <option value="Afternoon">Afternoon</option>
      <option value="Evening">Evening</option>
    </select>

    <center>
      <button type="submit">🔄 Refresh Summary</button>
    </center>
  </form>

  <div class="result">
    <c:if test="${not empty message}">
      <b>${message}</b>
    </c:if>
  </div>
</div>

</body>
</html>
