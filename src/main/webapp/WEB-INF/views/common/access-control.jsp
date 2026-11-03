<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Opened through AccessControlServlet (/access-control), which allows the Global role only.
    String acCtx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Access Control</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root { --blue:#0176d3; --blue-d:#014486; --navy:#032d60; --ink:#181818; --muted:#5c5c5c; --line:#dddbda; --soft:#f3f3f3;
        --ok:#2e844a; --ok-bg:#ebf7e6; --no:#ba0517; --no-bg:#feded8; --warn:#a96404; --warn-bg:#fef1d6; }
* { box-sizing: border-box; }
body { margin: 0; background: var(--soft); color: var(--ink); font: 14px/1.45 'Salesforce Sans', Inter, 'Segoe UI', Arial, sans-serif; }
.ac { max-width: 1320px; margin: 0 auto; padding: 14px 16px 140px; }
.card { background: #fff; border: 1px solid var(--line); border-radius: 4px; box-shadow: 0 2px 2px rgba(0,0,0,.06); }
.ac-head { display: flex; gap: 14px; align-items: center; padding: 16px 20px; flex-wrap: wrap; }
.ac-head .ico { width: 40px; height: 40px; border-radius: 4px; background: var(--navy); color: #fff; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.ac-head h1 { margin: 0; font-size: 20px; font-weight: 700; }
.ac-head .sub { color: var(--muted); font-size: 12.5px; }
.ac-head .grow { flex: 1; min-width: 220px; }
.tabs { display: flex; gap: 4px; border-top: 1px solid var(--line); padding: 0 12px; overflow-x: auto; }
.tabs button { border: 0; background: none; padding: 11px 14px; font: inherit; font-weight: 600; color: var(--muted); cursor: pointer; border-bottom: 3px solid transparent; white-space: nowrap; }
.tabs button.on { color: var(--blue); border-bottom-color: var(--blue); }
.notice { margin: 12px 0; padding: 10px 14px; border-radius: 4px; border: 1px solid; font-size: 13px; }
.notice.err { background: var(--no-bg); border-color: #f7b8ae; color: #8c0412; }
.notice.info { background: #eef4ff; border-color: #c6dbff; color: #0b3a75; }
.layout { display: grid; grid-template-columns: 280px minmax(0, 1fr); gap: 12px; margin-top: 12px; align-items: start; }
.subjects { position: sticky; top: 84px; max-height: calc(100vh - 100px); display: flex; flex-direction: column; }
.subjects .top { padding: 12px; border-bottom: 1px solid var(--line); }
.subjects .list { overflow-y: auto; padding: 4px 0 10px; }
.grp { font-size: 10.5px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: .6px; padding: 12px 14px 4px; }
.subj { display: flex; justify-content: space-between; gap: 8px; width: 100%; text-align: left; border: 0; background: none; padding: 7px 14px;
        font: inherit; font-size: 13px; cursor: pointer; border-left: 3px solid transparent; color: var(--ink); }
.subj:hover { background: #f4f6f9; }
.subj.on { background: #e9f2fd; border-left-color: var(--blue); font-weight: 600; }
.subj .n { color: var(--muted); font-size: 11.5px; font-weight: 400; white-space: nowrap; }
.subj .dot { display: inline-block; min-width: 18px; padding: 0 5px; margin-left: 4px; border-radius: 9px; background: var(--blue); color: #fff; font-size: 10.5px; text-align: center; }
input[type=search], input[type=text], select { height: 34px; border: 1px solid #c9c9c9; border-radius: 4px; padding: 0 10px; font: inherit; background: #fff; color: var(--ink); }
input[type=search]:focus, input[type=text]:focus, select:focus { outline: none; border-color: var(--blue); box-shadow: 0 0 0 2px rgba(1,118,211,.2); }
.w100 { width: 100%; }
.toolbar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; padding: 12px 14px; border-bottom: 1px solid var(--line); }
.toolbar .who { font-size: 16px; font-weight: 700; margin-right: auto; }
.toolbar .who small { display: block; font-size: 12px; font-weight: 400; color: var(--muted); }
.apps { display: inline-flex; border: 1px solid var(--blue); border-radius: 4px; overflow: hidden; }
.apps button { border: 0; background: #fff; color: var(--blue); padding: 7px 14px; font: inherit; font-weight: 600; cursor: pointer; }
.apps button.on { background: var(--blue); color: #fff; }
.btn { border: 1px solid var(--blue); background: var(--blue); color: #fff; border-radius: 4px; padding: 7px 14px; font: inherit; font-weight: 600; cursor: pointer; white-space: nowrap; }
.btn:hover { background: var(--blue-d); }
.btn.line { background: #fff; color: var(--blue); }
.btn.line:hover { background: #f4f6f9; }
.btn.small { padding: 4px 10px; font-size: 12px; }
.btn:disabled { opacity: .55; cursor: not-allowed; }
.module { border-bottom: 1px solid var(--line); }
.module:last-child { border-bottom: 0; }
.mod-head { display: flex; align-items: center; gap: 10px; padding: 10px 14px; background: #fafaf9; border-bottom: 1px solid #ecebea; }
.mod-head h3 { margin: 0; font-size: 13px; text-transform: uppercase; letter-spacing: .4px; color: #3e3e3c; flex: 1; }
.mod-head .cnt { font-size: 12px; color: var(--muted); }
table { width: 100%; border-collapse: collapse; }
td { padding: 8px 14px; border-bottom: 1px solid #f0efee; vertical-align: middle; text-align: left; }
tr:last-child td { border-bottom: 0; }
td.name { width: 38%; }
td.name b { font-weight: 600; }
td.name .k { display: block; font-size: 11px; color: var(--muted); font-family: Consolas, monospace; }
td.name .d { display: block; font-size: 11.5px; color: var(--warn); }
tr.action td.name { padding-left: 38px; }
tr.action td.name b { font-weight: 400; }
tr.action td.name b::before { content: "\f0da"; font-family: "Font Awesome 6 Free"; font-weight: 900; color: #a0a0a0; margin-right: 7px; }
td.set { width: 150px; }
td.set select { width: 140px; }
td.set select.allow { border-color: var(--ok); background: var(--ok-bg); color: var(--ok); font-weight: 600; }
td.set select.deny { border-color: var(--no); background: var(--no-bg); color: var(--no); font-weight: 600; }
tr.dirty td.set select { box-shadow: 0 0 0 2px var(--warn); }
td.who { color: var(--muted); font-size: 12px; }
.chip { display: inline-block; margin: 2px 4px 2px 0; padding: 1px 8px; border-radius: 10px; font-size: 11.5px; background: #eef1f6; color: #2b2b2b; white-space: nowrap; }
.chip.deny { background: var(--no-bg); color: var(--no); }
.chip.me { outline: 1px solid var(--blue); }
.chip.g { background: #e5e5e5; color: #444; }
.empty { padding: 26px; text-align: center; color: var(--muted); }
.savebar { position: fixed; left: 0; right: 0; bottom: 46px; z-index: 1001; background: #fff; border-top: 1px solid var(--line); box-shadow: 0 -2px 6px rgba(0,0,0,.08);
           display: none; align-items: center; gap: 10px; padding: 10px max(16px, calc((100% - 1290px)/2)); }
.savebar.show { display: flex; }
.toolbar .save-group { display: flex; gap: 8px; align-items: center; }
.toolbar .save-group .msg { font-size: 12.5px; font-weight: 600; color: var(--warn); }
.savebar .msg { margin-right: auto; font-weight: 600; color: var(--warn); }
.pane { display: none; }
.pane.on { display: block; }
.check { padding: 14px; display: flex; gap: 10px; flex-wrap: wrap; align-items: center; border-bottom: 1px solid var(--line); }
.res td.name { width: auto; }
.res td.st { width: 130px; white-space: nowrap; }
.yes { color: var(--ok); font-weight: 600; }
.no { color: #9a9a9a; }
.hist th { text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .4px; color: var(--muted); padding: 9px 14px; background: #fafaf9; border-bottom: 1px solid var(--line); }
.toast { position: fixed; right: 18px; bottom: 74px; z-index: 990; padding: 10px 16px; border-radius: 4px; color: #fff; background: var(--ok); box-shadow: 0 3px 8px rgba(0,0,0,.2); display: none; }
.toast.err { background: var(--no); }
@media (max-width: 860px) {
  .layout { grid-template-columns: 1fr; }
  .subjects { position: static; max-height: 300px; }
  td.who { display: none; }
  td.name { width: auto; }
}
</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />

<div class="ac">
  <div class="card">
    <div class="ac-head">
      <div class="ico"><i class="fa-solid fa-user-shield"></i></div>
      <div class="grow">
        <h1>Access Control</h1>
        <div class="sub">Choose which roles and departments may open each page and use each button in PInventory and School Operations.
          Global users always have full access. Changes apply within 30 seconds.</div>
      </div>
      <a class="btn line" href="<%= acCtx %>/settings"><i class="fa-solid fa-gear"></i> Settings Master</a>
    </div>
    <div class="tabs" role="tablist">
      <button type="button" class="on" data-pane="edit" role="tab">Edit access</button>
      <button type="button" data-pane="check" role="tab">Check a user</button>
      <button type="button" data-pane="hist" role="tab">Change history</button>
    </div>
  </div>

  <div id="loadErr" class="notice err" hidden></div>

  <!-- ===== Edit access ===== -->
  <div class="pane on" id="pane-edit">
    <div class="layout">
      <aside class="card subjects" aria-label="Who">
        <div class="top"><input type="search" id="subjSearch" class="w100" placeholder="Find a role, department or user" autocomplete="off"></div>
        <div class="list" id="subjList"></div>
      </aside>
      <section class="card" aria-label="Pages and buttons">
        <div class="toolbar">
          <div class="who" id="whoTitle">Select who to edit<small id="whoSub"></small></div>
          <div class="apps" id="appTabs">
            <button type="button" class="on" data-app="PINVENTORY">PInventory</button>
            <button type="button" data-app="SCHOOLOPS">School Operations</button>
          </div>
        </div>
        <div class="toolbar">
          <input type="search" id="permSearch" placeholder="Find a page or button" autocomplete="off" style="flex:1;min-width:180px">
          <label style="display:flex;gap:6px;align-items:center;font-size:13px">Copy from
            <select id="copyFrom"><option value="">&mdash; choose &mdash;</option></select></label>
          <button type="button" class="btn line small" id="copyBtn">Copy</button>
          <div class="save-group">
            <span class="msg" id="topMsg"></span>
            <button type="button" class="btn line" id="discardTop" disabled>Discard</button>
            <button type="button" class="btn" id="saveTop" disabled><i class="fa-solid fa-floppy-disk"></i> Save</button>
          </div>
        </div>
        <div id="modules"><div class="empty">Loading&hellip;</div></div>
      </section>
    </div>
  </div>

  <!-- ===== Check a user ===== -->
  <div class="pane" id="pane-check">
    <div class="card" style="margin-top:12px">
      <div class="check">
        <input type="text" id="userName" list="userList" placeholder="Username" autocomplete="off" style="min-width:240px">
        <datalist id="userList"></datalist>
        <button type="button" class="btn" id="checkBtn">Show access</button>
        <span id="checkWho" class="sub" style="color:var(--muted)"></span>
      </div>
      <div id="checkOut"><div class="empty">Enter a username to see every page and button that user can use.</div></div>
    </div>
  </div>

  <!-- ===== History ===== -->
  <div class="pane" id="pane-hist">
    <div class="card" style="margin-top:12px;overflow-x:auto">
      <table class="hist"><thead><tr><th>Date &amp; time</th><th>Changed by</th><th>For</th><th>Page / button</th><th>From</th><th>To</th></tr></thead>
        <tbody id="histRows"><tr><td colspan="6" class="empty">Loading&hellip;</td></tr></tbody></table>
    </div>
  </div>
</div>

<div class="savebar" id="saveBar">
  <span class="msg" id="saveMsg"></span>
  <button type="button" class="btn line" id="discardBtn">Discard</button>
  <button type="button" class="btn" id="saveBtn"><i class="fa-solid fa-floppy-disk"></i> Save changes</button>
</div>
<div class="toast" id="toast" role="status"></div>

<script>
(function () {
  'use strict';
  var BASE = '<%= acCtx %>/access-control';
  var TYPE_LABEL = { ALL: 'All users', ROLE: 'Role', DEPT: 'Department', USER: 'User' };
  var EFFECT = { ALLOW: 'Allow', DENY: 'Deny' };
  var data = null, grants = {}, subject = null, app = 'PINVENTORY', changes = {}, users = [];

  function $(id) { return document.getElementById(id); }
  function el(tag, cls, text) { var e = document.createElement(tag); if (cls) e.className = cls; if (text != null) e.textContent = text; return e; }
  function sid(type, subj) { return type + ':' + subj; }
  function toast(msg, bad) { var t = $('toast'); t.textContent = msg; t.className = 'toast' + (bad ? ' err' : ''); t.style.display = 'block';
    clearTimeout(toast.h); toast.h = setTimeout(function () { t.style.display = 'none'; }, 3500); }
  function fmtDate(s) {   // "2026-11-02 14:05:09.0" -> 02-11-2026 14:05
    if (!s) return ''; var m = /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})/.exec(s); return m ? m[3] + '-' + m[2] + '-' + m[1] + ' ' + m[4] + ':' + m[5] : s;
  }
  async function api(url, opt) {
    var r = await fetch(url, Object.assign({ credentials: 'same-origin', headers: { 'Accept': 'application/json' } }, opt || {}));
    var body = null; try { body = await r.json(); } catch (e) { }
    if (!r.ok) throw new Error((body && body.error) || ('Request failed (' + r.status + ')'));
    return body;
  }

  // ---------- tabs
  document.querySelectorAll('.tabs button').forEach(function (b) {
    b.addEventListener('click', function () {
      document.querySelectorAll('.tabs button').forEach(function (x) { x.classList.toggle('on', x === b); });
      document.querySelectorAll('.pane').forEach(function (p) { p.classList.toggle('on', p.id === 'pane-' + b.dataset.pane); });
      if (b.dataset.pane === 'hist') loadHistory();
    });
  });
  $('appTabs').addEventListener('click', function (e) {
    var b = e.target.closest('button'); if (!b) return;
    app = b.dataset.app;
    $('appTabs').querySelectorAll('button').forEach(function (x) { x.classList.toggle('on', x === b); });
    renderModules();
  });

  // ---------- load
  async function load() {
    try {
      data = await api(BASE + '/data');
    } catch (e) {
      $('loadErr').textContent = e.message; $('loadErr').hidden = false; $('modules').innerHTML = ''; return;
    }
    grants = {};
    data.grants.forEach(function (g) { (grants[g.key] = grants[g.key] || {})[sid(g.type, g.subject)] = g.effect; });
    users = data.users;
    var dl = $('userList'); dl.innerHTML = '';
    users.forEach(function (u) { var o = el('option'); o.value = u.username; dl.appendChild(o); });
    renderSubjects();
    if (!subject) pick({ type: 'ALL', subject: '*', name: 'All users', users: users.length });
    else renderModules();
  }

  function subjectList() {
    var out = [{ type: 'ALL', subject: '*', name: 'All users', users: users.length, group: 'Everyone' }];
    data.roles.forEach(function (r) { out.push({ type: 'ROLE', subject: r.subject, name: r.name, users: r.users, group: 'Roles' }); });
    data.departments.forEach(function (d) { out.push({ type: 'DEPT', subject: d.subject, name: d.name, users: d.users, group: 'Departments' }); });
    // roles / departments that have settings but no user today (so their settings can still be changed)
    var seen = {}; out.forEach(function (o) { seen[sid(o.type, o.subject)] = true; });
    data.grants.forEach(function (g) {
      if ((g.type === 'ROLE' || g.type === 'DEPT') && !seen[sid(g.type, g.subject)]) {
        seen[sid(g.type, g.subject)] = true;
        out.push({ type: g.type, subject: g.subject, name: g.subject, users: 0, group: g.type === 'ROLE' ? 'Roles' : 'Departments' });
      }
    });
    out.sort(function (x, y) { var o = { Everyone: 0, Roles: 1, Departments: 2 }; return (o[x.group] - o[y.group]) || x.name.localeCompare(y.name); });
    // users: only those who already have a personal exception, plus the one being searched
    var withGrants = {};
    data.grants.forEach(function (g) { if (g.type === 'USER') withGrants[g.subject] = true; });
    var q = $('subjSearch').value.trim().toUpperCase();
    users.forEach(function (u) {
      var n = (u.username || '').toUpperCase().replace(/[^A-Z0-9_]/g, '_');
      if (withGrants[n] || (q.length >= 2 && n.indexOf(q.replace(/[^A-Z0-9_]/g, '_')) > -1))
        out.push({ type: 'USER', subject: n, name: u.username, users: null, group: 'Users (personal exceptions)', detail: (u.role || '') + (u.department ? ' \u00b7 ' + u.department : '') });
    });
    return out;
  }

  function countFor(s) {
    var n = 0, id = sid(s.type, s.subject);
    Object.keys(grants).forEach(function (k) { if (grants[k][id]) n++; });
    return n;
  }

  function renderSubjects() {
    var list = $('subjList'), q = $('subjSearch').value.trim().toLowerCase(), group = null;
    list.innerHTML = '';
    subjectList().forEach(function (s) {
      if (q && s.name.toLowerCase().indexOf(q) < 0 && s.subject.toLowerCase().indexOf(q) < 0) return;
      if (s.group !== group) { group = s.group; list.appendChild(el('div', 'grp', group)); }
      var b = el('button', 'subj' + (subject && subject.type === s.type && subject.subject === s.subject ? ' on' : ''));
      b.type = 'button';
      var left = el('span', null, s.name);
      var c = countFor(s); if (c) { var d = el('span', 'dot', String(c)); d.title = c + ' setting(s)'; left.appendChild(d); }
      b.appendChild(left);
      b.appendChild(el('span', 'n', s.users != null ? s.users + ' user' + (s.users === 1 ? '' : 's') : (s.detail || '')));
      b.addEventListener('click', function () { pick(s); });
      list.appendChild(b);
    });
    // fill "copy from"
    var cf = $('copyFrom'), keep = cf.value; cf.innerHTML = '<option value="">\u2014 choose \u2014</option>';
    subjectList().forEach(function (s) {
      if (subject && s.type === subject.type && s.subject === subject.subject) return;
      var o = el('option', null, (s.type === 'ALL' ? '' : TYPE_LABEL[s.type] + ': ') + s.name); o.value = sid(s.type, s.subject); cf.appendChild(o);
    });
    cf.value = keep;
  }
  $('subjSearch').addEventListener('input', renderSubjects);

  function pick(s) {
    if (Object.keys(changes).length && !confirm('You have unsaved changes for ' + subject.name + '. Discard them?')) return;
    changes = {}; subject = s; updateBar();
    $('whoTitle').firstChild.textContent = (s.type === 'ALL' ? '' : TYPE_LABEL[s.type] + ': ') + s.name;
    $('whoSub').textContent = s.type === 'ALL' ? 'Applies to every signed-in user (a role or department "Deny" still removes it).'
      : s.type === 'USER' ? 'Personal exception: overrides this user\'s role and department.'
      : (s.users != null ? s.users + ' user(s) have this ' + (s.type === 'ROLE' ? 'role' : 'department') + '.' : '');
    renderSubjects(); renderModules();
  }

  // ---------- pages and buttons
  function current(key) {
    var id = sid(subject.type, subject.subject);
    if (Object.prototype.hasOwnProperty.call(changes, key)) return changes[key];
    return (grants[key] && grants[key][id]) || '';
  }

  function chips(key, td) {
    var g = grants[key] || {}, ids = Object.keys(g).sort(), me = sid(subject.type, subject.subject);
    td.appendChild(el('span', 'chip g', 'Global'));
    ids.forEach(function (id) {
      var p = id.split(':'), type = p[0], name = p.slice(1).join(':');
      var label = type === 'ALL' ? 'All users' : TYPE_LABEL[type] + ': ' + name;
      var c = el('span', 'chip' + (g[id] === 'DENY' ? ' deny' : '') + (id === me ? ' me' : ''), (g[id] === 'DENY' ? '\u2715 ' : '') + label);
      td.appendChild(c);
    });
  }

  function row(p, isAction) {
    var tr = el('tr', isAction ? 'action' : 'page'); tr.dataset.key = p.key;
    var name = el('td', 'name'); name.appendChild(el('b', null, p.label)); name.appendChild(el('span', 'k', p.key));
    if (p.description) name.appendChild(el('span', 'd', p.description));
    var set = el('td', 'set'), sel = el('select');
    sel.setAttribute('aria-label', 'Access to ' + p.label);
    [['', 'Not set'], ['ALLOW', 'Allow']].concat(subject.type === 'ALL' ? [] : [['DENY', 'Deny']]).forEach(function (o) {
      var op = el('option', null, o[1]); op.value = o[0]; sel.appendChild(op);
    });
    sel.value = current(p.key); paint(sel);
    sel.addEventListener('change', function () { setChange(p.key, sel.value); paint(sel); tr.classList.toggle('dirty', Object.prototype.hasOwnProperty.call(changes, p.key)); });
    set.appendChild(sel);
    var who = el('td', 'who'); chips(p.key, who);
    tr.appendChild(name); tr.appendChild(set); tr.appendChild(who);
    if (Object.prototype.hasOwnProperty.call(changes, p.key)) tr.classList.add('dirty');
    return tr;
  }
  function paint(sel) { sel.className = sel.value === 'ALLOW' ? 'allow' : sel.value === 'DENY' ? 'deny' : ''; }

  function setChange(key, value) {
    var id = sid(subject.type, subject.subject), saved = (grants[key] && grants[key][id]) || '';
    if (value === saved) delete changes[key]; else changes[key] = value;
    updateBar();
  }

  function renderModules() {
    var box = $('modules'); box.innerHTML = '';
    if (!data || !subject) return;
    var q = $('permSearch').value.trim().toLowerCase();
    var perms = data.permissions.filter(function (p) { return p.app === app; });
    var children = {};
    perms.forEach(function (p) { if (p.parent) (children[p.parent] = children[p.parent] || []).push(p); });
    var mods = [], byMod = {};
    perms.forEach(function (p) {
      if (p.parent) return;
      if (!byMod[p.module]) { byMod[p.module] = []; mods.push(p.module); }
      byMod[p.module].push(p);
    });
    var shown = 0;
    mods.forEach(function (m) {
      var pages = byMod[m].filter(function (p) {
        if (!q) return true;
        var txt = (m + ' ' + p.label + ' ' + p.key + ' ' + (children[p.key] || []).map(function (c) { return c.label; }).join(' ')).toLowerCase();
        return txt.indexOf(q) > -1;
      });
      if (!pages.length) return;
      var sec = el('div', 'module'), head = el('div', 'mod-head');
      head.appendChild(el('h3', null, m));
      var n = 0; pages.forEach(function (p) { n += 1 + (children[p.key] || []).length; });
      head.appendChild(el('span', 'cnt', n + ' item' + (n === 1 ? '' : 's')));
      var all = el('button', 'btn line small', 'Allow all'); all.type = 'button';
      var none = el('button', 'btn line small', 'Clear'); none.type = 'button';
      head.appendChild(all); head.appendChild(none);
      var t = el('table'), tb = el('tbody'); t.appendChild(tb);
      pages.forEach(function (p) {
        tb.appendChild(row(p, false));
        (children[p.key] || []).forEach(function (c) { tb.appendChild(row(c, true)); });
      });
      function bulk(v) {
        tb.querySelectorAll('tr').forEach(function (tr) {
          var sel = tr.querySelector('select'); sel.value = v; paint(sel); setChange(tr.dataset.key, v);
          tr.classList.toggle('dirty', Object.prototype.hasOwnProperty.call(changes, tr.dataset.key));
        });
      }
      all.addEventListener('click', function () { bulk('ALLOW'); });
      none.addEventListener('click', function () { bulk(''); });
      sec.appendChild(head); sec.appendChild(t); box.appendChild(sec); shown++;
    });
    if (!shown) box.appendChild(el('div', 'empty', q ? 'No page or button matches "' + q + '".' : 'Nothing to show.'));
  }
  $('permSearch').addEventListener('input', renderModules);

  $('copyBtn').addEventListener('click', function () {
    var from = $('copyFrom').value; if (!from || !subject) return;
    var me = sid(subject.type, subject.subject), n = 0;
    data.permissions.forEach(function (p) {
      var v = (grants[p.key] && grants[p.key][from]) || '';
      if (subject.type === 'ALL' && v === 'DENY') v = '';
      if (v !== current(p.key)) { setChange(p.key, v); n++; }
    });
    renderModules();
    toast(n ? n + ' setting(s) copied. Review and press Save.' : 'Nothing different to copy.');
  });

  function updateBar() {
    var n = Object.keys(changes).length;
    $('saveBar').classList.toggle('show', n > 0);
    $('saveMsg').textContent = n + ' unsaved change' + (n === 1 ? '' : 's') + (subject ? ' for ' + subject.name : '');
    $('saveTop').disabled = n === 0; $('discardTop').disabled = n === 0;
    $('topMsg').textContent = n ? n + ' unsaved' : '';
  }
  $('saveTop').addEventListener('click', function () { $('saveBtn').click(); });
  $('discardTop').addEventListener('click', function () { $('discardBtn').click(); });
  $('discardBtn').addEventListener('click', function () { changes = {}; updateBar(); renderModules(); });
  $('saveBtn').addEventListener('click', async function () {
    var keys = Object.keys(changes); if (!keys.length) return;
    var b = $('saveBtn'); b.disabled = true; $('saveTop').disabled = true;
    try {
      var res = await api(BASE + '/save', { method: 'POST', headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
        body: JSON.stringify({ subjectType: subject.type, subject: subject.subject,
          changes: keys.map(function (k) { return { key: k, effect: changes[k] || null }; }) }) });
      changes = {}; updateBar();
      toast(res.saved + ' change(s) saved for ' + subject.name + '.');
      await load();
    } catch (e) { toast(e.message, true); }
    finally { b.disabled = false; updateBar(); }
  });
  window.addEventListener('beforeunload', function (e) { if (Object.keys(changes).length) { e.preventDefault(); e.returnValue = ''; } });

  // ---------- check a user
  async function check() {
    var u = $('userName').value.trim(); if (!u) return;
    var out = $('checkOut'); out.innerHTML = '<div class="empty">Loading\u2026</div>';
    try {
      var r = await api(BASE + '/effective?username=' + encodeURIComponent(u));
      out.innerHTML = '';
      if (!r.found) { $('checkWho').textContent = ''; out.appendChild(el('div', 'empty', 'No user named "' + u + '".')); return; }
      $('checkWho').textContent = 'Role: ' + (r.role || '\u2014') + ' \u00b7 Department: ' + (r.department || '\u2014')
        + ((r.role || '').trim().toLowerCase() === 'global' ? ' \u00b7 Global: full access' : '');
      var ok = {}; r.allowed.forEach(function (k) { ok[k] = true; });
      ['PINVENTORY', 'SCHOOLOPS'].forEach(function (a) {
        var perms = data.permissions.filter(function (p) { return p.app === a; });
        var sec = el('div', 'module'), head = el('div', 'mod-head');
        head.appendChild(el('h3', null, a === 'PINVENTORY' ? 'PInventory' : 'School Operations'));
        var yes = perms.filter(function (p) { return ok[p.key]; }).length;
        head.appendChild(el('span', 'cnt', yes + ' of ' + perms.length + ' allowed'));
        var t = el('table', 'res'), tb = el('tbody'); t.appendChild(tb);
        perms.forEach(function (p) {
          var tr = el('tr', p.parent ? 'action' : 'page'), name = el('td', 'name');
          name.appendChild(el('b', null, p.label)); name.appendChild(el('span', 'k', p.module));
          var st = el('td', 'st ' + (ok[p.key] ? 'yes' : 'no'), ok[p.key] ? '\u2713 Allowed' : '\u2014 No');
          tr.appendChild(name); tr.appendChild(st); tb.appendChild(tr);
        });
        sec.appendChild(head); sec.appendChild(t); out.appendChild(sec);
      });
    } catch (e) { out.innerHTML = ''; out.appendChild(el('div', 'notice err', e.message)); }
  }
  $('checkBtn').addEventListener('click', check);
  $('userName').addEventListener('keydown', function (e) { if (e.key === 'Enter') check(); });

  // ---------- history
  async function loadHistory() {
    var tb = $('histRows');
    try {
      var rows = await api(BASE + '/audit');
      tb.innerHTML = '';
      if (!rows.length) { var tr = el('tr'), td = el('td', 'empty', 'No changes yet.'); td.colSpan = 6; tr.appendChild(td); tb.appendChild(tr); return; }
      rows.forEach(function (r) {
        var tr = el('tr');
        [fmtDate(r.at), r.by, (r.type === 'ALL' ? 'All users' : TYPE_LABEL[r.type] + ': ' + r.subject), (r.label || r.key),
         EFFECT[r.old] || 'Not set', EFFECT[r['new']] || 'Not set'].forEach(function (v) { tr.appendChild(el('td', null, v)); });
        tb.appendChild(tr);
      });
    } catch (e) { tb.innerHTML = ''; var tr = el('tr'), td = el('td', null, e.message); td.colSpan = 6; tr.appendChild(td); tb.appendChild(tr); }
  }

  load();
})();
</script>
<jsp:include page="/WEB-INF/views/layout/Footer.jsp" />
</body>
</html>
