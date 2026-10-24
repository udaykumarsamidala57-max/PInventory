package com.website.servlet;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.website.bean.MediaLibrary;
import com.website.bean.PhotoStore;
import com.website.bean.WebsiteDB;

/**
 * Website -> Photo Library: folders of photos in the bucket.
 *
 *   GET  /website/media?folder=Events/            page
 *   GET  /website/media?folder=...&format=json    the same folder as JSON (Page Builder picker)
 *   POST action=createFolder   folder, name
 *   POST action=upload         folder, files (several)
 *   POST action=deleteFile     key            (only users allowed to delete, and only when no page uses it)
 *   POST action=deleteFolder   folder         (only when empty)
 */
@WebServlet("/website/media")
@MultipartConfig(fileSizeThreshold = 2 * 1024 * 1024, maxFileSize = 200L * 1024 * 1024, maxRequestSize = 600L * 1024 * 1024)
public class MediaServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final long MAX_FILE = 200L * 1024 * 1024;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        boolean json = "json".equals(req.getParameter("format"));
        if (json) {
            HttpSession s = req.getSession(false);
            if (!WebsiteDB.allowed(s)) { send(resp, 403, err("Not allowed.")); return; }
        } else if (!WebsiteDB.guard(req, resp)) {
            return;
        }
        HttpSession sess = req.getSession(false);
        String site = WebsiteDB.site(sess);
        String folder = MediaLibrary.cleanFolder(req.getParameter("folder"));
        // area "old" = photos uploaded before the Photo Library (sections / news / events folders): view and pick only
        boolean old = "old".equals(req.getParameter("area"));
        req.setAttribute("area", old ? "old" : "");

        if (!PhotoStore.enabled()) {
            if (json) { send(resp, 200, err("The photo bucket is not set up (BUCKET, ACCESS_KEY_ID, SECRET_ACCESS_KEY).")); return; }
            req.setAttribute("error", "The photo bucket is not set up. Add BUCKET, ACCESS_KEY_ID, SECRET_ACCESS_KEY, ENDPOINT and REGION to the settings.");
            forward(req, resp, site, folder, new JsonArray(), new JsonArray());
            return;
        }

        JsonArray folders = new JsonArray();
        JsonArray files = new JsonArray();
        try {
            String root = old ? MediaLibrary.siteRoot(site) : MediaLibrary.root(site);
            PhotoStore.Listing l = PhotoStore.list(root + folder);
            if (!old && folder.isEmpty()) {                     // entry point to the earlier uploads
                JsonObject o = new JsonObject();
                o.addProperty("path", "");
                o.addProperty("name", "Earlier uploads");
                o.addProperty("area", "old");
                folders.add(o);
            }
            for (String f : l.folders) {
                String rel = f.substring(root.length());
                if (old && folder.isEmpty() && rel.equals("library/")) continue;   // the library itself
                JsonObject o = new JsonObject();
                o.addProperty("path", rel);
                String name = rel.substring(0, rel.length() - 1);
                o.addProperty("name", name.contains("/") ? name.substring(name.lastIndexOf('/') + 1) : name);
                if (old) o.addProperty("area", "old");
                folders.add(o);
            }
            for (PhotoStore.Item i : l.files) {
                if (i.key.endsWith("/" + MediaLibrary.MARKER) || !MediaLibrary.isMedia(i.key)) continue;
                JsonObject o = new JsonObject();
                o.addProperty("key", i.key);
                o.addProperty("name", i.key.substring(i.key.lastIndexOf('/') + 1));
                o.addProperty("size", i.size);
                o.addProperty("modified", i.modified == null ? "" : i.modified);
                o.addProperty("type", MediaLibrary.contentTypeOf(i.key));
                o.addProperty("url", PhotoStore.url(i.key));
                files.add(o);
            }
        } catch (Exception e) {
            e.printStackTrace();
            if (json) { send(resp, 200, err("Could not open the folder: " + e.getMessage())); return; }
            req.setAttribute("error", "Could not open the folder: " + e.getMessage());
        }

        if (json) {
            JsonObject out = new JsonObject();
            out.addProperty("ok", true);
            out.addProperty("site", site);
            out.addProperty("folder", folder);
            out.addProperty("area", old ? "old" : "");
            out.add("folders", folders);
            out.add("files", files);
            send(resp, 200, out);
            return;
        }
        forward(req, resp, site, folder, folders, files);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!WebsiteDB.guard(req, resp)) return;
        HttpSession sess = req.getSession(false);
        String site = WebsiteDB.site(sess);
        String folder = MediaLibrary.cleanFolder(req.getParameter("folder"));
        String action = req.getParameter("action");
        String msg;
        boolean ok = true;

        try {
            if (!PhotoStore.enabled()) throw new IllegalStateException("The photo bucket is not set up.");

            if ("createFolder".equals(action)) {
                String rel = MediaLibrary.createFolder(site, folder, req.getParameter("name"));
                msg = "Folder created.";
                folder = rel;

            } else if ("upload".equals(action)) {
                PhotoStore.Listing existing = PhotoStore.list(MediaLibrary.root(site) + folder);
                int saved = 0;
                List<String> skipped = new ArrayList<>();
                for (Part p : req.getParts()) {
                    if (!"files".equals(p.getName()) || p.getSize() <= 0) continue;
                    String name = p.getSubmittedFileName() == null ? "photo" : p.getSubmittedFileName();
                    byte[] head = new byte[16];
                    String type;
                    try (InputStream in = p.getInputStream()) {
                        int n = in.readNBytes(head, 0, head.length);
                        type = PhotoStore.sniff(n > 0 ? head : null, p.getContentType());
                    }
                    if (type == null || !(type.startsWith("image/") || type.startsWith("video/"))) {
                        skipped.add(name + " (not a photo or video)");
                        continue;
                    }
                    if (p.getSize() > MAX_FILE) {
                        skipped.add(name + " (over 200 MB)");
                        continue;
                    }
                    try (InputStream in = p.getInputStream()) {
                        MediaLibrary.upload(site, folder, name, in, p.getSize(), type, existing);
                        saved++;
                    }
                }
                msg = saved + " file" + (saved == 1 ? "" : "s") + " uploaded."
                        + (skipped.isEmpty() ? "" : " Skipped: " + String.join(", ", skipped));
                ok = saved > 0 || skipped.isEmpty();

            } else if ("move".equals(action)) {
                // move files / folders (library or earlier uploads) into a library folder; MySQL rows follow
                String[] sources = req.getParameterValues("source");
                if (sources == null || sources.length == 0) throw new IllegalArgumentException("Choose what to move.");
                String target = MediaLibrary.cleanFolder(req.getParameter("target"));
                MediaLibrary.MoveResult r;
                try (Connection conn = WebsiteDB.getConnection(site)) {
                    r = MediaLibrary.move(site, java.util.Arrays.asList(sources), target, conn);
                }
                msg = r.files == 0 && !r.notes.isEmpty() ? String.join("; ", r.notes)
                    : "Moved " + r.files + " file" + (r.files == 1 ? "" : "s") + " to " + (target.isEmpty() ? "the top folder" : target)
                      + (r.rowsUpdated > 0 ? " (" + r.rowsUpdated + " page / news / event photo" + (r.rowsUpdated == 1 ? "" : "s") + " updated)" : "")
                      + (r.notes.isEmpty() ? "." : ". " + String.join("; ", r.notes));
                ok = r.files > 0 || r.notes.isEmpty();
                folder = target;

            } else if ("deleteFile".equals(action)) {
                if (!WebsiteDB.canDelete(sess)) throw new IllegalStateException("Deleting is not allowed for your user.");
                String key = req.getParameter("key");
                if (!MediaLibrary.inLibrary(site, key)) throw new IllegalArgumentException("Unknown file.");
                List<String> used;
                try (Connection conn = WebsiteDB.getConnection(site)) {
                    used = MediaLibrary.usedBy(conn, key);
                }
                if (!used.isEmpty()) {
                    throw new IllegalStateException("This photo is still used on: " + String.join(", ", used)
                            + ". Remove it from those pages first.");
                }
                PhotoStore.delete(key);
                msg = "File deleted.";

            } else if ("deleteFolder".equals(action)) {
                if (!WebsiteDB.canDelete(sess)) throw new IllegalStateException("Deleting is not allowed for your user.");
                if (folder.isEmpty()) throw new IllegalArgumentException("The main folder cannot be deleted.");
                String prefix = MediaLibrary.root(site) + folder;
                PhotoStore.Listing l = PhotoStore.list(prefix);
                boolean onlyMarker = l.folders.isEmpty();
                for (PhotoStore.Item i : l.files) if (!i.key.equals(prefix + MediaLibrary.MARKER)) onlyMarker = false;
                if (!onlyMarker) throw new IllegalStateException("The folder is not empty. Delete or move its photos first.");
                PhotoStore.delete(prefix + MediaLibrary.MARKER);
                msg = "Folder deleted.";
                String f = folder.substring(0, folder.length() - 1);
                folder = f.contains("/") ? f.substring(0, f.lastIndexOf('/') + 1) : "";

            } else {
                throw new IllegalArgumentException("Unknown action.");
            }
        } catch (Exception e) {
            ok = false;
            msg = e.getMessage() == null ? e.toString() : e.getMessage();
        }

        if ("json".equals(req.getParameter("format"))) {
            JsonObject o = new JsonObject();
            o.addProperty("ok", ok);
            o.addProperty("message", msg);
            o.addProperty("folder", folder);
            send(resp, 200, o);
            return;
        }
        resp.sendRedirect("media?folder=" + java.net.URLEncoder.encode(folder, "UTF-8")
                + "&" + (ok ? "msg=" : "err=") + java.net.URLEncoder.encode(msg, "UTF-8"));
    }

    private void forward(HttpServletRequest req, HttpServletResponse resp, String site, String folder,
                         JsonArray folders, JsonArray files) throws ServletException, IOException {
        req.setAttribute("site", site);
        req.setAttribute("folder", folder);
        req.setAttribute("foldersJson", folders.toString());
        req.setAttribute("filesJson", files.toString());
        boolean oldArea = "old".equals(req.getAttribute("area"));
        req.setAttribute("canDelete", !oldArea && WebsiteDB.canDelete(req.getSession(false)));
        req.getRequestDispatcher("/WEB-INF/views/website/media.jsp").forward(req, resp);
    }

    private static JsonObject err(String m) {
        JsonObject o = new JsonObject();
        o.addProperty("ok", false);
        o.addProperty("message", m);
        return o;
    }

    private static void send(HttpServletResponse resp, int status, JsonObject o) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        resp.getWriter().write(o.toString());
    }
}
