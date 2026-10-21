package com.website.servlet;

import com.website.bean.WebsiteDB;
import com.website.bean.PhotoUpload;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import java.io.InputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Time;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/website/upcoming-events")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,  // 2MB
    maxFileSize = 1024 * 1024 * 10,       // 10MB
    maxRequestSize = 1024 * 1024 * 50     // 50MB
)
public class UpcomingEventsServlet extends HttpServlet {

    // -------------------------------------------------------------------------
    // GET: Retrieve and Display Events
    // -------------------------------------------------------------------------
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (!WebsiteDB.guard(request, response)) {
            return;
        }

        String branch = WebsiteDB.site(sess);
        List<Map<String, Object>> eventList = new ArrayList<>();
        try (Connection conn = WebsiteDB.getConnection(branch)) {

            boolean withKey = PhotoUpload.hasKeyColumn(conn, "upcoming_events");
            String sql = "SELECT id, event_date, event_name, time_from, time_to, place, event_description, " +
                         (withKey
                             ? "file_key, CASE WHEN file_key IS NULL OR file_key = '' THEN image_blob END AS image_blob "
                             : "NULL AS file_key, image_blob ") +
                         "FROM upcoming_events ORDER BY event_date ASC";

            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> event = new HashMap<>();
                event.put("id", rs.getInt("id"));
                event.put("eventDate", rs.getDate("event_date"));
                event.put("eventName", rs.getString("event_name"));
                event.put("timeFrom", rs.getTime("time_from"));
                event.put("timeTo", rs.getTime("time_to"));
                event.put("place", rs.getString("place"));
                event.put("eventDescription", rs.getString("event_description"));

                // picture: bucket link, or the old picture from MySQL
                String src = PhotoUpload.src(rs.getString("file_key"), rs.getBytes("image_blob"));
                event.put("imageSrc", src.isEmpty() ? null : src);

                eventList.add(event);
            }
            }

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error: " + e.getMessage());
        }

        request.setAttribute("events", eventList);
        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/views/website/upcoming_events.jsp");
        dispatcher.forward(request, response);
    }

    // -------------------------------------------------------------------------
    // POST: Router for Insert, Update, and Delete Actions
    // -------------------------------------------------------------------------
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (!WebsiteDB.guard(request, response)) {
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            action = "insert";
        }

        switch (action.toLowerCase()) {
            case "update":
                handleUpdate(request);
                break;
            case "delete":
                if (WebsiteDB.canDelete(sess)) {
                    handleDelete(request);
                } else {
                    request.setAttribute("errorMessage", "Deleting events is not allowed for your user.");
                }
                break;
            case "insert":
            default:
                handleInsert(request);
                break;
        }

        // Re-load dataset and forward back to the view
        doGet(request, response);
    }

    // -------------------------------------------------------------------------
    // Handler: Insert New Event
    // -------------------------------------------------------------------------
    private void handleInsert(HttpServletRequest request) throws ServletException, IOException {
        String branch = WebsiteDB.site(request.getSession());
        String eventDateStr = request.getParameter("event_date");
        String eventName = request.getParameter("event_name");
        String timeFromStr = request.getParameter("time_from");
        String timeToStr = request.getParameter("time_to");
        String place = request.getParameter("place");
        String eventDescription = request.getParameter("event_description");
        Part imagePart = request.getPart("image_blob");
        boolean toBucket = PhotoUpload.on(branch) && imagePart != null && imagePart.getSize() > 0;

        String sql = "INSERT INTO upcoming_events (event_date, event_name, time_from, time_to, place, event_description, image_blob) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = WebsiteDB.getConnection(branch);
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setDate(1, Date.valueOf(eventDateStr));
            ps.setString(2, eventName);

            setTimeParameter(ps, 3, timeFromStr);
            setTimeParameter(ps, 4, timeToStr);

            ps.setString(5, (place != null && !place.trim().isEmpty()) ? place : null);
            ps.setString(6, (eventDescription != null && !eventDescription.trim().isEmpty()) ? eventDescription : null);

            if (toBucket) {
                ps.setBytes(7, new byte[0]);
            } else if (imagePart != null && imagePart.getSize() > 0) {
                ps.setBinaryStream(7, imagePart.getInputStream(), (int) imagePart.getSize());
            } else {
                ps.setNull(7, Types.BLOB);
            }

            int rowsInserted = ps.executeUpdate();

            // SRS: picture goes to the bucket, MySQL keeps only its place
            if (toBucket && rowsInserted > 0) {
                long newId;
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    keys.next();
                    newId = keys.getLong(1);
                }
                try (InputStream in = imagePart.getInputStream()) {
                    PhotoUpload.store(conn, "upcoming_events", "image_blob", newId, branch, "events",
                            in, imagePart.getSize(), imagePart.getContentType());
                } catch (SQLException e) {
                    try (PreparedStatement undo = conn.prepareStatement("DELETE FROM upcoming_events WHERE id = ?")) {
                        undo.setLong(1, newId);
                        undo.executeUpdate();
                    }
                    throw e;
                }
            }
            if (rowsInserted > 0) {
                request.setAttribute("successMessage", "Event created successfully!");
            } else {
                request.setAttribute("errorMessage", "Failed to create event.");
            }

        } catch (SQLException | IllegalArgumentException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Error saving record: " + e.getMessage());
        }
    }

    // -------------------------------------------------------------------------
    // Handler: Update Existing Event
    // -------------------------------------------------------------------------
    private void handleUpdate(HttpServletRequest request) throws ServletException, IOException {
        String branch = WebsiteDB.site(request.getSession());
        String idStr = request.getParameter("id");
        String eventDateStr = request.getParameter("event_date");
        String eventName = request.getParameter("event_name");
        String timeFromStr = request.getParameter("time_from");
        String timeToStr = request.getParameter("time_to");
        String place = request.getParameter("place");
        String eventDescription = request.getParameter("event_description");
        Part imagePart = request.getPart("image_blob");

        boolean toBucket = PhotoUpload.on(branch) && imagePart != null && imagePart.getSize() > 0;
        boolean hasNewImage = !toBucket && (imagePart != null && imagePart.getSize() > 0);

        String sql = hasNewImage
            ? "UPDATE upcoming_events SET event_date=?, event_name=?, time_from=?, time_to=?, place=?, event_description=?, image_blob=? WHERE id=?"
            : "UPDATE upcoming_events SET event_date=?, event_name=?, time_from=?, time_to=?, place=?, event_description=? WHERE id=?";

        try (Connection conn = WebsiteDB.getConnection(branch);
             PreparedStatement ps = conn.prepareStatement(sql)) {

            int id = Integer.parseInt(idStr);

            ps.setDate(1, Date.valueOf(eventDateStr));
            ps.setString(2, eventName);

            setTimeParameter(ps, 3, timeFromStr);
            setTimeParameter(ps, 4, timeToStr);

            ps.setString(5, (place != null && !place.trim().isEmpty()) ? place : null);
            ps.setString(6, (eventDescription != null && !eventDescription.trim().isEmpty()) ? eventDescription : null);

            if (hasNewImage) {
                ps.setBinaryStream(7, imagePart.getInputStream(), (int) imagePart.getSize());
                ps.setInt(8, id);
            } else {
                ps.setInt(7, id);
            }

            int rowsUpdated = ps.executeUpdate();

            // SRS: new picture goes to the bucket (old file removed)
            if (toBucket && rowsUpdated > 0) {
                try (InputStream in = imagePart.getInputStream()) {
                    PhotoUpload.store(conn, "upcoming_events", "image_blob", id, branch, "events",
                            in, imagePart.getSize(), imagePart.getContentType());
                }
            }

            if (rowsUpdated > 0) {
                request.setAttribute("successMessage", "Event updated successfully!");
            } else {
                request.setAttribute("errorMessage", "Failed to update event.");
            }

        } catch (SQLException | IllegalArgumentException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Error updating record: " + e.getMessage());
        }
    }

    // -------------------------------------------------------------------------
    // Handler: Delete Event
    // -------------------------------------------------------------------------
    private void handleDelete(HttpServletRequest request) {
        String branch = WebsiteDB.site(request.getSession());
        String idStr = request.getParameter("id");

        String sql = "DELETE FROM upcoming_events WHERE id = ?";

        try (Connection conn = WebsiteDB.getConnection(branch);
             PreparedStatement ps = conn.prepareStatement(sql)) {

            java.util.List<String> files = PhotoUpload.keys(conn,
                    "SELECT file_key FROM upcoming_events WHERE id = ?", Integer.parseInt(idStr));

            ps.setInt(1, Integer.parseInt(idStr));

            int rowsDeleted = ps.executeUpdate();
            PhotoUpload.deleteFilesIfUnused(conn, "upcoming_events", files);
            if (rowsDeleted > 0) {
                request.setAttribute("successMessage", "Event deleted successfully!");
            } else {
                request.setAttribute("errorMessage", "Event not found or could not be deleted.");
            }

        } catch (SQLException | NumberFormatException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Error deleting record: " + e.getMessage());
        }
    }

    // Helper for time formatting
    private void setTimeParameter(PreparedStatement ps, int paramIndex, String timeStr) throws SQLException {
        if (timeStr != null && !timeStr.trim().isEmpty()) {
            String formattedTime = timeStr.length() == 5 ? timeStr + ":00" : timeStr;
            ps.setTime(paramIndex, Time.valueOf(formattedTime));
        } else {
            ps.setNull(paramIndex, Types.TIME);
        }
    }
}
