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
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
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
            
        List<Employee> employees = new ArrayList<Employee>();

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
                    
                    String listClass = isVerticalTier(emp.tire) ? " class='compact-vertical-tier' " : "";
                    treeHtml.append("<li").append(listClass).append(">");
                    
                    appendEmployeeCard(treeHtml, emp, request.getContextPath());
                    buildTree(treeHtml, emp.empId, employees, request.getContextPath(), new HashSet<Integer>());
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
        if (empIdParam == null || empIdParam.trim().isEmpty()) {
            return;
        }

        response.reset();
        response.setContentType("image/jpeg"); 

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
                        return;
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

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

        List<Employee> childEmployees = new ArrayList<Employee>();

        for (Employee emp : employees) {
            if (emp.reportingTo == null || emp.empId.equals(emp.reportingTo)) {
                continue;
            }
            if (parentId.equals(emp.reportingTo)) {
                childEmployees.add(emp);
            }
        }

        // Sort children by Tier -> Department -> Tier 3 custom order -> Name
        Collections.sort(childEmployees, new Comparator<Employee>() {
            @Override
            public int compare(Employee e1, Employee e2) {
                int t1 = 0, t2 = 0;
                try { if(e1.tire != null) t1 = Integer.parseInt(e1.tire.replaceAll("[^0-9]", "")); } catch(Exception ex){}
                try { if(e2.tire != null) t2 = Integer.parseInt(e2.tire.replaceAll("[^0-9]", "")); } catch(Exception ex){}
                
                if (t1 != t2) {
                    return Integer.compare(t1, t2);
                }

                // If both are Tier 3, prioritize grouping by Department name
                if (t1 == 3) {
                    String d1 = e1.department == null ? "" : e1.department.trim();
                    String d2 = e2.department == null ? "" : e2.department.trim();
                    int deptComp = d1.compareToIgnoreCase(d2);
                    if (deptComp != 0) {
                        return deptComp;
                    }
                    
                    int order1 = getTier3Order(e1);
                    int order2 = getTier3Order(e2);
                    if (order1 != order2) {
                        return Integer.compare(order1, order2);
                    }
                }

                String name1 = e1.empName == null ? "" : e1.empName;
                String name2 = e2.empName == null ? "" : e2.empName;
                return name1.compareToIgnoreCase(name2);
            }
        });

        boolean found = false;
        String lastSeenDept = null;
        boolean inDeptBlock = false;

        for (Employee emp : childEmployees) {
            String currentTier = emp.tire != null ? emp.tire.trim() : "";
            boolean isTier3 = "3".equals(currentTier);

            if (!found) {
                if (hasTier4Children(parentId, employees)) {
                    html.append("<ul class='vertical-tier'>");
                } else {
                    html.append("<ul>");
                }
                found = true;
            }

            if (isTier3) {
                String currentDept = (emp.department == null || emp.department.trim().isEmpty()) ? "GENERAL" : emp.department.trim();
                
                // If department changes, close the previous block and start a new one
                if (!currentDept.equalsIgnoreCase(lastSeenDept)) {
                    if (inDeptBlock) {
                        html.append("</ul>"); // close inner-tier-container
                        html.append("</li>"); // close department wrapper li
                    }
                    
                    html.append("<li class='dept-group-wrapper'>");
                    html.append("<div class='department-header'>").append(currentDept).append("</div>");
                    html.append("<ul class='inner-tier-container'>"); // Open list to display nodes under this header
                    
                    lastSeenDept = currentDept;
                    inDeptBlock = true;
                }
            } else {
                // If we hit a non-tier-3 item after tier-3 items, safely clear the active grouping container
                if (inDeptBlock) {
                    html.append("</ul>");
                    html.append("</li>");
                    inDeptBlock = false;
                    lastSeenDept = null;
                }
            }

            String listClass = isVerticalTier(emp.tire) ? " class='compact-vertical-tier' " : "";
            
            // Only prepend normal `<li>` structural items if it's not a Tier-3 node (handled by the sub-container wrapper)
            if (!isTier3) {
                html.append("<li").append(listClass).append(">");
            } else {
                html.append("<li>");
            }

            appendEmployeeCard(html, emp, contextPath);

            buildTree(
                    html,
                    emp.empId,
                    employees,
                    contextPath,
                    new HashSet<Integer>(visited));

            html.append("</li>");
        }

        // Close any dangling sub-containers safely before finishing the execution loop
        if (inDeptBlock) {
            html.append("</ul>");
            html.append("</li>");
        }

        if (found) {
            html.append("</ul>");
        }
    }

    private void appendEmployeeCard(
            StringBuilder html,
            Employee emp,
            String contextPath) {

    	String tierValue = (emp.tire == null) ? "" : emp.tire.trim();

    	html.append("<div class='emp");

    	if ("2".equals(tierValue)) {
    	    html.append(" tier2-card");
    	} else if ("3".equals(tierValue)) {
    	    html.append(" tier3-card");
    	}

        html.append("' data-tier='")
            .append(tierValue)
            .append("'>");
        html.append("<div class='emp-img-container'>");
        
        html.append("<img src='")
            .append(contextPath)
            .append("/EmployeePhoto?id=")
            .append(emp.empId)
            .append("' alt='")
            .append(emp.empName == null ? "Employee" : emp.empName)
            .append("'>");
            
        html.append("</div>"); 

        html.append("<div class='emp-details-wrapper'>"); 
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
    
    private boolean hasTier4Children(Integer parentId, List<Employee> employees) {
        for (Employee emp : employees) {
            if (parentId.equals(emp.reportingTo) && isVerticalTier(emp.tire)) {
                return true;
            }
        }
        return false;
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