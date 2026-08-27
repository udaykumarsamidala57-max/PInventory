package com.Service;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil5;

@WebServlet("/MasterServlet")
public class MasterServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
                         throws ServletException, IOException {
        
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        loadData(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
                          throws ServletException, IOException {
        
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        String branch = (String) sess.getAttribute("branch");
        String action = request.getParameter("action");

        Connection con = null;
        PreparedStatement ps = null;

        try {
            con = DBUtil5.getConnection(branch);

            // =========================================
            // ADD DEPARTMENT
            // =========================================
            if ("addDepartment".equals(action)) {
                String departmentName = request.getParameter("department_name");
                String inchargeId = request.getParameter("incharge_id");

                String sql = "INSERT INTO departments(department_name, incharge_user_id) VALUES(?,?)";
                ps = con.prepareStatement(sql);
                ps.setString(1, departmentName);
                ps.setInt(2, Integer.parseInt(inchargeId));
                ps.executeUpdate();
            }

            // =========================================
            // ADD COMPLAINT TYPE
            // =========================================
            else if ("addComplaintType".equals(action)) {
                String departmentId = request.getParameter("department_id");
                String complaintName = request.getParameter("complaint_name");

                String sql = "INSERT INTO complaint_types(department_id, complaint_name) VALUES(?,?)";
                ps = con.prepareStatement(sql);
                ps.setInt(1, Integer.parseInt(departmentId));
                ps.setString(2, complaintName);
                ps.executeUpdate();
            }

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if(ps != null) ps.close();
                if(con != null) con.close();
            } catch(Exception e){
                e.printStackTrace();
            }
        }

        response.sendRedirect("MasterServlet");
    }

    // ======================================================
    // LOAD DATA
    // ======================================================
    private void loadData(HttpServletRequest request,
                          HttpServletResponse response)
                          throws ServletException, IOException {
        
        HttpSession sess = request.getSession(false);
        String branch = (String) sess.getAttribute("branch");

        Connection con = null;
        PreparedStatement psDept = null;
        PreparedStatement psComplaint = null;
        PreparedStatement psIncharge = null;

        ResultSet rsDept = null;
        ResultSet rsComplaint = null;
        ResultSet rsIncharge = null;

        ArrayList<HashMap<String,Object>> departments = new ArrayList<HashMap<String,Object>>();
        ArrayList<HashMap<String,Object>> complaints = new ArrayList<HashMap<String,Object>>();
        ArrayList<HashMap<String,Object>> incharges = new ArrayList<HashMap<String,Object>>();

        try {
            con = DBUtil5.getConnection(branch);

            // =========================================
            // INCHARGE LIST
            // =========================================
            String inchargeSql = "SELECT id, incharge_name FROM department_incharge WHERE status='ACTIVE' ORDER BY incharge_name";
            psIncharge = con.prepareStatement(inchargeSql);
            rsIncharge = psIncharge.executeQuery();

            while(rsIncharge.next()){
                HashMap<String,Object> map = new HashMap<String,Object>();
                map.put("id", rsIncharge.getInt("id"));
                map.put("incharge_name", rsIncharge.getString("incharge_name"));
                incharges.add(map);
            }

            // =========================================
            // DEPARTMENT LIST
            // =========================================
            String deptSql = "SELECT d.id, d.department_name, i.incharge_name " +
                             "FROM departments d " +
                             "LEFT JOIN department_incharge i ON d.incharge_user_id = i.id " +
                             "ORDER BY d.department_name";
            psDept = con.prepareStatement(deptSql);
            rsDept = psDept.executeQuery();

            while(rsDept.next()){
                HashMap<String,Object> map = new HashMap<String,Object>();
                map.put("id", rsDept.getInt("id"));
                map.put("department_name", rsDept.getString("department_name"));
                map.put("incharge_name", rsDept.getString("incharge_name"));
                departments.add(map);
            }

            // =========================================
            // COMPLAINT LIST
            // =========================================
            String complaintSql = "SELECT c.id, c.complaint_name, d.department_name " +
                                  "FROM complaint_types c " +
                                  "JOIN departments d ON c.department_id = d.id " +
                                  "ORDER BY d.department_name";
            psComplaint = con.prepareStatement(complaintSql);
            rsComplaint = psComplaint.executeQuery();

            while(rsComplaint.next()){
                HashMap<String,Object> map = new HashMap<String,Object>();
                map.put("id", rsComplaint.getInt("id"));
                map.put("department_name", rsComplaint.getString("department_name"));
                map.put("complaint_name", rsComplaint.getString("complaint_name"));
                complaints.add(map);
            }

            // =========================================
            // SEND TO JSP
            // =========================================
            request.setAttribute("departments", departments);
            request.setAttribute("complaints", complaints);
            request.setAttribute("incharges", incharges);

            RequestDispatcher rd = request.getRequestDispatcher("/Service/Mater.jsp");
            rd.forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if(rsDept != null) rsDept.close();
                if(rsComplaint != null) rsComplaint.close();
                if(rsIncharge != null) rsIncharge.close();
                if(psDept != null) psDept.close();
                if(psComplaint != null) psComplaint.close();
                if(psIncharge != null) psIncharge.close();
                if(con != null) con.close();
            } catch(Exception e){
                e.printStackTrace();
            }
        }
    }
}