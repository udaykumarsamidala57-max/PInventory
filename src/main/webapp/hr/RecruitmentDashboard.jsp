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

I have updated your Edit Modal to include every single field handled by your Servlet's UPDATE query. I have organized them into logical groups (Personal, Education, Professional, and Recruitment Workflow) to keep the form clean and easy to navigate.

Updated JSP Edit Block
Replace your existing <div class="modal" id="editModal"> and the script section with this code:

HTML
<div class="modal" id="editModal">
    <div class="modal-content" style="width: 1100px;"> <div class="modal-title">Update Candidate Master Dossier</div>

        <form action="resume" method="post" class="modal-form">
            <input type="hidden" name="sl_no" id="f_sl_no">

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 30px;">
                
                <div>
                    <h4>1. Basic & Contact Information</h4>
                    <div class="form-row">
                        <input type="text" name="name" id="f_name" placeholder="Full Name">
                        <input type="text" name="mobile_no" id="f_mobile_no" placeholder="Mobile Number">
                    </div>
                    <div class="form-row">
                        <input type="text" name="address" id="f_address" placeholder="Full Address">
                    </div>
                    <div class="form-row">
                        <select name="gender" id="f_gender">
                            <option value="">Select Gender</option>
                            <option value="Male">Male</option>
                            <option value="Female">Female</option>
                            <option value="Other">Other</option>
                        </select>
                        <input type="date" name="date_of_birth" id="f_date_of_birth" title="Date of Birth">
                        <select name="marital_status" id="f_marital_status">
                            <option value="">Marital Status</option>
                            <option value="Single">Single</option>
                            <option value="Married">Married</option>
                        </select>
                    </div>

                    <h4>2. Qualification & Skills</h4>
                    <div class="form-row">
                        <input type="text" name="qualification" id="f_qualification" placeholder="Qualification (e.g. B.Ed)">
                        <input type="text" name="specialization" id="f_specialization" placeholder="Subject/Specialization">
                    </div>
                    <div class="form-row">
                        <input type="text" name="percentage_marks" id="f_percentage_marks" placeholder="Percentage %">
                        <input type="text" name="year_of_passing" id="f_year_of_passing" placeholder="Year of Passing">
                    </div>
                    <div class="form-row">
                        <textarea name="other_skills_certifications" id="f_other_skills_certifications" placeholder="Other Skills / Certifications" style="min-height: 60px;"></textarea>
                    </div>

                    <h4>3. Experience & Salary</h4>
                    <div class="form-row">
                        <input type="text" name="total_experience" id="f_total_experience" placeholder="Total Exp (Yrs)">
                        <input type="text" name="relevant_experience" id="f_relevant_experience" placeholder="Relevant Exp">
                    </div>
                    <div class="form-row">
                        <input type="text" name="present_salary" id="f_present_salary" placeholder="Present Salary">
                        <input type="text" name="expected_salary" id="f_expected_salary" placeholder="Expected Salary">
                    </div>
                </div>

                <div>
                    <h4>4. Selection Process</h4>
                    <div class="form-row">
                        <input type="text" name="post_applied_for" id="f_post_applied_for" placeholder="Post Applied For">
                        <input type="text" name="resume_no" id="f_resume_no" placeholder="Resume/Ref No.">
                    </div>
                    <div class="form-row">
                        <select name="shortlisted" id="f_shortlisted">
                            <option value="Pending">Shortlist Status: Pending</option>
                            <option value="Yes">Shortlisted</option>
                            <option value="No">Rejected</option>
                        </select>
                        <input type="text" name="call_status" id="f_call_status" placeholder="Call Status (e.g. Busy/Fixed)">
                    </div>

                    <div class="form-row">
                        <div>
                            <label style="font-size: 11px; color: #64748b;">Demo Date</label>
                            <input type="date" name="demo_date" id="f_demo_date">
                        </div>
                        <div>
                            <label style="font-size: 11px; color: #64748b;">Demo Result</label>
                            <select name="demo_status" id="f_demo_status">
                                <option value="Pending">Demo: Pending</option>
                                <option value="Selected">Demo: Selected</option>
                                <option value="Rejected">Demo: Rejected</option>
                            </select>
                        </div>
                    </div>
                    <input type="text" name="demo_taken_by" id="f_demo_taken_by" placeholder="Demo Taken By" style="margin-top: 10px;">
                    <textarea name="demo_remarks" id="f_demo_remarks" placeholder="Demo Performance Remarks" style="min-height: 40px; margin-top: 10px;"></textarea>

                    <div class="form-row" style="margin-top: 10px;">
                        <div>
                            <label style="font-size: 11px; color: #64748b;">Interview Date</label>
                            <input type="date" name="interview_date" id="f_interview_date">
                        </div>
                        <div>
                            <label style="font-size: 11px; color: #64748b;">HR Verdict</label>
                            <select name="interview_status" id="f_interview_status">
                                <option value="Pending">Int: Pending</option>
                                <option value="Selected">Int: Selected</option>
                                <option value="Rejected">Int: Rejected</option>
                            </select>
                        </div>
                    </div>
                    <input type="text" name="interview_taken_by" id="f_interview_taken_by" placeholder="Interview Taken By" style="margin-top: 10px;">

                    <h4 style="color: #9333ea;">5. Final Decision</h4>
                    <div class="form-row">
                        <select name="Hired_status" id="f_Hired_status" style="border: 2px solid #9333ea; font-weight: bold;">
                            <option value="No">Not Hired</option>
                            <option value="Yes">FINAL HIRE (Confirmed)</option>
                        </select>
                        <input type="text" name="reference_by" id="f_reference_by" placeholder="Referenced By">
                    </div>
                    <textarea name="remarks" id="f_remarks" placeholder="Final Closing Remarks / Salary Negotiated" style="margin-top: 10px;"></textarea>
                </div>
            </div>

            <div class="modal-buttons">
                <button type="button" onclick="closeModal()" class="btn-light">Close Without Saving</button>
                <button type="submit" class="btn-primary" style="padding: 10px 25px; font-weight: bold;">COMMIT UPDATES TO SYSTEM</button>
            </div>
        </form>
    </div>
</div>

<script>
document.querySelectorAll(".reviewBtn").forEach(btn => {
    btn.addEventListener("click", function() {
        let data = JSON.parse(this.dataset.candidate);
        
        // Populate all fields that have a corresponding ID
        Object.keys(data).forEach(key => {
            let el = document.getElementById("f_" + key);
            if (el) {
                // If it's a date field, we need the first 10 chars (YYYY-MM-DD)
                if(el.type === 'date' && data[key]){
                    el.value = data[key].split(' ')[0];
                } else {
                    el.value = data[key] || "";
                }
            }
        });
        document.getElementById("editModal").style.display = "flex";
    });
});

function closeModal() {
    document.getElementById("editModal").style.display = "none";
}

// Close when clicking outside content
window.onclick = function(event) {
    let modal = document.getElementById("editModal");
    if (event.target == modal) {
        closeModal();
    }
}
</script>

</body>
</html>