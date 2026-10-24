<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Photo Library</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <style>
        :root { --blue:#0176d3; --blue-dark:#014486; --bg:#f3f3f3; --surface:#fff; --border:#dddbda; --text:#181818;
                --muted:#706e6b; --danger:#ea001e; --radius:6px; }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Inter', -apple-system, "Segoe UI", Roboto, sans-serif; background: var(--bg); color: var(--text); }
        .ml-wrap { max-width: 1280px; margin: 0 auto; padding: 18px 16px 40px; }
        .ml-head { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; justify-content: space-between; margin-bottom: 14px; }
        .ml-title { display: flex; align-items: center; gap: 12px; }
        .ml-title .ic { width: 40px; height: 40px; border-radius: 8px; background: #e8f4ff; color: var(--blue); display: grid; place-items: center; font-size: 20px; }
        .ml-title h1 { margin: 0; font-size: 20px; }
        .ml-title p { margin: 2px 0 0; color: var(--muted); font-size: 13px; }
        .ml-card { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); }
        .ml-bar { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; justify-content: space-between; padding: 12px 14px; border-bottom: 1px solid var(--border); }
        .crumbs { display: flex; flex-wrap: wrap; align-items: center; gap: 4px; font-size: 14px; }
        .crumbs a { color: var(--blue); text-decoration: none; font-weight: 500; }
        .crumbs a:hover { text-decoration: underline; }
        .crumbs .sep { color: var(--muted); }
        .crumbs .here { font-weight: 600; }
        .ml-actions { display: flex; flex-wrap: wrap; gap: 8px; }
        .btn { height: 34px; padding: 0 14px; border-radius: 4px; border: 1px solid var(--border); background: #fff; color: var(--text);
               font: inherit; font-size: 13px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; }
        .btn:hover { background: #f4f6f9; }
        .btn.primary { background: var(--blue); border-color: var(--blue); color: #fff; }
        .btn.primary:hover { background: var(--blue-dark); }
        .btn.danger { color: var(--danger); }
        .btn:disabled { opacity: .55; cursor: not-allowed; }
        .notice { margin: 12px 14px 0; padding: 9px 12px; border-radius: 4px; font-size: 13px; }
        .notice.ok { background: #e5f5ed; color: #107e3e; }
        .notice.err { background: #fdecea; color: #ba0517; }
        .drop { margin: 14px; border: 2px dashed #c9d1db; border-radius: 8px; padding: 18px; text-align: center; color: var(--muted); font-size: 13px; transition: .15s; }
        .drop.over { border-color: var(--blue); background: #f2f8fe; color: var(--blue); }
        .drop b { color: var(--text); }
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 12px; padding: 0 14px 16px; }
        .tile { border: 1px solid var(--border); border-radius: 6px; overflow: hidden; background: #fff; position: relative; display: flex; flex-direction: column; }
        .tile .thumb { aspect-ratio: 4 / 3; background: #f4f6f9; display: grid; place-items: center; overflow: hidden; }
        .tile .thumb img, .tile .thumb video { width: 100%; height: 100%; object-fit: cover; display: block; }
        .tile .meta { padding: 7px 9px; font-size: 12px; min-width: 0; }
        .tile .name { font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .tile .sub { color: var(--muted); margin-top: 2px; }
        .tile .del { position: absolute; top: 6px; right: 6px; width: 28px; height: 28px; border-radius: 50%; border: 0; background: rgba(255,255,255,.92);
                     color: var(--danger); cursor: pointer; display: grid; place-items: center; box-shadow: 0 1px 3px rgba(0,0,0,.2); }
        .folder { cursor: pointer; text-decoration: none; color: inherit; }
        .folder .thumb { background: #fff8e6; color: #e6a700; font-size: 46px; }
        .folder:hover { border-color: var(--blue); }
        .empty { padding: 30px 14px; text-align: center; color: var(--muted); font-size: 14px; }
        .sec { padding: 4px 14px 8px; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: .4px; color: var(--muted); }
        .progress { display: none; margin: 0 14px 12px; font-size: 13px; color: var(--blue); }
        .progress.on { display: block; }
        .viewer { position: fixed; inset: 0; background: rgba(0,0,0,.82); display: none; align-items: center; justify-content: center; z-index: 4000; padding: 20px; }
        .viewer.on { display: flex; }
        .viewer img, .viewer video { max-width: 100%; max-height: 82vh; border-radius: 4px; }
        .viewer .cap { color: #fff; margin-top: 10px; font-size: 13px; text-align: center; word-break: break-all; }
        .tile .sel { position: absolute; top: 6px; left: 6px; width: 22px; height: 22px; margin: 0; cursor: pointer; accent-color: var(--blue); z-index: 2; }
        .tile.picked { border-color: var(--blue); box-shadow: 0 0 0 2px rgba(1,118,211,.25); }
        .selbar { display: none; align-items: center; gap: 10px; flex-wrap: wrap; margin: 12px 14px 0; padding: 8px 12px; border-radius: 6px;
                  background: #e8f4ff; color: #0a5aa8; font-size: 13px; font-weight: 600; }
        .selbar.on { display: flex; }
        .mv-overlay { position: fixed; inset: 0; background: rgba(15,23,42,.45); display: none; align-items: center; justify-content: center; z-index: 3500; padding: 16px; }
        .mv-overlay.on { display: flex; }
        .mv-box { background: #fff; width: 100%; max-width: 460px; border-radius: 10px; box-shadow: 0 18px 50px rgba(0,0,0,.25); display: flex; flex-direction: column; max-height: 86vh; }
        .mv-head { padding: 14px 16px; border-bottom: 1px solid var(--border); }
        .mv-head h3 { margin: 0; font-size: 16px; }
        .mv-head p { margin: 4px 0 0; font-size: 13px; color: var(--muted); }
        .mv-list { overflow: auto; padding: 6px 0; min-height: 140px; }
        .mv-row { display: flex; align-items: center; gap: 10px; padding: 9px 16px; cursor: pointer; font-size: 14px; border: 0; background: none; width: 100%; text-align: left; font: inherit; }
        .mv-row:hover { background: #f4f6f9; }
        .mv-row svg { color: #e6a700; flex: 0 0 auto; }
        .mv-row.up { color: var(--blue); font-weight: 600; }
        .mv-foot { padding: 12px 16px; border-top: 1px solid var(--border); display: flex; gap: 8px; justify-content: flex-end; flex-wrap: wrap; }
        .mv-new { margin-right: auto; }
        @media (max-width: 600px) { .grid { grid-template-columns: repeat(2, 1fr); } .ml-actions .btn { flex: 1; justify-content: center; } }
    </style>
</head>
<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />
<link rel="stylesheet" href="${pageContext.request.contextPath}/website/css/erp-shell.css?v=20261020a">

<div class="ml-wrap">
    <div class="ml-head">
        <div class="ml-title">
            <div class="ic"><i class="bi bi-images"></i></div>
            <div>
                <h1>Photo Library &middot; <c:out value="${site}"/> website</h1>
                <p>Upload photos into folders here, then pick them in the Page Builder.</p>
            </div>
        </div>
    </div>

    <div class="ml-card">
        <div class="ml-bar">
            <nav class="crumbs" id="crumbs" aria-label="Folder"></nav>
            <div class="ml-actions">
                <button type="button" class="btn" id="newFolderBtn"><i class="bi bi-folder-plus"></i> New folder</button>
                <button type="button" class="btn primary" id="uploadBtn"><i class="bi bi-cloud-arrow-up"></i> Upload photos</button>
                <c:if test="${canDelete}">
                    <button type="button" class="btn danger" id="delFolderBtn" title="Delete this folder (only when empty)"><i class="bi bi-trash"></i> Delete folder</button>
                </c:if>
            </div>
        </div>

        <c:if test="${not empty param.msg}"><div class="notice ok"><c:out value="${param.msg}"/></div></c:if>
        <c:if test="${not empty param.err}"><div class="notice err"><c:out value="${param.err}"/></div></c:if>
        <c:if test="${not empty error}"><div class="notice err"><c:out value="${error}"/></div></c:if>

        <form id="uploadForm" method="post" action="media" enctype="multipart/form-data">
            <input type="hidden" name="action" value="upload">
            <input type="hidden" name="folder" value="<c:out value='${folder}'/>">
            <input type="file" name="files" id="fileInput" accept="image/*,video/*" multiple hidden>
            <div class="drop" id="drop"><i class="bi bi-cloud-arrow-up" style="font-size:22px"></i><br>
                <b>Drop photos here</b> or click <b>Upload photos</b> &middot; JPG, PNG, WebP, GIF, MP4 &middot; up to 200 MB each &middot; several at once</div>
        </form>
        <div class="progress" id="progress"></div>
        <div class="selbar" id="selbar">
            <span id="selCount"></span>
            <button type="button" class="btn primary" id="moveBtn"><i class="bi bi-folder-symlink"></i> Move to&hellip;</button>
            <button type="button" class="btn" id="selClear">Clear</button>
            <span style="font-weight:400">Pages, news and events using these photos are updated automatically.</span>
        </div>

        <div id="content"></div>
    </div>
</div>

<form id="actionForm" method="post" action="media" hidden>
    <input type="hidden" name="action">
    <input type="hidden" name="folder" value="<c:out value='${folder}'/>">
    <input type="hidden" name="name">
    <input type="hidden" name="key">
</form>

<form id="moveForm" method="post" action="media" hidden>
    <input type="hidden" name="action" value="move">
    <input type="hidden" name="folder" value="<c:out value='${folder}'/>">
    <input type="hidden" name="target">
</form>

<div class="mv-overlay" id="mvOverlay" role="dialog" aria-modal="true" aria-labelledby="mvTitle">
    <div class="mv-box">
        <div class="mv-head"><h3 id="mvTitle">Move to folder</h3><p id="mvPath"></p></div>
        <div class="mv-list" id="mvList"></div>
        <div class="mv-foot">
            <button type="button" class="btn mv-new" id="mvNew"><i class="bi bi-folder-plus"></i> New folder here</button>
            <button type="button" class="btn" id="mvCancel">Cancel</button>
            <button type="button" class="btn primary" id="mvGo">Move here</button>
        </div>
    </div>
</div>

<div class="viewer" id="viewer"><div><div id="viewerMedia"></div><div class="cap" id="viewerCap"></div></div></div>

<script>
(function () {
    var folder = '<c:out value="${folder}"/>';
    var area = '<c:out value="${area}"/>';            // "old" = earlier uploads (read-only)
    var site_ = '<c:out value="${site}"/>';
    var libRoot = site_.toLowerCase().replace(/[^a-z0-9_-]/g, '') + '/library/';    // e.g. srs/library/
    var siteRoot = libRoot.replace(/library\/$/, '');                                // e.g. srs/
    var site = '<c:out value="${site}"/>';
    var canDelete = ${canDelete ? 'true' : 'false'};
    var folders = ${empty foldersJson ? '[]' : foldersJson};
    var files = ${empty filesJson ? '[]' : filesJson};
    var $ = function (id) { return document.getElementById(id); };
    function esc(s) { var d = document.createElement('div'); d.textContent = s == null ? '' : String(s); return d.innerHTML; }
    function size(n) { return n > 1048576 ? (n / 1048576).toFixed(1) + ' MB' : Math.max(1, Math.round(n / 1024)) + ' KB'; }
    function go(path, ar) { location.href = 'media?folder=' + encodeURIComponent(path) + (ar === 'old' ? '&area=old' : ''); }

    // breadcrumbs
    var parts = folder ? folder.replace(/\/$/, '').split('/') : [];
    var atTop = !parts.length && area !== 'old';
    var html = '<i class="bi bi-hdd-stack" style="color:#706e6b"></i> ' + (atTop ? '<span class="here">' + esc(site) + ' library</span>' : '<a href="#" data-go="">' + esc(site) + ' library</a>');
    if (area === 'old') {
        html += ' <span class="sep">/</span> ' + (parts.length ? '<a href="#" data-go="" data-area="old">Earlier uploads</a>' : '<span class="here">Earlier uploads</span>');
    }
    var acc = '';
    parts.forEach(function (p, i) {
        acc += p + '/';
        html += ' <span class="sep">/</span> ' + (i === parts.length - 1 ? '<span class="here">' + esc(p) + '</span>'
              : '<a href="#" data-go="' + esc(acc) + '"' + (area === 'old' ? ' data-area="old"' : '') + '>' + esc(p) + '</a>');
    });
    $('crumbs').innerHTML = html;
    $('crumbs').addEventListener('click', function (e) { var a = e.target.closest('a[data-go]'); if (a) { e.preventDefault(); go(a.getAttribute('data-go'), a.getAttribute('data-area')); } });

    // earlier uploads can be viewed and picked in the Page Builder, not changed here
    if (area === 'old') {
        ['newFolderBtn', 'uploadBtn', 'delFolderBtn', 'uploadForm'].forEach(function (id) { var el = $(id); if (el) el.style.display = 'none'; });
        var note = document.createElement('div');
        note.className = 'notice ok';
        note.style.background = '#e8f4ff'; note.style.color = '#0a5aa8';
        note.innerHTML = '<b>Earlier uploads</b> &middot; photos added to pages, news and events before the Photo Library existed. ' +
                         'You can view them here and pick them in the Page Builder. They cannot be changed here.';
        $('content').parentNode.insertBefore(note, $('content'));
    }

    // folders + files
    var out = '';
    if (folders.length) {
        out += '<div class="sec">Folders</div><div class="grid">' + folders.map(function (f) {
            var src = (area === 'old' ? siteRoot : libRoot) + f.path;
            var box = (f.area === 'old' && area !== 'old') ? '' : '<input type="checkbox" class="sel" data-src="' + esc(src) + '" title="Select to move">';
            return '<a class="tile folder" href="#" data-go="' + esc(f.path) + '"' + (f.area ? ' data-area="' + esc(f.area) + '"' : '') + '>' + box + '<div class="thumb"' + (f.area === 'old' && area !== 'old' ? ' style="background:#eef4fb;color:#0176d3"' : '') + '><svg viewBox="0 0 24 24" width="54" height="54" fill="currentColor" aria-hidden="true"><path d="M10 4l2 2h8a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h6z"/></svg></div>' +
                   '<div class="meta"><div class="name">' + esc(f.name) + '</div><div class="sub">Folder</div></div></a>';
        }).join('') + '</div>';
    }
    if (files.length) {
        out += '<div class="sec">Photos &amp; videos (' + files.length + ')</div><div class="grid">' + files.map(function (f, i) {
            var media = f.type.indexOf('video/') === 0
                ? '<video src="' + esc(f.url) + '" muted preload="metadata"></video>'
                : '<img src="' + esc(f.url) + '" alt="" loading="lazy">';
            return '<div class="tile" data-i="' + i + '"><input type="checkbox" class="sel" data-src="' + esc(f.key) + '" title="Select to move">' +
                   '<div class="thumb" data-view="' + i + '" style="cursor:zoom-in">' + media + '</div>' +
                   '<div class="meta"><div class="name" title="' + esc(f.name) + '">' + esc(f.name) + '</div><div class="sub">' + size(f.size) + '</div></div>' +
                   (canDelete ? '<button type="button" class="del" title="Delete" data-del="' + i + '"><i class="bi bi-trash"></i></button>' : '') + '</div>';
        }).join('') + '</div>';
    }
    if (area === 'old' && !folders.length && !files.length) out = '<div class="empty">No earlier uploads here.</div>';
    else if (!folders.length && !files.length) out = '<div class="empty"><i class="bi bi-images" style="font-size:28px"></i><br>This folder is empty. Create a folder or upload photos.</div>';
    $('content').innerHTML = out;

    $('content').addEventListener('click', function (e) {
        if (e.target.classList.contains('sel')) { e.stopPropagation(); setTimeout(updateSel, 0); return; }
        var g = e.target.closest('[data-go]');
        if (g) { e.preventDefault(); go(g.getAttribute('data-go'), g.getAttribute('data-area')); return; }
        var d = e.target.closest('[data-del]');
        if (d) {
            var f = files[+d.getAttribute('data-del')];
            if (confirm('Delete "' + f.name + '" from the Photo Library?')) post('deleteFile', { key: f.key });
            return;
        }
        var v = e.target.closest('[data-view]');
        if (v) {
            var file = files[+v.getAttribute('data-view')];
            $('viewerMedia').innerHTML = file.type.indexOf('video/') === 0
                ? '<video src="' + esc(file.url) + '" controls autoplay></video>' : '<img src="' + esc(file.url) + '" alt="">';
            $('viewerCap').textContent = file.name + ' · ' + size(file.size);
            $('viewer').classList.add('on');
        }
    });
    $('viewer').addEventListener('click', function () { this.classList.remove('on'); $('viewerMedia').innerHTML = ''; });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') $('viewer').click(); });

    // ---------- select + move ----------
    function picked() { return Array.prototype.slice.call(document.querySelectorAll('#content .sel:checked')); }
    function updateSel() {
        var p = picked();
        document.querySelectorAll('#content .tile').forEach(function (t) { var c = t.querySelector('.sel'); t.classList.toggle('picked', !!(c && c.checked)); });
        $('selbar').classList.toggle('on', p.length > 0);
        $('selCount').textContent = p.length + ' selected';
    }
    $('selClear').addEventListener('click', function () { picked().forEach(function (c) { c.checked = false; }); updateSel(); });

    var mvFolder = '';
    function mvLoad(path) {
        mvFolder = path || '';
        $('mvPath').textContent = 'Into: ' + site + ' library' + (mvFolder ? ' / ' + mvFolder.replace(/\/$/, '').split('/').join(' / ') : ' (top level)');
        $('mvList').innerHTML = '<div style="padding:12px 16px;color:#706e6b">Loading\u2026</div>';
        fetch('media?format=json&folder=' + encodeURIComponent(mvFolder), { credentials: 'same-origin' })
            .then(function (r) { return r.json(); })
            .then(function (d) {
                if (!d.ok) { $('mvList').innerHTML = '<div style="padding:12px 16px;color:#ba0517">' + esc(d.message) + '</div>'; return; }
                var svg = '<svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M10 4l2 2h8a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h6z"/></svg>';
                var h = '';
                if (mvFolder) {
                    var parts = mvFolder.replace(/\/$/, '').split('/'); parts.pop();
                    h += '<button type="button" class="mv-row up" data-mv="' + esc(parts.length ? parts.join('/') + '/' : '') + '">&larr; Up one level</button>';
                }
                d.folders.forEach(function (f) {
                    if (f.area) return;                                  // not into "Earlier uploads"
                    h += '<button type="button" class="mv-row" data-mv="' + esc(f.path) + '">' + svg + esc(f.name) + '</button>';
                });
                if (!h) h = '<div style="padding:12px 16px;color:#706e6b">No folders inside. Press \u201cMove here\u201d or create a new folder.</div>';
                $('mvList').innerHTML = h;
            });
    }
    $('moveBtn').addEventListener('click', function () { mvLoad(area === 'old' ? '' : folder); $('mvOverlay').classList.add('on'); });
    $('mvList').addEventListener('click', function (e) { var r = e.target.closest('[data-mv]'); if (r) mvLoad(r.getAttribute('data-mv')); });
    $('mvCancel').addEventListener('click', function () { $('mvOverlay').classList.remove('on'); });
    $('mvOverlay').addEventListener('click', function (e) { if (e.target === this) this.classList.remove('on'); });
    $('mvNew').addEventListener('click', function () {
        var n = prompt('Name of the new folder:');
        if (!n || !n.trim()) return;
        var b = new URLSearchParams(); b.append('action', 'createFolder'); b.append('folder', mvFolder); b.append('name', n.trim()); b.append('format', 'json');
        fetch('media', { method: 'POST', credentials: 'same-origin', body: b }).then(function (r) { return r.json(); })
            .then(function (d) { if (d.ok) mvLoad(d.folder); else alert(d.message); });
    });
    $('mvGo').addEventListener('click', function () {
        var p = picked();
        if (!p.length) return;
        if (!confirm('Move ' + p.length + ' item' + (p.length === 1 ? '' : 's') + ' to "' + (mvFolder || 'top level') + '"?')) return;
        var f = $('moveForm');
        f.target.value = mvFolder;
        f.querySelectorAll('input[name=source]').forEach(function (x) { x.remove(); });
        p.forEach(function (c) { var i = document.createElement('input'); i.type = 'hidden'; i.name = 'source'; i.value = c.getAttribute('data-src'); f.appendChild(i); });
        $('mvGo').disabled = true; $('mvGo').textContent = 'Moving\u2026';
        f.submit();
    });

    function post(action, extra) {
        var f = $('actionForm');
        f.action.value = action;
        f.name.value = extra && extra.name || '';
        f.key.value = extra && extra.key || '';
        f.submit();
    }

    $('newFolderBtn').addEventListener('click', function () {
        var n = prompt('Name of the new folder' + (folder ? ' (inside ' + folder.replace(/\/$/, '') + ')' : '') + ':');
        if (n && n.trim()) post('createFolder', { name: n.trim() });
    });
    if ($('delFolderBtn')) {
        $('delFolderBtn').disabled = !folder;
        $('delFolderBtn').addEventListener('click', function () {
            if (confirm('Delete the folder "' + folder.replace(/\/$/, '') + '"? It must be empty.')) post('deleteFolder');
        });
    }

    // upload: button, or drag and drop onto the page
    function upload(list) {
        if (!list || !list.length) return;
        var dt = new DataTransfer();
        Array.prototype.forEach.call(list, function (f) { dt.items.add(f); });
        $('fileInput').files = dt.files;
        $('progress').textContent = 'Uploading ' + list.length + ' file' + (list.length === 1 ? '' : 's') + '… please wait';
        $('progress').classList.add('on');
        $('uploadBtn').disabled = true;
        $('uploadForm').submit();
    }
    $('uploadBtn').addEventListener('click', function () { $('fileInput').click(); });
    $('drop').addEventListener('click', function () { $('fileInput').click(); });
    $('fileInput').addEventListener('change', function () { if (this.files.length) upload(this.files); });
    ['dragenter', 'dragover'].forEach(function (ev) {
        document.addEventListener(ev, function (e) { e.preventDefault(); $('drop').classList.add('over'); });
    });
    ['dragleave', 'drop'].forEach(function (ev) {
        document.addEventListener(ev, function (e) { e.preventDefault(); if (ev === 'drop' || e.target === document.documentElement) $('drop').classList.remove('over'); });
    });
    document.addEventListener('drop', function (e) { if (e.dataTransfer && e.dataTransfer.files.length) upload(e.dataTransfer.files); });
})();
</script>
</body>
</html>
