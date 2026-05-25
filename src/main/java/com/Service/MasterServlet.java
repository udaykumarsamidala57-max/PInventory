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

import com.bean.DBUtil5;

@WebServlet("/MasterServlet")
public class MasterServlet extends HttpServlet {

    // =========================================
    // LOAD PAGE
    // =========================================

    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
                         throws ServletException, IOException {

        loadData(request, response);
    }

    // =========================================
    // SAVE DATA
    // =========================================

    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
                          throws ServletException, IOException {

        String action = request.getParameter("action");

        Connection con = null;
        PreparedStatement ps = null;

        try {

            con = DBUtil5.getConnection();

            // =====================================
            // ADD DEPARTMENT
            // =====================================

            if ("addDepartment".equals(action)) {

                String departmentName =
                        request.getParameter("department_name");

                String inchargeUserId =
                        request.getParameter("incharge_user_id");

                String sql =
                        "INSERT INTO departments(department_name,incharge_user_id) VALUES(?,?)";

                ps = con.prepareStatement(sql);

                ps.setString(1, departmentName);

                ps.setInt(2,
                        Integer.parseInt(inchargeUserId));

                ps.executeUpdate();
            }

            // =====================================
            // ADD COMPLAINT TYPE
            // =====================================

            else if ("addComplaintType".equals(action)) {

                String departmentId =
                        request.getParameter("department_id");

                String complaintName =
                        request.getParameter("complaint_name");

                String sql =
                        "INSERT INTO complaint_types(department_id,complaint_name) VALUES(?,?)";

                ps = con.prepareStatement(sql);

                ps.setInt(1,
                        Integer.parseInt(departmentId));

                ps.setString(2, complaintName);

                ps.executeUpdate();
            }

        } catch (Exception e) {

            e.printStackTrace();
        }

        finally {

            try {

                if (ps != null)
                    ps.close();

                if (con != null)
                    con.close();

            } catch (Exception e) {

                e.printStackTrace();
            }
        }

        // Reload page through servlet only

        response.sendRedirect("MasterServlet");
    }

    // =========================================
    // LOAD ALL DATA
    // =========================================

    private void loadData(HttpServletRequest request,
                          HttpServletResponse response)
                          throws ServletException, IOException {

        Connection con = null;

        PreparedStatement psDept = null;
        PreparedStatement psComplaint = null;

        ResultSet rsDept = null;
        ResultSet rsComplaint = null;

        ArrayList<HashMap<String,Object>> departments =
                new ArrayList<HashMap<String,Object>>();

        ArrayList<HashMap<String,Object>> complaints =
                new ArrayList<HashMap<String,Object>>();

        try {

            con = DBUtil5.getConnection();

            // =====================================
            // DEPARTMENTS
            // =====================================

            String deptSql =
                    "SELECT * FROM departments ORDER BY department_name";

            psDept = con.prepareStatement(deptSql);

            rsDept = psDept.executeQuery();

            while(rsDept.next()) {

                HashMap<String,Object> map =
                        new HashMap<String,Object>();

                map.put("id",
                        rsDept.getInt("id"));

                map.put("department_name",
                        rsDept.getString("department_name"));

                map.put("incharge_user_id",
                        rsDept.getInt("incharge_user_id"));

                departments.add(map);
            }

            // =====================================
            // COMPLAINT TYPES
            // =====================================

            String complaintSql =
                    "SELECT c.id, " +
                    "c.complaint_name, " +
                    "d.department_name " +
                    "FROM complaint_types c " +
                    "JOIN departments d " +
                    "ON c.department_id = d.id " +
                    "ORDER BY d.department_name";

            psComplaint = con.prepareStatement(complaintSql);

            rsComplaint = psComplaint.executeQuery();

            while(rsComplaint.next()) {

                HashMap<String,Object> map =
                        new HashMap<String,Object>();

                map.put("id",
                        rsComplaint.getInt("id"));

                map.put("department_name",
                        rsComplaint.getString("department_name"));

                map.put("complaint_name",
                        rsComplaint.getString("complaint_name"));

                complaints.add(map);
            }

            // =====================================
            // SEND DATA TO JSP
            // =====================================

            request.setAttribute("departments",
                                 departments);

            request.setAttribute("complaints",
                                 complaints);

            RequestDispatcher rd =
            		request.getRequestDispatcher("/Service/Mater.jsp");

            rd.forward(request, response);

        } catch (Exception e) {

            e.printStackTrace();
        }

        finally {

            try {

                if(rsDept != null)
                    rsDept.close();

                if(rsComplaint != null)
                    rsComplaint.close();

                if(psDept != null)
                    psDept.close();

                if(psComplaint != null)
                    psComplaint.close();

                if(con != null)
                    con.close();

            } catch (Exception e) {

                e.printStackTrace();
            }
        }
    }
}