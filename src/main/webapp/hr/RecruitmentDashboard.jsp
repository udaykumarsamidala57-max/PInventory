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
<title>RecruitPro | High-Visibility Dashboard</title>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Recruitment.css?v=14">

<style>
    /* --- ENHANCED HIGHLIGHTING --- */
    
    /* Final Success - Interview Selected */
    .row-final-selected { 
        background-color: #dcfce7 !important; /* Soft Green */
        border-left: 5px solid #16a34a;
    }
    
    /* Demo Cleared - Waiting Interview */
    .row-demo-selected { 
        background-color: #dbeafe !important; /* Soft Blue */
        border-left: 5px solid #2563eb;
    }
    
    /* Shortlisted - Early Stage */
    .row-shortlisted { 
        background-color: #fffbeb !important; /* Soft Yellow */
        border-left: 5px solid #d97706;
    }

    /* Rejected */
    .row-rejected { 
        background-color: #fef2f2 !important; /* Soft Red */
        opacity: 0.8;
    }

    /* --- KPI STYLING --- */
    .kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 30px; }
    .kpi-card { padding: 20px; border-radius: 12px; background: white; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1); border: 1px solid #e5e7eb; }
    .kpi-number { font-size: 32px; font-weight: 800; margin-top: 10px; }
    .kpi-card.total { border-top: 4px solid #6366f1; }
    .kpi-card.short { border-top: 4px solid #f59e0b; }
    .kpi-card.demo { border-top: 4px solid #3b82f6; }
    .kpi-card.final { border-top: 4px solid #10b981; }

    /* --- TABLE & MODAL --- */
    .table-wrapper table tr:hover { filter: brightness(95%); cursor: pointer; }
    .badge { padding: 5px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
    .badge-success { background: #16a34a; color: white; }
    .badge-danger { background: #dc2626; color: white; }
    .badge-warning { background: #f59e0b; color: white; }
    .badge-info { background: #3b82f6; color: white; }
    .badge-dark { background: #4b5563; color: white; }

    .modal-content { width: 950px; border-radius: 15px; overflow: hidden; }
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="navbar">
    <div class="logo">RECRUITMENT TRACKER 2026-27</div>
    <div><span class="status-dot"></span> LIVE SYSTEM</div>
</div>

<div class="main-container">

<%
List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
int total = 0, shorted = 0, demoSel = 0, finalSel = 0;

if(rawList != null){
    total = rawList.size();
    for(Map<String,String> c : rawList){
        if("Yes".equalsIgnoreCase(c.get("shortlisted"))) shorted++;
        if("Selected".equalsIgnoreCase(c.get("demo_status"))) demoSel++;
        if("Selected".equalsIgnoreCase(c.get("interview_status"))) finalSel++;
    }
}
%>

<div class="kpi-grid">
    <div class="kpi-card total"><h3>Applications</h3><div class="kpi-number"><%=total%></div></div>
    <div class="kpi-card short"><h3>Shortlisted</h3><div class="kpi-number" style="color:#f59e0b"><%=shorted%></div></div>
    <div class="kpi-card demo"><h3>Demo Selected</h3><div class="kpi-number" style="color:#3b82f6"><%=demoSel%></div></div>
    <div class="kpi-card final"><h3>Final Hires</h3><div class="kpi-number" style="color:#10b981"><%=finalSel%></div></div>
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
        <span class="count"><%=candidates.size()%> Profiles</span>
    </div>

    <div class="table-wrapper">
        <table style="width:100%; border-collapse: separate; border-spacing: 0 5px;">
            <thead>
                <tr>
                    <th>Candidate</th>
                    <th>Education</th>
                    <th>Experience</th>
                    <th>Stage 1: Shortlist</th>
                    <th>Stage 2: Demo</th>
                    <th>Stage 3: Interview</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
            <% 
            for(Map<String,String> c : candidates){
                String sStat = c.get("shortlisted");
                String dStat = c.get("demo_status");
                String iStat = c.get("interview_status");

                // --- PRIORITY HIGHLIGHTING LOGIC ---
                String highlightClass = "";
                if("Selected".equalsIgnoreCase(iStat)) highlightClass = "row-final-selected";
                else if("Rejected".equalsIgnoreCase(iStat) || "No".equalsIgnoreCase(sStat) || "Rejected".equalsIgnoreCase(dStat)) highlightClass = "row-rejected";
                else if("Selected".equalsIgnoreCase(dStat)) highlightClass = "row-demo-selected";
                else if("Yes".equalsIgnoreCase(sStat)) highlightClass = "row-shortlisted";

                String json = gson.toJson(c).replace("&","&amp;").replace("\"","&quot;").replace("<","&lt;").replace(">","&gt;");
            %>
                <tr class="<%=highlightClass%>">
                    <td>
                        <div style="font-weight: 800; color: #1e293b;"><%=c.get("name")%></div>
                        <div style="font-size: 11px; color: #64748b;"><%=c.get("mobile_no")%></div>
                    </td>
                    <td><b><%=c.get("qualification")%></b><br><small><%=c.get("specialization")%></small></td>
                    <td><span style="font-weight: 700;"><%=c.get("total_experience")%> Yrs</span></td>
                    
                    <td>
                        <% if("Yes".equalsIgnoreCase(sStat)){ %> <span class="badge badge-success">Shortlisted</span>
                        <% } else if("No".equalsIgnoreCase(sStat)){ %> <span class="badge badge-danger">Rejected</span>
                        <% } else { %> <span class="badge badge-warning">In Review</span> <% } %>
                    </td>

                    <td>
                        <% if("Selected".equalsIgnoreCase(dStat)){ %> <span class="badge badge-success">Demo Passed</span>
                        <% } else if("Rejected".equalsIgnoreCase(dStat)){ %> <span class="badge badge-danger">Demo Failed</span>
                        <% } else if("Scheduled".equalsIgnoreCase(dStat)){ %> <span class="badge badge-info">Scheduled</span>
                        <% } else { %> <span class="badge badge-dark">Pending</span> <% } %>
                    </td>

                    <td>
                        <% if("Selected".equalsIgnoreCase(iStat)){ %> <span class="badge badge-success">SELECTED</span>
                        <% } else if("Rejected".equalsIgnoreCase(iStat)){ %> <span class="badge badge-danger">REJECTED</span>
                        <% } else { %> <span class="badge badge-dark">WAITING</span> <% } %>
                    </td>

                    <td>
                        <button class="btn-primary reviewBtn" data-candidate="<%=json%>" style="padding: 8px 15px; border-radius: 6px;">
                            VIEW & EDIT
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

<div class="modal" id="editModal" style="display: none; align-items: center; justify-content: center; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(15, 23, 42, 0.8); z-index: 1000;">
    <div class="modal-content" style="background: white; border-radius: 12px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5);">
        <div style="padding: 20px; background: #4f46e5; color: white; display: flex; justify-content: space-between; align-items: center;">
            <h2 style="margin:0; font-size: 1.25rem;">Candidate Management Profile</h2>
            <button onclick="closeModal()" style="background:none; border:none; color:white; font-size:24px; cursor:pointer;">&times;</button>
        </div>

        <form action="resume" method="post" class="modal-form" style="padding: 30px; display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
            <input type="hidden" name="sl_no" id="f_sl_no">

            <div class="form-group" style="grid-column: span 2;">
                <h4 style="color: #4f46e5; border-bottom: 2px solid #eef2ff; padding-bottom: 5px;">Personal & Application Details</h4>
            </div>
            
            <input type="text" name="name" id="f_name" placeholder="Full Name">
            <input type="text" name="mobile_no" id="f_mobile_no" placeholder="Mobile Number">
            <input type="text" name="post_applied_for" id="f_post_applied_for" placeholder="Position">
            <input type="text" name="qualification" id="f_qualification" placeholder="Qualification">

            <div class="form-group" style="grid-column: span 2;">
                <h4 style="color: #4f46e5; border-bottom: 2px solid #eef2ff; padding-bottom: 5px;">Recruitment Workflow</h4>
            </div>

            <div>
                <label style="display:block; font-size: 12px; font-weight:700; margin-bottom:5px;">Shortlist Status</label>
                <select name="shortlisted" id="f_shortlisted" style="width:100%; padding: 10px; border-radius: 5px; border: 1px solid #cbd5e1;">
                    <option value="Pending">Pending Review</option>
                    <option value="Yes">Yes - Shortlist</option>
                    <option value="No">No - Reject</option>
                </select>
            </div>

            <div>
                <label style="display:block; font-size: 12px; font-weight:700; margin-bottom:5px;">Demo Performance</label>
                <select name="demo_status" id="f_demo_status" style="width:100%; padding: 10px; border-radius: 5px; border: 1px solid #cbd5e1;">
                    <option value="Pending">Pending</option>
                    <option value="Scheduled">Scheduled</option>
                    <option value="Selected">Selected / Passed</option>
                    <option value="Rejected">Rejected / Failed</option>
                </select>
            </div>

            <div>
                <label style="display:block; font-size: 12px; font-weight:700; margin-bottom:5px;">Final Interview</label>
                <select name="interview_status" id="f_interview_status" style="width:100%; padding: 10px; border-radius: 5px; border: 1px solid #cbd5e1;">
                    <option value="Pending">Waiting</option>
                    <option value="Selected">SELECTED FOR HIRE</option>
                    <option value="Rejected">NOT SELECTED</option>
                </select>
            </div>

            <div>
                <label style="display:block; font-size: 12px; font-weight:700; margin-bottom:5px;">Call Log</label>
                <select name="call_status" id="f_call_status" style="width:100%; padding: 10px; border-radius: 5px; border: 1px solid #cbd5e1;">
                    <option value="Pending">Not Called</option>
                    <option value="Called">Called / Responsive</option>
                    <option value="Not Reachable">Not Reachable</option>
                </select>
            </div>

            <div style="grid-column: span 2;">
                <label style="display:block; font-size: 12px; font-weight:700; margin-bottom:5px;">Internal Remarks</label>
                <textarea name="remarks" id="f_remarks" style="width:100%; height:80px; padding: 10px; border: 1px solid #cbd5e1; border-radius: 5px;"></textarea>
            </div>

            <div style="grid-column: span 2; display: flex; justify-content: flex-end; gap: 15px; margin-top: 10px;">
                <button type="button" onclick="closeModal()" class="btn-light" style="padding: 12px 25px; cursor:pointer;">Close</button>
                <button type="submit" class="btn-primary" style="padding: 12px 40px; background: #4f46e5; color: white; border: none; border-radius: 6px; cursor:pointer; font-weight: 700;">UPDATE CANDIDATE STATUS</button>
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
            if (el) el.value = data[key] || "";
        });
        document.getElementById("editModal").style.display = "flex";
    });
});

function closeModal() {
    document.getElementById("editModal").style.display = "none";
}

window.onclick = function(e) {
    if (e.target == document.getElementById("editModal")) closeModal();
}
</script>

</body>
</html>