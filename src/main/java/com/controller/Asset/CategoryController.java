package com.controller.Asset;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.DAO.CategoryDAO;

@WebServlet("/CategoryController")
public class CategoryController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // ================= LOAD PAGE =================

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        loadPage(request, response);
    }

    // ================= HANDLE FORM ACTIONS =================

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action =
                request.getParameter("action");

        CategoryDAO dao =
                new CategoryDAO();

        String msg = "";

        try {

            // ================= ADD CATEGORY =================

            if ("add".equalsIgnoreCase(action)) {

                boolean status =
                        dao.addCategory(
                        request.getParameter("category_name"),
                        request.getParameter("description"));

                msg = status ? "added" : "failed";
            }

            // ================= UPDATE CATEGORY =================

            else if ("update".equalsIgnoreCase(action)) {

                int categoryId =
                        Integer.parseInt(
                        request.getParameter("category_id"));

                boolean status =
                        dao.updateCategory(
                        categoryId,
                        request.getParameter("category_name"),
                        request.getParameter("description"));

                msg = status ? "updated"
                             : "updatefailed";
            }

            // ================= DELETE CATEGORY =================

            else if ("delete".equalsIgnoreCase(action)) {

                int categoryId =
                        Integer.parseInt(
                        request.getParameter("category_id"));

                boolean status =
                        dao.deleteCategory(categoryId);

                msg = status ? "deleted"
                             : "deletefailed";
            }

            // ================= ADD SUBCATEGORY =================

            else if ("addSubcategory".equalsIgnoreCase(action)) {

                int categoryId =
                        Integer.parseInt(
                        request.getParameter("category_id"));

                boolean status =
                        dao.addSubcategory(
                        categoryId,
                        request.getParameter("subcategory_name"),
                        request.getParameter("description"));

                msg = status ? "subadded"
                             : "subfailed";
            }

            // ================= UPDATE SUBCATEGORY =================

            else if ("updateSubcategory".equalsIgnoreCase(action)) {

                int subcategoryId =
                        Integer.parseInt(
                        request.getParameter("subcategory_id"));

                boolean status =
                        dao.updateSubcategory(
                        subcategoryId,
                        request.getParameter("subcategory_name"),
                        request.getParameter("description"));

                msg = status ? "subupdated"
                             : "subupdatefailed";
            }

            // ================= DELETE SUBCATEGORY =================

            else if ("deleteSubcategory".equalsIgnoreCase(action)) {

                int subcategoryId =
                        Integer.parseInt(
                        request.getParameter("subcategory_id"));

                boolean status =
                        dao.deleteSubcategory(
                        subcategoryId);

                msg = status ? "subdeleted"
                             : "subdeletefailed";
            }

            // ================= INVALID ACTION =================

            else {

                msg = "invalid";
            }

        } catch (Exception e) {

            e.printStackTrace();

            msg = "error";
        }

        // ================= REDIRECT BACK =================

        response.sendRedirect(
                request.getContextPath()
                + "/CategoryController?msg="
                + msg);
    }

    // ================= LOAD JSP PAGE =================

    private void loadPage(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        try {

            CategoryDAO dao =
                    new CategoryDAO();

            ArrayList<HashMap<String, Object>>
            categoryList =
                    dao.getAllCategories();

            request.setAttribute(
                    "categoryList",
                    categoryList);

            RequestDispatcher rd =
                    request.getRequestDispatcher(
                    "/Asset/addCategory.jsp");

            rd.forward(request, response);

        } catch (Exception e) {

            e.printStackTrace();

            response.sendRedirect(
                    request.getContextPath()
                    + "/Asset/addCategory.jsp?msg=error");
        }
    }
}