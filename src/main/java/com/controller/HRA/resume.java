package com.controller.HRA;

import java.io.IOException;
import java.io.OutputStream;
import java.sql.Blob;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.bean.DBUtil2;

@WebServlet("/reseume")
public class resume extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String id = request.getParameter("id");
        if (id == null) return;

        try (Connection con = DBUtil2.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT resumelongblob FROM candidate_recruitment WHERE sl_no = ?")) {
            
            ps.setInt(1, Integer.parseInt(id));
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                Blob blob = rs.getBlob("resumelongblob");
                if (blob != null) {
                    byte[] data = blob.getBytes(1, (int) blob.length());
                    
                    // Most resumes are PDF, this allows them to open in the browser tab
                    response.setContentType("application/pdf"); 
                    response.setContentLength(data.length);
                    
                    try (OutputStream out = response.getOutputStream()) {
                        out.write(data);
                        out.flush();
                    }
                } else {
                    response.getWriter().println("No resume file found for this candidate.");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}