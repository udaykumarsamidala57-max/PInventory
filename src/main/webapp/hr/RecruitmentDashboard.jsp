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
<title>RecruitPro | Recruitment Dashboard</title>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="CSS/Recruitment.css?v=13">

<style>
    /* Modal Styling */
    .modal-content {
        width: 900px;
        max-height: 90vh;
        overflow-y: auto;
        border-radius: 12px;
    }

    .modal-form h4 {
        margin-top: 25px;
        margin-bottom: 12px;
        font-size: 14px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        color: #4f46e5;
        border-bottom: 1px solid #e5e7eb;
        padding-bottom: 5px;
    }

    /* Row Highlighting */
    .interview-selected { background-color: #ecfdf5 !important; }
    .demo-selected { background-color: #eff6ff !important; }

    /* Badge Consistency */
    .badge {
        padding: 4px 8px;
        border-radius: 6px;
        font-size: 11px;
        font-weight: 600;
        display: inline-block;
    }
    .badge.success { background: #dcfce7; color: #15803d; }
    .badge.danger { background: #fee2e2; color: #b91c1c; }
    .badge.warning { background: #fef3c7; color: #92400e; }
    .badge.primary { background: #e0e7ff; color: #4338ca; }
    .badge.secondary { background: #f3f4f6; color: #374151; }
</style>

</head>
<body>

<%@ include file="header.jsp" %>

<div class="navbar">
    <div class="logo">Recruitment 2026 - 27</div>
    <div><span class="status-dot"></span>System Active</div>
</div>

<div class="main-container">

<%
List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");

int total = 0;
int shortlisted = 0;
int selectedCount = 0;

if(rawList != null){
    total = rawList.size();
    for(Map<String,String> c : rawList){
        if("Yes".equalsIgnoreCase(c.get("shortlisted"))) shortlisted++;
        if("Selected".equalsIgnoreCase(c.get("interview_status"))) selectedCount++;
    }
}
%>

<div class="kpi-grid">
    <div class="kpi-card">
        <h3>Total Applications</h3>
        <div class="kpi-number"><%=total%></div>
    </div>
    <div class="kpi-card">
        <h3>Shortlisted</h3>
        <div class="kpi-number success"><%=shortlisted%></div>
    </div>
    <div class="kpi-card">
        <h3>Final Selection</h3>
        <div class="kpi-number primary"><%=selectedCount%></div>
    </div>
</div>

<%
if(rawList != null && !rawList.isEmpty()){
    Map<String,List<Map<String,String>>> grouped = new LinkedHashMap<>();
    for(Map<String,String> row : rawList){
        String post = row.get("post_applied_for");
        if(post == null || post.trim().isEmpty()) post = "General";
        grouped.computeIfAbsent(post, k-> new ArrayList<>()).add(row);
    }

    for(String post : grouped.keySet()){
        List<Map<String,String>> candidates = grouped.get(post);
%>

<div class="section">
    <div class="section-header">
        <h1><%=post%></h1>
        <span class="count"><%=candidates.size()%> Candidates</span>
    </div>

    <div class="table-wrapper">
        <table>
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Qualification</th>
                    <th>Experience</th>
                    <th>Shortlist</th>
                    <th>Call</th>
                    <th>Demo</th>
                    <th>Interview</th>
                    <th>Remarks</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
            <% 
            for(Map<String,String> c : candidates){
                String rowClass = "";
                if("Selected".equalsIgnoreCase(c.get("interview_status"))) rowClass="interview-selected";
                else if("Selected".equalsIgnoreCase(c.get("demo_status"))) rowClass="demo-selected";

                String json = gson.toJson(c).replace("&","&amp;").replace("\"","&quot;").replace("<","&lt;").replace(">","&gt;");
            %>
                <tr class="<%=rowClass%>">
                    <td>
                        <b><%=c.get("name")%></b><br>
                        <small><%=c.get("mobile_no")%></small>
                    </td>
                    <td>
                        <%=c.get("qualification")%><br>
                        <small><%=c.get("specialization")%></small>
                    </td>
                    <td><%=c.get("total_experience")%> Yrs</td>
                    
                    <td>
                        <% if("Yes".equalsIgnoreCase(c.get("shortlisted"))){ %>
                            <span class="badge success">Shortlisted</span>
                        <% } else if("No".equalsIgnoreCase(c.get("shortlisted"))){ %>
                            <span class="badge danger">Rejected</span>
                        <% } else { %>
                            <span class="badge warning">Review</span>
                        <% } %>
                    </td>

                    <td><%=c.get("call_status") != null ? c.get("call_status") : "-"%></td>

                    <td>
                        <% String ds = c.get("demo_status"); %>
                        <span class="badge <%= "Selected".equalsIgnoreCase(ds) ? "success" : "primary" %>">
                            <%= (ds == null || ds.isEmpty()) ? "Pending" : ds %>
                        </span>
                    </td>

                    <td>
                        <% 
                        String is = c.get("interview_status");
                        if("Selected".equalsIgnoreCase(is)){ %>
                            <span class="badge success">Selected</span>
                        <% } else if("Rejected".equalsIgnoreCase(is)){ %>
                            <span class="badge danger">Rejected</span>
                        <% } else if("Pending".equalsIgnoreCase(is) || is == null){ %>
                            <span class="badge secondary">Pending</span>
                        <% } else { %>
                            <span class="badge primary"><%=is%></span>
                        <% } %>
                    </td>

                    <td style="max-width: 150px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                        <%=c.get("remarks")%>
                    </td>

                    <td>
                        <button class="btn-primary reviewBtn" data-candidate="<%=json%>">Review</button>
                    </td>
                </tr>
            <% } %>
            </tbody>
        </table>
    </div>
</div>
<% } } %>

</div>

<div class="modal" id="editModal" style="display: none; align-items: center; justify-content: center; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 1000;">
    <div class="modal-content">
        <div class="modal-title" style="padding: 20px; background: #4f46e5; color: white; font-weight: bold; border-radius: 12px 12px 0 0;">
            Update Candidate Full Details
        </div>

        <form action="resume" method="post" class="modal-form" style="padding: 20px;">
            <input type="hidden" name="sl_no" id="f_sl_no">

            <h4>Basic Information</h4>
            <div class="form-row">
                <input type="text" name="name" id="f_name" placeholder="Full Name">
                <input type="text" name="mobile_no" id="f_mobile_no" placeholder="Mobile">
            </div>
            <div class="form-row">
                <input type="text" name="address" id="f_address" placeholder="Address">
                <input type="text" name="post_applied_for" id="f_post_applied_for" placeholder="Post Applied">
            </div>

            <h4>Education & Experience</h4>
            <div class="form-row">
                <input type="text" name="qualification" id="f_qualification" placeholder="Qualification">
                <input type="text" name="total_experience" id="f_total_experience" placeholder="Total Exp">
            </div>
            <textarea name="experience" id="f_experience" placeholder="Experience Details" style="width:100%; height:60px; margin-top:10px;"></textarea>

            <h4>Workflow Status</h4>
            <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                <div>
                    <label>Shortlist</label>
                    <select name="shortlisted" id="f_shortlisted" style="width:100%">
                        <option value="Pending">Pending</option>
                        <option value="Yes">Shortlist</option>
                        <option value="No">Reject</option>
                    </select>
                </div>
                <div>
                    <label>Demo</label>
                    <select name="demo_status" id="f_demo_status" style="width:100%">
                        <option value="Pending">Pending</option>
                        <option value="Scheduled">Scheduled</option>
                        <option value="Selected">Selected</option>
                        <option value="Rejected">Rejected</option>
                    </select>
                </div>
            </div>

            <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-top:15px;">
                <div>
                    <label>Interview Status</label>
                    <select name="interview_status" id="f_interview_status" style="width:100%">
                        <option value="Pending">Pending</option>
                        <option value="Selected">Selected</option>
                        <option value="Rejected">Rejected</option>
                    </select>
                </div>
                <div>
                    <label>Call Status</label>
                    <select name="call_status" id="f_call_status" style="width:100%">
                        <option value="Pending">Pending</option>
                        <option value="Called">Called</option>
                        <option value="Not Reachable">Not Reachable</option>
                    </select>
                </div>
            </div>

            <h4 style="margin-top:20px;">Remarks</h4>
            <textarea name="remarks" id="f_remarks" style="width:100%; height:80px;"></textarea>

            <div class="modal-buttons" style="margin-top: 20px; display: flex; justify-content: flex-end; gap: 10px;">
                <button type="button" onclick="closeModal()" class="btn-light">Cancel</button>
                <button type="submit" class="btn-primary">Save Changes</button>
            </div>
        </form>
    </div>
</div>

<script>
/* OPEN MODAL */
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

/* CLOSE MODAL */
function closeModal() {
    document.getElementById("editModal").style.display = "none";
}

// Close modal if clicking outside content
window.onclick = function(event) {
    let modal = document.getElementById("editModal");
    if (event.target == modal) {
        closeModal();
    }
}
</script>

</body>
</html>