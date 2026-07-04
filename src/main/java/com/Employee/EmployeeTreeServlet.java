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
import java.util.Collections;
import java.util.Comparator;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.bean.DBUtil6;

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
        String tire; 
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String servletPath = request.getServletPath();

        if ("/EmployeePhoto".equals(servletPath)) {
            streamEmployeePhoto(request, response);
        } else {
            renderEmployeeTree(request, response);
        }
    }

    private void renderEmployeeTree(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
            
        List<Employee> employees = new ArrayList<>();

        try (Connection con = DBUtil6.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT emp_id, emp_code, emp_name, designation, department, reporting_to, tire "
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
                emp.tire = rs.getString("tire"); 

                int reportingTo = rs.getInt("reporting_to");
                if (rs.wasNull() || reportingTo == 0) {
                    emp.reportingTo = null;
                } else {
                    emp.reportingTo = reportingTo;
                }
                employees.add(emp);
            }

            StringBuilder treeHtml = new StringBuilder();
            Set<Integer> allIds = new HashSet<>();

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
                    
                    String listClass = isVerticalTier(emp.tire) ? " class='compact-vertical-tier' " : "";
                    treeHtml.append("<li").append(listClass).append(">");
                    
                    appendEmployeeCard(treeHtml, emp, request.getContextPath());
                    buildTree(treeHtml, emp.empId, employees, request.getContextPath(), new HashSet<>());
                    treeHtml.append("</li>");
                }
            }

            if (!rootFound && !employees.isEmpty()) {
                Employee emp = employees.get(0);
                String listClass = isVerticalTier(emp.tire) ? " class='compact-vertical-tier' " : "";
                treeHtml.append("<li").append(listClass).append(">");
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

    private void streamEmployeePhoto(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
            
        String empIdParam = request.getParameter("id");
        if (empIdParam == null || empIdParam.trim().isEmpty() || "null".equals(empIdParam)) {
            fallbackToDefaultImage(request, response);
            return;
        }

        String sql = "SELECT photo FROM employee_master WHERE emp_id = ?";

        try (Connection con = DBUtil6.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, Integer.parseInt(empIdParam));
            
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    InputStream is = rs.getBinaryStream("photo");
                    if (is != null) {
                        response.reset();
                        response.setContentType("image/jpeg");
                        try (OutputStream os = response.getOutputStream()) {
                            byte[] buffer = new byte[4096];
                            int bytesRead;
                            while ((bytesRead = is.read(buffer)) != -1) {
                                os.write(buffer, 0, bytesRead);
                            }
                            os.flush();
                        }
                        return;
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        fallbackToDefaultImage(request, response);
    }

    private void fallbackToDefaultImage(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        response.reset();
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

        List<Employee> childEmployees = new ArrayList<>();
        for (Employee emp : employees) {
            if (emp.reportingTo == null || emp.empId.equals(emp.reportingTo)) {
                continue;
            }
            if (parentId.equals(emp.reportingTo)) {
                childEmployees.add(emp);
            }
        }

        if (childEmployees.isEmpty()) {
            return;
        }

        Collections.sort(childEmployees, new Comparator<Employee>() {
            @Override
            public int compare(Employee e1, Employee e2) {
                int t1 = 0, t2 = 0;
                try { if (e1.tire != null) t1 = Integer.parseInt(e1.tire.replaceAll("[^0-9]", "")); } catch (Exception ex) {}
                try { if (e2.tire != null) t2 = Integer.parseInt(e2.tire.replaceAll("[^0-9]", "")); } catch (Exception ex) {}

                if (t1 != t2) {
                    return Integer.compare(t1, t2);
                }

                if (t1 == 3) {
                    String d1 = e1.department == null ? "" : e1.department.trim();
                    String d2 = e2.department == null ? "" : e2.department.trim();
                    int deptCompare = d1.compareToIgnoreCase(d2);
                    if (deptCompare != 0) return deptCompare;

                    int order1 = getTier3Order(e1);
                    int order2 = getTier3Order(e2);
                    if (order1 != order2) return Integer.compare(order1, order2);
                }

                String n1 = e1.empName == null ? "" : e1.empName;
                String n2 = e2.empName == null ? "" : e2.empName;
                return n1.compareToIgnoreCase(n2);
            }
        });

        // Separate standard components vs vertical block components
        List<Employee> standardComponents = new ArrayList<>();
        List<Employee> verticalComponents = new ArrayList<>();

        for (Employee e : childEmployees) {
            if (isVerticalTier(e.tire)) {
                verticalComponents.add(e);
            } else {
                standardComponents.add(e);
            }
        }

        html.append("<ul>");

        // 1. Output Standard Layout Nodes (Tiers 1-3 Departments)
        String lastSeenDept = null;
        boolean inDeptBlock = false;

        for (Employee emp : standardComponents) {
            String currentDept = (emp.department == null || emp.department.trim().isEmpty()) ? "GENERAL" : emp.department.trim();

            if (!currentDept.equalsIgnoreCase(lastSeenDept)) {
                if (inDeptBlock) {
                    html.append("</ul></li>");
                }
                html.append("<li class='dept-group-wrapper'>");
                html.append("<div class='department-header'>").append(currentDept).append("</div>");
                html.append("<ul class='inner-tier-container'>");
                lastSeenDept = currentDept;
                inDeptBlock = true;
            }

            html.append("<li>");
            appendEmployeeCard(html, emp, contextPath);
            buildTree(html, emp.empId, employees, contextPath, new HashSet<>(visited));
            html.append("</li>");
        }

        if (inDeptBlock) {
            html.append("</ul></li>");
        }

        // 2. Output Dedicated Vertical Tier 4+ Block (Separated cleanly below standard tree segments)
        if (!verticalComponents.isEmpty()) {
            html.append("<li class='vertical-group-container'>");
            html.append("<div class='tier-separator'><span>Team Members</span></div>");
            html.append("<ul class='vertical-tier'>");

            for (Employee emp : verticalComponents) {
                html.append("<li class='compact-vertical-tier'>");
                appendEmployeeCard(html, emp, contextPath);
                buildTree(html, emp.empId, employees, contextPath, new HashSet<>(visited));
                html.append("</li>");
            }

            html.append("</ul></li>");
        }

        html.append("</ul>");
    }

    private void appendEmployeeCard(StringBuilder html, Employee emp, String contextPath) {
        String tierValue = (emp.tire == null) ? "" : emp.tire.trim();

        html.append("<div class='emp");
        if ("2".equals(tierValue)) {
            html.append(" tier2-card");
        } else if ("3".equals(tierValue)) {
            html.append(" tier3-card");
        }
        html.append("' data-tier='").append(tierValue).append("'>");
        
        html.append("<div class='emp-img-container'>");
        html.append("<img src='").append(contextPath).append("/EmployeePhoto?id=").append(emp.empId)
            .append("' alt='").append(emp.empName == null ? "Employee" : emp.empName).append("'>");
        html.append("</div>"); 

        html.append("<div class='emp-details-wrapper'>"); 
        html.append("<div class='emp-name'>").append(emp.empName == null ? "" : emp.empName).append("</div>");
        html.append("<div class='emp-desg'>").append(emp.designation == null ? "" : emp.designation).append("</div>");
        html.append("<div class='emp-id'>").append(emp.empCode == null ? "" : emp.empCode).append("</div>");
        html.append("</div>"); 

        html.append("</div>");
    }

    private boolean isVerticalTier(String tireStr) {
        if (tireStr == null || tireStr.trim().isEmpty()) {
            return false;
        }
        try {
            int tierNum = Integer.parseInt(tireStr.replaceAll("[^0-9]", ""));
            return tierNum >= 4;
        } catch (NumberFormatException e) {
            return false;
        }
    }
    
    private int getTier3Order(Employee emp) {
        if (emp == null || !"3".equals(emp.tire)) {
            return 999;
        }
        String designation = emp.designation == null ? "" : emp.designation.trim();
        switch (designation) {
            case "English HOD": return 1;
            case "Kannada HOD": return 2;
            case "Hindi HOD": return 3;
            case "Maths HOD": return 4;
            case "Chemistry HOD": return 5;
            case "Physics HOD": return 6;
            case "Biology HOD": return 7;
            case "Social HOD": return 8;
            case "CS HOD": return 9;
            case "Coordinator (Boarding)": return 10;
            default: return 999;
        }
    }
}