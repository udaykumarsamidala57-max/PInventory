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
<title>RecruitPro Enterprise | workflow Intelligence</title>

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

    .app-container { max-width: 1440px; margin: 0 auto; padding: 32px; }
    
    .header-flex {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 32px;
    }

    /* KPI CARDS */
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
        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.02);
    }
    .kpi-card .label { font-size: 11px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1px; }
    .kpi-card .value { font-size: 32px; font-weight: 800; margin-top: 8px; }

    /* TABLE */
    .table-container {
        background: var(--surface);
        border-radius: 20px;
        border: 1px solid var(--border);
        box-shadow: 0 10px 15px -3px rgba(0,0,0,0.04);
        overflow: hidden;
    }
    .table-header {
        padding: 20px 24px;
        background: #f1f5f9;
        border-bottom: 1px solid var(--border);
        font-weight: 800;
        color: var(--primary);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }
    
    table { width: 100%; border-collapse: collapse; }
    th { padding: 16px 24px; font-size: 11px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; background: #fafafa; border-bottom: 1px solid var(--border); }
    td { padding: 18px 24px; border-bottom: 1px solid var(--border); font-size: 14px; }
    
    /* HIGHLIGHTED ROW FOR HIRED */
    .row-hired { background-color: #f0fdf4 !important; }
    .name-highlight-hired { 
        color: var(--success); 
        display: flex; 
        align-items: center; 
        gap: 8px; 
        font-weight: 800 !important;
    }

    .pipeline-wrapper { display: flex; align-items: center; gap: 6px; }
    .step { width: 10px; height: 10px; border-radius: 50%; background: #e2e8f0; transition: 0.3s; }
    .step.completed { background: var(--success); }
    .step.active { background: var(--warning); box-shadow: 0 0 0 4px rgba(245, 158, 11, 0.2); }

    .btn-action {
        padding: 8px 16px;
        border-radius: 8px;
        font-weight: 700;
        font-size: 12px;
        cursor: pointer;
        transition: all 0.2s;
        border: 1px solid var(--border);
        background: white;
    }
    .btn-action:hover { background: var(--primary); color: white; border-color: var(--primary); }

    /* MODAL */
    .modal-overlay {
        display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(15, 23, 42, 0.7); backdrop-filter: blur(8px); z-index: 1000;
        align-items: center; justify-content: center;
    }
    .modal-card {
        background: white; width: 1200px; max-height: 95vh; border-radius: 24px;
        overflow: hidden; display: flex; flex-direction: column;
    }
    .modal-body { padding: 32px 40px; overflow-y: auto; display: grid; grid-template-columns: 2fr 1fr; gap: 40px; }
    
    .workflow-section {
        background: var(--background);
        border-radius: 16px;
        padding: 24px;
        margin-bottom: 24px;
        border: 1px solid var(--border);
    }
    .section-title { font-size: 14px; font-weight: 800; margin-bottom: 16px; display: flex; align-items: center; gap: 10px; color: var(--text-main); }
    .section-title span { background: var(--primary); color: white; padding: 2px 8px; border-radius: 4px; font-size: 10px; }

    .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
    .input-label { display: block; font-size: 10px; font-weight: 700; color: var(--text-muted); margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.5px; }
    .input-field { 
        width: 100%; padding: 10px 14px; border: 1px solid var(--border); border-radius: 8px; 
        font-size: 13px; box-sizing: border-box; font-family: inherit; transition: 0.2s;
    }
    .input-field:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 4px var(--primary-soft); }
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="app-container">
    <div class="header-flex">
        <div>
            <h1 style="margin:0; font-size: 32px; font-weight: 800; letter-spacing: -1px;">Recruitment Pipeline</h1>
            <p style="margin: 4px 0 0 0; color: var(--text-muted);">Shortlist → Demo → Interview → Hire</p>
        </div>
        <div style="font-size: 12px; font-weight: 700; color: var(--text-muted); background: white; padding: 10px 20px; border-radius: 100px; border: 1px solid var(--border);">
            SYSTEM SESSION: 2026-27
        </div>
    </div>

    <%
    List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
    int total = 0, shorted = 0, demoed = 0, hiredCount = 0;
    if(rawList != null){
        total = rawList.size();
        for(Map<String,String> c : rawList){
            if("Yes".equalsIgnoreCase(c.get("shortlisted"))) shorted++;
            if(c.get("demo_status") != null && !c.get("demo_status").isEmpty()) demoed++;
            if("Hired".equalsIgnoreCase(c.get("Hired_status"))) hiredCount++;
        }
    }
    %>

    <div class="kpi-grid">
        <div class="kpi-card"><div class="label">Total Applications</div><div class="value"><%=total%></div></div>
        <div class="kpi-card"><div class="label">Shortlisted</div><div class="value" style="color:var(--warning)"><%=shorted%></div></div>
        <div class="kpi-card"><div class="label">In Interview</div><div class="value" style="color:var(--primary)"><%=demoed%></div></div>
        <div class="kpi-card"><div class="label">Confirmed Hires</div><div class="value" style="color:var(--success)"><%=hiredCount%></div></div>
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
    <div class="table-container" style="margin-bottom: 40px;">
        <div class="table-header">
            <span><%=post.toUpperCase()%></span>
            <span style="font-size: 12px; color: var(--text-muted); font-weight: 600;"><%=candidates.size()%> PROFILES</span>
        </div>
        <table>
            <thead>
                <tr>
                    <th style="width:280px">Candidate</th>
                    <th>Lifecycle</th>
                    <th>Experience</th>
                    <th>Final Verdict</th>
                    <th style="text-align:right">Dossier</th>
                </tr>
            </thead>
            <tbody>
            <% 
            for(Map<String,String> c : candidates){
                boolean isShort = "Yes".equalsIgnoreCase(c.get("shortlisted"));
                boolean isDemo = c.get("demo_status") != null && !c.get("demo_status").isEmpty();
                boolean isInt = "Selected".equalsIgnoreCase(c.get("interview_status"));
                boolean isHired = "Hired".equalsIgnoreCase(c.get("Hired_status"));
                String json = gson.toJson(c).replace("&","&amp;").replace("\"","&quot;");
            %>
                <tr class="<%= isHired ? "row-hired" : "" %>">
                    <td>
                        <div class="<%= isHired ? "name-highlight-hired" : "" %>" style="font-weight: 800;">
                            <%= isHired ? "★ " + c.get("name") : c.get("name") %>
                        </div>
                        <div style="font-size: 12px; color: var(--text-muted)"><%=c.get("mobile_no")%></div>
                    </td>
                    <td>
                        <div class="pipeline-wrapper">
                            <div class="step <%= isShort ? "completed" : "active" %>" title="Shortlisted"></div>
                            <div style="width:15px; height:1px; background:#cbd5e1"></div>
                            <div class="step <%= isDemo ? "completed" : (isShort ? "active" : "") %>" title="Demo Done"></div>
                            <div style="width:15px; height:1px; background:#cbd5e1"></div>
                            <div class="step <%= isInt ? "completed" : (isDemo ? "active" : "") %>" title="Interview Cleared"></div>
                            <div style="width:15px; height:1px; background:#cbd5e1"></div>
                            <div class="step <%= isHired ? "completed" : (isInt ? "active" : "") %>" title="Hired"></div>
                        </div>
                    </td>
                    <td><span style="font-weight: 700"><%=c.get("total_experience")%> Yrs</span></td>
                    <td>
                        <% if(isHired){ %>
                            <span style="color: var(--success); font-weight: 800; font-size: 12px;">HIRED</span>
                        <% } else { %>
                            <span style="color: var(--text-muted); font-size: 12px; font-weight: 600;"><%=c.get("Hired_status")%></span>
                        <% } %>
                    </td>
                    <td style="text-align:right">
                        <button class="btn-action reviewBtn" data-candidate="<%=json%>">Edit Profile</button>
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
        <div style="padding: 24px 40px; background: var(--text-main); color: white; display:flex; justify-content:space-between; align-items:center;">
            <div>
                <div style="font-size: 11px; font-weight: 700; opacity: 0.6; text-transform: uppercase;">Edit Candidate Dossier</div>
                <h2 id="modal_name" style="margin:0; font-size: 24px; font-weight: 800;">Candidate Name</h2>
            </div>
            <button onclick="closeModal()" style="background:none; border:none; color:white; font-size:32px; cursor:pointer;">&times;</button>
        </div>

        <form action="resume" method="post" style="flex:1; overflow:hidden; display:flex; flex-direction:column;">
            <div class="modal-body">
                <div>
                    <div class="workflow-section">
                        <div class="section-title"><span>1</span> Personal Details</div>
                        <input type="hidden" name="sl_no" id="f_sl_no">
                        <div class="form-grid">
                            <div class="field-group">
                                <label class="input-label">Full Name</label>
                                <input type="text" name="name" id="f_name" class="input-field">
                            </div>
                            <div class="field-group">
                                <label class="input-label">Mobile Number</label>
                                <input type="text" name="mobile_no" id="f_mobile_no" class="input-field">
                            </div>
                            <div class="field-group" style="grid-column: span 2;">
                                <label class="input-label">Address</label>
                                <input type="text" name="address" id="f_address" class="input-field">
                            </div>
                        </div>
                    </div>

                    <div class="workflow-section">
                        <div class="section-title"><span>2</span> Qualification & Position</div>
                        <div class="form-grid">
                            <div class="field-group">
                                <label class="input-label">Post Applied For</label>
                                <input type="text" name="post_applied_for" id="f_post_applied_for" class="input-field">
                            </div>
                            <div class="field-group">
                                <label class="input-label">Qualification</label>
                                <input type="text" name="qualification" id="f_qualification" class="input-field">
                            </div>
                            <div class="field-group">
                                <label class="input-label">Specialization</label>
                                <input type="text" name="specialization" id="f_specialization" class="input-field">
                            </div>
                            <div class="field-group">
                                <label class="input-label">Total Experience (Years)</label>
                                <input type="text" name="total_experience" id="f_total_experience" class="input-field">
                            </div>
                        </div>
                    </div>

                    <div class="workflow-section">
                        <div class="section-title"><span>3</span> Selection Workflow</div>
                        <div class="form-grid">
                            <div class="field-group">
                                <label class="input-label">Shortlisted?</label>
                                <select name="shortlisted" id="f_shortlisted" class="input-field">
                                    <option value="Pending">Pending</option>
                                    <option value="Yes">Yes</option>
                                    <option value="No">No</option>
                                </select>
                            </div>
                            <div class="field-group">
                                <label class="input-label">Demo Status</label>
                                <input type="text" name="demo_status" id="f_demo_status" class="input-field" placeholder="Result/Score">
                            </div>
                            <div class="field-group">
                                <label class="input-label">Interview Status</label>
                                <select name="interview_status" id="f_interview_status" class="input-field">
                                    <option value="Pending">Waiting</option>
                                    <option value="Selected">Selected</option>
                                    <option value="Rejected">Rejected</option>
                                </select>
                            </div>
                            <div class="field-group">
                                <label class="input-label">Interview Taken By</label>
                                <input type="text" name="interview_taken_by" id="f_interview_taken_by" class="input-field">
                            </div>
                        </div>
                    </div>
                </div>

                <div>
                    <div style="background: var(--primary-soft); padding: 32px; border-radius: 20px; border: 1px solid var(--primary); position: sticky; top: 0;">
                        <div class="section-title" style="color: var(--primary);">FINAL HIRING VERDICT</div>
                        
                        <div class="field-group" style="margin-bottom: 24px;">
                            <label class="input-label">Official Status</label>
                            <select name="Hired_status" id="f_Hired_status" class="input-field" style="border-color:var(--primary); font-weight:800; color:var(--primary); height: 50px; font-size: 15px;">
                                <option value="Pipeline">Pipeline</option>
                                <option value="Hired">CONFIRM HIRE</option>
                                <option value="Hold">On Hold</option>
                                <option value="Rejected">Rejected</option>
                            </select>
                        </div>
                        
                        <div class="field-group">
                            <label class="input-label">Experience Details</label>
                            <textarea name="experience" id="f_experience" class="input-field" style="height: 100px; resize: none;"></textarea>
                        </div>
                        
                        <div class="field-group" style="margin-top: 15px;">
                            <label class="input-label">Remarks</label>
                            <textarea name="remarks" id="f_remarks" class="input-field" style="height: 100px; resize: none;"></textarea>
                        </div>

                        <button type="submit" style="width:100%; margin-top:32px; padding:18px; background:var(--primary); color:white; border:none; border-radius:12px; font-weight:800; cursor:pointer; box-shadow: 0 10px 15px -3px rgba(79, 70, 229, 0.4);">
                            UPDATE DOSSIER
                        </button>
                    </div>
                </div>
            </div>
        </form>
    </div>
</div>

<script>
document.querySelectorAll(".reviewBtn").forEach(btn => {
    btn.addEventListener("click", function() {
        const data = JSON.parse(this.dataset.candidate);
        document.getElementById("modal_name").innerText = data.name;
        
        // Populate all fields that match the ID prefix f_
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
</script>

</body>
</html>