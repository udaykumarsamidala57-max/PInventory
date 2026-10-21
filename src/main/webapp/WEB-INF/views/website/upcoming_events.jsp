<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upcoming Events</title>
    
    <!-- Google Fonts & Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Salesforce+Sans:wght@400;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    
    <!-- Flatpickr CSS -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
    
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
            --slds-danger: #ea001e;
            --slds-danger-hover: #ba001a;
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

        /* Header Banner */
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
            background-color: #fef2f2;
            color: var(--slds-danger);
            border: 1px solid #fe8f8f;
        }
        .alert-success {
            background-color: #f0fdf4;
            color: #2e844a;
            border: 1px solid #91e0a6;
        }

        /* Form Cards */
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

        /* File Input Component */
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

        .btn-submit {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            background-color: var(--slds-blue);
            color: white;
            border: none;
            padding: 7px 16px;
            font-size: 0.825rem;
            font-weight: 600;
            border-radius: var(--slds-radius);
            cursor: pointer;
            transition: background-color 0.15s ease;
            align-self: flex-end;
        }

        .btn-submit:hover {
            background-color: var(--slds-blue-hover);
        }

        /* Section Title */
        .section-title {
            font-size: 0.95rem;
            font-weight: 700;
            margin-bottom: 10px;
            color: var(--slds-text-main);
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }

        /* Event List & Cards */
        .events-list {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .event-card {
            background: var(--slds-surface);
            border-radius: var(--slds-radius);
            padding: 12px 16px;
            box-shadow: var(--slds-shadow);
            border: 1px solid var(--slds-border);
            display: flex;
            gap: 16px;
            align-items: flex-start;
            position: relative;
        }

        .event-image-wrapper {
            flex-shrink: 0;
            width: 120px;
            height: 85px;
            border-radius: var(--slds-radius);
            overflow: hidden;
            background-color: #f3f3f3;
            border: 1px solid var(--slds-border);
        }

        .event-image {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .no-image {
            width: 100%;
            height: 100%;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            color: var(--slds-text-muted);
            font-size: 0.725rem;
            gap: 2px;
        }

        .event-details {
            flex: 1;
            min-width: 0;
            padding-right: 70px; /* Leave room for actions */
        }

        .event-title {
            font-size: 0.975rem;
            font-weight: 700;
            color: var(--slds-blue);
            margin-bottom: 6px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .event-meta-grid {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 6px;
            font-size: 0.775rem;
            color: var(--slds-text-label);
        }

        .event-meta-item {
            display: flex;
            align-items: center;
            gap: 4px;
            background: #f3f3f3;
            padding: 2px 8px;
            border-radius: 12px;
            border: 1px solid #e5e5e5;
        }

        .event-meta-item i {
            color: var(--slds-blue);
            font-size: 0.75rem;
        }

        .event-description {
            font-size: 0.825rem;
            color: #3e3e3e;
            line-height: 1.35;
        }

        /* Action Buttons */
        .event-actions {
            position: absolute;
            top: 12px;
            right: 16px;
            display: flex;
            gap: 6px;
        }

        .btn-action {
            background: none;
            border: 1px solid var(--slds-border);
            border-radius: var(--slds-radius);
            padding: 4px 8px;
            font-size: 0.8rem;
            cursor: pointer;
            color: var(--slds-text-label);
            transition: all 0.15s ease;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .btn-action-edit:hover {
            border-color: var(--slds-blue);
            color: var(--slds-blue);
            background: #f0f7ff;
        }

        .btn-action-delete:hover {
            border-color: var(--slds-danger);
            color: var(--slds-danger);
            background: #fff5f5;
        }

        /* Modal Backdrop & Dialog */
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.4);
            z-index: 1000;
            align-items: center;
            justify-content: center;
        }

        .modal-overlay.active {
            display: flex;
        }

        .modal-dialog {
            background: var(--slds-surface);
            width: 100%;
            max-width: 650px;
            border-radius: var(--slds-radius);
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
            border: 1px solid var(--slds-border);
            animation: modalFadeIn 0.2s ease-out;
            margin: 16px;
        }

        @keyframes modalFadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .modal-header {
            padding: 12px 16px;
            border-bottom: 1px solid var(--slds-border);
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-weight: 700;
            font-size: 0.95rem;
        }

        .modal-close {
            background: none;
            border: none;
            font-size: 1.2rem;
            cursor: pointer;
            color: var(--slds-text-muted);
        }

        .modal-body {
            padding: 16px;
        }

        .modal-footer {
            padding: 12px 16px;
            border-top: 1px solid var(--slds-border);
            display: flex;
            justify-content: flex-end;
            gap: 8px;
            background: #fafafa;
        }

        .btn-secondary {
            background: #fff;
            border: 1px solid var(--slds-border);
            color: var(--slds-text-main);
            padding: 7px 16px;
            font-size: 0.825rem;
            font-weight: 600;
            border-radius: var(--slds-radius);
            cursor: pointer;
        }

        .empty-state {
            text-align: center;
            padding: 24px;
            background: var(--slds-surface);
            border-radius: var(--slds-radius);
            border: 1px dashed var(--slds-border);
            color: var(--slds-text-muted);
            font-size: 0.85rem;
        }

        .empty-state i {
            font-size: 1.5rem;
            margin-bottom: 4px;
            color: #aeaeae;
            display: block;
        }

        @media (max-width: 600px) {
            .event-card {
                flex-direction: column;
            }
            .event-image-wrapper {
                width: 100%;
                height: 120px;
            }
            .event-details {
                padding-right: 0;
            }
            .event-actions {
                position: static;
                margin-top: 8px;
                width: 100%;
                justify-content: flex-end;
            }
        }
    </style>
</head>
<body>

<jsp:include page="/WEB-INF/views/layout/header.jsp" />
<link rel="stylesheet" href="${pageContext.request.contextPath}/website/css/erp-shell.css?v=20261020a">

<div class="container">

    <!-- Top Action Bar -->
    <div class="page-header">
        <div class="page-header-title">
            <div class="page-header-icon">
                <i class="bi bi-calendar-event"></i>
            </div>
            <div>
                <h1>Event Workspace</h1>
                <p>Manage and publish official organization schedules</p>
            </div>
        </div>
    </div>

    <!-- System Alerts -->
    <c:if test="${not empty errorMessage}">
        <div class="alert alert-error">
            <i class="bi bi-exclamation-triangle-fill"></i>
            <div>${errorMessage}</div>
        </div>
    </c:if>
    <c:if test="${not empty successMessage}">
        <div class="alert alert-success">
            <i class="bi bi-check-circle-fill"></i>
            <div>${successMessage}</div>
        </div>
    </c:if>

    <!-- Event Creation Panel -->
    <div class="form-card">
        <div class="form-card-header">
            <i class="bi bi-plus-circle" style="color: var(--slds-blue);"></i> New Event Record
        </div>
        
        <form action="upcoming-events" method="post" enctype="multipart/form-data" class="form-grid">
            <input type="hidden" name="action" value="insert">
            
            <div class="form-group">
                <label for="event_name">Event Name *</label>
                <input type="text" id="event_name" name="event_name" class="form-control" required placeholder="Enter primary title">
            </div>

            <div class="form-row">
                <div class="form-group">
                    <label for="event_date">Date *</label>
                    <input type="date" id="event_date" name="event_date" class="form-control" required>
                </div>
                <div class="form-group">
                    <label for="place">Venue / Location</label>
                    <input type="text" id="place" name="place" class="form-control" placeholder="e.g. Auditorium A">
                </div>
                <div class="form-group">
                    <label for="time_from">Start Time</label>
                    <input type="text" id="time_from" name="time_from" class="form-control clock-input" placeholder="00:00" readonly>
                </div>
                <div class="form-group">
                    <label for="time_to">End Time</label>
                    <input type="text" id="time_to" name="time_to" class="form-control clock-input" placeholder="00:00" readonly>
                </div>
            </div>

            <div class="form-row">
                <div class="form-group" style="flex: 2;">
                    <label for="event_description">Description</label>
                    <textarea id="event_description" name="event_description" class="form-control" rows="1" placeholder="Brief event summary..."></textarea>
                </div>
                <div class="form-group" style="flex: 1;">
                    <label>Attachment</label>
                    <div class="file-upload-wrapper">
                        <input type="file" id="image_blob" name="image_blob" accept="image/*" onchange="updateFileName(this, 'create-file-label')">
                        <i class="bi bi-paperclip file-upload-icon"></i>
                        <span class="file-upload-text" id="create-file-label">Attach Image</span>
                    </div>
                </div>
            </div>

            <button type="submit" class="btn-submit">
                <i class="bi bi-check2"></i> Save Event
            </button>
        </form>
    </div>

    <!-- Active Events List -->
    <div class="section-title">
        <span>Scheduled Records</span>
    </div>
    
    <div class="events-list">
        <c:choose>
            <c:when test="${not empty events}">
                <c:forEach var="event" items="${events}">
                    <div class="event-card">
                        
                        <div class="event-actions">
                            <button type="button" class="btn-action btn-action-edit" 
                                    onclick="openEditModal('${event.id}', '${fn:escapeXml(event.eventName)}', '${event.eventDate}', '${fn:escapeXml(event.place)}', '${event.timeFrom}', '${event.timeTo}', '${fn:escapeXml(event.eventDescription)}')">
                                <i class="bi bi-pencil"></i> Edit
                            </button>
                            
                            <form action="upcoming-events" method="post" style="display:inline;" onsubmit="return confirm('Are you sure you want to delete this event?');">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="id" value="${event.id}">
                                <button type="submit" class="btn-action btn-action-delete">
                                    <i class="bi bi-trash"></i>
                                </button>
                            </form>
                        </div>

                        <div class="event-image-wrapper">
                            <c:choose>
                                <c:when test="${not empty event.imageSrc}">
                                    <img src="${event.imageSrc}" alt="${event.eventName}" class="event-image" />
                                </c:when>
                                <c:otherwise>
                                    <div class="no-image">
                                        <i class="bi bi-image"></i>
                                        <span>No Banner</span>
                                    </div>
                                </c:otherwise>
                            </c:choose>
                        </div>

                        <div class="event-details">
                            <h3 class="event-title">${event.eventName}</h3>
                            
                            <div class="event-meta-grid">
                                <div class="event-meta-item">
                                    <i class="bi bi-calendar3"></i>
                                    <span>${event.eventDate}</span>
                                </div>
                                <div class="event-meta-item">
                                    <i class="bi bi-clock"></i>
                                    <span>${event.timeFrom != null ? event.timeFrom : 'N/A'} - ${event.timeTo != null ? event.timeTo : 'N/A'}</span>
                                </div>
                                <div class="event-meta-item">
                                    <i class="bi bi-geo-alt"></i>
                                    <span>${event.place != null ? event.place : 'TBD'}</span>
                                </div>
                            </div>

                            <p class="event-description">${event.eventDescription}</p>
                        </div>
                    </div>
                </c:forEach>
            </c:when>
            <c:otherwise>
                <div class="empty-state">
                    <i class="bi bi-inbox"></i>
                    <p>No active event records available.</p>
                </div>
            </c:otherwise>
        </c:choose>
    </div>

</div>

<!-- Modal Dialog for Editing Events -->
<div class="modal-overlay" id="editModal">
    <div class="modal-dialog">
        <div class="modal-header">
            <span><i class="bi bi-pencil-square" style="color: var(--slds-blue);"></i> Edit Event Record</span>
            <button class="modal-close" onclick="closeEditModal()">&times;</button>
        </div>
        <form action="upcoming-events" method="post" enctype="multipart/form-data">
            <div class="modal-body form-grid">
                <input type="hidden" name="action" value="update">
                <input type="hidden" id="edit_id" name="id">

                <div class="form-group">
                    <label for="edit_event_name">Event Name *</label>
                    <input type="text" id="edit_event_name" name="event_name" class="form-control" required>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label for="edit_event_date">Date *</label>
                        <input type="date" id="edit_event_date" name="event_date" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="edit_place">Venue / Location</label>
                        <input type="text" id="edit_place" name="place" class="form-control">
                    </div>
                    <div class="form-group">
                        <label for="edit_time_from">Start Time</label>
                        <input type="text" id="edit_time_from" name="time_from" class="form-control clock-input" placeholder="00:00" readonly>
                    </div>
                    <div class="form-group">
                        <label for="edit_time_to">End Time</label>
                        <input type="text" id="edit_time_to" name="time_to" class="form-control clock-input" placeholder="00:00" readonly>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group" style="flex: 2;">
                        <label for="edit_event_description">Description</label>
                        <textarea id="edit_event_description" name="event_description" class="form-control" rows="2"></textarea>
                    </div>
                    <div class="form-group" style="flex: 1;">
                        <label>Replace Image (Optional)</label>
                        <div class="file-upload-wrapper">
                            <input type="file" name="image_blob" accept="image/*" onchange="updateFileName(this, 'edit-file-label')">
                            <i class="bi bi-paperclip file-upload-icon"></i>
                            <span class="file-upload-text" id="edit-file-label">New Image</span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary" onclick="closeEditModal()">Cancel</button>
                <button type="submit" class="btn-submit"><i class="bi bi-save"></i> Save Changes</button>
            </div>
        </form>
    </div>
</div>

<!-- Flatpickr Engine -->
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
<script>
    flatpickr(".clock-input", {
        enableTime: true,
        noCalendar: true,
        dateFormat: "H:i",
        time_24hr: false
    });

    function updateFileName(input, targetId) {
        const label = document.getElementById(targetId);
        if (input.files && input.files[0]) {
            label.innerText = input.files[0].name;
            label.style.fontWeight = "600";
        }
    }

    function openEditModal(id, name, date, place, timeFrom, timeTo, description) {
        document.getElementById('edit_id').value = id;
        document.getElementById('edit_event_name').value = name;
        document.getElementById('edit_event_date').value = date;
        document.getElementById('edit_place').value = (place && place !== 'null') ? place : '';
        
        // Handle time parsing for Flatpickr instance
        const fpFrom = document.getElementById('edit_time_from')._flatpickr;
        const fpTo = document.getElementById('edit_time_to')._flatpickr;
        if (fpFrom) fpFrom.setDate((timeFrom && timeFrom !== 'null') ? timeFrom.substring(0, 5) : '');
        if (fpTo) fpTo.setDate((timeTo && timeTo !== 'null') ? timeTo.substring(0, 5) : '');

        document.getElementById('edit_event_description').value = (description && description !== 'null') ? description : '';
        document.getElementById('edit-file-label').innerText = "New Image";
        
        document.getElementById('editModal').classList.add('active');
    }

    function closeEditModal() {
        document.getElementById('editModal').classList.remove('active');
    }
</script>


</body>
</html>