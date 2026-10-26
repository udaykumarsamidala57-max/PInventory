<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*, com.mobile.MobileAccessDAO" %>
<%!
    private static String esc(Object o) {
        if (o == null) return "";
        String s = String.valueOf(o);
        StringBuilder b = new StringBuilder(s.length() + 16);
        for (char c : s.toCharArray()) {
            switch (c) {
                case '<': b.append("&lt;"); break;
                case '>': b.append("&gt;"); break;
                case '&': b.append("&amp;"); break;
                case '"': b.append("&quot;"); break;
                case '\'': b.append("&#39;"); break;
                default: b.append(c);
            }
        }
        return b.toString();
    }
%>
<%
    @SuppressWarnings("unchecked") List<String[]> rows = (List<String[]>) request.getAttribute("rows");
    @SuppressWarnings("unchecked") Map<String, Boolean> rules = (Map<String, Boolean>) request.getAttribute("rules");
    List<String> features = new ArrayList<>(MobileAccessDAO.FEATURES.keySet());
    String[] icons = {"fa-right-to-bracket", "fa-clipboard-list", "fa-plus", "fa-circle-check",
                      "fa-boxes-stacked", "fa-screwdriver-wrench", "fa-paper-plane", "fa-pen-to-square"};
    String msg = (String) request.getAttribute("message");
    String msgType = (String) request.getAttribute("messageType");
    String ctx = request.getContextPath();

    // Group: default row (*|*) and, per department, the role rows of that department.
    int defaultIndex = -1;
    Map<String, List<Integer>> byDept = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
    for (int i = 0; i < rows.size(); i++) {
        String[] r = rows.get(i);
        boolean anyRole = MobileAccessDAO.ANY.equals(r[0]), anyDept = MobileAccessDAO.ANY.equals(r[1]);
        if (anyRole && anyDept) defaultIndex = i;
        else if (!anyRole && !anyDept) byDept.computeIfAbsent(r[1], k -> new ArrayList<>()).add(i);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Mobile App Access | Office Central ERP</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <style>
    :root { --blue:#0176d3; --navy:#032d60; --ink:#181818; --muted:#5e5e5e; --line:#dddbda; --page:#f3f3f3; --green:#2e844a; --red:#ea001e; }
    * { box-sizing:border-box; }
    body { margin:0; background:var(--page); color:var(--ink); font:14px/1.45 "Salesforce Sans",Inter,"Segoe UI",Arial,sans-serif; }
    .topbar { height:54px; display:flex; align-items:center; justify-content:space-between; padding:0 max(18px,calc((100% - 1240px)/2)); background:linear-gradient(135deg,var(--navy),var(--blue)); color:#fff; }
    .brand { font-weight:700; } .topbar a { color:#fff; text-decoration:none; font-size:13px; }
    main { max-width:1240px; margin:20px auto; padding:0 18px 90px; }
    h1 { margin:0; font-size:22px; font-weight:600; display:flex; align-items:center; gap:10px; } h1 i { color:#3ddc84; }
    .subtitle { margin:4px 0 16px; color:var(--muted); font-size:13px; }
    .msg { padding:10px 14px; border-radius:8px; margin-bottom:14px; font-weight:600; }
    .msg.success { background:#e8f5ee; color:var(--green); border:1px solid #b7dfc5; }
    .msg.error { background:#fdecea; color:var(--red); border:1px solid #f5b8b0; }
    .layout { display:grid; grid-template-columns:250px 1fr; gap:18px; align-items:start; }
    .depts { background:#fff; border:1px solid var(--line); border-radius:12px; padding:8px; position:sticky; top:12px; max-height:calc(100vh - 140px); overflow:auto; }
    .dept-btn { display:flex; justify-content:space-between; align-items:center; width:100%; border:0; background:none; text-align:left; padding:10px 12px; border-radius:8px; font:inherit; cursor:pointer; color:var(--ink); }
    .dept-btn:hover { background:#f4f8fd; }
    .dept-btn.active { background:linear-gradient(135deg,var(--navy),var(--blue)); color:#fff; font-weight:600; }
    .dept-btn .n { font-size:11px; background:#edf4fb; color:var(--blue); border-radius:20px; padding:1px 8px; }
    .dept-btn.active .n { background:#ffffff33; color:#fff; }
    .dept-btn.default { border-bottom:1px solid var(--line); border-radius:8px 8px 0 0; margin-bottom:6px; }
    .dept-select { display:none; width:100%; height:40px; border:1px solid #c9c9c9; border-radius:8px; padding:0 10px; font:inherit; margin-bottom:12px; }
    .panel-title { font-size:17px; font-weight:600; margin:2px 0 4px; }
    .panel-sub { color:var(--muted); font-size:12.5px; margin-bottom:12px; }
    .cards { display:grid; grid-template-columns:repeat(auto-fill,minmax(330px,1fr)); gap:14px; }
    .card { background:#fff; border:1px solid var(--line); border-radius:12px; box-shadow:0 2px 6px #0000000a; overflow:hidden; }
    .card-head { display:flex; justify-content:space-between; align-items:center; padding:12px 14px; border-bottom:1px solid #ecebea; background:#fafaf9; }
    .card-head .role { font-weight:700; font-size:15px; }
    .card-head .role small { display:block; font-weight:400; color:var(--muted); font-size:12px; }
    .reset { border:0; background:none; color:var(--blue); font:inherit; font-size:12px; cursor:pointer; }
    .opt { display:flex; align-items:center; justify-content:space-between; padding:9px 14px; border-bottom:1px solid #f3f2f2; }
    .opt:last-child { border-bottom:0; }
    .opt .label { display:flex; align-items:center; gap:10px; }
    .opt .label i { width:18px; text-align:center; color:var(--blue); }
    .opt .tag { font-size:10.5px; color:#939393; margin-left:6px; }
    .opt.changed { background:#f4f8fd; }
    .card.blocked .opt:not(:first-child) { opacity:.45; }
    .switch { position:relative; width:44px; height:24px; flex:none; }
    .switch input { opacity:0; width:0; height:0; }
    .slider { position:absolute; inset:0; background:#c9c9c9; border-radius:24px; cursor:pointer; transition:.2s; }
    .slider:before { content:""; position:absolute; width:18px; height:18px; left:3px; top:3px; background:#fff; border-radius:50%; transition:.2s; box-shadow:0 1px 3px #0003; }
    .switch input:checked + .slider { background:var(--green); }
    .switch input:checked + .slider:before { transform:translateX(20px); }
    .empty { color:var(--muted); padding:30px; text-align:center; background:#fff; border:1px dashed var(--line); border-radius:12px; }
    .savebar { position:fixed; left:0; right:0; bottom:0; background:#fff; border-top:1px solid var(--line); padding:10px max(18px,calc((100% - 1240px)/2)); display:flex; justify-content:space-between; align-items:center; box-shadow:0 -4px 12px #0000000d; }
    .save { border:0; border-radius:8px; background:linear-gradient(135deg,var(--navy),var(--blue)); color:#fff; padding:10px 22px; font:inherit; font-weight:700; cursor:pointer; }
    .save:disabled { opacity:.45; cursor:default; }
    .changed-count { color:var(--blue); font-weight:600; font-size:13px; }
    @media (max-width:800px) { .layout { grid-template-columns:1fr; } .depts { display:none; } .dept-select { display:block; } }
  </style>
</head>
<body>
<div class="topbar">
  <span class="brand">OFC ERP &nbsp;|&nbsp; Mobile App Access</span>
  <a href="<%= ctx %>/home"><i class="fa-solid fa-arrow-left"></i> Back to ERP</a>
</div>
<main>
  <h1><i class="fa-brands fa-android"></i> Android App Access</h1>
  <p class="subtitle">Choose a department, then switch app options on or off for each role. Switches marked
    <i>default</i> follow the Default settings. Approvals still follow the normal rules (Global / Incharge / Admin).</p>

  <% if (msg != null) { %><div class="msg <%= esc(msgType) %>"><%= esc(msg) %></div><% } %>

  <form method="post" action="<%= ctx %>/mobile-access" id="accessForm">
    <input type="hidden" name="csrfToken" value="<%= esc(request.getAttribute("csrfToken")) %>">
    <input type="hidden" name="rowCount" value="<%= rows.size() %>">

    <select class="dept-select" id="deptSelect">
      <option value="default">Default (all departments)</option>
      <% for (String d : byDept.keySet()) { %><option value="<%= esc(d) %>"><%= esc(d) %></option><% } %>
    </select>

    <div class="layout">
      <nav class="depts">
        <button type="button" class="dept-btn default active" data-dept="default"><span><i class="fa-solid fa-globe"></i>&nbsp; Default (all departments)</span></button>
        <% for (Map.Entry<String, List<Integer>> e : byDept.entrySet()) { %>
          <button type="button" class="dept-btn" data-dept="<%= esc(e.getKey()) %>"><span><%= esc(e.getKey()) %></span><span class="n"><%= e.getValue().size() %></span></button>
        <% } %>
      </nav>

      <div>
      <%-- one panel per department; only the selected one is shown --%>
      <%
        List<String> panelKeys = new ArrayList<>();
        panelKeys.add("default");
        panelKeys.addAll(byDept.keySet());
        for (String pk : panelKeys) {
            boolean isDefault = "default".equals(pk);
            List<Integer> idxs = isDefault ? (defaultIndex >= 0 ? Collections.singletonList(defaultIndex) : Collections.<Integer>emptyList()) : byDept.get(pk);
      %>
        <section class="panel" data-panel="<%= esc(pk) %>" <%= isDefault ? "" : "hidden" %>>
          <div class="panel-title"><%= isDefault ? "Default for everyone" : esc(pk) %></div>
          <div class="panel-sub"><%= isDefault ? "Applies to every role and department unless a role card says otherwise." : "Roles in this department. Changes apply only to that role in " + esc(pk) + "." %></div>
          <% if (idxs.isEmpty()) { %><div class="empty">No users in this department.</div><% } %>
          <div class="cards">
          <% for (int i : idxs) {
                 String[] r = rows.get(i);
                 boolean loginOn = true;
          %>
            <div class="card" data-row="<%= i %>">
              <input type="hidden" name="role_<%= i %>" value="<%= esc(r[0]) %>">
              <input type="hidden" name="dept_<%= i %>" value="<%= esc(r[1]) %>">
              <div class="card-head">
                <div class="role"><%= isDefault ? "Everyone" : esc(r[0]) %><small><%= isDefault ? "All roles, all departments" : esc(r[1]) %></small></div>
                <button type="button" class="reset" title="Remove this role's own settings">Reset to default</button>
              </div>
              <% for (int f = 0; f < features.size(); f++) {
                     String feat = features.get(f);
                     Boolean ex = MobileAccessDAO.explicit(rules, r[0], r[1], feat);
                     boolean inh = MobileAccessDAO.inherited(rules, r[0], r[1], feat);
                     boolean eff = ex != null ? ex : inh;
                     if (f == 0) loginOn = eff;
                     String state = ex == null ? "inherit" : (ex ? "on" : "off");
              %>
                <div class="opt">
                  <span class="label"><i class="fa-solid <%= icons[f] %>"></i><%= esc(MobileAccessDAO.FEATURES.get(feat)) %><span class="tag"><%= ex == null ? "default" : "" %></span></span>
                  <label class="switch">
                    <input type="checkbox" <%= eff ? "checked" : "" %> data-inherited="<%= inh ? "on" : "off" %>" data-feature-index="<%= f %>">
                    <span class="slider"></span>
                  </label>
                  <input type="hidden" class="val" name="v_<%= i %>_<%= f %>" value="<%= state %>" data-initial="<%= state %>">
                </div>
              <% } %>
            </div>
          <% } %>
          </div>
        </section>
      <% } %>
      </div>
    </div>

    <div class="savebar">
      <span class="changed-count" id="changed"></span>
      <button class="save" type="submit" id="saveBtn" disabled><i class="fa-solid fa-floppy-disk"></i> Save Changes</button>
    </div>
  </form>
</main>
<script>
  (function () {
    var form = document.getElementById('accessForm'), changed = document.getElementById('changed'),
        saveBtn = document.getElementById('saveBtn'), dirty = false;

    function refresh() {
      var n = 0;
      form.querySelectorAll('.card').forEach(function (card) {
        var opts = card.querySelectorAll('.opt');
        opts.forEach(function (opt) {
          var val = opt.querySelector('.val'), isChanged = val.value !== val.dataset.initial;
          opt.classList.toggle('changed', isChanged);
          opt.querySelector('.tag').textContent = val.value === 'inherit' ? 'default' : '';
          if (isChanged) n++;
        });
        card.classList.toggle('blocked', !opts[0].querySelector('input[type=checkbox]').checked);
      });
      dirty = n > 0;
      saveBtn.disabled = !dirty;
      changed.textContent = n ? n + (n === 1 ? ' change' : ' changes') + ' not saved' : '';
    }

    // Flip a switch -> explicit On/Off for that role (back to "default" if it matches the default again)
    form.addEventListener('change', function (e) {
      if (e.target.type !== 'checkbox') return;
      var val = e.target.closest('.opt').querySelector('.val');
      var want = e.target.checked ? 'on' : 'off';
      val.value = (val.dataset.initial === 'inherit' && want === e.target.dataset.inherited) ? 'inherit' : want;
      refresh();
    });

    // Reset a role card to the default settings
    form.querySelectorAll('.reset').forEach(function (btn) {
      btn.addEventListener('click', function () {
        btn.closest('.card').querySelectorAll('.opt').forEach(function (opt) {
          var cb = opt.querySelector('input[type=checkbox]');
          opt.querySelector('.val').value = 'inherit';
          cb.checked = cb.dataset.inherited === 'on';
        });
        refresh();
      });
    });

    // Department navigation
    function showDept(d) {
      form.querySelectorAll('.panel').forEach(function (p) { p.hidden = p.dataset.panel !== d; });
      form.querySelectorAll('.dept-btn').forEach(function (b) { b.classList.toggle('active', b.dataset.dept === d); });
      document.getElementById('deptSelect').value = d;
      try { sessionStorage.setItem('mobileAccessDept', d); } catch (x) { }
    }
    form.querySelectorAll('.dept-btn').forEach(function (b) { b.addEventListener('click', function () { showDept(b.dataset.dept); }); });
    document.getElementById('deptSelect').addEventListener('change', function () { showDept(this.value); });
    try { var last = sessionStorage.getItem('mobileAccessDept'); if (last && form.querySelector('[data-panel="' + CSS.escape(last) + '"]')) showDept(last); } catch (x) { }

    // Send ONLY changed switches; untouched roles are not updated
    form.addEventListener('submit', function (e) {
      var any = false;
      form.querySelectorAll('.card').forEach(function (card) {
        var rowChanged = false;
        card.querySelectorAll('.val').forEach(function (v) {
          if (v.value === v.dataset.initial) v.disabled = true; else { rowChanged = true; any = true; }
        });
        card.querySelectorAll('input[name^=role_], input[name^=dept_]').forEach(function (h) { h.disabled = !rowChanged; });
      });
      if (!any) { e.preventDefault(); return; }
      dirty = false;
    });
    window.addEventListener('beforeunload', function (e) { if (dirty) { e.preventDefault(); e.returnValue = ''; } });
    refresh();
  })();
</script>
</body>
</html>
