package com.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil;
import com.bean.IndentItems;

@WebServlet("/IndentPO")
public class IndentPO extends HttpServlet {

    @Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        List<IndentItems> indentList = new ArrayList<>();

        String sql = "SELECT * FROM indent WHERE POStatus IS NULL AND Indentnext = 'PO' ORDER BY indent_id DESC";

        try (Connection con = DBUtil.getConnection();
        	     PreparedStatement ps = con.prepareStatement(sql);
        	     ResultSet rs = ps.executeQuery()) {

        	    while (rs.next()) {
        	        IndentItems item = new IndentItems();
        	        item.setId(rs.getInt("indent_id"));
        	        item.setIndentNo(rs.getString("indent_no"));
        	        item.setIndentDate(rs.getDate("indent_date"));
        	        item.setItemName(rs.getString("item_name"));
        	        item.setQty(rs.getDouble("qty"));

        	        item.setDepartment(rs.getString("department"));
        	        item.setRequestedBy(rs.getString("requested_by"));
        	        item.setPurpose(rs.getString("purpose"));
        	        item.setIstatus(rs.getString("istatus"));
        	        item.setIstatusApprove(rs.getString("IstausApprove"));
        	        item.setStatus(rs.getString("status"));

        	        indentList.add(item);
        	    }

        	} catch (SQLException e) {
        	    throw new ServletException("DB Error: " + e.getMessage(), e);
        	}

        request.setAttribute("indentList", indentList);
        RequestDispatcher rd = request.getRequestDispatcher("IndentPO.jsp");
        rd.forward(request, response);
    }
}
