package com.controller.Asset;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;

import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.DAO.AssetDAO;

@WebServlet("/AssetController")
public class AssetController extends HttpServlet {

    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String action =
                request.getParameter("action");

        AssetDAO dao = new AssetDAO();

        // LOAD PAGE
        if(action == null) {

            ArrayList<HashMap<String,Object>> list =
                    dao.getAllAssets();

            request.setAttribute(
                    "assetList",
                    list);

            RequestDispatcher rd =
                    request.getRequestDispatcher(
                            "/Asset/asset.jsp");

            rd.forward(request,response);
        }

        // DELETE
        else if("delete".equals(action)) {

            int id =
                    Integer.parseInt(
                            request.getParameter("id"));

            dao.deleteAsset(id);

            response.sendRedirect(
                    request.getContextPath()
                    + "/AssetController");
        }

        // EDIT
        else if("edit".equals(action)) {

            int id =
                    Integer.parseInt(
                            request.getParameter("id"));

            HashMap<String,Object> asset =
                    dao.getAssetById(id);

            ArrayList<HashMap<String,Object>> list =
                    dao.getAllAssets();

            request.setAttribute("asset", asset);

            request.setAttribute(
                    "assetList",
                    list);

            RequestDispatcher rd =
                    request.getRequestDispatcher(
                            "/Asset/asset.jsp");

            rd.forward(request,response);
        }
    }

    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String action =
                request.getParameter("action");

        AssetDAO dao = new AssetDAO();

        String assetCode =
                request.getParameter("assetCode");

        String assetName =
                request.getParameter("assetName");

        int vendorId =
                Integer.parseInt(
                        request.getParameter("vendorId"));

        String brand =
                request.getParameter("brand");

        // ADD
        if("add".equals(action)) {

            dao.addAsset(
                    assetCode,
                    assetName,
                    vendorId,
                    brand);
        }

        // UPDATE
        else if("update".equals(action)) {

            int assetId =
                    Integer.parseInt(
                            request.getParameter("assetId"));

            dao.updateAsset(
                    assetId,
                    assetCode,
                    assetName,
                    vendorId,
                    brand);
        }

        response.sendRedirect(
                request.getContextPath()
                + "/AssetController");
    }
}