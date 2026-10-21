package com.website.servlet;

import com.website.bean.WebsiteDB;
import com.website.bean.PhotoUpload;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import java.io.IOException;
import java.io.InputStream;
import java.sql.*;

@WebServlet("/website/LatestNewsServlet")
@MultipartConfig(
        maxFileSize = 5 * 1024 * 1024,
        maxRequestSize = 10 * 1024 * 1024
)
public class LatestNewsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);

        if (!WebsiteDB.guard(request, response)) {
            return;
        }

        String branch = WebsiteDB.site(sess);
        String action = request.getParameter("action");

        try {
            if ("delete".equals(action)) {
                if (!WebsiteDB.guardDelete(request, response)) return;
                deleteNews(request, response, branch);
            } else {
                response.sendRedirect("latestNews.jsp");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("latestNews.jsp?error=1");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);

        if (!WebsiteDB.guard(request, response)) {
            return;
        }

        String branch = WebsiteDB.site(sess);
        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");

        try {
            if ("add".equals(action)) {
                addNews(request, response, branch);
            } else if ("update".equals(action)) {
                updateNews(request, response, branch);
            } else {
                response.sendRedirect("latestNews.jsp");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("latestNews.jsp?error=1");
        }
    }

    private void addNews(HttpServletRequest request, HttpServletResponse response, String branch)
            throws Exception {

        String eventName = request.getParameter("event_name");
        String description = request.getParameter("description");
        Part imagePart = request.getPart("image");

        // SRS: picture goes to the bucket, MySQL keeps only its place
        if (PhotoUpload.on(branch) && imagePart != null && imagePart.getSize() > 0) {
            try (Connection con = WebsiteDB.getConnection(branch)) {
                long newId;
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO latest_news (event_name, description, image) VALUES (?, ?, ?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, eventName);
                    ps.setString(2, description);
                    ps.setBytes(3, new byte[0]);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        keys.next();
                        newId = keys.getLong(1);
                    }
                }
                try (InputStream in = imagePart.getInputStream()) {
                    PhotoUpload.store(con, "latest_news", "image", newId, branch, "news",
                            in, imagePart.getSize(), imagePart.getContentType());
                } catch (SQLException e) {
                    try (PreparedStatement undo = con.prepareStatement("DELETE FROM latest_news WHERE id = ?")) {
                        undo.setLong(1, newId);
                        undo.executeUpdate();
                    }
                    throw e;
                }
            }
            response.sendRedirect("latestNews.jsp?success=added");
            return;
        }

        String sql = "INSERT INTO latest_news (event_name, description, image) VALUES (?, ?, ?)";

        try (Connection con = WebsiteDB.getConnection(branch);
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, eventName);
            ps.setString(2, description);

            if (imagePart != null && imagePart.getSize() > 0) {
                try (InputStream inputStream = imagePart.getInputStream()) {
                    ps.setBinaryStream(3, inputStream, (int) imagePart.getSize());
                    ps.executeUpdate();
                }
            } else {
                ps.setNull(3, Types.BLOB);
                ps.executeUpdate();
            }
        }

        response.sendRedirect("latestNews.jsp?success=added");
    }

    private void updateNews(HttpServletRequest request, HttpServletResponse response, String branch)
            throws Exception {

        int id = Integer.parseInt(request.getParameter("id"));
        String eventName = request.getParameter("event_name");
        String description = request.getParameter("description");
        Part imagePart = request.getPart("image");

        if (PhotoUpload.on(branch) && imagePart != null && imagePart.getSize() > 0) {
            // SRS: text in MySQL, new picture in the bucket (old file removed)
            try (Connection con = WebsiteDB.getConnection(branch)) {
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE latest_news SET event_name=?, description=? WHERE id=?")) {
                    ps.setString(1, eventName);
                    ps.setString(2, description);
                    ps.setInt(3, id);
                    ps.executeUpdate();
                }
                try (InputStream in = imagePart.getInputStream()) {
                    PhotoUpload.store(con, "latest_news", "image", id, branch, "news",
                            in, imagePart.getSize(), imagePart.getContentType());
                }
            }
        } else if (imagePart != null && imagePart.getSize() > 0) {
            // Update including the new image BLOB
            String sql = "UPDATE latest_news SET event_name=?, description=?, image=? WHERE id=?";

            try (Connection con = WebsiteDB.getConnection(branch);
                 PreparedStatement ps = con.prepareStatement(sql);
                 InputStream inputStream = imagePart.getInputStream()) {

                ps.setString(1, eventName);
                ps.setString(2, description);
                ps.setBinaryStream(3, inputStream, (int) imagePart.getSize());
                ps.setInt(4, id);

                ps.executeUpdate();
            }
        } else {
            // Preserve existing image BLOB if no new file uploaded
            String sql = "UPDATE latest_news SET event_name=?, description=? WHERE id=?";

            try (Connection con = WebsiteDB.getConnection(branch);
                 PreparedStatement ps = con.prepareStatement(sql)) {

                ps.setString(1, eventName);
                ps.setString(2, description);
                ps.setInt(3, id);

                ps.executeUpdate();
            }
        }

        response.sendRedirect("latestNews.jsp?success=updated");
    }

    private void deleteNews(HttpServletRequest request, HttpServletResponse response, String branch)
            throws Exception {

        int id = Integer.parseInt(request.getParameter("id"));
        String deleteSQL = "DELETE FROM latest_news WHERE id=?";

        try (Connection con = WebsiteDB.getConnection(branch)) {
            java.util.List<String> files = PhotoUpload.keys(con,
                    "SELECT file_key FROM latest_news WHERE id = ?", id);
            try (PreparedStatement ps = con.prepareStatement(deleteSQL)) {
                ps.setInt(1, id);
                ps.executeUpdate();
            }
            PhotoUpload.deleteFilesIfUnused(con, "latest_news", files);
        }

        response.sendRedirect("latestNews.jsp?success=deleted");
    }
}
