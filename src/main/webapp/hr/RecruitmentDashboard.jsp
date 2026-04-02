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

<%!
public String safe(Object o){
    return (o==null) ? "" : o.toString();
}

// Helper to determine badge styling based on status text
public String getBadgeClass(String status) {
    if (status == null) return "badge";
    String s = status.toLowerCase();
    if (s.contains("yes") || s.contains("selected") || s.contains("hired")) return "badge success";
    if (s.contains("no") || s.contains("rejected")) return "badge danger";
    if (s.contains("pending") || s.contains("called")) return "badge warning";
    return "badge primary";
}
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>RecruitPro | Recruitment Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        body { font-family:'Inter',sans-serif; background:#f4f6fb; margin:0; color:#1e293b; }
        .main-container { padding: 20px; max-width: 1400px; margin: 0 auto; }
        .kpi-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); gap:20px; margin-bottom:30px; }
        .kpi-card { background:white; padding:22px; border-radius:12px; box-shadow:0 3px 12px rgba(0,0,0,0.05); }
        .kpi-card h3 { font-size:14px; color:#64748b; margin:0; }
        .kpi-number { font-size:32px; font-weight:800; margin-top:10px; }
        .kpi-number.success {color:#16a34a;} 
        .kpi-number.primary {color:#2563eb;} 
        .kpi-number.hired {color:#9333ea;}
        
        .section { margin-top:40px; }
        .section-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:15px; }
        .table-wrapper { overflow-x:auto; }
        table { width:100%; border-collapse:collapse; background:white; border-radius:10px; overflow:hidden; box-shadow:0 2px 8px rgba(0,0,0,0.05); }
        th { background:#f8fafc; font-size:11px; text-transform:uppercase; color:#64748b; padding:12px; text-align: left; }
        td { padding:12px; border-top:1px solid #f1f5f9; font-size:13px; vertical-align: top; transition: all 0.2s ease; }
        
        /* Dimmed Row Effect (Gmail Style) */
        .dimmed-row td { 
            opacity: 0.45; 
            filter: grayscale(0.8);
        }
        .dimmed-row:hover td {
            opacity: 1;
            filter: grayscale(0);
        }

        /* Badges Styling */
        .badge { display:inline-block; padding:4px 10px; border-radius:20px; font-size:11px; font-weight:700; text-transform: uppercase; letter-spacing: 0.3px; }
        .badge.success {background:#dcfce7;color:#166534; border: 1px solid #bbf7d0;}
        .badge.primary {background:#dbeafe;color:#1d4ed8; border: 1px solid #bfdbfe;}
        .badge.warning {background:#fef3c7;color:#92400e; border: 1px solid #fde68a;}
        .badge.danger {background:#fee2e2;color:#991b1b; border: 1px solid #fecaca;}
        
        .btn-primary { background:#4f46e5; color:white; border:none; padding:8px 14px; border-radius:6px; cursor:pointer; font-size:12px; font-weight:600; text-decoration:none; display:inline-block;}
        .btn-outline { background:transparent; border:1px solid #4f46e5; color:#4f46e5; padding:7px 13px; border-radius:6px; cursor:pointer; font-size:12px; font-weight:600; text-decoration:none; display:inline-block;}
        .btn-outline:hover { background:#4f46e5; color:white; }
        
        .modal { display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(15, 23, 42, 0.7); z-index:9999; justify-content:center; align-items:center; backdrop-filter: blur(4px); }
        .modal-content { background:white; width:90%; max-width:1100px; max-height:92vh; overflow-y:auto; padding:30px; border-radius:12px; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); }
        .modal-title { font-size:20px; font-weight:800; margin-bottom:20px; color:#1e293b; border-bottom: 1px solid #e2e8f0; padding-bottom: 10px; }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 30px; }
        .modal-form h4 { margin: 20px 0 10px 0; font-size: 13px; color: #4f46e5; text-transform: uppercase; letter-spacing: 0.5px; }
        .form-row { display: flex; gap: 12px; margin-top: 10px; }
        input, select, textarea { width: 100%; padding: 10px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 13px; }
        textarea { min-height: 80px; }
        .modal-buttons { margin-top: 30px; display: flex; justify-content: flex-end; gap: 12px; padding-top: 20px; border-top: 1px solid #e2e8f0; }
        .btn-light { background:#f1f5f9; border:none; padding:10px 20px; border-radius:8px; cursor:pointer; font-weight:600; color:#475569; }
        .file-upload-box { border: 2px dashed #cbd5e1; padding: 10px; border-radius: 8px; background: #f8fafc; margin-top: 10px; }
    </style>
</head>

<body>

<%@ include file="header.jsp" %>

<div class="main-container">

    <%
    List<Map<String,String>> rawList=(List<Map<String,String>>)request.getAttribute("resumeList");
    int total=0, shortlisted=0, demoSelected=0, hired=0;

    if(rawList!=null){
        total=rawList.size();
        for(Map<String,String> c:rawList){
            if("Yes".equalsIgnoreCase(c.get("shortlisted"))) shortlisted++;
            if("Selected".equalsIgnoreCase(c.get("demo_status"))) demoSelected++;
            if("Yes".equalsIgnoreCase(c.get("Hired_status"))) hired++;
        }
    }
    %>

    <div class="kpi-grid">
        <div class="kpi-card"><h3>Total Applications</h3><div class="kpi-number"><%=total%></div></div>
        <div class="kpi-card"><h3>Shortlisted</h3><div class="kpi-number success"><%=shortlisted%></div></div>
        <div class="kpi-card"><h3>Demo Selected</h3><div class="kpi-number primary"><%=demoSelected%></div></div>
        <div class="kpi-card"><h3>Hired</h3><div class="kpi-number hired"><%=hired%></div></div>
    </div>

    <% if(rawList!=null && !rawList.isEmpty()){
        Map<String,List<Map<String,String>>> grouped=new LinkedHashMap<>();
        for(Map<String,String> row:rawList){
            String post=row.get("post_applied_for");
            if(post==null||post.trim().isEmpty()) post="General Pipeline";
            grouped.computeIfAbsent(post, k->new ArrayList<>()).add(row);
        }

        for(String post:grouped.keySet()){
            List<Map<String,String>> candidates=grouped.get(post);
            
            // Sort logic: Active candidates first, Rejected (Dimmed) candidates last
            Collections.sort(candidates, new Comparator<Map<String,String>>() {
                public int compare(Map<String,String> c1, Map<String,String> c2) {
                    boolean r1 = "No".equalsIgnoreCase(c1.get("shortlisted")) || "Rejected".equalsIgnoreCase(c1.get("demo_status")) || "Rejected".equalsIgnoreCase(c1.get("interview_status"));
                    boolean r2 = "No".equalsIgnoreCase(c2.get("shortlisted")) || "Rejected".equalsIgnoreCase(c2.get("demo_status")) || "Rejected".equalsIgnoreCase(c2.get("interview_status"));
                    return Boolean.compare(r1, r2); 
                }
            });
    %>
    <div class="section">
        <div class="section-header"><h1><%=post%></h1></div>
        <div class="table-wrapper">
            <table>
                <thead>
                    <tr>
                        <th>Enquiry No</th>
                        <th>Candidate</th>
                        <th>Qualification</th>
                        <th>Exp</th>
                        <th>Call</th>
                        <th>Shortlist</th>
                        <th>Demo</th>
                        <th>Interview Status</th>
                        <th>Hired Status</th>
                        <th> Remarks></th>	
                        <th>Resume</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                <% for(Map<String,String> c:candidates){
                    String json=gson.toJson(c).replace("&","&amp;").replace("\"","&quot;");
                    String hiredStatusText = "Yes".equalsIgnoreCase(c.get("Hired_status")) ? "Hired" : "Pending";
                    
                    boolean isRejected = "No".equalsIgnoreCase(c.get("shortlisted")) || 
                                       "Rejected".equalsIgnoreCase(c.get("demo_status")) || 
                                       "Rejected".equalsIgnoreCase(c.get("interview_status"));
                    
                    String rowClass = isRejected ? "dimmed-row" : "";
                %>
                    <tr class="<%=rowClass%>">
                        <td><%=safe(c.get("sl_no"))%></td>
                        <td><b><%=safe(c.get("name"))%></b><br><small><%=safe(c.get("mobile_no"))%></small></td>
                        <td><%=safe(c.get("qualification"))%></td>
                        <td><%=safe(c.get("total_experience"))%> Y</td>
                        <td><%=safe(c.get("call_status"))%> </td>
                        
                        <td><span class="<%=getBadgeClass(c.get("shortlisted"))%>"><%=safe(c.get("shortlisted"))%></span></td>
                        <td><span class="<%=getBadgeClass(c.get("demo_status"))%>"><%=safe(c.get("demo_status"))%></span></td>
                        <td><span class="<%=getBadgeClass(hiredStatusText)%>"><%=hiredStatusText%></span></td>
                        <td><%=safe(c.get("remarks"))%> </td>
                        <td><a href="viewResumeFile?id=<%=c.get("sl_no")%>" target="_blank" class="btn-outline">View</a></td>
                        <td><button class="btn-primary reviewBtn" data-candidate="<%=json%>">Review</button></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
    <% } } %>
</div>

<div class="modal" id="editModal">
    <div class="modal-content">
        <div class="modal-title">Update Candidate Dossier</div>
        <form action="resume" method="post" enctype="multipart/form-data" class="modal-form">
            <input type="hidden" name="sl_no" id="f_sl_no">
            
            <div class="form-grid">
                <div>
                    <h4>1. Basic Information</h4>
                    <div class="form-row">
                        <input type="text" name="name" id="f_name" placeholder="Full Name">
                        <input type="text" name="mobile_no" id="f_mobile_no" placeholder="Mobile">
                    </div>
                    <div class="form-row">
                        <input type="text" name="address" id="f_address" placeholder="Address">
                    </div>
                    <div class="form-row">
                        <select name="gender" id="f_gender"><option value="Male">Male</option><option value="Female">Female</option></select>
                        <input type="date" name="date_of_birth" id="f_date_of_birth">
                        <select name="marital_status" id="f_marital_status"><option value="Single">Single</option><option value="Married">Married</option></select>
                    </div>

                    <h4>2. Qualification & Skills</h4>
                    <div class="form-row">
                        <input type="text" name="qualification" id="f_qualification" placeholder="Qualification">
                        <input type="text" name="specialization" id="f_specialization" placeholder="Specialization">
                    </div>
                    <div class="form-row">
                        <input type="text" name="percentage_marks" id="f_percentage_marks" placeholder="Marks %">
                        <input type="text" name="year_of_passing" id="f_year_of_passing" placeholder="Year">
                    </div>
                    <textarea name="other_skills_certifications" id="f_other_skills_certifications" placeholder="Skills"></textarea>

                    <h4>3. Experience & Salary</h4>
                    <div class="form-row">
                        <input type="text" name="total_experience" id="f_total_experience" placeholder="Total Exp">
                        <input type="text" name="relevant_experience" id="f_relevant_experience" placeholder="Rel Exp">
                    </div>
                    <div class="form-row">
                        <input type="text" name="present_salary" id="f_present_salary" placeholder="Current Salary">
                        <input type="text" name="expected_salary" id="f_expected_salary" placeholder="Expected">
                    </div>
                </div>

                <div>
                    <h4>4. Selection Process</h4>
                    <div class="form-row">
                        <input type="text" name="post_applied_for" id="f_post_applied_for" placeholder="Post">
                        <select name="shortlisted" id="f_shortlisted"><option value="Pending">Pending</option><option value="Yes">Yes</option><option value="No">No</option></select>
                    </div>
                    <div class="form-row">
                        <select name="call_status" id="f_call_status"><option value="Called">Called</option><option value="Not Reachable">Not Reachable</option></select>
                    </div>
                    <div class="form-row">
                    <h6> Demo Status</h6>
                        <input type="date" name="demo_date" id="f_demo_date">
                        <select name="demo_status" id="f_demo_status"><option value="Pending">Pending</option><option value="Selected">Selected</option><option value="Rejected">Rejected</option></select>
                    </div>
                    <div class="form-row">
                     <h6> Interview Status</h6>
                        <input type="date" name="interview_date" id="f_interview_date">
                        <select name="interview_status" id="f_interview_status"><option value="Pending">Pending</option><option value="Selected">Selected</option><option value="Rejected">Rejected</option></select>
                    </div>

                    <h4>5. Final Decision & Resume</h4>
                    <div class="form-row">
                        <select name="Hired_status" id="f_Hired_status" style="border: 2px solid #9333ea;">
                            <option value="No">Not Hired</option>
                            <option value="Yes">FINAL HIRE</option>
                        </select>
                        <input type="text" name="reference_by" id="f_reference_by" placeholder="Reference By">
                    </div>
                    
                    <div class="file-upload-box">
                        <label style="font-size:11px; font-weight:bold; color:#4f46e5;">UPDATE RESUME (PDF Only)</label>
                        <input type="file" name="resumeFile" accept="application/pdf" style="border:none; padding:5px;">
                    </div>

                    <textarea name="remarks" id="f_remarks" placeholder="Final Remarks" style="margin-top:10px;"></textarea>
                </div>
            </div>

            <div class="modal-buttons">
                <button type="button" onclick="closeModal()" class="btn-light">Discard</button>
                <button type="submit" class="btn-primary">SAVE PROFILE</button>
            </div>
        </form>
    </div>
</div>

<script>
document.querySelectorAll(".reviewBtn").forEach(btn => {
    btn.addEventListener("click", function() {
        const data = JSON.parse(this.getAttribute("data-candidate"));
        Object.keys(data).forEach(key => {
            const el = document.getElementById("f_" + key);
            if (el) el.value = (el.type === 'date' && data[key]) ? data[key].split(' ')[0] : (data[key] || "");
        });
        document.getElementById("editModal").style.display = "flex";
    });
});
function closeModal() { document.getElementById("editModal").style.display = "none"; }
</script>

</body>
</html>