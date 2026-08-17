<%@page import="java.sql.*"%>
<%@page import="com.bean.DBUtil"%>

<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
String branch = (String) sess.getAttribute("branch");

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String category = request.getParameter("category");
String subCategory = request.getParameter("subcategory");

try {
    con = DBUtil.getConnection(branch);
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Item Master</title>

<style>
/* Salesforce Lightning Design System (SLDS) Core Tokens */
:root {
    --slds-g-color-neutral-base-10: #f3f3f3;
    --slds-g-color-neutral-base-100: #ffffff;
    --slds-text-color: #181818;
    --slds-text-weak: #444444;
    --slds-font-family: 'Salesforce Sans', Arial, sans-serif;
    --slds-brand-primary: #0176d3;
    --slds-brand-primary-hover: #014b96;
    --slds-border-color: #c9c9c9;
    --slds-table-header-bg: #fafaf9;
    --slds-table-hover-bg: #f3f3f3;
    --slds-radius: 0.5rem;
    --slds-radius-small: 0.25rem;
}

body {
    font-family: var(--slds-font-family);
    background-color: var(--slds-g-color-neutral-base-10);
    color: var(--slds-text-color);
    margin: 0;
    padding: 0;
}

.slds-page-container {
    padding: 1.5rem;
    max-width: 1600px;
    margin: 0 auto;
}

/* Salesforce Card Layout */
.slds-card {
    background-color: var(--slds-g-color-neutral-base-100);
    border: 1px solid var(--slds-border-color);
    border-radius: var(--slds-radius);
    margin-bottom: 1.5rem;
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.05);
}

.slds-card__header {
    padding: 1rem 1.5rem;
    border-bottom: 1px solid var(--slds-border-color);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.slds-card__title {
    font-size: 1.25rem;
    font-weight: 700;
    color: var(--slds-text-color);
}

/* Salesforce Grid Filters */
.slds-filters-grid {
    padding: 1.25rem 1.5rem;
    background-color: #fafaf9;
    border-bottom: 1px solid var(--slds-border-color);
    display: flex;
    flex-wrap: wrap;
    align-items: flex-end;
    gap: 1.25rem;
}

.slds-form-element {
    display: flex;
    flex-direction: column;
}

.slds-form-element__label {
    font-size: 0.75rem;
    font-weight: 600;
    color: var(--slds-text-weak);
    margin-bottom: 0.25rem;
}

/* Salesforce Inputs and Utilities */
.slds-select {
    font-family: var(--slds-font-family);
    font-size: 0.8125rem;
    height: 2rem;
    width: 260px;
    padding: 0 1rem 0 0.75rem;
    border: 1px solid var(--slds-border-color);
    border-radius: var(--slds-radius-small);
    background-color: var(--slds-g-color-neutral-base-100);
    color: var(--slds-text-color);
    outline: none;
    transition: border-color 0.1s linear, box-shadow 0.1s linear;
}

.slds-select:focus {
    border-color: var(--slds-brand-primary);
    box-shadow: 0 0 3px #0176d3;
}

/* Standard Lightning Buttons */
.slds-button_brand {
    font-family: var(--slds-font-family);
    font-size: 0.8125rem;
    font-weight: 500;
    height: 2rem;
    padding: 0 1rem;
    background-color: var(--slds-brand-primary);
    color: #ffffff;
    border: 1px solid var(--slds-brand-primary);
    border-radius: var(--slds-radius-small);
    cursor: pointer;
    text-align: center;
    transition: background-color 0.1s linear;
}

.slds-button_brand:hover {
    background-color: var(--slds-brand-primary-hover);
    border-color: var(--slds-brand-primary-hover);
}

/* Salesforce Classic Table Element */
.slds-table_container {
    overflow-x: auto;
}

.slds-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.8125rem;
    background-color: var(--slds-g-color-neutral-base-100);
}

/* Interactive Sortable Headers */
.slds-table th {
    background-color: var(--sap-table-header-bg, var(--slds-table-header-bg));
    color: var(--slds-text-weak);
    font-weight: 600;
    text-transform: uppercase;
    font-size: 0.75rem;
    letter-spacing: 0.03rem;
    padding: 0.5rem 0.75rem;
    border-bottom: 1px solid var(--slds-border-color);
}

.slds-table th.sortable {
    cursor: pointer;
    user-select: none;
    transition: background-color 0.1s ease;
}

.slds-table th.sortable:hover {
    background-color: #f3f2f2;
    color: var(--slds-brand-primary);
}

.sort-icon {
    margin-left: 0.25rem;
    font-size: 0.75rem;
    display: inline-block;
    color: #909090;
}

.slds-table td {
    padding: 0.75rem;
    border-bottom: 1px solid var(--slds-border-color);
    color: var(--slds-text-color);
    white-space: nowrap;
}

.slds-table tbody tr:hover {
    background-color: var(--slds-table-hover-bg);
}

.slds-table tbody tr:last-child td {
    border-bottom: none;
}

/* Structural Alignment Overrides */
.text-center {
    text-align: center;
}
.cell-link {
    color: var(--slds-brand-primary);
    text-decoration: none;
    font-weight: 600;
}
.cell-link:hover {
    text-decoration: underline;
}
</style>

<script>
function loadSubCategory(){
    document.getElementById("filterForm").submit();
}

// Client-Side lightning Sorting Engine
let currentDirection = 'asc';

function sortTable(columnIndex) {
    const table = document.querySelector(".slds-table");
    const tbody = table.querySelector("tbody");
    const rows = Array.from(tbody.querySelectorAll("tr"));
    
    // Fallback if no records found row is present
    if (rows.length === 1 && rows[0].cells.length === 1) return;

    // Toggle sorting directions
    currentDirection = (currentDirection === 'asc') ? 'desc' : 'asc';

    // Clear previous indicator glyphs, restore standard look
    document.querySelectorAll('.sort-icon').forEach(icon => icon.textContent = '↕');

    // Update active sorted heading indicator
    const activeHeader = table.querySelectorAll("th")[columnIndex];
    const activeIcon = activeHeader.querySelector(".sort-icon");
    activeIcon.textContent = (currentDirection === 'asc') ? '▲' : '▼';

    // Execution Sort Logic
    rows.sort((rowA, rowB) => {
        const cellA = rowA.cells[columnIndex].textContent.trim();
        const cellB = rowB.cells[columnIndex].textContent.trim();

        // Numeric evaluation if columns are completely numeric digits
        if (!isNaN(cellA) && !isNaN(cellB) && cellA !== "" && cellB !== "") {
            return currentDirection === 'asc' ? cellA - cellB : cellB - cellA;
        }

        // Standard local alphabetical sorting
        return currentDirection === 'asc' 
            ? cellA.localeCompare(cellB, undefined, {numeric: true, sensitivity: 'base'})
            : cellB.localeCompare(cellA, undefined, {numeric: true, sensitivity: 'base'});
    });

    // Re-append items into the DOM layout matrix
    rows.forEach(row => tbody.appendChild(row));
}
</script>

</head>
<body>
<%@ include file="header.jsp" %>

<div class="slds-page-container">

    <div class="slds-card">
        
        <div class="slds-card__header">
            <span class="slds-card__title">Item Masters</span>
        </div>

        <form method="get" id="filterForm" class="slds-filters-grid">
        
            <div class="slds-form-element">
                <label class="slds-form-element__label">Category</label>
                <select name="category" class="slds-select" onchange="loadSubCategory()">
                    <option value="">-- Select Category --</option>
                    <%
                    ps = con.prepareStatement("SELECT DISTINCT category FROM item_master ORDER BY category");
                    rs = ps.executeQuery();
                    while(rs.next()){
                        String cat = rs.getString("category");
                    %>
                        <option value="<%=cat%>" <%=cat.equals(category)?"selected":""%>><%=cat%></option>
                    <%
                    }
                    rs.close();
                    ps.close();
                    %>
                </select>
            </div>

            <div class="slds-form-element">
                <label class="slds-form-element__label">Sub Category</label>
                <select name="subcategory" class="slds-select">
                    <option value="">-- All --</option>
                    <%
                    if(category != null && !category.trim().isEmpty()){
                        ps = con.prepareStatement(
                            "SELECT DISTINCT sub_category FROM item_master WHERE category=? ORDER BY sub_category");
                        ps.setString(1, category);
                        rs = ps.executeQuery();
                        while(rs.next()){
                            String sub = rs.getString("sub_category");
                    %>
                        <option value="<%=sub%>" <%=sub.equals(subCategory)?"selected":""%>><%=sub%></option>
                    <%
                        }
                        rs.close();
                        ps.close();
                    }
                    %>
                </select>
            </div>

            <div class="slds-form-element">
                <button type="submit" class="slds-button_brand">Search</button>
            </div>
            
        </form>

        <div class="slds-table_container">
            <table class="slds-table">
                <thead>
                    <tr>
                        <th class="sortable text-center" style="width: 90px;" onclick="sortTable(0)">Item ID <span class="sort-icon">↕</span></th>
                        <th class="sortable" onclick="sortTable(1)">Category <span class="sort-icon">↕</span></th>
                        <th class="sortable" onclick="sortTable(2)">Sub Category <span class="sort-icon">↕</span></th>
                        <th class="sortable" onclick="sortTable(3)">Item Name <span class="sort-icon">▲</span></th>
                        <th class="sortable" onclick="sortTable(4)">UOM <span class="sort-icon">↕</span></th>
                        <th class="sortable" onclick="sortTable(5)">Description <span class="sort-icon">↕</span></th>
                    </tr>
                </thead>
                <tbody>
                <%
                // Initial Default Server-side Fetch ordered alphabetically by item_name
                String sql = "SELECT * FROM item_master WHERE 1=1 ";
                if(category != null && !category.trim().isEmpty()){
                    sql += " AND category=? ";
                }
                if(subCategory != null && !subCategory.trim().isEmpty()){
                    sql += " AND sub_category=? ";
                }
                sql += " ORDER BY item_name ASC";
                
                ps = con.prepareStatement(sql);
                int index = 1;
                if(category != null && !category.trim().isEmpty()){
                    ps.setString(index++, category);
                }
                if(subCategory != null && !subCategory.trim().isEmpty()){
                    ps.setString(index++, subCategory);
                }
                
                rs = ps.executeQuery();
                boolean dataFound = false;
                while(rs.next()){
                    dataFound = true;
                %>
                    <tr>
                        <td class="text-center"><a href="#" class="cell-link"><%=rs.getInt("item_id")%></a></td>
                        <td><%=rs.getString("category")%></td>
                        <td><%=rs.getString("sub_category")%></td>
                        <td><strong><%=rs.getString("item_name")%></strong></td>
                        <td><%=rs.getString("uom")%></td>
                        <td><%=rs.getString("desci") != null ? rs.getString("desci") : ""%></td>
                    </tr>
                <%
                }
                if(!dataFound){
                %>
                    <tr>
                        <td colspan="6" style="text-align: center; color: #747474; padding: 3rem; font-size: 0.875rem;">No records to display.</td>
                    </tr>
                <%
                }
                %>
                </tbody>
            </table>
        </div>
    </div>
</div>

</body>
</html>

<%
} catch(Exception e){
    out.println("<div style='color:#ea001e; padding:20px; font-family:sans-serif;'><strong>Review the following component errors:</strong> " + e.getMessage() + "</div>");
} finally{
    try{ if(rs!=null) rs.close(); }catch(Exception e){}
    try{ if(ps!=null) ps.close(); }catch(Exception e){}
    try{ if(con!=null) con.close(); }catch(Exception e){}
}
%>