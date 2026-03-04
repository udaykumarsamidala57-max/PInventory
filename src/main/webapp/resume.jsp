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
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>RecruitPro | High-Impact HR Dashboard</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RecruitPro | High-Impact HR Dashboard</title>
    
    <link rel="stylesheet" href="CSS/Recruitment.css">
    
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>

<body>

<div class="container">
    <div class="header-hero">
        <div>
            <h1 style="margin:0; font-size: 32px; font-weight: 800;">Recruitment 2026 -27</h1>
            <p style="opacity:0.7; margin: 5px 0 0;">Managing Excellence at Sandur Residential School</p>
        </div>
        <div style="text-align: right;">
            <div style="font-size: 14px; opacity:0.6;">System Status</div>
            <div style="font-weight: 800; color: #4ade80;"><i class="fas fa-circle"></i> LIVE & ACCURATE</div>
        </div>
    </div>

    <%
    List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
    if(rawList != null && !rawList.isEmpty()){
        Map<String,List<Map<String,String>>> groupedData = new LinkedHashMap<>();
        for(Map<String,String> row : rawList){
            String post = row.get("post_applied_for");
            if(post == null || post.trim().isEmpty()) post = "General/Open";
            groupedData.computeIfAbsent(post, k -> new ArrayList<>()).add(row);
        }

        for(String postName : groupedData.keySet()){
            List<Map<String,String>> candidates = groupedData.get(postName);
    %>

    <div style="margin-bottom: 60px;">
        <h2 style="display:flex; align-items:center; gap:15px; color: var(--dark);">
            <span style="background:var(--primary); color:white; width:40px; height:40px; display:inline-flex; align-items:center; justify-content:center; border-radius:12px;"><i class="fas fa-layer-group"></i></span>
            <%=postName%> <small style="font-weight:400; color:#94a3b8;">(<%=candidates.size()%>)</small>
        </h2>

        <div class="modern-card">
            <table>
                <thead>
                    <tr>
                        <th>Candidate Profile</th>
                        <th>Academic Summary</th>
                        <th>Experience</th>
                        <th>Shortlist Status</th>
                        <th>Demo Stage</th>
                        <th style="text-align:center;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                <% for(Map<String,String> c : candidates){ 
                	String isYes = c.get("shortlisted") == null ? "" : c.get("shortlisted");
                	String demo = c.get("demo_status") == null ? "" : c.get("demo_status");
                	String gender = c.get("gender") == null ? "" : c.get("gender");

                	String rowClass = "";

           
                	// 1️⃣ If Shortlisted = No → Always Red
                	if(isYes.equalsIgnoreCase("No")){
                	    rowClass = "demo-rejected-row";
                	}
                	// 2️⃣ Demo Selected → Green
                	else if(demo.equalsIgnoreCase("Selected") || demo.equalsIgnoreCase("Selected in Demo")){
                	    rowClass = "demo-selected-row";
                	}
                	// 3️⃣ Demo Rejected → Red
                	else if(demo.equalsIgnoreCase("Rejected") || demo.equalsIgnoreCase("Rejected in Demo")){
                	    rowClass = "demo-rejected-row";
                	}
                	
                %>
                    <tr class="<%=rowClass%>">
                        <td>
                            <div style="font-weight: 800; font-size: 16px;"><%=c.get("name")%></div>
                            <div style="display:flex; gap:8px; margin-top:5px; align-items:center;">
                                <span class="gender-pill <%=gender.toLowerCase()%>">
                                    <i class="fas fa-<%=gender.equalsIgnoreCase("Male") ? "mars" : "venus"%>"></i> <%=gender%>
                                </span>
                                <small style="color:#64748b;"><i class="fas fa-phone"></i> <%=c.get("mobile_no")%></small>
                            </div>
                        </td>
                        <td>
                            <div style="font-weight: 600; color:#1e293b;"><%=c.get("qualification")%></div>
                            <small style="color:#94a3b8;"><%=c.get("specialization")%></small>
                        </td>
                        <td>
                            <div style="background:#f1f5f9; display:inline-block; padding:5px 12px; border-radius:10px; font-weight:800; color:var(--dark);">
                                <%=c.get("total_experience")%> Years
                            </div>
                        </td>
                        <td>
                            <% if(isYes.equalsIgnoreCase("Yes")) { %>
                                <div style="color:var(--success); font-weight:800;"><i class="fas fa-check-double"></i> SHORTLISTED</div>
                            <% } else if(isYes.equalsIgnoreCase("No")) { %>
                                <div style="color:var(--accent); font-weight:800;"><i class="fas fa-times"></i> REJECTED</div>
                            <% } else { %>
                                <div style="color:var(--warning); font-weight:800;"><i class="fas fa-hourglass-start"></i> IN REVIEW</div>
                            <% } %>
                        </td>
                        <td>
                            <div class="demo-active">
                                <i class="fas fa-chalkboard-teacher"></i> <%= (demo == null || demo.isEmpty()) ? "PENDING" : demo.toUpperCase() %>
                            </div>
                        </td>
                        <td style="text-align:center;">
                            <button class="btn-action" onclick='openModal(<%=new Gson().toJson(c)%>)'>Review Profile</button>
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
    <div class="modal-window">
        <div class="modal-header">
            <div>
                <h2 style="margin:0; font-weight: 800; color:var(--dark);">Application Intelligence</h2>
                <p style="margin:0; color:#64748b;">Full control over candidate status and workflow</p>
            </div>
            <button onclick="closeModal()" style="background:none; border:none; font-size:28px; cursor:pointer;">&times;</button>
        </div>
        
        <form action="resume" method="post">
            <div class="modal-body">
                <input type="hidden" name="sl_no" id="f_sl_no">
                
                <div class="input-grid">
                    <div class="section-tag">Basic Identity</div>
                    <div class="form-group">
                        <label>Full Name</label>
                        <input type="text" name="name" id="f_name" class="form-input">
                    </div>
                    <div class="form-group">
                        <label>Mobile Number</label>
                        <input type="text" name="mobile_no" id="f_mobile_no" class="form-input">
                    </div>
                    <div class="form-group">
                        <label>Gender Selection</label>
                        <select name="gender" id="f_gender" class="form-input" style="background: #fff7ed;">
                            <option value="Male">Male ♂</option>
                            <option value="Female">Female ♀</option>
                        </select>
                    </div>

                    <div class="section-tag">Candidate Assessment</div>
                    <div class="form-group">
                        <label>Shortlisting Final Call</label>
                        <select name="shortlisted" id="f_shortlisted" class="form-input" style="border:2px solid var(--success);">
                            <option value="Pending">Pending Decision</option>
                            <option value="Yes">Shortlist (Yes)</option>
                            <option value="No">Reject (No)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Demo Progress</label>
                        <select name="demo_status" id="f_demo_status" class="form-input" style="border:2px solid var(--demo-color);">
                            <option value="Not Scheduled">Not Scheduled</option>
                            <option value="Scheduled">Scheduled</option>
                            <option value="Demo Completed">Demo Completed</option>
                            <option value="Selected">Selected in Demo</option>
                            <option value="Rejected">Rejected in Demo</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Interview Outcome</label>
                        <input type="text" name="interview_status" id="f_interview_status" class="form-input" placeholder="e.g. Selected for HOD round">
                    </div>

                    <div class="section-tag">Professional Data</div>
                    <div class="form-group">
                        <label>Qualification</label>
                        <input type="text" name="qualification" id="f_qualification" class="form-input">
                    </div>
                    <div class="form-group">
                        <label>Specialization</label>
                        <input type="text" name="specialization" id="f_specialization" class="form-input">
                    </div>
                    <div class="form-group">
                        <label>Experience (Yrs)</label>
                        <input type="text" name="total_experience" id="f_total_experience" class="form-input">
                    </div>

                    <div class="form-group" style="grid-column: span 3;">
                        <label>Internal Admin Remarks</label>
                        <textarea name="remarks" id="f_remarks" class="form-input" rows="3"></textarea>
                    </div>
                </div>

                <input type="hidden" name="address" id="f_address">
                <input type="hidden" name="post_applied_for" id="f_post_applied_for">
                <input type="hidden" name="date_of_birth" id="f_date_of_birth">
                <input type="hidden" name="marital_status" id="f_marital_status">
                <input type="hidden" name="percentage_marks" id="f_percentage_marks">
                <input type="hidden" name="year_of_passing" id="f_year_of_passing">
                <input type="hidden" name="reference_by" id="f_reference_by">
                <input type="hidden" name="other_skills_certifications" id="f_other_skills_certifications">
                <input type="hidden" name="experience" id="f_experience">
                <input type="hidden" name="relevant_experience" id="f_relevant_experience">
                <input type="hidden" name="present_salary" id="f_present_salary">
                <input type="hidden" name="expected_salary" id="f_expected_salary">
                <input type="hidden" name="call_status" id="f_call_status">
                <input type="hidden" name="demo_taken_by" id="f_demo_taken_by">
                <input type="hidden" name="interview_taken_by" id="f_interview_taken_by">
            </div>
            
            <div style="padding: 30px 40px; background: #f8fafc; border-top: 1px solid #e2e8f0; display:flex; justify-content: flex-end; gap: 20px;">
                <button type="button" onclick="closeModal()" style="background:none; border:none; font-weight:700; cursor:pointer; color:#64748b;">Cancel Changes</button>
                <button type="submit" class="btn-action" style="padding: 15px 50px; font-size:16px;">Commit Updates</button>
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
function closeModal(){ document.getElementById('editModal').style.display = 'none'; }
</script>

</body>
</html>