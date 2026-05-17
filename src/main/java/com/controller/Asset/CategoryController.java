package com.controller.Asset;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.DAO.CategoryDAO;

@WebServlet("/CategoryController")
public class CategoryController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");

        String action = request.getParameter("action");

        CategoryDAO dao = new CategoryDAO();

        try {

            // ADD
            if ("add".equals(action)) {

                String categoryName =
                        request.getParameter("category_name");

                String subcategoryName =
                        request.getParameter("subcategory_name");

                String description =
                        request.getParameter("description");

                boolean status =
                        dao.addCategory(categoryName,
                                        subcategoryName,
                                        description);

                if (status) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/Asset/addCategory.jsp?msg=added");

                } else {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/Asset/addCategory.jsp?msg=failed");
                }
            }

            // UPDATE
            else if ("update".equals(action)) {

                int categoryId =
                        Integer.parseInt(
                                request.getParameter("category_id"));

                String categoryName =
                        request.getParameter("category_name");

                String subcategoryName =
                        request.getParameter("subcategory_name");

                String description =
                        request.getParameter("description");

                boolean status =
                        dao.updateCategory(categoryId,
                                           categoryName,
                                           subcategoryName,
                                           description);

                if (status) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/Asset/addCategory.jsp?msg=updated");

                } else {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/Asset/addCategory.jsp?msg=updatefailed");
                }
            }

            // DELETE
            else if ("delete".equals(action)) {

                int categoryId =
                        Integer.parseInt(
                                request.getParameter("category_id"));

                boolean status =
                        dao.deleteCategory(categoryId);

                if (status) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/Asset/addCategory.jsp?msg=deleted");

                } else {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/Asset/addCategory.jsp?msg=deletefailed");
                }
            }

        } catch (Exception e) {

            e.printStackTrace();

            response.sendRedirect(
                    request.getContextPath()
                    + "/Asset/addCategory.jsp?msg=error");
        }
    }

    // IMPORTANT FIX
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        request.getRequestDispatcher("/Asset/addCategory.jsp")
               .forward(request, response);
    }
}