<%@ page import="java.util.*" %>
<%@ page import="com.google.gson.Gson" %>

<%
HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}

Gson gson = new Gson();
%>

<%!
public String safe(Object o){
    return (o==null) ? "" : o.toString();
}
%>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">
<title>RecruitPro | Recruitment Dashboard</title>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Recruitment.css?v=16">

<style>

body{
font-family:'Inter',sans-serif;
background:#f4f6fb;
margin:0;
color:#1e293b;
}

/* KPI GRID */

.kpi-grid{
display:grid;
grid-template-columns:repeat(auto-fit,minmax(220px,1fr));
gap:20px;
margin-bottom:30px;
}

.kpi-card{
background:white;
padding:22px;
border-radius:12px;
box-shadow:0 3px 12px rgba(0,0,0,0.05);
}

.kpi-card h3{
font-size:14px;
color:#64748b;
margin:0;
}

.kpi-number{
font-size:32px;
font-weight:800;
margin-top:10px;
}

.kpi-number.success{color:#16a34a;}
.kpi-number.primary{color:#2563eb;}
.kpi-number.hired{color:#9333ea;}

/* FUNNEL */

.funnel{
background:white;
padding:18px;
border-radius:10px;
margin-bottom:30px;
box-shadow:0 2px 8px rgba(0,0,0,0.05);
}

.progress{
height:10px;
background:#e2e8f0;
border-radius:8px;
overflow:hidden;
margin-top:10px;
}

.progress div{
height:100%;
background:#4f46e5;
}

/* SECTION */

.section{
margin-top:40px;
}

.section-header{
display:flex;
justify-content:space-between;
align-items:center;
}

.section-header h1{
font-size:20px;
margin:0;
}

.section-stats{
display:flex;
gap:20px;
font-size:13px;
color:#64748b;
}

/* TABLE */

.table-wrapper{
margin-top:15px;
overflow-x:auto;
}

table{
width:100%;
border-collapse:collapse;
background:white;
border-radius:10px;
overflow:hidden;
}

th{
background:#f8fafc;
font-size:12px;
text-transform:uppercase;
letter-spacing:.4px;
color:#64748b;
padding:12px;
}

td{
padding:12px;
border-top:1px solid #f1f5f9;
font-size:14px;
vertical-align:top;
}

td b{
font-weight:600;
}

.badge{
display:inline-block;
padding:4px 8px;
border-radius:6px;
font-size:12px;
font-weight:600;
}

.badge.success{background:#dcfce7;color:#166534;}
.badge.primary{background:#dbeafe;color:#1d4ed8;}
.badge.warning{background:#fef3c7;color:#92400e;}
.badge.danger{background:#fee2e2;color:#991b1b;}

/* ROW STATES */

.hired-row{
background:#faf5ff;
}

/* BUTTON */

.btn-primary{
background:#4f46e5;
color:white;
border:none;
padding:6px 12px;
border-radius:6px;
cursor:pointer;
font-size:12px;
}

.btn-primary:hover{
background:#4338ca;
}

/* MODAL */

.modal{
display:none;
position:fixed;
top:0;
left:0;
width:100%;
height:100%;
background:rgba(0,0,0,0.35);
justify-content:center;
align-items:center;
z-index:999;
}

.modal-content{
background:white;
width:900px;
max-height:90vh;
overflow-y:auto;
padding:25px;
border-radius:10px;
}

.modal-title{
font-size:20px;
font-weight:700;
margin-bottom:15px;
}

.modal-form h4{
margin-top:20px;
font-size:14px;
color:#4f46e5;
}

.form-row{
display:flex;
gap:12px;
margin-top:10px;
}

input,select,textarea{
width:100%;
padding:8px;
border:1px solid #e2e8f0;
border-radius:6px;
font-size:13px;
}

textarea{
min-height:80px;
}

.modal-buttons{
margin-top:20px;
display:flex;
justify-content:flex-end;
gap:10px;
}

.btn-light{
background:#e2e8f0;
border:none;
padding:8px 14px;
border-radius:6px;
cursor:pointer;
}

</style>
</head>

<body>

<%@ include file="header.jsp" %>

<div class="navbar">
<div class="logo">Recruitment 2026 - 27</div>
<div><span class="status-dot"></span>System Active</div>
</div>

<div class="main-container">

<%
List<Map<String,String>> rawList=(List<Map<String,String>>)request.getAttribute("resumeList");

int total=0;
int shortlisted=0;
int demoSelected=0;
int hired=0;

if(rawList!=null){

total=rawList.size();

for(Map<String,String> c:rawList){

if("Yes".equalsIgnoreCase(c.get("shortlisted"))) shortlisted++;

if("Selected".equalsIgnoreCase(c.get("demo_status"))) demoSelected++;

if("Yes".equalsIgnoreCase(c.get("Hired_status"))) hired++;

}

}
%>

<!-- KPI DASHBOARD -->

<div class="kpi-grid">

<div class="kpi-card">
<h3>Total Applications</h3>
<div class="kpi-number"><%=total%></div>
</div>

<div class="kpi-card">
<h3>Shortlisted</h3>
<div class="kpi-number success"><%=shortlisted%></div>
</div>

<div class="kpi-card">
<h3>Demo Selected</h3>
<div class="kpi-number primary"><%=demoSelected%></div>
</div>

<div class="kpi-card">
<h3>Hired</h3>
<div class="kpi-number hired"><%=hired%></div>
</div>

</div>

<!-- FUNNEL -->

<div class="funnel">

<b>Recruitment Funnel</b>

<div class="progress">

<%
int percent = total==0 ? 0 : (hired*100/total);
%>

<div style="width:<%=percent%>%"></div>

</div>

<small><%=percent%>% conversion to hired</small>

</div>

<%

if(rawList!=null && !rawList.isEmpty()){

Map<String,List<Map<String,String>>> grouped=new LinkedHashMap<>();

for(Map<String,String> row:rawList){

String post=row.get("post_applied_for");

if(post==null||post.trim().isEmpty()) post="General";

grouped.computeIfAbsent(post,k->new ArrayList<>()).add(row);

}

for(String post:grouped.keySet()){

List<Map<String,String>> candidates=grouped.get(post);

%>

<div class="section">

<div class="section-header">

<h1><%=post%></h1>

<div class="section-stats">

<span>Total : <%=candidates.size()%></span>

</div>

</div>

<div class="table-wrapper">

<table>

<thead>

<tr>
<th>Name</th>
<th>Qualification</th>
<th>Experience</th>
<th>Shortlist</th>
<th>Call</th>
<th>Demo</th>
<th>Interview</th>
<th>Hired</th>
<th>Remarks</th>
<th>Action</th>
</tr>

</thead>

<tbody>

<%

for(Map<String,String> c:candidates){

String rowClass="Yes".equalsIgnoreCase(c.get("Hired_status"))?"hired-row":"";

String json=gson.toJson(c)
.replace("&","&amp;")
.replace("\"","&quot;")
.replace("<","&lt;")
.replace(">","&gt;");

%>

<tr class="<%=rowClass%>">

<td>
<b><%=safe(c.get("name"))%></b><br>
<small><%=safe(c.get("mobile_no"))%></small>
</td>

<td>
<%=safe(c.get("qualification"))%><br>
<small><%=safe(c.get("specialization"))%></small>
</td>

<td><%=safe(c.get("total_experience"))%> Yrs</td>

<td>

<%

String s=c.get("shortlisted");

if("Yes".equalsIgnoreCase(s)){

%>

<span class="badge success">Shortlisted</span>

<%

}else if("No".equalsIgnoreCase(s)){

%>

<span class="badge danger">Rejected</span>

<%

}else{

%>

<span class="badge warning">Review</span>

<% } %>

</td>

<td><%=safe(c.get("call_status"))%></td>

<td>

<span class="badge primary">

<%=safe(c.get("demo_status")).isEmpty()?"Pending":safe(c.get("demo_status"))%>

</span>

</td>

<td><%=safe(c.get("interview_status"))%></td>

<td>

<%

if("Yes".equalsIgnoreCase(c.get("Hired_status"))){

%>

<span class="badge success">Hired</span>

<%

}else{

%>

<span class="badge warning">Pending</span>

<%

}

%>

</td>

<td><%=safe(c.get("remarks"))%></td>

<td>

<button class="btn-primary reviewBtn"
data-candidate="<%=json%>">

Review

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

<!-- MODAL -->

<div class="modal" id="editModal">

<div class="modal-content">

<div class="modal-title">Update Candidate Full Details</div>

<form action="resume" method="post" class="modal-form">

<input type="hidden" name="sl_no" id="f_sl_no">

<h4>Basic Information</h4>

<div class="form-row">
<input type="text" name="name" id="f_name" placeholder="Full Name">
<input type="text" name="mobile_no" id="f_mobile_no" placeholder="Mobile">
</div>

<h4>Hired Status</h4>

<select name="Hired_status" id="f_Hired_status">
<option value="No">Not Hired</option>
<option value="Yes">Hired</option>
</select>

<h4>Remarks</h4>

<textarea name="remarks" id="f_remarks"></textarea>

<div class="modal-buttons">

<button type="button" onclick="closeModal()" class="btn-light">Cancel</button>

<button type="submit" class="btn-primary">Update Full Detail</button>

</div>

</form>

</div>

</div>

<script>

document.querySelectorAll(".reviewBtn").forEach(btn=>{

btn.addEventListener("click",function(){

let data=JSON.parse(this.dataset.candidate);

Object.keys(data).forEach(key=>{

let el=document.getElementById("f_"+key);

if(el) el.value=data[key]||"";

});

document.getElementById("editModal").style.display="flex";

});

});

function closeModal(){

document.getElementById("editModal").style.display="none";

}

</script>

</body>
</html>