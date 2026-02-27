<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Teacher Recruitment - Sandur Residential School</title>
    <style>
        :root {
            --brand-dark: #1a2a47; /* Dark Blue from image */
            --brand-yellow: #f1c40f; /* Yellow from image */
            --brand-accent: #3498db; /* Light Blue highlight */
            --bg-color: #f0f2f5;
            --text-main: #2c3e50;
        }

        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background-color: var(--bg-color);
            margin: 0;
            padding: 0;
            color: var(--text-main);
        }

        /* --- BRAND HEADER STYLES --- */
        .brand-header {
            background-color: var(--brand-dark);
            padding: 20px 0;
            border-bottom: 4px solid var(--brand-accent);
            display: flex;
            justify-content: center;
            align-items: center;
            box-shadow: 0 4px 10px rgba(0,0,0,0.2);
        }

        .header-content {
            display: flex;
            align-items: center;
            width: 90%;
            max-width: 1000px;
        }

        .yellow-bar {
            width: 4px;
            height: 45px;
            background-color: var(--brand-yellow);
            margin-right: 15px;
        }

        .text-group {
            display: flex;
            flex-direction: column;
        }

        .school-name {
            color: var(--brand-yellow);
            font-size: 24px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 1px;
            line-height: 1;
            margin-bottom: 4px;
        }

        .system-name {
            color: #ffffff;
            font-size: 16px;
            font-weight: 400;
            opacity: 0.9;
        }

        /* --- FORM CONTAINER STYLES --- */
        .container {
            max-width: 900px;
            margin: 30px auto;
            background: #ffffff;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
        }

        .section-title {
            background: #f8f9fa;
            padding: 10px 15px;
            border-left: 5px solid var(--brand-dark);
            margin: 25px 0 15px 0;
            font-weight: bold;
            color: var(--brand-dark);
            font-size: 1.1rem;
        }

        .form-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 20px;
        }

        .full-width { grid-column: span 2; }

        .form-group { display: flex; flex-direction: column; }

        label {
            font-weight: 600;
            margin-bottom: 8px;
            font-size: 0.9rem;
        }

        input, select, textarea {
            padding: 12px;
            border: 1px solid #ced4da;
            border-radius: 5px;
            font-size: 14px;
            transition: all 0.3s ease;
        }

        input:focus, select:focus, textarea:focus {
            border-color: var(--brand-accent);
            box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.2);
            outline: none;
        }

        .btn-submit {
            background-color: var(--brand-dark);
            color: white;
            padding: 15px 40px;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            width: 100%;
            margin-top: 30px;
            transition: background 0.3s;
        }

        .btn-submit:hover {
            background-color: #0d1625;
        }

        .message {
            text-align: center;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }

        .success { background: #d4edda; color: #155724; }
        .error { background: #f8d7da; color: #721c24; }

        /* Mobile Responsive */
        @media (max-width: 768px) {
            .form-grid { grid-template-columns: 1fr; }
            .full-width { grid-column: span 1; }
            .container { margin: 10px; padding: 20px; }
            .school-name { font-size: 18px; }
        }
    </style>
</head>
<body>

<header class="brand-header">
    <div class="header-content">
        <div class="yellow-bar"></div>
        <div class="text-group">
            <span class="school-name">Sandur Residential School</span>
            <span class="system-name">Recruitment Management System</span>
        </div>
    </div>
</header>

<div class="container">
    <%
        String msg = (String) session.getAttribute("message");
        if (msg != null) {
            String cls = msg.startsWith("❌") ? "error" : "success";
    %>
        <div class="message <%= cls %>"><%= msg %></div>
    <%
            session.removeAttribute("message");
        }
    %>

    <form action="CandidateServlet" method="post">
        
        <div class="section-title">Personal Information</div>
        <div class="form-grid">
            <div class="form-group">
                <label>Name *</label>
                <input type="text" name="name" required placeholder="Full Name">
            </div>
            <div class="form-group">
                <label>Gender</label>
                <select name="gender">
                    <option value="" disabled selected>Select Gender</option>
                    <option value="Male">Male</option>
                    <option value="Female">Female</option>
                    
                </select>
            </div>
            <div class="form-group">
                <label>Date of Birth</label>
                <input type="date" name="date_of_birth">
            </div>
            <div class="form-group">
                <label>Mobile No</label>
                <input type="text" name="mobile_no">
            </div>
            <div class="form-group full-width">
                <label>Address</label>
                <textarea name="address" rows="2"></textarea>
            </div>
        </div>

        <div class="section-title">Application Details</div>
        <div class="form-grid">
            <div class="form-group">
                <label>Post Applied For</label>
                <select name="post_applied_for">
                    <option value="" disabled selected>Select Post</option>
                    <option value="Teacher">Mathematics Teacher</option>
                    <option value="Administrator">English Teacher</option>
                    <option value="Support Staff">Social Teacher</option>
                    <option value="Support Staff">Biology Teacher</option>
                    <option value="Warden">Physics Teacher</option>
                    <option value="Warden">Chemistry Teacher</option>
                    <option value="Warden">Geography Teacher</option>
                    <option value="Warden">Computer Science Teacher</option>
                </select>
            </div>
          
            <div class="form-group">
                <label>Marital Status</label>
                <select name="marital_status">
                    <option value="Single">Single</option>
                    <option value="Married">Married</option>
                </select>
            </div>
            <div class="form-group">
                <label>Reference By</label>
                <input type="text" name="reference_by">
            </div>
        </div>

        <div class="section-title">Academic & Professional</div>
        <div class="form-grid">
            <div class="form-group">
                <label>Qualification</label>
                <input type="text" name="qualification">
            </div>
            <div class="form-group">
                <label>Specialization</label>
                <input type="text" name="specialization">
            </div>
            <div class="form-group">
                <label>Total Experience (Years)</label>
                <input type="text" name="total_experience">
            </div>
            <div class="form-group">
                <label>Expected Salary</label>
                <input type="text" name="expected_salary">
            </div>
            <div class="form-group full-width">
                <label>Experience Details</label>
                <textarea name="experience" rows="3"></textarea>
            </div>
            <div class="form-group full-width">
                <label>Remarks</label>
                <textarea name="remarks" rows="2"></textarea>
            </div>
        </div>

        <button type="submit" class="btn-submit">Submit Application</button>

    </form>
</div>

</body>
</html>