<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.officecentral.common.web.SettingsMenu" %>
<%!
    private static String esc(Object o) {
        if (o == null) return "";
        return String.valueOf(o).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    // Opened through SettingsServlet (/settings), which checks Global / Finance access.
    String ctx = request.getContextPath();
    Map<String, List<SettingsMenu.Page>> groups = new LinkedHashMap<>();
    for (SettingsMenu.Page p : SettingsMenu.PAGES) groups.computeIfAbsent(p.group, k -> new ArrayList<>()).add(p);
%>
<!DOCTYPE html>
<html>
<head>
<title>Settings Master</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
* { box-sizing: border-box; }
body { font-family: 'Poppins', sans-serif; background: #f3f3f3; margin: 0; color: #181818; }
.main-content { width: 100%; max-width: 1200px; margin: 0 auto; padding: 16px; }
.card { background: #fff; border: 1px solid #c9c9c9; border-radius: 4px; padding: 22px 24px; box-shadow: 0 2px 2px rgba(0,0,0,.1); margin-bottom: 16px; }
.head { display: flex; align-items: center; gap: 12px; }
.head .ico { width: 40px; height: 40px; border-radius: 4px; background: #514f4d; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0; }
h2 { margin: 0; font-size: 20px; font-weight: 700; }
.sub { font-size: 12.5px; color: #514f4d; margin-top: 2px; }
.group { font-size: 11px; font-weight: 700; color: #514f4d; text-transform: uppercase; letter-spacing: .6px; margin: 4px 0 10px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 12px; margin-bottom: 18px; }
.tile { display: flex; gap: 12px; align-items: flex-start; padding: 14px; border: 1px solid #dddbda; border-radius: 4px; background: #fff; text-decoration: none; color: inherit; }
.tile:hover { border-color: #0176d3; box-shadow: 0 0 0 2px rgba(1,118,211,.15); }
.tile i { width: 34px; height: 34px; border-radius: 4px; display: flex; align-items: center; justify-content: center; font-size: 15px; color: #fff; flex-shrink: 0; }
.t-primary { background: #0176d3; } .t-success { background: #2e844a; } .t-danger { background: #c23934; }
.t-info { background: #0b827c; } .t-warning { background: #b16500; }
.tile b { display: block; font-size: 14px; }
.tile span { font-size: 12px; color: #514f4d; }
.note { font-size: 12px; color: #514f4d; }
@media (max-width: 560px) { .main-content { padding: 10px; } .card { padding: 14px; } }
</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />

<div class="main-content">
<div class="card">
    <div class="head" style="margin-bottom:18px">
        <div class="ico"><i class="fa-solid fa-gear"></i></div>
        <div>
            <h2>Settings Master</h2>
            <div class="sub">Masters and stock adjustments. Available only to Global and Finance users. Use the sidebar to move between them.</div>
        </div>
    </div>

    <% for (Map.Entry<String, List<SettingsMenu.Page>> g : groups.entrySet()) { %>
        <div class="group"><%= esc(g.getKey()) %></div>
        <div class="grid">
        <% for (SettingsMenu.Page p : g.getValue()) { %>
            <a class="tile" href="<%= ctx %>/<%= esc(p.key) %>">
                <i class="<%= esc(p.icon) %> t-<%= esc(p.tone) %>"></i>
                <div><b><%= esc(p.title) %></b><span><%= esc(p.description) %></span></div>
            </a>
        <% } %>
        </div>
    <% } %>
    <div class="note"><i class="fa-solid fa-shield-halved"></i> Every page here also checks your role on the server, so the links work only for Global and Finance users.</div>
</div>
</div>

<jsp:include page="/WEB-INF/views/layout/Footer.jsp" />
</body>
</html>
