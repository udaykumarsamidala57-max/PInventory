package com.controller;

import java.io.IOException;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Properties;
import java.util.Random;
import javax.mail.*;
import javax.mail.internet.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.bean.DBUtil;

@WebServlet("/SendOTPServlet")
public class SendOTPServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        Random rand = new Random();
        int otp = 100000 + rand.nextInt(900000);
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(5);

        try (Connection con = DBUtil.getConnection()) {

            PreparedStatement check = con.prepareStatement("SELECT * FROM users WHERE mail=?");
            check.setString(1, email);
            ResultSet rs = check.executeQuery();

            if (rs.next()) {
                PreparedStatement ps = con.prepareStatement("UPDATE users SET otp=?, otp_expiry=? WHERE mail=?");
                ps.setInt(1, otp);
                ps.setString(2, expiry.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
                ps.setString(3, email);
                ps.executeUpdate();

                sendEmail(email, otp);
                request.setAttribute("email", email);
                RequestDispatcher rd = request.getRequestDispatcher("verify_otp.jsp");
                rd.forward(request, response);
            } else {
                request.setAttribute("error", "Email not registered!");
                RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
                rd.forward(request, response);
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error sending OTP. Try again.");
            RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
            rd.forward(request, response);
        }
    }

    private void sendEmail(String to, int otp) throws MessagingException {
        final String from = "udaykumarsamidala57@gmail.com"; // your Gmail
        final String password = "ppmx bxto kijp qike"; // Gmail App Password

        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");

        Session session = Session.getInstance(props, new Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(from, password);
            }
        });

        Message message = new MimeMessage(session);
        message.setFrom(new InternetAddress(from));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
        message.setSubject("Your OTP for Login");
        message.setText("Your OTP is: " + otp + "\nIt is valid for 5 minutes.\n\nRegards,\nSystem Admin");

        Transport.send(message);
    }
}
