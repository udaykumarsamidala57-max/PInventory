<%@page import="java.util.*, java.time.*, java.time.format.*"%>

<%
    List<String> categoryList = (List<String>)request.getAttribute("categoryList");
    List<String> subCategoryList = (List<String>)request.getAttribute("subCategoryList");
    List<Map<String,Object>> itemList = (List<Map<String,Object>>)request.getAttribute("itemList");
    String selectedCategory = (String)request.getAttribute("selectedCategory");
    String selectedSubCategory = (String)request.getAttribute("selectedSubCategory");
    String selectedMonth = request.getParameter("filter_month");
    
    if(selectedMonth == null) selectedMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy-MM"));
    if(categoryList == null) categoryList = new ArrayList<>();
    if(subCategoryList == null) subCategoryList = new ArrayList<>();
    if(itemList == null) itemList = new ArrayList<>();
%>
<%@ include file="header.jsp" %>
<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/design-system/2.21.4/styles/salesforce-lightning-design-system.min.css" />

<div class="slds-container_large slds-container_center slds-p-around_medium">
    
    <article class="slds-card slds-m-bottom_medium">
        <div class="slds-card__body slds-card__body_inner slds-p-around_medium">
            <form action="StockVerificationServlet" method="get" class="slds-grid slds-wrap slds-gutters">
                <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-4">
                    <label class="slds-form-element__label">Category</label>
                    <select name="category" class="slds-select" onchange="this.form.submit()">
                        <option value="">All</option>
                        <% for(String cat : categoryList){ %>
                            <option value="<%=cat%>" <%=cat.equals(selectedCategory) ? "selected" : ""%>><%=cat%></option>
                        <% } %>
                    </select>
                </div>
                <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-4">
                    <label class="slds-form-element__label">Sub Category</label>
                    <select name="subcategory" class="slds-select">
                        <option value="">All</option>
                        <% for(String sub : subCategoryList){ %>
                            <option value="<%=sub%>" <%=sub.equals(selectedSubCategory) ? "selected" : ""%>><%=sub%></option>
                        <% } %>
                    </select>
                </div>
                <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-4">
                    <label class="slds-form-element__label">Month</label>
                    <input type="month" name="filter_month" value="<%=selectedMonth%>" class="slds-input">
                </div>
                <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-4 slds-m-top_large">
                    <button type="submit" class="slds-button slds-button_brand">Apply Filter</button>
                </div>
            </form>
        </div>
    </article>

    <form action="StockVerificationServlet" method="post">
        <input type="hidden" name="filter_month" value="<%=selectedMonth%>">
        
        <div class="slds-scrollable_x" style="border: 1px solid #dddbda; border-radius: 0.25rem;">
            <table class="slds-table slds-table_bordered slds-table_cell-buffer slds-table_col-bordered">
                <thead>
                    <tr class="slds-line-height_reset">
                        <th>Item</th><th>UOM</th>
                        <th class="slds-text-align_right">Opening</th>
                        <th class="slds-text-align_right">Purchase</th>
                        <th class="slds-text-align_right">Consume</th>
                        <th class="slds-text-align_right">Balance</th>
                        <th style="width:150px;">Physical Qty *</th>
                        <th>Remarks</th>
                    </tr>
                </thead>
                <tbody>
                    <% if(itemList.isEmpty()) { %>
                        <tr><td colspan="10" class="slds-text-align_center slds-p-around_large">No items found.</td></tr>
                    <% } %>
                    <% for(Map<String,Object> row : itemList){ %>
                        <tr>
                            
                            <td>
                                <%=row.get("item_name")%>
                                <input type="hidden" name="item_id" value="<%=row.get("item_id")%>">
                            </td>
                            <td><%=row.get("uom")%></td>
                            <td class="slds-text-align_right"><%=row.getOrDefault("opening_qty", 0.0)%></td>
                            <td class="slds-text-align_right"><%=row.getOrDefault("purchase_qty", 0.0)%></td>
                            <td class="slds-text-align_right"><%=row.getOrDefault("consume_qty", 0.0)%></td>
                            <td class="slds-text-align_right">
                                <%=row.getOrDefault("balance_qty", 0.0)%>
                                <input type="hidden" name="system_qty" value="<%=row.getOrDefault("balance_qty", 0.0)%>">
                            </td>
                            <td><input type="number" step="0.01" name="physical_qty" required class="slds-input" placeholder="0.00"></td>
                            <td><input type="text" name="remarks" class="slds-input" placeholder="Notes..."></td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <div class="slds-m-top_medium">
            <button type="submit" class="slds-button slds-button_brand">Save Verification</button>
        </div>
    </form>
</div>