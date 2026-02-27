package com.controller.Admissions;

import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.WebServlet;
import java.sql.*;
import com.bean.DBUtil3;

@WebServlet("/UpdateTCStatusServlet")
public class UpdateTCStatusServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/plain");

        // 🔐 Session Check
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.getWriter().print("SESSION_EXPIRED");
            return;
        }

        String role = (String) sess.getAttribute("role");

        if (!"Global".equalsIgnoreCase(role)
                && !"Incharge".equalsIgnoreCase(role)
                && !"Admin".equalsIgnoreCase(role)) {
            response.getWriter().print("ACCESS_DENIED");
            return;
        }

        Connection con = null;
        PreparedStatement ps = null;

        try {
            int sno = Integer.parseInt(request.getParameter("sno"));
            String status = request.getParameter("tcstatus");

            System.out.println("Updating TC: sno=" + sno + " status=" + status); // DEBUG

            con = DBUtil3.getConnection();

            ps = con.prepareStatement(
                "UPDATE student_master SET TC_Status=? WHERE sno=?");

            ps.setString(1, status);
            ps.setInt(2, sno);

            int i = ps.executeUpdate();

            if (i > 0)
                response.getWriter().print("SUCCESS");
            else
                response.getWriter().print("NOT_UPDATED");

        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().print("ERROR: " + e.getMessage());
        } finally {
            try { if(ps != null) ps.close(); } catch(Exception e) {}
            try { if(con != null) con.close(); } catch(Exception e) {}
        }
    }
}
