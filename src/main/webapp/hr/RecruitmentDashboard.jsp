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
<title>Recruitment Management System | Enterprise Edition</title>

<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Recruitment.css?v=20">

<style>
    :root {
        --primary: #4f46e5;
        --success: #10b981;
        --danger: #ef4444;
        --sidebar-bg: #f8fafc;
        --border-color: #e2e8f0;
        --text-main: #1e293b;
        --text-muted: #64748b;
    }

    body { 
        background-color: #fcfcfd; 
        font-family: 'Plus Jakarta Sans', sans-serif; 
        color: var(--text-main);
        margin: 0;
    }

    /* --- DASHBOARD HEADER --- */
    .dashboard-header {
        background: white;
        padding: 24px 40px;
        border-bottom: 1px solid var(--border-color);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    /* --- KPI CARDS (Minimalist) --- */
    .kpi-container {
        display: flex;
        gap: 20px;
        padding: 30px 40px;
    }
    .kpi-card {
        background: white;
        border: 1px solid var(--border-color);
        padding: 20px 24px;
        border-radius: 12px;
        flex: 1;
        transition: all 0.3s ease;
    }
    .kpi-card:hover { border-color: var(--primary); box-shadow: 0 4px 12px rgba(0,0,0,0.03); }
    .kpi-label { font-size: 13px; font-weight: 600; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; }
    .kpi-value { font-size: 28px; font-weight: 800; margin-top: 8px; color: var(--text-main); }

    /* --- TABLE UI (Clean & Spaced) --- */
    .content-wrapper { padding: 0 40px 40px 40px; }
    .table-card {
        background: white;
        border: 1px solid var(--border-color);
        border-radius: 16px;
        overflow: hidden;
    }
    .position-group-header {
        background: var(--sidebar-bg);
        padding: 12px 24px;
        font-weight: 700;
        font-size: 14px;
        border-bottom: 1px solid var(--border-color);
        color: var(--primary);
        display: flex;
        justify-content: space-between;
    }
    
    table { width: 100%; border-collapse: collapse; text-align: left; }
    th { padding: 16px 24px; font-size: 12px; font-weight: 700; color: var(--text-muted); border-bottom: 1px solid var(--border-color); }
    td { padding: 18px 24px; border-bottom: 1px solid #f8fafc; font-size: 14px; }
    
    tr:hover { background-color: #fbfbfb; }
    
    /* Highlight Hired */
    tr.row-hired { background-color: #f0fdf4; }
    tr.row-hired td:first-child { border-left: 4px solid var(--success); }

    /* --- BADGE STYLING --- */
    .status-badge {
        padding: 4px 10px;
        border-radius: 6px;
        font-size: 12px;
        font-weight: 600;
        display: inline-block;
    }
    .status-pending { background: #fff7ed; color: #9a3412; }
    .status-success { background: #ecfdf5; color: #065f46; }
    .status-rejected { background: #fef2f2; color: #991b1b; }
    .status-blue { background: #eff6ff; color: #1e40af; }

    /* --- ACTION BUTTONS --- */
    .btn-edit {
        background: transparent;
        border: 1px solid var(--border-color);
        color: var(--text-main);
        padding: 8px 16px;
        border-radius: 8px;
        font-weight: 600;
        font-size: 13px;
        cursor: pointer;
        transition: all 0.2s;
    }
    .btn-edit:hover { background: var(--primary); color: white; border-color: var(--primary); }

    /* --- MODAL (Dossier View) --- */
    .modal-content {
        border-radius: 20px;
        border: none;
        overflow: hidden;
    }
    .modal-header {
        background: #1e293b;
        color: white;
        padding: 30px 40px;
    }
    .modal-body {
        padding: 40px;
        display: grid;
        grid-template-columns: 2fr 1fr; /* Dossier Layout */
        gap: 40px;
    }
    .field-group { margin-bottom: 24px; }
    .field-label { display: block; font-size: 11px; font-weight: 700; color: var(--text-muted); margin-bottom: 6px; text-transform: uppercase; }
    .field-input { 
        width: 100%; 
        padding: 10px 14px; 
        border: 1px solid var(--border-color); 
        border-radius: 8px; 
        font-family: inherit;
        font-size: 14px;
        box-sizing: border-box;
    }
    .field-input:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1); }
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="dashboard-header">
    <div>
        <h1 style="margin:0; font-size: 24px; font-weight: 800;">Recruitment Dashboard</h1>
        <p style="margin:4px 0 0 0; color: var(--text-muted); font-size: 14px;">Review and manage incoming candidate profiles.</p>
    </div>
    <div style="font-size: 12px; font-weight: 700; color: var(--text-muted); background: #f1f5f9; padding: 8px 16px; border-radius: 20px;">
        SESSION: 2026-2027
    </div>
</div>

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

<div class="kpi-container">
    <div class="kpi-card">
        <div class="kpi-label">Total Applications</div>
        <div class="kpi-value"><%=total%></div>
    </div>
    <div class="kpi-card">
        <div class="kpi-label">Shortlisted</div>
        <div class="kpi-value" style="color: var(--primary);"><%=shorted%></div>
    </div>
    <div class="kpi-card">
        <div class="kpi-label">Confirmed Hires</div>
        <div class="kpi-value" style="color: var(--success);"><%=hiredCount%></div>
    </div>
</div>

<div class="content-wrapper">
<%
if(rawList != null && !rawList.isEmpty()){
    Map<String,List<Map<String,String>>> grouped = new LinkedHashMap<>();
    for(Map<String,String> row : rawList){
        String post = row.get("post_applied_for");
        if(post == null || post.trim().isEmpty()) post = "Unassigned Positions";
        grouped.computeIfAbsent(post, k-> new ArrayList<>()).add(row);
    }

    for(String post : grouped.keySet()){
        List<Map<String,String>> candidates = grouped.get(post);
%>

    <div class="table-card" style="margin-bottom: 30px;">
        <div class="position-group-header">
            <span><%=post.toUpperCase()%></span>
            <span><%=candidates.size()%> PROFILES</span>
        </div>
        <table>
            <thead>
                <tr>
                    <th style="width: 25%;">Full Name</th>
                    <th>Experience</th>
                    <th>Interview</th>
                    <th>Demo Status</th>
                    <th>Final Verdict</th>
                    <th style="text-align: right;">Action</th>
                </tr>
            </thead>
            <tbody>
            <% 
            for(Map<String,String> c : candidates){
                String iStat = c.get("interview_status");
                String hStat = c.get("Hired_status");
                String highlight = "Hired".equalsIgnoreCase(hStat) ? "row-hired" : "";
                String json = gson.toJson(c).replace("&","&amp;").replace("\"","&quot;");
            %>
                <tr class="<%=highlight%>">
                    <td>
                        <div style="font-weight: 700;"><%=c.get("name")%></div>
                        <div style="font-size: 12px; color: var(--text-muted); margin-top:2px;"><%=c.get("mobile_no")%></div>
                    </td>
                    <td><span style="font-weight: 600;"><%=c.get("total_experience")%> Years</span></td>
                    <td>
                        <span class="status-badge <%= "Selected".equalsIgnoreCase(iStat) ? "status-success" : "status-pending" %>">
                            <%=iStat == null || iStat.isEmpty() ? "Waiting" : iStat%>
                        </span>
                    </td>
                    <td><span class="status-badge status-blue"><%=c.get("demo_status")%></span></td>
                    <td>
                        <% if("Hired".equalsIgnoreCase(hStat)){ %>
                            <span class="status-badge status-success" style="background:#059669; color:white;">HIRED</span>
                        <% } else { %>
                            <span class="status-badge status-pending"><%=hStat%></span>
                        <% } %>
                    </td>
                    <td style="text-align: right;">
                        <button class="btn-edit reviewBtn" data-candidate="<%=json%>">View Profile</button>
                    </td>
                </tr>
            <% } %>
            </tbody>
        </table>
    </div>
<% } } %>
</div>
</div>

<div class="modal" id="editModal" style="display: none; align-items: center; justify-content: center; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(15, 23, 42, 0.7); z-index: 1000; backdrop-filter: blur(4px);">
    <div class="modal-content" style="background: white; width: 1050px; max-height: 90vh; display:flex; flex-direction:column;">
        <div class="modal-header">
            <div style="display:flex; justify-content:space-between; align-items:center;">
                <div>
                    <h2 style="margin:0; font-size: 22px;">Candidate Dossier</h2>
                    <span id="display_sl_no" style="font-size:12px; opacity:0.7;">Ref: ---</span>
                </div>
                <button onclick="closeModal()" style="background:none; border:none; color:white; font-size:28px; cursor:pointer;">&times;</button>
            </div>
        </div>

        <form action="resume" method="post" style="overflow-y:auto;">
            <div class="modal-body">
                <div>
                    <h3 style="margin-top:0; font-size:16px; border-bottom:1px solid #eee; padding-bottom:10px;">Personal & Education</h3>
                    <input type="hidden" name="sl_no" id="f_sl_no">
                    
                    <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px;">
                        <div class="field-group"><label class="field-label">Candidate Name</label><input type="text" name="name" id="f_name" class="field-input"></div>
                        <div class="field-group"><label class="field-label">Mobile Number</label><input type="text" name="mobile_no" id="f_mobile_no" class="field-input"></div>
                    </div>

                    <div class="field-group"><label class="field-label">Address</label><input type="text" name="address" id="f_address" class="field-input"></div>

                    <div style="display:grid; grid-template-columns: 1fr 1fr 1fr; gap:15px;">
                        <div class="field-group"><label class="field-label">Position</label><input type="text" name="post_applied_for" id="f_post_applied_for" class="field-input"></div>
                        <div class="field-group"><label class="field-label">Qualification</label><input type="text" name="qualification" id="f_qualification" class="field-input"></div>
                        <div class="field-group"><label class="field-label">Specialization</label><input type="text" name="specialization" id="f_specialization" class="field-input"></div>
                    </div>

                    <h3 style="margin-top:20px; font-size:16px; border-bottom:1px solid #eee; padding-bottom:10px;">Experience & Salary</h3>
                    <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px;">
                        <div class="field-group"><label class="field-label">Total Exp (Years)</label><input type="text" name="total_experience" id="f_total_experience" class="field-input"></div>
                        <div class="field-group"><label class="field-label">Current Salary</label><input type="text" name="present_salary" id="f_present_salary" class="field-input"></div>
                    </div>
                    <div class="field-group"><label class="field-label">Experience Details</label><textarea name="experience" id="f_experience" class="field-input" style="height:80px;"></textarea></div>
                </div>

                <div style="background: #f8fafc; padding: 25px; border-radius: 12px; border: 1px solid var(--border-color);">
                    <h3 style="margin-top:0; font-size:16px; color: var(--primary);">Review Process</h3>
                    
                    <div class="field-group">
                        <label class="field-label">Shortlist Status</label>
                        <select name="shortlisted" id="f_shortlisted" class="field-input">
                            <option value="Pending">Pending</option>
                            <option value="Yes">Shortlisted</option>
                            <option value="No">Rejected</option>
                        </select>
                    </div>

                    <div class="field-group">
                        <label class="field-label">Demo Assessment</label>
                        <input type="text" name="demo_status" id="f_demo_status" class="field-input" placeholder="Result">
                        <input type="text" name="demo_taken_by" id="f_demo_taken_by" class="field-input" placeholder="Taken By" style="margin-top:8px;">
                    </div>

                    <div class="field-group">
                        <label class="field-label">Interview Verdict</label>
                        <select name="interview_status" id="f_interview_status" class="field-input">
                            <option value="Pending">Waiting</option>
                            <option value="Selected">Selected</option>
                            <option value="Rejected">Rejected</option>
                        </select>
                    </div>

                    <div class="field-group" style="margin-top:30px; border-top: 1px solid #cbd5e1; padding-top:20px;">
                        <label class="field-label" style="color: var(--success); font-weight:800;">Hiring Decision</label>
                        <select name="Hired_status" id="f_Hired_status" class="field-input" style="background:#ecfdf5; border-color:var(--success); font-weight:700;">
                            <option value="Pipeline">Pipeline</option>
                            <option value="Hired">Confirm Hire</option>
                            <option value="Hold">On Hold</option>
                            <option value="Rejected">Rejected</option>
                        </select>
                    </div>

                    <div style="margin-top:40px;">
                        <button type="submit" style="width:100%; padding:14px; background:var(--primary); color:white; border:none; border-radius:8px; font-weight:700; cursor:pointer;">Update Dossier</button>
                        <button type="button" onclick="closeModal()" style="width:100%; margin-top:10px; padding:10px; background:white; color:var(--text-muted); border:1px solid var(--border-color); border-radius:8px; font-weight:600; cursor:pointer;">Cancel</button>
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
        document.getElementById("display_sl_no").innerText = "Ref: #" + data.sl_no;
        Object.keys(data).forEach(key => {
            const el = document.getElementById("f_" + key);
            if (el) el.value = data[key] || "";
        });
        document.getElementById("editModal").style.display = "flex";
    });
});

function closeModal() { document.getElementById("editModal").style.display = "none"; }
</script>

</body>
</html>