package com.controller.Asset;

import java.io.IOException;
import java.sql.*;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.bean.DBUtil4;

@WebServlet("/StaffIssued")
public class StaffIssuedAssetsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        List<Map<String, Object>> assetList = new ArrayList<Map<String, Object>>();

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {

            con = DBUtil4.getConnection();

            String sql =
                "SELECT a.asset_id, " +
                "a.asset_code, " +
                "a.asset_name, " +
                "a.brand, " +
          
                "l.location_name, " +
                "acl.assigned_date, " +
                "acl.assigned_by " +
                "FROM asset_current_location acl " +
                "INNER JOIN assets a ON a.asset_id = acl.asset_id " +
                "INNER JOIN locations l ON l.location_id = acl.location_id " +
                "WHERE l.building = ? " +
                "ORDER BY a.asset_name";

            ps = con.prepareStatement(sql);
            ps.setString(1, "TEACHING");

            rs = ps.executeQuery();

            while (rs.next()) {

                Map<String, Object> row = new HashMap<String, Object>();

                row.put("assetCode", rs.getString("asset_code"));
                row.put("assetName", rs.getString("asset_name"));
                row.put("brand", rs.getString("brand"));
             
                row.put("location", rs.getString("location_name"));
                row.put("assignedDate", rs.getTimestamp("assigned_date"));
                row.put("assignedBy", rs.getString("assigned_by"));

                assetList.add(row);
            }

            request.setAttribute("assetList", assetList);

        } catch (Exception e) {
            e.printStackTrace();
        } finally {

            try { if(rs != null) rs.close(); } catch(Exception e) {}
            try { if(ps != null) ps.close(); } catch(Exception e) {}
            try { if(con != null) con.close(); } catch(Exception e) {}
        }

        request.getRequestDispatcher("Asset/StaffIssued.jsp").forward(request, response);
    }
}