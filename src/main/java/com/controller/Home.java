package com.controller;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

@WebServlet("/Home")
public class Home extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int istatusPending = 0;
        int statusPending = 0;
        Map<String, Integer> deptPendingMap = new LinkedHashMap<>();
        Map<String, Integer> nextStageCountMap = new LinkedHashMap<>();
        Map<String, Integer> totalDeptMap = new LinkedHashMap<>();

        try (Connection con = DBUtil.getConnection()) {

            // ----- Pending at In-charge -----
            String query1 = "SELECT COUNT(*) FROM indent WHERE Istatus='Pending'";
            try (PreparedStatement ps1 = con.prepareStatement(query1);
                 ResultSet rs1 = ps1.executeQuery()) {
                if (rs1.next()) istatusPending = rs1.getInt(1);
            }

            // ----- Pending at Secretary -----
            String query2 = "SELECT COUNT(*) FROM indent WHERE status='Pending'";
            try (PreparedStatement ps2 = con.prepareStatement(query2);
                 ResultSet rs2 = ps2.executeQuery()) {
                if (rs2.next()) statusPending = rs2.getInt(1);
            }

            // ----- Pending by Department -----
            String query3 = "SELECT department, COUNT(*) AS pending_count " +
                            "FROM indent " +
                            "WHERE status='Pending' OR Istatus='Pending' " +
                            "GROUP BY department ORDER BY department";
            try (PreparedStatement ps3 = con.prepareStatement(query3);
                 ResultSet rs3 = ps3.executeQuery()) {
                while (rs3.next()) {
                    deptPendingMap.put(rs3.getString("department"), rs3.getInt("pending_count"));
                }
            }

            // ----- Total Indents by Department -----
            String totalDeptQuery = "SELECT department, COUNT(*) AS totalCount FROM indent GROUP BY department ORDER BY department";
            try (PreparedStatement ps = con.prepareStatement(totalDeptQuery);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    totalDeptMap.put(rs.getString("department"), rs.getInt("totalCount"));
                }
            }

            // ----- Count by Next Stage (Indentnext) -----
            String query4 = "SELECT IFNULL(Indentnext, '') AS stage, COUNT(*) AS cnt FROM indent GROUP BY Indentnext";
            try (PreparedStatement ps4 = con.prepareStatement(query4);
                 ResultSet rs4 = ps4.executeQuery()) {

                while (rs4.next()) {
                    String stage = rs4.getString("stage").trim();
                    int count = rs4.getInt("cnt");

                    switch (stage) {
                        case "":
                            stage = "Approval-Pending";
                            break;
                        case "PO":
                            stage = "PO";
                            break;
                        case "Issue":
                            stage = "Issue Pending";
                            break;
                        case "Issued":
                            stage = "Issued";
                            break;
                        case "Management Note":
                            stage = "Management Note";
                            break;
                        default:
                            stage = "Others";
                            break;
                    }

                    nextStageCountMap.put(stage, nextStageCountMap.getOrDefault(stage, 0) + count);
                }
            }

            // Ensure all main stages exist even if 0
            String[] allStages = {"Approval-Pending", "PO", "Issue Pending", "Issued", "Management Note"};
            for (String s : allStages) {
                nextStageCountMap.putIfAbsent(s, 0);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        // ----- Set attributes -----
        request.setAttribute("istatusPending", istatusPending);
        request.setAttribute("statusPending", statusPending);
        request.setAttribute("deptPendingMap", deptPendingMap);
        request.setAttribute("totalDeptMap", totalDeptMap);
        request.setAttribute("nextStageCountMap", nextStageCountMap);

        // ----- Forward -----
        RequestDispatcher rd = request.getRequestDispatcher("Home.jsp");
        rd.forward(request, response);
    }
}
