package com.Service;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil5;

@WebServlet("/RequestBookingServlet")
public class RequestBookingServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    Connection con = null;

    @Override
    public void init() throws ServletException {

        try {

            con = DBUtil5.getConnection();

        } catch (Exception e) {

            e.printStackTrace();
        }
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        if(action != null
        && action.equals("loadComplaintTypes")) {

            loadComplaintTypes(request,response);

        } else {

            loadDepartments(request,response);
        }
    }

    private void loadDepartments(HttpServletRequest request,
                                 HttpServletResponse response)
            throws ServletException, IOException {

        ArrayList<HashMap<String,Object>> list =
        new ArrayList<HashMap<String,Object>>();

        try {

            String sql =
            "select * from departments "
            + "order by department_name";

            PreparedStatement ps =
            con.prepareStatement(sql);

            ResultSet rs = ps.executeQuery();

            while(rs.next()) {

                HashMap<String,Object> map =
                new HashMap<String,Object>();

                map.put(
                "id",
                rs.getInt("id")
                );

                map.put(
                "department_name",
                rs.getString("department_name")
                );

                list.add(map);
            }

        } catch (Exception e) {

            e.printStackTrace();
        }

        request.setAttribute("departments", list);

        request.getRequestDispatcher(
        "/Service/request_booking.jsp"
        ).forward(request, response);
    }

    private void loadComplaintTypes(HttpServletRequest request,
                                    HttpServletResponse response)
            throws IOException {

        response.setContentType("text/html;charset=UTF-8");

        PrintWriter out = response.getWriter();

        try {

            String deptId =
            request.getParameter("department_id");

            if(deptId == null || deptId.equals("")) {

                out.println(
                "<option value=''>Select Complaint Type</option>"
                );

                return;
            }

            int departmentId =
            Integer.parseInt(deptId);

            String sql =
            "select * from complaint_types "
            + "where department_id=? "
            + "order by complaint_name";

            PreparedStatement ps =
            con.prepareStatement(sql);

            ps.setInt(1, departmentId);

            ResultSet rs = ps.executeQuery();

            out.println(
            "<option value=''>Select Complaint Type</option>"
            );

            while(rs.next()) {

                out.println(

                "<option value='"
                + rs.getInt("id")
                + "'>"

                + rs.getString("complaint_name")

                + "</option>"
                );
            }

        } catch (Exception e) {

            e.printStackTrace();

            out.println(
            "<option value=''>Unable To Load</option>"
            );
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        try {

            HttpSession session =
            request.getSession(false);

            if(session == null) {

                response.sendRedirect(
                request.getContextPath()
                + "/login.jsp"
                );

                return;
            }

            String requestedBy =
            ((String)session.getAttribute("username"))
            .toUpperCase();

            int departmentId =
            Integer.parseInt(
            request.getParameter("department_id")
            );

            int complaintTypeId =
            Integer.parseInt(
            request.getParameter("complaint_type_id")
            );

            String location =
            request.getParameter("location");

            String description =
            request.getParameter("description");

            String priority =
            request.getParameter("priority");

            int assignedTo = 0;

            String inchargeSql =

            "select id "
            + "from department_incharge "
            + "where department_id=? "
            + "and status='ACTIVE' "
            + "limit 1";

            PreparedStatement ps1 =
            con.prepareStatement(inchargeSql);

            ps1.setInt(1, departmentId);

            ResultSet rs = ps1.executeQuery();

            if(rs.next()) {

                assignedTo =
                rs.getInt("id");
            }

            /*
             * GENERATE REQUEST NUMBER
             * FORMAT : SR/2026/001
             */

            String year =
            new SimpleDateFormat("yyyy")
            .format(new Date());

            String countSql =

            "select count(*) as total "
            + "from service_requests "
            + "where year(request_date)=year(now())";

            PreparedStatement countPs =
            con.prepareStatement(countSql);

            ResultSet countRs =
            countPs.executeQuery();

            int nextNo = 1;

            if(countRs.next()) {

                nextNo =
                countRs.getInt("total") + 1;
            }

            String serialNo =
            String.format("%03d", nextNo);

            String requestNo =

            "SR/"
            + year
            + "/"
            + serialNo;

            /*
             * INSERT REQUEST
             */

            String sql =

            "insert into service_requests("
            + "request_no,"
            + "request_date,"
            + "requested_by,"
            + "department_id,"
            + "complaint_type_id,"
            + "location,"
            + "description,"
            + "priority,"
            + "assigned_to,"
            + "status"
            + ")"

            + "values("
            + "?,"     
            + "now(),"
            + "?,"     
            + "?,"     
            + "?,"     
            + "?,"     
            + "?,"     
            + "?,"     
            + "?,"     
            + "?"      
            + ")";

            PreparedStatement ps =
            con.prepareStatement(sql);

            ps.setString(1, requestNo);

            ps.setString(2, requestedBy);

            ps.setInt(3, departmentId);

            ps.setInt(4, complaintTypeId);

            ps.setString(5, location);

            ps.setString(6, description);

            ps.setString(7, priority);

            ps.setInt(8, assignedTo);

            ps.setString(9, "OPEN");

            int i = ps.executeUpdate();

            if(i > 0) {

                session.setAttribute(
                "msg",
                "Service Request Submitted Successfully : "
                + requestNo
                );

            } else {

                session.setAttribute(
                "msg",
                "Failed To Submit Request"
                );
            }

        } catch (Exception e) {

            e.printStackTrace();

            request.setAttribute(
            "msg",
            "Error : " + e.getMessage()
            );
        }

        response.sendRedirect(
        		request.getContextPath()
        		+ "/RequestBookingServlet"
        		);
    }
}