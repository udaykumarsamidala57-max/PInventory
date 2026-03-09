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

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>RecruitPro | Recruitment Dashboard</title>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Recruitment.css?v=15">

<style>
/* MODAL */
.modal-content{
    width:900px;
    max-height:90vh;
    overflow-y:auto;
}
.modal-form h4{
    margin-top:20px;
    margin-bottom:10px;
    font-size:14px;
    color:#4f46e5;
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
    padding:20px;
    border-radius:10px;
    box-shadow:0 2px 8px rgba(0,0,0,0.06);
}
.kpi-number{
    font-size:32px;
    font-weight:700;
    margin-top:10px;
}
.kpi-number.success{color:#16a34a;}
.kpi-number.primary{color:#2563eb;}
.kpi-number.hired{color:#9333ea;}

/* POST ANALYTICS */
.section-stats{
    display:flex;
    gap:20px;
    font-size:13px;
    margin-top:5px;
    color:#64748b;
}

/* HIRED ROW */
.hired-row{
    background:#f5f3ff;
    font-weight:600;
}

/* TABLE STYLING */
.table-wrapper{
    overflow-x:auto;
    margin-top:20px;
}
table{
    width:100%;
    border-collapse:collapse;
    table-layout:fixed;
}
th, td{
    padding:12px 16px;
    text-align:left;
    vertical-align:top;
    word-wrap:break-word;
    border-bottom:1px solid #e5e7eb;
}
th{
    background:#f9fafb;
    font-weight:700;
    font-size:13px;
    color:#374151;
}
td b{
    font-weight:600;
    display:block;
}
.badge{
    display:inline-block;
    padding:3px 8px;
    border-radius:6px;
    font-size:12px;
    font-weight:700;
    text-align:center;
    white-space:nowrap;
}
.badge.success{background:#16a34a;color:white;}
.badge.primary{background:#2563eb;color:white;}
.badge.warning{background:#fbbf24;color:white;}
.badge.danger{background:#ef4444;color:white;}

/* COLUMN WIDTHS */
th.name, td.name{width:180px;}
th.qualification, td.qualification{width:200px;}
th.experience, td.experience{width:80px;}
th.shortlist, td.shortlist{width:120px;}
th.callstatus, td.callstatus{width:120px;}
th.demo, td.demo{width:120px;}
th.interview, td.interview{width:120px;}
th.hired, td.hired{width:100px;}
th.remarks, td.remarks{width:180px;}
th.action, td.action{width:100px; text-align:center;}

/* BUTTONS */
.btn-primary{
    padding:6px 12px;
    background:#4f46e5;
    color:white;
    border:none;
    border-radius:6px;
    cursor:pointer;
    font-size:12px;
}
.btn-primary:hover{
    background:#4338ca;
}

/* WRAP LONG TEXT */
td{
    word-break:break-word;
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
List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
int total=0, shortlisted=0, selected=0, hired=0;
if(rawList!=null){
    total = rawList.size();
    for(Map<String,String> c:rawList){
        if("Yes".equalsIgnoreCase(c.get("shortlisted"))) shortlisted++;
        if(c.get("demo_status")!=null && c.get("demo_status").equalsIgnoreCase("Selected")) selected++;
        if("Yes".equalsIgnoreCase(c.get("Hired_status"))) hired++;
    }
}
%>

<!-- KPI DASHBOARD -->
<div class="kpi-grid">
<div class="kpi-card"><h3>Total Applications</h3><div class="kpi-number"><%=total%></div></div>
<div class="kpi-card"><h3>Shortlisted</h3><div class="kpi-number success"><%=shortlisted%></div></div>
<div class="kpi-card"><h3>Selected in Demo</h3><div class="kpi-number primary"><%=selected%></div></div>
<div class="kpi-card"><h3>Hired Candidates</h3><div class="kpi-number hired"><%=hired%></div></div>
</div>

<%
if(rawList!=null && !rawList.isEmpty()){
    Map<String,List<Map<String,String>>> grouped = new LinkedHashMap<>();
    for(Map<String,String> row:rawList){
        String post=row.get("post_applied_for");
        if(post==null || post.trim().isEmpty()) post="General";
        grouped.computeIfAbsent(post,k->new ArrayList<>()).add(row);
    }

    for(String post:grouped.keySet()){
        List<Map<String,String>> candidates=grouped.get(post);
        int postShortlisted=0, postDemoSelected=0, postHired=0;
        for(Map<String,String> c:candidates){
            if("Yes".equalsIgnoreCase(c.get("shortlisted"))) postShortlisted++;
            if("Selected".equalsIgnoreCase(c.get("demo_status"))) postDemoSelected++;
            if("Yes".equalsIgnoreCase(c.get("Hired_status"))) postHired++;
        }
%>

<div class="section">
<div class="section-header">
<h1><%=post%></h1>
<div class="section-stats">
<span>Total: <%=candidates.size()%></span>
<span>Shortlisted: <%=postShortlisted%></span>
<span>Demo Selected: <%=postDemoSelected%></span>
<span>Hired: <%=postHired%></span>
</div>
</div>

<div class="table-wrapper">
<table>
<thead>
<tr>
<th class="name">Name</th>
<th class="qualification">Qualification</th>
<th class="experience">Experience</th>
<th class="shortlist">Shortlist Status</th>
<th class="callstatus">Call Status</th>
<th class="demo">Demo Status</th>
<th class="interview">Interview Status</th>
<th class="hired">Hired</th>
<th class="remarks">Remarks</th>
<th class="action">Action</th>
</tr>
</thead>

<tbody>
<%
for(Map<String,String> c:candidates){
    String rowClass = "Yes".equalsIgnoreCase(c.get("Hired_status")) ? "hired-row" : "";
    String json=gson.toJson(c).replace("&","&amp;").replace("\"","&quot;").replace("<","&lt;").replace(">","&gt;");
%>

<tr class="<%=rowClass%>">
<td class="name">
<b><%=c.get("name")%></b><br>
<small><%=c.get("mobile_no")%></small>
</td>

<td class="qualification">
<%=c.get("qualification")%><br>
<small><%=c.get("specialization")%></small>
</td>

<td class="experience"><%=c.get("total_experience")%> Yrs</td>

<td class="shortlist">
<% if("Yes".equalsIgnoreCase(c.get("shortlisted"))){ %>
<span class="badge success">Shortlisted</span>
<% } else if("No".equalsIgnoreCase(c.get("shortlisted"))){ %>
<span class="badge danger">Rejected</span>
<% } else { %>
<span class="badge warning">Review</span>
<% } %>
</td>

<td class="callstatus"><%=c.get("call_status")%></td>

<td class="demo">
<span class="badge primary"><%= (c.get("demo_status")==null)?"Pending":c.get("demo_status") %></span>
</td>

<td class="interview"><%=c.get("interview_status")%></td>

<td class="hired">
<% if("Yes".equalsIgnoreCase(c.get("Hired_status"))){ %>
<span class="badge success">Hired</span>
<% } else { %>
<span class="badge warning">Pending</span>
<% } %>
</td>

<td class="remarks"><%=c.get("remarks")%></td>

<td class="action">
<button class="btn-primary reviewBtn" data-candidate="<%=json%>">Review</button>
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

<!-- Other modal fields remain same as before -->

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

function closeModal(){document.getElementById("editModal").style.display="none";}
</script>

</body>
</html>