package com.Service;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
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

@WebServlet("/TrackRequestServlet")
public class TrackRequestServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Connection con = null;

        try {

            HttpSession session =
            request.getSession(false);

            if(session == null ||
            session.getAttribute("username") == null){

                response.sendRedirect(
                request.getContextPath()
                + "/login.jsp");

                return;
            }

            String username =
            String.valueOf(
            session.getAttribute("username"))
            .trim();
            String role =
                    String.valueOf(
                    session.getAttribute("role"))
                    .trim();

            con = DBUtil5.getConnection();

            ArrayList<HashMap<String,Object>>
            requestList =
            new ArrayList<HashMap<String,Object>>();

            boolean isSecretary =
            		role.equalsIgnoreCase("Global12");

            		boolean isAdmin =
            		role.equalsIgnoreCase("Admin12");
            		
            		boolean isveeresh =
            				username.equalsIgnoreCase("A_Veeresh12");

            		String sql = "";

            		if(isSecretary){

            		    sql =

            		    "SELECT sr.*, " +
            		    "di.incharge_name AS assigned_name " +

            		    "FROM service_requests sr " +

            		    "LEFT JOIN department_incharge di " +
            		    "ON sr.assigned_to = di.id " +

            		    "ORDER BY sr.id DESC";

            		}else if(isAdmin ||isveeresh){

            		    sql =

            		    "SELECT sr.*, " +
            		    "di.incharge_name AS assigned_name " +

            		    "FROM service_requests sr " +

            		    "LEFT JOIN department_incharge di " +
            		    "ON sr.assigned_to = di.id " +

            		    "LEFT JOIN departments d " +
            		    "ON sr.department_id = d.id " +

            		    "WHERE UPPER(d.department_name) IN " +
            		    "('ELECTRICAL','PLUMBING','HOUSEKEEPING') " +

            		    "AND COALESCE(TRIM(UPPER(sr.status)),'') <> 'SATISFIED' " +

            		    "ORDER BY sr.id DESC";

            		}else{

            			sql =

            				    "SELECT sr.*, " +
            				    "di.incharge_name AS assigned_name " +

            				    "FROM service_requests sr " +

            				    "LEFT JOIN department_incharge di " +
            				    "ON sr.assigned_to = di.id " +

            				    "WHERE UPPER(sr.requested_by)=? " +

            				    "AND COALESCE(TRIM(UPPER(sr.status)),'') NOT IN ('SATISFIED','CLOSED') " +

            				    "ORDER BY sr.id DESC";
            		}

            		PreparedStatement ps =
            				con.prepareStatement(sql);

            		if(!isSecretary && !isAdmin && !isveeresh){

            		    ps.setString(1,
            		    username.toUpperCase());
            		}

            				ResultSet rs =
            				ps.executeQuery();

            while(rs.next()){

                HashMap<String,Object> map =
                new HashMap<String,Object>();

                int requestId =
                rs.getInt("id");

                map.put("id", requestId);

                map.put("request_no",
                rs.getString("request_no"));

                map.put("request_date",
                rs.getString("request_date"));
                
                map.put("requested_by",
                		 rs.getString("requested_by"));
                
                map.put("location",
                rs.getString("location"));

                map.put("description",
                rs.getString("description"));

                map.put("priority",
                rs.getString("priority"));

                map.put("status",
                rs.getString("status"));

                map.put("assigned_name",
                rs.getString("assigned_name"));

                map.put("requested_by",
                rs.getString("requested_by"));

                ArrayList<HashMap<String,Object>>
                followupList =
                new ArrayList<HashMap<String,Object>>();

                String followupSql = "";

                if(isSecretary){

                    followupSql =

                    "SELECT * FROM followups " +
                    "WHERE request_id=? " +
                    "ORDER BY updated_on DESC " +
                    "LIMIT 200";

                }else{

                    followupSql =

                    "SELECT * FROM followups " +
                    "WHERE request_id=? " +
                    "AND COALESCE(TRIM(UPPER(status)),'') <> 'SATISFIED' " +
                    "ORDER BY updated_on DESC " +
                    "LIMIT 200";
                }

                PreparedStatement ps2 =
                con.prepareStatement(
                followupSql);

                ps2.setInt(1, requestId);

                ResultSet rs2 =
                ps2.executeQuery();

                while(rs2.next()){

                    HashMap<String,Object> f =
                    new HashMap<String,Object>();

                    f.put("remarks",
                    rs2.getString("remarks"));

                    f.put("status",
                    rs2.getString("status"));

                    f.put("updated_by",
                    rs2.getString("updated_by"));

                    Timestamp ts =
                    rs2.getTimestamp(
                    "updated_on");

                    String formattedDate = "";

                    if(ts != null){

                        formattedDate =
                        new SimpleDateFormat(
                        "dd MMM yyyy hh:mm a")
                        .format(ts);
                    }

                    f.put("updated_on",
                    formattedDate);

                    followupList.add(f);
                }

                rs2.close();
                ps2.close();

                map.put(
                "followupList",
                followupList);

                requestList.add(map);
            }

            rs.close();
            ps.close();

            request.setAttribute(
            "requestList",
            requestList);

            request.setAttribute(
            "isSecretary",
            isSecretary);

        } catch (Exception e) {

            e.printStackTrace();
        }

        RequestDispatcher rd =
        request.getRequestDispatcher(
        "/Service/TrackRequest.jsp");

        rd.forward(request, response);
    }

    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Connection con = null;

        try {

            HttpSession session =
            request.getSession(false);

            if(session == null ||
            session.getAttribute("username") == null){

                response.sendRedirect(
                request.getContextPath()
                + "/login.jsp");

                return;
            }

            String username =
            String.valueOf(
            session.getAttribute("username"))
            .trim();

            int requestId =
            Integer.parseInt(
            request.getParameter(
            "request_id"));

            String status =
            request.getParameter(
            "status");

            String remarks =
            request.getParameter(
            "remarks");

            if(status == null ||
            status.trim().equals("")){

                response.sendRedirect(
                request.getContextPath()
                + "/TrackRequestServlet?msg=error");

                return;
            }

            if(remarks == null ||
            remarks.trim().equals("")){

                response.sendRedirect(
                request.getContextPath()
                + "/TrackRequestServlet?msg=error");

                return;
            }

            con = DBUtil5.getConnection();

            PreparedStatement ps =
            con.prepareStatement(

            "INSERT INTO followups " +

            "(request_id,remarks,status," +
            "updated_by,updated_on) " +

            "VALUES(?,?,?,?,?)"

            );

            ps.setInt(1, requestId);

            ps.setString(2,
            remarks.trim());

            ps.setString(3,
            status.trim().toUpperCase());

            ps.setString(4,
            username);

            ps.setTimestamp(5,
            new Timestamp(
            System.currentTimeMillis()));

            int i = ps.executeUpdate();

            ps.close();

            PreparedStatement ps2 =
            con.prepareStatement(

            "UPDATE service_requests " +
            "SET status=? " +
            "WHERE id=?"

            );

            ps2.setString(1,
            status.trim().toUpperCase());

            ps2.setInt(2,
            requestId);

            ps2.executeUpdate();

            ps2.close();

            if(i > 0){

                response.sendRedirect(

                request.getContextPath()

                + "/TrackRequestServlet"
                + "?msg=success"

                );

            }else{

                response.sendRedirect(

                request.getContextPath()

                + "/TrackRequestServlet"
                + "?msg=error"
                );
            }

        } catch (Exception e) {

            e.printStackTrace();

            response.sendRedirect(

            request.getContextPath()

            + "/TrackRequestServlet"
            + "?msg=error"

            );

        } finally {

            try {

                if(con != null){

                    con.close();
                }

            } catch (Exception e) {

                e.printStackTrace();
            }
        }
    }
}