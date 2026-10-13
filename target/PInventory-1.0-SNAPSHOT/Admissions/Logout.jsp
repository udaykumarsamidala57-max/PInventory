<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
    
    HttpSession sess = request.getSession(false);

    if (sess != null) {
        sess.invalidate();   // Destroy the session
    }

    
    response.sendRedirect("login.jsp");
%>