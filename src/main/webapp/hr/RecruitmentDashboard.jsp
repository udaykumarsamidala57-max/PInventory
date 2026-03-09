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
<title>RecruitPro Elite | 2026-27</title>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Recruitment.css?v=16">

<style>
    :root {
        --glass-bg: rgba(255, 255, 255, 0.95);
        --hired-green: #059669;
        --interview-blue: #2563eb;
        --reject-red: #e11d48;
    }

    body { background-color: #f1f5f9; font-family: 'Inter', sans-serif; }

    /* --- INTELLIGENT HIGHLIGHTING --- */
    .row-hired { 
        background: linear-gradient(90deg, #f0fdf4 0%, #ffffff 100%) !important;
        border-left: 8px solid var(--hired-green) !important;
        box-shadow: inset 0 0 10px rgba(5, 150, 105, 0.1);
    }
    .row-hired b { color: var(--hired-green); }

    .row-final-selected { 
        background: linear-gradient(90deg, #eff6ff 0%, #ffffff 100%) !important;
        border-left: 8px solid var(--interview-blue) !important;
    }

    .row-rejected { 
        background-color: #fff1f2 !important; 
        opacity: 0.7;
        filter: grayscale(0.4);
    }

    /* --- KPI CARDS REIMAGINED --- */
    .kpi-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 25px; margin-bottom: 35px; }
    .kpi-card { 
        padding: 25px; border-radius: 16px; background: white; 
        box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05);
        transition: transform 0.2s;
        position: relative; overflow: hidden;
    }
    .kpi-card:hover { transform: translateY(-5px); }
    .kpi-card::after { content: ""; position: absolute; top: 0; left: 0; width: 5px; height: 100%; }
    .kpi-card.total::after { background: #6366f1; }
    .kpi-card.short::after { background: #f59e0b; }
    .kpi-card.final::after { background: #10b981; }

    /* --- TABLE STYLING --- */
    .table-wrapper { border-radius: 12px; overflow: hidden; background: white; box-shadow: 0 4px 6px rgba(0,0,0,0.02); }
    table { width: 100%; border-collapse: collapse; }
    th { background: #f8fafc; padding: 16px; font-size: 12px; text-transform: uppercase; color: #64748b; letter-spacing: 0.05em; }
    td { padding: 16px; border-bottom: 1px solid #f1f5f9; vertical-align: middle; }
    
    .badge { 
        padding: 6px 12px; border-radius: 9999px; font-size: 11px; font-weight: 700; 
        display: inline-flex; align-items: center; gap: 4px;
    }
    .badge-hired { background: #dcfce7; color: #166534; border: 1px solid #bbf7d0; }
    .badge-process { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; }

    /* --- MODAL DESIGN --- */
    .modal-content { border-radius: 24px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); border:none; }
    .section-title { 
        border-left: 4px solid #4f46e5; background: #f8fafc; 
        padding: 10px 15px; margin: 20px 0 10px 0; font-size: 13px;
    }
    .modal-form input:focus, .modal-form select:focus {
        border-color: #4f46e5; outline: none; ring: 2px rgba(79, 70, 229, 0.2);
    }
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="main-container" style="max-width: 1400px; margin: 0 auto; padding: 20px;">

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
    <div class="kpi-card total">
        <span style="color:#64748b; font-size: 14px; font-weight: 600;">Active Applications</span>
        <div class="kpi-number" style="font-size: 36px; font-weight: 800; color:#1e293b;"><%=total%></div>
    </div>
    <div class="kpi-card short">
        <span style="color:#64748b; font-size: 14px; font-weight: 600;">Shortlisted Talents</span>
        <div class="kpi-number" style="font-size: 36px; font-weight: 800; color:#d97706;"><%=shorted%></div>
    </div>
    <div class="kpi-card final">
        <span style="color:#64748b; font-size: 14px; font-weight: 600;">Successful Hires</span>
        <div class="kpi-number" style="font-size: 36px; font-weight: 800; color:#059669;"><%=hiredCount%></div>
    </div>
</div>

<%
if(rawList != null && !rawList.isEmpty()){
    Map<String,List<Map<String,String>>> grouped = new LinkedHashMap<>();
    for(Map<String,String> row : rawList){
        String post = row.get("post_applied_for");
        if(post == null || post.trim().isEmpty()) post = "General Positions";
        grouped.computeIfAbsent(post, k-> new ArrayList<>()).add(row);
    }

    for(String post : grouped.keySet()){
        List<Map<String,String>> candidates = grouped.get(post);
%>

<div class="section" style="margin-bottom: 40px;">
    <div class="section-header" style="display: flex; align-items: center; gap: 15px; margin-bottom: 15px;">
        <h2 style="font-size: 20px; font-weight: 800; color: #1e293b; margin: 0;"><%=post%></h2>
        <span style="background: #e2e8f0; padding: 4px 12px; border-radius: 8px; font-size: 12px; font-weight: 700;"><%=candidates.size()%> Candidates</span>
    </div>

    <div class="table-wrapper">
        <table>
            <thead>
                <tr>
                    <th style="width: 25%;">Candidate Detail</th>
                    <th>Experience</th>
                    <th>Shortlist</th>
                    <th>Demo Status</th>
                    <th>Interview</th>
                    <th>Employment</th>
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
                else if("No".equalsIgnoreCase(sStat) || "Rejected".equalsIgnoreCase(iStat) || "Rejected".equalsIgnoreCase(dStat)) highlightClass = "row-rejected";

                String json = gson.toJson(c).replace("&","&amp;").replace("\"","&quot;").replace("<","&lt;").replace(">","&gt;");
            %>
                <tr class="<%=highlightClass%>">
                    <td>
                        <div style="font-weight: 700; color: #1e293b; font-size: 15px;"><%=c.get("name")%></div>
                        <div style="font-size: 12px; color: #64748b; margin-top: 2px;">
                            <span style="background:#f1f5f9; padding:2px 6px; border-radius:4px; margin-right:5px;"><%=c.get("mobile_no")%></span>
                            <%=c.get("qualification")%>
                        </div>
                    </td>
                    <td><b style="font-size: 14px;"><%=c.get("total_experience")%> Yrs</b></td>
                    
                    <td><span class="badge <%= "Yes".equalsIgnoreCase(sStat) ? "badge-success" : "badge-warning" %>"><%=sStat%></span></td>
                    <td><span class="badge badge-info" style="background:#e0f2fe; color:#0369a1;"><%=dStat == null ? "Pending" : dStat%></span></td>
                    <td><span class="badge <%= "Selected".equalsIgnoreCase(iStat) ? "badge-success" : "badge-dark" %>"><%=iStat%></span></td>
                    
                    <td>
                        <% if("Hired".equalsIgnoreCase(hStat)){ %>
                            <span class="badge badge-hired">✔ HIRED</span>
                        <% } else { %>
                            <span class="badge badge-process"><%=hStat == null ? "Pipeline" : hStat%></span>
                        <% } %>
                    </td>

                    <td>
                        <button class="reviewBtn" data-candidate="<%=json%>" 
                                style="background: linear-gradient(135deg, #4f46e5 0%, #3730a3 100%); color: white; border: none; padding: 10px 18px; border-radius: 10px; font-weight: 600; cursor: pointer; transition: all 0.2s;">
                            MANAGE
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

<div class="modal" id="editModal" style="display: none; align-items: center; justify-content: center; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(15, 23, 42, 0.85); z-index: 1000; backdrop-filter: blur(8px);">
    <div class="modal-content" style="background: white; width: 1100px; max-height: 95vh; overflow-y: auto;">
        <div style="padding: 25px; background: #1e293b; color: white; display: flex; justify-content: space-between; align-items: center;">
            <div>
                <h2 style="margin:0; font-size: 1.5rem; font-weight: 800;">Candidate Master File</h2>
                <p style="margin: 5px 0 0 0; font-size: 12px; color: #94a3b8; letter-spacing: 1px;">ID: <span id="display_sl_no">---</span> | SYSTEM UPDATE 2026</p>
            </div>
            <button onclick="closeModal()" style="color:#94a3b8; background:none; border:none; font-size:32px; cursor:pointer;">&times;</button>
        </div>

        <form action="resume" method="post" class="modal-form" style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; padding: 30px;">
            <input type="hidden" name="sl_no" id="f_sl_no">

            <div class="section-title full-width" style="margin-top:0">PERSONAL ARCHIVE</div>
            <div><label>Full Name</label><input type="text" name="name" id="f_name" style="width:100%"></div>
            <div><label>Phone Number</label><input type="text" name="mobile_no" id="f_mobile_no" style="width:100%"></div>
            <div><label>Application ID / Resume No</label><input type="text" name="resume_no" id="f_resume_no" style="width:100%"></div>
            
            <div class="half-width"><label>Current Address</label><input type="text" name="address" id="f_address" style="width:100%"></div>
            <div><label>Position Target</label><input type="text" name="post_applied_for" id="f_post_applied_for" style="width:100%"></div>

            <div><label>Gender</label><input type="text" name="gender" id="f_gender" style="width:100%"></div>
            <div><label>Date of Birth</label><input type="text" name="date_of_birth" id="f_date_of_birth" style="width:100%"></div>
            <div><label>Marital Status</label><input type="text" name="marital_status" id="f_marital_status" style="width:100%"></div>

            <div class="section-title full-width">EDUCATION & EXPERTISE</div>
            <div><label>Highest Qualification</label><input type="text" name="qualification" id="f_qualification" style="width:100%"></div>
            <div><label>Stream / Specialization</label><input type="text" name="specialization" id="f_specialization" style="width:100%"></div>
            <div><label>Year of Passing</label><input type="text" name="year_of_passing" id="f_year_of_passing" style="width:100%"></div>
            <div><label>Score (%)</label><input type="text" name="percentage_marks" id="f_percentage_marks" style="width:100%"></div>
            <div class="half-width"><label>Key Certifications</label><input type="text" name="other_skills_certifications" id="f_other_skills_certifications" style="width:100%"></div>

            <div class="section-title full-width">PROFESSIONAL TRACK & COMPENSATION</div>
            <div><label>Total Experience (Yrs)</label><input type="text" name="total_experience" id="f_total_experience" style="width:100%; font-weight:700;"></div>
            <div><label>Relevant Experience</label><input type="text" name="relevant_experience" id="f_relevant_experience" style="width:100%"></div>
            <div><label>Referred By</label><input type="text" name="reference_by" id="f_reference_by" style="width:100%"></div>
            
            <div><label>Current CTC</label><input type="text" name="present_salary" id="f_present_salary" style="width:100%"></div>
            <div><label>Expected CTC</label><input type="text" name="expected_salary" id="f_expected_salary" style="width:100%; color: #4f46e5; font-weight: 700;"></div>
            <div><label>File Created Date</label><input type="text" id="f_created_at" readonly style="background:#f8fafc; color:#94a3b8; width:100%"></div>
            
            <div class="full-width"><label>Prior Experience Summary</label><textarea name="experience" id="f_experience" style="width:100%; height:60px;"></textarea></div>

            <div class="section-title full-width" style="border-left-color: #e11d48; color: #e11d48;">RECRUITMENT STAGES & VERDICT</div>
            
            <div>
                <label>1. Initial Shortlist</label>
                <select name="shortlisted" id="f_shortlisted" style="width:100%; background: #fffbeb;">
                    <option value="No">Rejected</option>
                    <option value="Yes">Qualified</option>
                    <option value="Pending">Under Review</option>
                </select>
            </div>
            <div><label>Call Status</label><input type="text" name="call_status" id="f_call_status" style="width:100%" placeholder="e.g. Called/Interested"></div>
            <div><label>Reporting Date</label><input type="date" name="attending_date" id="f_attending_date" style="width:100%"></div>

            <div><label>2. Demo Scheduled</label><input type="date" name="demo_date" id="f_demo_date" style="width:100%"></div>
            <div><label>Demo Outcome</label><input type="text" name="demo_status" id="f_demo_status" style="width:100%" placeholder="Pending/Selected"></div>
            <div><label>Demo Assessor</label><input type="text" name="demo_taken_by" id="f_demo_taken_by" style="width:100%"></div>
            
            <div class="full-width"><label>Demo Feedback Notes</label><textarea name="demo_remarks" id="f_demo_remarks" style="width:100%; height:40px;"></textarea></div>

            <div><label>3. Final Interview</label><input type="date" name="interview_date" id="f_interview_date" style="width:100%"></div>
            <div><label>Interview Outcome</label><input type="text" name="interview_status" id="f_interview_status" style="width:100%" placeholder="Pending/Selected"></div>
            <div><label>Panel Lead</label><input type="text" name="interview_taken_by" id="f_interview_taken_by" style="width:100%"></div>

            <div style="background:#f0fdf4; padding:10px; border-radius:12px; grid-column: span 1; border: 2px solid #10b981;">
                <label style="color:#065f46; font-weight: 800;">FINAL HIRED STATUS</label>
                <select name="Hired_status" id="f_Hired_status" style="width:100%; font-weight:800; color:#10b981;">
                    <option value="On Process">Pipeline</option>
                    <option value="Hired">CONFIRMED HIRE</option>
                    <option value="Hold">On Hold</option>
                    <option value="Rejected">Not Hired</option>
                </select>
            </div>
            <div class="half-width"><label>Final Decision Remarks</label><textarea name="remarks" id="f_remarks" style="width:100%; height:52px; border-color:#cbd5e1;"></textarea></div>

            <div class="full-width" style="display: flex; justify-content: flex-end; gap: 15px; border-top: 1px solid #e2e8f0; padding-top: 25px; margin-top: 10px;">
                <button type="button" onclick="closeModal()" class="btn-light" style="padding: 14px 30px; border-radius: 12px; cursor:pointer;">Discard</button>
                <button type="submit" class="btn-primary" style="padding: 14px 60px; border-radius: 12px; background: #4f46e5; color:white; border:none; font-weight:800; cursor:pointer; box-shadow: 0 4px 14px rgba(79, 70, 229, 0.4);">
                    COMMIT ALL CHANGES
                </button>
            </div>
        </form>
    </div>
</div>

<script>
document.querySelectorAll(".reviewBtn").forEach(btn => {
    btn.addEventListener("click", function() {
        const data = JSON.parse(this.dataset.candidate);
        document.getElementById("display_sl_no").innerText = data.sl_no;
        
        Object.keys(data).forEach(key => {
            const el = document.getElementById("f_" + key);
            if (el) {
                if(el.type === 'date' && data[key]) {
                    el.value = data[key].split(' ')[0];
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