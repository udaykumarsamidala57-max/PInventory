package com.example;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * The empty string "" in @WebServlet ensures that when you visit 
 * the root domain (srsadmincentral.up.railway.app), this Servlet handles it.
 */
@WebServlet("") 
public class HomeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // This looks for index.jsp inside your src/main/webapp folder
        RequestDispatcher dispatcher = request.getRequestDispatcher("/Home");
        
        // Internal forward: The URL in the browser stays the same, 
        // but the content of the JSP is displayed.
        dispatcher.forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Redirect POST requests to the same logic
        doGet(request, response);
    }
}