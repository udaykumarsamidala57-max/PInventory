package com.Service;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
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

@WebServlet("/RequestReport")
public class RequestReportServlet extends HttpServlet {
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
        String branch = (String) sess.getAttribute("branch");

        String role = (String) sess.getAttribute("role");
        String dept = (String) sess.getAttribute("department");

        List<Map<String, Object>> reportDataList = new ArrayList<>();

        // 1. Updated SQL Query to LEFT JOIN the departments table
        String mainSql =
                "SELECT sr.id, " +
                "sr.request_no, " +
                "DATE(sr.request_date) AS request_date, " +
                "sr.requested_by, " +
                "sr.location, " +
                "sr.description, " +
                "di.incharge_name, " +
                "d.department_name, " + // <-- Fetching the department name here
                "DATE(sr.closed_date) AS closed_date, " +
                "DATEDIFF(COALESCE(sr.closed_date, NOW()), sr.request_date) AS days_difference " +
                "FROM service_requests sr " +
                "LEFT JOIN department_incharge di ON sr.assigned_to = di.id " +
                "LEFT JOIN departments d ON sr.department_id = d.id " + // <-- Assumed foreign key is sr.department_id
                "ORDER BY sr.id DESC";

        String detailsSql =
                "SELECT remarks, status, updated_by, " +
                "DATE(updated_on) AS updated_on_date " +
                "FROM followups " +
                "WHERE request_id = ? " +
                "ORDER BY id ASC";

        try (
                Connection con = DBUtil5.getConnection(branch);
                PreparedStatement psMain = con.prepareStatement(mainSql);
                ResultSet rsMain = psMain.executeQuery();
                PreparedStatement psDetail = con.prepareStatement(detailsSql)
        ) {

            System.out.println("Connected Database : " + con.getCatalog());

            while (rsMain.next()) {

                Map<String, Object> rowMap = new HashMap<>();

                int requestId = rsMain.getInt("id");

                rowMap.put("id", requestId);
                rowMap.put("requestNo", rsMain.getString("request_no"));
                rowMap.put("requestDate", rsMain.getDate("request_date"));
                rowMap.put("requestedBy", rsMain.getString("requested_by"));
                rowMap.put("location", rsMain.getString("location"));
                rowMap.put("description", rsMain.getString("description"));
                rowMap.put("assignedTo", rsMain.getString("incharge_name"));
                
                // 2. Map the department name so it is available in the list
                rowMap.put("departmentName", rsMain.getString("department_name"));

                java.sql.Date closedDate =
                        rsMain.getDate("closed_date");

                rowMap.put("closedDate", closedDate);

                rowMap.put(
                        "currentStatus",
                        closedDate != null ? "CLOSED" : "ACTIVE"
                );

                rowMap.put(
                        "daysDifference",
                        rsMain.getInt("days_difference")
                );

                List<Map<String, Object>> followUps =
                        new ArrayList<>();

                psDetail.setInt(1, requestId);

                try (ResultSet rsDetail =
                             psDetail.executeQuery()) {

                    while (rsDetail.next()) {

                        Map<String, Object> followUp =
                                new HashMap<>();

                        followUp.put(
                                "updatedOn",
                                rsDetail.getDate("updated_on_date")
                        );

                        followUp.put(
                                "status",
                                rsDetail.getString("status")
                        );

                        followUp.put(
                                "updatedBy",
                                rsDetail.getString("updated_by")
                        );

                        followUp.put(
                                "remarks",
                                rsDetail.getString("remarks")
                        );

                        followUps.add(followUp);
                    }
                }

                rowMap.put("followUps", followUps);

                reportDataList.add(rowMap);

                System.out.println(
                        "Loaded Request : " +
                        rsMain.getString("request_no")
                );
            }

            System.out.println(
                    "Total Records Loaded : " +
                    reportDataList.size()
            );

            request.setAttribute(
                    "reportDataList",
                    reportDataList
            );

        } catch (Exception e) {

            e.printStackTrace();

            request.setAttribute(
                    "errorMessage",
                    e.getMessage()
                );

            System.out.println(
                    "ERROR : " + e.getMessage()
            );
        }

        request.getRequestDispatcher(
                "/Service/requestReportView.jsp"
        ).forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        doGet(request, response);
    }
}