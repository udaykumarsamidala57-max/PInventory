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

    /* --- LAYOUT --- */
    .app-container { max-width: 1400px; margin: 0 auto; padding: 32px; }
    
    .header-flex {
        display: flex;
        justify-content: space-between;
        align-items: flex-end;
        margin-bottom: 32px;
    }

    /* --- KPI SECTION --- */
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
    .kpi-card .label { font-size: 12px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1px; }
    .kpi-card .value { font-size: 32px; font-weight: 800; margin-top: 8px; }

    /* --- TABLE UI --- */
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
    th { padding: 16px 24px; font-size: 12px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; background: #fafafa; }
    td { padding: 20px 24px; border-bottom: 1px solid var(--border); font-size: 14px; vertical-align: middle; }
    
    /* --- PIPELINE VISUALIZER --- */
    .pipeline-wrapper { display: flex; align-items: center; gap: 8px; }
    .step { width: 12px; height: 12px; border-radius: 50%; background: #e2e8f0; }
    .step.completed { background: var(--success); }
    .step.active { background: var(--warning); box-shadow: 0 0 0 4px rgba(245, 158, 11, 0.2); }
    
    /* --- ROW STATES --- */
    .row-hired { background: #f0fdf4 !important; }
    .row-hired td:first-child { border-left: 4px solid var(--success); }

    /* --- BUTTONS --- */
    .btn-action {
        padding: 10px 20px;
        border-radius: 10px;
        font-weight: 700;
        font-size: 13px;
        cursor: pointer;
        transition: all 0.2s;
        border: 1px solid var(--border);
        background: white;
    }
    .btn-action:hover { background: var(--primary); color: white; border-color: var(--primary); transform: translateY(-1px); }

    /* --- MODAL --- */
    .modal-overlay {
        display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(15, 23, 42, 0.6); backdrop-filter: blur(8px); z-index: 1000;
        align-items: center; justify-content: center;
    }
    .modal-card {
        background: white; width: 1100px; max-height: 90vh; border-radius: 24px;
        overflow: hidden; display: flex; flex-direction: column; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
    }
    .modal-body { padding: 40px; overflow-y: auto; display: grid; grid-template-columns: 1fr 320px; gap: 40px; }
    
    .workflow-section {
        background: var(--background);
        border-radius: 16px;
        padding: 24px;
        margin-bottom: 24px;
        border: 1px solid var(--border);
    }
    .workflow-tag {
        display: inline-block; padding: 4px 12px; border-radius: 6px; font-size: 11px; font-weight: 800;
        background: var(--primary-soft); color: var(--primary); margin-bottom: 16px; text-transform: uppercase;
    }
    
    .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
    .input-label { display: block; font-size: 11px; font-weight: 700; color: var(--text-muted); margin-bottom: 6px; text-transform: uppercase; }
    .input-field { 
        width: 100%; padding: 12px; border: 1px solid var(--border); border-radius: 10px; 
        font-size: 14px; box-sizing: border-box; font-family: inherit;
    }
    .input-field:focus { outline: none; border-color: var(--primary); ring: 3px var(--primary-soft); }
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="app-container">
    <div class="header-flex">
        <div>
            <h1 style="margin:0; font-size: 32px; font-weight: 800; letter-spacing: -1px;">Talent Acquisition</h1>
            <p style="margin: 4px 0 0 0; color: var(--text-muted);">Manage the 4-stage recruitment lifecycle</p>
        </div>
        <div style="text-align: right">
            <div style="font-size: 12px; font-weight: 700; color: var(--text-muted);">Recruitment Cycle</div>
            <div style="font-weight: 800; color: var(--primary)">Q1 2026 - Active</div>
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
        <div class="kpi-card"><div class="label">Incoming</div><div class="value"><%=total%></div></div>
        <div class="kpi-card"><div class="label">Shortlisted</div><div class="value" style="color:var(--warning)"><%=shorted%></div></div>
        <div class="kpi-card"><div class="label">Interviews</div><div class="value" style="color:var(--primary)"><%=demoed%></div></div>
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
    <div class="table-container" style="margin-bottom: 40px;">
        <div class="table-header">
            <span><%=post.toUpperCase()%></span>
            <span><%=candidates.size()%> Candidates</span>
        </div>
        <table>
            <thead>
                <tr>
                    <th style="width:250px">Candidate</th>
                    <th>Lifecycle Stage</th>
                    <th>Experience</th>
                    <th>Interview Verdict</th>
                    <th>Final Status</th>
                    <th style="text-align:right">Action</th>
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
                        <div style="font-weight: 800;"><%=c.get("name")%></div>
                        <div style="font-size: 12px; color: var(--text-muted)"><%=c.get("mobile_no")%></div>
                    </td>
                    <td>
                        <div class="pipeline-wrapper">
                            <div class="step <%= isShort ? "completed" : "active" %>" title="Shortlist"></div>
                            <div style="width:20px; height:2px; background:#e2e8f0"></div>
                            <div class="step <%= isDemo ? "completed" : (isShort ? "active" : "") %>" title="Demo"></div>
                            <div style="width:20px; height:2px; background:#e2e8f0"></div>
                            <div class="step <%= isInt ? "completed" : (isDemo ? "active" : "") %>" title="Interview"></div>
                            <div style="width:20px; height:2px; background:#e2e8f0"></div>
                            <div class="step <%= isHired ? "completed" : (isInt ? "active" : "") %>" title="Hire"></div>
                        </div>
                    </td>
                    <td><span style="font-weight: 700"><%=c.get("total_experience")%> Yrs</span></td>
                    <td>
                        <span style="font-size: 12px; font-weight: 700; color: <%= isInt ? "var(--success)" : "var(--text-muted)" %>">
                            <%= isInt ? "SELECTED" : (c.get("interview_status") != null ? c.get("interview_status").toUpperCase() : "PENDING") %>
                        </span>
                    </td>
                    <td>
                        <% if(isHired){ %>
                            <b style="color: var(--success); font-size: 12px;">✅ CONFIRMED</b>
                        <% } else { %>
                            <span style="color: var(--text-muted); font-size: 12px;"><%=c.get("Hired_status")%></span>
                        <% } %>
                    </td>
                    <td style="text-align:right">
                        <button class="btn-action reviewBtn" data-candidate="<%=json%>">Process Details</button>
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
                <div style="font-size: 11px; font-weight: 700; opacity: 0.6; text-transform: uppercase;">Candidate Lifecycle Management</div>
                <h2 id="modal_name" style="margin:0; font-size: 24px; font-weight: 800;">---</h2>
            </div>
            <button onclick="closeModal()" style="background:none; border:none; color:white; font-size:32px; cursor:pointer;">&times;</button>
        </div>

        <form action="resume" method="post" style="flex:1; overflow:hidden; display:flex; flex-direction:column;">
            <div class="modal-body">
                <div>
                    <div class="workflow-section">
                        <span class="workflow-tag">Stage 1: Shortlisting</span>
                        <div class="form-grid">
                            <input type="hidden" name="sl_no" id="f_sl_no">
                            <div class="field-group">
                                <label class="input-label">Qualified for Demo?</label>
                                <select name="shortlisted" id="f_shortlisted" class="input-field">
                                    <option value="No">No (Reject)</option>
                                    <option value="Yes">Yes (Proceed)</option>
                                    <option value="Pending">Pending</option>
                                </select>
                            </div>
                            <div class="field-group">
                                <label class="input-label">Call Comments</label>
                                <input type="text" name="call_status" id="f_call_status" class="input-field">
                            </div>
                        </div>
                    </div>

                    <div class="workflow-section">
                        <span class="workflow-tag">Stage 2: Demo / Technical</span>
                        <div class="form-grid">
                            <div class="field-group">
                                <label class="input-label">Demo Date</label>
                                <input type="date" name="demo_date" id="f_demo_date" class="input-field">
                            </div>
                            <div class="field-group">
                                <label class="input-label">Technical Score/Status</label>
                                <input type="text" name="demo_status" id="f_demo_status" class="input-field">
                            </div>
                        </div>
                    </div>

                    <div class="workflow-section">
                        <span class="workflow-tag">Stage 3: HR Interview</span>
                        <div class="form-grid">
                            <div class="field-group">
                                <label class="input-label">Final Interview Date</label>
                                <input type="date" name="interview_date" id="f_interview_date" class="input-field">
                            </div>
                            <div class="field-group">
                                <label class="input-label">Final Verdict</label>
                                <select name="interview_status" id="f_interview_status" class="input-field">
                                    <option value="Pending">Waiting</option>
                                    <option value="Selected">Selected</option>
                                    <option value="Rejected">Rejected</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>

                <div>
                    <div style="background: var(--primary-soft); padding: 24px; border-radius: 20px; border: 2px solid var(--primary);">
                        <span class="workflow-tag" style="background:var(--primary); color:white;">Final Stage</span>
                        
                        <div class="field-group" style="margin-bottom: 20px;">
                            <label class="input-label">Official Hire Status</label>
                            <select name="Hired_status" id="f_Hired_status" class="input-field" style="border-color:var(--primary); font-weight:800; color:var(--primary)">
                                <option value="Pipeline">In Pipeline</option>
                                <option value="Hired">CONFIRM HIRE</option>
                                <option value="Hold">On Hold</option>
                                <option value="Rejected">Rejected</option>
                            </select>
                        </div>
                        
                        <div class="field-group">
                            <label class="input-label">Closing Remarks</label>
                            <textarea name="remarks" id="f_remarks" class="input-field" style="height: 100px;"></textarea>
                        </div>

                        <button type="submit" style="width:100%; margin-top:24px; padding:16px; background:var(--primary); color:white; border:none; border-radius:12px; font-weight:800; cursor:pointer; box-shadow: 0 4px 12px rgba(79, 70, 229, 0.3);">
                            COMMIT TO SYSTEM
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