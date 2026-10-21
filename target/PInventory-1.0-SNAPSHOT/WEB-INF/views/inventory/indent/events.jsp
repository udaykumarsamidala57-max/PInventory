<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.SimpleDateFormat" %>
<%!
    private static String h(Object o) {
        if (o == null) return "";
        return String.valueOf(o).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) { response.sendRedirect("login.jsp"); return; }
    if (request.getAttribute("events") == null) { response.sendRedirect(request.getContextPath() + "/events"); return; }

    List<Map<String, Object>> events = (List<Map<String, Object>>) request.getAttribute("events");
    int activeCount   = (Integer) request.getAttribute("activeCount");
    int inactiveCount = (Integer) request.getAttribute("inactiveCount");
    String show = (String) request.getAttribute("show");
    if (show == null) show = "";

    String okMsg  = (String) sess.getAttribute("eventOk");
    String errMsg = (String) sess.getAttribute("eventErr");
    sess.removeAttribute("eventOk");
    sess.removeAttribute("eventErr");

    SimpleDateFormat showFmt = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat isoFmt  = new SimpleDateFormat("yyyy-MM-dd");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Events</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
    :root {
        --accent: #2f6fb3; --accent-hover: #255a94; --accent-soft: #edf4fb;
        --bg: #f4f6f9; --surface: #ffffff; --surface-2: #f7f9fc;
        --border: #dde3ea; --border-strong: #c3ccd6;
        --text-heading: #1f2a37; --text-body: #374151; --text-muted: #667085;
        --ok-bg: #f0f9f4; --ok-border: #b7e0c8; --ok-text: #1f6b43;
        --warn-bg: #fff8eb; --warn-border: #f3d59b; --warn-text: #8a5a00;
    }
    * { box-sizing: border-box; }
    body { margin: 0; background: var(--bg); color: var(--text-body);
           font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; font-size: 13px; }
    .ev-wrap { max-width: 1200px; margin: 0 auto; padding: 14px 18px 40px; }
    .ev-head { display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap;
               background: var(--surface); border: 1px solid var(--border); border-radius: 6px; padding: 12px 16px; margin-bottom: 12px; }
    .ev-title { display: flex; align-items: center; gap: 12px; }
    .ev-icon { width: 36px; height: 36px; border-radius: 6px; background: var(--accent-soft); color: var(--accent);
               display: flex; align-items: center; justify-content: center; font-size: 15px; }
    .ev-title h1 { margin: 0; font-size: 17px; color: var(--text-heading); font-weight: 600; }
    .ev-title p { margin: 2px 0 0; color: var(--text-muted); font-size: 12px; }
    .ev-stats { display: flex; gap: 8px; }
    .ev-stat { border: 1px solid var(--border); border-radius: 6px; padding: 6px 12px; background: var(--surface-2); text-align: center; min-width: 84px; }
    .ev-stat b { display: block; font-size: 16px; color: var(--text-heading); }
    .ev-stat span { font-size: 11px; color: var(--text-muted); }

    .ev-msg { margin: 0 0 12px; padding: 10px 14px; border-radius: 6px; border: 1px solid; font-size: 13px; }
    .ev-ok  { background: var(--ok-bg); border-color: var(--ok-border); color: var(--ok-text); }
    .ev-err { background: var(--warn-bg); border-color: var(--warn-border); color: var(--warn-text); }

    .ev-grid { display: grid; grid-template-columns: minmax(280px, 360px) 1fr; gap: 12px; align-items: start; }
    .ev-card { background: var(--surface); border: 1px solid var(--border); border-radius: 6px; }
    .ev-card-h { padding: 10px 14px; border-bottom: 1px solid var(--border); background: var(--surface-2);
                 display: flex; justify-content: space-between; align-items: center; gap: 8px; flex-wrap: wrap; }
    .ev-card-h h2 { margin: 0; font-size: 13.5px; color: var(--text-heading); font-weight: 600; }
    .ev-card-b { padding: 14px; }

    .ev-field { display: flex; flex-direction: column; gap: 5px; margin-bottom: 12px; }
    .ev-field label { font-size: 12px; font-weight: 600; color: #475467; }
    .ev-field label .req { color: var(--accent); }
    .ev-input { width: 100%; padding: 8px 10px; border: 1px solid var(--border-strong); border-radius: 6px; background: #fff;
                font: inherit; font-size: 13px; color: var(--text-heading); outline: none; }
    .ev-input:focus { border-color: var(--accent); box-shadow: 0 0 0 3px rgba(47,111,179,0.15); }
    textarea.ev-input { min-height: 84px; resize: vertical; line-height: 1.45; }
    .ev-hint { font-size: 11px; color: var(--text-muted); text-align: right; }
    .ev-actions { display: flex; gap: 8px; justify-content: flex-end; }
    .ev-btn { height: 34px; padding: 0 14px; border-radius: 6px; font: inherit; font-size: 13px; font-weight: 600; cursor: pointer;
              display: inline-flex; align-items: center; gap: 6px; border: 1px solid transparent; }
    .ev-btn-primary { background: var(--accent); color: #fff; border-color: var(--accent); }
    .ev-btn-primary:hover { background: var(--accent-hover); }
    .ev-btn-light { background: #fff; color: #475467; border-color: var(--border-strong); }
    .ev-btn-light:hover { background: var(--surface-2); }

    .ev-filters { display: flex; gap: 6px; align-items: center; flex-wrap: wrap; }
    .ev-chip { border: 1px solid var(--border); background: #fff; color: #475467; border-radius: 999px; padding: 3px 10px;
               font-size: 12px; text-decoration: none; }
    .ev-chip.active { background: var(--accent-soft); color: var(--accent); border-color: #9dbbdc; font-weight: 600; }
    .ev-search { width: 200px; height: 30px; padding: 0 10px; border: 1px solid var(--border-strong); border-radius: 6px; font: inherit; font-size: 12.5px; }

    table.ev-table { width: 100%; border-collapse: collapse; }
    .ev-table th { text-align: left; font-size: 11.5px; font-weight: 600; color: var(--text-muted); text-transform: uppercase; letter-spacing: .3px;
                   padding: 9px 14px; border-bottom: 1px solid var(--border-strong); background: var(--surface-2); }
    .ev-table td { padding: 10px 14px; border-bottom: 1px solid var(--border); vertical-align: top; }
    .ev-table tr:last-child td { border-bottom: none; }
    .ev-table tr.inactive td { color: #98a2b3; }
    .ev-name { font-weight: 600; color: var(--text-heading); overflow-wrap: anywhere; }
    .ev-table tr.inactive .ev-name { color: #98a2b3; }
    .ev-desc { margin-top: 2px; font-size: 12px; color: var(--text-muted); overflow-wrap: anywhere; }
    .ev-meta { font-size: 11px; color: #98a2b3; margin-top: 3px; }
    .ev-badge { display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 11.5px; font-weight: 600; border: 1px solid; white-space: nowrap; }
    .ev-badge.on  { background: var(--ok-bg); color: var(--ok-text); border-color: var(--ok-border); }
    .ev-badge.off { background: #f4f6f9; color: #667085; border-color: var(--border); }
    .ev-row-actions { display: flex; gap: 6px; justify-content: flex-end; white-space: nowrap; }
    .ev-link { background: #fff; border: 1px solid var(--border-strong); color: #475467; border-radius: 6px; padding: 4px 10px;
               font: inherit; font-size: 12px; cursor: pointer; }
    .ev-link:hover { background: var(--surface-2); color: var(--text-heading); }
    .ev-empty { padding: 28px 14px; text-align: center; color: var(--text-muted); }

    @media (max-width: 860px) {
        .ev-grid { grid-template-columns: 1fr; }
        .ev-search { width: 100%; }
        .ev-table th.hide-sm, .ev-table td.hide-sm { display: none; }
    }
</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />

<div class="ev-wrap">
    <div class="ev-head">
        <div class="ev-title">
            <div class="ev-icon"><i class="fas fa-calendar-check"></i></div>
            <div>
                <h1>Events</h1>
                <p>Add events and mark them Active or Inactive</p>
            </div>
        </div>
        <div class="ev-stats">
            <div class="ev-stat"><b><%= activeCount %></b><span>Active</span></div>
            <div class="ev-stat"><b><%= inactiveCount %></b><span>Inactive</span></div>
        </div>
    </div>

    <% if (okMsg != null) { %><div class="ev-msg ev-ok" role="status"><i class="fas fa-check-circle"></i> <%= h(okMsg) %></div><% } %>
    <% if (errMsg != null) { %><div class="ev-msg ev-err" role="alert"><i class="fas fa-exclamation-circle"></i> <%= h(errMsg) %></div><% } %>

    <div class="ev-grid">
        <!-- Add / edit form -->
        <div class="ev-card">
            <div class="ev-card-h"><h2 id="formTitle">Add Event</h2></div>
            <div class="ev-card-b">
                <form method="post" action="events" id="eventForm" autocomplete="off">
                    <input type="hidden" name="action" id="fAction" value="add">
                    <input type="hidden" name="event_id" id="fId" value="">
                    <div class="ev-field">
                        <label for="fName">Event Name <span class="req">*</span></label>
                        <input class="ev-input" type="text" name="event_name" id="fName" maxlength="150" required placeholder="e.g. Annual Day 2026">
                    </div>
                    <div class="ev-field">
                        <label for="fDate">Event Date</label>
                        <input class="ev-input" type="date" name="event_date" id="fDate">
                    </div>
                    <div class="ev-field">
                        <label for="fDesc">Description</label>
                        <textarea class="ev-input" name="description" id="fDesc" maxlength="500" placeholder="Optional notes"></textarea>
                        <span class="ev-hint"><span id="fCount">0</span> / 500</span>
                    </div>
                    <div class="ev-actions">
                        <button type="button" class="ev-btn ev-btn-light" id="fCancel" style="display:none" onclick="resetForm()">Cancel</button>
                        <button type="submit" class="ev-btn ev-btn-primary" id="fSubmit"><i class="fas fa-plus"></i> Add Event</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- List -->
        <div class="ev-card">
            <div class="ev-card-h">
                <div class="ev-filters">
                    <a class="ev-chip <%= show.isEmpty() ? "active" : "" %>" href="events">All (<%= activeCount + inactiveCount %>)</a>
                    <a class="ev-chip <%= "Active".equalsIgnoreCase(show) ? "active" : "" %>" href="events?show=Active">Active (<%= activeCount %>)</a>
                    <a class="ev-chip <%= "Inactive".equalsIgnoreCase(show) ? "active" : "" %>" href="events?show=Inactive">Inactive (<%= inactiveCount %>)</a>
                </div>
                <input class="ev-search" type="search" id="evSearch" placeholder="Search events…" oninput="filterRows(this.value)">
            </div>
            <% if (events.isEmpty()) { %>
                <div class="ev-empty">No events <%= show.isEmpty() ? "yet. Add your first event using the form." : "in this list." %></div>
            <% } else { %>
            <table class="ev-table" id="evTable">
                <thead><tr><th>Event</th><th class="hide-sm">Date</th><th>Status</th><th></th></tr></thead>
                <tbody>
                <% for (Map<String, Object> e : events) {
                     boolean on = "Active".equals(e.get("status"));
                     java.util.Date d = (java.util.Date) e.get("date");
                     java.util.Date c = (java.util.Date) e.get("createdAt");
                %>
                    <tr class="<%= on ? "" : "inactive" %>">
                        <td>
                            <div class="ev-name"><%= h(e.get("name")) %></div>
                            <% if (e.get("description") != null) { %><div class="ev-desc"><%= h(e.get("description")) %></div><% } %>
                            <div class="ev-meta">Added<%= e.get("createdBy") != null ? " by " + h(e.get("createdBy")) : "" %><%= c != null ? " on " + showFmt.format(c) : "" %></div>
                        </td>
                        <td class="hide-sm" style="white-space:nowrap"><%= d != null ? showFmt.format(d) : "&ndash;" %></td>
                        <td><span class="ev-badge <%= on ? "on" : "off" %>"><%= on ? "Active" : "Inactive" %></span></td>
                        <td>
                            <div class="ev-row-actions">
                                <button type="button" class="ev-link"
                                        data-id="<%= e.get("id") %>" data-name="<%= h(e.get("name")) %>"
                                        data-date="<%= d != null ? isoFmt.format(d) : "" %>" data-desc="<%= h(e.get("description")) %>"
                                        onclick="editEvent(this)"><i class="fas fa-pen"></i> Edit</button>
                                <form method="post" action="events" style="margin:0">
                                    <input type="hidden" name="action" value="toggle">
                                    <input type="hidden" name="event_id" value="<%= e.get("id") %>">
                                    <button type="submit" class="ev-link"><i class="fas <%= on ? "fa-toggle-off" : "fa-toggle-on" %>"></i> <%= on ? "Make Inactive" : "Make Active" %></button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
            <% } %>
        </div>
    </div>
</div>

<script>
function editEvent(btn) {
    document.getElementById('fAction').value = 'update';
    document.getElementById('fId').value = btn.dataset.id;
    document.getElementById('fName').value = btn.dataset.name;
    document.getElementById('fDate').value = btn.dataset.date;
    document.getElementById('fDesc').value = btn.dataset.desc;
    document.getElementById('formTitle').textContent = 'Edit Event';
    document.getElementById('fSubmit').innerHTML = '<i class="fas fa-save"></i> Save Changes';
    document.getElementById('fCancel').style.display = '';
    updateCount();
    document.getElementById('fName').focus();
    window.scrollTo({ top: 0, behavior: 'smooth' });
}
function resetForm() {
    document.getElementById('eventForm').reset();
    document.getElementById('fAction').value = 'add';
    document.getElementById('fId').value = '';
    document.getElementById('formTitle').textContent = 'Add Event';
    document.getElementById('fSubmit').innerHTML = '<i class="fas fa-plus"></i> Add Event';
    document.getElementById('fCancel').style.display = 'none';
    updateCount();
}
function updateCount() { document.getElementById('fCount').textContent = document.getElementById('fDesc').value.length; }
document.getElementById('fDesc').addEventListener('input', updateCount);
function filterRows(q) {
    q = q.trim().toLowerCase();
    document.querySelectorAll('#evTable tbody tr').forEach(function (tr) {
        tr.style.display = tr.innerText.toLowerCase().indexOf(q) > -1 ? '' : 'none';
    });
}
</script>
</body>
</html>
