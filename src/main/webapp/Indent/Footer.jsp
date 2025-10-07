<%@ page import="java.util.Calendar, java.text.SimpleDateFormat" %>
<%
    SimpleDateFormat sdf = new SimpleDateFormat("dd MMMM yyyy"); // Example: 04 October 2025
    String todayDate = sdf.format(Calendar.getInstance().getTime());
%>

<!-- FOOTER -->
<footer>
    <p>©<%= todayDate %> | SRS Inventory System | 
   <i class="fas fa-leaf" style="color:green;"></i> Crafted with devotion 
   <i class="fas fa-leaf" style="color:green;"></i> by Your Team
</p>

</footer>