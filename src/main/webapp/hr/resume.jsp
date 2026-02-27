<%@ page import="java.util.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Admin Dashboard | Candidate Management</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #2563eb; --bg: #f1f5f9; --text: #1e293b; --border: #e2e8f0;
        }
        body { font-family: 'Inter', sans-serif; background: var(--bg); color: var(--text); margin: 0; padding: 20px; }
        .wrapper { max-width: 1300px; margin: 0 auto; }
        
        /* Table Styles */
        .card { background: white; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #f8fafc; padding: 15px; text-align: left; font-size: 12px; text-transform: uppercase; color: #64748b; border-bottom: 1px solid var(--border); }
        td { padding: 12px 15px; border-bottom: 1px solid var(--border); font-size: 14px; }
        tr:hover { background: #f8fafc; }

        /* Modal Styles */
        .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: none; align-items: center; justify-content: center; z-index: 1000; backdrop-filter: blur(4px); }
        .modal-content { background: white; width: 90%; max-width: 800px; max-height: 90vh; overflow-y: auto; border-radius: 16px; padding: 30px; position: relative; }
        
        .grid-form { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .full { grid-column: span 2; }
        
        .form-group label { display: block; font-size: 12px; font-weight: 600; margin-bottom: 5px; color: #64748b; }
        .form-control { width: 100%; padding: 10px; border: 1px solid var(--border); border-radius: 6px; box-sizing: border-box; font-family: inherit; }
        
        .section-divider { grid-column: span 2; padding: 10px 0; border-bottom: 2px solid var(--bg); margin-top: 10px; font-weight: 700; color: var(--primary); font-size: 14px; text-transform: uppercase; }

        .btn { padding: 10px 20px; border-radius: 6px; cursor: pointer; border: none; font-weight: 600; }
        .btn-primary { background: var(--primary); color: white; }
        .btn-edit { background: #dbeafe; color: var(--primary); font-size: 12px; }
        .footer-actions { margin-top: 30px; display: flex; justify-content: flex-end; gap: 10px; }
    </style>
</head>
<body>

<div class="wrapper">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:20px;">
        <h2>Candidate Database</h2>
    </div>

    <div class="card">
        <table>
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Post</th>
                    <th>Mobile</th>
                    <th>Qualification</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <%
                    List<Map<String,String>> list = (List<Map<String,String>>) request.getAttribute("resumeList");
                    if (list != null) {
                        for (Map<String,String> row : list) {
                %>
                <tr>
                    <td><strong><%= row.get("name") %></strong></td>
                    <td><%= row.get("post_applied_for") %></td>
                    <td><%= row.get("mobile_no") %></td>
                    <td><%= row.get("qualification") %></td>
                    <td><span style="color:blue"><%= row.get("call_status") %></span></td>
                    <td>
                        <button class="btn btn-edit" onclick='openModal(<%= new com.google.gson.Gson().toJson(row) %>)'>View / Edit</button>
                    </td>
                </tr>
                <% } } %>
            </tbody>
        </table>
    </div>
</div>

<div class="modal-overlay" id="editModal">
    <div class="modal-content">
        <h3>Candidate Full Profile</h3>
        <form action="resume" method="post" class="grid-form">
            <input type="hidden" name="sl_no" id="f_sl_no">
            
            <div class="section-divider">Personal Information</div>
            <div class="form-group">
                <label>Name</label>
                <input type="text" name="name" id="f_name" class="form-control">
            </div>
            <div class="form-group">
                <label>Mobile</label>
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
            <div class="form-group full">
                <label>Address</label>
                <textarea name="address" id="f_address" class="form-control" rows="2"></textarea>
            </div>

            <div class="section-divider">Academic Details</div>
            <div class="form-group">
                <label>Qualification</label>
                <input type="text" name="qualification" id="f_qualification" class="form-control">
            </div>
            <div class="form-group">
                <label>Specialization</label>
                <input type="text" name="specialization" id="f_specialization" class="form-control">
            </div>
            <div class="form-group">
                <label>Percentage / Year</label>
                <div style="display:flex; gap:5px;">
                    <input type="text" name="percentage_marks" id="f_percentage_marks" class="form-control" placeholder="%">
                    <input type="text" name="year_of_passing" id="f_year_of_passing" class="form-control" placeholder="YYYY">
                </div>
            </div>
            <div class="form-group">
                <label>Reference By</label>
                <input type="text" name="reference_by" id="f_reference_by" class="form-control">
            </div>

            <div class="section-divider">Experience & Salary</div>
            <div class="form-group">
                <label>Total Experience</label>
                <input type="text" name="total_experience" id="f_total_experience" class="form-control">
            </div>
            <div class="form-group">
                <label>Present / Expected Salary</label>
                <div style="display:flex; gap:5px;">
                    <input type="text" name="present_salary" id="f_present_salary" class="form-control" placeholder="Present">
                    <input type="text" name="expected_salary" id="f_expected_salary" class="form-control" placeholder="Expected">
                </div>
            </div>
            <div class="form-group full">
                <label>Experience Details</label>
                <textarea name="experience" id="f_experience" class="form-control" rows="3"></textarea>
            </div>

            <div class="section-divider">Recruitment Status</div>
            <div class="form-group">
                <label>Call Status</label>
                <input type="text" name="call_status" id="f_call_status" class="form-control">
            </div>
            <div class="form-group">
                <label>Demo Status</label>
                <input type="text" name="demo_status" id="f_demo_status" class="form-control">
            </div>
            <div class="form-group">
                <label>Interview Status</label>
                <input type="text" name="interview_status" id="f_interview_status" class="form-control">
            </div>
            <div class="form-group">
                <label>Applied For</label>
                <input type="text" name="post_applied_for" id="f_post_applied_for" class="form-control">
            </div>

            <div class="footer-actions full">
                <button type="button" class="btn" onclick="closeModal()" style="background:#f1f5f9">Close</button>
                <button type="submit" class="btn btn-primary">Update Database</button>
            </div>
        </form>
    </div>
</div>

<script>
    function openModal(data) {
        // Map keys dynamically to IDs starting with f_
        for (let key in data) {
            let element = document.getElementById('f_' + key);
            if (element) element.value = data[key];
        }
        document.getElementById('editModal').style.display = 'flex';
    }

    function closeModal() {
        document.getElementById('editModal').style.display = 'none';
    }
</script>

</body>
</html>