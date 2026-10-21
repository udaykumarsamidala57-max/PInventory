package com.website.servlet;

import com.website.bean.PageBean;
import com.website.bean.WebsiteDB;
import com.website.bean.PhotoStore;
import com.website.bean.PhotoUpload;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/website/pages")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024 * 2,          // 2 MB
        maxFileSize = 1024L * 1024L * 200L,            // 200 MB per file
        maxRequestSize = 1024L * 1024L * 250L          // 250 MB per request
)
public class PageServlet extends HttpServlet {

    // =========================================================
    // ALLOWED FILE TYPES
    // =========================================================

    private static final String[] ALLOWED_IMAGE_TYPES = {
            "image/jpeg",
            "image/png",
            "image/gif",
            "image/webp",
            "image/bmp",
            "image/svg+xml"
    };

    private static final String[] ALLOWED_VIDEO_TYPES = {
            "video/mp4",
            "video/webm",
            "video/ogg",
            "video/quicktime"
    };

    // =========================================================
    // GET
    // =========================================================

    @Override
    protected void doGet(
            HttpServletRequest req,
            HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession sess = req.getSession(false);

        if (!WebsiteDB.guard(req, resp)) {
            return;
        }

        String branch = WebsiteDB.site(sess);
        String role = (String) sess.getAttribute("role");

        if (!isAuthorized(role)) {
            resp.setContentType("text/html");
            resp.getWriter().println(
                    "<h3 style='color:red;'>Access Denied</h3>"
            );
            return;
        }

        String action = req.getParameter("action");

        if (action == null) {
            action = "list";
        }

        try (Connection conn = WebsiteDB.getConnection(branch)) {

            switch (action) {

                // =================================================
                // RENDER IMAGE OR VIDEO
                // =================================================

                case "renderImage":

                    Long imageId = parseLongOrNull(
                            req.getParameter("imageId")
                    );

                    if (imageId == null) {
                        resp.sendError(
                                HttpServletResponse.SC_BAD_REQUEST,
                                "Invalid asset ID"
                        );
                        return;
                    }

                    renderImageFromDb(conn, imageId, resp);
                    break;

                // =================================================
                // DELETE PAGE
                // =================================================

                case "delete":

                    if (!WebsiteDB.guardDelete(req, resp)) return;
                    Long pageId = parseLongOrNull(
                            req.getParameter("id")
                    );

                    if (pageId == null) {
                        resp.sendError(
                                HttpServletResponse.SC_BAD_REQUEST,
                                "Invalid page ID"
                        );
                        return;
                    }

                    deletePage(conn, pageId);

                    resp.sendRedirect("pages");
                    break;

                // =================================================
                // DELETE SECTION
                // =================================================

                case "deleteSection":

                    if (!WebsiteDB.guardDelete(req, resp)) return;
                    Long sectionId = parseLongOrNull(
                            req.getParameter("sectionId")
                    );

                    if (sectionId == null) {
                        resp.sendError(
                                HttpServletResponse.SC_BAD_REQUEST,
                                "Invalid section ID"
                        );
                        return;
                    }

                    deleteSection(conn, sectionId);

                    resp.sendRedirect(
                            "pages?action=view&id="
                                    + req.getParameter("pageId")
                    );

                    break;

                // =================================================
                // DELETE IMAGE / VIDEO
                // =================================================

                case "deleteImage":

                    if (!WebsiteDB.guardDelete(req, resp)) return;
                    Long deleteImageId = parseLongOrNull(
                            req.getParameter("imageId")
                    );

                    if (deleteImageId == null) {
                        resp.sendError(
                                HttpServletResponse.SC_BAD_REQUEST,
                                "Invalid asset ID"
                        );
                        return;
                    }

                    deleteImage(conn, deleteImageId);

                    resp.sendRedirect(
                            "pages?action=view&id="
                                    + req.getParameter("pageId")
                    );

                    break;

                // =================================================
                // VIEW PAGE
                // =================================================

                case "view":

                    Long viewId = parseLongOrNull(
                            req.getParameter("id")
                    );

                    if (viewId == null) {
                        resp.sendError(
                                HttpServletResponse.SC_BAD_REQUEST,
                                "Invalid page ID"
                        );
                        return;
                    }

                    req.setAttribute(
                            "activePage",
                            getPageDetails(conn, viewId)
                    );

                    req.setAttribute(
                            "pages",
                            getAllPages(conn)
                    );

                    req.getRequestDispatcher(
                            "/WEB-INF/views/website/pageBuilder.jsp"
                    ).forward(req, resp);

                    break;

                // =================================================
                // PAGE LIST
                // =================================================

                case "list":

                default:

                    req.setAttribute(
                            "pages",
                            getAllPages(conn)
                    );

                    req.getRequestDispatcher(
                            "/WEB-INF/views/website/pageBuilder.jsp"
                    ).forward(req, resp);

                    break;
            }

        } catch (SQLException e) {

            throw new ServletException(
                    "Database error",
                    e
            );
        }
    }

    // =========================================================
    // POST
    // =========================================================

    @Override
    protected void doPost(
            HttpServletRequest req,
            HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession sess = req.getSession(false);

        if (!WebsiteDB.guard(req, resp)) {
            return;
        }

        String role = (String) sess.getAttribute("role");
        String branch = WebsiteDB.site(sess);

        if (!isAuthorized(role)) {

            resp.setContentType("text/html");

            resp.getWriter().println(
                    "<h3 style='color:red;'>Access Denied</h3>"
            );

            return;
        }

        String action = req.getParameter("action");

        if (action == null) {
            resp.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Action is required"
            );
            return;
        }

        try (Connection conn = WebsiteDB.getConnection(branch)) {

            // =====================================================
            // CREATE PAGE
            // =====================================================

            if ("createPage".equals(action)) {

                String title = req.getParameter("title");
                String slug = req.getParameter("slug");

                Long parentId = parseLongOrNull(
                        req.getParameter("parentId")
                );

                Long newId = createPage(
                        conn,
                        title,
                        slug,
                        parentId
                );

                resp.sendRedirect(
                        "pages?action=view&id=" + newId
                );
            }

            // =====================================================
            // UPDATE PAGE
            // =====================================================

            else if (
                    "updatePage".equals(action)
                            || "editPage".equals(action)
            ) {

                Long pageId = parseLongOrNull(
                        req.getParameter("id")
                );

                if (pageId == null) {

                    pageId = parseLongOrNull(
                            req.getParameter("pageId")
                    );
                }

                if (pageId == null) {
                    resp.sendError(
                            HttpServletResponse.SC_BAD_REQUEST,
                            "Invalid page ID"
                    );
                    return;
                }

                String title = req.getParameter("title");
                String slug = req.getParameter("slug");

                Long parentId = parseLongOrNull(
                        req.getParameter("parentId")
                );

                updatePage(
                        conn,
                        pageId,
                        title,
                        slug,
                        parentId
                );

                resp.sendRedirect(
                        "pages?action=view&id=" + pageId
                );
            }

            // =====================================================
            // ADD SECTION
            // =====================================================

            else if ("addSection".equals(action)) {

                Long pageId = Long.parseLong(
                        req.getParameter("pageId")
                );

                String type = req.getParameter(
                        "sectionType"
                );

                int order = Integer.parseInt(
                        req.getParameter("sequenceOrder")
                );

                String title = req.getParameter("title");

                String content = req.getParameter(
                        "content"
                );

                createSection(
                        conn,
                        pageId,
                        type,
                        order,
                        title,
                        content
                );

                resp.sendRedirect(
                        "pages?action=view&id=" + pageId
                );
            }

            // =====================================================
            // UPDATE SECTION
            // =====================================================

            else if ("updateSection".equals(action)) {

                Long pageId = Long.parseLong(
                        req.getParameter("pageId")
                );

                Long sectionId = Long.parseLong(
                        req.getParameter("sectionId")
                );

                String type = req.getParameter(
                        "sectionType"
                );

                int order = Integer.parseInt(
                        req.getParameter("sequenceOrder")
                );

                String title = req.getParameter("title");

                String content = req.getParameter(
                        "content"
                );

                updateSection(
                        conn,
                        sectionId,
                        type,
                        order,
                        title,
                        content
                );

                resp.sendRedirect(
                        "pages?action=view&id=" + pageId
                );
            }

            // =====================================================
            // UPLOAD IMAGE OR VIDEO
            // =====================================================

            else if ("uploadImage".equals(action)) {

                Long pageId = Long.parseLong(
                        req.getParameter("pageId")
                );

                Long sectionId = Long.parseLong(
                        req.getParameter("sectionId")
                );

                String alt = req.getParameter(
                        "altText"
                );

                int order = Integer.parseInt(
                        req.getParameter("sequenceOrder")
                );

                String heading1 = req.getParameter(
                        "heading1"
                );

                String heading2 = req.getParameter(
                        "heading2"
                );

                Part filePart = req.getPart(
                        "imageFile"
                );

                if (filePart == null
                        || filePart.getSize() <= 0) {

                    throw new ServletException(
                            "Please select an image or video."
                    );
                }

                String contentType =
                        normalizeContentType(
                                filePart.getContentType()
                        );

                // Validate file type
                if (!isAllowedFileType(contentType)) {

                    throw new ServletException(
                            "Unsupported file type: "
                                    + contentType
                                    + ". Please upload an image or video."
                    );
                }

                // Validate file size
                if (filePart.getSize()
                        > 200L * 1024L * 1024L) {

                    throw new ServletException(
                            "File size cannot exceed 200 MB."
                    );
                }

                try (InputStream inputStream =
                             filePart.getInputStream()) {

                    saveImageToDb(
                            conn,
                            sectionId,
                            inputStream,
                            contentType,
                            alt,
                            order,
                            heading1,
                            heading2,
                            filePart.getSize(),
                            branch
                    );
                }

                resp.sendRedirect(
                        "pages?action=view&id=" + pageId
                );
            }

            // =====================================================
            // UPDATE IMAGE / VIDEO
            // =====================================================

            else if (
                    "updateImageMeta".equals(action)
                            || "updateImage".equals(action)
            ) {

                Long pageId = Long.parseLong(
                        req.getParameter("pageId")
                );

                Long imageId = Long.parseLong(
                        req.getParameter("imageId")
                );

                String alt = req.getParameter(
                        "altText"
                );

                int order = Integer.parseInt(
                        req.getParameter("sequenceOrder")
                );

                String heading1 = req.getParameter(
                        "heading1"
                );

                String heading2 = req.getParameter(
                        "heading2"
                );

                Part filePart = null;

                try {

                    filePart = req.getPart(
                            "imageFile"
                    );

                } catch (Exception ignored) {

                    // Metadata-only form
                }

                // =================================================
                // REPLACE FILE
                // =================================================

                if (filePart != null
                        && filePart.getSize() > 0) {

                    String contentType =
                            normalizeContentType(
                                    filePart.getContentType()
                            );

                    if (!isAllowedFileType(
                            contentType)) {

                        throw new ServletException(
                                "Unsupported file type: "
                                        + contentType
                        );
                    }

                    if (filePart.getSize()
                            > 200L * 1024L * 1024L) {

                        throw new ServletException(
                                "File size cannot exceed 200 MB."
                        );
                    }

                    try (InputStream inputStream =
                                 filePart.getInputStream()) {

                        updateImageWithFile(
                                conn,
                                imageId,
                                inputStream,
                                contentType,
                                alt,
                                order,
                                heading1,
                                heading2,
                                filePart.getSize(),
                                branch
                        );
                    }

                }

                // =================================================
                // METADATA ONLY
                // =================================================

                else {

                    updateImageMetadata(
                            conn,
                            imageId,
                            alt,
                            order,
                            heading1,
                            heading2
                    );
                }

                resp.sendRedirect(
                        "pages?action=view&id=" + pageId
                );
            }

            // =====================================================
            // UNKNOWN ACTION
            // =====================================================

            else {

                resp.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "Unknown action: " + action
                );
            }

        } catch (SQLException e) {

            throw new ServletException(
                    "Database error",
                    e
            );
        }
    }

    // =========================================================
    // AUTHORIZATION
    // =========================================================

    private boolean isAuthorized(String role) {

        return true;   // who may open the Website pages is checked by WebsiteDB.guard()
    }

    // =========================================================
    // PARSE LONG
    // =========================================================

    private Long parseLongOrNull(String str) {

        if (str == null
                || str.trim().isEmpty()
                || "null".equalsIgnoreCase(str.trim())) {

            return null;
        }

        try {

            return Long.parseLong(
                    str.trim()
            );

        } catch (NumberFormatException e) {

            return null;
        }
    }

    // =========================================================
    // NORMALIZE CONTENT TYPE
    // =========================================================

    private String normalizeContentType(
            String contentType) {

        if (contentType == null) {
            return "";
        }

        return contentType
                .trim()
                .toLowerCase();
    }

    // =========================================================
    // CHECK ALLOWED FILE TYPE
    // =========================================================

    private boolean isAllowedFileType(
            String contentType) {

        for (String type : ALLOWED_IMAGE_TYPES) {

            if (type.equalsIgnoreCase(contentType)) {
                return true;
            }
        }

        for (String type : ALLOWED_VIDEO_TYPES) {

            if (type.equalsIgnoreCase(contentType)) {
                return true;
            }
        }

        return false;
    }

    // =========================================================
    // CHECK VIDEO
    // =========================================================

    private boolean isVideoType(
            String contentType) {

        return contentType != null
                && contentType
                .toLowerCase()
                .startsWith("video/");
    }

    // =========================================================
    // RENDER IMAGE OR VIDEO
    // =========================================================

    private void renderImageFromDb(
            Connection conn,
            Long imageId,
            HttpServletResponse resp)
            throws SQLException, IOException {

        // photo kept in the bucket: send the browser to its link
        String bucketKey = PhotoUpload.keyOf(conn, "section_images", imageId);
        if (bucketKey != null && PhotoStore.enabled()) {
            resp.setHeader("Cache-Control", "private, max-age=2400");
            resp.sendRedirect(PhotoStore.url(bucketKey));
            return;
        }

        String sql =
                "SELECT image_data, image_type " +
                "FROM section_images " +
                "WHERE id = ?";

        try (PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setLong(1, imageId);

            try (ResultSet rs =
                         ps.executeQuery()) {

                if (rs.next()) {

                    String contentType =
                            rs.getString("image_type");

                    if (contentType == null
                            || contentType.trim().isEmpty()) {

                        contentType =
                                "application/octet-stream";
                    }

                    contentType =
                            normalizeContentType(
                                    contentType
                            );

                    resp.setContentType(
                            contentType
                    );

                    // Helps browser display video inline
                    resp.setHeader(
                            "Content-Disposition",
                            "inline; filename=\"asset-"
                                    + imageId
                                    + "\""
                    );

                    // Video browsers benefit from range requests,
                    // but this implementation streams the existing
                    // database BLOB directly.

                    try (
                            InputStream in =
                                    rs.getBinaryStream(
                                            "image_data"
                                    );

                            OutputStream out =
                                    resp.getOutputStream()
                    ) {

                        byte[] buffer =
                                new byte[8192];

                        int bytesRead;

                        while (
                                (bytesRead =
                                        in.read(buffer))
                                        != -1
                        ) {

                            out.write(
                                    buffer,
                                    0,
                                    bytesRead
                            );
                        }

                        out.flush();
                    }

                } else {

                    resp.sendError(
                            HttpServletResponse.SC_NOT_FOUND
                    );
                }
            }
        }
    }

    // =========================================================
    // SAVE IMAGE / VIDEO
    // =========================================================

    private void saveImageToDb(
            Connection conn,
            Long sectionId,
            InputStream is,
            String type,
            String altText,
            int order,
            String heading1,
            String heading2,
            long size,
            String branch)
            throws SQLException {

        // SRS: picture goes to the bucket, MySQL keeps only its place
        if (PhotoUpload.on(branch)) {
            long newId;
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO section_images " +
                    "(section_id, image_data, image_type, " +
                    "alt_text, sequence_order, Heading1, Heading2) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?)",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.setLong(1, sectionId);
                ps.setBytes(2, new byte[0]);
                ps.setString(3, type);
                ps.setString(4, altText);
                ps.setInt(5, order);
                ps.setString(6, heading1);
                ps.setString(7, heading2);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    keys.next();
                    newId = keys.getLong(1);
                }
            }
            try {
                PhotoUpload.store(conn, "section_images", "image_data", newId, branch,
                        "sections", is, size, type);
            } catch (SQLException e) {
                try (PreparedStatement undo = conn.prepareStatement("DELETE FROM section_images WHERE id = ?")) {
                    undo.setLong(1, newId);
                    undo.executeUpdate();
                }
                throw e;
            }
            return;
        }

        String sql =
                "INSERT INTO section_images " +
                "(section_id, image_data, image_type, " +
                "alt_text, sequence_order, Heading1, Heading2) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setLong(1, sectionId);

            ps.setBinaryStream(
                    2,
                    is
            );

            ps.setString(
                    3,
                    type
            );

            ps.setString(
                    4,
                    altText
            );

            ps.setInt(
                    5,
                    order
            );

            ps.setString(
                    6,
                    heading1
            );

            ps.setString(
                    7,
                    heading2
            );

            ps.executeUpdate();
        }
    }

    // =========================================================
    // UPDATE IMAGE / VIDEO FILE
    // =========================================================

    private void updateImageWithFile(
            Connection conn,
            Long imageId,
            InputStream is,
            String type,
            String altText,
            int order,
            String heading1,
            String heading2,
            long size,
            String branch)
            throws SQLException {

        // SRS: new picture goes to the bucket, the old file is removed
        if (PhotoUpload.on(branch)) {
            updateImageMetadata(conn, imageId, altText, order, heading1, heading2);
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE section_images SET image_type = ? WHERE id = ?")) {
                ps.setString(1, type);
                ps.setLong(2, imageId);
                ps.executeUpdate();
            }
            PhotoUpload.store(conn, "section_images", "image_data", imageId, branch,
                    "sections", is, size, type);
            return;
        }

        String sql =
                "UPDATE section_images SET " +
                "image_data = ?, " +
                "image_type = ?, " +
                "alt_text = ?, " +
                "sequence_order = ?, " +
                "Heading1 = ?, " +
                "Heading2 = ? " +
                "WHERE id = ?";

        try (PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setBinaryStream(
                    1,
                    is
            );

            ps.setString(
                    2,
                    type
            );

            ps.setString(
                    3,
                    altText
            );

            ps.setInt(
                    4,
                    order
            );

            ps.setString(
                    5,
                    heading1
            );

            ps.setString(
                    6,
                    heading2
            );

            ps.setLong(
                    7,
                    imageId
            );

            ps.executeUpdate();
        }
    }

    // =========================================================
    // UPDATE METADATA ONLY
    // =========================================================

    private void updateImageMetadata(
            Connection conn,
            Long imageId,
            String altText,
            int order,
            String heading1,
            String heading2)
            throws SQLException {

        String sql =
                "UPDATE section_images SET " +
                "alt_text = ?, " +
                "sequence_order = ?, " +
                "Heading1 = ?, " +
                "Heading2 = ? " +
                "WHERE id = ?";

        try (PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setString(
                    1,
                    altText
            );

            ps.setInt(
                    2,
                    order
            );

            ps.setString(
                    3,
                    heading1
            );

            ps.setString(
                    4,
                    heading2
            );

            ps.setLong(
                    5,
                    imageId
            );

            ps.executeUpdate();
        }
    }

    // =========================================================
    // GET ALL PAGES
    // =========================================================

    private List<PageBean> getAllPages(
            Connection conn)
            throws SQLException {

        List<PageBean> list =
                new ArrayList<>();

        String sql =
                "SELECT id, parent_id, title, slug, created_at " +
                "FROM pages " +
                "ORDER BY id DESC";

        try (
                PreparedStatement ps =
                        conn.prepareStatement(sql);

                ResultSet rs =
                        ps.executeQuery()
        ) {

            while (rs.next()) {

                PageBean p =
                        new PageBean();

                p.setId(
                        rs.getLong("id")
                );

                long parentId =
                        rs.getLong("parent_id");

                p.setParentId(
                        rs.wasNull()
                                ? null
                                : parentId
                );

                p.setTitle(
                        rs.getString("title")
                );

                p.setSlug(
                        rs.getString("slug")
                );

                list.add(p);
            }
        }

        return list;
    }

    // =========================================================
    // GET PAGE DETAILS
    // =========================================================

    private PageBean getPageDetails(
            Connection conn,
            Long pageId)
            throws SQLException {

        PageBean page = null;

        String sql =
                "SELECT " +
                "p.id as page_id, " +
                "p.parent_id, " +
                "p.title as page_title, " +
                "p.slug, " +

                "s.id as section_id, " +
                "s.section_type, " +
                "s.sequence_order as sec_order, " +
                "s.title as sec_title, " +
                "s.content, " +

                "i.id as image_id, " +
                "i.image_type, " +
                "i.alt_text, " +
                "i.sequence_order as img_order, " +
                "i.created_at, " +
                "i.Heading1, " +
                "i.Heading2 " +

                "FROM pages p " +

                "LEFT JOIN sections s " +
                "ON p.id = s.page_id " +

                "LEFT JOIN section_images i " +
                "ON s.id = i.section_id " +

                "WHERE p.id = ? " +

                "ORDER BY " +
                "s.sequence_order ASC, " +
                "i.sequence_order ASC";

        try (
                PreparedStatement ps =
                        conn.prepareStatement(sql)
        ) {

            ps.setLong(
                    1,
                    pageId
            );

            try (
                    ResultSet rs =
                            ps.executeQuery()
            ) {

                Map<Long, PageBean.Section>
                        sectionMap =
                        new LinkedHashMap<>();

                while (rs.next()) {

                    // =================================================
                    // PAGE
                    // =================================================

                    if (page == null) {

                        page =
                                new PageBean();

                        page.setId(
                                rs.getLong(
                                        "page_id"
                                )
                        );

                        long parentId =
                                rs.getLong(
                                        "parent_id"
                                );

                        page.setParentId(
                                rs.wasNull()
                                        ? null
                                        : parentId
                        );

                        page.setTitle(
                                rs.getString(
                                        "page_title"
                                )
                        );

                        page.setSlug(
                                rs.getString(
                                        "slug"
                                )
                        );
                    }

                    // =================================================
                    // SECTION
                    // =================================================

                    long secId =
                            rs.getLong(
                                    "section_id"
                            );

                    if (!rs.wasNull()) {

                        PageBean.Section section =
                                sectionMap.get(
                                        secId
                                );

                        if (section == null) {

                            section =
                                    new PageBean.Section();

                            section.setId(
                                    secId
                            );

                            section.setPageId(
                                    pageId
                            );

                            section.setSectionType(
                                    rs.getString(
                                            "section_type"
                                    )
                            );

                            section.setSequenceOrder(
                                    rs.getInt(
                                            "sec_order"
                                    )
                            );

                            section.setTitle(
                                    rs.getString(
                                            "sec_title"
                                    )
                            );

                            section.setContent(
                                    rs.getString(
                                            "content"
                                    )
                            );

                            sectionMap.put(
                                    secId,
                                    section
                            );

                            page.getSections()
                                    .add(section);
                        }

                        // =================================================
                        // IMAGE / VIDEO ASSET
                        // =================================================

                        long imgId =
                                rs.getLong(
                                        "image_id"
                                );

                        if (!rs.wasNull()) {

                            PageBean.SectionImage img =
                                    new PageBean.SectionImage();

                            img.setId(
                                    imgId
                            );

                            img.setSectionId(
                                    secId
                            );

                            img.setImageType(
                                    rs.getString(
                                            "image_type"
                                    )
                            );

                            img.setAltText(
                                    rs.getString(
                                            "alt_text"
                                    )
                            );

                            img.setSequenceOrder(
                                    rs.getInt(
                                            "img_order"
                                    )
                            );

                            img.setCreatedAt(
                                    rs.getTimestamp(
                                            "created_at"
                                    )
                            );

                            img.setHeading1(
                                    rs.getString(
                                            "Heading1"
                                    )
                            );

                            img.setHeading2(
                                    rs.getString(
                                            "Heading2"
                                    )
                            );

                            section.getImages()
                                    .add(img);
                        }
                    }
                }
            }
        }

        return page;
    }

    // =========================================================
    // CREATE PAGE
    // =========================================================

    private Long createPage(
            Connection conn,
            String title,
            String slug,
            Long parentId)
            throws SQLException {

        String sql =
                "INSERT INTO pages " +
                "(title, slug, parent_id) " +
                "VALUES (?, ?, ?)";

        try (
                PreparedStatement ps =
                        conn.prepareStatement(
                                sql,
                                Statement.RETURN_GENERATED_KEYS
                        )
        ) {

            ps.setString(
                    1,
                    title
            );

            ps.setString(
                    2,
                    slug
            );

            if (parentId != null) {

                ps.setLong(
                        3,
                        parentId
                );

            } else {

                ps.setNull(
                        3,
                        Types.BIGINT
                );
            }

            ps.executeUpdate();

            try (
                    ResultSet rs =
                            ps.getGeneratedKeys()
            ) {

                if (rs.next()) {

                    return rs.getLong(1);
                }
            }
        }

        return null;
    }

    // =========================================================
    // UPDATE PAGE
    // =========================================================

    private void updatePage(
            Connection conn,
            Long pageId,
            String title,
            String slug,
            Long parentId)
            throws SQLException {

        String sql =
                "UPDATE pages SET " +
                "title = ?, " +
                "slug = ?, " +
                "parent_id = ? " +
                "WHERE id = ?";

        try (PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setString(
                    1,
                    title
            );

            ps.setString(
                    2,
                    slug
            );

            if (parentId != null) {

                ps.setLong(
                        3,
                        parentId
                );

            } else {

                ps.setNull(
                        3,
                        Types.BIGINT
                );
            }

            ps.setLong(
                    4,
                    pageId
            );

            ps.executeUpdate();
        }
    }

    // =========================================================
    // CREATE SECTION
    // =========================================================

    private void createSection(
            Connection conn,
            Long pageId,
            String type,
            int order,
            String title,
            String content)
            throws SQLException {

        String sql =
                "INSERT INTO sections " +
                "(page_id, section_type, sequence_order, " +
                "title, content) " +
                "VALUES (?, ?, ?, ?, ?)";

        try (PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setLong(
                    1,
                    pageId
            );

            ps.setString(
                    2,
                    type
            );

            ps.setInt(
                    3,
                    order
            );

            ps.setString(
                    4,
                    title
            );

            ps.setString(
                    5,
                    content
            );

            ps.executeUpdate();
        }
    }

    // =========================================================
    // UPDATE SECTION
    // =========================================================

    private void updateSection(
            Connection conn,
            Long sectionId,
            String type,
            int order,
            String title,
            String content)
            throws SQLException {

        String sql =
                "UPDATE sections SET " +
                "section_type = ?, " +
                "sequence_order = ?, " +
                "title = ?, " +
                "content = ? " +
                "WHERE id = ?";

        try (PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setString(
                    1,
                    type
            );

            ps.setInt(
                    2,
                    order
            );

            ps.setString(
                    3,
                    title
            );

            ps.setString(
                    4,
                    content
            );

            ps.setLong(
                    5,
                    sectionId
            );

            ps.executeUpdate();
        }
    }

    // =========================================================
    // DELETE PAGE
    // =========================================================

    private void deletePage(
            Connection conn,
            Long id)
            throws SQLException {

        java.util.List<String> files = PhotoUpload.keys(conn,
                "SELECT i.file_key FROM section_images i JOIN sections s ON s.id = i.section_id WHERE s.page_id = ?", id);

        String sql =
                "DELETE FROM pages WHERE id = ?";

        try (PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setLong(
                    1,
                    id
            );

            ps.executeUpdate();
        }

        PhotoUpload.deleteFilesIfUnused(conn, "section_images", files);
    }

    // =========================================================
    // DELETE SECTION
    // =========================================================

    private void deleteSection(
            Connection conn,
            Long sectionId)
            throws SQLException {

        java.util.List<String> files = PhotoUpload.keys(conn,
                "SELECT file_key FROM section_images WHERE section_id = ?", sectionId);

        String sql =
                "DELETE FROM sections WHERE id = ?";

        try (PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setLong(
                    1,
                    sectionId
            );

            ps.executeUpdate();
        }

        PhotoUpload.deleteFilesIfUnused(conn, "section_images", files);
    }

    // =========================================================
    // DELETE IMAGE / VIDEO
    // =========================================================

    private void deleteImage(
            Connection conn,
            Long imageId)
            throws SQLException {

        java.util.List<String> files = PhotoUpload.keys(conn,
                "SELECT file_key FROM section_images WHERE id = ?", imageId);

        String sql =
                "DELETE FROM section_images WHERE id = ?";

        try (PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setLong(
                    1,
                    imageId
            );

            ps.executeUpdate();
        }

        PhotoUpload.deleteFilesIfUnused(conn, "section_images", files);
    }
}
