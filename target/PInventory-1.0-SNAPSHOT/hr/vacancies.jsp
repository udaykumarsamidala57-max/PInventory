<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.controller.HRA.VacancyServlet.Vacancy" %>

<%

HttpSession sess = request.getSession(false);
if (sess == null || sess.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}
    List<Vacancy> vacancies = (List<Vacancy>) request.getAttribute("vacancies");
    Vacancy editVac = (Vacancy) request.getAttribute("vacancy");
    
    boolean isEdit = (editVac != null);
    
    String filterJobType = request.getParameter("job_type");
    String filterStatus = request.getParameter("status");
    String message = request.getParameter("message");
    String error = request.getParameter("error");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Vacancies</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { 
            padding: 16px 20px; 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; 
            background: #b0c4df; 
            color: #181818; 
            font-size: 13px; 
            line-height: 1.4; 
        }
        .container { max-width: 1400px; margin: 0 auto; }
        
        /* Salesforce Page Header / Header Card */
        .page-header { 
            background: #ffffff; 
            padding: 12px 16px; 
            border: 1px solid #dddbda; 
            border-radius: 4px; 
            margin-bottom: 12px; 
            display: flex; 
            justify-content: space-between; 
            align-items: center;
            box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
        }
        .header-title-group { display: flex; align-items: center; gap: 10px; }
        .header-icon {
            width: 32px;
            height: 32px;
            background: #0070d2;
            border-radius: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #ffffff;
            font-weight: 700;
            font-size: 14px;
        }
        .header-subtitle { font-size: 11px; text-transform: uppercase; color: #514f4d; font-weight: 600; letter-spacing: 0.5px; }
        h1 { font-size: 18px; font-weight: 700; color: #080707; line-height: 1.2; }
        
        /* Salesforce Lightning Card */
        .card { 
            background: #ffffff; 
            padding: 14px 16px; 
            border: 1px solid #dddbda; 
            border-radius: 4px; 
            margin-bottom: 12px; 
            box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
        }
        .card-header { 
            display: flex; 
            align-items: center; 
            justify-content: space-between;
            margin-bottom: 12px; 
            padding-bottom: 8px; 
            border-bottom: 1px solid #dddbda; 
        }
        .card-title { font-size: 14px; font-weight: 700; color: #080707; }
        
        /* Alerts */
        .alert { padding: 8px 12px; border-radius: 4px; margin-bottom: 12px; font-size: 12px; font-weight: 600; display: flex; align-items: center; gap: 8px; }
        .alert-success { background: #e0f5ea; color: #027e46; border: 1px solid #4bca81; }
        .alert-danger { background: #fef0f0; color: #ea001e; border: 1px solid #c23934; }
        
        /* Form Styling */
        .form-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 10px 14px; }
        .form-group { display: flex; flex-direction: column; gap: 3px; }
        .form-group.full-width { grid-column: 1 / -1; }
        
        label { font-size: 11px; font-weight: 600; color: #444444; }
        label.required::after { content: " *"; color: #c23934; }
        
        select, input, textarea { 
            padding: 5px 8px; 
            border: 1px solid #dddbda; 
            border-radius: 4px; 
            font-size: 12px; 
            font-family: inherit; 
            width: 100%; 
            background: #ffffff; 
            color: #080707;
            transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
        }
        select:focus, input:focus, textarea:focus { 
            border-color: #1589ee; 
            outline: 0; 
            box-shadow: 0 0 3px #0070d2; 
        }
        textarea { resize: vertical; min-height: 48px; }

        .filter-form { display: flex; gap: 12px; align-items: flex-end; flex-wrap: wrap; }
        .filter-form .form-group { width: 180px; }

        /* Salesforce Buttons */
        .btn { 
            padding: 5px 12px; 
            border: 1px solid transparent; 
            border-radius: 4px; 
            cursor: pointer; 
            text-decoration: none; 
            font-size: 12px; 
            font-weight: 600; 
            display: inline-flex; 
            align-items: center;
            justify-content: center;
            text-align: center; 
            transition: all 0.1s ease-in-out;
            line-height: 1.4;
        }
        .btn-brand { background: #0070d2; color: #ffffff; border-color: #0070d2; }
        .btn-brand:hover { background: #005fb2; border-color: #005fb2; color: #ffffff; }
        
        .btn-neutral { background: #ffffff; color: #0070d2; border-color: #dddbda; }
        .btn-neutral:hover { background: #f4f6f9; color: #005fb2; }
        
        .btn-outline-brand { background: #ffffff; color: #0070d2; border-color: #0070d2; padding: 3px 8px; font-size: 11px; }
        .btn-outline-brand:hover { background: #f4f6f9; }
        
        .btn-destructive { background: #ffffff; color: #ea001e; border-color: #dddbda; padding: 3px 8px; font-size: 11px; }
        .btn-destructive:hover { background: #fef0f0; border-color: #c23934; }
        
        .form-actions { display: flex; gap: 8px; margin-top: 12px; border-top: 1px solid #dddbda; padding-top: 10px; }

        /* Salesforce Table */
        table { width: 100%; border-collapse: collapse; margin-top: 4px; font-size: 12px; }
        th, td { text-align: left; padding: 7px 10px; border-bottom: 1px solid #dddbda; }
        th { background: #fafaf9; color: #514f4d; font-weight: 700; text-transform: uppercase; font-size: 10px; letter-spacing: 0.5px; }
        tr:hover { background: #f3f2f2; }
        
        /* Status Badges */
        .badge { display: inline-block; padding: 2px 8px; border-radius: 10px; font-size: 10px; font-weight: 700; text-transform: uppercase; }
        .badge-open { background: #e0f5ea; color: #027e46; }
        .badge-closed { background: #fef0f0; color: #c23934; }
        .badge-draft { background: #fff8e1; color: #b78103; }
        
        .actions { display: flex; gap: 6px; white-space: nowrap; }
        .empty-state { text-align: center; padding: 20px; color: #706e6b; font-weight: 500; }
    </style>
</head>
<body>
<%@ include file="header.jsp" %>
<div class="container">

    <!-- PAGE HEADER -->
    <div class="page-header">
        <div class="header-title-group">
            <div class="header-icon">V</div>
            <div>
                <div class="header-subtitle">Recruitment Management</div>
                <h1>Vacancies</h1>
            </div>
        </div>
        <button type="button" class="btn btn-brand" onclick="toggleForm()">
            <%= isEdit ? "Edit Vacancy" : "New Vacancy" %>
        </button>
    </div>

    <% if ("added".equals(message)) { %>
        <div class="alert alert-success">Vacancy created successfully.</div>
    <% } else if ("updated".equals(message)) { %>
        <div class="alert alert-success">Vacancy updated successfully.</div>
    <% } else if ("deleted".equals(message)) { %>
        <div class="alert alert-success">Vacancy removed successfully.</div>
    <% } else if (error != null) { %>
        <div class="alert alert-danger">An error occurred while processing your request.</div>
    <% } %>

    <!-- ADD / EDIT FORM CARD -->
    <div class="card" id="formCard" style="<%= isEdit ? "display: block;" : "display: none;" %>">
        <div class="card-header">
            <span class="card-title"><%= isEdit ? "Edit Vacancy Details" : "New Vacancy Detail" %></span>
        </div>
        <form action="VacancyServlet" method="post">
            <input type="hidden" name="action" value="<%= isEdit ? "update" : "add" %>">
            <% if (isEdit) { %>
                <input type="hidden" name="id" value="<%= editVac.getId() %>">
            <% } %>

            <div class="form-grid">
                <div class="form-group">
                    <label for="f_job_type" class="required">Job Type</label>
                    <select id="f_job_type" name="job_type" required>
                        <option value="Teaching" <%= isEdit && "Teaching".equals(editVac.getJobType()) ? "selected" : "" %>>Teaching</option>
                        <option value="Non-Teaching" <%= isEdit && "Non-Teaching".equals(editVac.getJobType()) ? "selected" : "" %>>Non-Teaching</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="f_job_title" class="required">Job Title</label>
                    <input type="text" id="f_job_title" name="job_title" value="<%= isEdit && editVac.getJobTitle() != null ? editVac.getJobTitle() : "" %>" required>
                </div>

                <div class="form-group">
                    <label for="f_department">Department</label>
                    <input type="text" id="f_department" name="department" value="<%= isEdit && editVac.getDepartment() != null ? editVac.getDepartment() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_subject">Subject</label>
                    <input type="text" id="f_subject" name="subject" value="<%= isEdit && editVac.getSubject() != null ? editVac.getSubject() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_qualification">Qualification</label>
                    <input type="text" id="f_qualification" name="qualification" value="<%= isEdit && editVac.getQualification() != null ? editVac.getQualification() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_experience">Experience</label>
                    <input type="text" id="f_experience" name="experience" value="<%= isEdit && editVac.getExperience() != null ? editVac.getExperience() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_vacancies">No. Vacancies</label>
                    <input type="number" id="f_vacancies" name="number_of_vacancies" value="<%= isEdit ? editVac.getNumberOfVacancies() : 1 %>" min="1">
                </div>

                <div class="form-group">
                    <label for="f_emp_type">Employment Type</label>
                    <select id="f_emp_type" name="employment_type">
                        <option value="Full-Time" <%= isEdit && "Full-Time".equals(editVac.getEmploymentType()) ? "selected" : "" %>>Full-Time</option>
                        <option value="Part-Time" <%= isEdit && "Part-Time".equals(editVac.getEmploymentType()) ? "selected" : "" %>>Part-Time</option>
                        <option value="Contract" <%= isEdit && "Contract".equals(editVac.getEmploymentType()) ? "selected" : "" %>>Contract</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="f_salary">Salary</label>
                    <input type="text" id="f_salary" name="salary" value="<%= isEdit && editVac.getSalary() != null ? editVac.getSalary() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_location">Location</label>
                    <input type="text" id="f_location" name="location" value="<%= isEdit && editVac.getLocation() != null ? editVac.getLocation() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_start_date">Start Date</label>
                    <input type="date" id="f_start_date" name="application_start_date" value="<%= isEdit && editVac.getApplicationStartDate() != null ? editVac.getApplicationStartDate().toString() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_last_date">Last Date</label>
                    <input type="date" id="f_last_date" name="application_last_date" value="<%= isEdit && editVac.getApplicationLastDate() != null ? editVac.getApplicationLastDate().toString() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_email">Application Email</label>
                    <input type="email" id="f_email" name="application_email" value="<%= isEdit && editVac.getApplicationEmail() != null ? editVac.getApplicationEmail() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_link">Application Link</label>
                    <input type="text" id="f_link" name="application_link" value="<%= isEdit && editVac.getApplicationLink() != null ? editVac.getApplicationLink() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_contact_person">Contact Person</label>
                    <input type="text" id="f_contact_person" name="contact_person" value="<%= isEdit && editVac.getContactPerson() != null ? editVac.getContactPerson() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_contact_phone">Contact Phone</label>
                    <input type="text" id="f_contact_phone" name="contact_phone" value="<%= isEdit && editVac.getContactPhone() != null ? editVac.getContactPhone() : "" %>">
                </div>

                <div class="form-group">
                    <label for="f_status">Status</label>
                    <select id="f_status" name="status">
                        <option value="Draft" <%= isEdit && "Draft".equalsIgnoreCase(editVac.getStatus()) ? "selected" : "" %>>Draft</option>
                        <option value="Open" <%= isEdit && "Open".equalsIgnoreCase(editVac.getStatus()) ? "selected" : "" %>>Open</option>
                        <option value="Closed" <%= isEdit && "Closed".equalsIgnoreCase(editVac.getStatus()) ? "selected" : "" %>>Closed</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="f_display_order">Display Order</label>
                    <input type="number" id="f_display_order" name="display_order" value="<%= isEdit ? editVac.getDisplayOrder() : 0 %>">
                </div>

                <div class="form-group full-width">
                    <label for="f_description">Job Description</label>
                    <textarea id="f_description" name="job_description"><%= isEdit && editVac.getJobDescription() != null ? editVac.getJobDescription() : "" %></textarea>
                </div>

                <div class="form-group full-width">
                    <label for="f_responsibilities">Responsibilities</label>
                    <textarea id="f_responsibilities" name="responsibilities"><%= isEdit && editVac.getResponsibilities() != null ? editVac.getResponsibilities() : "" %></textarea>
                </div>

                <div class="form-group full-width">
                    <label for="f_skills">Skills Required</label>
                    <textarea id="f_skills" name="skills_required"><%= isEdit && editVac.getSkillsRequired() != null ? editVac.getSkillsRequired() : "" %></textarea>
                </div>
            </div>

            <div class="form-actions">
                <button type="submit" class="btn btn-brand"><%= isEdit ? "Save Changes" : "Save Record" %></button>
                <a href="VacancyServlet?action=list" class="btn btn-neutral">Cancel</a>
            </div>
        </form>
    </div>

    <!-- FILTER CARD -->
    <div class="card">
        <form action="VacancyServlet" method="get" class="filter-form">
            <input type="hidden" name="action" value="list">

            <div class="form-group">
                <label for="filter_job_type">Job Type</label>
                <select id="filter_job_type" name="job_type">
                    <option value="">All Types</option>
                    <option value="Teaching" <%= "Teaching".equals(filterJobType) ? "selected" : "" %>>Teaching</option>
                    <option value="Non-Teaching" <%= "Non-Teaching".equals(filterJobType) ? "selected" : "" %>>Non-Teaching</option>
                </select>
            </div>

            <div class="form-group">
                <label for="filter_status">Status</label>
                <select id="filter_status" name="status">
                    <option value="">All Statuses</option>
                    <option value="Open" <%= "Open".equals(filterStatus) ? "selected" : "" %>>Open</option>
                    <option value="Closed" <%= "Closed".equals(filterStatus) ? "selected" : "" %>>Closed</option>
                    <option value="Draft" <%= "Draft".equals(filterStatus) ? "selected" : "" %>>Draft</option>
                </select>
            </div>

            <button type="submit" class="btn btn-neutral">Apply Filter</button>
            <a href="VacancyServlet?action=list" class="btn btn-neutral">Reset</a>
        </form>
    </div>

    <!-- DATA TABLE CARD -->
    <div class="card" style="padding: 0;">
        <% if (vacancies != null && !vacancies.isEmpty()) { %>
            <table>
                <thead>
                    <tr>
                        <th style="width: 60px;">Order</th>
                        <th>Job Title</th>
                        <th style="width: 120px;">Type</th>
                        <th style="width: 140px;">Department</th>
                        <th style="width: 80px;">Positions</th>
                        <th style="width: 100px;">Last Date</th>
                        <th style="width: 90px;">Status</th>
                        <th style="width: 110px;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Vacancy v : vacancies) { %>
                        <tr>
                            <td><%= v.getDisplayOrder() %></td>
                            <td><strong style="color: #0070d2;"><%= v.getJobTitle() != null ? v.getJobTitle() : "" %></strong></td>
                            <td><%= v.getJobType() != null ? v.getJobType() : "" %></td>
                            <td><%= v.getDepartment() != null ? v.getDepartment() : "-" %></td>
                            <td><%= v.getNumberOfVacancies() %></td>
                            <td><%= v.getApplicationLastDate() != null ? v.getApplicationLastDate().toString() : "-" %></td>
                            <td>
                                <% 
                                    String st = v.getStatus() != null ? v.getStatus() : "Draft";
                                    String badgeClass = "badge-draft";
                                    if ("Open".equalsIgnoreCase(st)) badgeClass = "badge-open";
                                    else if ("Closed".equalsIgnoreCase(st)) badgeClass = "badge-closed";
                                %>
                                <span class="badge <%= badgeClass %>"><%= st %></span>
                            </td>
                            <td class="actions">
                                <a href="VacancyServlet?action=edit&id=<%= v.getId() %>" class="btn btn-outline-brand">Edit</a>
                                <a href="VacancyServlet?action=delete&id=<%= v.getId() %>" class="btn btn-destructive" onclick="return confirm('Are you sure you want to delete this record?');">Del</a>
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        <% } else { %>
            <div class="empty-state">No vacancy records found.</div>
        <% } %>
    </div>

</div>

<script>
    function toggleForm() {
        var card = document.getElementById('formCard');
        card.style.display = (card.style.display === 'none' || card.style.display === '') ? 'block' : 'none';
    }
</script>

</body>
</html>