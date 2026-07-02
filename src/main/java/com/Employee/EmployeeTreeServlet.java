package com.Employee;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.bean.DBUtil6;

// Maps this single servlet to intercept both tree rendering and dynamic image streaming requests
@WebServlet(urlPatterns = {"/EmployeeTree", "/EmployeePhoto"})
public class EmployeeTreeServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    static class Employee {
        Integer empId;
        String empCode;
        String empName;
        String designation;
        String department;
        Integer reportingTo;
    }

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Determine which endpoint the browser is targeting
        String servletPath = request.getServletPath();

        if ("/EmployeePhoto".equals(servletPath)) {
            // Route dynamically to the photo streaming logic
            streamEmployeePhoto(request, response);
        } else {
            // Default route: Build and display the Organization Chart Tree
            renderEmployeeTree(request, response);
        }
    }

    /**
     * ROUTE A: Fetches employee records, builds the organizational nesting structure,
     * and forwards the generated tree markup to your JSP view.
     */
    private void renderEmployeeTree(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
            
        List<Employee> employees = new ArrayList<Employee>();

        try (Connection con = DBUtil6.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT emp_id, emp_code, emp_name, designation, department, reporting_to "
                   + "FROM employee_master "
                   + "WHERE status='Active' "
                   + "ORDER BY emp_name");
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Employee emp = new Employee();
                emp.empId = rs.getInt("emp_id");
                emp.empCode = rs.getString("emp_code");
                emp.empName = rs.getString("emp_name");
                emp.designation = rs.getString("designation");
                emp.department = rs.getString("department");

                int reportingTo = rs.getInt("reporting_to");
                if (rs.wasNull() || reportingTo == 0) {
                    emp.reportingTo = null;
                } else {
                    emp.reportingTo = reportingTo;
                }
                employees.add(emp);
            }

            StringBuilder treeHtml = new StringBuilder();
            Set<Integer> allIds = new HashSet<Integer>();

            for (Employee emp : employees) {
                allIds.add(emp.empId);
            }

            treeHtml.append("<ul>");
            boolean rootFound = false;

            for (Employee emp : employees) {
                boolean isRoot =
                        emp.reportingTo == null
                        || !allIds.contains(emp.reportingTo)
                        || emp.empId.equals(emp.reportingTo);

                if (isRoot) {
                    rootFound = true;
                    treeHtml.append("<li>");
                    appendEmployeeCard(treeHtml, emp, request.getContextPath());
                    buildTree(treeHtml, emp.empId, employees, request.getContextPath(), new HashSet<Integer>());
                    treeHtml.append("</li>");
                }
            }

            if (!rootFound && !employees.isEmpty()) {
                Employee emp = employees.get(0);
                treeHtml.append("<li>");
                appendEmployeeCard(treeHtml, emp, request.getContextPath());
                treeHtml.append("</li>");
            }

            treeHtml.append("</ul>");

            request.setAttribute("treeHtml", treeHtml.toString());
            request.getRequestDispatcher("/Employee/EmployeeTree.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    /**
     * ROUTE B: Streams raw image binary arrays directly from your longblob column 
     * back to the frontend image tags.
     */
    private void streamEmployeePhoto(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
            
        String empIdParam = request.getParameter("id");
        if (empIdParam == null || empIdParam.trim().isEmpty()) {
            return;
        }

        response.reset();
        response.setContentType("image/jpeg"); // Signals a visual payload stream

        // Tailored directly to your validated database table schema
        String sql = "SELECT photo FROM employee_master WHERE emp_id = ?";

        try (Connection con = DBUtil6.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, Integer.parseInt(empIdParam));
            
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    InputStream is = rs.getBinaryStream("photo");
                    
                    if (is != null) {
                        OutputStream os = response.getOutputStream();
                        byte[] buffer = new byte[4096];
                        int bytesRead;
                        
                        while ((bytesRead = is.read(buffer)) != -1) {
                            os.write(buffer, 0, bytesRead);
                        }
                        os.flush();
                        return; // Done processing binary response
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // Fallback: If no custom photo blob exists, output your local web asset placeholder instead
        request.getRequestDispatcher("/images/user.png").forward(request, response);
    }

    private void buildTree(
            StringBuilder html,
            Integer parentId,
            List<Employee> employees,
            String contextPath,
            Set<Integer> visited) {

        if (parentId == null || visited.contains(parentId)) {
            return;
        }

        visited.add(parentId);
        boolean found = false;

        for (Employee emp : employees) {
            if (emp.reportingTo == null || emp.empId.equals(emp.reportingTo)) {
                continue;
            }

            if (parentId.equals(emp.reportingTo)) {
                if (!found) {
                    html.append("<ul>");
                    found = true;
                }

                html.append("<li>");
                appendEmployeeCard(html, emp, contextPath);
                buildTree(html, emp.empId, employees, contextPath, new HashSet<Integer>(visited));
                html.append("</li>");
            }
        }

        if (found) {
            html.append("</ul>");
        }
    }

    private void appendEmployeeCard(
            StringBuilder html,
            Employee emp,
            String contextPath) {

        html.append("<div class='emp'>");
        html.append("<div class='emp-img-container'>");
        
        // This targets the exact same servlet via our multi-url array mapping pattern
        html.append("<img src='")
            .append(contextPath)
            .append("/EmployeePhoto?id=")
            .append(emp.empId)
            .append("' alt='")
            .append(emp.empName == null ? "Employee" : emp.empName)
            .append("'>");
            
        html.append("</div>"); 

        html.append("<div class='emp-name'>")
            .append(emp.empName == null ? "" : emp.empName)
            .append("</div>");

        html.append("<div class='emp-desg'>")
            .append(emp.designation == null ? "" : emp.designation)
            .append("</div>");

        html.append("<div class='emp-id'>")
            .append(emp.empCode == null ? "" : emp.empCode)
            .append("</div>");

        html.append("</div>");
    }
}