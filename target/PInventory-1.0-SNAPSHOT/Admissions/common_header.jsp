<%@ page import="javax.servlet.http.HttpSession" %>
<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String user = (String) sess.getAttribute("username");
%>

<style>
header.ams-header,
header.ams-header * {
    box-sizing: border-box !important;
    font-family: 'Inter', "Segoe UI", Roboto, sans-serif !important;
}

header.ams-header {
    background: #0f2a4d !important;
    border-bottom: 3px solid #38bdf8 !important; /* Slightly thicker border */
    margin: 0 !important;
    padding: 0 !important;
    width: 100% !important;
    display: block !important;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.ams-header .nav-container {
    max-width: 1400px;
    margin: 0 auto !important;
    padding: 12px 25px !important; /* Increased padding (was 5px) */
    display: flex !important;
    align-items: center !important;
    justify-content: space-between !important;
    min-height: 70px !important; /* Increased height (was 45px) */
}

.ams-header .brand-box {
    display: flex !important;
    flex-direction: column !important;
    border-left: 4px solid #fbbf24 !important; /* Thicker accent */
    padding-left: 15px !important;
}

.ams-header .school-name {
    color: #fbbf24 !important;
    font-size: 1.3rem !important; /* Increased font (was 0.95) */
    font-weight: 800 !important;
    text-transform: uppercase !important;
    line-height: 1.2 !important;
}

.ams-header .system-name {
    color: #ffffff !important;
    font-size: 0.85rem !important; /* Increased font (was 0.7) */
    opacity: 0.9 !important;
    letter-spacing: 0.5px;
}

.ams-header nav.ams-nav {
    display: block !important;
}

.ams-header nav.ams-nav ul {
    list-style: none !important;
    display: flex !important;
    gap: 8px !important; /* Increased gap between items */
    margin: 0 !important;
    padding: 0 !important;
}

.ams-header nav.ams-nav ul li a {
    text-decoration: none !important;
    color: #e5e7eb !important;
    font-size: 14px !important; /* Increased font (was 11px) */
    font-weight: 600 !important;
    padding: 8px 14px !important; /* Increased padding */
    border-radius: 6px !important;
    transition: all 0.2s ease !important;
    display: block !important;
}

.ams-header nav.ams-nav ul li a:hover {
    background: rgba(255,255,255,0.15) !important;
    color: #38bdf8 !important;
}

.ams-header .user-info {
    display: flex !important;
    align-items: center !important;
    gap: 15px !important;
    background: rgba(0,0,0,0.3) !important;
    padding: 8px 18px !important; /* Larger container */
    border-radius: 8px !important;
}

.ams-header .user-name {
    color: #ffffff !important;
    font-size: 13px !important; /* Increased font */
    font-weight: 600 !important;
}

.ams-header .logout-btn {
    color: #fca5a5 !important;
    font-size: 13px !important; /* Increased font */
    font-weight: 700 !important;
    text-decoration: none !important;
    padding-left: 15px !important;
    border-left: 1px solid rgba(255,255,255,0.2) !important;
}

@media (max-width: 1100px) {
    .ams-header .nav-container {
        flex-direction: column !important;
        padding: 15px !important;
        gap: 15px;
    }

    .ams-header nav.ams-nav ul {
        flex-wrap: wrap !important;
        justify-content: center !important;
    }
}
</style>

<header class="ams-header">
    <div class="nav-container">
        <div class="brand-box">
            <span class="school-name">Sandur Residential School</span>
            <span class="system-name">Admissions Management System</span>
        </div>

        <nav class="ams-nav">
            <ul>
                <li><a href="dashboard">Home</a></li>
                <li><a href="admission">Enquiries</a></li>
                <li><a href="admission_report.jsp">Dashboard</a></li>
                <li><a href="enter_marks.jsp">Exam</a></li>
                <li><a href="marks_report.jsp">Tabulation</a></li>
                <li><a href="ApproveAdmission.jsp">Approval</a></li>
                <li><a href="Capcity.jsp">Vacancy</a></li>
                <li><a href="student_tc_update.jsp">TC Update</a></li>
            </ul>
        </nav>

        <div class="user-info">
            <span class="user-name">👤 <%= user %></span>
            <a href="Logout.jsp" class="logout-btn">Logout</a>
        </div>
    </div>
</header>