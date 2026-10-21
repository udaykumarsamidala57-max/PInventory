<%@ page import="java.util.Calendar, java.text.SimpleDateFormat" %>
<%
    SimpleDateFormat sdf = new SimpleDateFormat("dd MMMM yyyy"); // Example: 04 October 2025
    String todayDate = sdf.format(Calendar.getInstance().getTime());
%>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<footer>
    <p>©<%= todayDate %> | SRS Inventory System | 
   <i class="fas fa-leaf" style="color:green;"></i> Developed by 
   <i class="fas fa-leaf" style="color:green;"></i> School IT Department
</p>

</footer>