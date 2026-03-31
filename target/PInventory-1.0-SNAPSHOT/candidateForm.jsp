<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Careers | Sandur Residential School</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --brand-dark: #1a2a47;
            --brand-yellow: #f1c40f;
            --brand-accent: #3498db;
            --bg-body: #f4f7f9;
            --card-bg: #ffffff;
            --border-color: #e1e4e8;
            --text-main: #333c48;
            --text-muted: #6a737d;
            --input-focus: #3498db;
        }

        * {
            box-sizing: border-box;
            -webkit-font-smoothing: antialiased;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: var(--bg-body);
            margin: 0;
            padding: 0;
            color: var(--text-main);
            line-height: 1.6;
        }

        /* --- Zoho Style Navigation --- */
        .brand-header {
            background-color: var(--brand-dark);
            padding: 1rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            position: sticky;
            top: 0;
            z-index: 1000;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .header-content {
            display: flex;
            align-items: center;
        }

        .yellow-bar {
            width: 3px;
            height: 32px;
            background-color: var(--brand-yellow);
            margin-right: 12px;
            border-radius: 2px;
        }

        .school-name {
            color: #fff;
            font-size: 1.2rem;
            font-weight: 700;
            letter-spacing: -0.5px;
        }

        .system-tag {
            background: rgba(255,255,255,0.1);
            color: var(--brand-yellow);
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
            margin-left: 10px;
            text-transform: uppercase;
            font-weight: 600;
        }

        /* --- Main Layout --- */
        .page-wrapper {
            max-width: 1000px;
            margin: 40px auto;
            padding: 0 20px;
        }

        .intro-section {
            margin-bottom: 30px;
        }

        .intro-section h1 {
            font-size: 1.8rem;
            margin-bottom: 8px;
            color: var(--brand-dark);
        }

        .intro-section p {
            color: var(--text-muted);
            font-size: 0.95rem;
        }

        .form-card {
            background: var(--card-bg);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.04), 0 10px 20px rgba(0,0,0,0.02);
            border: 1px solid var(--border-color);
            overflow: hidden;
        }

        /* --- Form Elements --- */
        .section-header {
            padding: 25px 40px 10px 40px;
            display: flex;
            align-items: center;
        }

        .section-number {
            width: 28px;
            height: 28px;
            background: #f0f4f8;
            color: var(--brand-dark);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 0.8rem;
            margin-right: 12px;
            border: 1px solid var(--border-color);
        }

        .section-title {
            font-size: 1.1rem;
            font-weight: 600;
            color: var(--brand-dark);
            letter-spacing: -0.2px;
        }

        .form-body {
            padding: 20px 40px 40px 40px;
        }

        .form-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 24px;
            margin-bottom: 30px;
        }

        .full-width { grid-column: span 2; }

        .form-group {
            display: flex;
            flex-direction: column;
        }

        label {
            font-size: 0.85rem;
            font-weight: 500;
            margin-bottom: 8px;
            color: var(--text-main);
        }

        input, select, textarea {
            padding: 10px 14px;
            border: 1.5px solid var(--border-color);
            border-radius: 8px;
            font-size: 0.95rem;
            color: var(--text-main);
            transition: all 0.2s ease;
            background-color: #fafbfc;
        }

        input:focus, select:focus, textarea:focus {
            outline: none;
            border-color: var(--brand-accent);
            background-color: #ffffff;
            box-shadow: 0 0 0 4px rgba(52, 152, 219, 0.1);
        }

        /* --- File Upload Styling --- */
        .file-input-wrapper {
            border: 2px dashed var(--border-color);
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            background: #fafbfc;
            transition: border-color 0.2s;
        }

        .file-input-wrapper:hover {
            border-color: var(--brand-accent);
        }

        /* --- Button --- */
        .footer-actions {
            padding: 30px 40px;
            background: #fafbfc;
            border-top: 1px solid var(--border-color);
            text-align: right;
        }

        .btn-submit {
            background-color: var(--brand-dark);
            color: white;
            padding: 12px 32px;
            border: none;
            border-radius: 6px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.1s, background 0.2s;
        }

        .btn-submit:hover {
            background-color: #0d1625;
            transform: translateY(-1px);
        }

        /* --- Messages --- */
        .message {
            margin: 20px 0;
            padding: 14px 20px;
            border-radius: 8px;
            font-size: 0.9rem;
            display: flex;
            align-items: center;
        }
        .success { background: #e6fffa; color: #234e52; border: 1px solid #b2f5ea; }
        .error { background: #fff5f5; color: #742a2a; border: 1px solid #fed7d7; }

        @media (max-width: 768px) {
            .form-grid { grid-template-columns: 1fr; }
            .full-width { grid-column: span 1; }
            .form-body { padding: 20px; }
            .page-wrapper { margin: 20px auto; }
        }
    </style>
</head>
<body>

<header class="brand-header">
    <div class="header-content">
        <div class="yellow-bar"></div>
        <span class="school-name">Sandur Residential School</span>
        <span class="system-tag">Recruitment</span>
    </div>
</header>

<div class="page-wrapper">
    <div class="intro-section">
        <h1>Submit Your Application</h1>
        <p>Join our team of dedicated educators. Please fill out the form below accurately.</p>
    </div>

    <%
        String msg = (String) session.getAttribute("message");
        if (msg != null) {
            String cls = msg.contains("❌") ? "error" : "success";
    %>
        <div class="message <%= cls %>">
            <span><%= msg %></span>
        </div>
    <%
            session.removeAttribute("message");
        }
    %>

    <div class="form-card">
        <form action="CandidateServlet" method="post" enctype="multipart/form-data">
            
            <div class="section-header">
                <div class="section-number">01</div>
                <div class="section-title">Personal Information</div>
            </div>
            <div class="form-body">
                <div class="form-grid">
                    <div class="form-group">
                        <label>Full Name *</label>
                        <input type="text" name="name" required placeholder="e.g. Uday Kumar">
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
                        <input type="date" required name="date_of_birth">
                    </div>
                    <div class="form-group">
                        <label>Mobile Number *</label>
                        <input type="tel" required name="mobile_no" placeholder="+91 00000 00000">
                    </div>
                    <div class="form-group full-width">
                        <label>Current Address</label>
                        <textarea name="address" required rows="2" placeholder="Street, City, State, ZIP"></textarea>
                    </div>
                </div>
            </div>

            <div class="section-header">
                <div class="section-number">02</div>
                <div class="section-title">Application Details</div>
            </div>
            <div class="form-body">
                <div class="form-grid">
                    <div class="form-group">
                        <label>Post Applied For</label>
                        <select name="post_applied_for">
                            <option value="" disabled selected>Select Post</option>
                            <option value="Mathematics Teacher">Mathematics Teacher</option>
                            <option value="English Teacher">English Teacher</option>
                            <option value="Kannada Teacher">Kannada Teacher</option>
                            <option value="Hindi Teacher">Hindi Teacher</option>
                            <option value="Social Teacher">Social Teacher</option>
                            <option value="Biology Teacher">Biology Teacher</option>
                            <option value="Physics Teacher">Physics Teacher</option>
                            <option value="Chemistry Teacher">Chemistry Teacher</option>
                            <option value="Geography Teacher">Geography Teacher</option>
                            <option value="Computer Science Teacher">Computer Science Teacher</option>
                            <option value="HR">HR</option>
                            <option value="Academic Assistant">Academic Assistant</option>
                            <option value="Environmental Applications Teacher">Environmental Applications Teacher</option>
                            <option value="Mother Teacher">Mother Teacher</option>
                            <option value="General Science Teacher">General Science Teacher</option>
                            <option value="Dance">Dance</option>
                            <option value="Music">Music</option>
                            <option value="PE Teacher">PE Teacher</option>
                            <option value="Art & Craft">Art & Craft</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Marital Status</label>
                        <select name="marital_status">
                            <option value="Single">Single</option>
                            <option value="Married">Married</option>
                        </select>
                    </div>
                    <div class="form-group full-width">
                        <label>How did you hear about us? (Reference)</label>
                        <input type="text" name="reference_by" placeholder="Referral name or Advertisement source">
                    </div>
                </div>
            </div>

            <div class="section-header">
                <div class="section-number">03</div>
                <div class="section-title">Academic & Professional</div>
            </div>
            <div class="form-body">
                <div class="form-grid">
                    <div class="form-group">
                        <label>Highest Qualification</label>
                        <input type="text" required name="qualification" placeholder="e.g. M.Sc, B.Ed">
                    </div>
                    <div class="form-group">
                        <label>Specialization</label>
                        <input type="text" required name="specialization" placeholder="e.g. Mathematics">
                    </div>
                    <div class="form-group">
                        <label>Percentage Marks (%)</label>
                        <input type="text" name="percentage_marks" placeholder="00.00%">
                    </div>
                    <div class="form-group">
                        <label>Year of Passing</label>
                        <input type="text" name="year_of_passing" placeholder="YYYY">
                    </div>
                    <div class="form-group">
                        <label>Total Experience (Years)</label>
                        <input type="text" required name="total_experience" placeholder="e.g. 5">
                    </div>
                    <div class="form-group">
                        <label>Expected Monthly Salary</label>
                        <input type="text" required name="expected_salary" placeholder="₹">
                    </div>
                    <div class="form-group full-width">
                        <label>Experience Details</label>
                        <textarea name="experience" required rows="3" placeholder="List your previous organizations and roles..."></textarea>
                    </div>
                    <div class="form-group full-width">
                        <label>Additional Remarks</label>
                        <textarea name="remarks" rows="2"></textarea>
                    </div>
                </div>
            </div>

            <div class="section-header">
                <div class="section-number">04</div>
                <div class="section-title">Resume Attachment</div>
            </div>
            <div class="form-body">
                <div class="form-group full-width">
                    <div class="file-input-wrapper">
                        <label style="display:block; cursor:pointer;">
                            <span style="color: var(--brand-accent); font-weight:600;">Click to upload</span> or drag and drop
                            <br><span style="font-size:0.75rem; color: var(--text-muted);">PDF or Word documents (Max 5MB)</span>
                            <input type="file" name="resume" accept=".pdf,.doc,.docx" required style="margin-top:10px; width:100%;">
                        </label>
                    </div>
                </div>
            </div>

            <div class="footer-actions">
                <button type="submit" class="btn-submit">Submit Application</button>
            </div>

        </form>
    </div>
</div>

</body>
</html>