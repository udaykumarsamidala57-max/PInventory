<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
String user = (String) sess.getAttribute("username");
String role = (String) sess.getAttribute("role");
String dept = (String) sess.getAttribute("department");
if ((!"Global".equalsIgnoreCase(role) &&  !"Finance".equalsIgnoreCase(dept))) {

    out.println("<h3 style='color:red;text-align:center;'>Access Denied! You are not authorized.</h3>");
    return;
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Asset Configuration Control</title>
    <style>
        :root {
            --primary: #2563eb;
            --primary-hover: #1d4ed8;
            --success: #16a34a;
            --success-hover: #15803d;
            --bg-main: #f8fafc;
            --bg-card: #ffffff;
            --border: #e2e8f0;
            --text-main: #0f172a;
            --text-muted: #64748b;
        }

        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; 
            margin: 0; 
            padding: 32px; 
            background-color: var(--bg-main); 
            color: var(--text-main);
            line-height: 1.5;
        }

        .dashboard-card {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 28px;
            margin-bottom: 32px;
            box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.05), 0 2px 4px -2px rgb(0 0 0 / 0.05);
        }

        h2 { 
            margin-top: 0; 
            margin-bottom: 24px; 
            font-size: 1.4rem; 
            font-weight: 700; 
            letter-spacing: -0.02em;
            color: var(--text-main);
        }
        
        .form-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); 
            gap: 16px; 
            margin-bottom: 24px; 
        }
        
        .form-group { display: flex; flex-direction: column; }
        .form-group.span-2 { grid-column: span 2; }
        
        label { 
            font-size: 13px; 
            font-weight: 600; 
            margin-bottom: 6px; 
            color: var(--text-muted); 
        }
        
        input, select, textarea { 
            padding: 10px 14px; 
            border: 1px solid var(--border); 
            border-radius: 8px; 
            font-family: inherit; 
            font-size: 14px; 
            color: var(--text-main);
            background-color: #fff;
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }

        input:focus, select:focus, textarea:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
        }
        
        .btn-panel { 
            display: flex;
            gap: 12px;
            align-items: center;
            margin-top: 20px; 
        }
        
        .btn-primary { 
            background: var(--primary); 
            color: #fff; 
            border: 0; 
            padding: 10px 20px; 
            border-radius: 8px; 
            cursor: pointer; 
            font-weight: 600;
            font-size: 14px;
            transition: background 0.15s ease;
        }
        .btn-primary:hover { background: var(--primary-hover); }

        .btn-success { 
            background: var(--success); 
            color: #fff; 
            border: 0; 
            padding: 10px 20px; 
            border-radius: 8px; 
            cursor: pointer; 
            font-weight: 600;
            font-size: 14px;
            transition: background 0.15s ease;
        }
        .btn-success:hover { background: var(--success-hover); }
        
        .btn-secondary { 
            background: #fff; 
            color: var(--text-main); 
            text-decoration: none; 
            border: 1px solid var(--border); 
            padding: 9px 18px; 
            border-radius: 8px; 
            font-size: 14px;
            font-weight: 500;
            display: inline-flex;
            align-items: center;
            transition: background 0.15s ease;
        }
        .btn-secondary:hover { background: #f8fafc; }

        .matrix-toolbar {
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            margin-bottom: 20px;
            gap: 16px;
            flex-wrap: wrap;
        }

        .toolbar-filter {
            display: flex;
            gap: 12px;
            align-items: center;
        }
        
        .table-container {
            overflow-x: auto;
            border: 1px solid var(--border);
            border-radius: 10px;
            background: #fff;
        }

        table { width: 100%; border-collapse: collapse; font-size: 14px; text-align: left; }
        th, td { padding: 12px 16px; border-bottom: 1px solid var(--border); }
        
        th { 
            background: #f8fafc; 
            font-weight: 600; 
            color: var(--text-muted);
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }
        
        tr:last-child td { border-bottom: 0; }
        tr:hover { background: #fdfdfd; }

        /* Grouping UI Enhancements */
        .group-start {
            border-top: 2px solid #cbd5e1 !important;
            background-color: #fcfdfe;
        }
        .group-label {
            font-weight: 600;
            color: var(--primary);
        }
        
        .badge {
            display: inline-block;
            padding: 2px 8px;
            font-size: 12px;
            font-weight: 500;
            border-radius: 6px;
            background: #f1f5f9;
            color: var(--text-muted);
        }
    </style>
</head>
<body>
<%@ include file="../header.jsp" %>

    <!-- Asset Registration Form Section -->
    <div class="dashboard-card">
        <h2>Asset Profile Entry Form</h2>
        <form action="AssetServlet" method="post">
            <input type="hidden" name="assetId" value="${editableAsset.assetId}" />

            <div class="form-grid">
                <div class="form-group">
                    <label>Asset Code *</label>
                    <input type="text" name="assetCode" value="${editableAsset.assetCode}" required maxlength="50" />
                </div>
                <div class="form-group">
                    <label>Asset Name *</label>
                    <input type="text" name="assetName" value="${editableAsset.assetName}" required maxlength="150" />
                </div>
                
                <div style="grid-column: 1/-1;"></div>
                
                <div class="form-group">
                    <label>Category *</label>
                    <select id="categorySelect" name="categoryId" required onchange="filterSubcategories()">
                        <option value="">-- Select Category --</option>
                        <c:forEach var="cat" items="${categoriesList}">
                            <option value="${cat.id}" ${cat.id == editableAsset.categoryId ? 'selected="selected"' : ''}>
                                <c:out value="${cat.name}"/>
                            </option>
                        </c:forEach>
                    </select>
                </div>
                
                <div class="form-group">
                    <label>Subcategory</label>
                    <select id="subcategorySelect" name="subcategoryId">
                        <option value="">-- Select Subcategory --</option>
                        <c:forEach var="sub" items="${subcategoriesList}">
                            <option value="${sub.id}" 
                                    data-category="${sub.categoryId}" 
                                    ${sub.id == editableAsset.subcategoryId ? 'selected="selected"' : ''}>
                                <c:out value="${sub.name}"/>
                            </option>
                        </c:forEach>
                    </select>
                </div>
                
                
               <div class="form-group">
    <label>Vendor Name</label>
    <select id="vendorSelect" name="vendorName">
        <option value="">-- Select Vendor --</option>
        <c:forEach var="vendor" items="${vendorsList}">
            <option value="${vendor.name}" ${vendor.name == editableAsset.vendorName ? 'selected="selected"' : ''}>
                <c:out value="${vendor.name}"/>
            </option>
        </c:forEach>
    </select>
</div>
                
                
                <div class="form-group">
                    <label>Brand</label>
                    <input type="text" name="brand" value="${editableAsset.brand}" maxlength="100" />
                </div>
                <div class="form-group">
                    <label>Model Number</label>
                    <input type="text" name="modelNumber" value="${editableAsset.modelNumber}" maxlength="100" />
                </div>
                <div class="form-group">
                    <label>Serial Number</label>
                    <input type="text" name="serialNumber" value="${editableAsset.serialNumber}" maxlength="100" />
                </div>
                <div class="form-group">
                    <label>Purchase Date</label>
                    <input type="date" name="purchaseDate" value="${editableAsset.purchaseDate}" />
                </div>
                <div class="form-group">
                    <label>Purchase Cost</label>
                    <input type="number" step="0.01" name="purchaseCost" value="${editableAsset.purchaseCost}" />
                </div>
                <div class="form-group">
                    <label>Warranty Expiry</label>
                    <input type="date" name="warrantyExpiry" value="${editableAsset.warrantyExpiry}" />
                </div>
                <div class="form-group">
                    <label>Depreciation Method</label>
                    <input type="text" name="depreciationMethod" value="${editableAsset.depreciationMethod}" maxlength="500" />
                </div>
                <div class="form-group">
                    <label>Useful Life (Years)</label>
                    <input type="number" name="usefulLifeYears" value="${editableAsset.usefulLifeYears}" />
                </div>
                <div class="form-group">
                    <label>Salvage Value</label>
                    <input type="number" step="0.01" name="salvageValue" value="${editableAsset.salvageValue}" />
                </div>
                <div class="form-group">
                    <label>Asset Status</label>
                    <input type="text" name="assetStatus" value="${editableAsset.assetStatus}" maxlength="500" />
                </div>
                <div class="form-group">
                    <label>QR Code Location String</label>
                    <input type="text" name="qrCode" value="${editableAsset.qrCode}" maxlength="255" />
                </div>
                <div class="form-group span-2">
                    <label>Description Details</label>
                    <textarea name="description" rows="2">${editableAsset.description}</textarea>
                </div>
            </div>

            <div class="btn-panel">
                <button type="submit" class="btn-primary">
                    <c:choose>
                        <c:when test="${not empty editableAsset}">Update Asset</c:when>
                        <c:otherwise>Save New Asset</c:otherwise>
                    </c:choose>
                </button>
                <c:if test="${not empty editableAsset}">
                    <a href="AssetServlet" class="btn-secondary">Cancel Edit</a>
                </c:if>
            </div>
        </form>
    </div>

    <!-- Live Management Matrix Area -->
    <div class="dashboard-card">
        <div class="matrix-toolbar">
            <div>
                <h2>Registered Assets</h2>
            </div>
            <div class="toolbar-filter">
                <div class="form-group" style="margin: 0;">
                    <select id="matrixCategoryFilter" onchange="filterMatrixByCategory()" style="padding: 8px 12px; font-size: 13px;">
                        <option value="ALL">All Categories</option>
                        <c:forEach var="cat" items="${categoriesList}">
                            <option value="${cat.name}"><c:out value="${cat.name}"/></option>
                        </c:forEach>
                    </select>
                </div>
                <button type="button" onclick="exportToExcel()" class="btn-success" style="padding: 8px 14px; font-size: 13px;">
                    Export Excel
                </button>
            </div>
        </div>
        
        <div class="table-container">
            <table id="assetDataTable">
                <thead>
                    <tr>
                        <th>Actions</th>
                        <th>Code</th>
                        <th>Name</th>
                        <th>Classification (Cat / Sub)</th>
                        <th>Vendor</th>
                        <th>Brand/Model</th>
                        <th>Serial No</th>
                        <th>Purchase Date</th>
                        <th>Cost</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <!-- Local variable pointers initialization tracking group row boundaries -->
                    <c:set var="prevGroup" value="" />
                    <c:forEach var="item" items="${assetList}">
                        <!-- Build distinct group parsing logic token out of text values -->
                        <c:set var="currentGroup" value="${item.categoryName} // ${item.subcategoryName}" />
                        
                        <tr class="asset-row ${currentGroup != prevGroup ? 'group-start' : ''}" data-category-name="${item.categoryName}">
                            <td>
                                <a href="AssetServlet?action=edit&id=${item.assetId}" class="btn-secondary" style="padding: 4px 8px; font-size: 12px; border-radius: 6px;">Edit</a>
                            </td>
                            <td><strong><c:out value="${item.assetCode}"/></strong></td>
                            <td><c:out value="${item.assetName}"/></td>
                            <td data-group-token="${currentGroup}">
                                <c:choose>
                                    <c:when test="${not empty item.categoryName}">
                                        <span class="${currentGroup != prevGroup ? 'group-label' : ''}"><c:out value="${item.categoryName}"/></span>
                                        <c:if test="${not empty item.subcategoryName}">
                                             / <span style="color: var(--text-muted);"><c:out value="${item.subcategoryName}"/></span>
                                        </c:if>
                                    </c:when>
                                    <c:otherwise>
                                        <span style="color: #999; font-style: italic;">Unassigned</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td><c:out value="${item.vendorName}"/></td>
                            <td><c:out value="${item.brand}"/> <c:out value="${item.modelNumber}"/></td>
                            <td><c:out value="${item.serialNumber}"/></td>
                            <td><c:out value="${item.purchaseDate}"/></td>
                            <td>
                                <c:if test="${not empty item.purchaseCost}">
                                    $<c:out value="${item.purchaseCost}"/>
                                </c:if>
                            </td>
                            <td>
                                <span class="badge"><c:out value="${item.assetStatus}"/></span>
                            </td>
                        </tr>
                        <c:set var="prevGroup" value="${currentGroup}" />
                    </c:forEach>
                    <c:if test="${empty assetList}">
                        <tr id="emptyRowPlaceholder">
                            <td colspan="10" style="text-align: center; color: var(--text-muted); padding: 32px;">No registered infrastructure assets discovered.</td>
                        </tr>
                    </c:if>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Scripting Routine Core Framework Blocks -->
    <script type="text/javascript">
        // Cascading logic linking input categories down to matching child elements
        function filterSubcategories() {
            var categorySelect = document.getElementById("categorySelect");
            var subcategorySelect = document.getElementById("subcategorySelect");
            var selectedCategoryId = categorySelect.value;
            var options = subcategorySelect.options;
            
            for (var i = 1; i < options.length; i++) {
                var option = options[i];
                var optionCatId = option.getAttribute("data-category");
                
                if (selectedCategoryId === "" || optionCatId === selectedCategoryId) {
                    option.style.display = "";
                } else {
                    option.style.display = "none";
                    if (option.selected) { subcategorySelect.value = ""; }
                }
            }
        }

        // Live category UI display matching filter routine
        function filterMatrixByCategory() {
            var filterValue = document.getElementById("matrixCategoryFilter").value;
            var rows = document.getElementsByClassName("asset-row");
            var visibleCount = 0;
            
            for (var i = 0; i < rows.length; i++) {
                var row = rows[i];
                var rowCat = row.getAttribute("data-category-name");
                
                if (filterValue === "ALL" || rowCat === filterValue) {
                    row.style.display = "";
                    visibleCount++;
                } else {
                    row.style.display = "none";
                }
            }
            
            // Handle row visually separating lines reconfiguration during multi-row hidden states
            recalculateVisibleGroupingBorders(filterValue);
        }

        // dynamically resets grouping styling classes when items are filtered out
        function recalculateVisibleGroupingBorders(filterActive) {
            var rows = document.querySelectorAll(".asset-row");
            var lastGroupToken = "";
            
            rows.forEach(function(row) {
                if (row.style.display === "none") return;
                
                var cell = row.querySelector("td[data-group-token]");
                var currentToken = cell ? cell.getAttribute("data-group-token") : "";
                
                if (filterActive !== "ALL" || currentToken !== lastGroupToken) {
                    row.classList.add("group-start");
                    var labelSpan = row.querySelector(".group-label");
                    if (labelSpan) labelSpan.style.fontWeight = "600";
                } else {
                    row.classList.remove("group-start");
                }
                lastGroupToken = currentToken;
            });
        }

        // Standalone safe pure client-side raw data Microsoft Excel layout pipeline
        function exportToExcel() {
            var table = document.getElementById("assetDataTable");
            var html = table.outerHTML;
            
            // Strip structural application operation components cleanly from the binary stream wrapper
            html = html.replace(/<th>Actions<\/th>/g, "")
                       .replace(/<td>\s*<a[^>]*>Edit<\/a>\s*<\/td>/g, "");

            var blob = new Blob([html], {
                type: "application/vnd.ms-excel;charset=utf-8;"
            });
            
            var link = document.createElement("a");
            var url = URL.createObjectURL(blob);
            link.href = url;
            link.setAttribute("download", "Asset_Configuration_Matrix.xls");
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }

        // Trigger loading behaviors explicitly on window instantiation sequences
        window.onload = function() {
            if (document.getElementById("categorySelect").value !== "") {
                filterSubcategories();
            }
        };
    </script>
</body>
</html>