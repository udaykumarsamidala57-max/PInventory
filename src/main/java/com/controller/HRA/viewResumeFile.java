package com.controller.HRA;

import java.io.IOException;
import java.io.OutputStream;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.bean.DBUtil2;

// Rename the URL mapping to avoid conflicts with JSP files
@WebServlet("/viewResumeFile") 
public class viewResumeFile extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String id = request.getParameter("id");
        if (id == null) return;

        // CRITICAL FIX: Ensure SQL column matches the rs.getBlob column name
        String sql = "SELECT resume FROM candidate_recruitment WHERE sl_no = ?";

        try (Connection con = DBUtil2.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, Integer.parseInt(id));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Blob blob = rs.getBlob("resume"); // Matches SQL select
                    if (blob != null) {
                        byte[] data = blob.getBytes(1, (int) blob.length());
                        
                        response.setContentType("application/pdf"); 
                        response.setContentLength(data.length);
                        
                        try (OutputStream out = response.getOutputStream()) {
                            out.write(data);
                            out.flush();
                        }
                    } else {
                        response.setContentType("text/html");
                        response.getWriter().println("<h3>No resume file found for this candidate.</h3>");
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }
}