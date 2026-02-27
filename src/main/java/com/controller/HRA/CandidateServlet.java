package com.controller.HRA;

import com.bean.DBUtil2;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/CandidateServlet")
public class CandidateServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String message;

        try (Connection con = DBUtil2.getConnection()) {

            String sql = "INSERT INTO candidate_recruitment "
                    + "( name, mobile_no, address, post_applied_for, gender, date_of_birth, "
                    + "marital_status, qualification, specialization, percentage_marks, year_of_passing, "
                    + "reference_by, other_skills_certifications, experience, relevant_experience, "
                    + "total_experience, present_salary, expected_salary, remarks) "
                    + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

            PreparedStatement ps = con.prepareStatement(sql);

           
            ps.setString(1, request.getParameter("name"));
            ps.setString(2, request.getParameter("mobile_no"));
            ps.setString(3, request.getParameter("address"));
            ps.setString(4, request.getParameter("post_applied_for"));
            ps.setString(5, request.getParameter("gender"));
            ps.setString(6, request.getParameter("date_of_birth"));
            ps.setString(7, request.getParameter("marital_status"));
            ps.setString(8, request.getParameter("qualification"));
            ps.setString(9, request.getParameter("specialization"));
            ps.setString(10, request.getParameter("percentage_marks"));
            ps.setString(11, request.getParameter("year_of_passing"));
            ps.setString(12, request.getParameter("reference_by"));
            ps.setString(13, request.getParameter("other_skills_certifications"));
            ps.setString(14, request.getParameter("experience"));
            ps.setString(15, request.getParameter("relevant_experience"));
            ps.setString(16, request.getParameter("total_experience"));
            ps.setString(17, request.getParameter("present_salary"));
            ps.setString(18, request.getParameter("expected_salary"));
            ps.setString(19, request.getParameter("remarks"));

            ps.executeUpdate();
            message = "✅ Candidate data saved successfully";

        } catch (Exception e) {
            e.printStackTrace();
            message = "❌ Error while saving candidate data";
        }

        // store message in session
        request.getSession().setAttribute("message", message);

        // redirect to JSP (GET request)
        response.sendRedirect(request.getContextPath() + "/candidateForm.jsp");
    }
    
    
}