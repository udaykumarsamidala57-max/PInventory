<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
    // Get current session, do not create new
    HttpSession sess = request.getSession(false);

    if (sess != null) {
        sess.invalidate();   // Destroy the session
    }

    // Redirect to login page after logout
    response.sendRedirect("login.jsp");
%>