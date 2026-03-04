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
<html>
<head>
<meta charset="UTF-8">
<title>RecruitPro | Recruitment Dashboard</title>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">

<link rel="stylesheet" href="CSS/Recruitment.css?v=5">
</head>

<body>

<!-- ================= NAVBAR ================= -->
<div class="navbar">
    <div class="logo">
        <i class="fas fa-briefcase"></i>
        RecruitPro 2026–27
    </div>
    <div class="nav-right">
        <span class="status-dot"></span>
        System Active
    </div>
</div>

<div class="main-container">

<%
List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");

int total = 0;
int shortlisted = 0;
int selected = 0;

if(rawList != null){
    total = rawList.size();
    for(Map<String,String> c : rawList){
        if("Yes".equalsIgnoreCase(c.get("shortlisted"))) shortlisted++;
        if(c.get("demo_status") != null && c.get("demo_status").toLowerCase().contains("selected"))
            selected++;
    }
}
%>

<!-- ================= KPI CARDS ================= -->
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
        <h3>Selected in Demo</h3>
        <div class="kpi-number primary"><%=selected%></div>
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
        <h2><%=post%></h2>
        <span class="count"><%=candidates.size()%> Candidates</span>
    </div>

    <div class="table-wrapper">
        <table>
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Qualification</th>
                    <th>Experience</th>
                    <th>Status</th>
                    <th>Demo</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
            <% for(Map<String,String> c : candidates){ %>
                <tr>
                    <td>
                        <div class="candidate-name"><%=c.get("name")%></div>
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
                    <td>
                        <span class="badge primary">
                        <%= (c.get("demo_status")==null)?"Pending":c.get("demo_status") %>
                        </span>
                    </td>
                    <td>
                        <button class="btn-primary" 
                        onclick='openModal(<%=new Gson().toJson(c)%>)'>
                        Review
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

<!-- ================= MODAL ================= -->
<div class="modal" id="editModal">
    <div class="modal-content">
        <div class="modal-title">Update Candidate</div>

        <form action="resume" method="post" class="modal-form">

            <input type="hidden" name="sl_no" id="f_sl_no">

            <div class="form-row">
                <input type="text" name="name" id="f_name" placeholder="Full Name">
                <input type="text" name="mobile_no" id="f_mobile_no" placeholder="Mobile">
            </div>

            <div class="form-row">
                <select name="shortlisted" id="f_shortlisted">
                    <option value="Pending">Pending</option>
                    <option value="Yes">Shortlist</option>
                    <option value="No">Reject</option>
                </select>

                <select name="demo_status" id="f_demo_status">
                    <option value="Pending">Pending</option>
                    <option value="Scheduled">Scheduled</option>
                    <option value="Selected">Selected</option>
                    <option value="Rejected">Rejected</option>
                </select>
            </div>

            <textarea name="remarks" id="f_remarks" 
            placeholder="Administrative Notes"></textarea>

            <div class="modal-buttons">
                <button type="button" onclick="closeModal()" class="btn-light">Cancel</button>
                <button type="submit" class="btn-primary">Update</button>
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
    document.getElementById('editModal').style.display='flex';
}
function closeModal(){
    document.getElementById('editModal').style.display='none';
}
</script>

</body>
</html>