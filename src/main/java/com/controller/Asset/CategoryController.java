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

            // ================= ADD CATEGORY =================

            if("add".equalsIgnoreCase(action)) {

                boolean status =
                        dao.addCategory(
                        request.getParameter("category_name"),
                        request.getParameter("description"));

                response.sendRedirect(
                        request.getContextPath()
                        + "/Asset/addCategory.jsp?msg="
                        + (status ? "added" : "failed"));
            }

            // ================= UPDATE CATEGORY =================

            else if("update".equalsIgnoreCase(action)) {

                boolean status =
                        dao.updateCategory(
                        Integer.parseInt(
                        request.getParameter("category_id")),
                        request.getParameter("category_name"),
                        request.getParameter("description"));

                response.sendRedirect(
                        request.getContextPath()
                        + "/Asset/addCategory.jsp?msg="
                        + (status ? "updated" : "updatefailed"));
            }

            // ================= DELETE CATEGORY =================

            else if("delete".equalsIgnoreCase(action)) {

                boolean status =
                        dao.deleteCategory(
                        Integer.parseInt(
                        request.getParameter("category_id")));

                response.sendRedirect(
                        request.getContextPath()
                        + "/Asset/addCategory.jsp?msg="
                        + (status ? "deleted" : "deletefailed"));
            }

            // ================= ADD SUBCATEGORY =================

            else if("addSubcategory".equalsIgnoreCase(action)) {

                boolean status =
                        dao.addSubcategory(
                        Integer.parseInt(
                        request.getParameter("category_id")),
                        request.getParameter("subcategory_name"),
                        request.getParameter("description"));

                response.sendRedirect(
                        request.getContextPath()
                        + "/Asset/addCategory.jsp?msg="
                        + (status ? "subadded" : "subfailed"));
            }

            // ================= UPDATE SUBCATEGORY =================

            else if("updateSubcategory".equalsIgnoreCase(action)) {

                boolean status =
                        dao.updateSubcategory(
                        Integer.parseInt(
                        request.getParameter("subcategory_id")),
                        request.getParameter("subcategory_name"),
                        request.getParameter("description"));

                response.sendRedirect(
                        request.getContextPath()
                        + "/Asset/addCategory.jsp?msg="
                        + (status ? "subupdated"
                                  : "subupdatefailed"));
            }

            // ================= DELETE SUBCATEGORY =================

            else if("deleteSubcategory".equalsIgnoreCase(action)) {

                boolean status =
                        dao.deleteSubcategory(
                        Integer.parseInt(
                        request.getParameter("subcategory_id")));

                response.sendRedirect(
                        request.getContextPath()
                        + "/Asset/addCategory.jsp?msg="
                        + (status ? "subdeleted"
                                  : "subdeletefailed"));
            }

            else {

                response.sendRedirect(
                        request.getContextPath()
                        + "/Asset/addCategory.jsp?msg=invalid");
            }

        } catch(Exception e) {

            e.printStackTrace();

            response.sendRedirect(
                    request.getContextPath()
                    + "/Asset/addCategory.jsp?msg=error");
        }
    }

    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        doPost(request, response);
    }
}