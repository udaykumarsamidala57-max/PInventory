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
<html>
<head>
<meta charset="UTF-8">
<title>RecruitPro | Recruitment Dashboard</title>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Recruitment.css?v=6">

<style>
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

int total = 0;
int shortlisted = 0;
int selected = 0;

if(rawList != null){
    total = rawList.size();
    for(Map<String,String> c : rawList){
        if("Yes".equalsIgnoreCase(c.get("shortlisted"))) shortlisted++;
        if(c.get("demo_status") != null && c.get("demo_status").toLowerCase().contains("selected"))
            selected++;
    }
}
%>

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
        <h3>Selected in Demo</h3>
        <div class="kpi-number primary"><%=selected%></div>
    </div>
</div>

<%
if(rawList != null && !rawList.isEmpty()){

Map<String,List<Map<String,String>>> grouped = new LinkedHashMap<>();

for(Map<String,String> row : rawList){
    String post = row.get("post_applied_for");
    if(post == null || post.trim().isEmpty()) post = "General";
    grouped.computeIfAbsent(post, k-> new ArrayList<>()).add(row);
}

for(String post : grouped.keySet()){
List<Map<String,String>> candidates = grouped.get(post);
%>

<div class="section">
    <div class="section-header">
        <h2><%=post%></h2>
        <span class="count"><%=candidates.size()%> Candidates</span>
    </div>

    <div class="table-wrapper">
        <table>
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Qualification</th>
                    <th>Experience</th>
                    <th>Shortlist Status</th>
                    <th>Call Status</th>
                    <th>Demo Status</th>
                    <th>Interview Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
            <% for(Map<String,String> c : candidates){ %>
                <tr>
                    <td>
                        <b><%=c.get("name")%></b><br>
                        <small><%=c.get("mobile_no")%></small>
                    </td>
                    <td>
                        <%=c.get("qualification")%><br>
                        <small><%=c.get("specialization")%></small>
                    </td>
                    <td><%=c.get("total_experience")%> Yrs</td>
                    <td>
                        <% if("Yes".equalsIgnoreCase(c.get("shortlisted"))){ %>
                            <span class="badge success">Shortlisted</span>
                        <% } else if("No".equalsIgnoreCase(c.get("shortlisted"))){ %>
                            <span class="badge danger">Rejected</span>
                        <% } else { %>
                            <span class="badge warning">Review</span>
                        <% } %>
                    </td>
                    <td><%=c.get("call_status")%> </td>
                    <td>
                        <span class="badge primary">
                        <%= (c.get("demo_status")==null)?"Pending":c.get("demo_status") %>
                        </span>
                    </td>
                    <td><%=c.get("interview_status")%> </td>
                    
                    <td>
                        <button class="btn-primary"
                        onclick='openModal(<%=new Gson().toJson(c)%>)'>
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

<!-- ================= FULL EDIT MODAL ================= -->

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

<div class="form-row">
<input type="text" name="address" id="f_address" placeholder="Address">
<input type="text" name="post_applied_for" id="f_post_applied_for" placeholder="Post Applied">
</div>

<div class="form-row">
<input type="text" name="gender" id="f_gender" placeholder="Gender">
<input type="text" name="date_of_birth" id="f_date_of_birth" placeholder="Date of Birth">
</div>

<div class="form-row">
<input type="text" name="marital_status" id="f_marital_status" placeholder="Marital Status">
<input type="text" name="reference_by" id="f_reference_by" placeholder="Reference By">
</div>

<h4>Education</h4>
<div class="form-row">
<input type="text" name="qualification" id="f_qualification" placeholder="Qualification">
<input type="text" name="specialization" id="f_specialization" placeholder="Specialization">
</div>

<div class="form-row">
<input type="text" name="percentage_marks" id="f_percentage_marks" placeholder="Percentage">
<input type="text" name="year_of_passing" id="f_year_of_passing" placeholder="Year of Passing">
</div>

<h4>Experience</h4>
<textarea name="experience" id="f_experience" placeholder="Experience Details"></textarea>

<div class="form-row">
<input type="text" name="relevant_experience" id="f_relevant_experience" placeholder="Relevant Experience">
<input type="text" name="total_experience" id="f_total_experience" placeholder="Total Experience">
</div>

<h4>Salary</h4>
<div class="form-row">
<input type="text" name="present_salary" id="f_present_salary" placeholder="Present Salary">
<input type="text" name="expected_salary" id="f_expected_salary" placeholder="Expected Salary">
</div>

<h4>Shortlisting Status</h4>
<div class="form-row">
<select name="shortlisted" id="f_shortlisted">
<option value="Pending">Pending</option>
<option value="Yes">Shortlist</option>
<option value="No">Reject</option>
</select>
<h4>Calling Status</h4>
<select name="call_status" id="f_call_status">
<option value="Pending">Pending</option>
<option value="Called">Called</option>
<option value="Not Reachable">Not Reachable</option>
</select>
</div>
<h4>Demo Status</h4>
<div class="form-row">
<select name="demo_status" id="f_demo_status">
<option value="Pending">Pending</option>
<option value="Scheduled">Scheduled</option>
<option value="Selected">Selected</option>
<option value="Rejected">Rejected</option>
</select>
<h4>Demo Taken By</h4>
<input type="text" name="demo_taken_by" id="f_demo_taken_by" placeholder="Demo Taken By">
</div>
<h4>Interview Status</h4>
<div class="form-row">
<select name="interview_status" id="f_interview_status">
<option value="Pending">Pending</option>
<option value="Selected">Selected</option>
<option value="Rejected">Rejected</option>
</select>
<h4>Interview Taken by</h4>
<input type="text" name="interview_taken_by" id="f_interview_taken_by" placeholder="Interview Taken By">
</div>
<h4>Interview Taken by</h4>
<textarea name="remarks" id="f_remarks" placeholder="Remarks"></textarea>

<div class="modal-buttons">
<button type="button" onclick="closeModal()" class="btn-light">Cancel</button>
<button type="submit" class="btn-primary">Update Full Details</button>
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
    document.getElementById('editModal').style.display='flex';
}
function closeModal(){
    document.getElementById('editModal').style.display='none';
}
</script>

</body>
</html>