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
    <title>Admin Dashboard | Candidate Management</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --primary: #2563eb; --bg: #f1f5f9; --text: #1e293b; --border: #e2e8f0; --success: #10b981;
        }
        body { font-family: 'Inter', sans-serif; background: var(--bg); color: var(--text); margin: 0; padding: 20px; }
        .wrapper { max-width: 1400px; margin: 0 auto; }
        
        /* Table and Card Styles */
        .post-container { margin-bottom: 40px; }
        .post-title { 
            display: flex; 
            align-items: center; 
            gap: 10px; 
            font-size: 18px; 
            font-weight: 700; 
            color: #0f172a; 
            margin-bottom: 15px;
            padding-left: 5px;
            border-left: 4px solid var(--primary);
        }
        
        .card { background: white; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #f8fafc; padding: 15px; text-align: left; font-size: 11px; text-transform: uppercase; color: #64748b; border-bottom: 2px solid var(--border); letter-spacing: 0.05em; }
        td { padding: 12px 15px; border-bottom: 1px solid var(--border); font-size: 13px; vertical-align: middle; }
        tr:hover { background: #f8fafc; }

        .sl-no { color: #94a3b8; font-weight: 600; width: 50px; text-align: center; background: #f8fafc; }

        /* Status Badges */
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
        .badge-blue { background: #eff6ff; color: #2563eb; border: 1px solid #bfdbfe; }

        /* Modal Styles */
        .modal-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.7); display: none; align-items: center; justify-content: center; z-index: 1000; backdrop-filter: blur(4px); }
        .modal-content { background: white; width: 95%; max-width: 850px; max-height: 90vh; overflow-y: auto; border-radius: 16px; padding: 0; position: relative; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); }
        .modal-header { padding: 20px 30px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; background: #f8fafc; }
        .modal-body { padding: 30px; }
        
        .grid-form { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .full { grid-column: span 2; }
        
        .form-group label { display: block; font-size: 12px; font-weight: 600; margin-bottom: 6px; color: #64748b; }
        .form-control { width: 100%; padding: 10px; border: 1px solid var(--border); border-radius: 6px; box-sizing: border-box; font-family: inherit; font-size: 14px; }
        
        .section-divider { grid-column: span 2; padding: 15px 0 5px 0; border-bottom: 1px solid var(--border); margin-top: 10px; font-weight: 800; color: var(--text); font-size: 12px; text-transform: uppercase; display: flex; align-items: center; gap: 10px; }

        .btn { padding: 10px 20px; border-radius: 6px; cursor: pointer; border: none; font-weight: 600; }
        .btn-primary { background: var(--primary); color: white; }
        .btn-edit { background: white; border: 1px solid var(--border); color: var(--text); font-size: 12px; display: flex; align-items: center; gap: 5px; }
        .footer-actions { margin-top: 30px; display: flex; justify-content: flex-end; gap: 12px; padding-top: 20px; border-top: 1px solid var(--border); }
    </style>
</head>
<body>

<div class="wrapper">
    <div style="margin-bottom:30px;">
        <h2 style="margin:0;">Candidate Database</h2>
        <p style="color: #64748b; margin: 5px 0 0 0;">Browse candidates grouped by their applied post.</p>
    </div>

    <%
        List<Map<String,String>> rawList = (List<Map<String,String>>) request.getAttribute("resumeList");
        if (rawList != null && !rawList.isEmpty()) {
            // Grouping logic: Map<PostName, List<Candidates>>
            Map<String, List<Map<String,String>>> groupedData = new LinkedHashMap<>();
            
            for (Map<String,String> row : rawList) {
                String post = row.get("post_applied_for");
                if (post == null || post.trim().isEmpty()) post = "General / Unspecified";
                
                if (!groupedData.containsKey(post)) {
                    groupedData.put(post, new ArrayList<>());
                }
                groupedData.get(post).add(row);
            }

            // Iterate through each group to create a separate table
            for (String postName : groupedData.keySet()) {
                List<Map<String,String>> candidates = groupedData.get(postName);
    %>
    
    <div class="post-container">
        <div class="post-title">
            <i class="fas fa-briefcase"></i> 
            <%= postName.toUpperCase() %> 
            <span style="font-weight:400; color:#94a3b8; font-size:14px;">(<%= candidates.size() %> candidates)</span>
        </div>
        
        <div class="card">
            <table>
                <thead>
                    <tr>
                        <th class="sl-no">SL</th>
                        <th>Candidate Name</th>
                        <th>Mobile</th>
                        <th>Qualification</th>
                        <th>Experience</th>
                        <th>Status</th>
                        <th style="text-align:center">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        int serialNo = 1;
                        for (Map<String,String> candidate : candidates) {
                    %>
                    <tr>
                        <td class="sl-no"><%= serialNo++ %></td>
                        <td><strong><%= candidate.get("name") %></strong></td>
                        <td><%= candidate.get("mobile_no") %></td>
                        <td><%= candidate.get("qualification") %></td>
                        <td><%= candidate.get("total_experience") %> Years</td>
                        <td><span class="badge badge-blue"><%= candidate.get("call_status") %></span></td>
                        <td style="text-align:center">
                            <button class="btn btn-edit" style="margin: 0 auto;" onclick='openModal(<%= new Gson().toJson(candidate) %>)'>
                                <i class="fas fa-user-edit"></i> View Profile
                            </button>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

    <% 
            } // End group iteration
        } else { 
    %>
    <div class="card" style="padding: 50px; text-align: center; color: #94a3b8;">
        <i class="fas fa-users-slash" style="font-size: 48px; margin-bottom: 20px;"></i>
        <h3>No candidates found in the database.</h3>
    </div>
    <% } %>
</div>

<div class="modal-overlay" id="editModal">
    <div class="modal-content">
        <div class="modal-header">
            <h3 style="margin:0;"><i class="fas fa-id-card"></i> Candidate Full Profile</h3>
            <button onclick="closeModal()" style="background:none; border:none; font-size:20px; cursor:pointer;">&times;</button>
        </div>
        <div class="modal-body">
            <form action="resume" method="post" class="grid-form">
                <input type="hidden" name="sl_no" id="f_sl_no">
                
                <div class="section-divider"><i class="fas fa-user"></i> Personal Details</div>
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
                    <input type="text" name="gender" id="f_gender" class="form-control">
                </div>
                <div class="form-group">
                    <label>DOB</label>
                    <input type="text" name="date_of_birth" id="f_date_of_birth" class="form-control">
                </div>
                
                <div class="section-divider"><i class="fas fa-graduation-cap"></i> Academic & Experience</div>
                <div class="form-group">
                    <label>Qualification</label>
                    <input type="text" name="qualification" id="f_qualification" class="form-control">
                </div>
                <div class="form-group">
                    <label>Total Experience</label>
                    <input type="text" name="total_experience" id="f_total_experience" class="form-control">
                </div>
                <div class="form-group">
                    <label>Post Applied For</label>
                    <input type="text" name="post_applied_for" id="f_post_applied_for" class="form-control">
                </div>
                <div class="form-group">
                    <label>Expected Salary</label>
                    <input type="text" name="expected_salary" id="f_expected_salary" class="form-control">
                </div>

                <div class="section-divider"><i class="fas fa-info-circle"></i> Status Tracking</div>
                <div class="form-group">
                    <label>Call Status</label>
                    <input type="text" name="call_status" id="f_call_status" class="form-control">
                </div>
                <div class="form-group">
                    <label>Demo Status</label>
                    <input type="text" name="demo_status" id="f_demo_status" class="form-control">
                </div>

                <div class="footer-actions full">
                    <button type="button" class="btn" onclick="closeModal()" style="background:#f1f5f9;">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    function openModal(data) {
        for (let key in data) {
            let element = document.getElementById('f_' + key);
            if (element) element.value = data[key] || '';
        }
        document.getElementById('editModal').style.display = 'flex';
        document.body.style.overflow = 'hidden';
    }

    function closeModal() {
        document.getElementById('editModal').style.display = 'none';
        document.body.style.overflow = 'auto';
    }
</script>

</body>
</html>