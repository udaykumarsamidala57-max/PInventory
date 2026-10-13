<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil2" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Job Application | Sandur Residential School</title>
    <link href="https://fonts.googleapis.com/css2?family=Salesforce+Sans,SalesforceSans,-apple-system,BlinkMacSystemFont,Segoe+UI,Roboto,Helvetica,Arial,sans-serif" rel="stylesheet">
    <style>
        :root {
            /* Brown & Orange Palette */
            --slds-brand: #e05600;            /* Warm Orange Accent */
            --slds-brand-hover: #c44700;      /* Darker Orange Hover */
            --slds-brand-dark: #3d2314;       /* Chocolate Brown Header/Accent */
            --slds-bg-page: #f6f3f0;          /* Subtle Warm Grey/Cream */
            --slds-bg-card: #ffffff;
            --slds-border: #e8d8ce;          /* Soft Brownish Border */
            --slds-border-focus: #e05600;    /* Focus Ring Orange */
            --slds-text-primary: #2b1d14;    /* Dark Warm Brown Text */
            --slds-text-secondary: #5c473a;  /* Medium Earthy Brown Text */
            --slds-text-muted: #8c7365;     /* Muted Earthy Brown Text */
            --slds-error: #ba0505;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--slds-bg-page);
            color: var(--slds-text-primary);
            line-height: 1.5;
            padding: 32px 16px;
        }

        /* --- Page Layout --- */
        .page-container {
            max-width: 840px;
            margin: 0 auto;
        }

        /* Salesforce Style Header Block */
        .page-header {
            background: var(--slds-bg-card);
            border: 1px solid var(--slds-border);
            border-radius: 4px 4px 0 0;
            padding: 20px 24px;
            border-bottom: 3px solid var(--slds-brand);
            text-align: center;
        }

        .page-header h1 {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--slds-brand-dark);
            margin-bottom: 2px;
        }

        .page-header .subtitle {
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--slds-brand);
            font-weight: 700;
        }

        .form-card {
            background: var(--slds-bg-card);
            border: 1px solid var(--slds-border);
            border-top: none;
            border-radius: 0 0 4px 4px;
            box-shadow: 0 2px 6px rgba(61, 35, 20, 0.05);
        }

        /* --- Section Styling --- */
        .form-section {
            padding: 24px;
            border-bottom: 1px solid var(--slds-border);
        }

        .form-section:last-of-type {
            border-bottom: none;
        }

        .section-header {
            display: flex;
            align-items: center;
            margin-bottom: 16px;
            padding-bottom: 8px;
            border-bottom: 1px solid #f4ece7;
        }

        .section-title {
            font-size: 0.95rem;
            font-weight: 700;
            color: var(--slds-brand-dark);
            text-transform: uppercase;
            letter-spacing: 0.03em;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .section-title::before {
            content: '';
            display: inline-block;
            width: 4px;
            height: 14px;
            background-color: var(--slds-brand);
            border-radius: 2px;
        }

        /* Form Grid System */
        .form-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 16px 20px;
        }

        .full-width {
            grid-column: span 2;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        label {
            font-size: 0.75rem;
            font-weight: 600;
            color: var(--slds-text-secondary);
        }

        label .required {
            color: var(--slds-error);
            margin-left: 2px;
        }

        /* Form Controls */
        input[type="text"],
        input[type="tel"],
        input[type="date"],
        select,
        textarea {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid var(--slds-border);
            border-radius: 4px;
            font-size: 0.875rem;
            color: var(--slds-text-primary);
            background-color: #ffffff;
            transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
        }

        input:hover, select:hover, textarea:hover {
            border-color: #cbb5a7;
        }

        input:focus, select:focus, textarea:focus {
            outline: none;
            border-color: var(--slds-border-focus);
            box-shadow: 0 0 0 1px var(--slds-border-focus) inset, 0 0 3px rgba(224, 86, 0, 0.4);
        }

        select {
            appearance: none;
            background-image: url("data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%238c7365%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5-1.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E");
            background-repeat: no-repeat;
            background-position: right 10px center;
            background-size: 9px auto;
            padding-right: 28px;
        }

        textarea {
            resize: vertical;
        }

        /* --- File Upload (Warm Accent Box) --- */
        .file-upload-box {
            border: 1px dashed var(--slds-brand);
            border-radius: 4px;
            padding: 16px;
            text-align: center;
            background-color: #fdfaf7;
            cursor: pointer;
            transition: background-color 0.15s, border-color 0.15s;
        }

        .file-upload-box:hover {
            background-color: #f7eee7;
        }

        .file-upload-box span {
            font-size: 0.8125rem;
            color: var(--slds-brand);
            font-weight: 600;
        }

        .file-upload-box input[type="file"] {
            display: none;
        }

        /* --- Footer & Actions --- */
        .form-footer {
            padding: 16px 24px;
            background: #f8f4f0;
            border-top: 1px solid var(--slds-border);
            display: flex;
            justify-content: flex-end;
            gap: 12px;
            border-radius: 0 0 4px 4px;
        }

        .btn-submit {
            background-color: var(--slds-brand);
            color: #ffffff;
            border: 1px solid var(--slds-brand);
            padding: 8px 24px;
            border-radius: 4px;
            font-size: 0.8125rem;
            font-weight: 600;
            cursor: pointer;
            transition: background-color 0.15s;
        }

        .btn-submit:hover {
            background-color: var(--slds-brand-hover);
            border-color: var(--slds-brand-hover);
        }

        /* --- System Alerts --- */
        .alert {
            padding: 12px 16px;
            border-radius: 4px;
            font-size: 0.85rem;
            font-weight: 500;
            margin-bottom: 16px;
        }
        .alert-success { background-color: #f0f7f0; color: #2e7d32; border: 1px solid #a5d6a7; }
        .alert-error { background-color: #fdf2f2; color: var(--slds-error); border: 1px solid #f8b4b4; }

        @media (max-width: 640px) {
            body { padding: 12px; }
            .form-grid { grid-template-columns: 1fr; }
            .full-width { grid-column: span 1; }
            .form-section { padding: 16px; }
            .page-header { padding: 16px; }
        }
    </style>
</head>
<body>

<div class="page-container">

    <%
        String msg = (String) session.getAttribute("message");
        if (msg != null) {
            String alertType = msg.contains("❌") ? "alert-error" : "alert-success";
    %>
        <div class="alert <%= alertType %>">
            <%= msg %>
        </div>
    <%
            session.removeAttribute("message");
        }
    %>

    <div class="page-header">
        <h1>Sandur Residential School</h1>
        <div class="subtitle">Candidate Application Form</div>
    </div>

    <div class="form-card">
        <form action="CandidateServlet" method="post" enctype="multipart/form-data">
            
            <!-- Section 1: Personal Details -->
            <div class="form-section">
                <div class="section-header">
                    <span class="section-title">Personal Information</span>
                </div>
                <div class="form-grid">
                    <div class="form-group">
                        <label>Full Name <span class="required">*</span></label>
                        <input type="text" name="name" required placeholder="First and Last Name">
                    </div>
                    <div class="form-group">
                        <label>Gender</label>
                        <select name="gender">
                            <option value="" disabled selected>-- Select --</option>
                            <option value="Male">Male</option>
                            <option value="Female">Female</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Date of Birth <span class="required">*</span></label>
                        <input type="date" required name="date_of_birth">
                    </div>
                    <div class="form-group">
                        <label>Mobile Phone <span class="required">*</span></label>
                        <input type="tel" required name="mobile_no" placeholder="+91 00000 00000">
                    </div>
                    <div class="form-group full-width">
                        <label>Current Address <span class="required">*</span></label>
                        <input type="text" name="address" required placeholder="Street, City, State, ZIP Code">
                    </div>
                </div>
            </div>

            <!-- Section 2: Application Details -->
            <div class="form-section">
                <div class="section-header">
                    <span class="section-title">Position & Referral</span>
                </div>
                <div class="form-grid">
                    <div class="form-group">
                        <label>Post Applied For <span class="required">*</span></label>
                        <select name="post_applied_for" required>
                            <option value="" disabled selected>-- Select Position --</option>
                            <%
                                Connection conn = null;
                                PreparedStatement ps = null;
                                ResultSet rs = null;
                                try {
                                    conn = DBUtil2.getConnection();
                                    String query = "SELECT job_type, job_title FROM school_vacancies ORDER BY job_type DESC, job_title ASC";
                                    ps = conn.prepareStatement(query);
                                    rs = ps.executeQuery();

                                    String currentGroup = "";
                                    boolean hasResults = false;

                                    while (rs.next()) {
                                        hasResults = true;
                                        String jobType = rs.getString("job_type");
                                        String jobTitle = rs.getString("job_title");

                                        if (!jobType.equals(currentGroup)) {
                                            if (!currentGroup.isEmpty()) {
                                                out.println("</optgroup>");
                                            }
                                            currentGroup = jobType;
                                            out.println("<optgroup label='" + currentGroup + " Staff'>");
                                        }
                            %>
                                        <option value="<%= jobTitle %>"><%= jobTitle %></option>
                            <%
                                    }
                                    if (!currentGroup.isEmpty()) {
                                        out.println("</optgroup>");
                                    }
                                    if (!hasResults) {
                            %>
                                        <option value="" disabled>No current openings</option>
                            <%
                                    }
                                } catch (Exception e) {
                                    e.printStackTrace();
                            %>
                                    <option value="" disabled>Error loading positions</option>
                            <%
                                } finally {
                                    if (rs != null) try { rs.close(); } catch (SQLException e) {}
                                    if (ps != null) try { ps.close(); } catch (SQLException e) {}
                                    if (conn != null) try { conn.close(); } catch (SQLException e) {}
                                }
                            %>
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
                        <label>Referral Source / How did you hear about us?</label>
                        <input type="text" name="reference_by" placeholder="e.g. Employee referral, Job Board, Newspaper">
                    </div>
                </div>
            </div>

            <!-- Section 3: Professional & Experience -->
            <div class="form-section">
                <div class="section-header">
                    <span class="section-title">Education & Work Experience</span>
                </div>
                <div class="form-grid">
                    <div class="form-group">
                        <label>Highest Qualification <span class="required">*</span></label>
                        <input type="text" required name="qualification" placeholder="e.g. M.Sc, B.Ed">
                    </div>
                    <div class="form-group">
                        <label>Specialization / Major <span class="required">*</span></label>
                        <input type="text" required name="specialization" placeholder="e.g. Mathematics, English">
                    </div>
                    <div class="form-group">
                        <label>Percentage Marks (%)</label>
                        <input type="text" name="percentage_marks" placeholder="e.g. 82.5%">
                    </div>
                    <div class="form-group">
                        <label>Year of Graduation</label>
                        <input type="text" name="year_of_passing" placeholder="YYYY">
                    </div>
                    <div class="form-group">
                        <label>Total Experience (Years) <span class="required">*</span></label>
                        <input type="text" required name="total_experience" placeholder="e.g. 5">
                    </div>
                    <div class="form-group">
                        <label>Expected Monthly Salary <span class="required">*</span></label>
                        <input type="text" required name="expected_salary" placeholder="₹">
                    </div>
                    <div class="form-group full-width">
                        <label>Work History Summary <span class="required">*</span></label>
                        <textarea name="experience" required rows="3" placeholder="Provide details of past employers, positions held, and key responsibilities..."></textarea>
                    </div>
                    <div class="form-group full-width">
                        <label>Additional Notes / Remarks</label>
                        <input type="text" name="remarks" placeholder="Any additional information you wish to disclose">
                    </div>
                </div>
            </div>

            <!-- Section 4: Resume Attachment -->
            <div class="form-section">
                <div class="section-header">
                    <span class="section-title">Resume Upload</span>
                </div>
                <div class="form-group full-width">
                    <label class="file-upload-box" for="resume-upload">
                        <span id="file-label">Upload Resume (.pdf, .doc, .docx - Max 5MB)</span>
                        <input type="file" id="resume-upload" name="resume" accept=".pdf,.doc,.docx" required onchange="document.getElementById('file-label').innerText = this.files[0] ? 'Selected: ' + this.files[0].name : 'Upload Resume (.pdf, .doc, .docx - Max 5MB)'">
                    </label>
                </div>
            </div>

            <div class="form-footer">
                <button type="submit" class="btn-submit">Submit Application</button>
            </div>

        </form>
    </div>
</div>

</body>
</html>