package com.Service;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil5;

@WebServlet("/Incharge")
public class Incharge extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null ||
            session.getAttribute("username") == null) {

            response.sendRedirect(
                    request.getContextPath() + "/login.jsp"
            );
            return;
        }

        /*
         * SESSION USERNAME
         * Example:
         * MICHEL
         */

        String username = String.valueOf(
                session.getAttribute("username")
        ).trim().toUpperCase();

        List<Map<String, Object>> requestList =
                new ArrayList<Map<String, Object>>();

        /*
         * IMPORTANT:
         * service_requests.assigned_to
         * stores department_incharge.id
         *
         * Session username stores:
         * incharge_name
         */

        String sql =
        	    "SELECT " +
        	    "sr.id, " +
        	    "sr.request_no, " +
        	    "DATE_FORMAT(sr.request_date,'%d %b %Y %h:%i %p') AS request_date, " +
        	    "sr.requested_by, " +
        	    "sr.location, " +
        	    "sr.description, " +
        	    "sr.priority, " +
        	    "sr.status, " +
        	    "di.incharge_name AS assigned_name, " +
        	    "di.employee_id " +
        	    "FROM service_requests sr " +
        	    "LEFT JOIN department_incharge di " +
        	    "ON sr.assigned_to = di.id " +
        	    "WHERE UPPER(TRIM(di.incharge_name)) = ? " +
        	    "AND (sr.status IS NULL " +
        	    "OR UPPER(TRIM(sr.status)) NOT IN ('SATISFIED', 'CLOSED')) " +
        	    "ORDER BY sr.id DESC";

        /*
         * FOLLOWUP QUERY
         */

        String followupSql =
                "SELECT remarks, status, updated_by, updated_on " +
                "FROM followups " +
                "WHERE request_id = ? " +
                "ORDER BY updated_on DESC " +
                "LIMIT 200";

        System.out.println("==================================");
        System.out.println("LOGIN USER : " + username);
        System.out.println("==================================");

        try (
                Connection con = DBUtil5.getConnection();

                PreparedStatement ps =
                        con.prepareStatement(sql);

                PreparedStatement ps2 =
                        con.prepareStatement(followupSql)
        ) {

            /*
             * SET LOGIN USERNAME
             */

            ps.setString(1, username);

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {

                Map<String, Object> map =
                        new HashMap<String, Object>();

                int requestId = rs.getInt("id");

                map.put("id", requestId);

                map.put(
                        "request_no",
                        rs.getString("request_no")
                );

                map.put(
                        "request_date",
                        rs.getString("request_date")
                );

                map.put(
                        "requested_by",
                        rs.getString("requested_by")
                );

                map.put(
                        "location",
                        rs.getString("location")
                );

                map.put(
                        "description",
                        rs.getString("description")
                );

                map.put(
                        "priority",
                        rs.getString("priority")
                );

                /*
                 * STATUS
                 */

                String status = rs.getString("status");

                if (status == null ||
                    status.trim().isEmpty()) {

                    status = "OPEN";
                }

                map.put("status", status);

                /*
                 * ASSIGNED NAME
                 */

                String assignedName =
                        rs.getString("assigned_name");

                if (assignedName == null ||
                    assignedName.trim().isEmpty()) {

                    assignedName = "Unassigned";
                }

                map.put("assigned_name", assignedName);

                /*
                 * FETCH FOLLOWUPS
                 */

                List<Map<String, Object>> followupList =
                        new ArrayList<Map<String, Object>>();

                ps2.setInt(1, requestId);

                ResultSet rs2 = ps2.executeQuery();

                while (rs2.next()) {

                    Map<String, Object> followup =
                            new HashMap<String, Object>();

                    followup.put(
                            "remarks",
                            rs2.getString("remarks")
                    );

                    followup.put(
                            "status",
                            rs2.getString("status")
                    );

                    followup.put(
                            "updated_by",
                            rs2.getString("updated_by")
                    );

                    Timestamp ts =
                            rs2.getTimestamp("updated_on");

                    String formattedDate = "";

                    if (ts != null) {

                        formattedDate =
                                new SimpleDateFormat(
                                        "dd MMM yyyy hh:mm a"
                                ).format(ts);
                    }

                    followup.put(
                            "updated_on",
                            formattedDate
                    );

                    followupList.add(followup);
                }

                rs2.close();

                map.put("followupList", followupList);

                requestList.add(map);
            }

            rs.close();

            System.out.println("==================================");
            System.out.println("TOTAL REQUESTS : " + requestList.size());
            System.out.println("==================================");

            request.setAttribute(
                    "requestList",
                    requestList
            );

        } catch (Exception e) {

            System.out.println("==================================");
            System.out.println("INCHARGE SERVLET ERROR");
            System.out.println("==================================");

            e.printStackTrace();
        }

        request.getRequestDispatcher(
                "/Service/Incharge.jsp"
        ).forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null ||
            session.getAttribute("username") == null) {

            response.sendRedirect(
                    request.getContextPath() + "/login.jsp"
            );
            return;
        }

        String username = String.valueOf(
                session.getAttribute("username")
        ).trim().toUpperCase();

        String requestIdParam =
                request.getParameter("request_id");

        String status =
                request.getParameter("status");

        String remarks =
                request.getParameter("remarks");

        /*
         * VALIDATION
         */

        if (requestIdParam == null ||
            status == null ||
            status.trim().isEmpty() ||
            remarks == null ||
            remarks.trim().isEmpty()) {

            response.sendRedirect(
                    request.getContextPath()
                            + "/Incharge?msg=error"
            );

            return;
        }

        int requestId =
                Integer.parseInt(requestIdParam);

        /*
         * VERIFY LOGGED USER IS ACTUAL OWNER
         */

        String verifySql =
                "SELECT sr.id " +
                "FROM service_requests sr " +
                "LEFT JOIN department_incharge di " +
                "ON sr.assigned_to = di.id " +
                "WHERE sr.id = ? " +
                "AND UPPER(TRIM(di.incharge_name)) = ?";

        /*
         * INSERT FOLLOWUP
         */

        String insertSql =
                "INSERT INTO followups " +
                "(request_id, remarks, status, updated_by, updated_on) " +
                "VALUES (?, ?, ?, ?, ?)";

        /*
         * UPDATE STATUS
         */

        String updateSql =
                "UPDATE service_requests " +
                "SET status = ? " +
                "WHERE id = ?";

        try (
                Connection con = DBUtil5.getConnection();

                PreparedStatement verifyPs =
                        con.prepareStatement(verifySql);

                PreparedStatement insertPs =
                        con.prepareStatement(insertSql);

                PreparedStatement updatePs =
                        con.prepareStatement(updateSql)
        ) {

            /*
             * VERIFY USER ACCESS
             */

            verifyPs.setInt(1, requestId);
            verifyPs.setString(2, username);

            ResultSet verifyRs =
                    verifyPs.executeQuery();

            if (!verifyRs.next()) {

                verifyRs.close();

                response.sendRedirect(
                        request.getContextPath()
                                + "/Incharge?msg=unauthorized"
                );

                return;
            }

            verifyRs.close();

            /*
             * INSERT FOLLOWUP
             */

            insertPs.setInt(1, requestId);

            insertPs.setString(
                    2,
                    remarks.trim()
            );

            insertPs.setString(
                    3,
                    status.trim().toUpperCase()
            );

            insertPs.setString(
                    4,
                    username
            );

            insertPs.setTimestamp(
                    5,
                    new Timestamp(System.currentTimeMillis())
            );

            int inserted =
                    insertPs.executeUpdate();

            /*
             * UPDATE MAIN STATUS
             */

            updatePs.setString(
                    1,
                    status.trim().toUpperCase()
            );

            updatePs.setInt(2, requestId);

            updatePs.executeUpdate();

            /*
             * RESPONSE
             */

            if (inserted > 0) {

                response.sendRedirect(
                        request.getContextPath()
                                + "/Incharge?msg=success"
                );

            } else {

                response.sendRedirect(
                        request.getContextPath()
                                + "/Incharge?msg=error"
                );
            }

        } catch (Exception e) {

            e.printStackTrace();

            response.sendRedirect(
                    request.getContextPath()
                            + "/Incharge?msg=error"
            );
        }
    }
}