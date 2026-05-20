package com.controller.Asset;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;

import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.DAO.AssetLocationDAO;

@WebServlet("/AssetLocationController")
public class AssetLocationController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    AssetLocationDAO dao;

    @Override
    public void init() throws ServletException {
        dao = new AssetLocationDAO();
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");

        if (action != null && action.equals("history")) {
            getAssetHistory(req, resp);
        } else if (action == null || action.equals("load")) {
            loadPage(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");

        if (action != null && action.equals("assign")) {
            assignLocation(req, resp);
        }
    }

    private void loadPage(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        try {
            String categoryId = req.getParameter("category_id");
            String subcategoryId = req.getParameter("subcategory_id");

            req.setAttribute("categories", dao.getCategories());
            req.setAttribute("locations", dao.getLocations());

            if (categoryId != null && !categoryId.trim().isEmpty()) {
                req.setAttribute("subcategories", dao.getSubcategories(categoryId));
            }

            if (categoryId != null && subcategoryId != null && !subcategoryId.trim().isEmpty()) {
                req.setAttribute("assets", dao.getAssets(categoryId, subcategoryId));
            }

            RequestDispatcher rd = req.getRequestDispatcher("/Asset/assignAssetLocation.jsp");
            rd.forward(req, resp);

        } catch (Exception e) {
            e.printStackTrace();
            resp.getWriter().println("Error Loading Page");
        }
    }

    private void getAssetHistory(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        
        try {
            String assetIdStr = req.getParameter("asset_id");
            if (assetIdStr == null || assetIdStr.trim().isEmpty()) {
                out.print("[]");
                return;
            }
            
            int assetId = Integer.parseInt(assetIdStr);
            
            ArrayList<HashMap<String, Object>> historyList = dao.getAssetHistory(assetId);
            
            if (historyList == null || historyList.isEmpty()) {
                out.print("[]");
                return;
            }
            
            StringBuilder json = new StringBuilder();
            json.append("[");
            
            for (int i = 0; i < historyList.size(); i++) {
                HashMap<String, Object> row = historyList.get(i);
                
                // Pull maps safely without relying on raw object type evaluations
                String fromLoc = escapeJson(row.get("from_location") != null ? row.get("from_location").toString() : "");
                String toLoc = escapeJson(row.get("to_location") != null ? row.get("to_location").toString() : "");
                String movedBy = escapeJson(row.get("moved_by") != null ? row.get("moved_by").toString() : "");
                String timestamp = escapeJson(row.get("moved_datetime") != null ? row.get("moved_datetime").toString() : "");
                String remarks = escapeJson(row.get("remarks") != null ? row.get("remarks").toString() : "");
                
                json.append("{");
                json.append("\"from_location\":\"").append(fromLoc).append("\",");
                json.append("\"to_location\":\"").append(toLoc).append("\",");
                json.append("\"moved_by\":\"").append(movedBy).append("\",");
                json.append("\"moved_datetime\":\"").append(timestamp).append("\",");
                json.append("\"remarks\":\"").append(remarks).append("\"");
                json.append("}");
                
                if (i < historyList.size() - 1) {
                    json.append(",");
                }
            }
            
            json.append("]");
            out.print(json.toString());
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"Failed to look up asset history arrays\"}");
        } finally {
            out.flush();
        }
    }

    private String escapeJson(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\b", "\\b")
                    .replace("\f", "\\f")
                    .replace("\n", "\\n")
                    .replace("\r", "\\r")
                    .replace("\t", "\\t");
    }

    private void assignLocation(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        try {
            HttpSession sess = req.getSession(false);

            if (sess == null) {
                resp.sendRedirect("login.jsp");
                return;
            }

            String user = String.valueOf(sess.getAttribute("username"));
            int assetId = Integer.parseInt(req.getParameter("asset_id"));
            int locationId = Integer.parseInt(req.getParameter("location_id"));

            boolean status = dao.assignLocation(assetId, locationId, user);

            if (status) {
                String categoryId = req.getParameter("category_id");
                String subcategoryId = req.getParameter("subcategory_id");

                resp.sendRedirect("AssetLocationController"
                        + "?action=load"
                        + "&category_id=" + categoryId
                        + "&subcategory_id=" + subcategoryId
                        + "&msg=success");
            } else {
                resp.sendRedirect("AssetLocationController?action=load&msg=failed");
            }

        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect("AssetLocationController?action=load&msg=error");
        }
    }
}