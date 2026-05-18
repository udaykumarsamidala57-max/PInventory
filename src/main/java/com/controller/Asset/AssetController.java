package com.controller.Asset;

import java.io.IOException;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.DAO.AssetDAO;

@WebServlet("/AssetController")
public class AssetController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // =========================
    // DO GET
    // =========================

    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        // =========================
        // SESSION CHECK
        // =========================

        HttpSession sess =
                request.getSession(false);

        if (sess == null
                || sess.getAttribute("username") == null) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/login.jsp");

            return;
        }

        String role =
                String.valueOf(
                        sess.getAttribute("role"));

        String dept =
                String.valueOf(
                        sess.getAttribute("department"));

        if (!"Global".equalsIgnoreCase(role)
                && !"Finance".equalsIgnoreCase(dept)) {

            response.setContentType("text/html");

            response.getWriter().println(
                    "<h3 style='color:red;"
                    + "text-align:center;"
                    + "margin-top:40px;'>"
                    + "Access Denied!"
                    + "</h3>");

            return;
        }

        String action =
                request.getParameter("action");

        AssetDAO dao =
                new AssetDAO();

        // =========================
        // LOAD DROPDOWNS
        // =========================

        loadDropdowns(request, dao);

        // =========================
        // DEFAULT PAGE
        // =========================

        if (action == null
                || action.trim().equals("")) {

            request.setAttribute(
                    "assetList",
                    dao.getAllAssets());

            RequestDispatcher rd =
                    request.getRequestDispatcher(
                            "/Asset/asset.jsp");

            rd.forward(request, response);

            return;
        }

        // =========================
        // DELETE
        // =========================

        if ("delete".equalsIgnoreCase(action)) {

            try {

                int id =
                        Integer.parseInt(
                                request.getParameter("id"));

                boolean status =
                        dao.deleteAsset(id);

                if (status) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/AssetController?msg=deleted");

                } else {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/AssetController?msg=deletefailed");
                }

            } catch (Exception e) {

                e.printStackTrace();

                response.sendRedirect(
                        request.getContextPath()
                        + "/AssetController?msg=error");
            }

            return;
        }

        // =========================
        // EDIT
        // =========================

        if ("edit".equalsIgnoreCase(action)) {

            try {

                int id =
                        Integer.parseInt(
                                request.getParameter("id"));

                request.setAttribute(
                        "asset",
                        dao.getAssetById(id));

                request.setAttribute(
                        "assetList",
                        dao.getAllAssets());

                RequestDispatcher rd =
                        request.getRequestDispatcher(
                                "/Asset/asset.jsp");

                rd.forward(request, response);

            } catch (Exception e) {

                e.printStackTrace();

                response.sendRedirect(
                        request.getContextPath()
                        + "/AssetController?msg=error");
            }
        }
    }

    // =========================
    // DO POST
    // =========================

    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        // =========================
        // SESSION CHECK
        // =========================

        HttpSession sess =
                request.getSession(false);

        if (sess == null
                || sess.getAttribute("username") == null) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/login.jsp");

            return;
        }

        request.setCharacterEncoding("UTF-8");

        String action =
                request.getParameter("action");

        AssetDAO dao =
                new AssetDAO();

        try {

            // =========================
            // FORM VALUES
            // =========================

            String assetCode =
                    nullCheck(
                            request.getParameter(
                                    "assetCode"));

            String assetName =
                    nullCheck(
                            request.getParameter(
                                    "assetName"));

            int categoryId =
                    parseInt(
                            request.getParameter(
                                    "categoryId"));

            int subcategoryId =
                    parseInt(
                            request.getParameter(
                                    "subcategoryId"));

            String vendorName =
                    nullCheck(
                            request.getParameter(
                                    "vendor_name"));

            int locationId =
                    parseInt(
                            request.getParameter(
                                    "locationId"));

            String brand =
                    nullCheck(
                            request.getParameter(
                                    "brand"));

            String modelNumber =
                    nullCheck(
                            request.getParameter(
                                    "modelNumber"));

            String serialNumber =
                    nullCheck(
                            request.getParameter(
                                    "serialNumber"));

            String purchaseDate =
                    nullCheck(
                            request.getParameter(
                                    "purchaseDate"));

            double purchaseCost =
                    parseDouble(
                            request.getParameter(
                                    "purchaseCost"));

            String warrantyExpiry =
                    nullCheck(
                            request.getParameter(
                                    "warrantyExpiry"));

            String depreciationMethod =
                    nullCheck(
                            request.getParameter(
                                    "depreciationMethod"));

            int usefulLifeYears =
                    parseInt(
                            request.getParameter(
                                    "usefulLifeYears"));

            double salvageValue =
                    parseDouble(
                            request.getParameter(
                                    "salvageValue"));

            String assetStatus =
                    nullCheck(
                            request.getParameter(
                                    "assetStatus"));

            String qrCode =
                    nullCheck(
                            request.getParameter(
                                    "qrCode"));

            String description =
                    nullCheck(
                            request.getParameter(
                                    "description"));

            boolean status = false;

            // =========================
            // ADD
            // =========================

            if ("add".equalsIgnoreCase(action)) {

                status =
                        dao.addAsset(

                                assetCode,
                                assetName,
                                categoryId,
                                subcategoryId,
                                vendorName,
                                locationId,
                                brand,
                                modelNumber,
                                serialNumber,
                                purchaseDate,
                                purchaseCost,
                                warrantyExpiry,
                                depreciationMethod,
                                usefulLifeYears,
                                salvageValue,
                                assetStatus,
                                qrCode,
                                description);

                if (status) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/AssetController?msg=added");

                } else {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/AssetController?msg=addfailed");
                }

                return;
            }

            // =========================
            // UPDATE
            // =========================

            if ("update".equalsIgnoreCase(action)) {

                int assetId =
                        parseInt(
                                request.getParameter(
                                        "assetId"));

                status =
                        dao.updateAsset(

                                assetId,
                                assetCode,
                                assetName,
                                categoryId,
                                subcategoryId,
                                vendorName,
                                locationId,
                                brand,
                                modelNumber,
                                serialNumber,
                                purchaseDate,
                                purchaseCost,
                                warrantyExpiry,
                                depreciationMethod,
                                usefulLifeYears,
                                salvageValue,
                                assetStatus,
                                qrCode,
                                description);

                if (status) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/AssetController?msg=updated");

                } else {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/AssetController?msg=updatefailed");
                }

                return;
            }

            // =========================
            // INVALID ACTION
            // =========================

            response.sendRedirect(
                    request.getContextPath()
                    + "/AssetController?msg=invalid");

        } catch (Exception e) {

            e.printStackTrace();

            response.sendRedirect(
                    request.getContextPath()
                    + "/AssetController?msg=error");
        }
    }

    // =========================
    // LOAD DROPDOWNS
    // =========================

    private void loadDropdowns(
            HttpServletRequest request,
            AssetDAO dao) {

        request.setAttribute(
                "vendorList",
                dao.getAllVendors());

        request.setAttribute(
                "categoryList",
                dao.getAllCategories());

        request.setAttribute(
                "subcategoryList",
                dao.getAllSubCategories());

        request.setAttribute(
                "locationList",
                dao.getAllLocations());
    }

    // =========================
    // NULL CHECK
    // =========================

    private String nullCheck(String value) {

        if (value == null) {

            return "";
        }

        return value.trim();
    }

    // =========================
    // PARSE INT
    // =========================

    private int parseInt(String value) {

        try {

            if (value == null
                    || value.trim().equals("")) {

                return 0;
            }

            return Integer.parseInt(value);

        } catch (Exception e) {

            return 0;
        }
    }

    // =========================
    // PARSE DOUBLE
    // =========================

    private double parseDouble(String value) {

        try {

            if (value == null
                    || value.trim().equals("")) {

                return 0.0;
            }

            return Double.parseDouble(value);

        } catch (Exception e) {

            return 0.0;
        }
    }
}