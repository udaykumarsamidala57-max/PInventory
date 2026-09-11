package com.controller.HRA;

import com.bean.DBUtil2;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/VacancyServlet")
public class VacancyServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection getConnection() throws SQLException {
        return DBUtil2.getConnection();
    }

    // Session validation helper
    private boolean isSessionInvalid(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return true;
        }
        return false;
    }

    // =========================
    // GET - LIST / EDIT / DELETE
    // =========================
    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        if (isSessionInvalid(request, response)) {
            return;
        }

        String action = request.getParameter("action");

        if ("edit".equals(action)) {
            editVacancy(request, response);
        } else if ("delete".equals(action)) {
            deleteVacancy(request, response);
        } else {
            listVacancies(request, response);
        }
    }

    // =========================
    // POST - ADD / UPDATE
    // =========================
    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        if (isSessionInvalid(request, response)) {
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");

        if ("add".equals(action)) {
            addVacancy(request, response);
        } else if ("update".equals(action)) {
            updateVacancy(request, response);
        } else {
            response.sendRedirect("VacancyServlet?action=list");
        }
    }

    // =========================
    // LIST (WITH FILTERING)
    // =========================
    private void listVacancies(HttpServletRequest request,
                               HttpServletResponse response)
            throws ServletException, IOException {

        List<Vacancy> vacancies = fetchVacancies(request);
        request.setAttribute("vacancies", vacancies);
        request.getRequestDispatcher("/hr/vacancies.jsp").forward(request, response);
    }

    private List<Vacancy> fetchVacancies(HttpServletRequest request) {
        List<Vacancy> vacancies = new ArrayList<>();
        String filterJobType = request.getParameter("job_type");
        String filterStatus = request.getParameter("status");

        StringBuilder sql = new StringBuilder("SELECT * FROM school_vacancies WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (filterJobType != null && !filterJobType.trim().isEmpty()) {
            sql.append(" AND job_type = ?");
            params.add(filterJobType.trim());
        }

        if (filterStatus != null && !filterStatus.trim().isEmpty()) {
            sql.append(" AND status = ?");
            params.add(filterStatus.trim());
        }

        sql.append(" ORDER BY display_order ASC, id DESC");

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {

            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    vacancies.add(mapResultSetToVacancy(rs));
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Unable to load vacancies.");
        }
        return vacancies;
    }

    // =========================
    // ADD
    // =========================
    private void addVacancy(HttpServletRequest request,
                            HttpServletResponse response)
            throws IOException {

        String sql =
                "INSERT INTO school_vacancies (" +
                "job_type, job_title, department, subject, " +
                "qualification, experience, number_of_vacancies, " +
                "employment_type, salary, job_description, " +
                "responsibilities, skills_required, location, " +
                "application_start_date, application_last_date, " +
                "application_email, application_link, " +
                "contact_person, contact_phone, status, display_order" +
                ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            setParameters(ps, request);
            ps.executeUpdate();

            response.sendRedirect("VacancyServlet?action=list&message=added");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("VacancyServlet?action=list&error=add");
        }
    }

    // =========================
    // EDIT
    // =========================
    private void editVacancy(HttpServletRequest request,
                             HttpServletResponse response)
            throws ServletException, IOException {

        String idStr = request.getParameter("id");

        if (idStr != null && !idStr.trim().isEmpty()) {
            String sql = "SELECT * FROM school_vacancies WHERE id=?";

            try (Connection con = getConnection();
                 PreparedStatement ps = con.prepareStatement(sql)) {

                ps.setInt(1, Integer.parseInt(idStr.trim()));

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        Vacancy v = mapResultSetToVacancy(rs);
                        request.setAttribute("vacancy", v);
                    }
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        List<Vacancy> vacancies = fetchVacancies(request);
        request.setAttribute("vacancies", vacancies);
        request.getRequestDispatcher("/hr/vacancies.jsp").forward(request, response);
    }

    // =========================
    // UPDATE
    // =========================
    private void updateVacancy(HttpServletRequest request,
                               HttpServletResponse response)
            throws IOException {

        String idStr = request.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            response.sendRedirect("VacancyServlet?action=list&error=missing_id");
            return;
        }

        String sql =
                "UPDATE school_vacancies SET " +
                "job_type=?, job_title=?, department=?, subject=?, " +
                "qualification=?, experience=?, number_of_vacancies=?, " +
                "employment_type=?, salary=?, job_description=?, " +
                "responsibilities=?, skills_required=?, location=?, " +
                "application_start_date=?, application_last_date=?, " +
                "application_email=?, application_link=?, " +
                "contact_person=?, contact_phone=?, status=?, " +
                "display_order=? WHERE id=?";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            setParameters(ps, request);
            ps.setInt(22, Integer.parseInt(idStr.trim()));

            ps.executeUpdate();

            response.sendRedirect("VacancyServlet?action=list&message=updated");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("VacancyServlet?action=list&error=update");
        }
    }

    // =========================
    // DELETE
    // =========================
    private void deleteVacancy(HttpServletRequest request,
                               HttpServletResponse response)
            throws IOException {

        String idStr = request.getParameter("id");

        if (idStr == null || idStr.trim().isEmpty()) {
            response.sendRedirect("VacancyServlet?action=list");
            return;
        }

        String sql = "DELETE FROM school_vacancies WHERE id=?";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, Integer.parseInt(idStr.trim()));
            ps.executeUpdate();

            response.sendRedirect("VacancyServlet?action=list&message=deleted");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("VacancyServlet?action=list&error=delete");
        }
    }

    // =========================
    // HELPER: MAP RS TO BEAN
    // =========================
    private Vacancy mapResultSetToVacancy(ResultSet rs) throws SQLException {
        Vacancy v = new Vacancy();
        v.setId(rs.getInt("id"));
        v.setJobType(rs.getString("job_type"));
        v.setJobTitle(rs.getString("job_title"));
        v.setDepartment(rs.getString("department"));
        v.setSubject(rs.getString("subject"));
        v.setQualification(rs.getString("qualification"));
        v.setExperience(rs.getString("experience"));
        v.setNumberOfVacancies(rs.getInt("number_of_vacancies"));
        v.setEmploymentType(rs.getString("employment_type"));
        v.setSalary(rs.getString("salary"));
        v.setJobDescription(rs.getString("job_description"));
        v.setResponsibilities(rs.getString("responsibilities"));
        v.setSkillsRequired(rs.getString("skills_required"));
        v.setLocation(rs.getString("location"));
        v.setApplicationStartDate(rs.getDate("application_start_date"));
        v.setApplicationLastDate(rs.getDate("application_last_date"));
        v.setApplicationEmail(rs.getString("application_email"));
        v.setApplicationLink(rs.getString("application_link"));
        v.setContactPerson(rs.getString("contact_person"));
        v.setContactPhone(rs.getString("contact_phone"));
        v.setStatus(rs.getString("status"));
        v.setDisplayOrder(rs.getInt("display_order"));
        return v;
    }

    // =========================
    // SET PARAMETERS
    // =========================
    private void setParameters(PreparedStatement ps,
                               HttpServletRequest request)
            throws SQLException {

        ps.setString(1, request.getParameter("job_type"));
        ps.setString(2, request.getParameter("job_title"));
        ps.setString(3, request.getParameter("department"));
        ps.setString(4, request.getParameter("subject"));
        ps.setString(5, request.getParameter("qualification"));
        ps.setString(6, request.getParameter("experience"));

        String vacancies = request.getParameter("number_of_vacancies");
        int vacCount = 1;
        if (vacancies != null && !vacancies.trim().isEmpty()) {
            try {
                vacCount = Integer.parseInt(vacancies.trim());
            } catch (NumberFormatException ignored) {}
        }
        ps.setInt(7, vacCount);

        ps.setString(8, request.getParameter("employment_type"));
        ps.setString(9, request.getParameter("salary"));
        ps.setString(10, request.getParameter("job_description"));
        ps.setString(11, request.getParameter("responsibilities"));
        ps.setString(12, request.getParameter("skills_required"));
        ps.setString(13, request.getParameter("location"));

        setDate(ps, 14, request.getParameter("application_start_date"));
        setDate(ps, 15, request.getParameter("application_last_date"));

        ps.setString(16, request.getParameter("application_email"));
        ps.setString(17, request.getParameter("application_link"));
        ps.setString(18, request.getParameter("contact_person"));
        ps.setString(19, request.getParameter("contact_phone"));
        ps.setString(20, request.getParameter("status"));

        String order = request.getParameter("display_order");
        int dispOrder = 0;
        if (order != null && !order.trim().isEmpty()) {
            try {
                dispOrder = Integer.parseInt(order.trim());
            } catch (NumberFormatException ignored) {}
        }
        ps.setInt(21, dispOrder);
    }

    private void setDate(PreparedStatement ps,
                         int index,
                         String value)
            throws SQLException {

        if (value == null || value.trim().isEmpty()) {
            ps.setNull(index, Types.DATE);
        } else {
            try {
                ps.setDate(index, Date.valueOf(value.trim()));
            } catch (IllegalArgumentException e) {
                ps.setNull(index, Types.DATE);
            }
        }
    }

    // =========================
    // BEAN
    // =========================
    public static class Vacancy {

        private int id;
        private String jobType;
        private String jobTitle;
        private String department;
        private String subject;
        private String qualification;
        private String experience;
        private int numberOfVacancies;
        private String employmentType;
        private String salary;
        private String jobDescription;
        private String responsibilities;
        private String skillsRequired;
        private String location;
        private Date applicationStartDate;
        private Date applicationLastDate;
        private String applicationEmail;
        private String applicationLink;
        private String contactPerson;
        private String contactPhone;
        private String status;
        private int displayOrder;

        public int getId() { return id; }
        public void setId(int id) { this.id = id; }

        public String getJobType() { return jobType; }
        public void setJobType(String jobType) { this.jobType = jobType; }

        public String getJobTitle() { return jobTitle; }
        public void setJobTitle(String jobTitle) { this.jobTitle = jobTitle; }

        public String getDepartment() { return department; }
        public void setDepartment(String department) { this.department = department; }

        public String getSubject() { return subject; }
        public void setSubject(String subject) { this.subject = subject; }

        public String getQualification() { return qualification; }
        public void setQualification(String qualification) { this.qualification = qualification; }

        public String getExperience() { return experience; }
        public void setExperience(String experience) { this.experience = experience; }

        public int getNumberOfVacancies() { return numberOfVacancies; }
        public void setNumberOfVacancies(int numberOfVacancies) { this.numberOfVacancies = numberOfVacancies; }

        public String getEmploymentType() { return employmentType; }
        public void setEmploymentType(String employmentType) { this.employmentType = employmentType; }

        public String getSalary() { return salary; }
        public void setSalary(String salary) { this.salary = salary; }

        public String getJobDescription() { return jobDescription; }
        public void setJobDescription(String jobDescription) { this.jobDescription = jobDescription; }

        public String getResponsibilities() { return responsibilities; }
        public void setResponsibilities(String responsibilities) { this.responsibilities = responsibilities; }

        public String getSkillsRequired() { return skillsRequired; }
        public void setSkillsRequired(String skillsRequired) { this.skillsRequired = skillsRequired; }

        public String getLocation() { return location; }
        public void setLocation(String location) { this.location = location; }

        public Date getApplicationStartDate() { return applicationStartDate; }
        public void setApplicationStartDate(Date applicationStartDate) { this.applicationStartDate = applicationStartDate; }

        public Date getApplicationLastDate() { return applicationLastDate; }
        public void setApplicationLastDate(Date applicationLastDate) { this.applicationLastDate = applicationLastDate; }

        public String getApplicationEmail() { return applicationEmail; }
        public void setApplicationEmail(String applicationEmail) { this.applicationEmail = applicationEmail; }

        public String getApplicationLink() { return applicationLink; }
        public void setApplicationLink(String applicationLink) { this.applicationLink = applicationLink; }

        public String getContactPerson() { return contactPerson; }
        public void setContactPerson(String contactPerson) { this.contactPerson = contactPerson; }

        public String getContactPhone() { return contactPhone; }
        public void setContactPhone(String contactPhone) { this.contactPhone = contactPhone; }

        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }

        public int getDisplayOrder() { return displayOrder; }
        public void setDisplayOrder(int displayOrder) { this.displayOrder = displayOrder; }
    }
}