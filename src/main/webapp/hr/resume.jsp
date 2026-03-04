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
<title>Admin Dashboard | Candidate Management</title>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
:root{
--primary:#2563eb;
--bg:#f8fafc;
--text:#0f172a;
--border:#e2e8f0;
/* Solid Professional Status Colors */
--status-yes-bg: #dcfce7;
--status-yes-text: #166534;
--status-no-bg: #fee2e2;
--status-no-text: #991b1b;
--status-hold-bg: #fef9c3;
--status-hold-text: #854d0e;
}

body{
font-family:'Inter',sans-serif;
background:var(--bg);
margin:0;
padding:25px;
color:var(--text);
}

.wrapper{max-width:1400px;margin:auto;}

.post-container{margin-bottom:45px;}

.post-title{
display:flex;
align-items:center;
gap:12px;
font-size:20px;
font-weight:700;
margin-bottom:20px;
color: #334155;
}

.card{
background:#fff;
border-radius:12px;
box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
overflow:hidden;
border: 1px solid var(--border);
}

table{width:100%;border-collapse:collapse;}

th{
background:#f1f5f9;
padding:16px;
font-size:12px;
text-transform:uppercase;
color:#475569;
border-bottom:1px solid var(--border);
letter-spacing:0.05em;
text-align: left;
}

td{
padding:14px 16px;
border-bottom:1px solid var(--border);
font-size:14px;
vertical-align:middle;
}

/* Row Highlighting for Shortlisted */
tr.is-shortlisted { background-color: #f0fdf4; }
tr:hover{ background-color: #f1f5f9 !important; }

.sl-no{ width:50px; text-align:center; font-weight:600; color:#64748b; }

/* IMPROVISED BADGES */
.status-pill {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 4px 12px;
    border-radius: 9999px;
    font-size: 12px;
    font-weight: 600;
    white-space: nowrap;
}

.pill-yes { background: var(--status-yes-bg); color: var(--status-yes-text); border: 1px solid #bbf7d0; }
.pill-no { background: var(--status-no-bg); color: var(--status-no-text); border: 1px solid #fecaca; }
.pill-hold { background: var(--status-hold-bg); color: var(--status-hold-text); border: 1px solid #fef08a; }
.pill-default { background: #f1f5f9; color: #475569; border: 1px solid var(--border); }

.btn-edit{
background:#fff;
border:1px solid var(--border);
padding:6px 12px;
border-radius:6px;
font-weight:600;
color: var(--primary);
cursor:pointer;
transition: all 0.2s;
display: inline-flex;
align-items: center;
gap: 5px;
}

.btn-edit:hover{ background: var(--primary); color: #fff; }

/* Modal Styling */
.modal-overlay{
position:fixed;
inset:0;
background:rgba(15,23,42,0.6);
display:none;
align-items:center;
justify-content:center;
z-index:1000;
backdrop-filter: blur(8px);
}

.modal-content{
background:#fff;
width:90%;
max-width:800px;
border-radius:16px;
max-height:90vh;
overflow:hidden;
display:flex;
flex-direction:column;
}

.modal-header{
padding:20px 25px;
border-bottom:1px solid var(--border);
display:flex;
justify-content:space-between;
align-items:center;
background:#fff;
}

.modal-body{padding:25px; overflow-y:auto;}

.grid-form{ display:grid; grid-template-columns: 1fr 1fr; gap:20px; }

.section-divider{
grid-column: span 2;
font-size: 11px;
letter-spacing: 1px;
text-transform: uppercase;
color: var(--primary);
font-weight: 700;
border-bottom: 2px solid #eff6ff;
padding-bottom: 5px;
margin-top: 10px;
}

.form-group label { display:block; font-size:12px; font-weight:600; margin-bottom:6px; color:#64748b; }
.form-control { width:100%; padding:10px; border:1px solid var(--border); border-radius:8px; font-size:14px; box-sizing:border-box;}
.form-control:focus { outline:none; border-color:var(--primary); ring: 2px solid #dbeafe; }

.footer-actions { 
    padding: 20px 25px; 
    border-top: 1px solid var(--border); 
    display:flex; 
    justify-content:flex-end; 
    gap:12px; 
    background:#f8fafc;
}
</style>
</head>

<body>

<div class="wrapper">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:30px;">
        <h2 style="margin:0;">Candidate Database</h2>
        <div style="color:#64748b; font-size:14px;"><i class="fas fa-calendar-alt"></i> March 2026</div>
    </div>

<%
List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
Set<String> uniquePosts = new TreeSet<>(); 

if(rawList != null && !rawList.isEmpty()){
    Map<String,List<Map<String,String>>> groupedData = new LinkedHashMap<>();
    for(Map<String,String> row : rawList){
        String post = row.get("post_applied_for");
        if(post == null || post.trim().isEmpty()) post = "General";
        uniquePosts.add(post); 
        groupedData.computeIfAbsent(post, k -> new ArrayList<>()).add(row);
    }

    for(String postName : groupedData.keySet()){
        List<Map<String,String>> candidates = groupedData.get(postName);
%>

<div class="post-container">
    <div class="post-title">
        <div style="width:35px; height:35px; background:var(--primary); color:#fff; border-radius:8px; display:flex; align-items:center; justify-content:center;">
            <i class="fas fa-briefcase"></i>
        </div>
        <%=postName.toUpperCase()%>
        <span style="font-size:14px; color:#94a3b8; font-weight:400;">(<%=candidates.size()%>)</span>
    </div>

    <div class="card">
        <table>
            <thead>
                <tr>
                    <th class="sl-no">#</th>
                    <th>Candidate Name</th>
                    <th>Mobile</th>
                    <th>Qualification</th>
                    <th>Exp.</th>
                    <th>Shortlisted</th>
                    <th style="text-align:center;">Action</th>
                </tr>
            </thead>
            <tbody>
            <%
            int serial=1;
            for(Map<String,String> c : candidates){
                String status = String.valueOf(c.get("shortlisted")).trim();
                String rowClass = status.equalsIgnoreCase("Yes") ? "is-shortlisted" : "";
                
                String pillClass = "pill-default";
                String icon = "fa-clock";
                String displayStatus = "Pending";

                if(status.equalsIgnoreCase("Yes")) {
                    pillClass = "pill-yes"; icon = "fa-check-circle"; displayStatus = "Shortlisted";
                } else if(status.equalsIgnoreCase("No")) {
                    pillClass = "pill-no"; icon = "fa-times-circle"; displayStatus = "Rejected";
                } else if(status.equalsIgnoreCase("On Hold")) {
                    pillClass = "pill-hold"; icon = "fa-pause-circle"; displayStatus = "On Hold";
                }
            %>
            <tr class="<%=rowClass%>">
                <td class="sl-no"><%=serial++%></td>
                <td><strong><%=c.get("name")%></strong></td>
                <td><%=c.get("mobile_no")%></td>
                <td><%=c.get("qualification")%></td>
                <td><%=c.get("total_experience")%> Yrs</td>
                <td>
                    <span class="status-pill <%=pillClass%>">
                        <i class="fas <%=icon%>"></i> <%=displayStatus%>
                    </span>
                </td>
                <td style="text-align:center;">
                    <button class="btn-edit" onclick='openModal(<%=new Gson().toJson(c)%>)'>
                        <i class="fas fa-external-link-alt"></i> Review
                    </button>
                </td>
            </tr>
            <% } %>
            </tbody>
        </table>
    </div>
</div>

<% } } %>
</div>

<div class="modal-overlay" id="editModal">
    <div class="modal-content">
        <div class="modal-header">
            <h3 style="margin:0;"><i class="fas fa-user-tie"></i> Candidate Profile Review</h3>
            <button onclick="closeModal()" style="background:none; border:none; font-size:24px; cursor:pointer; color:#94a3b8;">&times;</button>
        </div>
        
        <form action="resume" method="post">
            <div class="modal-body">
                <input type="hidden" name="sl_no" id="f_sl_no">
                
                <div class="grid-form">
                    <div class="section-divider">Basic Information</div>
                    <div class="form-group">
                        <label>Full Name</label>
                        <input type="text" name="name" id="f_name" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Contact Number</label>
                        <input type="text" name="mobile_no" id="f_mobile_no" class="form-control">
                    </div>

                    <div class="section-divider">Professional Background</div>
                    <div class="form-group">
                        <label>Applying For</label>
                        <select name="post_applied_for" id="f_post_applied_for" class="form-control">
                            <% for(String p : uniquePosts) { %>
                                <option value="<%= p %>"><%= p %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Total Experience (Years)</label>
                        <input type="text" name="total_experience" id="f_total_experience" class="form-control">
                    </div>

                    <div class="section-divider">HR Decision Panel</div>
                    <div class="form-group">
                        <label>Shortlist Status</label>
                        <select name="shortlisted" id="f_shortlisted" class="form-control" style="font-weight:700;">
                            <option value="Pending">🕒 Pending</option>
                            <option value="Yes" style="color:green;">✅ Yes, Shortlist</option>
                            <option value="No" style="color:red;">❌ No, Reject</option>
                            <option value="On Hold">⏸️ On Hold</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Interview Stage</label>
                        <input type="text" name="interview_status" id="f_interview_status" class="form-control" placeholder="e.g. Technical Round 1">
                    </div>
                    
                    <div class="form-group" style="grid-column: span 2;">
                        <label>HR Remarks</label>
                        <textarea name="remarks" id="f_remarks" class="form-control" rows="3"></textarea>
                    </div>
                </div>
            </div>

            <div class="footer-actions">
                <button type="button" class="btn-edit" style="color:#64748b;" onclick="closeModal()">Discard Changes</button>
                <button type="submit" class="btn-edit" style="background:var(--primary); color:#fff; border:none; padding:10px 25px;">Update Profile</button>
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
    document.body.style.overflow = 'hidden';
}

function closeModal(){
    document.getElementById('editModal').style.display = 'none';
    document.body.style.overflow = 'auto';
}

window.onclick = function(e) {
    if (e.target.classList.contains('modal-overlay')) closeModal();
}
</script>

</body>
</html>