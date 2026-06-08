<%@page import="java.util.*"%>

<%
List<String> categoryList = (List<String>)request.getAttribute("categoryList");
List<String> subCategoryList = (List<String>)request.getAttribute("subCategoryList");
List<Map<String,Object>> itemList = (List<Map<String,Object>>)request.getAttribute("itemList");
String selectedCategory = (String)request.getAttribute("selectedCategory");
String selectedSubCategory = (String)request.getAttribute("selectedSubCategory");

// Retrieve username from session, default to empty string if missing
String sessionUser = (String)session.getAttribute("username");
if(sessionUser == null) {
    sessionUser = "";
}

if(categoryList == null) categoryList = new ArrayList<>();
if(subCategoryList == null) subCategoryList = new ArrayList<>();
if(itemList == null) itemList = new ArrayList<>();
%>

<!-- Salesforce Lightning Design System (SLDS) Dependency -->
<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/design-system/2.21.4/styles/salesforce-lightning-design-system.min.css" />

<style>
    .custom-icon {
        background-color: #ba5340; /* Standard SLDS Inventory/Stock color icon */
        color: white;
        padding: 0.5rem;
        border-radius: .25rem;
        font-weight: bold;
    }
    .slds-card {
        border: 1px solid #dddbda;
        box-shadow: none;
    }
</style>
<head>
<title>Stock Verification</title>
</head>
<%@ include file="header.jsp" %>

<div class="slds-container_large slds-container_center slds-p-around_medium">
    
    

   
    <article class="slds-card slds-m-bottom_large">
        <div class="slds-card__body slds-card__body_inner slds-p-top_medium">
            <form action="StockVerificationServlet" method="get" class="slds-form slds-grid slds-wrap slds-gutters_direct slds-grid_vertical-align-end">
                
                <div class="slds-col slds-size_1-of-1 slds-medium-size_2-of-5 slds-form-element">
                    <label class="slds-form-element__label" for="category-select">Category</label>
                    <div class="slds-form-element__control">
                        <div class="slds-select_container">
                            <select name="category" id="category-select" class="slds-select">
                                <option value="">All</option>
                                <% for(String cat : categoryList){ %>
                                    <option value="<%=cat%>" <%=cat.equals(selectedCategory) ? "selected" : ""%>><%=cat%></option>
                                <% } %>
                            </select>
                        </div>
                    </div>
                </div>

                <div class="slds-col slds-size_1-of-1 slds-medium-size_2-of-5 slds-form-element">
                    <label class="slds-form-element__label" for="subcategory-select">Sub Category</label>
                    <div class="slds-form-element__control">
                        <div class="slds-select_container">
                            <select name="subcategory" id="subcategory-select" class="slds-select">
                                <option value="">All</option>
                                <% for(String sub : subCategoryList){ %>
                                    <option value="<%=sub%>" <%=sub.equals(selectedSubCategory) ? "selected" : ""%>><%=sub%></option>
                                <% } %>
                            </select>
                        </div>
                    </div>
                </div>

                <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-5 slds-m-top_medium">
                    <button type="submit" class="slds-button slds-button_brand slds-w-full">Filter</button>
                </div>
            </form>
        </div>
    </article>

    <!-- DATA ENTRY & VERIFICATION CARD -->
    <article class="slds-card">
        <form action="StockVerificationServlet" method="post">
            
            <div class="slds-card__body slds-card__body_inner">
                
                <!-- VERIFIED BY & OVERALL REMARKS (MOVED TO TOP) -->
                <div class="slds-form slds-m-top_medium slds-m-bottom_large" style="text-align: left;">
                    <div class="slds-grid slds-wrap slds-gutters">
                        
                        <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-form-element">
                            <label class="slds-form-element__label" for="verified-by">Verified By</label>
                            <div class="slds-form-element__control">
                                <input type="text" id="verified-by" name="verified_by" value="<%=sessionUser%>" readonly class="slds-input slds-text-color_weak" style="background-color: #f3f3f3; border-color: #e5e5e5; cursor: not-allowed;">
                            </div>
                        </div>

                        <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-form-element">
                            <label class="slds-form-element__label" for="overall-remarks">Overall Remarks</label>
                            <div class="slds-form-element__control">
                                <input type="text" id="overall-remarks" name="overall_remarks" class="slds-input" placeholder="Summary of overall physical verification">
                            </div>
                        </div>
                        
                    </div>
                </div>

                <!-- STOCK ITEMS TABLE -->
                <div class="slds-scrollable_x" style="border: 1px solid #dddbda; border-radius: 0.25rem;">
                    <table class="slds-table slds-table_bordered slds-table_cell-buffer slds-table_col-bordered">
                        <thead>
                            <tr class="slds-line-height_reset">
                                <th scope="col"><div class="slds-truncate" title="Category">Category</div></th>
                                <th scope="col"><div class="slds-truncate" title="Sub Category">Sub Category</div></th>
                                <th scope="col"><div class="slds-truncate" title="Item">Item</div></th>
                                <th scope="col"><div class="slds-truncate" title="UOM">UOM</div></th>
                                <th scope="col" class="slds-text-align_right"><div class="slds-truncate" title="System Qty">System Qty</div></th>
                                <th scope="col" style="width: 150px;"><div class="slds-truncate" title="Physical Qty">Physical Qty <span class="slds-required">*</span></div></th>
                                <th scope="col"><div class="slds-truncate" title="Remarks">Remarks</div></th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if(itemList.isEmpty()) { %>
                                <tr>
                                    <td colspan="7" class="slds-text-align_center slds-text-color_weak slds-p-around_large">
                                        No items found for the selected filters.
                                    </td>
                                </tr>
                            <% } %>
                            <% for(Map<String,Object> row : itemList){ %>
                                <tr class="slds-hint-parent">
                                    <td><div class="slds-truncate"><%=row.get("category")%></div></td>
                                    <td><div class="slds-truncate"><%=row.get("subcategory")%></div></td>
                                    <th scope="row">
                                        <div class="slds-truncate slds-text-link" title="<%=row.get("item_name")%>">
                                            <%=row.get("item_name")%>
                                        </div>
                                        <input type="hidden" name="item_id" value="<%=row.get("item_id")%>">
                                    </th>
                                    <td><div class="slds-truncate"><%=row.get("uom")%></div></td>
                                    <td class="slds-text-align_right">
                                        <div class="slds-truncate slds-font-weight_bold"><%=row.get("balance_qty")%></div>
                                        <input type="hidden" name="system_qty" value="<%=row.get("balance_qty")%>">
                                    </td>
                                    <td>
                                        <div class="slds-form-element">
                                            <div class="slds-form-element__control">
                                                <input type="number" step="0.01" name="physical_qty" required class="slds-input" placeholder="0.00">
                                            </div>
                                        </div>
                                    </td>
                                    <td>
                                        <div class="slds-form-element">
                                            <div class="slds-form-element__control">
                                                <input type="text" name="remarks" class="slds-input" placeholder="Notes...">
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- FOOTER ACTIONS -->
            <footer class="slds-card__footer slds-p-around_medium slds-theme_default" style="border-top: 1px solid #dddbda;">
                <div class="slds-grid slds-grid_align-end">
                    <button type="button" onclick="window.location.reload();" class="slds-button slds-button_neutral slds-m-right_small">Cancel</button>
                    <button type="submit" class="slds-button slds-button_brand">Save Verification</button>
                </div>
            </footer>

        </form>
    </article>

</div>