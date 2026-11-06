<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Opened through UamsServlet (/uams), which allows the Global role only. All data comes from /uams/api/*
    // and is written into the page with textContent (never as HTML), so stored names cannot run as script.
    String uCtx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Access Management (UAMS)</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root { --blue:#0176d3; --blue-d:#014486; --navy:#032d60; --ink:#181818; --muted:#5c5c5c; --line:#dddbda; --soft:#f3f3f3;
        --ok:#2e844a; --ok-bg:#ebf7e6; --no:#ba0517; --no-bg:#feded8; --warn:#a96404; --warn-bg:#fef1d6; --chip:#eef4ff; }
* { box-sizing: border-box; }
body { margin: 0; background: var(--soft); color: var(--ink); font: 14px/1.45 'Salesforce Sans', Inter, 'Segoe UI', Arial, sans-serif; }
.ua { max-width: 1360px; margin: 0 auto; padding: 14px 16px 120px; }
.card { background: #fff; border: 1px solid var(--line); border-radius: 4px; box-shadow: 0 2px 2px rgba(0,0,0,.06); }
.head { display: flex; gap: 14px; align-items: center; padding: 16px 20px; flex-wrap: wrap; }
.head .ico { width: 40px; height: 40px; border-radius: 4px; background: var(--navy); color: #fff; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.head h1 { margin: 0; font-size: 20px; font-weight: 700; }
.head .sub { color: var(--muted); font-size: 12.5px; }
.head .grow { flex: 1; min-width: 220px; }
.mode { font-size: 12px; font-weight: 700; padding: 4px 10px; border-radius: 12px; white-space: nowrap; }
.mode.on { background: var(--ok-bg); color: var(--ok); } .mode.off { background: var(--warn-bg); color: var(--warn); }
.tabs { display: flex; gap: 4px; border-top: 1px solid var(--line); padding: 0 12px; overflow-x: auto; }
.tabs a { padding: 11px 14px; font-weight: 600; color: var(--muted); text-decoration: none; border-bottom: 3px solid transparent; white-space: nowrap; }
.tabs a.on { color: var(--blue); border-bottom-color: var(--blue); }
.notice { margin: 12px 0; padding: 10px 14px; border-radius: 4px; border: 1px solid; font-size: 13px; }
.notice.err { background: var(--no-bg); border-color: #f7b8ae; color: #8c0412; }
.notice.info { background: #eef4ff; border-color: #c6dbff; color: #0b3a75; }
.notice.warn { background: var(--warn-bg); border-color: #f9d58a; color: #6b3d00; }
.notice.ok { background: var(--ok-bg); border-color: #b5dfa8; color: #1d5a30; }
.panel { display: none; margin-top: 12px; } .panel.on { display: block; }
.kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 12px; }
.kpi { padding: 16px 18px; } .kpi .l { color: var(--muted); font-size: 12px; text-transform: uppercase; letter-spacing: .5px; font-weight: 700; }
.kpi .v { font-size: 30px; font-weight: 700; margin-top: 4px; } .kpi .s { color: var(--muted); font-size: 12px; }
.kpi.alert .v { color: var(--no); }
.grid2 { display: grid; grid-template-columns: repeat(auto-fit, minmax(340px, 1fr)); gap: 12px; margin-top: 12px; }
.sec-h { padding: 12px 16px; border-bottom: 1px solid var(--line); font-weight: 700; display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.sec-h .grow { flex: 1; }
.bars { padding: 10px 16px 14px; }
.bar { display: grid; grid-template-columns: minmax(110px, 38%) 1fr 56px; gap: 10px; align-items: center; padding: 6px 0; font-size: 13px; }
.bar .t { height: 10px; background: #eef1f6; border-radius: 5px; overflow: hidden; } .bar .t i { display: block; height: 100%; background: var(--blue); }
.bar .n { text-align: right; font-variant-numeric: tabular-nums; font-weight: 600; }
.toolbar { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; padding: 12px 14px; border-bottom: 1px solid var(--line); }
.toolbar .grow { flex: 1; }
input[type=search], input[type=text], input[type=number], select, textarea { height: 34px; border: 1px solid #c9c9c9; border-radius: 4px; padding: 0 10px; font: inherit; background: #fff; color: var(--ink); }
textarea { height: auto; padding: 8px 10px; resize: vertical; }
input:focus, select:focus, textarea:focus { outline: none; border-color: var(--blue); box-shadow: 0 0 0 2px rgba(1,118,211,.2); }
.btn { border: 1px solid var(--blue); background: var(--blue); color: #fff; border-radius: 4px; padding: 7px 14px; font: inherit; font-weight: 600; cursor: pointer; white-space: nowrap; }
.btn:hover { background: var(--blue-d); } .btn.line { background: #fff; color: var(--blue); } .btn.line:hover { background: #f4f6f9; }
.btn.danger { background: #fff; color: var(--no); border-color: #e3a19a; } .btn.danger:hover { background: var(--no-bg); }
.btn.small { padding: 4px 10px; font-size: 12px; } .btn:disabled { opacity: .55; cursor: not-allowed; }
.icon { border: 0; background: none; color: var(--muted); cursor: pointer; padding: 4px 6px; border-radius: 4px; }
.icon:hover { background: #eef1f6; color: var(--blue); }
.tbl-wrap { overflow-x: auto; }
table { width: 100%; border-collapse: collapse; font-size: 13px; }
th { text-align: left; font-size: 11.5px; text-transform: uppercase; letter-spacing: .4px; color: var(--muted); background: #fafaf9; padding: 9px 10px; border-bottom: 1px solid var(--line); white-space: nowrap; }
td { padding: 8px 10px; border-bottom: 1px solid #ecebea; vertical-align: top; }
tr:hover td { background: #fbfcfe; }
td.num, th.num { text-align: right; font-variant-numeric: tabular-nums; }
.chip { display: inline-flex; align-items: center; gap: 4px; background: var(--chip); color: #0b3a75; border: 1px solid #c6dbff; border-radius: 12px; padding: 1px 4px 1px 9px; margin: 2px 4px 2px 0; font-size: 12px; }
.chip button { border: 0; background: none; color: #0b3a75; cursor: pointer; padding: 0 4px; font-size: 13px; line-height: 1; }
.chip.g { background: var(--ok-bg); border-color: #b5dfa8; color: var(--ok); padding-right: 9px; }
.chip.none { background: var(--warn-bg); border-color: #f9d58a; color: var(--warn); padding-right: 9px; }
.muted { color: var(--muted); } .small { font-size: 12px; }
.addrole { height: 26px; font-size: 12px; padding: 0 6px; max-width: 170px; }
.layout { display: grid; grid-template-columns: 290px minmax(0, 1fr); gap: 12px; align-items: start; }
.side { position: sticky; top: 84px; max-height: calc(100vh - 100px); display: flex; flex-direction: column; }
.side .top { padding: 12px; border-bottom: 1px solid var(--line); display: grid; gap: 8px; }
.side .list { overflow-y: auto; padding: 4px 0 10px; }
.item { display: flex; justify-content: space-between; gap: 8px; width: 100%; text-align: left; border: 0; background: none; padding: 8px 14px; font: inherit; font-size: 13px; cursor: pointer; border-left: 3px solid transparent; color: var(--ink); }
.item:hover { background: #f4f6f9; } .item.on { background: #e9f2fd; border-left-color: var(--blue); font-weight: 600; }
.item .n { color: var(--muted); font-size: 11.5px; font-weight: 400; white-space: nowrap; }
.pills { display: inline-flex; border: 1px solid var(--blue); border-radius: 4px; overflow: hidden; flex-wrap: wrap; }
.pills button { border: 0; background: #fff; color: var(--blue); padding: 7px 14px; font: inherit; font-weight: 600; cursor: pointer; }
.pills button.on { background: var(--blue); color: #fff; }
.lvl { display: flex; align-items: center; gap: 10px; padding: 10px 14px; border-bottom: 1px solid #ecebea; }
.lvl.proj { background: #f2f6fb; font-weight: 700; } .lvl.mod { background: #fafaf9; font-weight: 700; font-size: 13px; text-transform: uppercase; letter-spacing: .3px; color: #3e3e3c; }
.lvl .grow { flex: 1; }
.sw { position: relative; display: inline-block; width: 36px; height: 20px; flex: none; }
.sw input { opacity: 0; width: 0; height: 0; }
.sw span { position: absolute; inset: 0; background: #c9c9c9; border-radius: 10px; cursor: pointer; transition: .15s; }
.sw span:before { content: ""; position: absolute; width: 14px; height: 14px; left: 3px; top: 3px; background: #fff; border-radius: 50%; transition: .15s; }
.sw input:checked + span { background: var(--ok); } .sw input:checked + span:before { transform: translateX(16px); }
.sw input:focus-visible + span { box-shadow: 0 0 0 2px rgba(1,118,211,.4); }
.off-under td, .off-under .lvl { opacity: .45; }
table.perm { table-layout: fixed; min-width: 980px; }
table.perm th.pg { width: 26%; } table.perm th.acc { width: 74px; } table.perm th.act { width: 70px; }
td.act, th.act { text-align: center; } td.act input { width: 16px; height: 16px; cursor: pointer; }
.dash { color: #c9c9c9; }
.custom label { display: inline-flex; gap: 4px; align-items: center; margin: 2px 10px 2px 0; font-size: 12px; white-space: nowrap; }
.rhead { position: sticky; top: 70px; z-index: 20; background: #fff; border-radius: 4px 4px 0 0; }
.dirty { color: var(--warn); font-weight: 700; font-size: 12.5px; white-space: nowrap; }
.tree .node { display: flex; gap: 8px; align-items: center; padding: 7px 14px; border-bottom: 1px solid #f0efee; font-size: 13px; }
.tree .node.k-PROJECT { background: #f2f6fb; font-weight: 700; }
.tree .node.k-MODULE { padding-left: 30px; background: #fafaf9; font-weight: 600; }
.tree .node.k-PAGE { padding-left: 50px; } .tree .node.k-ACTION { padding-left: 74px; color: #3e3e3c; }
.tree .node .grow { flex: 1; min-width: 0; }
.badge { font-size: 10.5px; font-weight: 700; padding: 1px 6px; border-radius: 3px; background: #ecebea; color: #3e3e3c; white-space: nowrap; }
.code { font-family: Consolas, monospace; font-size: 11.5px; color: var(--muted); }
.ok { color: var(--ok); } .no { color: var(--no); }
.steps { display: grid; gap: 12px; }
.step { padding: 14px 16px; display: flex; gap: 14px; align-items: flex-start; flex-wrap: wrap; }
.step .num { width: 28px; height: 28px; border-radius: 50%; background: var(--navy); color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 700; flex: none; }
.step .grow { flex: 1; min-width: 240px; }
.step h3 { margin: 0 0 4px; font-size: 15px; }
dialog { border: 1px solid var(--line); border-radius: 6px; padding: 0; width: min(560px, calc(100vw - 32px)); box-shadow: 0 8px 30px rgba(0,0,0,.25); }
dialog::backdrop { background: rgba(8,7,7,.45); }
dialog form { display: grid; gap: 10px; padding: 18px 20px; } dialog h2 { margin: 0 0 4px; font-size: 17px; }
dialog label { display: grid; gap: 4px; font-size: 12.5px; font-weight: 600; color: #3e3e3c; }
dialog .row { display: flex; gap: 8px; justify-content: flex-end; margin-top: 6px; }
.empty { padding: 30px; text-align: center; color: var(--muted); }
.toast { position: fixed; right: 16px; bottom: 64px; background: #032d60; color: #fff; padding: 10px 14px; border-radius: 4px; box-shadow: 0 4px 12px rgba(0,0,0,.25); z-index: 1100; display: none; max-width: calc(100vw - 32px); }
.toast.err { background: var(--no); }
@media (max-width: 860px) { .layout { grid-template-columns: 1fr; } .side { position: static; max-height: 320px; } }
</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />
<div class="ua">
  <div class="card">
    <div class="head">
      <div class="ico"><i class="fa-solid fa-user-shield"></i></div>
      <div class="grow">
        <h1>Access Management (UAMS)</h1>
        <div class="sub">One place for users, roles and permissions across PInventory, School Operations and HR Management.</div>
      </div>
      <span id="modeBadge" class="mode off">Loading…</span>
    </div>
    <nav class="tabs" id="tabs">
      <a href="#dashboard" data-tab="dashboard"><i class="fa-solid fa-gauge"></i> Dashboard</a>
      <a href="#users" data-tab="users"><i class="fa-solid fa-users"></i> Users &amp; Roles</a>
      <a href="#roles" data-tab="roles"><i class="fa-solid fa-key"></i> Roles &amp; Permissions</a>
      <a href="#catalogue" data-tab="catalogue"><i class="fa-solid fa-sitemap"></i> Projects &amp; Pages</a>
      <a href="#migration" data-tab="migration"><i class="fa-solid fa-right-left"></i> Migration</a>
      <a href="#audit" data-tab="audit"><i class="fa-solid fa-clock-rotate-left"></i> Audit Trail</a>
    </nav>
  </div>
  <div id="globalMsg"></div>

  <!-- ============================ Dashboard -->
  <section class="panel" id="p-dashboard">
    <div class="kpis">
      <div class="card kpi"><div class="l">Total Users</div><div class="v" id="kUsers">–</div><div class="s" id="kGlobal"></div></div>
      <div class="card kpi"><div class="l">Total Roles</div><div class="v" id="kRoles">–</div><div class="s">UAMS roles</div></div>
      <div class="card kpi"><div class="l">Total Projects</div><div class="v" id="kProjects">–</div><div class="s">Applications managed here</div></div>
      <div class="card kpi" id="kWithoutCard"><div class="l">Users Without Roles</div><div class="v" id="kWithout">–</div><div class="s">Not counting Global users</div></div>
    </div>
    <div class="grid2">
      <div class="card"><div class="sec-h"><i class="fa-solid fa-layer-group"></i> Project-wise User Access</div><div class="bars" id="projBars"></div></div>
      <div class="card"><div class="sec-h"><i class="fa-solid fa-key"></i> Role-wise User Count</div><div class="bars" id="roleBars"></div></div>
    </div>
  </section>

  <!-- ============================ Users & Roles -->
  <section class="panel" id="p-users">
    <div class="card">
      <div class="toolbar">
        <input type="search" id="uSearch" placeholder="Search name or employee ID" style="min-width:260px" aria-label="Search users">
        <select id="uDept" aria-label="Filter by department"><option value="">All departments</option></select>
        <select id="uRole" aria-label="Filter by role"><option value="">All roles</option><option value="__none">Without roles</option></select>
        <span class="grow"></span>
        <span class="small muted" id="uCount"></span>
      </div>
      <div class="toolbar" style="background:#fafaf9">
        <span class="small"><b id="uSel">0</b> selected</span>
        <select id="bulkRole" aria-label="Role for selected users"><option value="">Choose a role…</option></select>
        <button class="btn small" id="bulkAdd" type="button"><i class="fa-solid fa-plus"></i> Give role</button>
        <button class="btn small line" id="bulkRemove" type="button"><i class="fa-solid fa-minus"></i> Remove role</button>
      </div>
      <div class="tbl-wrap">
        <table>
          <thead><tr>
            <th style="width:32px"><input type="checkbox" id="uAll" aria-label="Select all shown users"></th>
            <th>User Name</th><th>Employee Name</th><th>Employee ID</th><th>Department</th><th>Assigned Roles</th><th></th>
          </tr></thead>
          <tbody id="uBody"></tbody>
        </table>
      </div>
    </div>
  </section>

  <!-- ============================ Roles & Permissions -->
  <section class="panel" id="p-roles">
    <div class="layout">
      <div class="card side">
        <div class="top">
          <button class="btn" type="button" id="newRole"><i class="fa-solid fa-plus"></i> New role</button>
          <input type="search" id="rSearch" placeholder="Search roles" aria-label="Search roles">
        </div>
        <div class="list" id="rList"></div>
      </div>
      <div class="card" id="rEditor"><div class="empty">Choose a role on the left, or create a new one.</div></div>
    </div>
  </section>

  <!-- ============================ Catalogue -->
  <section class="panel" id="p-catalogue">
    <div class="notice info">Projects contain modules, modules contain pages, and pages contain actions. A new project, module, page or action
      added here can be given to roles straight away. A PInventory page is protected by its addresses; pages of other projects are checked by
      that project's own code, and an action is enforced only where the page's code checks it.</div>
    <div class="card">
      <div class="toolbar">
        <button class="btn" type="button" id="addProject"><i class="fa-solid fa-plus"></i> Add project</button>
        <button class="btn line" type="button" id="repair" title="Create missing module entries for pages added later">
          <i class="fa-solid fa-screwdriver-wrench"></i> Repair modules</button>
        <span class="grow"></span>
        <input type="search" id="cSearch" placeholder="Search pages" aria-label="Search catalogue">
      </div>
      <div class="tree" id="cTree"></div>
    </div>
  </section>

  <!-- ============================ Migration -->
  <section class="panel" id="p-migration">
    <div class="steps">
      <div class="card step">
        <div class="num">1</div>
        <div class="grow">
          <h3>Review: today's access vs. UAMS roles</h3>
          <div class="muted small">For each role + department in use, a starter role is planned with exactly what it can use today.
            Users who also have access by name get a "Personal" role. Nothing changes in this step.</div>
          <div id="migSummary" style="margin-top:8px"></div>
        </div>
        <button class="btn line" type="button" id="migRefresh"><i class="fa-solid fa-rotate"></i> Refresh</button>
      </div>
      <div class="card step">
        <div class="num">2</div>
        <div class="grow">
          <h3>Create the starter roles and assign users</h3>
          <div class="muted small">Creates only roles that do not exist yet and adds their users. Existing roles are not changed.
            Access stays on the old rules until step 3.</div>
        </div>
        <button class="btn" type="button" id="migApply">Create starter roles</button>
      </div>
      <div class="card step">
        <div class="num">3</div>
        <div class="grow">
          <h3>Switch all projects to UAMS roles</h3>
          <div class="muted small" id="modeText"></div>
        </div>
        <button class="btn" type="button" id="modeBtn">Switch</button>
      </div>
    </div>
    <div class="card" style="margin-top:12px">
      <div class="sec-h"><span class="grow">Users</span>
        <label class="small" style="font-weight:400"><input type="checkbox" id="migOnlyDiff"> Show only users with differences</label></div>
      <div class="tbl-wrap"><table>
        <thead><tr><th>User Name</th><th>Old role / department</th><th>UAMS roles</th><th>Pages &amp; actions (today → UAMS)</th><th>Result</th></tr></thead>
        <tbody id="migBody"></tbody>
      </table></div>
    </div>
  </section>

  <!-- ============================ Audit -->
  <section class="panel" id="p-audit">
    <div class="card">
      <div class="toolbar"><b class="grow">Last 200 changes</b><input type="search" id="aSearch" placeholder="Search" aria-label="Search audit"></div>
      <div class="tbl-wrap"><table>
        <thead><tr><th>Date &amp; time</th><th>Changed by</th><th>Type</th><th>Item</th><th>Change</th></tr></thead>
        <tbody id="aBody"></tbody>
      </table></div>
    </div>
  </section>
</div>

<div class="toast" id="toast" role="status" aria-live="polite"></div>

<dialog id="dlg"><form method="dialog" id="dlgForm"></form></dialog>

<script>
(function () {
  'use strict';
  var API = '<%= uCtx %>/uams/api/';
  var APPS = {};                 // app code -> project label
  var state = { users: null, roles: [], catalogue: null, actions: [], role: null, granted: null, saved: null, app: null, mode: 'LEGACY' };

  // ------------------------------------------------------------ helpers
  function $(id) { return document.getElementById(id); }
  function el(tag, attrs, kids) {
    var e = document.createElement(tag);
    if (attrs) Object.keys(attrs).forEach(function (k) {
      var v = attrs[k];
      if (v == null || v === false) return;
      if (k === 'text') e.textContent = v;
      else if (k === 'class') e.className = v;
      else if (k.slice(0, 2) === 'on') e.addEventListener(k.slice(2), v);
      else if (v === true) e.setAttribute(k, '');
      else e.setAttribute(k, v);
    });
    (kids || []).forEach(function (c) { if (c != null) e.appendChild(typeof c === 'string' ? document.createTextNode(c) : c); });
    return e;
  }
  function clear(e) { while (e.firstChild) e.removeChild(e.firstChild); return e; }
  function icon(cls) { return el('i', { class: cls }); }
  function toast(msg, err) {
    var t = $('toast'); t.textContent = msg; t.className = 'toast' + (err ? ' err' : ''); t.style.display = 'block';
    clearTimeout(toast.t); toast.t = setTimeout(function () { t.style.display = 'none'; }, err ? 6000 : 2600);
  }
  function fmt(n) { return Number(n || 0).toLocaleString('en-IN'); }
  async function api(path, body) {
    var opt = { credentials: 'same-origin', headers: { 'Accept': 'application/json' } };
    if (body !== undefined) {
      opt.method = 'POST'; opt.headers['Content-Type'] = 'application/json';
      if (window.CSRF_TOKEN) opt.headers['X-CSRF-Token'] = window.CSRF_TOKEN;
      opt.body = JSON.stringify(body);
    }
    var r = await fetch(API + path, opt);
    var data = null;
    try { data = await r.json(); } catch (e) { /* not JSON */ }
    if (!r.ok) {
      var err = new Error((data && data.message) || ('The server answered ' + r.status + '.'));
      err.status = r.status; err.data = data; throw err;
    }
    return data;
  }
  function showError(e) {
    clear($('globalMsg')).appendChild(el('div', { class: 'notice err', text: e.message }));
  }
  function setMode(mode) {
    state.mode = mode;
    var b = $('modeBadge');
    b.textContent = mode === 'ROLES' ? 'UAMS roles in use (all projects)' : 'Old rules in use (all projects)';
    b.className = 'mode ' + (mode === 'ROLES' ? 'on' : 'off');
  }
  function roleName(key) {
    for (var i = 0; i < state.roles.length; i++) if (state.roles[i].key === key) return state.roles[i].name;
    return key;
  }

  // ------------------------------------------------------------ tabs
  var loaders = {};
  function openTab() {
    var tab = (location.hash || '#dashboard').slice(1);
    if (!$('p-' + tab)) tab = 'dashboard';
    Array.prototype.forEach.call(document.querySelectorAll('#tabs a'), function (a) { a.classList.toggle('on', a.dataset.tab === tab); });
    Array.prototype.forEach.call(document.querySelectorAll('.panel'), function (p) { p.classList.toggle('on', p.id === 'p-' + tab); });
    clear($('globalMsg'));
    (loaders[tab] || function () {})().catch(showError);
  }
  window.addEventListener('hashchange', function () {
    if (dirtyCount() > 0 && location.hash !== '#roles' && !confirm('You have unsaved permission changes. Leave without saving?')) {
      history.replaceState(null, '', '#roles'); return;
    }
    if (location.hash !== '#roles') discard();
    openTab();
  });
  window.addEventListener('beforeunload', function (e) { if (dirtyCount() > 0) { e.preventDefault(); e.returnValue = ''; } });

  // ------------------------------------------------------------ dashboard
  loaders.dashboard = async function () {
    var d = await api('dashboard');
    setMode(d.mode);
    $('kUsers').textContent = fmt(d.totalUsers);
    $('kGlobal').textContent = fmt(d.globalUsers) + ' Global (full access)';
    $('kRoles').textContent = fmt(d.totalRoles);
    $('kProjects').textContent = fmt(d.totalProjects);
    $('kWithout').textContent = fmt(d.usersWithoutRoles);
    $('kWithoutCard').classList.toggle('alert', d.usersWithoutRoles > 0);
    var pb = clear($('projBars'));
    d.projects.forEach(function (p) {
      var pct = d.totalUsers ? Math.round(p.users * 100 / d.totalUsers) : 0;
      pb.appendChild(el('div', { class: 'bar', title: pct + '% of users' }, [
        el('span', {}, [el('b', { text: p.name }), el('div', { class: 'small muted', text: fmt(p.pages) + ' pages' })]),
        el('span', { class: 't' }, [el('i', { style: 'width:' + pct + '%' })]),
        el('span', { class: 'n', text: fmt(p.users) })
      ]));
    });
    if (!d.projects.length) pb.appendChild(el('div', { class: 'empty', text: 'Run uams.sql to add the projects.' }));
    if (d.mode !== 'ROLES') pb.appendChild(el('div', { class: 'notice warn', text: 'These counts show access through UAMS roles. Until the switch on the Migration tab, the old rules still decide access.' }));
    var rb = clear($('roleBars'));
    var roles = d.roles.slice().sort(function (a, b) { return b.users - a.users || a.name.localeCompare(b.name); });
    var max = roles.reduce(function (m, r) { return Math.max(m, r.users); }, 1);
    roles.forEach(function (r) {
      rb.appendChild(el('div', { class: 'bar' }, [
        el('span', { text: r.name }),
        el('span', { class: 't' }, [el('i', { style: 'width:' + Math.round(r.users * 100 / max) + '%' })]),
        el('span', { class: 'n', text: fmt(r.users) })
      ]));
    });
    if (!roles.length) rb.appendChild(el('div', { class: 'empty', text: 'No roles yet. Create them on the Migration tab or under Roles & Permissions.' }));
  };

  // ------------------------------------------------------------ users
  loaders.users = async function () {
    var d = await api('users');
    state.users = d.users; state.roles = d.roles;
    var depts = {};
    d.users.forEach(function (u) { if (u.department) depts[u.department] = 1; });
    fillSelect($('uDept'), Object.keys(depts).sort().map(function (x) { return [x, x]; }), 'All departments');
    fillSelect($('uRole'), [['__none', 'Without roles']].concat(d.roles.map(function (r) { return [r.key, r.name]; })), 'All roles');
    fillSelect($('bulkRole'), d.roles.map(function (r) { return [r.key, r.name]; }), 'Choose a role…');
    renderUsers();
  };
  function fillSelect(sel, items, first) {
    var keep = sel.value; clear(sel);
    sel.appendChild(el('option', { value: '', text: first }));
    items.forEach(function (i) { sel.appendChild(el('option', { value: i[0], text: i[1] })); });
    sel.value = keep; if (sel.value !== keep) sel.value = '';
  }
  function shownUsers() {
    var q = $('uSearch').value.trim().toLowerCase(), dept = $('uDept').value, role = $('uRole').value;
    return (state.users || []).filter(function (u) {
      if (dept && u.department !== dept) return false;
      if (role === '__none' && (u.global || u.roles.length)) return false;
      if (role && role !== '__none' && u.roles.indexOf(role) < 0) return false;
      if (!q) return true;
      return [u.username, u.employeeName, u.employeeId].some(function (v) { return v && v.toLowerCase().indexOf(q) >= 0; });
    });
  }
  var selected = {};
  function renderUsers() {
    var body = clear($('uBody')), list = shownUsers();
    $('uCount').textContent = list.length + ' of ' + state.users.length + ' users';
    list.forEach(function (u) {
      var roles = el('td');
      if (u.global) roles.appendChild(el('span', { class: 'chip g', title: 'Global users always have full access', text: 'Global (full access)' }));
      u.roles.forEach(function (k) {
        roles.appendChild(el('span', { class: 'chip' }, [roleName(k),
          el('button', { type: 'button', title: 'Remove this role', 'aria-label': 'Remove ' + roleName(k), onclick: function () { changeRoles(u, u.roles.filter(function (x) { return x !== k; })); } }, ['×'])]));
      });
      if (!u.global && !u.roles.length) roles.appendChild(el('span', { class: 'chip none', text: 'No role' }));
      var add = el('select', { class: 'addrole', 'aria-label': 'Add a role to ' + u.username, onchange: function () {
        if (add.value) changeRoles(u, u.roles.concat([add.value]));
      } });
      add.appendChild(el('option', { value: '', text: '+ Add role' }));
      state.roles.forEach(function (r) { if (u.roles.indexOf(r.key) < 0) add.appendChild(el('option', { value: r.key, text: r.name })); });
      if (!u.global) roles.appendChild(add);
      var cb = el('input', { type: 'checkbox', 'aria-label': 'Select ' + u.username, onchange: function () { selected[u.id] = cb.checked; countSel(); } });
      cb.checked = !!selected[u.id];
      body.appendChild(el('tr', {}, [
        el('td', {}, [cb]),
        el('td', {}, [el('b', { text: u.username }), u.oldRole ? el('div', { class: 'small muted', text: 'Old role: ' + u.oldRole }) : null]),
        el('td', { text: u.employeeName || '–' }),
        el('td', { text: u.employeeId || '–' }),
        el('td', { text: u.department || '–' }),
        roles,
        el('td', {}, [el('button', { class: 'icon', type: 'button', title: 'Edit employee details', 'aria-label': 'Edit employee details of ' + u.username,
          onclick: function () { editEmployee(u); } }, [icon('fa-solid fa-pen')])])
      ]));
    });
    if (!list.length) body.appendChild(el('tr', {}, [el('td', { colspan: 7, class: 'empty', text: 'No users match.' })]));
    countSel();
  }
  function countSel() {
    var ids = shownUsers().filter(function (u) { return selected[u.id]; });
    $('uSel').textContent = ids.length;
    return ids.map(function (u) { return u.id; });
  }
  async function changeRoles(u, roles) {
    try {
      await api('user-roles', { userId: u.id, roles: roles });
      u.roles = roles; renderUsers(); toast('Roles of ' + u.username + ' saved.');
    } catch (e) { toast(e.message, true); renderUsers(); }
  }
  async function bulk(add) {
    var role = $('bulkRole').value, ids = countSel();
    if (!role) { toast('Choose a role first.', true); return; }
    if (!ids.length) { toast('Select users first.', true); return; }
    if (!add && !confirm('Remove "' + roleName(role) + '" from ' + ids.length + ' user(s)?')) return;
    try {
      var r = await api('bulk-role', { role: role, userIds: ids, add: add });
      selected = {}; $('uAll').checked = false;
      await loaders.users(); toast(r.changed + ' user(s) updated.');
    } catch (e) { toast(e.message, true); }
  }
  function editEmployee(u) {
    var id = el('input', { type: 'text', maxlength: 30, value: u.employeeId || '' });
    var name = el('input', { type: 'text', maxlength: 120, value: u.employeeName || '' });
    dialog('Employee details: ' + u.username, [el('label', {}, ['Employee ID', id]), el('label', {}, ['Employee name', name])], async function () {
      await api('employee', { userId: u.id, employeeId: id.value, employeeName: name.value });
      u.employeeId = id.value.trim() || null; u.employeeName = name.value.trim() || null; renderUsers(); toast('Employee details saved.');
    });
  }
  $('uSearch').addEventListener('input', renderUsers);
  $('uDept').addEventListener('change', renderUsers);
  $('uRole').addEventListener('change', renderUsers);
  $('uAll').addEventListener('change', function () { shownUsers().forEach(function (u) { selected[u.id] = $('uAll').checked; }); renderUsers(); });
  $('bulkAdd').addEventListener('click', function () { bulk(true); });
  $('bulkRemove').addEventListener('click', function () { bulk(false); });

  // ------------------------------------------------------------ roles & permissions
  loaders.roles = async function () {
    var r = await Promise.all([api('roles'), api('catalogue')]);
    state.roles = r[0]; state.catalogue = r[1].projects; state.actions = r[1].actions; setMode(r[1].mode);
    state.catalogue.forEach(function (p) { if (p.kind === 'PROJECT') APPS[p.app] = p.label; });
    if (!state.app && state.catalogue.length) state.app = state.catalogue[0].app;
    renderRoleList();
    if (state.role && state.roles.some(function (x) { return x.key === state.role; })) await openRole(state.role, true);
    else { state.role = null; renderEditor(); }
  };
  function renderRoleList() {
    var q = $('rSearch').value.trim().toLowerCase(), list = clear($('rList'));
    state.roles.filter(function (r) { return !q || r.name.toLowerCase().indexOf(q) >= 0; }).forEach(function (r) {
      list.appendChild(el('button', { type: 'button', class: 'item' + (r.key === state.role ? ' on' : ''), onclick: function () { openRole(r.key); } }, [
        el('span', { text: r.name }), el('span', { class: 'n', text: r.users + (r.users === 1 ? ' user' : ' users') })]));
    });
    if (!state.roles.length) list.appendChild(el('div', { class: 'empty', text: 'No roles yet.' }));
  }
  async function openRole(key, keepEdits) {
    if (!keepEdits && dirtyCount() > 0 && !confirm('Discard unsaved changes to ' + roleName(state.role) + '?')) return;
    var keys = await api('role-permissions?role=' + encodeURIComponent(key));
    state.role = key; state.saved = new Set(keys); state.granted = new Set(keys);
    renderRoleList(); renderEditor(); updateSaveBar();
  }
  function dirtyCount() {
    if (!state.granted || !state.saved) return 0;
    var n = 0;
    state.granted.forEach(function (k) { if (!state.saved.has(k)) n++; });
    state.saved.forEach(function (k) { if (!state.granted.has(k)) n++; });
    return n;
  }
  function updateSaveBar() {
    var n = dirtyCount(), save = $('savePerms'), disc = $('discard'), info = $('dirtyInfo');
    if (save) { save.disabled = n === 0; save.lastChild.textContent = n ? ' Save permissions (' + n + ')' : ' Save permissions'; }
    if (disc) disc.disabled = n === 0;
    if (info) info.textContent = n ? n + ' unsaved change' + (n === 1 ? '' : 's') : 'All changes saved';
  }
  function discard() { if (state.saved) state.granted = new Set(state.saved); updateSaveBar(); }
  function setKey(key, on) { if (on) state.granted.add(key); else state.granted.delete(key); }
  function sw(key, on, label, onchange) {
    var i = el('input', { type: 'checkbox', 'aria-label': label });
    i.checked = on;
    i.addEventListener('change', function () { onchange(i.checked); });
    return el('label', { class: 'sw', title: label }, [i, el('span')]);
  }
  function renderEditor() {
    var box = clear($('rEditor'));
    if (!state.role) { box.appendChild(el('div', { class: 'empty', text: 'Choose a role on the left, or create a new one.' })); return; }
    var role = state.roles.filter(function (r) { return r.key === state.role; })[0] || { name: state.role, users: 0 };
    var head = el('div', { class: 'toolbar rhead' }, [
      el('div', { class: 'grow' }, [el('div', { style: 'font-size:16px;font-weight:700', text: role.name }),
        el('div', { class: 'small muted', text: (role.description || 'No description') + ' · ' + role.users + (role.users === 1 ? ' user' : ' users') })]),
      el('span', { id: 'dirtyInfo', class: 'dirty', 'aria-live': 'polite' }),
      el('button', { class: 'btn line', type: 'button', id: 'discard', onclick: doDiscard }, ['Discard']),
      el('button', { class: 'btn', type: 'button', id: 'savePerms', onclick: doSave }, [icon('fa-solid fa-floppy-disk'), ' Save permissions']),
      el('button', { class: 'btn small line', type: 'button', onclick: function () { editRole(role); } }, [icon('fa-solid fa-pen'), ' Rename']),
      el('button', { class: 'btn small danger', type: 'button', onclick: function () { deleteRole(role); } }, [icon('fa-solid fa-trash'), ' Delete'])
    ]);
    box.appendChild(head);
    var pills = el('div', { class: 'pills', role: 'tablist' });
    state.catalogue.filter(function (p) { return p.kind === 'PROJECT'; }).forEach(function (p) {
      pills.appendChild(el('button', { type: 'button', class: p.app === state.app ? 'on' : '', role: 'tab', 'aria-selected': p.app === state.app ? 'true' : 'false',
        onclick: function () { state.app = p.app; renderEditor(); } }, [p.label]));
    });
    box.appendChild(el('div', { class: 'toolbar' }, [pills, el('span', { class: 'grow' }),
      el('input', { type: 'search', id: 'pSearch', placeholder: 'Filter pages', 'aria-label': 'Filter pages', oninput: function () { renderTree(); } })]));
    var note = state.mode === 'ROLES' ? null
      : 'The old rules still decide access in PInventory, School Operations and HR Management. Settings made here take effect in all three when you switch on the Migration tab.';
    if (note) box.appendChild(el('div', { class: 'notice warn', style: 'margin:10px 14px', text: note }));
    box.appendChild(el('div', { id: 'pTree' }));
    renderTree();
    updateSaveBar();
  }
  function renderTree() {
    var wrap = clear($('pTree')), q = ($('pSearch') && $('pSearch').value.trim().toLowerCase()) || '';
    var proj = state.catalogue.filter(function (p) { return p.kind === 'PROJECT' && p.app === state.app; })[0];
    if (!proj) { wrap.appendChild(el('div', { class: 'empty', text: 'No such project.' })); return; }
    var projOn = state.granted.has(proj.key);
    wrap.appendChild(el('div', { class: 'lvl proj' }, [
      sw(proj.key, projOn, 'Project ' + proj.label, function (on) { setKey(proj.key, on); afterEdit(); }),
      el('span', { class: 'grow', text: 'Project: ' + proj.label }),
      el('button', { class: 'btn small line', type: 'button', onclick: function () { allIn(proj, true); } }, ['Allow all']),
      el('button', { class: 'btn small line', type: 'button', onclick: function () { allIn(proj, false); } }, ['Remove all'])
    ]));
    proj.children.forEach(function (mod) {
      if (mod.kind !== 'MODULE') return;
      var pages = mod.children.filter(function (pg) { return pg.kind === 'PAGE' && (!q || pg.label.toLowerCase().indexOf(q) >= 0); });
      if (q && !pages.length) return;
      var modOn = state.granted.has(mod.key);
      var block = el('div', { class: (!projOn ? 'off-under' : '') });
      block.appendChild(el('div', { class: 'lvl mod' }, [
        sw(mod.key, modOn, 'Module ' + mod.label, function (on) { setKey(mod.key, on); if (on) setKey(proj.key, true); afterEdit(); }),
        el('span', { class: 'grow', text: mod.label }),
        el('span', { class: 'small muted', style: 'text-transform:none;font-weight:400', text: pages.length + ' page(s)' })
      ]));
      var head = el('tr', {}, [el('th', { class: 'pg', text: 'Page' }), el('th', { class: 'acc', text: 'Access' })]
        .concat(state.actions.map(function (a) { return el('th', { class: 'act', text: a.charAt(0) + a.slice(1).toLowerCase() }); }))
        .concat([el('th', { text: 'Other options' })]));
      var tb = el('tbody');
      pages.forEach(function (pg) {
        var pageOn = state.granted.has(pg.key);
        var row = el('tr', { class: (!modOn && projOn) ? 'off-under' : '' });
        row.appendChild(el('td', {}, [el('div', { text: pg.label }), el('div', { class: 'code', text: pg.key })]));
        row.appendChild(el('td', {}, [sw(pg.key, pageOn, 'Page ' + pg.label, function (on) {
          setKey(pg.key, on); if (on) { setKey(mod.key, true); setKey(proj.key, true); } afterEdit();
        })]));
        var byCode = {}, custom = [];
        pg.children.forEach(function (a) { if (a.kind === 'ACTION') { if (a.actionCode) byCode[a.actionCode] = a; else custom.push(a); } });
        state.actions.forEach(function (code) {
          var a = byCode[code];
          if (!a) { row.appendChild(el('td', { class: 'act', title: 'Not controlled separately: page access decides' }, [el('span', { class: 'dash', text: '–' })])); return; }
          var c = el('input', { type: 'checkbox', title: a.label, 'aria-label': pg.label + ': ' + a.label });
          c.checked = state.granted.has(a.key);
          c.addEventListener('change', function () { setKey(a.key, c.checked); if (c.checked) { setKey(pg.key, true); setKey(mod.key, true); setKey(proj.key, true); } afterEdit(); });
          row.appendChild(el('td', { class: 'act' }, [c]));
        });
        var cust = el('td', { class: 'custom' });
        custom.forEach(function (a) {
          var c = el('input', { type: 'checkbox' }); c.checked = state.granted.has(a.key);
          c.addEventListener('change', function () { setKey(a.key, c.checked); if (c.checked) { setKey(pg.key, true); setKey(mod.key, true); setKey(proj.key, true); } afterEdit(); });
          cust.appendChild(el('label', {}, [c, a.label]));
        });
        if (!custom.length) cust.appendChild(el('span', { class: 'dash', text: '–' }));
        row.appendChild(cust);
        tb.appendChild(row);
      });
      block.appendChild(el('div', { class: 'tbl-wrap' }, [el('table', { class: 'perm' }, [el('thead', {}, [head]), tb])]));
      wrap.appendChild(block);
    });
  }
  function allIn(proj, on) {
    (function walk(n) { setKey(n.key, on); (n.children || []).forEach(walk); })(proj);
    afterEdit();
  }
  function afterEdit() { renderTree(); updateSaveBar(); }
  function doDiscard() { discard(); renderTree(); updateSaveBar(); }
  async function doSave() {
    var btn = $('savePerms'); if (btn) btn.disabled = true;
    try {
      var r = await api('role-permissions', { role: state.role, keys: Array.from(state.granted) });
      state.saved = new Set(state.granted); toast(r.changed + ' permission change(s) saved.');
      state.roles = await api('roles'); renderRoleList(); renderEditor();
    } catch (e) { toast(e.message, true); updateSaveBar(); }
  }
  $('rSearch').addEventListener('input', renderRoleList);
  $('newRole').addEventListener('click', function () { editRole(null); });
  function editRole(role) {
    var name = el('input', { type: 'text', maxlength: 100, required: true, value: role ? role.name : '' });
    var desc = el('textarea', { rows: 3, maxlength: 255 }); desc.value = role && role.description ? role.description : '';
    dialog(role ? 'Rename role' : 'New role', [el('label', {}, ['Role name', name]), el('label', {}, ['Description (optional)', desc])], async function () {
      var r = await api('role', { key: role ? role.key : null, name: name.value, description: desc.value });
      state.roles = await api('roles'); toast(role ? 'Role saved.' : 'Role created. Now choose what it may do.');
      await openRole(r.key, true);
    });
  }
  async function deleteRole(role) {
    if (role.users > 0) { toast(role.users + ' user(s) still hold this role. Remove it from them on Users & Roles first.', true); return; }
    if (!confirm('Delete the role "' + role.name + '" and its permissions?')) return;
    try { await api('role-delete', { key: role.key }); state.role = null; state.saved = state.granted = null; await loaders.roles(); toast('Role deleted.'); }
    catch (e) { toast(e.message, true); }
  }

  // ------------------------------------------------------------ catalogue
  loaders.catalogue = async function () {
    var c = await api('catalogue');
    state.catalogue = c.projects; state.actions = c.actions; setMode(c.mode);
    renderCatalogue();
  };
  function renderCatalogue() {
    var tree = clear($('cTree')), q = $('cSearch').value.trim().toLowerCase();
    function match(n) { return !q || (n.label || '').toLowerCase().indexOf(q) >= 0 || (n.key || '').toLowerCase().indexOf(q) >= 0 || (n.children || []).some(match); }
    function node(n, parent) {
      if (!match(n)) return;
      var kind = n.kind === 'ORPHANS' ? 'PROJECT' : n.kind;
      var tools = el('span');
      if (n.kind === 'PROJECT') tools.appendChild(el('button', { class: 'btn small line', type: 'button', onclick: function () { catForm({ kind: 'MODULE', app: n.app }); } }, ['+ Module']));
      if (n.kind === 'MODULE') tools.appendChild(el('button', { class: 'btn small line', type: 'button', onclick: function () { catForm({ kind: 'PAGE', parent: n.key, app: n.app }); } }, ['+ Page']));
      if (n.kind === 'PAGE') tools.appendChild(el('button', { class: 'btn small line', type: 'button', onclick: function () { catForm({ kind: 'ACTION', parent: n.key }); } }, ['+ Action']));
      if (n.kind !== 'ORPHANS') {
        tools.appendChild(el('button', { class: 'icon', type: 'button', title: 'Edit', 'aria-label': 'Edit ' + n.label, onclick: function () { catForm(n, true); } }, [icon('fa-solid fa-pen')]));
        tools.appendChild(el('button', { class: 'icon', type: 'button', title: 'Delete', 'aria-label': 'Delete ' + n.label, onclick: function () { catDelete(n); } }, [icon('fa-solid fa-trash')]));
      }
      tree.appendChild(el('div', { class: 'node k-' + kind }, [
        el('span', { class: 'badge', text: n.kind === 'ACTION' ? (n.actionCode || 'OPTION') : (n.kind === 'ORPHANS' ? 'CHECK' : n.kind) }),
        el('span', { class: 'grow' }, [el('span', { text: n.label + ' ' }), el('span', { class: 'code', text: n.key || '' }),
          n.paths ? el('div', { class: 'small muted', text: n.paths }) : null]),
        tools]));
      (n.children || []).forEach(function (c) { node(c, n); });
    }
    state.catalogue.forEach(function (p) { node(p, null); });
    if (!state.catalogue.length) tree.appendChild(el('div', { class: 'empty', text: 'The catalogue is empty. Run access_control.sql and uams.sql.' }));
  }
  function catForm(n, edit) {
    var kind = n.kind, f = {};
    var fields = [];
    if (!edit && kind === 'PROJECT') { f.app = el('input', { type: 'text', maxlength: 20, placeholder: 'e.g. LIBRARY' }); fields.push(el('label', {}, ['Project code (capital letters)', f.app])); }
    if (!edit && (kind === 'PAGE' || (kind === 'ACTION'))) {
      f.key = el('input', { type: 'text', maxlength: 80, placeholder: kind === 'PAGE' ? 'e.g. lib.issue-book' : 'only for a custom option' });
      fields.push(el('label', {}, [kind === 'PAGE' ? 'Page code' : 'Option code (custom options only)', f.key]));
    }
    if (kind === 'ACTION') {
      f.actionCode = el('select');
      f.actionCode.appendChild(el('option', { value: '', text: 'Custom option (named below)' }));
      state.actions.forEach(function (a) { f.actionCode.appendChild(el('option', { value: a, text: a.charAt(0) + a.slice(1).toLowerCase() })); });
      f.actionCode.value = n.actionCode || '';
      fields.push(el('label', {}, ['Action', f.actionCode]));
    }
    f.label = el('input', { type: 'text', maxlength: 120, required: true, value: edit ? n.label : '' });
    fields.push(el('label', {}, [kind === 'MODULE' && !edit ? 'Module name' : 'Name shown to admins', f.label]));
    if (kind === 'PAGE') {
      f.paths = el('input', { type: 'text', value: edit ? (n.paths || '') : '', placeholder: '/library/issue, /IssueBookServlet' });
      fields.push(el('label', {}, ['Addresses (PInventory pages, comma separated)', f.paths]));
    }
    f.description = el('textarea', { rows: 2, maxlength: 255 }); f.description.value = edit ? (n.description || '') : '';
    fields.push(el('label', {}, ['Description (optional)', f.description]));
    f.sort = el('input', { type: 'number', value: edit ? n.sort : 0 });
    fields.push(el('label', {}, ['Display order', f.sort]));
    var title = (edit ? 'Edit ' : 'Add ') + { PROJECT: 'project', MODULE: 'module', PAGE: 'page', ACTION: 'action' }[kind];
    dialog(title, fields, async function () {
      var body = { create: !edit, kind: kind, key: edit ? n.key : (f.key ? f.key.value : null), app: f.app ? f.app.value : n.app, parent: n.parent || null };
      Object.keys(f).forEach(function (k) { if (k !== 'key' && k !== 'app') body[k] = f[k].value; });
      await api('catalogue', body); await loaders.catalogue(); toast('Saved.');
    });
  }
  async function catDelete(n) {
    if (!confirm('Delete "' + n.label + '"? This works only when no role uses it and nothing is under it.')) return;
    try { await api('catalogue-delete', { key: n.key }); await loaders.catalogue(); toast('Deleted.'); } catch (e) { toast(e.message, true); }
  }
  $('addProject').addEventListener('click', function () { catForm({ kind: 'PROJECT' }); });
  $('cSearch').addEventListener('input', renderCatalogue);
  $('repair').addEventListener('click', async function () {
    try { var r = await api('catalogue-repair', {}); await loaders.catalogue(); toast(r.added + ' module(s) added.'); } catch (e) { toast(e.message, true); }
  });

  // ------------------------------------------------------------ migration
  var mig = null;
  loaders.migration = async function () { mig = await api('migration'); renderMigration(); };
  function renderMigration() {
    setMode(mig.mode);
    var s = clear($('migSummary'));
    s.appendChild(el('div', { class: 'notice ' + (mig.different ? 'warn' : 'ok') }, [
      el('b', { text: mig.same + ' user(s) keep exactly the same access' }),
      mig.different ? ', ' + mig.different + ' user(s) differ (see below).' : '.',
      ' Starter roles planned: ' + mig.roles.length + ' (' + mig.toCreate + ' to create).']));
    $('migApply').disabled = !mig.toCreate || mig.mode === 'ROLES';
    $('migApply').textContent = mig.toCreate ? 'Create ' + mig.toCreate + ' starter role(s)' : 'Starter roles created';
    var roles = mig.mode === 'ROLES';
    $('modeText').textContent = roles
      ? 'PInventory, School Operations and HR Management now use UAMS roles only. Switching back restores the old rules at once; roles and assignments are kept.'
      : 'After the switch only UAMS roles decide access in PInventory, School Operations and HR Management (Global users keep full access). You can switch back at any time.';
    $('modeBtn').textContent = roles ? 'Switch back to old rules' : 'Switch to UAMS roles';
    $('modeBtn').className = roles ? 'btn danger' : 'btn';
    var body = clear($('migBody')), only = $('migOnlyDiff').checked;
    mig.users.forEach(function (u) {
      if (only && u.same) return;
      var res = u.global ? el('span', { class: 'chip g', text: 'Global' }) : (u.same
        ? el('span', { class: 'ok' }, [icon('fa-solid fa-circle-check'), ' Same'])
        : el('div', {}, [el('span', { class: 'no' }, [icon('fa-solid fa-triangle-exclamation'), ' Differs']),
            u.lost.length ? el('div', { class: 'small', text: 'Loses: ' + u.lost.join(', ') }) : null,
            u.gained.length ? el('div', { class: 'small', text: 'Gains: ' + u.gained.join(', ') }) : null]));
      var counts = el('td', { class: 'small' });
      (u.projects || []).forEach(function (p) { counts.appendChild(el('div', { text: p.project + ': ' + p.before + ' → ' + p.after })); });
      body.appendChild(el('tr', {}, [
        el('td', {}, [el('b', { text: u.username })]),
        el('td', { text: (u.oldRole || '–') + ' / ' + (u.department || '–') }),
        el('td', { text: u.global ? 'Full access' : ((u.roles || []).join(', ') || '–') }),
        counts, el('td', {}, [res])]));
    });
  }
  $('migOnlyDiff').addEventListener('change', function () { if (mig) renderMigration(); });
  $('migRefresh').addEventListener('click', function () { loaders.migration().catch(showError); });
  $('migApply').addEventListener('click', async function () {
    if (!confirm('Create ' + mig.toCreate + ' starter role(s) and assign their users? Access does not change until step 3.')) return;
    try { mig = await api('migration-apply', {}); renderMigration(); toast(mig.createdRoles + ' role(s) created, ' + mig.assignments + ' assignment(s).'); }
    catch (e) { toast(e.message, true); }
  });
  $('modeBtn').addEventListener('click', async function () {
    var target = state.mode === 'ROLES' ? 'LEGACY' : 'ROLES';
    if (target === 'ROLES' && mig && mig.different && !confirm(mig.different + ' user(s) will not have exactly the same access. Switch anyway?')) return;
    if (!confirm(target === 'ROLES' ? 'Switch all projects to UAMS roles now?' : 'Switch all projects back to the old rules now?')) return;
    try {
      await api('mode', { mode: target });
    } catch (e) {
      if (e.status === 409 && e.data && e.data.needsConfirm) {
        if (!confirm(e.data.message + ' Switch anyway?')) return;
        try { await api('mode', { mode: target, force: true }); } catch (e2) { toast(e2.message, true); return; }
      } else { toast(e.message, true); return; }
    }
    toast(target === 'ROLES' ? 'All projects now use UAMS roles.' : 'All projects are back on the old rules.');
    await loaders.migration();
  });

  // ------------------------------------------------------------ audit
  var auditRows = [];
  loaders.audit = async function () { auditRows = await api('audit'); renderAudit(); };
  function renderAudit() {
    var q = $('aSearch').value.trim().toLowerCase(), body = clear($('aBody'));
    auditRows.filter(function (a) { return !q || [a.by, a.what, a.item, a.detail].join(' ').toLowerCase().indexOf(q) >= 0; }).forEach(function (a) {
      body.appendChild(el('tr', {}, [el('td', { text: a.at, style: 'white-space:nowrap' }), el('td', { text: a.by }), el('td', { text: a.what }),
        el('td', { text: a.item }), el('td', { text: a.detail })]));
    });
    if (!body.firstChild) body.appendChild(el('tr', {}, [el('td', { colspan: 5, class: 'empty', text: 'No changes yet.' })]));
  }
  $('aSearch').addEventListener('input', renderAudit);

  // ------------------------------------------------------------ dialog
  function dialog(title, fields, onSave) {
    var d = $('dlg'), f = clear($('dlgForm'));
    var msg = el('div');
    f.appendChild(el('h2', { text: title }));
    fields.forEach(function (x) { f.appendChild(x); });
    f.appendChild(msg);
    var save = el('button', { class: 'btn', type: 'submit', text: 'Save' });
    f.appendChild(el('div', { class: 'row' }, [el('button', { class: 'btn line', type: 'button', text: 'Cancel', onclick: function () { d.close(); } }), save]));
    f.onsubmit = async function (e) {
      e.preventDefault(); save.disabled = true; clear(msg);
      try { await onSave(); d.close(); }
      catch (err) { msg.appendChild(el('div', { class: 'notice err', text: err.message })); }
      finally { save.disabled = false; }
    };
    d.showModal();
    var first = f.querySelector('input,select,textarea'); if (first) first.focus();
  }

  openTab();
})();
</script>
<jsp:include page="/WEB-INF/views/layout/Footer.jsp" />
</body>
</html>
