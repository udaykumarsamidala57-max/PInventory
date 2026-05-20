package com.controller.Asset;

import java.io.IOException;

import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.DAO.AssetLocationDAO;

@WebServlet("/AssetLocationController")
public class AssetLocationController
extends HttpServlet {

    private static final long serialVersionUID = 1L;

    AssetLocationDAO dao;

    @Override
    public void init()
            throws ServletException {

        dao = new AssetLocationDAO();
    }

    protected void doGet(

            HttpServletRequest req,

            HttpServletResponse resp)

            throws ServletException,
            IOException {

        String action =
        req.getParameter("action");

        if(action == null
                || action.equals("load")){

            loadPage(req, resp);
        }
    }

    protected void doPost(

            HttpServletRequest req,

            HttpServletResponse resp)

            throws ServletException,
            IOException {

        String action =
        req.getParameter("action");

        if(action != null
                && action.equals("assign")){

            assignLocation(req, resp);
        }
    }

    private void loadPage(

            HttpServletRequest req,

            HttpServletResponse resp)

            throws ServletException,
            IOException {

        try{

            String categoryId =
            req.getParameter(
            "category_id");

            String subcategoryId =
            req.getParameter(
            "subcategory_id");

            req.setAttribute(

            "categories",

            dao.getCategories());

            req.setAttribute(

            "locations",

            dao.getLocations());

            if(categoryId != null
                    && !categoryId.trim()
                    .isEmpty()){

                req.setAttribute(

                "subcategories",

                dao.getSubcategories(
                categoryId));
            }

            if(categoryId != null
                    && subcategoryId != null
                    && !subcategoryId.trim()
                    .isEmpty()){

                req.setAttribute(

                "assets",

                dao.getAssets(
                categoryId,
                subcategoryId));
            }

            RequestDispatcher rd =

            req.getRequestDispatcher(

            "/Asset/"
            + "assignAssetLocation.jsp");

            rd.forward(req, resp);

        }catch(Exception e){

            e.printStackTrace();

            resp.getWriter().println(
            "Error Loading Page");
        }
    }

    private void assignLocation(

            HttpServletRequest req,

            HttpServletResponse resp)

            throws IOException {

        try{

            HttpSession sess =
            req.getSession(false);

            if(sess == null){

                resp.sendRedirect(
                "login.jsp");

                return;
            }

            String user =

            String.valueOf(

            sess.getAttribute(
            "username"));

            int assetId =

            Integer.parseInt(

            req.getParameter(
            "asset_id"));

            int locationId =

            Integer.parseInt(

            req.getParameter(
            "location_id"));

            boolean status =

            dao.assignLocation(

            assetId,

            locationId,

            user);

            if(status){

            	String categoryId =
            			req.getParameter("category_id");

            			String subcategoryId =
            			req.getParameter("subcategory_id");

            			resp.sendRedirect(

            			"AssetLocationController"

            			+ "?action=load"

            			+ "&category_id="
            			+ categoryId

            			+ "&subcategory_id="
            			+ subcategoryId

            			+ "&msg=success");

            }else{

                resp.sendRedirect(

                "AssetLocationController"
                + "?action=load"
                + "&msg=failed");
            }

        }catch(Exception e){

            e.printStackTrace();

            resp.sendRedirect(

            "AssetLocationController"
            + "?action=load"
            + "&msg=error");
        }
    }
}