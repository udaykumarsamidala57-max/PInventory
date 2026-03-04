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
<title>RecruitPro | HR Intelligence Dashboard</title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
:root {
    --brand-primary: #4f46e5;
    --brand-secondary: #0ea5e9;
    --bg-main: #f1f5f9;
    --glass-bg: rgba(255, 255, 255, 0.8);
    --text-main: #1e293b;
    --text-muted: #64748b;
    --border-color: #e2e8f0;
    
    /* Semantic Colors */
    --success: #10b981;
    --danger: #ef4444;
    --warning: #f59e0b;
    --info: #3b82f6;
}

body {
    font-family: 'Plus Jakarta Sans', sans-serif;
    background: var(--bg-main);
    color: var(--text-main);
    margin: 0;
    padding: 0;
    line-height: 1.5;
}

.main-layout {
    display: flex;
    min-height: 100vh;
}

.content-area {
    flex: 1;
    padding: 40px;
    max-width: 1600px;
    margin: auto;
}

/* Header Glassmorphism */
.glass-header {
    background: var(--glass-bg);
    backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.3);
    padding: 24px 32px;
    border-radius: 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05);
    margin-bottom: 30px;
}

/* Stats Row */
.stats-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 20px;
    margin-bottom: 40px;
}

.stat-card {
    background: #fff;
    padding: 24px;
    border-radius: 20px;
    border: 1px solid var(--border-color);
    display: flex;
    align-items: center;
    gap: 16px;
    transition: transform 0.3s ease;
}

.stat-card:hover { transform: translateY(-5px); }
.stat-icon {
    width: 48px;
    height: 48px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
}

/* Modern Table styling */
.post-group { margin-bottom: 50px; }
.group-label {
    font-size: 14px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1px;
    color: var(--brand-primary);
    margin-bottom: 16px;
    display: flex;
    align-items: center;
    gap: 8px;
}

.modern-card {
    background: #fff;
    border-radius: 24px;
    border: 1px solid var(--border-color);
    box-shadow: 0 4px 6px -1px rgba(0,0,0,0.02);
    overflow: hidden;
}

table { width: 100%; border-collapse: collapse; }
th {
    background: #f8fafc;
    padding: 18px 24px;
    text-align: left;
    font-size: 12px;
    font-weight: 700;
    color: var(--text-muted);
    border-bottom: 1px solid var(--border-color);
}

td { padding: 20px 24px; border-bottom: 1px solid #f1f5f9; font-size: 14px; }
tr:last-child td { border-bottom: none; }
tr:hover { background: #f8fafc; }

/* Status Pills */
.badge {
    padding: 6px 12px;
    border-radius: 8px;
    font-size: 11px;
    font-weight: 700;
    display: inline-flex;
    align-items: center;
    gap: 5px;
}
.bg-success { background: #dcfce7; color: #166534; }
.bg-danger { background: #fee2e2; color: #991b1b; }
.bg-warning { background: #fef9c3; color: #854d0e; }
.bg-info { background: #e0f2fe; color: #075985; }

/* Action Buttons */
.btn-primary {
    background: var(--brand-primary);
    color: #fff;
    border: none;
    padding: 10px 20px;
    border-radius: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: 0.3s;
    display: inline-flex;
    align-items: center;
    gap: 8px;
}
.btn-primary:hover { background: #4338ca; box-shadow: 0 4px 12px rgba(79, 70, 229, 0.3); }

/* Modal Design */
.modal-overlay {
    position: fixed;
    inset: 0;
    background: rgba(15, 23, 42, 0.4);
    backdrop-filter: blur(8px);
    display: none;
    align-items: center;
    justify-content: center;
    z-index: 1000;
}

.modal-content {
    background: #fff;
    width: 90%;
    max-width: 1000px;
    border-radius: 28px;
    max-height: 90vh;
    overflow: hidden;
    display: flex;
    flex-direction: column;
}

.modal-header {
    padding: 30px;
    border-bottom: 1px solid var(--border-color);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.modal-body { padding: 40px; overflow-y: auto; }

.form-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 24px;
}

.divider {
    grid-column: span 3;
    display: flex;
    align-items: center;
    gap: 15px;
    margin: 20px 0 10px;
}
.divider span { font-weight: 800; font-size: 11px; text-transform: uppercase; color: var(--brand-primary); letter-spacing: 1px; }
.divider::after { content: ""; height: 1px; flex: 1; background: #e2e8f0; }

.form-group label { display: block; font-size: 12px; font-weight: 700; color: var(--text-muted); margin-bottom: 8px; }
.form-control {
    width: 100%;
    padding: 12px 16px;
    border-radius: 12px;
    border: 1px solid var(--border-color);
    font-family: inherit;
    font-size: 14px;
    transition: 0.2s;
}
.form-control:focus { outline: none; border-color: var(--brand-primary); box-shadow: 0 0 0 4px rgba(79, 70, 229, 0.1); }
</style>
</head>

<body>

<div class="content-area">
    <header class="glass-header">
        <div>
            <h1 style="margin:0; font-size: 24px; font-weight: 800; color: var(--text-main);">Recruit Intelligence</h1>
            <p style="margin:5px 0 0; color: var(--text-muted); font-size: 14px;">Sandur Residential School | Admin Portal 2026</p>
        </div>
        <div style="display:flex; gap: 15px;">
            <button class="btn-primary" style="background:#fff; color:var(--text-main); border:1px solid var(--border-color);">
                <i class="fas fa-file-export"></i> Export Data
            </button>
            <div style="width: 45px; height: 45px; background: var(--brand-primary); border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #fff;">
                <i class="fas fa-user"></i>
            </div>
        </div>
    </header>

    <%
    List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
    int total = 0, shorted = 0, pending = 0, demos = 0;
    
    if(rawList != null) {
        total = rawList.size();
        for(Map<String,String> r : rawList) {
            String s = r.get("shortlisted");
            if("Yes".equalsIgnoreCase(s)) shorted++;
            else if("No".equalsIgnoreCase(s)) {} 
            else pending++;
            if(!r.get("demo_status").isEmpty() && !"Not Scheduled".equalsIgnoreCase(r.get("demo_status"))) demos++;
        }
    }
    %>

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon" style="background: #eef2ff; color: #4f46e5;"><i class="fas fa-users"></i></div>
            <div><div style="font-size: 20px; font-weight: 800;"><%=total%></div><div style="font-size: 12px; color: var(--text-muted);">Total Applications</div></div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #ecfdf5; color: #10b981;"><i class="fas fa-user-check"></i></div>
            <div><div style="font-size: 20px; font-weight: 800;"><%=shorted%></div><div style="font-size: 12px; color: var(--text-muted);">Shortlisted</div></div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #fff7ed; color: #f59e0b;"><i class="fas fa-clock"></i></div>
            <div><div style="font-size: 20px; font-weight: 800;"><%=pending%></div><div style="font-size: 12px; color: var(--text-muted);">Pending Review</div></div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #f0f9ff; color: #0ea5e9;"><i class="fas fa-chalkboard-teacher"></i></div>
            <div><div style="font-size: 20px; font-weight: 800;"><%=demos%></div><div style="font-size: 12px; color: var(--text-muted);">Demo Stages</div></div>
        </div>
    </div>

<%
if(rawList != null && !rawList.isEmpty()){
    Map<String,List<Map<String,String>>> groupedData = new LinkedHashMap<>();
    for(Map<String,String> row : rawList){
        String post = row.get("post_applied_for");
        if(post == null || post.trim().isEmpty()) post = "General/Other";
        groupedData.computeIfAbsent(post, k -> new ArrayList<>()).add(row);
    }

    for(String postName : groupedData.keySet()){
        List<Map<String,String>> candidates = groupedData.get(postName);
%>

    <div class="post-group">
        <div class="group-label">
            <i class="fas fa-briefcase"></i> <%=postName%> 
            <span style="opacity:0.5; font-weight:400; text-transform:none;">&mdash; <%=candidates.size()%> Candidates</span>
        </div>
        <div class="modern-card">
            <table>
                <thead>
                    <tr>
                        <th>CANDIDATE PROFILE</th>
                        <th>QUALIFICATION</th>
                        <th>EXPERIENCE</th>
                        <th>SHORTLIST STATUS</th>
                        <th>PROCESS STAGE</th>
                        <th style="text-align:right;">ACTION</th>
                    </tr>
                </thead>
                <tbody>
                <% for(Map<String,String> c : candidates){ 
                    String status = c.get("shortlisted");
                    String badgeClass = status.equalsIgnoreCase("Yes") ? "bg-success" : (status.equalsIgnoreCase("No") ? "bg-danger" : "bg-warning");
                %>
                    <tr>
                        <td>
                            <div style="font-weight: 700; color: var(--text-main);"><%=c.get("name")%></div>
                            <div style="font-size: 12px; color: var(--text-muted); margin-top:2px;">
                                <i class="fas fa-phone-alt" style="font-size: 10px;"></i> <%=c.get("mobile_no")%>
                            </div>
                        </td>
                        <td><div style="font-weight: 600;"><%=c.get("qualification")%></div><small style="color:var(--text-muted)"><%=c.get("specialization")%></small></td>
                        <td><div style="font-weight: 700;"><%=c.get("total_experience")%></div><small>Years</small></td>
                        <td><span class="badge <%=badgeClass%>"><i class="fas fa-circle" style="font-size:6px;"></i> <%=status%></span></td>
                        <td>
                            <div class="badge bg-info"><i class="fas fa-spinner fa-spin"></i> <%=c.get("demo_status")%></div>
                        </td>
                        <td style="text-align:right;">
                            <button class="btn-primary" onclick='openModal(<%=new Gson().toJson(c)%>)'>
                                View Details <i class="fas fa-arrow-right"></i>
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
            <div>
                <h2 style="margin:0; font-weight: 800;">Candidate Application</h2>
                <p style="margin:5px 0 0; font-size:13px; color:var(--text-muted);">Complete record update & assessment</p>
            </div>
            <button onclick="closeModal()" style="background: #f1f5f9; border: none; width: 40px; height: 40px; border-radius: 50%; cursor: pointer;"><i class="fas fa-times"></i></button>
        </div>
        
        <form action="resume" method="post">
            <div class="modal-body">
                <input type="hidden" name="sl_no" id="f_sl_no">
                
                <div class="form-grid">
                    <div class="divider"><span>Personal Details</span></div>
                    <div class="form-group">
                        <label>Candidate Name</label>
                        <input type="text" name="name" id="f_name" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Phone Number</label>
                        <input type="text" name="mobile_no" id="f_mobile_no" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Date of Birth</label>
                        <input type="text" name="date_of_birth" id="f_date_of_birth" class="form-control">
                    </div>
                    <div class="form-group" style="grid-column: span 2;">
                        <label>Current Address</label>
                        <input type="text" name="address" id="f_address" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Gender</label>
                        <select name="gender" id="f_gender" class="form-control">
                            <option value="Male">Male</option><option value="Female">Female</option>
                        </select>
                    </div>

                    <div class="divider"><span>Professional Info</span></div>
                    <div class="form-group">
                        <label>Qualification</label>
                        <input type="text" name="qualification" id="f_qualification" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Specialization</label>
                        <input type="text" name="specialization" id="f_specialization" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Total Experience</label>
                        <input type="text" name="total_experience" id="f_total_experience" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Present Salary</label>
                        <input type="text" name="present_salary" id="f_present_salary" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Expected Salary</label>
                        <input type="text" name="expected_salary" id="f_expected_salary" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Post Applied For</label>
                        <input type="text" name="post_applied_for" id="f_post_applied_for" class="form-control">
                    </div>

                    <div class="divider"><span>Interview & Decision</span></div>
                    <div class="form-group">
                        <label>Shortlist Decision</label>
                        <select name="shortlisted" id="f_shortlisted" class="form-control" style="font-weight:700;">
                            <option value="Pending">Pending</option>
                            <option value="Yes">Yes (Approved)</option>
                            <option value="No">No (Rejected)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Demo Status</label>
                        <select name="demo_status" id="f_demo_status" class="form-control">
                            <option value="Not Scheduled">Not Scheduled</option>
                            <option value="Scheduled">Scheduled</option>
                            <option value="Completed">Completed</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Interview Status</label>
                        <input type="text" name="interview_status" id="f_interview_status" class="form-control">
                    </div>
                    
                    <input type="hidden" name="marital_status" id="f_marital_status">
                    <input type="hidden" name="percentage_marks" id="f_percentage_marks">
                    <input type="hidden" name="year_of_passing" id="f_year_of_passing">
                    <input type="hidden" name="reference_by" id="f_reference_by">
                    <input type="hidden" name="other_skills_certifications" id="f_other_skills_certifications">
                    <input type="hidden" name="experience" id="f_experience">
                    <input type="hidden" name="relevant_experience" id="f_relevant_experience">
                    <input type="hidden" name="call_status" id="f_call_status">
                    <input type="hidden" name="demo_taken_by" id="f_demo_taken_by">
                    <input type="hidden" name="interview_taken_by" id="f_interview_taken_by">

                    <div class="form-group" style="grid-column: span 3;">
                        <label>Evaluation Remarks</label>
                        <textarea name="remarks" id="f_remarks" class="form-control" rows="3"></textarea>
                    </div>
                </div>
            </div>
            
            <div style="padding: 25px 40px; border-top: 1px solid var(--border-color); display: flex; justify-content: flex-end; gap: 15px; background: #f8fafc;">
                <button type="button" onclick="closeModal()" style="background: none; border: none; font-weight: 700; cursor: pointer;">Discard</button>
                <button type="submit" class="btn-primary" style="padding: 14px 40px; border-radius: 16px;">Save Update</button>
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
window.onclick = function(e){ if(e.target.id == 'editModal') closeModal(); }
</script>

</body>
</html>