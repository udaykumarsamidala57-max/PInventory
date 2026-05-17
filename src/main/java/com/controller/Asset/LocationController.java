package com.controller.Asset;

import java.io.IOException;
import java.sql.ResultSet;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.DAO.LocationDAO;

@WebServlet("/LocationController")
public class LocationController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        // DEFAULT ACTION

        if(action == null) {

            action = "view";
        }

        LocationDAO dao = new LocationDAO();

        // INSERT LOCATION

        if(action.equals("insert")) {

            String locationName =
                    request.getParameter("location_name");

            String building =
                    request.getParameter("building");

            String floorName =
                    request.getParameter("floor_name");

            String roomNumber =
                    request.getParameter("room_number");

            String description =
                    request.getParameter("description");

            boolean status = dao.addLocation(
                    locationName,
                    building,
                    floorName,
                    roomNumber,
                    description
            );

            if(status) {

                response.sendRedirect(
                    request.getContextPath()
                    + "/LocationController?action=view&success=1"
                );

            } else {

                response.sendRedirect(
                    request.getContextPath()
                    + "/LocationController?action=view&error=1"
                );
            }
        }

        // VIEW LOCATIONS

        else if(action.equals("view")) {

            ResultSet rs = dao.getLocations();

            request.setAttribute("locationData", rs);

            RequestDispatcher rd =
            	    request.getRequestDispatcher(
            	        "/Asset/AddLocations.jsp"
            	    );

            rd.forward(request, response);
        }

        // DELETE LOCATION

        else if(action.equals("delete")) {

            int locationId =
                Integer.parseInt(
                    request.getParameter("id")
                );

            boolean status =
                dao.deleteLocation(locationId);

            if(status) {

                response.sendRedirect(
                    request.getContextPath()
                    + "/LocationController?action=view&deleted=1"
                );

            } else {

                response.sendRedirect(
                    request.getContextPath()
                    + "/LocationController?action=view&error=1"
                );
            }
        }

        // EDIT LOCATION

        else if(action.equals("edit")) {

            int locationId =
                Integer.parseInt(
                    request.getParameter("id")
                );

            ResultSet rs =
                dao.getLocationById(locationId);

            request.setAttribute("editData", rs);

            RequestDispatcher rd =
                request.getRequestDispatcher(
                    "/Asset/editLocation.jsp"
                );

            rd.forward(request, response);
        }

        // UPDATE LOCATION

        else if(action.equals("update")) {

            int locationId =
                Integer.parseInt(
                    request.getParameter("location_id")
                );

            String locationName =
                    request.getParameter("location_name");

            String building =
                    request.getParameter("building");

            String floorName =
                    request.getParameter("floor_name");

            String roomNumber =
                    request.getParameter("room_number");

            String description =
                    request.getParameter("description");

            boolean status =
                dao.updateLocation(
                    locationId,
                    locationName,
                    building,
                    floorName,
                    roomNumber,
                    description
                );

            if(status) {

                response.sendRedirect(
                    request.getContextPath()
                    + "/LocationController?action=view&updated=1"
                );

            } else {

                response.sendRedirect(
                    request.getContextPath()
                    + "/LocationController?action=view&error=1"
                );
            }
        }
    }

    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        doPost(request, response);
    }
}