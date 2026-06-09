<%@page import="java.util.*"%>

<%
List<Map<String,Object>> reportList =
(List<Map<String,Object>>)request.getAttribute("reportList");

if(reportList == null){
    reportList = new ArrayList<>();
}
%>

<%@ include file="header.jsp" %>

<h2>Dining Hall Consumption Report</h2>

<form method="get"
      action="DiningHallConsumptionReportServlet">

    From Date:
    <input type="date"
           name="from_date">

    To Date:
    <input type="date"
           name="to_date">

    Session:
    <select name="session">
        <option value="">All</option>
        <option value="BREAKFAST">BREAKFAST</option>
        <option value="LUNCH">LUNCH</option>
        <option value="SNACKS">SNACKS</option>
        <option value="DINNER">DINNER</option>
    </select>

    <input type="submit"
           value="Search">
</form>

<br>

<table border="1"
       cellpadding="5"
       cellspacing="0"
       width="100%">

    <tr>
        <th>Date</th>
        <th>Session</th>
        <th>Item</th>
        <th>UOM</th>
        <th>Quantity</th>
        <th>Value</th>
    </tr>

    <%
    double grandTotal = 0;

    for(Map<String,Object> row : reportList){

        grandTotal +=
        ((Number)row.get("value")).doubleValue();
    %>

    <tr>
        <td><%=row.get("issue_day")%></td>
        <td><%=row.get("session")%></td>
        <td><%=row.get("item_name")%></td>
        <td><%=row.get("uom")%></td>
        <td align="right">
            <%=row.get("qty")%>
        </td>
        <td align="right">
            <%=row.get("value")%>
        </td>
    </tr>

    <% } %>

    <tr>
        <th colspan="5">
            Grand Total
        </th>
        <th>
            <%=grandTotal%>
        </th>
    </tr>

</table>