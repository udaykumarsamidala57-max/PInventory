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
--bg:#f1f5f9;
--text:#1e293b;
--border:#e2e8f0;
--success:#10b981;
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
gap:10px;
font-size:18px;
font-weight:700;
margin-bottom:15px;
padding-left:8px;
border-left:5px solid var(--primary);
}

.card{
background:#fff;
border-radius:14px;
box-shadow:0 8px 20px rgba(0,0,0,0.05);
overflow:hidden;
}

table{width:100%;border-collapse:collapse;}

th{
background:#f8fafc;
padding:14px;
font-size:11px;
text-transform:uppercase;
color:#64748b;
border-bottom:2px solid var(--border);
letter-spacing:0.05em;
}

td{
padding:12px;
border-bottom:1px solid var(--border);
font-size:13px;
vertical-align:middle;
}

tr:hover{background:#f8fafc;}

.sl-no{
width:60px;
text-align:center;
font-weight:700;
color:#94a3b8;
}

.badge{
padding:4px 8px;
border-radius:4px;
font-size:11px;
font-weight:700;
text-transform:uppercase;
}

.badge-blue{
background:#eff6ff;
color:#2563eb;
border:1px solid #bfdbfe;
}

.btn{
padding:8px 14px;
border-radius:6px;
cursor:pointer;
border:none;
font-weight:600;
font-size:12px;
}

.btn-edit{
background:#fff;
border:1px solid var(--border);
}

.modal-overlay{
position:fixed;
inset:0;
background:rgba(15,23,42,0.7);
display:none;
align-items:center;
justify-content:center;
z-index:1000;
}

.modal-content{
background:#fff;
width:95%;
max-width:850px;
border-radius:16px;
max-height:90vh;
overflow-y:auto;
}

.modal-header{
padding:20px 25px;
border-bottom:1px solid var(--border);
display:flex;
justify-content:space-between;
align-items:center;
background:#f8fafc;
}

.modal-body{padding:25px;}

.grid-form{
display:grid;
grid-template-columns:1fr 1fr;
gap:18px;
}

.full{grid-column:span 2;}

.form-group label{
display:block;
font-size:12px;
font-weight:600;
margin-bottom:5px;
color:#64748b;
}

.form-control{
width:100%;
padding:8px;
border:1px solid var(--border);
border-radius:6px;
font-size:14px;
}

.section-divider{
grid-column:span 2;
font-weight:800;
font-size:12px;
text-transform:uppercase;
margin-top:15px;
padding-bottom:5px;
border-bottom:1px solid var(--border);
}

.footer-actions{
margin-top:25px;
display:flex;
justify-content:flex-end;
gap:10px;
padding-top:15px;
border-top:1px solid var(--border);
}
</style>
</head>

<body>

<div class="wrapper">

<h2 style="margin-bottom:30px;">Candidate Database</h2>

<%
List<Map<String,String>> rawList =
(List<Map<String,String>>) request.getAttribute("resumeList");

if(rawList!=null && !rawList.isEmpty()){

Map<String,List<Map<String,String>>> groupedData =
new LinkedHashMap<>();

for(Map<String,String> row : rawList){
String post=row.get("post_applied_for");
if(post==null||post.trim().isEmpty())
post="General / Unspecified";

groupedData.computeIfAbsent(post,k->new ArrayList<>()).add(row);
}

int globalSerial=1;

for(String postName:groupedData.keySet()){
List<Map<String,String>> candidates=groupedData.get(postName);
%>

<div class="post-container">
<div class="post-title">
<i class="fas fa-briefcase"></i>
<%=postName.toUpperCase()%>
<span style="color:#94a3b8;font-weight:400;">
(<%=candidates.size()%> Candidates)
</span>
</div>

<div class="card">
<table>
<thead>
<tr>
<th class="sl-no">SL</th>
<th>Name</th>
<th>Mobile</th>
<th>Qualification</th>
<th>Experience</th>
<th>Status</th>
<th style="text-align:center;">Action</th>
</tr>
</thead>

<tbody>

<%
int serial=1;
for(Map<String,String> candidate:candidates){
%>

<tr>
<td class="sl-no"><%=serial++%></td>

<td><strong><%=String.valueOf(candidate.get("name"))%></strong></td>

<td><%=String.valueOf(candidate.get("mobile_no"))%></td>

<td><%=String.valueOf(candidate.get("qualification"))%></td>

<td><%=String.valueOf(candidate.get("total_experience"))%> Years</td>

<td>
<span class="badge badge-blue">
<%=String.valueOf(candidate.get("call_status"))%>
</span>
</td>

<td style="text-align:center;">
<button class="btn btn-edit"
onclick='openModal(<%=new Gson().toJson(candidate)%>)'>
<i class="fas fa-user-edit"></i> View
</button>
</td>
</tr>

<% } %>

</tbody>
</table>
</div>
</div>

<% } } else { %>

<div class="card" style="padding:50px;text-align:center;">
<h3>No Candidates Found</h3>
</div>

<% } %>

</div>


<!-- MODAL -->

<div class="modal-overlay" id="editModal">
<div class="modal-content">

<div class="modal-header">
<h3><i class="fas fa-id-card"></i> Candidate Profile</h3>
<button onclick="closeModal()" 
style="background:none;border:none;font-size:20px;">&times;</button>
</div>

<div class="modal-body">
<form action="resume" method="post" class="grid-form">

<input type="hidden" name="sl_no" id="f_sl_no">

<div class="section-divider">Personal Details</div>

<div class="form-group">
<label>Full Name</label>
<input type="text" name="name" id="f_name" class="form-control">
</div>

<div class="form-group">
<label>Mobile</label>
<input type="text" name="mobile_no" id="f_mobile_no" class="form-control">
</div>

<div class="form-group">
<label>Gender</label>
<input type="text" name="gender" id="f_gender" class="form-control">
</div>

<div class="form-group">
<label>DOB</label>
<input type="text" name="date_of_birth" id="f_date_of_birth" class="form-control">
</div>

<div class="section-divider">Academic & Experience</div>

<div class="form-group">
<label>Qualification</label>
<input type="text" name="qualification" id="f_qualification" class="form-control">
</div>

<div class="form-group">
<label>Experience</label>
<input type="text" name="total_experience" id="f_total_experience" class="form-control">
</div>

<div class="form-group">
<label>Post Applied</label>
<input type="text" name="post_applied_for" id="f_post_applied_for" class="form-control">
</div>

<div class="form-group">
<label>Expected Salary</label>
<input type="text" name="expected_salary" id="f_expected_salary" class="form-control">
</div>

<div class="section-divider">Status</div>

<div class="form-group">
<label>Call Status</label>
<input type="text" name="call_status" id="f_call_status" class="form-control">
</div>

<div class="form-group">
<label>Demo Status</label>
<input type="text" name="demo_status" id="f_demo_status" class="form-control">
</div>

<div class="footer-actions full">
<button type="button" class="btn"
onclick="closeModal()" style="background:#f1f5f9;">
Cancel
</button>
<button type="submit" class="btn"
style="background:var(--primary);color:#fff;">
Save Changes
</button>
</div>

</form>
</div>
</div>
</div>


<script>
function openModal(data){
for(let key in data){
let element=document.getElementById('f_'+key);
if(element) element.value=data[key]||'';
}
document.getElementById('editModal').style.display='flex';
document.body.style.overflow='hidden';
}

function closeModal(){
document.getElementById('editModal').style.display='none';
document.body.style.overflow='auto';
}
</script>

</body>
</html>