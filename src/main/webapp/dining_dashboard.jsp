<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="com.bean.DBUtil" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Dining Hall Dashboard</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
<style>
    body {
        font-family: 'Poppins', sans-serif;
        background: #f5f6fa;
        margin: 0;
        padding: 0;
        display: flex;
    }

    .content {
        margin-left: 260px;
        width: calc(100% - 260px);
        padding: 30px;
    }

    h2 {
        text-align: center;
        color: #2d3436;
        margin: 70px 0 30px;
        font-weight: 600;
        letter-spacing: 1px;
    }

    /* Filter Box */
    .filter-box {
        background: #fff;
        border-radius: 15px;
        padding: 20px 30px;
        box-shadow: 0 2px 12px rgba(0,0,0,0.08);
        display: flex;
        justify-content: center;
        align-items: center;
        gap: 15px;
        margin-bottom: 30px;
        flex-wrap: wrap;
    }

    label {
        font-weight: 500;
        color: #333;
    }

    input[type="date"], button {
        padding: 10px 15px;
        border-radius: 10px;
        border: 1px solid #ccc;
        font-size: 15px;
        transition: all 0.3s;
    }

    input[type="date"]:focus {
        border-color: #007bff;
        outline: none;
        box-shadow: 0 0 4px rgba(0,123,255,0.2);
    }

    button {
        background-color: #007bff;
        color: #fff;
        cursor: pointer;
        border: none;
        display: flex;
        align-items: center;
        gap: 6px;
        transition: 0.3s;
    }

    button:hover {
        background-color: #0056b3;
        transform: translateY(-2px);
    }

    /* Dashboard Board */
    .board {
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        gap: 30px;
        padding: 20px;
    }

    .note {
        width: 250px;
        height: 200px;
        border-radius: 12px;
        box-shadow: 0 6px 15px rgba(0,0,0,0.15);
        padding: 20px;
        position: relative;
        color: #333;
        background: #fff3b0;
        transform: rotate(-2deg);
        transition: all 0.3s ease;
    }

    .note:nth-child(2) { background: #c9f2c7; transform: rotate(2deg); }
    .note:nth-child(3) { background: #bde0fe; transform: rotate(-1deg); }

    .note:hover {
        transform: scale(1.05);
        z-index: 2;
        box-shadow: 0 10px 25px rgba(0,0,0,0.2);
    }

    .note .pin {
        position: absolute;
        width: 20px;
        height: 20px;
        background: crimson;
        border-radius: 50%;
        top: 10px;
        left: 50%;
        transform: translateX(-50%);
        box-shadow: 0 2px 6px rgba(0,0,0,0.3);
    }

    .note h3 {
        text-align: center;
        margin-top: 35px;
        font-size: 20px;
        font-weight: 600;
    }

    .note p {
        margin: 10px 0;
        font-size: 15px;
        font-weight: 500;
    }

    .no-data {
        text-align: center;
        color: #888;
        font-style: italic;
        margin-top: 50px;
    }

    @media (max-width: 768px) {
        .content { margin-left: 0; width: 100%; }
    }
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="content">
    <h2><i class="fas fa-utensils"></i> Dining Hall Dashboard</h2>

    <div class="filter-box">
        <form method="post">
            <label for="date">Select Date:</label>
            <input type="date" name="date" required 
                value="<%= request.getParameter("date") != null ? request.getParameter("date") : "" %>">
            <button type="submit"><i class="fas fa-sync-alt"></i> Refresh</button>
        </form>
    </div>

<%
    String selectedDate = request.getParameter("date");
    if (selectedDate != null && !selectedDate.trim().isEmpty()) {
        String[] sessions = {"Breakfast", "Lunch", "Dinner"};
        boolean anyData = false;
        Connection con = null;

        try {
            con = DBUtil.getConnection();
%>
        <div class="board">
<%
            for (String sessionName : sessions) {
                PreparedStatement ps = null;
                ResultSet rs = null;

                try {
                    String sql = "SELECT COUNT(DISTINCT item_id) AS total_items, " +
                                 "SUM(qty_issued) AS total_qty, SUM(total_value) AS total_cost " +
                                 "FROM dining_hall_consumption WHERE DATE(issue_date)=? AND session=?";
                    ps = con.prepareStatement(sql);
                    ps.setString(1, selectedDate);
                    ps.setString(2, sessionName);
                    rs = ps.executeQuery();

                    if (rs.next() && rs.getInt("total_items") > 0) {
                        anyData = true;
%>
            <div class="note">
                <div class="pin"></div>
                <h3><i class="fas fa-sun"></i> <%= sessionName %></h3>
                <p><i class="fas fa-bowl-food"></i> Total Items: <b><%= rs.getInt("total_items") %></b></p>
                <p><i class="fas fa-weight-scale"></i> Total Qty: <b><%= rs.getDouble("total_qty") %></b></p>
                <p><i class="fas fa-indian-rupee-sign"></i> Total Cost: <b>₹ <%= rs.getDouble("total_cost") %></b></p>
            </div>
<%
                    }
                } finally {
                    if (rs != null) rs.close();
                    if (ps != null) ps.close();
                }
            }

            if (!anyData) {
%>
                <div class="no-data">No records found for the selected date.</div>
<%
            }
%>
        </div>
<%
        } catch (Exception e) {
            out.println("<p style='color:red;text-align:center;'>Error: " + e.getMessage() + "</p>");
        } finally {
            if (con != null) con.close();
        }
    }
%>

</div>
</body>
</html>
