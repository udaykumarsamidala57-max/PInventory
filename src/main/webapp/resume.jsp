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
        
        /* Table Styles */
        .card { background: white; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; margin-top: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #f8fafc; padding: 15px; text-align: left; font-size: 11px; text-transform: uppercase; color: #64748b; border-bottom: 2px solid var(--border); letter-spacing: 0.05em; }
        td { padding: 12px 15px; border-bottom: 1px solid var(--border); font-size: 13px; vertical-align: middle; }
        tr:hover { background: #f8fafc; }

        /* Group Headers */
        .subject-group-header { background: #f1f5f9 !important; font-weight: 700; color: var(--primary); font-size: 14px; }
        .sl-no { color: #94a3b8; font-weight: 600; width: 40px; text-align: center; }

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
        .form-control { width: 100%; padding: 10px; border: 1px solid var(--border); border-radius: 6px; box-sizing: border-box; font-family: inherit; font-size: 14px; transition: border 0.2s; }
        .form-control:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1); }
        
        .section-divider { grid-column: span 2; padding: 15px 0 5px 0; border-bottom: 1px solid var(--border); margin-top: 10px; font-weight: 800; color: var(--text); font-size: 12px; text-transform: uppercase; letter-spacing: 1px; display: flex; align-items: center; gap: 10px; }
        .section-divider i { color: var(--primary); }

        .btn { padding: 10px 20px; border-radius: 6px; cursor: pointer; border: none; font-weight: 600; transition: all 0.2s; }
        .btn-primary { background: var(--primary); color: white; }
        .btn-primary:hover { background: #1d4ed8; }
        .btn-edit { background: white; border: 1px solid var(--border); color: var(--text); font-size: 12px; display: flex; align-items: center; gap: 5px; }
        .btn-edit:hover { background: var(--bg); border-color: #cbd5e1; }
        .footer-actions { margin-top: 30px; display: flex; justify-content: flex-end; gap: 12px; padding-top: 20px; border-top: 1px solid var(--border); }
    </style>
</head>
<body>

<div class="wrapper">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
        <h2 style="margin:0;">Candidate Management System</h2>
        <div style="font-size: 13px; color: #64748b;">
            Sorted by <strong>Post Applied For</strong>
        </div>
    </div>

    <div class="card">
        <table>
            <thead>
                <tr>
                    <th class="sl-no">#</th>
                    <th>Candidate Name</th>
                    <th>Mobile Number</th>
                    <th>Qualification</th>
                    <th>Experience</th>
                    <th>Call Status</th>
                    <th style="text-align:center">Action</th>
                </tr>
            </thead>
            <tbody>
                <%
                    List<Map<String,String>> list = (List<Map<String,String>>) request.getAttribute("resumeList");
                    if (list != null && !list.isEmpty()) {
                        // Sort list by Post Applied For
                        Collections.sort(list, new Comparator<Map<String, String>>() {
                            @Override
                            public int compare(Map<String, String> m1, Map<String, String> m2) {
                                String post1 = m1.get("post_applied_for") != null ? m1.get("post_applied_for") : "";
                                String post2 = m2.get("post_applied_for") != null ? m2.get("post_applied_for") : "";
                                return post1.compareToIgnoreCase(post2);
                            }
                        });

                        String currentPost = "";
                        int slNo = 1;
                        for (Map<String,String> row : list) {
                            String post = row.get("post_applied_for") != null ? row.get("post_applied_for") : "Unspecified Post";
                            
                            // Group Header Logic
                            if (!post.equalsIgnoreCase(currentPost)) {
                                currentPost = post;
                %>
                <tr class="subject-group-header">
                    <td colspan="7"><i class="fas fa-folder-open" style="margin-right:8px"></i> <%= currentPost.toUpperCase() %></td>
                </tr>
                <%
                            }
                %>
                <tr>
                    <td class="sl-no"><%= slNo++ %></td>
                    <td><strong><%= row.get("name") %></strong></td>
                    <td><%= row.get("mobile_no") %></td>
                    <td><%= row.get("qualification") %></td>
                    <td><%= row.get("total_experience") %> Yrs</td>
                    <td><span class="badge badge-blue"><%= row.get("call_status") %></span></td>
                    <td style="text-align:center">
                        <button class="btn btn-edit" style="margin: 0 auto;" onclick='openModal(<%= new Gson().toJson(row) %>)'>
                            <i class="fas fa-user-edit"></i> Profile
                        </button>
                    </td>
                </tr>
                <% 
                        } 
                    } else { 
                %>
                <tr>
                    <td colspan="7" style="text-align:center; padding: 40px; color: #94a3b8;">No candidate records found.</td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
</div>

<div class="modal-overlay" id="editModal">
    <div class="modal-content">
        <div class="modal-header">
            <h3 style="margin:0;"><i class="fas fa-id-card text-primary"></i> Candidate Full Profile</h3>
            <button onclick="closeModal()" style="background:none; border:none; font-size:20px; cursor:pointer; color:#64748b;">&times;</button>
        </div>
        <div class="modal-body">
            <form action="resume" method="post" class="grid-form">
                <input type="hidden" name="sl_no" id="f_sl_no">
                
                <div class="section-divider"><i class="fas fa-user"></i> Personal Information</div>
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
                    <select name="gender" id="f_gender" class="form-control">
                        <option value="Male">Male</option>
                        <option value="Female">Female</option>
                        <option value="Other">Other</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>Date of Birth</label>
                    <input type="text" name="date_of_birth" id="f_date_of_birth" class="form-control" placeholder="DD/MM/YYYY">
                </div>
                <div class="form-group full">
                    <label>Permanent Address</label>
                    <textarea name="address" id="f_address" class="form-control" rows="2"></textarea>
                </div>

                <div class="section-divider"><i class="fas fa-graduation-cap"></i> Academic Details</div>
                <div class="form-group">
                    <label>Highest Qualification</label>
                    <input type="text" name="qualification" id="f_qualification" class="form-control">
                </div>
                <div class="form-group">
                    <label>Specialization / Subject</label>
                    <input type="text" name="specialization" id="f_specialization" class="form-control">
                </div>
                <div class="form-group">
                    <label>Percentage / Marks</label>
                    <input type="text" name="percentage_marks" id="f_percentage_marks" class="form-control">
                </div>
                <div class="form-group">
                    <label>Year of Passing</label>
                    <input type="text" name="year_of_passing" id="f_year_of_passing" class="form-control">
                </div>
                <div class="form-group full">
                    <label>Reference Person</label>
                    <input type="text" name="reference_by" id="f_reference_by" class="form-control">
                </div>

                <div class="section-divider"><i class="fas fa-briefcase"></i> Experience & Salary</div>
                <div class="form-group">
                    <label>Total Experience (Years)</label>
                    <input type="text" name="total_experience" id="f_total_experience" class="form-control">
                </div>
                <div class="form-group">
                    <label>Post Applied For</label>
                    <input type="text" name="post_applied_for" id="f_post_applied_for" class="form-control">
                </div>
                <div class="form-group">
                    <label>Present Salary (Monthly)</label>
                    <input type="text" name="present_salary" id="f_present_salary" class="form-control">
                </div>
                <div class="form-group">
                    <label>Expected Salary (Monthly)</label>
                    <input type="text" name="expected_salary" id="f_expected_salary" class="form-control">
                </div>
                <div class="form-group full">
                    <label>Experience Details</label>
                    <textarea name="experience" id="f_experience" class="form-control" rows="3"></textarea>
                </div>

                <div class="section-divider"><i class="fas fa-tasks"></i> Recruitment Process</div>
                <div class="form-group">
                    <label>Calling Status</label>
                    <input type="text" name="call_status" id="f_call_status" class="form-control">
                </div>
                <div class="form-group">
                    <label>Demo Class Status</label>
                    <input type="text" name="demo_status" id="f_demo_status" class="form-control">
                </div>
                <div class="form-group">
                    <label>Final Interview Status</label>
                    <input type="text" name="interview_status" id="f_interview_status" class="form-control">
                </div>

                <div class="footer-actions full">
                    <button type="button" class="btn" onclick="closeModal()" style="background:#f1f5f9; color:#475569">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    function openModal(data) {
        // Map keys dynamically to IDs starting with f_
        for (let key in data) {
            let element = document.getElementById('f_' + key);
            if (element) {
                element.value = data[key] || '';
            }
        }
        document.getElementById('editModal').style.display = 'flex';
        document.body.style.overflow = 'hidden'; // Prevent scroll
    }

    function closeModal() {
        document.getElementById('editModal').style.display = 'none';
        document.body.style.overflow = 'auto';
    }

    // Close on overlay click
    window.onclick = function(event) {
        let modal = document.getElementById('editModal');
        if (event.target == modal) closeModal();
    }
</script>

</body>
</html>