<%@ page import="java.util.*,com.bean.Item" %>
<%
List<Item> list = (List<Item>) request.getAttribute("itemList");
if (list == null) {
    response.sendRedirect("ItemServlet?action=list");
    return;
}
%>
<html>
<head><title>Items List</title></head>
<body>
<h2>Item Master List</h2>
<a href="addItem.jsp">Add New Item</a>
<table border="1" cellpadding="6">
<tr>
<th>ID</th><th>Category</th><th>Sub Category</th><th>Item Name</th>
<th>UOM</th><th>Description</th><th>Remarks</th><th>Actions</th>
</tr>
<%
for (Item i : list) {
%>
<tr>
<td><%=i.getItemId()%></td>
<td><%=i.getCategory()%></td>
<td><%=i.getSubCategory()%></td>
<td><%=i.getItemName()%></td>
<td><%=i.getUom()%></td>
<td><%=i.getDesc()%></td>
<td><%=i.getRemarks()%></td>
<td>
<a href="ItemServlet?action=edit&id=<%=i.getItemId()%>">Edit</a> |
<a href="ItemServlet?action=delete&id=<%=i.getItemId()%>">Delete</a>
</td>
</tr>
<% } %>
</table>
</body>
</html>
