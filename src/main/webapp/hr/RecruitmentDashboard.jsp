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
<html lang="en">
<head>
<meta charset="UTF-8">
<title>RecruitPro | Intelligence Dashboard</title>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Recruitment.css?v=15">

<style>
    /* --- ENHANCED COLOR LOGIC --- */
    .row-hired { background-color: #f0fdf4 !important; border-left: 6px solid #15803d; } /* Deep Green */
    .row-final-selected { background-color: #f0f9ff !important; border-left: 6px solid #0369a1; } /* Blue */
    .row-rejected { background-color: #fff1f2 !important; opacity: 0.8; }
    
    .badge-hired { background: #15803d; color: white; border: 1px solid #14532d; }
    
    /* --- MODAL OPTIMIZATION --- */
    .modal-content { width: 1000px; border-radius: 16px; border: none; }
    .modal-form { 
        display: grid; 
        grid-template-columns: repeat(3, 1fr); 
        gap: 15px; 
        padding: 25px;
        background: #f8fafc;
    }
    .full-width { grid-column: span 3; }
    .half-width { grid-column: span 2; }
    
    .section-title {
        grid-column: span 3;
        background: #e2e8f0;
        padding: 8px 15px;
        border-radius: 6px;
        font-weight: 700;
        font-size: 13px;
        color: #475569;
        margin-top: 10px;
        display: flex;
        align-items: center;
    }

    input, select, textarea {
        padding: 10px;
        border: 1px solid #cbd5e1;
        border-radius: 6px;
        font-size: 13px;
    }

    label { font-size: 11px; font-weight: 700; color: #64748b; margin-bottom: 2px; display: block; }
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-container">

<%
List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
int total = 0, shorted = 0, hiredCount = 0;

if(rawList != null){
    total = rawList.size();
    for(Map<String,String> c : rawList){
        if("Yes".equalsIgnoreCase(c.get("shortlisted"))) shorted++;
        if("Hired".equalsIgnoreCase(c.get("Hired_status"))) hiredCount++;
    }
}
%>

<div class="kpi-grid">
    <div class="kpi-card total"><h3>Applications</h3><div class="kpi-number"><%=total%></div></div>
    <div class="kpi-card short"><h3>Shortlisted</h3><div class="kpi-number" style="color:#f59e0b"><%=shorted%></div></div>
    <div class="kpi-card final"><h3>Final Hires</h3><div class="kpi-number" style="color:#10b981"><%=hiredCount%></div></div>
</div>

<%
if(rawList != null && !rawList.isEmpty()){
    Map<String,List<Map<String,String>>> grouped = new LinkedHashMap<>();
    for(Map<String,String> row : rawList){
        String post = row.get("post_applied_for");
        if(post == null || post.trim().isEmpty()) post = "General/Others";
        grouped.computeIfAbsent(post, k-> new ArrayList<>()).add(row);
    }

    for(String post : grouped.keySet()){
        List<Map<String,String>> candidates = grouped.get(post);
%>

<div class="section">
    <div class="section-header">
        <h1><%=post%></h1>
    </div>

    <div class="table-wrapper">
        <table style="width:100%;">
            <thead>
                <tr>
                    <th>Candidate Detail</th>
                    <th>Experience</th>
                    <th>Status: Shortlist</th>
                    <th>Status: Demo</th>
                    <th>Status: Interview</th>
                    <th>HIRED STATUS</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
            <% 
            for(Map<String,String> c : candidates){
                String sStat = c.get("shortlisted");
                String dStat = c.get("demo_status");
                String iStat = c.get("interview_status");
                String hStat = c.get("Hired_status");

                String highlightClass = "";
                if("Hired".equalsIgnoreCase(hStat)) highlightClass = "row-hired";
                else if("Selected".equalsIgnoreCase(iStat)) highlightClass = "row-final-selected";
                else if("No".equalsIgnoreCase(sStat) || "Rejected".equalsIgnoreCase(iStat)) highlightClass = "row-rejected";

                String json = gson.toJson(c).replace("&","&amp;").replace("\"","&quot;").replace("<","&lt;").replace(">","&gt;");
            %>
                <tr class="<%=highlightClass%>">
                    <td>
                        <b><%=c.get("name")%></b><br>
                        <small><%=c.get("mobile_no")%> | <%=c.get("qualification")%></small>
                    </td>
                    <td><b><%=c.get("total_experience")%> Yrs</b></td>
                    
                    <td><span class="badge <%= "Yes".equalsIgnoreCase(sStat) ? "badge-success" : "badge-warning" %>"><%=sStat%></span></td>
                    <td><span class="badge badge-info"><%=dStat == null ? "Pending" : dStat%></span></td>
                    <td><span class="badge <%= "Selected".equalsIgnoreCase(iStat) ? "badge-success" : "badge-dark" %>"><%=iStat%></span></td>
                    
                    <td>
                        <% if("Hired".equalsIgnoreCase(hStat)){ %>
                            <span class="badge badge-hired">HIRED</span>
                        <% } else { %>
                            <span class="badge badge-dark"><%=hStat == null ? "On Process" : hStat%></span>
                        <% } %>
                    </td>

                    <td>
                        <button class="btn-primary reviewBtn" data-candidate="<%=json%>">EDIT FULL PROFILE</button>
                    </td>
                </tr>
            <% } %>
            </tbody>
        </table>
    </div>
</div>
<% } } %>

</div>

<div class="modal" id="editModal" style="display: none; align-items: center; justify-content: center; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(15, 23, 42, 0.9); z-index: 1000;">
    <div class="modal-content">
        <div style="padding: 15px 25px; background: #1e293b; color: white; display: flex; justify-content: space-between;">
            <h3 style="margin:0">Complete Candidate File</h3>
            <button onclick="closeModal()" style="color:white; background:none; border:none; font-size:24px; cursor:pointer;">&times;</button>
        </div>

        <form action="resume" method="post" class="modal-form">
            <input type="hidden" name="sl_no" id="f_sl_no">

            <div class="section-title">PRIMARY INFORMATION</div>
            <div><label>Full Name</label><input type="text" name="name" id="f_name" style="width:100%"></div>
            <div><label>Mobile</label><input type="text" name="mobile_no" id="f_mobile_no" style="width:100%"></div>
            <div><label>Resume No</label><input type="text" name="resume_no" id="f_resume_no" style="width:100%"></div>
            
            <div class="half-width"><label>Address</label><input type="text" name="address" id="f_address" style="width:100%"></div>
            <div><label>Post Applied For</label><input type="text" name="post_applied_for" id="f_post_applied_for" style="width:100%"></div>

            <div><label>Gender</label><input type="text" name="gender" id="f_gender" style="width:100%"></div>
            <div><label>DOB</label><input type="text" name="date_of_birth" id="f_date_of_birth" style="width:100%"></div>
            <div><label>Marital Status</label><input type="text" name="marital_status" id="f_marital_status" style="width:100%"></div>

            <div class="section-title">EDUCATION & SKILLS</div>
            <div><label>Qualification</label><input type="text" name="qualification" id="f_qualification" style="width:100%"></div>
            <div><label>Specialization</label><input type="text" name="specialization" id="f_specialization" style="width:100%"></div>
            <div><label>Passing Year</label><input type="text" name="year_of_passing" id="f_year_of_passing" style="width:100%"></div>
            <div><label>Percentage %</label><input type="text" name="percentage_marks" id="f_percentage_marks" style="width:100%"></div>
            <div class="half-width"><label>Other Skills/Certifications</label><input type="text" name="other_skills_certifications" id="f_other_skills_certifications" style="width:100%"></div>

            <div class="section-title">PROFESSIONAL EXPERIENCE & SALARY</div>
            <div><label>Total Experience</label><input type="text" name="total_experience" id="f_total_experience" style="width:100%"></div>
            <div><label>Relevant Exp</label><input type="text" name="relevant_experience" id="f_relevant_experience" style="width:100%"></div>
            <div><label>Reference By</label><input type="text" name="reference_by" id="f_reference_by" style="width:100%"></div>
            
            <div><label>Present Salary</label><input type="text" name="present_salary" id="f_present_salary" style="width:100%"></div>
            <div><label>Expected Salary</label><input type="text" name="expected_salary" id="f_expected_salary" style="width:100%"></div>
            <div><label>Created At</label><input type="text" id="f_created_at" readonly style="background:#f1f5f9; width:100%"></div>
            
            <div class="full-width"><label>Experience Details</label><textarea name="experience" id="f_experience" style="width:100%; height:50px;"></textarea></div>

            <div class="section-title" style="background:#fee2e2; color:#b91c1c;">INTERNAL WORKFLOW & STATUS</div>
            
            <div><label>Shortlisted</label>
                <select name="shortlisted" id="f_shortlisted" style="width:100%">
                    <option value="No">No</option><option value="Yes">Yes</option><option value="Pending">Pending</option>
                </select>
            </div>
            <div><label>Call Status</label><input type="text" name="call_status" id="f_call_status" style="width:100%"></div>
            <div><label>Attending Date</label><input type="date" name="attending_date" id="f_attending_date" style="width:100%"></div>

            <div><label>Demo Date</label><input type="date" name="demo_date" id="f_demo_date" style="width:100%"></div>
            <div><label>Demo Status</label><input type="text" name="demo_status" id="f_demo_status" style="width:100%"></div>
            <div><label>Demo Taken By</label><input type="text" name="demo_taken_by" id="f_demo_taken_by" style="width:100%"></div>
            
            <div class="full-width"><label>Demo Remarks</label><textarea name="demo_remarks" id="f_demo_remarks" style="width:100%; height:40px;"></textarea></div>

            <div><label>Interview Date</label><input type="date" name="interview_date" id="f_interview_date" style="width:100%"></div>
            <div><label>Interview Status</label><input type="text" name="interview_status" id="f_interview_status" style="width:100%"></div>
            <div><label>Interview Taken By</label><input type="text" name="interview_taken_by" id="f_interview_taken_by" style="width:100%"></div>

            <div style="background:#dcfce7; padding:5px; border-radius:5px;">
                <label style="color:#15803d">HIRED STATUS</label>
                <select name="Hired_status" id="f_Hired_status" style="width:100%; border-color:#15803d; font-weight:bold;">
                    <option value="On Process">On Process</option>
                    <option value="Hired">Hired</option>
                    <option value="Hold">Hold</option>
                    <option value="Rejected">Rejected</option>
                </select>
            </div>
            <div class="half-width"><label>Final Remarks</label><textarea name="remarks" id="f_remarks" style="width:100%; height:40px;"></textarea></div>

            <div class="full-width" style="display: flex; justify-content: flex-end; gap: 15px; border-top: 1px solid #e2e8f0; padding-top: 15px;">
                <button type="button" onclick="closeModal()" class="btn-light">Discard Changes</button>
                <button type="submit" class="btn-primary" style="padding: 12px 50px;">SAVE FULL PROFILE</button>
            </div>
        </form>
    </div>
</div>

<script>
document.querySelectorAll(".reviewBtn").forEach(btn => {
    btn.addEventListener("click", function() {
        let data = JSON.parse(this.dataset.candidate);
        Object.keys(data).forEach(key => {
            let el = document.getElementById("f_" + key);
            if (el) {
                // Special check for date fields to ensure they format correctly for <input type="date">
                if(el.type === 'date' && data[key]) {
                    el.value = data[key].split(' ')[0]; // Takes 'YYYY-MM-DD' from 'YYYY-MM-DD HH:mm:ss'
                } else {
                    el.value = data[key] || "";
                }
            }
        });
        document.getElementById("editModal").style.display = "flex";
    });
});

function closeModal() { document.getElementById("editModal").style.display = "none"; }
window.onclick = function(e) { if (e.target == document.getElementById("editModal")) closeModal(); }
</script>

</body>
</html>