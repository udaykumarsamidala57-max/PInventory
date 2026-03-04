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
<title>HR Dashboard | Comprehensive Management</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
:root{
    --primary:#2563eb; --bg:#f8fafc; --text:#0f172a; --border:#e2e8f0;
    --status-yes-bg: #dcfce7; --status-yes-text: #166534;
    --status-no-bg: #fee2e2; --status-no-text: #991b1b;
    --status-hold-bg: #fef9c3; --status-hold-text: #854d0e;
}

body{ font-family:'Inter',sans-serif; background:var(--bg); margin:0; padding:25px; color:var(--text); }
.wrapper{ max-width:1450px; margin:auto; }

.card{ background:#fff; border-radius:12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow:hidden; border: 1px solid var(--border); margin-top:20px; }
table{ width:100%; border-collapse:collapse; }
th{ background:#f1f5f9; padding:16px; font-size:11px; text-transform:uppercase; color:#475569; border-bottom:1px solid var(--border); text-align: left; }
td{ padding:14px 16px; border-bottom:1px solid var(--border); font-size:13.5px; }

/* Status Styles */
tr.is-shortlisted { background-color: #f0fdf4; }
.status-pill { display: inline-flex; align-items: center; gap: 6px; padding: 5px 12px; border-radius: 9999px; font-size: 11px; font-weight: 700; }
.pill-yes { background: var(--status-yes-bg); color: var(--status-yes-text); }
.pill-no { background: var(--status-no-bg); color: var(--status-no-text); }
.pill-hold { background: var(--status-hold-bg); color: var(--status-hold-text); }

.btn-review{ background:var(--primary); color:#fff; border:none; padding:8px 16px; border-radius:6px; cursor:pointer; font-weight:600; transition:0.2s; }
.btn-review:hover{ opacity:0.9; transform:translateY(-1px); }

/* Modal */
.modal-overlay{ position:fixed; inset:0; background:rgba(15,23,42,0.6); display:none; align-items:center; justify-content:center; z-index:1000; backdrop-filter: blur(4px); }
.modal-content{ background:#fff; width:95%; max-width:900px; border-radius:16px; max-height:95vh; overflow-y:auto; padding:0; }
.modal-header{ padding:20px 25px; border-bottom:1px solid var(--border); display:flex; justify-content:space-between; align-items:center; position:sticky; top:0; background:#fff; z-index:10; }
.modal-body{ padding:25px; }
.grid-form{ display:grid; grid-template-columns: repeat(3, 1fr); gap:15px; }
.section-divider{ grid-column: span 3; color: var(--primary); font-weight: 700; font-size: 12px; text-transform: uppercase; border-bottom: 2px solid #eff6ff; padding-bottom: 5px; margin-top: 15px; }
.full-width{ grid-column: span 3; }
.form-group label { display:block; font-size:11px; font-weight:600; margin-bottom:4px; color:#64748b; }
.form-control { width:100%; padding:8px 10px; border:1px solid var(--border); border-radius:6px; font-size:13px; box-sizing:border-box; }
</style>
</head>

<body>

<div class="wrapper">
    <div style="display:flex; justify-content:space-between; align-items:center;">
        <h2>Candidate Recruitment Database</h2>
        <span style="color:#64748b;">Showing all records from Latest to Oldest</span>
    </div>

<%
List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
Set<String> uniquePosts = new TreeSet<>(); 

if(rawList != null && !rawList.isEmpty()){
    Map<String,List<Map<String,String>>> groupedData = new LinkedHashMap<>();
    for(Map<String,String> row : rawList){
        String post = row.get("post_applied_for");
        if(post == null || post.trim().isEmpty()) post = "Unspecified";
        uniquePosts.add(post); 
        groupedData.computeIfAbsent(post, k -> new ArrayList<>()).add(row);
    }

    for(String postName : groupedData.keySet()){
        List<Map<String,String>> candidates = groupedData.get(postName);
%>

<div class="post-container" style="margin-top:40px;">
    <h3 style="color:#334155;"><i class="fas fa-layer-group"></i> <%=postName%> (<%=candidates.size()%>)</h3>
    <div class="card">
        <table>
            <thead>
                <tr>
                    <th>Candidate</th>
                    <th>Mobile</th>
                    <th>Qualification</th>
                    <th>Exp.</th>
                    <th>Shortlisted</th>
                    <th>Interview Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
            <%
            for(Map<String,String> c : candidates){
                String sh = String.valueOf(c.get("shortlisted")).trim();
                String rowCls = sh.equalsIgnoreCase("Yes") ? "is-shortlisted" : "";
            %>
            <tr class="<%=rowCls%>">
                <td><strong><%=c.get("name")%></strong><br><small><%=c.get("gender")%> | <%=c.get("date_of_birth")%></small></td>
                <td><%=c.get("mobile_no")%></td>
                <td><%=c.get("qualification")%></td>
                <td><%=c.get("total_experience")%> Yrs</td>
                <td>
                    <% if(sh.equalsIgnoreCase("Yes")) { %>
                        <span class="status-pill pill-yes"><i class="fas fa-check"></i> Yes</span>
                    <% } else if(sh.equalsIgnoreCase("No")) { %>
                        <span class="status-pill pill-no"><i class="fas fa-times"></i> No</span>
                    <% } else { %>
                        <span class="status-pill pill-hold"><i class="fas fa-clock"></i> Pending</span>
                    <% } %>
                </td>
                <td><%=c.get("interview_status")%></td>
                <td>
                    <button class="btn-review" onclick='openModal(<%=new Gson().toJson(c)%>)'>
                        Full Profile
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
            <h3 style="margin:0;"><i class="fas fa-edit"></i> Edit Candidate Application</h3>
            <button onclick="closeModal()" style="border:none; background:none; font-size:24px; cursor:pointer;">&times;</button>
        </div>
        
        <form action="resume" method="post">
            <div class="modal-body">
                <input type="hidden" name="sl_no" id="f_sl_no">
                
                <div class="grid-form">
                    <div class="section-divider">1. Personal & Contact Information</div>
                    <div class="form-group">
                        <label>Full Name</label>
                        <input type="text" name="name" id="f_name" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Mobile Number</label>
                        <input type="text" name="mobile_no" id="f_mobile_no" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Gender</label>
                        <select name="gender" id="f_gender" class="form-control">
                            <option value="Male">Male</option><option value="Female">Female</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Date of Birth</label>
                        <input type="text" name="date_of_birth" id="f_date_of_birth" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Marital Status</label>
                        <input type="text" name="marital_status" id="f_marital_status" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Address</label>
                        <input type="text" name="address" id="f_address" class="form-control">
                    </div>

                    <div class="section-divider">2. Academic Details</div>
                    <div class="form-group">
                        <label>Highest Qualification</label>
                        <input type="text" name="qualification" id="f_qualification" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Specialization</label>
                        <input type="text" name="specialization" id="f_specialization" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Percentage / Marks</label>
                        <input type="text" name="percentage_marks" id="f_percentage_marks" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Year of Passing</label>
                        <input type="text" name="year_of_passing" id="f_year_of_passing" class="form-control">
                    </div>
                    <div class="form-group" style="grid-column: span 2;">
                        <label>Other Skills / Certifications</label>
                        <input type="text" name="other_skills_certifications" id="f_other_skills_certifications" class="form-control">
                    </div>

                    <div class="section-divider">3. Experience & Salary</div>
                    <div class="form-group">
                        <label>Total Experience</label>
                        <input type="text" name="total_experience" id="f_total_experience" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Relevant Experience</label>
                        <input type="text" name="relevant_experience" id="f_relevant_experience" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Company/Experience Detail</label>
                        <input type="text" name="experience" id="f_experience" class="form-control">
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
                        <select name="post_applied_for" id="f_post_applied_for" class="form-control">
                            <% for(String p : uniquePosts) { %>
                                <option value="<%= p %>"><%= p %></option>
                            <% } %>
                        </select>
                    </div>

                    <div class="section-divider">4. Recruitment Process Status</div>
                    <div class="form-group">
                        <label>Shortlisted Status</label>
                        <select name="shortlisted" id="f_shortlisted" class="form-control" style="background:#fff7ed; font-weight:bold;">
                            <option value="Pending">Pending</option>
                            <option value="Yes">Yes (Approved)</option>
                            <option value="No">No (Rejected)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Call Status</label>
                        <input type="text" name="call_status" id="f_call_status" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Demo Status</label>
                        <input type="text" name="demo_status" id="f_demo_status" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Demo Taken By</label>
                        <input type="text" name="demo_taken_by" id="f_demo_taken_by" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Interview Status</label>
                        <input type="text" name="interview_status" id="f_interview_status" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Interview Taken By</label>
                        <input type="text" name="interview_taken_by" id="f_interview_taken_by" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Reference By</label>
                        <input type="text" name="reference_by" id="f_reference_by" class="form-control">
                    </div>
                    <div class="form-group" style="grid-column: span 2;">
                        <label>General Remarks</label>
                        <textarea name="remarks" id="f_remarks" class="form-control" rows="2"></textarea>
                    </div>
                </div>
            </div>
            <div class="footer-actions" style="padding: 20px 25px; border-top: 1px solid #eee; text-align: right; background:#f8fafc;">
                <button type="button" onclick="closeModal()" style="padding:10px 20px; border:none; background:none; cursor:pointer;">Cancel</button>
                <button type="submit" class="btn-review" style="padding:10px 30px;">Save All Changes</button>
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