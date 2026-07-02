package com.Employee;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Types;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;

import com.bean.DBUtil6;

@WebServlet("/EmployeeServlet")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 5 * 1024 * 1024,
    maxRequestSize = 10 * 1024 * 1024
)
public class Employee extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        Connection con = null;
        PreparedStatement ps = null;

        try {

            // Read Form Fields
            String empCode = request.getParameter("emp_code");
            String empName = request.getParameter("emp_name");
            String designation = request.getParameter("designation");
            String department = request.getParameter("department");
            String reportingTo = request.getParameter("reporting_to");
            String email = request.getParameter("email");
            String mobile = request.getParameter("mobile");
            String status = request.getParameter("status");

            // Debug
            System.out.println("================================");
            System.out.println("Employee Code : " + empCode);
            System.out.println("Employee Name : " + empName);
            System.out.println("Designation   : " + designation);
            System.out.println("Department    : " + department);
            System.out.println("Reporting To  : " + reportingTo);
            System.out.println("Email         : " + email);
            System.out.println("Mobile        : " + mobile);
            System.out.println("Status        : " + status);
            System.out.println("================================");

            // Get Uploaded Photo
            Part photoPart = null;

            try {
                photoPart = request.getPart("photo");

                if (photoPart != null) {
                    System.out.println("Photo Name : "
                            + photoPart.getSubmittedFileName());
                    System.out.println("Photo Size : "
                            + photoPart.getSize());
                }

            } catch (Exception ex) {
                System.out.println("Photo Upload Error");
                ex.printStackTrace();
            }

            con = DBUtil6.getConnection();

            String sql =
                    "INSERT INTO employee_master "
                  + "(emp_code, emp_name, designation, department, "
                  + "reporting_to, email, mobile, photo, status) "
                  + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

            ps = con.prepareStatement(sql);

            ps.setString(1, empCode);
            ps.setString(2, empName);
            ps.setString(3, designation);
            ps.setString(4, department);

            // Reporting To
            if (reportingTo == null || reportingTo.trim().isEmpty()) {
                ps.setNull(5, Types.INTEGER);
            } else {
                ps.setInt(5, Integer.parseInt(reportingTo));
            }

            ps.setString(6, email);
            ps.setString(7, mobile);

            // Photo BLOB
            if (photoPart != null && photoPart.getSize() > 0) {
                ps.setBinaryStream(
                        8,
                        photoPart.getInputStream(),
                        (int) photoPart.getSize());
            } else {
                ps.setNull(8, Types.BLOB);
            }

            // Status
            if (status == null || status.trim().isEmpty()) {
                status = "Active";
            }

            ps.setString(9, status);

            int result = ps.executeUpdate();

            System.out.println("Rows Inserted : " + result);

            if (result > 0) {

                response.sendRedirect(
                        request.getContextPath()
                        + "/Employee/EmployeeForm.jsp?msg=success");

            } else {

                response.sendRedirect(
                        request.getContextPath()
                        + "/Employee/EmployeeForm.jsp?msg=failed");
            }

        } catch (Exception e) {

            System.out.println("===== EMPLOYEE SAVE ERROR =====");
            e.printStackTrace();

            response.sendRedirect(
                    request.getContextPath()
                    + "/Employee/EmployeeForm.jsp?msg=error");

        } finally {

            try {
                if (ps != null)
                    ps.close();
            } catch (Exception e) {
                e.printStackTrace();
            }

            try {
                if (con != null)
                    con.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}