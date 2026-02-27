package com.controller.Admissions;


import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import com.bean.DBUtil3;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        try (Connection con = DBUtil3.getConnection()) {
            /* --- 1. Total Enquiries --- */
            int totalEnq = 0;
            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM admission_enquiry");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) totalEnq = rs.getInt(1);
            }

            /* --- 2. Admission Type Totals (Enquiries) --- */
            int dayTotal = 0, resTotal = 0, semiTotal = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT LOWER(TRIM(admission_type)), COUNT(*) FROM admission_enquiry GROUP BY 1");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String type = rs.getString(1);
                    int cnt = rs.getInt(2);
                    if (type.contains("day")) dayTotal += cnt;
                    else if (type.contains("semi")) semiTotal += cnt;
                    else if (type.contains("res")) resTotal += cnt;
                }
            }

            /* --- 3. Capacity Map --- */
            Map<String, int[]> capacityMap = new LinkedHashMap<>();
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT TRIM(class_name), day_scholars, boarders_girls, boarders_boys, total_capacity FROM class_capacity");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String cls = normalizeClass(rs.getString(1));
                    capacityMap.put(cls, new int[]{
                            rs.getInt("day_scholars"),
                            parseSafe(rs.getString("boarders_girls")),
                            parseSafe(rs.getString("boarders_boys")),
                            rs.getInt("total_capacity")
                    });
                }
            }

            /* --- 4. Dashboard Matrix (Present Strength) --- */
            Map<String, int[]> dashboardMatrix = new LinkedHashMap<>();
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT TRIM(class), LOWER(TRIM(category)), LOWER(TRIM(gender)), COUNT(*) " +
                    "FROM student_master " +
                    "WHERE (TC_Status IS NULL OR TC_Status = '') " +
                    "GROUP BY 1, 2, 3")) {
                
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String cls = normalizeClass(rs.getString(1));
                        String type = rs.getString(2);
                        String gender = rs.getString(3);
                        int cnt = rs.getInt(4);

                        int[] arr = dashboardMatrix.getOrDefault(cls, new int[4]);
                        // arr[0]=Day, arr[1]=ResGirls, arr[2]=ResBoys, arr[3]=Semi

                        if (type.contains("day")) arr[0] += cnt;
                        else if (type.contains("semi")) arr[3] += cnt;
                        else if (type.contains("res")) {
                            if (gender != null && (gender.startsWith("f") || gender.contains("girl"))) arr[1] += cnt;
                            else arr[2] += cnt;
                        }
                        dashboardMatrix.put(cls, arr);
                    }
                }
            }

            request.setAttribute("total", totalEnq);
            request.setAttribute("day", dayTotal);
            request.setAttribute("res", resTotal);
            request.setAttribute("semi", semiTotal);
            request.setAttribute("dashboardMatrix", dashboardMatrix);
            request.setAttribute("capacityMap", capacityMap);
            request.getRequestDispatcher("dashboard.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    private int parseSafe(String val) {
        try { return (val == null || val.trim().isEmpty()) ? 0 : Integer.parseInt(val.trim()); }
        catch (NumberFormatException e) { return 0; }
    }

    private String normalizeClass(String raw) {
        if (raw == null || raw.trim().isEmpty()) return "Unknown";
        String clean = raw.toLowerCase().trim().replaceAll("[^a-z0-9]", "");
        
        // Match Database entries to classOrder array
        if (clean.contains("prekg") || clean.contains("nur") || clean.contains("pre")) return "Nursery";
        if (clean.contains("lkg")) return "LKG";
        if (clean.contains("ukg")) return "UKG";
        if (clean.equals("x") || clean.equals("10") || clean.contains("classx") || clean.contains("class10")) return "Class 10";
        
        String digits = clean.replaceAll("[^0-9]", "");
        if (!digits.isEmpty()) {
            try {
                int n = Integer.parseInt(digits);
                if (n >= 1 && n <= 9) return "Class " + n;
            } catch (Exception ignored) {}
        }
        return raw;
    }
}