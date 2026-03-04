<%@ page import="java.util.*" %>
<%@ page import="com.google.gson.Gson" %>

<%
    // Session Check
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
    
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    
   <link rel="stylesheet" href="CSS/Recruitment.css">
</head>

<body>

<div class="container">
    <header class="header-hero">
        <div class="header-left">
            <h1>Recruitment 2026 - 27</h1>
            <p>Managing Excellence at Sandur Residential School</p>
        </div>
        <div style="text-align: right;">
            <div style="font-size: 12px; opacity:0.6; text-transform: uppercase; letter-spacing: 1px;">System Status</div>
            <div style="font-weight: 800; color: #4ade80; display: flex; align-items: center; gap: 8px; justify-content: flex-end;">
                <i class="fas fa-circle" style="font-size: 8px;"></i> LIVE & ACCURATE
            </div>
        </div>
    </header>

    <%
    List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
    if(rawList != null && !rawList.isEmpty()){
        // Grouping logic
        Map<String,List<Map<String,String>>> groupedData = new LinkedHashMap<>();
        for(Map<String,String> row : rawList){
            String post = row.get("post_applied_for");
            if(post == null || post.trim().isEmpty()) post = "General/Open";
            groupedData.computeIfAbsent(post, k -> new ArrayList<>()).add(row);
        }

        for(String postName : groupedData.keySet()){
            List<Map<String,String>> candidates = groupedData.get(postName);
    %>

    <section style="margin-bottom: 60px;">
        <h2 style="display:flex; align-items:center; gap:15px; color: var(--dark); margin-bottom: 20px;">
            <span style="background:var(--primary); color:white; width:36px; height:36px; display:inline-flex; align-items:center; justify-content:center; border-radius:10px; font-size: 14px;">
                <i class="fas fa-layer-group"></i>
            </span>
            <%=postName%> 
            <span style="font-weight:400; color:#94a3b8; font-size: 16px;">(<%=candidates.size()%>)</span>
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
                    if(isYes.equalsIgnoreCase("No") || demo.toLowerCase().contains("rejected")) {
                        rowClass = "demo-rejected-row";
                    } else if(demo.toLowerCase().contains("selected")) {
                        rowClass = "demo-selected-row";
                    }
                %>
                    <tr class="<%=rowClass%>">
                        <td>
                            <div style="font-weight: 700; font-size: 15px; color: var(--dark);"><%=c.get("name")%></div>
                            <div style="display:flex; gap:8px; margin-top:6px; align-items:center;">
                                <span class="gender-pill <%=gender.toLowerCase()%>">
                                    <i class="fas fa-<%=gender.equalsIgnoreCase("Male") ? "mars" : "venus"%>"></i> <%=gender%>
                                </span>
                                <small style="color:var(--muted);"><i class="fas fa-phone"></i> <%=c.get("mobile_no")%></small>
                            </div>
                        </td>
                        <td>
                            <div style="font-weight: 600;"><%=c.get("qualification")%></div>
                            <small style="color:var(--muted);"><%=c.get("specialization")%></small>
                        </td>
                        <td>
                            <span style="background:#f1f5f9; padding:4px 10px; border-radius:8px; font-weight:700; font-size: 13px;">
                                <%=c.get("total_experience")%> Yrs
                            </span>
                        </td>
                        <td>
                            <% if(isYes.equalsIgnoreCase("Yes")) { %>
                                <span style="color:var(--success); font-weight:700; font-size: 12px;"><i class="fas fa-check-circle"></i> SHORTLISTED</span>
                            <% } else if(isYes.equalsIgnoreCase("No")) { %>
                                <span style="color:var(--danger); font-weight:700; font-size: 12px;"><i class="fas fa-times-circle"></i> REJECTED</span>
                            <% } else { %>
                                <span style="color:var(--warning); font-weight:700; font-size: 12px;"><i class="fas fa-clock"></i> IN REVIEW</span>
                            <% } %>
                        </td>
                        <td>
                            <div style="font-weight: 600; font-size: 13px; color: var(--muted);">
                                <i class="fas fa-chalkboard-teacher" style="margin-right: 5px;"></i>
                                <%= (demo == null || demo.isEmpty()) ? "PENDING" : demo.toUpperCase() %>
                            </div>
                        </td>
                        <td style="text-align:center;">
                            <button class="btn-action" onclick='openModal(<%=new Gson().toJson(c)%>)'>
                                <i class="fas fa-external-link-alt" style="font-size: 10px; margin-right: 5px;"></i> Review
                            </button>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </section>
    <% } } %>
</div>

<div class="modal-overlay" id="editModal">
    <div class="modal-window">
        <div class="modal-header" style="display: flex; justify-content: space-between; align-items: center;">
            <div>
                <h2 style="margin:0; font-weight: 800; color:var(--dark); font-size: 20px;">Application Intelligence</h2>
                <p style="margin:4px 0 0; color:var(--muted); font-size: 13px;">Update candidate status and workflow details</p>
            </div>
            <button onclick="closeModal()" style="background:#f1f5f9; border:none; width: 36px; height: 36px; border-radius: 50%; cursor:pointer; display: flex; align-items: center; justify-content: center; transition: 0.2s;">
                <i class="fas fa-times" style="color: var(--muted);"></i>
            </button>
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
                        <label>Gender</label>
                        <select name="gender" id="f_gender" class="form-input">
                            <option value="Male">Male</option>
                            <option value="Female">Female</option>
                        </select>
                    </div>

                    <div class="section-tag">Assessment & Progress</div>
                    <div class="form-group">
                        <label>Shortlist Status</label>
                        <select name="shortlisted" id="f_shortlisted" class="form-input" style="font-weight: 700;">
                            <option value="Pending">Pending Decision</option>
                            <option value="Yes">Shortlist (Yes)</option>
                            <option value="No">Reject (No)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Demo Status</label>
                        <select name="demo_status" id="f_demo_status" class="form-input">
                            <option value="Not Scheduled">Not Scheduled</option>
                            <option value="Scheduled">Scheduled</option>
                            <option value="Demo Completed">Demo Completed</option>
                            <option value="Selected">Selected in Demo</option>
                            <option value="Rejected">Rejected in Demo</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Interview Outcome</label>
                        <input type="text" name="interview_status" id="f_interview_status" class="form-input" placeholder="Current stage...">
                    </div>

                    <div class="section-tag">Professional Background</div>
                    <div class="form-group">
                        <label>Qualification</label>
                        <input type="text" name="qualification" id="f_qualification" class="form-input">
                    </div>
                    <div class="form-group">
                        <label>Specialization</label>
                        <input type="text" name="specialization" id="f_specialization" class="form-input">
                    </div>
                    <div class="form-group">
                        <label>Experience (Years)</label>
                        <input type="text" name="total_experience" id="f_total_experience" class="form-input">
                    </div>

                    <div class="form-group full-width">
                        <label>Internal Administrative Remarks</label>
                        <textarea name="remarks" id="f_remarks" class="form-input" rows="3" placeholder="Add notes about the candidate..."></textarea>
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
            
            <div class="modal-footer" style="padding: 24px 40px; background: #f8fafc; border-top: 1px solid var(--border); display:flex; justify-content: flex-end; gap: 15px;">
                <button type="button" onclick="closeModal()" style="background:none; border:none; font-weight:700; cursor:pointer; color:var(--muted); font-size: 14px;">Dismiss</button>
                <button type="submit" class="btn-action" style="padding: 12px 36px; font-size: 14px; border-radius: 12px;">Update Record</button>
            </div>
        </form>
    </div>
</div>

<script>
    function openModal(data){
        // Map JSON data to form fields
        for(let key in data){
            let el = document.getElementById('f_'+key);
            if(el) el.value = data[key] || '';
        }
        
        const modal = document.getElementById('editModal');
        modal.style.display = 'flex';
        // Gentle fade in
        modal.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 200, fill: 'forwards' });
    }

    function closeModal(){ 
        const modal = document.getElementById('editModal');
        modal.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 200, fill: 'forwards' });
        setTimeout(() => { modal.style.display = 'none'; }, 200);
    }
    
    // Close modal on outside click
    window.onclick = function(event) {
        const modal = document.getElementById('editModal');
        if (event.target == modal) { closeModal(); }
    }
</script>

</body>
</html>