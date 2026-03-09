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
<title>RecruitPro | Workflow Intelligence</title>

<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

<style>
    :root {
        --primary: #4f46e5;
        --primary-soft: #eef2ff;
        --success: #10b981;
        --warning: #f59e0b;
        --danger: #ef4444;
        --surface: #ffffff;
        --background: #f8fafc;
        --border: #e2e8f0;
        --text-main: #0f172a;
        --text-muted: #64748b;
    }

    body { 
        background-color: var(--background); 
        font-family: 'Plus Jakarta Sans', sans-serif; 
        color: var(--text-main);
        margin: 0;
        line-height: 1.5;
    }

    .app-container { max-width: 1400px; margin: 0 auto; padding: 32px; }
    
    .header-flex {
        display: flex;
        justify-content: space-between;
        align-items: flex-end;
        margin-bottom: 32px;
    }

    .kpi-grid {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 24px;
        margin-bottom: 40px;
    }
    .kpi-card {
        background: var(--surface);
        padding: 24px;
        border-radius: 16px;
        border: 1px solid var(--border);
        box-shadow: 0 1px 3px rgba(0,0,0,0.02);
    }
    .kpi-card .label { font-size: 11px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1px; }
    .kpi-card .value { font-size: 32px; font-weight: 800; margin-top: 8px; }

    .table-container {
        background: var(--surface);
        border-radius: 20px;
        border: 1px solid var(--border);
        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
        overflow: hidden;
    }
    .table-header {
        padding: 20px 24px;
        background: #f1f5f9;
        border-bottom: 1px solid var(--border);
        font-weight: 700;
        color: var(--primary);
        display: flex;
        justify-content: space-between;
    }
    
    table { width: 100%; border-collapse: collapse; }
    th { padding: 16px 24px; font-size: 11px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; background: #fafafa; border-bottom: 1px solid var(--border); }
    td { padding: 18px 24px; border-bottom: 1px solid var(--border); font-size: 14px; }
    
    .pipeline-wrapper { display: flex; align-items: center; gap: 8px; }
    .step { width: 10px; height: 10px; border-radius: 50%; background: #e2e8f0; position: relative; }
    .step.completed { background: var(--success); }
    .step.active { background: var(--warning); box-shadow: 0 0 0 4px rgba(245, 158, 11, 0.2); }
    
    .row-hired { background: #f0fdf4 !important; }
    .row-hired td { border-bottom-color: #dcfce7; }

    .btn-action {
        padding: 8px 16px;
        border-radius: 8px;
        font-weight: 700;
        font-size: 12px;
        cursor: pointer;
        transition: all 0.2s;
        border: 1px solid var(--border);
        background: white;
        color: var(--text-main);
    }
    .btn-action:hover { background: var(--primary); color: white; border-color: var(--primary); }

    /* MODAL */
    .modal-overlay {
        display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(15, 23, 42, 0.6); backdrop-filter: blur(8px); z-index: 1000;
        align-items: center; justify-content: center;
    }
    .modal-card {
        background: white; width: 1100px; max-height: 95vh; border-radius: 24px;
        overflow: hidden; display: flex; flex-direction: column;
    }
    .modal-body { padding: 32px 40px; overflow-y: auto; display: grid; grid-template-columns: 1fr 340px; gap: 40px; }
    
    .workflow-section {
        background: var(--background);
        border-radius: 16px;
        padding: 20px;
        margin-bottom: 20px;
        border: 1px solid var(--border);
    }
    .workflow-tag {
        display: inline-block; padding: 4px 10px; border-radius: 6px; font-size: 10px; font-weight: 800;
        background: var(--primary-soft); color: var(--primary); margin-bottom: 12px; text-transform: uppercase;
    }
    
    .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
    .input-label { display: block; font-size: 11px; font-weight: 700; color: var(--text-muted); margin-bottom: 4px; text-transform: uppercase; }
    .input-field { 
        width: 100%; padding: 10px; border: 1px solid var(--border); border-radius: 8px; 
        font-size: 14px; box-sizing: border-box; font-family: inherit;
    }
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="app-container">
    <div class="header-flex">
        <div>
            <h1 style="margin:0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px;">Talent Acquisition Pipeline</h1>
            <p style="margin: 2px 0 0 0; color: var(--text-muted); font-size: 14px;">End-to-end recruitment lifecycle tracking</p>
        </div>
        <div style="background: white; padding: 8px 16px; border-radius: 12px; border: 1px solid var(--border); text-align: right;">
            <div style="font-size: 10px; font-weight: 700; color: var(--text-muted); text-transform: uppercase;">System Status</div>
            <div style="font-weight: 800; color: var(--success); font-size: 14px;">● LIVE 2026</div>
        </div>
    </div>

    <%
    List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
    int total = 0, shorted = 0, interviewDone = 0, hiredCount = 0;
    if(rawList != null){
        total = rawList.size();
        for(Map<String,String> c : rawList){
            if("Yes".equalsIgnoreCase(c.get("shortlisted"))) shorted++;
            if("Selected".equalsIgnoreCase(c.get("interview_status"))) interviewDone++;
            if("Hired".equalsIgnoreCase(c.get("Hired_status"))) hiredCount++;
        }
    }
    %>

    <div class="kpi-grid">
        <div class="kpi-card"><div class="label">Total Applied</div><div class="value"><%=total%></div></div>
        <div class="kpi-card"><div class="label">Shortlisted</div><div class="value" style="color:var(--warning)"><%=shorted%></div></div>
        <div class="kpi-card"><div class="label">Interview Passed</div><div class="value" style="color:var(--primary)"><%=interviewDone%></div></div>
        <div class="kpi-card"><div class="label">Hired</div><div class="value" style="color:var(--success)"><%=hiredCount%></div></div>
    </div>

    <%
    if(rawList != null && !rawList.isEmpty()){
        Map<String,List<Map<String,String>>> grouped = new LinkedHashMap<>();
        for(Map<String,String> row : rawList){
            String post = row.get("post_applied_for");
            if(post == null || post.trim().isEmpty()) post = "General Pipeline";
            grouped.computeIfAbsent(post, k-> new ArrayList<>()).add(row);
        }

        for(String post : grouped.keySet()){
            List<Map<String,String>> candidates = grouped.get(post);
    %>
    <div class="table-container" style="margin-bottom: 32px;">
        <div class="table-header">
            <span><%=post.toUpperCase()%></span>
            <span style="font-size: 12px; opacity: 0.7;"><%=candidates.size()%> PROFILES</span>
        </div>
        <table>
            <thead>
                <tr>
                    <th style="width:280px">Candidate Detail</th>
                    <th>Progress Pipeline</th>
                    <th>Experience</th>
                    <th>HR Verdict</th>
                    <th>Hired Status</th>
                    <th style="text-align:right">Management</th>
                </tr>
            </thead>
            <tbody>
            <% 
            for(Map<String,String> c : candidates){
                boolean isShort = "Yes".equalsIgnoreCase(c.get("shortlisted"));
                boolean isDemo = c.get("demo_status") != null && !c.get("demo_status").isEmpty() && !"Pending".equalsIgnoreCase(c.get("demo_status"));
                boolean isInt = "Selected".equalsIgnoreCase(c.get("interview_status"));
                boolean isHired = "Hired".equalsIgnoreCase(c.get("Hired_status"));
                
                String json = gson.toJson(c).replace("&","&amp;").replace("\"","&quot;");
            %>
                <tr class="<%= isHired ? "row-hired" : "" %>">
                    <td>
                        <div style="font-weight: 700; color: var(--text-main);"><%=c.get("name")%></div>
                        <div style="font-size: 12px; color: var(--text-muted)"><%=c.get("mobile_no")%> | <%=c.get("qualification")%></div>
                    </td>
                    <td>
                        <div class="pipeline-wrapper">
                            <div class="step <%= isShort ? "completed" : "active" %>" title="Shortlist"></div>
                            <div style="width:15px; height:2px; background:#e2e8f0"></div>
                            <div class="step <%= isDemo ? "completed" : (isShort ? "active" : "") %>" title="Demo"></div>
                            <div style="width:15px; height:2px; background:#e2e8f0"></div>
                            <div class="step <%= isInt ? "completed" : (isDemo ? "active" : "") %>" title="Interview"></div>
                            <div style="width:15px; height:2px; background:#e2e8f0"></div>
                            <div class="step <%= isHired ? "completed" : (isInt ? "active" : "") %>" title="Hire"></div>
                        </div>
                    </td>
                    <td><span style="font-weight: 600"><%=c.get("total_experience")%> Yrs</span></td>
                    <td>
                        <span style="font-size: 11px; font-weight: 800; color: <%= isInt ? "var(--success)" : "var(--text-muted)" %>">
                            <%= (c.get("interview_status") == null || c.get("interview_status").isEmpty()) ? "PENDING" : c.get("interview_status").toUpperCase() %>
                        </span>
                    </td>
                    <td>
                        <% if(isHired){ %>
                            <span style="background: var(--success); color: white; padding: 2px 8px; border-radius: 4px; font-size: 10px; font-weight: 800;">HIRED</span>
                        <% } else { %>
                            <span style="color: var(--text-muted); font-size: 12px;"><%=c.get("Hired_status")%></span>
                        <% } %>
                    </td>
                    <td style="text-align:right">
                        <button class="btn-action reviewBtn" data-candidate="<%=json%>">OPEN DOSSIER</button>
                    </td>
                </tr>
            <% } %>
            </tbody>
        </table>
    </div>
    <% } } %>
</div>

<div class="modal-overlay" id="editModal">
    <div class="modal-card">
        <div style="padding: 20px 40px; background: var(--text-main); color: white; display:flex; justify-content:space-between; align-items:center;">
            <div>
                <div style="font-size: 10px; font-weight: 700; opacity: 0.6; text-transform: uppercase; letter-spacing: 1px;">Candidate Data Management</div>
                <h2 id="modal_name_display" style="margin:0; font-size: 22px; font-weight: 800; color: #fff;">---</h2>
            </div>
            <button onclick="closeModal()" style="background:none; border:none; color:white; font-size:32px; cursor:pointer; line-height: 1;">&times;</button>
        </div>

        <form action="resume" method="post" id="updateForm" style="flex:1; overflow:hidden; display:flex; flex-direction:column;">
            <div class="modal-body">
                <div>
                    <input type="hidden" name="sl_no" id="f_sl_no">
                    <input type="hidden" name="name" id="f_name">
                    <input type="hidden" name="mobile_no" id="f_mobile_no">
                    <input type="hidden" name="address" id="f_address">
                    <input type="hidden" name="post_applied_for" id="f_post_applied_for">
                    <input type="hidden" name="gender" id="f_gender">
                    <input type="hidden" name="date_of_birth" id="f_date_of_birth">
                    <input type="hidden" name="marital_status" id="f_marital_status">
                    <input type="hidden" name="qualification" id="f_qualification">
                    <input type="hidden" name="specialization" id="f_specialization">
                    <input type="hidden" name="percentage_marks" id="f_percentage_marks">
                    <input type="hidden" name="year_of_passing" id="f_year_of_passing">
                    <input type="hidden" name="reference_by" id="f_reference_by">
                    <input type="hidden" name="other_skills_certifications" id="f_other_skills_certifications">
                    <input type="hidden" name="experience" id="f_experience">
                    <input type="hidden" name="relevant_experience" id="f_relevant_experience">
                    <input type="hidden" name="total_experience" id="f_total_experience">
                    <input type="hidden" name="present_salary" id="f_present_salary">
                    <input type="hidden" name="expected_salary" id="f_expected_salary">

                    <div class="workflow-section">
                        <span class="workflow-tag">Phase 1: Shortlisting</span>
                        <div class="form-grid">
                            <div class="field-group">
                                <label class="input-label">Initial Shortlist</label>
                                <select name="shortlisted" id="f_shortlisted" class="input-field">
                                    <option value="Pending">Pending</option>
                                    <option value="Yes">Selected for Demo</option>
                                    <option value="No">Rejected</option>
                                </select>
                            </div>
                            <div class="field-group">
                                <label class="input-label">Call Status</label>
                                <input type="text" name="call_status" id="f_call_status" class="input-field" placeholder="e.g. Call scheduled">
                            </div>
                        </div>
                    </div>

                    <div class="workflow-section">
                        <span class="workflow-tag">Phase 2: Demo Session</span>
                        <div class="form-grid">
                            <div class="field-group">
                                <label class="input-label">Demo Date</label>
                                <input type="date" name="demo_date" id="f_demo_date" class="input-field">
                            </div>
                            <div class="field-group">
                                <label class="input-label">Demo Taken By</label>
                                <input type="text" name="demo_taken_by" id="f_demo_taken_by" class="input-field">
                            </div>
                            <div class="field-group" style="grid-column: span 2;">
                                <label class="input-label">Demo Result/Remarks</label>
                                <input type="text" name="demo_status" id="f_demo_status" class="input-field" placeholder="e.g. Excellent / Cleared">
                            </div>
                        </div>
                    </div>

                    <div class="workflow-section">
                        <span class="workflow-tag">Phase 3: Final Interview</span>
                        <div class="form-grid">
                            <div class="field-group">
                                <label class="input-label">Interview Date</label>
                                <input type="date" name="interview_date" id="f_interview_date" class="input-field">
                            </div>
                            <div class="field-group">
                                <label class="input-label">Interview Taken By</label>
                                <input type="text" name="interview_taken_by" id="f_interview_taken_by" class="input-field">
                            </div>
                            <div class="field-group" style="grid-column: span 2;">
                                <label class="input-label">Final Interview Verdict</label>
                                <select name="interview_status" id="f_interview_status" class="input-field">
                                    <option value="Pending">Awaiting Result</option>
                                    <option value="Selected">Selected</option>
                                    <option value="Rejected">Rejected</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>

                <div style="background: #f1f5f9; padding: 24px; border-radius: 20px; border: 1px solid var(--border); height: fit-content;">
                    <div class="workflow-tag" style="background:var(--text-main); color:white;">Final Decision</div>
                    
                    <div class="field-group" style="margin-bottom: 20px;">
                        <label class="input-label">Official Hire Status</label>
                        <select name="Hired_status" id="f_Hired_status" class="input-field" style="border-color:var(--primary); font-weight:800; color:var(--primary); height: 45px;">
                            <option value="Pipeline">In Pipeline</option>
                            <option value="Hired">CONFIRM HIRE</option>
                            <option value="Hold">On Hold</option>
                            <option value="Rejected">Not Hired</option>
                        </select>
                    </div>
                    
                    <div class="field-group">
                        <label class="input-label">Decision Remarks</label>
                        <textarea name="remarks" id="f_remarks" class="input-field" style="height: 120px; resize: none;"></textarea>
                    </div>

                    <button type="submit" style="width:100%; margin-top:24px; padding:16px; background:var(--primary); color:white; border:none; border-radius:12px; font-weight:800; cursor:pointer; font-size: 14px; transition: transform 0.2s;">
                        SAVE & UPDATE
                    </button>
                </div>
            </div>
        </form>
    </div>
</div>

<script>
document.querySelectorAll(".reviewBtn").forEach(btn => {
    btn.addEventListener("click", function() {
        // Parse the JSON data from the data-candidate attribute
        const data = JSON.parse(this.dataset.candidate);
        
        // Explicitly set the name in the header
        document.getElementById("modal_name_display").innerText = data.name || "Unknown Candidate";
        
        // Loop through all data keys and fill inputs with id "f_[key]"
        Object.keys(data).forEach(key => {
            const el = document.getElementById("f_" + key);
            if (el) {
                if(el.type === 'date' && data[key]) {
                    // Extract YYYY-MM-DD from timestamp if needed
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

// Close modal when clicking background
window.onclick = function(event) {
    let modal = document.getElementById("editModal");
    if (event.target == modal) {
        closeModal();
    }
}
</script>

</body>
</html>