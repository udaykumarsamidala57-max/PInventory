<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="com.website.bean.WebsiteDB" %>
<%@ page import="com.website.bean.PhotoUpload" %>

<%!
    // Helper method to sanitize HTML output and prevent XSS vulnerabilities
    private String escapeHtml(String input) {
        if (input == null) return "";
        return input.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#x27;");
    }
%>

<%
    HttpSession sess = request.getSession(false);

    if (!WebsiteDB.guard(request, response)) return;

    String branch = WebsiteDB.site(sess);
    String editId = request.getParameter("edit");

    String eventName = "";
    String description = "";
    String base64Image = "";
    int id = 0;

    if (editId != null && !editId.trim().isEmpty()) {
        String sql = "SELECT * FROM latest_news WHERE id=?";
        try (Connection con = WebsiteDB.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, Integer.parseInt(editId));

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    id = rs.getInt("id");
                    eventName = rs.getString("event_name");
                    description = rs.getString("description");

                    String editKey = null;
                    try { editKey = rs.getString("file_key"); } catch (SQLException noColumn) { }
                    byte[] imgBytes = (editKey != null && !editKey.trim().isEmpty()) ? null : rs.getBytes("image");
                    base64Image = PhotoUpload.src(editKey, imgBytes);
                }
            }
        } catch (NumberFormatException e) {
            // Handle invalid ID format gracefully
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Latest News Management</title>
    
    <!-- Google Fonts & Salesforce-Style Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">

    <style>
        :root {
            --slds-blue: #0176d3;
            --slds-blue-hover: #014486;
            --slds-bg: #f3f3f3;
            --slds-surface: #ffffff;
            --slds-border: #dddbda;
            --slds-text-main: #181818;
            --slds-text-label: #444444;
            --slds-text-muted: #706e6b;
            --slds-radius: 4px;
            --slds-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.08);
            --slds-danger: #ba0517;
            --slds-danger-bg: #fef2f2;
            --slds-danger-border: #fe8f8f;
            --slds-success: #2e844a;
            --slds-success-bg: #f0fdf4;
            --slds-success-border: #91e0a6;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background-color: var(--slds-bg);
            color: var(--slds-text-main);
            line-height: 1.4;
            padding-bottom: 30px;
            font-size: 0.875rem;
        }

        .container {
            max-width: 1050px;
            margin: 16px auto 0;
            padding: 0 16px;
        }

        /* Compact Header Banner */
        .page-header {
            background: var(--slds-surface);
            border: 1px solid var(--slds-border);
            border-radius: var(--slds-radius);
            padding: 12px 16px;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            box-shadow: var(--slds-shadow);
        }

        .page-header-title {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .page-header-icon {
            background: #e0f2fe;
            color: var(--slds-blue);
            width: 32px;
            height: 32px;
            border-radius: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.1rem;
        }

        .page-header h1 {
            font-size: 1.1rem;
            font-weight: 700;
            color: var(--slds-text-main);
        }

        .page-header p {
            color: var(--slds-text-muted);
            font-size: 0.775rem;
        }

        /* Alert Banners */
        .alert {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 8px 12px;
            border-radius: var(--slds-radius);
            font-weight: 500;
            font-size: 0.825rem;
            margin-bottom: 12px;
        }
        .alert-error {
            background-color: var(--slds-danger-bg);
            color: var(--slds-danger);
            border: 1px solid var(--slds-danger-border);
        }
        .alert-success {
            background-color: var(--slds-success-bg);
            color: var(--slds-success);
            border: 1px solid var(--slds-success-border);
        }

        /* Form Card */
        .form-card {
            background: var(--slds-surface);
            border-radius: var(--slds-radius);
            padding: 16px;
            margin-bottom: 20px;
            box-shadow: var(--slds-shadow);
            border: 1px solid var(--slds-border);
        }

        .form-card-header {
            font-size: 0.95rem;
            font-weight: 700;
            margin-bottom: 12px;
            padding-bottom: 8px;
            border-bottom: 1px solid var(--slds-border);
            display: flex;
            align-items: center;
            gap: 8px;
            color: var(--slds-text-main);
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }

        .form-grid {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .form-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .form-group label {
            font-size: 0.75rem;
            font-weight: 600;
            color: var(--slds-text-label);
            text-transform: uppercase;
            letter-spacing: 0.02em;
        }

        .required-asterisk {
            color: var(--slds-danger);
        }

        .form-control {
            width: 100%;
            padding: 6px 10px;
            font-family: inherit;
            font-size: 0.85rem;
            color: var(--slds-text-main);
            background-color: #fff;
            border: 1px solid var(--slds-border);
            border-radius: var(--slds-radius);
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }

        .form-control:focus {
            outline: none;
            border-color: var(--slds-blue);
            box-shadow: 0 0 0 1px var(--slds-blue);
        }

        textarea.form-control {
            resize: vertical;
            min-height: 54px;
        }

        /* File Upload Component */
        .file-upload-wrapper {
            position: relative;
            border: 1px dashed var(--slds-border);
            border-radius: var(--slds-radius);
            padding: 8px 12px;
            text-align: center;
            background: #fafafa;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .file-upload-wrapper:hover {
            border-color: var(--slds-blue);
            background: #f4f6f9;
        }

        .file-upload-wrapper input[type="file"] {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            opacity: 0;
            cursor: pointer;
        }

        .file-upload-icon {
            font-size: 1rem;
            color: var(--slds-blue);
        }

        .file-upload-text {
            font-size: 0.8rem;
            color: var(--slds-text-muted);
        }

        /* Buttons */
        .btn-group {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-top: 4px;
            align-self: flex-start;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            padding: 6px 14px;
            font-size: 0.825rem;
            font-weight: 600;
            border-radius: var(--slds-radius);
            border: 1px solid transparent;
            cursor: pointer;
            text-decoration: none;
            transition: background-color 0.15s ease;
        }

        .btn-primary {
            background-color: var(--slds-blue);
            color: white;
        }

        .btn-primary:hover {
            background-color: var(--slds-blue-hover);
        }

        .btn-secondary {
            background-color: #f3f3f3;
            color: var(--slds-text-main);
            border-color: var(--slds-border);
        }

        .btn-secondary:hover {
            background-color: #e5e5e5;
        }

        .btn-danger {
            background-color: var(--slds-danger-bg);
            color: var(--slds-danger);
            border-color: var(--slds-danger-border);
        }

        .btn-danger:hover {
            background-color: #fee2e2;
        }

        .btn-sm {
            padding: 3px 8px;
            font-size: 0.775rem;
        }

        /* Image Previews */
        .current-image-wrapper {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-top: 4px;
        }

        .img-preview {
            width: 36px;
            height: 36px;
            object-fit: cover;
            border-radius: var(--slds-radius);
            border: 1px solid var(--slds-border);
        }

        /* Table Card & Data Grid */
        .section-title {
            font-size: 0.95rem;
            font-weight: 700;
            margin-bottom: 10px;
            color: var(--slds-text-main);
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }

        .table-card {
            background: var(--slds-surface);
            border-radius: var(--slds-radius);
            box-shadow: var(--slds-shadow);
            border: 1px solid var(--slds-border);
            overflow: hidden;
        }

        .table-wrapper {
            overflow-x: auto;
        }

        .slds-table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
            font-size: 0.825rem;
        }

        .slds-table th {
            background-color: #fafafa;
            color: var(--slds-text-label);
            font-weight: 700;
            padding: 8px 12px;
            border-bottom: 1px solid var(--slds-border);
            text-transform: uppercase;
            font-size: 0.725rem;
            letter-spacing: 0.04em;
        }

        .slds-table td {
            padding: 8px 12px;
            border-bottom: 1px solid var(--slds-border);
            vertical-align: middle;
            color: var(--slds-text-main);
        }

        .slds-table tbody tr:last-child td {
            border-bottom: none;
        }

        .slds-table tbody tr:hover {
            background-color: #f4f6f9;
        }

        .no-img-badge {
            display: inline-block;
            padding: 2px 6px;
            background-color: #f3f3f3;
            color: var(--slds-text-muted);
            font-size: 0.725rem;
            border-radius: 2px;
            border: 1px solid #e5e5e5;
        }

        .actions-cell {
            white-space: nowrap;
            display: flex;
            gap: 6px;
        }
    </style>
</head>

<body>
    <jsp:include page="/WEB-INF/views/layout/header.jsp" />
    <link rel="stylesheet" href="${pageContext.request.contextPath}/website/css/erp-shell.css?v=20261020a">

    <div class="container">

        <!-- Header -->
        <div class="page-header">
            <div class="page-header-title">
                <div class="page-header-icon">
                    <i class="bi bi-newspaper"></i>
                </div>
                <div>
                    <h1>Latest News Workspace</h1>
                    <p>Publish and update organization news records</p>
                </div>
            </div>
        </div>

        <!-- Alert Notifications -->
        <%
            String success = request.getParameter("success");
            String error = request.getParameter("error");

            if ("added".equals(success)) {
        %>
            <div class="alert alert-success">
                <i class="bi bi-check-circle-fill"></i>
                <div>News entry created successfully.</div>
            </div>
        <%
            } else if ("updated".equals(success)) {
        %>
            <div class="alert alert-success">
                <i class="bi bi-check-circle-fill"></i>
                <div>News entry updated successfully.</div>
            </div>
        <%
            } else if ("deleted".equals(success)) {
        %>
            <div class="alert alert-success">
                <i class="bi bi-check-circle-fill"></i>
                <div>News entry deleted successfully.</div>
            </div>
        <%
            } else if ("1".equals(error)) {
        %>
            <div class="alert alert-error">
                <i class="bi bi-exclamation-triangle-fill"></i>
                <div>An error occurred while processing your request. Please try again.</div>
            </div>
        <%
            }
        %>

        <!-- Form Panel -->
        <div class="form-card">
            <div class="form-card-header">
                <i class="bi bi-pencil-square" style="color: var(--slds-blue);"></i>
                <%= (editId == null || editId.trim().isEmpty()) ? "New Entry Record" : "Edit Entry Record" %>
            </div>
            
            <form action="LatestNewsServlet" method="post" enctype="multipart/form-data">
                <div class="form-grid">

                    <% if (editId == null || editId.trim().isEmpty()) { %>
                        <input type="hidden" name="action" value="add">
                    <% } else { %>
                        <input type="hidden" name="action" value="update">
                        <input type="hidden" name="id" value="<%= id %>">
                    <% } %>

                    <div class="form-group">
                        <label for="event_name">Event Name <span class="required-asterisk">*</span></label>
                        <input type="text" id="event_name" class="form-control" name="event_name" value="<%= escapeHtml(eventName) %>" placeholder="Enter primary title" required>
                    </div>

                    <div class="form-row">
                        <div class="form-group" style="flex: 2;">
                            <label for="description">Description <span class="required-asterisk">*</span></label>
                            <textarea id="description" class="form-control" name="description" placeholder="Brief event details..." required><%= escapeHtml(description) %></textarea>
                        </div>

                        <div class="form-group" style="flex: 1;">
                            <label>Thumbnail Image <%= (editId == null || editId.trim().isEmpty()) ? "<span class='required-asterisk'>*</span>" : "" %></label>
                            <div class="file-upload-wrapper">
                                <input type="file" id="image" name="image" accept="image/*" <%= (editId == null || editId.trim().isEmpty()) ? "required" : "" %> onchange="updateFileName(this)">
                                <i class="bi bi-paperclip file-upload-icon"></i>
                                <span class="file-upload-text" id="file-label">Attach Image</span>
                            </div>
                            
                            <% if (!base64Image.isEmpty()) { %>
                                <div class="current-image-wrapper">
                                    <img src="<%= base64Image %>" class="img-preview" alt="Current Image">
                                    <span style="font-size: 0.75rem; color: var(--slds-text-muted);">Current Active</span>
                                </div>
                            <% } %>
                        </div>
                    </div>

                    <div class="btn-group">
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-check2"></i> <%= (editId == null || editId.trim().isEmpty()) ? "Save Record" : "Update Record" %>
                        </button>
                        <% if (editId != null && !editId.trim().isEmpty()) { %>
                            <a href="latestNews.jsp" class="btn btn-secondary">Cancel</a>
                        <% } %>
                    </div>

                </div>
            </form>
        </div>

        <!-- Data Grid Section -->
        <div class="section-title">News Records</div>

        <div class="table-card">
            <div class="table-wrapper">
                <table class="slds-table">
                    <thead>
                        <tr>
                            <th style="width: 5%;">ID</th>
                            <th style="width: 8%;">Preview</th>
                            <th style="width: 25%;">Event Name</th>
                            <th style="width: 37%;">Description</th>
                            <th style="width: 15%;">Date Created</th>
                            <th style="width: 10%;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            String sqlList = "SELECT * FROM latest_news ORDER BY created_at DESC";

                            try (Connection con = WebsiteDB.getConnection(branch);
                                 PreparedStatement ps = con.prepareStatement(sqlList);
                                 ResultSet rs = ps.executeQuery()) {

                                boolean found = false;

                                while (rs.next()) {
                                    found = true;
                                    String rowKey = null;
                                    try { rowKey = rs.getString("file_key"); } catch (SQLException noColumn) { }
                                    byte[] imgBytes = (rowKey != null && !rowKey.trim().isEmpty()) ? null : rs.getBytes("image");
                                    String rowBase64Image = PhotoUpload.src(rowKey, imgBytes);
                                    
                                    int rowId = rs.getInt("id");
                                    String rowEvent = rs.getString("event_name");
                                    String rowDesc = rs.getString("description");
                                    Timestamp rowCreated = rs.getTimestamp("created_at");
                        %>
                        <tr>
                            <td><strong>#<%= rowId %></strong></td>
                            <td>
                                <% if (!rowBase64Image.isEmpty()) { %>
                                    <img src="<%= rowBase64Image %>" class="img-preview" alt="News Image">
                                <% } else { %>
                                    <span class="no-img-badge">None</span>
                                <% } %>
                            </td>
                            <td><strong style="color: var(--slds-blue);"><%= escapeHtml(rowEvent) %></strong></td>
                            <td style="color: var(--slds-text-label);"><%= escapeHtml(rowDesc) %></td>
                            <td style="white-space: nowrap; color: var(--slds-text-muted);"><%= rowCreated != null ? rowCreated.toString().substring(0, 16) : "" %></td>
                            <td class="actions-cell">
                                <a href="latestNews.jsp?edit=<%= rowId %>" class="btn btn-secondary btn-sm">Edit</a>
                                <a href="LatestNewsServlet?action=delete&amp;id=<%= rowId %>" class="btn btn-danger btn-sm" onclick="return confirm('Permanently delete this news record?');">Delete</a>
                            </td>
                        </tr>
                        <%
                                }
                                if (!found) {
                        %>
                        <tr>
                            <td colspan="6" style="text-align: center; color: var(--slds-text-muted); padding: 16px;">
                                <em>No news records found.</em>
                            </td>
                        </tr>
                        <%
                                }
                            } catch (Exception e) {
                                e.printStackTrace();
                        %>
                        <tr>
                            <td colspan="6" style="text-align: center; color: var(--slds-danger); padding: 16px;">
                                <em>Error loading records. Please contact system administrator.</em>
                            </td>
                        </tr>
                        <%
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

<script>
    function updateFileName(input) {
        const label = document.getElementById('file-label');
        if (input.files && input.files[0]) {
            label.innerText = input.files[0].name;
            label.style.fontWeight = "600";
        }
    }
</script>


</body>
</html>