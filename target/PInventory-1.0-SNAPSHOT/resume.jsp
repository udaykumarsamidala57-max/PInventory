<%@ page import="java.util.*" %>
<%@ page import="com.google.gson.Gson" %>
<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Management Console | Candidate Database</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --primary: #1e293b; /* Dark Navy Classic */
            --accent: #2563eb;
            --bg: #f8fafc;
            --border: #e2e8f0;
        }
        body { font-family: 'Inter', sans-serif; background: var(--bg); margin: 0; display: flex; color: #334155; }
        
        /* Sidebar Navigation */
        .side-nav { width: 260px; height: 100vh; background: #fff; border-right: 1px solid var(--border); position: fixed; padding: 20px; overflow-y: auto; }
        .side-nav h3 { font-size: 12px; text-transform: uppercase; color: #94a3b8; letter-spacing: 1px; margin-bottom: 15px; }
        .nav-item { display: block; padding: 10px; color: #475569; text-decoration: none; border-radius: 6px; font-size: 13px; margin-bottom: 5px; transition: 0.2s; }
        .nav-item:hover { background: #f1f5f9; color: var(--accent); }
        .nav-item i { margin-right: 8px; width: 16px; }

        /* Main Content */
        .main-content { margin-left: 260px; flex: 1; padding: 40px; }
        .header-strip { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; }
        
        .post-card { background: #fff; border: 1px solid var(--border); border-radius: 8px; margin-bottom: 30px; box-shadow: 0 1px 3px rgba(0,0,0,0.02); }
        .post-header { padding: 15px 20px; background: #fff; border-bottom: 1px solid var(--border); border-radius: 8px 8px 0 0; display: flex; justify-content: space-between; align-items: center; }
        .post-header h2 { font-size: 16px; margin: 0; color: var(--primary); }

        table { width: 100%; border-collapse: collapse; table-layout: fixed; }
        th { background: #f8fafc; text-align: left; padding: 12px 20px; font-size: 11px; text-transform: uppercase; color: #64748b; border-bottom: 1px solid var(--border); position: sticky; top: 0; }
        td { padding: 10px 20px; border-bottom: 1px solid #f1f5f9; font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        tr:nth-child(even) { background-color: #fafafa; }
        tr:hover { background-color: #f1f5f9; }

        /* Status Badges - Classic Colors */
        .badge { padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; }
        .status-called { background: #dcfce7; color: #166534; }
        .status-pending { background: #fef9c3; color: #854d0e; }
        .status-rejected { background: #fee2e2; color: #991b1b; }

        .btn-view { color: var(--accent); background: none; border: none; font-weight: 600; cursor: pointer; padding: 0; }
        .btn-view:hover { text-decoration: underline; }

        /* Modal Refinement */
        .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.4); display: none; align-items: center; justify-content: center; z-index: 1000; }
        .modal-content { background: #fff; width: 600px; border-radius: 12px; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); }
        .modal-header { padding: 20px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; }
        .modal-body { padding: 20px; display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
        .form-group.full { grid-column: span 2; }
        .form-group label { display: block; font-size: 11px; font-weight: 600; color: #94a3b8; text-transform: uppercase; margin-bottom: 4px; }
        .form-control { width: 100%; border: 1px solid var(--border); padding: 8px; border-radius: 4px; box-sizing: border-box; }
        .modal-footer { padding: 15px 20px; border-top: 1px solid var(--border); text-align: right; background: #f8fafc; border-radius: 0 0 12px 12px; }
        
        .save-btn { background: var(--accent); color: #fff; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; }
    </style>
</head>
<body>

<%
    List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
    Map<String, List<Map<String,String>>> groupedData = new LinkedHashMap<>();
    
    if(rawList != null) {
        for(Map<String,String> row : rawList) {
            String post = row.get("post_applied_for");
            if(post == null || post.trim().isEmpty()) post = "General";
            groupedData.computeIfAbsent(post, k -> new ArrayList<>()).add(row);
        }
    }
%>

<div class="side-nav">
    <div style="margin-bottom: 30px;">
        <h1 style="font-size: 18px; color: var(--accent);"><i class="fas fa-database"></i> Console</h1>
    </div>
    <h3>Post Categories</h3>
    <% for(String post : groupedData.keySet()) { %>
        <a href="#post-<%= post.hashCode() %>" class="nav-item">
            <i class="fas fa-tag"></i> <%= post %>
        </a>
    <% } %>
</div>

<div class="main-content">
    <div class="header-strip">
        <h2 style="font-size: 22px;">Candidate Database</h2>
        <div style="font-size: 13px; color: #64748b;">Total Groups: <%= groupedData.size() %></div>
    </div>

    <% for(String postName : groupedData.keySet()) { 
        List<Map<String,String>> candidates = groupedData.get(postName);
    %>
    <div class="post-card" id="post-<%= postName.hashCode() %>">
        <div class="post-header">
            <h2><%= postName %></h2>
            <span style="font-size: 12px; background: #f1f5f9; padding: 2px 10px; border-radius: 10px;"><%= candidates.size() %> entries</span>
        </div>
        <table>
            <thead>
                <tr>
                    <th style="width: 40px;">#</th>
                    <th>Full Name</th>
                    <th>Mobile</th>
                    <th>Qualification</th>
                    <th>Exp.</th>
                    <th>Status</th>
                    <th style="width: 80px;"></th>
                </tr>
            </thead>
            <tbody>
                <% int i = 1; for(Map<String,String> c : candidates) { 
                   String status = String.valueOf(c.get("call_status")).toLowerCase();
                   String statusClass = status.contains("call") ? "status-called" : (status.contains("rej") ? "status-rejected" : "status-pending");
                %>
                <tr>
                    <td style="color: #94a3b8;"><%= i++ %></td>
                    <td><strong><%= c.get("name") %></strong></td>
                    <td><%= c.get("mobile_no") %></td>
                    <td><%= c.get("qualification") %></td>
                    <td><%= c.get("total_experience") %>y</td>
                    <td><span class="badge <%= statusClass %>"><%= c.get("call_status") %></span></td>
                    <td>
                        <button class="btn-view" onclick='openModal(<%= new Gson().toJson(c) %>)'>Edit Profile</button>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</div>

<div class="modal-overlay" id="editModal">
    <div class="modal-content">
        <div class="modal-header">
            <h3 style="margin:0; font-size: 16px;"><i class="fas fa-user-circle"></i> Candidate File</h3>
            <button onclick="closeModal()" style="background:none; border:none; cursor:pointer; color:#94a3b8; font-size: 20px;">&times;</button>
        </div>
        <form action="resume" method="post">
            <div class="modal-body">
                <input type="hidden" name="sl_no" id="f_sl_no">
                <div class="form-group">
                    <label>Full Name</label>
                    <input type="text" name="name" id="f_name" class="form-control">
                </div>
                <div class="form-group">
                    <label>Mobile</label>
                    <input type="text" name="mobile_no" id="f_mobile_no" class="form-control">
                </div>
                <div class="form-group">
                    <label>Post Applied</label>
                    <input type="text" name="post_applied_for" id="f_post_applied_for" class="form-control">
                </div>
                <div class="form-group">
                    <label>Qualification</label>
                    <input type="text" name="qualification" id="f_qualification" class="form-control">
                </div>
                <div class="form-group">
                    <label>Call Status</label>
                    <input type="text" name="call_status" id="f_call_status" class="form-control">
                </div>
                <div class="form-group">
                    <label>Demo Status</label>
                    <input type="text" name="demo_status" id="f_demo_status" class="form-control">
                </div>
                <div class="form-group full">
                    <label>Expected Salary</label>
                    <input type="text" name="expected_salary" id="f_expected_salary" class="form-control">
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" onclick="closeModal()" style="background:none; border:none; color:#64748b; margin-right:15px; cursor:pointer;">Discard</button>
                <button type="submit" class="save-btn">Update Record</button>
            </div>
        </form>
    </div>
</div>

<script>
    function openModal(data){
        for(let key in data){
            let el = document.getElementById('f_'+key);
            if(el) el.value = data[key] || '';
        }
        document.getElementById('editModal').style.display = 'flex';
    }
    function closeModal(){
        document.getElementById('editModal').style.display = 'none';
    }
    // Close on click outside
    window.onclick = function(e) {
        if (e.target.className === 'modal-overlay') closeModal();
    }
</script>

</body>
</html>