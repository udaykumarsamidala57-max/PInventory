<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.officecentral.common.web.Csrf" %>
<%
    String roleCtx = request.getContextPath();
    String roleCsrf = Csrf.token(session);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>User Role Assignments</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root { --blue:#0176d3; --blue-d:#014486; --navy:#032d60; --ink:#181818; --muted:#5c5c5c; --line:#dddbda; --soft:#f3f3f3; --green:#2e844a; --green-bg:#ebf7e6; }
* { box-sizing:border-box; }
body { margin:0; background:var(--soft); color:var(--ink); font:14px/1.45 'Salesforce Sans',Inter,'Segoe UI',Arial,sans-serif; }
.page { max-width:1320px; margin:0 auto; padding:14px 16px 120px; }
.card { background:#fff; border:1px solid var(--line); border-radius:5px; box-shadow:0 2px 3px rgba(0,0,0,.06); }
.head { display:flex; align-items:center; gap:12px; padding:13px 16px; }
.head .ico { width:38px; height:38px; display:grid; place-items:center; border-radius:4px; color:#fff; background:var(--navy); font-size:16px; }
h1 { margin:0; font-size:19px; line-height:1.2; }
.sub { margin-top:3px; color:var(--muted); font-size:12px; }
.head .grow { flex:1; min-width:220px; }
.btn { display:inline-flex; align-items:center; justify-content:center; gap:7px; min-height:34px; padding:6px 12px; border:1px solid var(--blue); border-radius:4px; background:var(--blue); color:#fff; font:inherit; font-size:13px; font-weight:600; cursor:pointer; text-decoration:none; white-space:nowrap; }
.btn:hover { background:var(--blue-d); }
.btn.line { background:#fff; color:var(--blue); }
.btn:disabled { opacity:.55; cursor:not-allowed; }
.body { display:grid; grid-template-columns:300px minmax(0,1fr); gap:12px; margin-top:12px; align-items:start; }
.user-panel { min-height:420px; max-height:calc(100vh - 145px); display:flex; flex-direction:column; overflow:hidden; }
.panel-head { padding:10px 12px; border-bottom:1px solid var(--line); }
.panel-title { margin:0 0 8px; font-size:13px; font-weight:700; display:flex; align-items:center; justify-content:space-between; }
input[type=search] { width:100%; height:34px; padding:0 10px; border:1px solid #c9c9c9; border-radius:4px; font:inherit; }
input[type=search]:focus { outline:0; border-color:var(--blue); box-shadow:0 0 0 2px rgba(1,118,211,.18); }
.user-list { overflow:auto; padding:4px 0; }
.user { width:100%; border:0; border-left:3px solid transparent; background:#fff; padding:8px 11px; text-align:left; font:inherit; cursor:pointer; }
.user:hover { background:#f7f9fc; }
.user.on { background:#eef4fe; border-left-color:var(--blue); }
.user strong { display:block; font-size:13px; font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.user small { display:flex; gap:6px; color:var(--muted); font-size:11px; margin-top:2px; }
.user small span { overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.right { min-height:420px; }
.right-head { display:flex; align-items:center; gap:12px; padding:11px 14px; border-bottom:1px solid var(--line); }
.avatar { width:36px; height:36px; flex:0 0 auto; display:grid; place-items:center; border-radius:50%; color:var(--blue); background:#eaf3fb; font-weight:700; }
.right-title { flex:1; min-width:0; }
.right-title h2 { margin:0; font-size:16px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.right-title div { color:var(--muted); font-size:12px; margin-top:2px; }
.role-count { color:var(--blue-d); background:#eaf3fb; padding:3px 8px; border-radius:12px; font-size:11px; font-weight:700; white-space:nowrap; }
.rule { padding:9px 14px; color:#3e3e3c; background:#f8f9fb; border-bottom:1px solid var(--line); font-size:12px; }
.roles { display:grid; grid-template-columns:repeat(auto-fill,minmax(205px,1fr)); gap:8px; padding:12px; }
.role { display:flex; align-items:center; gap:9px; min-height:44px; padding:8px 10px; border:1px solid var(--line); border-radius:4px; cursor:pointer; }
.role:hover { border-color:#8ab9e6; background:#f8fbff; }
.role.selected { border-color:#91c79e; background:#f4fbf4; }
.role input { width:16px; height:16px; margin:0; accent-color:var(--blue); }
.role .name { min-width:0; flex:1; font-weight:600; font-size:13px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.role .badge { color:var(--green); background:var(--green-bg); padding:2px 6px; border-radius:10px; font-size:10px; font-weight:700; }
.empty { padding:26px 16px; text-align:center; color:var(--muted); }
.empty i { display:block; color:#9ca3af; font-size:22px; margin-bottom:8px; }
.note { margin:0 12px 12px; padding:9px 11px; border:1px solid #d8e7f5; border-radius:4px; background:#f4f9fd; color:#3e3e3c; font-size:12px; }
.savebar { position:fixed; left:0; right:0; bottom:46px; z-index:1001; display:none; align-items:center; gap:10px; padding:9px max(16px,calc((100% - 1290px)/2)); background:#fff; border-top:1px solid var(--line); box-shadow:0 -2px 6px rgba(0,0,0,.08); }
.savebar.show { display:flex; }
.save-msg { flex:1; font-weight:600; color:#a96404; font-size:12px; }
.toast { position:fixed; right:18px; bottom:74px; z-index:1100; display:none; padding:10px 14px; border-radius:4px; background:var(--green); color:#fff; box-shadow:0 3px 8px rgba(0,0,0,.2); }
.toast.err { background:#ba0517; }
@media(max-width:800px) { .body { grid-template-columns:1fr; } .user-panel { min-height:0; max-height:300px; } .head { flex-wrap:wrap; } .head .grow { min-width:180px; } }
@media(max-width:520px) { .page { padding:10px 8px 120px; } .head { align-items:flex-start; } .head .btn { width:100%; } .roles { grid-template-columns:1fr; } .role-count { display:none; } }
</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />
<main class="page">
  <section class="card head">
    <div class="ico"><i class="fa-solid fa-users-gear"></i></div>
    <div class="grow"><h1>User Role Assignments</h1><div class="sub">Give each user one or more roles. PHRMS page and action access is granted to roles only.</div></div>
    <a class="btn line" href="<%= roleCtx %>/access-control"><i class="fa-solid fa-user-shield"></i> Access Control</a>
  </section>
  <section class="body">
    <aside class="card user-panel">
      <div class="panel-head"><div class="panel-title"><span>Users</span><span id="userCount" class="sub"></span></div><input id="userSearch" type="search" placeholder="Search name, role or department"></div>
      <div id="users" class="user-list"><div class="empty">Loading users…</div></div>
    </aside>
    <section class="card right" aria-label="Roles assigned to selected user">
      <div id="roleHead" class="right-head">
        <div class="avatar"><i class="fa-solid fa-user"></i></div>
        <div class="right-title"><h2 id="selectedName">Select a user</h2><div id="selectedMeta">Choose a user to review assigned roles.</div></div>
        <span id="roleCount" class="role-count"></span>
      </div>
      <div class="rule"><i class="fa-solid fa-circle-info"></i> The user's primary role is retained. Add or remove additional roles below; all PHRMS access is combined from assigned roles.</div>
      <div id="roleGrid" class="roles"><div class="empty" style="grid-column:1/-1">Loading role catalogue…</div></div>
      <div id="globalNote" class="note" hidden><i class="fa-solid fa-shield-halved"></i> This account has the Global role and already receives full access.</div>
    </section>
  </section>
</main>
<div class="savebar" id="saveBar"><span class="save-msg" id="saveMsg">Unsaved changes</span><button class="btn line" id="discardBtn" type="button">Discard</button><button class="btn" id="saveBtn" type="button"><i class="fa-solid fa-floppy-disk"></i> Save assignments</button></div>
<div class="toast" id="toast" role="status"></div>
<script>
(function(){
  'use strict';
  var BASE='<%= roleCtx %>/user-roles', CSRF='<%= roleCsrf %>', data=null, selected=null, saved=[], working=[];
  function $(id){return document.getElementById(id);}
  function el(tag,cls,txt){var n=document.createElement(tag);if(cls)n.className=cls;if(txt!=null)n.textContent=txt;return n;}
  function esc(s){return String(s||'');}
  async function api(url,opt){opt=opt||{};opt.credentials='same-origin';opt.headers=Object.assign({'Accept':'application/json','X-CSRF-Token':CSRF},opt.headers||{});var r=await fetch(url,opt),b=null;try{b=await r.json();}catch(e){}if(!r.ok)throw new Error((b&&b.error)||('Request failed ('+r.status+')'));return b;}
  function showToast(msg,bad){var t=$('toast');t.textContent=msg;t.className='toast'+(bad?' err':'');t.style.display='block';clearTimeout(showToast.timer);showToast.timer=setTimeout(function(){t.style.display='none';},3500);}
  function dirty(){var a=working.slice().sort().join('|'),b=saved.slice().sort().join('|');return a!==b;}
  function updateBar(){var d=dirty();$('saveBar').classList.toggle('show',d);$('saveMsg').textContent=d?'Unsaved role changes for '+(selected?selected.username:'this user')+'.':'No unsaved changes.';}
  function userMatch(u,q){return !q||(u.username+' '+u.primary+' '+u.department+' '+u.roles.join(' ')).toLowerCase().indexOf(q)>-1;}
  function renderUsers(){var box=$('users'),q=$('userSearch').value.trim().toLowerCase();box.innerHTML='';var rows=data.users.filter(function(u){return userMatch(u,q);});$('userCount').textContent=rows.length+' of '+data.users.length;if(!rows.length){box.appendChild(el('div','empty','No matching users.'));return;}rows.forEach(function(u){var b=el('button','user'+(selected&&selected.id===u.id?' on':''));b.type='button';b.appendChild(el('strong',null,u.username));var small=el('small');small.appendChild(el('span',null,(u.primary==='GLOBAL'?'Global':(u.primary||'No primary role'))+(u.department?' · '+u.department:'')));small.appendChild(el('span',null,u.roles.length+' role'+(u.roles.length===1?'':'s')));b.appendChild(small);b.addEventListener('click',function(){choose(u);});box.appendChild(b);});}
  function choose(u){if(selected&&selected.id===u.id)return;if(dirty()&&!confirm('Discard unsaved role changes for '+selected.username+'?'))return;selected=u;saved=u.roles.slice();working=u.roles.slice();renderUsers();renderRoles();updateBar();}
  function renderRoles(){var grid=$('roleGrid');grid.innerHTML='';if(!selected){grid.appendChild(el('div','empty','Select a user to view role assignments.'));return;}var global=selected.primary==='GLOBAL';$('globalNote').hidden=!global;$('selectedName').textContent=selected.username;$('selectedMeta').textContent=(selected.primary==='GLOBAL'?'Global access':('Primary role: '+(selected.primary||'Not set')))+(selected.department?' · '+selected.department:'');$('roleCount').textContent=working.length+' assigned';if(!data.roles.length){grid.appendChild(el('div','empty','No roles are configured yet.'));return;}data.roles.forEach(function(r){var checked=working.indexOf(r.key)>=0,primary=selected.primary===r.key;var label=el('label','role'+(checked?' selected':''));var input=document.createElement('input');input.type='checkbox';input.value=r.key;input.checked=checked;input.disabled=primary||global;input.addEventListener('change',function(){var i=working.indexOf(r.key);if(input.checked&&i<0)working.push(r.key);else if(!input.checked&&i>=0)working.splice(i,1);selected.roles=working.slice();label.classList.toggle('selected',input.checked);$('roleCount').textContent=working.length+' assigned';updateBar();renderUsers();});label.appendChild(input);label.appendChild(el('span','name',r.name));if(primary)label.appendChild(el('span','badge','PRIMARY'));grid.appendChild(label);});if(global)grid.appendChild(el('div','note','Additional roles cannot change this account’s Global access.'));}
  async function load(preserveId){var d=await api(BASE+'/data');data=d;if(preserveId){selected=data.users.find(function(u){return u.id===preserveId;})||null;}else if(!selected&&data.users.length)selected=data.users[0];if(selected){saved=selected.roles.slice();working=selected.roles.slice();}renderUsers();renderRoles();updateBar();}
  $('userSearch').addEventListener('input',renderUsers);
  $('discardBtn').addEventListener('click',function(){working=saved.slice();if(selected)selected.roles=working.slice();renderRoles();renderUsers();updateBar();});
  $('saveBtn').addEventListener('click',async function(){if(!selected||!dirty())return;var b=$('saveBtn');b.disabled=true;try{var res=await api(BASE+'/save',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({userId:selected.id,roles:working})});showToast(res.saved+' role change'+(res.saved===1?'':'s')+' saved for '+selected.username+'.');await load(selected.id);}catch(e){showToast(e.message,true);}finally{b.disabled=false;}});
  window.addEventListener('beforeunload',function(e){if(dirty()){e.preventDefault();e.returnValue='';}});
  load().catch(function(e){$('users').innerHTML='';$('users').appendChild(el('div','empty',e.message));$('roleGrid').innerHTML='';$('roleGrid').appendChild(el('div','empty',e.message));});
})();
</script>
<jsp:include page="/WEB-INF/views/layout/Footer.jsp" />
</body>
</html>
