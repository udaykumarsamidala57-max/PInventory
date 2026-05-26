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

@WebServlet("/Assign_ServiceRequestServlet")
public class Assign_ServiceRequestServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        ArrayList<HashMap<String,Object>> requestList =
        new ArrayList<HashMap<String,Object>>();

        Connection con = null;

        try {

            con = DBUtil5.getConnection();

            String sql =
            		"SELECT sr.*, di.incharge_name AS assigned_name " +
            		"FROM service_requests sr " +
            		"LEFT JOIN department_incharge di ON sr.assigned_to = di.id " +
            		"WHERE sr.status IN ('OPEN','ASSIGNED') " +
            		"ORDER BY sr.id DESC";

            PreparedStatement ps = con.prepareStatement(sql);

            ResultSet rs = ps.executeQuery();

            while(rs.next()) {

                HashMap<String,Object> map =
                new HashMap<String,Object>();

                map.put("id", rs.getInt("id"));
                map.put("request_no", rs.getString("request_no"));
                map.put("request_date", rs.getString("request_date"));
                map.put("requested_by", rs.getString("requested_by"));
                map.put("location", rs.getString("location"));
                map.put("description", rs.getString("description"));
                map.put("priority", rs.getString("priority"));
                map.put("status", rs.getString("status"));
                map.put("department_id", rs.getInt("department_id"));
                map.put("assigned_name", rs.getString("assigned_name"));
                ArrayList<HashMap<String,Object>> inchargeList =
                new ArrayList<HashMap<String,Object>>();

                PreparedStatement ps2 = con.prepareStatement(
                "SELECT * FROM department_incharge WHERE department_id=? AND status='ACTIVE'"
                );

                ps2.setInt(1, rs.getInt("department_id"));

                ResultSet rs2 = ps2.executeQuery();

                while(rs2.next()) {

                    HashMap<String,Object> inc =
                    new HashMap<String,Object>();

                    inc.put("id", rs2.getInt("id"));
                    inc.put("incharge_name",
                    rs2.getString("incharge_name"));

                    inc.put("designation",
                    rs2.getString("designation"));

                    inchargeList.add(inc);
                }

                rs2.close();
                ps2.close();

                map.put("inchargeList", inchargeList);

                requestList.add(map);
            }

            rs.close();
            ps.close();

        } catch (Exception e) {

            e.printStackTrace();
        }

        request.setAttribute("requestList", requestList);

        RequestDispatcher rd =
        request.getRequestDispatcher(
        "/Service/AssignService.jsp");

        rd.forward(request, response);
    }

    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Connection con = null;

        try {

            int requestId =
            Integer.parseInt(request.getParameter("request_id"));

            int assignedTo =
            Integer.parseInt(request.getParameter("assigned_to"));

            con = DBUtil5.getConnection();

            String sql =
            "UPDATE service_requests SET assigned_to=?, status='ASSIGNED' WHERE id=?";

            PreparedStatement ps =
            con.prepareStatement(sql);

            ps.setInt(1, assignedTo);
            ps.setInt(2, requestId);

            int i = ps.executeUpdate();

            ps.close();

            if(i > 0){

                response.sendRedirect(
                request.getContextPath()
                +"/Assign_ServiceRequestServlet?msg=success");

            }else{

                response.sendRedirect(
                request.getContextPath()
                +"/Assign_ServiceRequestServlet?msg=error");
            }

        } catch (Exception e) {

            e.printStackTrace();

            response.sendRedirect(
            request.getContextPath()
            +"/Assign_ServiceRequestServlet?msg=error");
        }
    }
}