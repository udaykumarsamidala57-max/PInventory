package com.menu;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.bean.DBUtil;

@WebServlet("/MenuMasterServlet")
public class MenuMasterServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // ============================================================
    // GET
    // ============================================================

    @Override
    protected void doGet(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        // --------------------------------------------------------
        // LOGIN CHECK
        // --------------------------------------------------------

        HttpSession sess = request.getSession(false);

        if (sess == null || sess.getAttribute("username") == null) {

            response.sendRedirect(
                    request.getContextPath() + "/login.jsp"
            );

            return;
        }

        // --------------------------------------------------------
        // BRANCH
        // --------------------------------------------------------

        String branch = (String) sess.getAttribute("branch");

        if (branch == null || branch.trim().isEmpty()) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Branch not found in session."
            );

            return;
        }

        // --------------------------------------------------------
        // ACTION
        // --------------------------------------------------------

        String action = request.getParameter("action");

        // --------------------------------------------------------
        // EDIT
        // --------------------------------------------------------

        if ("edit".equals(action)) {

            String id = request.getParameter("menu_id");

            if (id != null && !id.trim().isEmpty()) {

                try {

                    loadMenuForEdit(
                            request,
                            branch,
                            id
                    );

                } catch (Exception e) {

                    e.printStackTrace();

                    request.setAttribute(
                            "error",
                            "Unable to load menu: "
                                    + e.getMessage()
                    );
                }
            }
        }

        // --------------------------------------------------------
        // LOAD ALL MENUS
        // --------------------------------------------------------

        loadMenus(
                request,
                branch
        );

        // --------------------------------------------------------
        // OPEN JSP
        // --------------------------------------------------------

        request.getRequestDispatcher(
                "/menu/menu_master.jsp"
        ).forward(request, response);
    }


    // ============================================================
    // POST
    // ============================================================

    @Override
    protected void doPost(HttpServletRequest request,
                           HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        // --------------------------------------------------------
        // LOGIN CHECK
        // --------------------------------------------------------

        HttpSession sess = request.getSession(false);

        if (sess == null || sess.getAttribute("username") == null) {

            response.sendRedirect(
                    request.getContextPath() + "/login.jsp"
            );

            return;
        }

        // --------------------------------------------------------
        // BRANCH
        // --------------------------------------------------------

        String branch = (String) sess.getAttribute("branch");

        if (branch == null || branch.trim().isEmpty()) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Branch not found in session."
            );

            return;
        }

        // --------------------------------------------------------
        // ACTION
        // --------------------------------------------------------

        String action = request.getParameter("action");

        try {

            // ----------------------------------------------------
            // SAVE
            // ----------------------------------------------------

            if ("save".equals(action)) {

                saveMenu(
                        request,
                        branch
                );
            }

            // ----------------------------------------------------
            // UPDATE
            // ----------------------------------------------------

            else if ("update".equals(action)) {

                updateMenu(
                        request,
                        branch
                );
            }

            // ----------------------------------------------------
            // DELETE
            // ----------------------------------------------------

            else if ("delete".equals(action)) {

                deleteMenu(
                        request,
                        branch
                );
            }

            // ----------------------------------------------------
            // INVALID ACTION
            // ----------------------------------------------------

            else {

                throw new Exception(
                        "Invalid action."
                );
            }

            // ----------------------------------------------------
            // SUCCESS
            // ----------------------------------------------------

            response.sendRedirect(
                    request.getContextPath()
                            + "/MenuMasterServlet?success=1"
            );

        } catch (Exception e) {

            e.printStackTrace();

            request.setAttribute(
                    "error",
                    e.getMessage()
            );

            loadMenus(
                    request,
                    branch
            );

            request.getRequestDispatcher(
                    "/menu/menu_master.jsp"
            ).forward(request, response);
        }
    }


    // ============================================================
    // LOAD SINGLE MENU
    // ============================================================

    private void loadMenuForEdit(HttpServletRequest request,
                                 String branch,
                                 String id)
            throws Exception {

        int menuId;

        try {

            menuId = Integer.parseInt(id);

        } catch (NumberFormatException e) {

            throw new Exception(
                    "Invalid Menu ID."
            );
        }


        String sql =
                "SELECT menu_id, day_of_week, session, "
                        + "menu_name, remarks, active "
                        + "FROM menu_master "
                        + "WHERE menu_id = ?";


        try (Connection con =
                     DBUtil.getConnection(branch);

             PreparedStatement ps =
                     con.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    menuId
            );

            try (ResultSet rs =
                         ps.executeQuery()) {

                if (rs.next()) {

                    request.setAttribute(
                            "menu_id",
                            rs.getInt("menu_id")
                    );

                    request.setAttribute(
                            "day_of_week",
                            rs.getString("day_of_week")
                    );

                    request.setAttribute(
                            "session",
                            rs.getString("session")
                    );

                    request.setAttribute(
                            "menu_name",
                            rs.getString("menu_name")
                    );

                    request.setAttribute(
                            "remarks",
                            rs.getString("remarks")
                    );

                    request.setAttribute(
                            "active",
                            rs.getInt("active")
                    );

                } else {

                    throw new Exception(
                            "Menu record not found."
                    );
                }
            }
        }
    }


    // ============================================================
    // INSERT MENU
    // ============================================================

    private void saveMenu(HttpServletRequest request,
                          String branch)
            throws Exception {

        String day =
                request.getParameter("day_of_week");

        String session =
                request.getParameter("session");

        String menuName =
                request.getParameter("menu_name");

        String remarks =
                request.getParameter("remarks");


        // --------------------------------------------------------
        // VALIDATION
        // --------------------------------------------------------

        if (day == null || day.trim().isEmpty()) {

            throw new Exception(
                    "Please select a day."
            );
        }

        if (session == null || session.trim().isEmpty()) {

            throw new Exception(
                    "Please select a session."
            );
        }

        if (menuName == null || menuName.trim().isEmpty()) {

            throw new Exception(
                    "Please enter menu name."
            );
        }


        // --------------------------------------------------------
        // INSERT
        // --------------------------------------------------------

        String sql =
                "INSERT INTO menu_master "
                        + "(day_of_week, session, menu_name, remarks, active) "
                        + "VALUES (?, ?, ?, ?, 1)";


        try (Connection con =
                     DBUtil.getConnection(branch);

             PreparedStatement ps =
                     con.prepareStatement(sql)) {

            ps.setString(
                    1,
                    day.trim().toUpperCase()
            );

            ps.setString(
                    2,
                    session.trim().toUpperCase()
            );

            ps.setString(
                    3,
                    menuName.trim()
            );

            ps.setString(
                    4,
                    remarks != null
                            ? remarks.trim()
                            : null
            );

            ps.executeUpdate();
        }
    }


    // ============================================================
    // UPDATE MENU
    // ============================================================

    private void updateMenu(HttpServletRequest request,
                            String branch)
            throws Exception {

        String id =
                request.getParameter("menu_id");

        if (id == null || id.trim().isEmpty()) {

            throw new Exception(
                    "Menu ID is missing."
            );
        }


        int menuId;

        try {

            menuId =
                    Integer.parseInt(id);

        } catch (NumberFormatException e) {

            throw new Exception(
                    "Invalid Menu ID."
            );
        }


        String day =
                request.getParameter("day_of_week");

        String session =
                request.getParameter("session");

        String menuName =
                request.getParameter("menu_name");

        String remarks =
                request.getParameter("remarks");


        // --------------------------------------------------------
        // VALIDATION
        // --------------------------------------------------------

        if (day == null || day.trim().isEmpty()) {

            throw new Exception(
                    "Please select a day."
            );
        }

        if (session == null || session.trim().isEmpty()) {

            throw new Exception(
                    "Please select a session."
            );
        }

        if (menuName == null || menuName.trim().isEmpty()) {

            throw new Exception(
                    "Please enter menu name."
            );
        }


        // --------------------------------------------------------
        // ACTIVE
        // --------------------------------------------------------

        int active =
                request.getParameter("active") != null
                        ? 1
                        : 0;


        // --------------------------------------------------------
        // UPDATE
        // --------------------------------------------------------

        String sql =
                "UPDATE menu_master SET "
                        + "day_of_week = ?, "
                        + "session = ?, "
                        + "menu_name = ?, "
                        + "remarks = ?, "
                        + "active = ? "
                        + "WHERE menu_id = ?";


        try (Connection con =
                     DBUtil.getConnection(branch);

             PreparedStatement ps =
                     con.prepareStatement(sql)) {

            ps.setString(
                    1,
                    day.trim().toUpperCase()
            );

            ps.setString(
                    2,
                    session.trim().toUpperCase()
            );

            ps.setString(
                    3,
                    menuName.trim()
            );

            ps.setString(
                    4,
                    remarks != null
                            ? remarks.trim()
                            : null
            );

            ps.setInt(
                    5,
                    active
            );

            ps.setInt(
                    6,
                    menuId
            );


            int rows =
                    ps.executeUpdate();


            if (rows == 0) {

                throw new Exception(
                        "Menu record not found."
                );
            }
        }
    }


    // ============================================================
    // DELETE MENU
    // ============================================================

    private void deleteMenu(HttpServletRequest request,
                            String branch)
            throws Exception {

        String id =
                request.getParameter("menu_id");

        if (id == null || id.trim().isEmpty()) {

            throw new Exception(
                    "Menu ID is missing."
            );
        }


        int menuId;

        try {

            menuId =
                    Integer.parseInt(id);

        } catch (NumberFormatException e) {

            throw new Exception(
                    "Invalid Menu ID."
            );
        }


        String sql =
                "DELETE FROM menu_master "
                        + "WHERE menu_id = ?";


        try (Connection con =
                     DBUtil.getConnection(branch);

             PreparedStatement ps =
                     con.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    menuId
            );


            int rows =
                    ps.executeUpdate();


            if (rows == 0) {

                throw new Exception(
                        "Menu record not found."
                );
            }
        }
    }


    // ============================================================
    // LOAD ALL MENUS
    // ============================================================

    private void loadMenus(HttpServletRequest request,
                           String branch) {

        List<Map<String, Object>> menus =
                new ArrayList<>();


        String sql =
                "SELECT menu_id, day_of_week, session, "
                        + "menu_name, remarks, active "
                        + "FROM menu_master "
                        + "ORDER BY "
                        + "FIELD(day_of_week, "
                        + "'MONDAY','TUESDAY','WEDNESDAY',"
                        + "'THURSDAY','FRIDAY','SATURDAY','SUNDAY'), "
                        + "FIELD(session, "
                        + "'BREAKFAST','LUNCH','SNACKS','DINNER'), "
                        + "menu_id";


        try (Connection con =
                     DBUtil.getConnection(branch);

             PreparedStatement ps =
                     con.prepareStatement(sql);

             ResultSet rs =
                     ps.executeQuery()) {


            while (rs.next()) {

                Map<String, Object> menu =
                        new HashMap<>();


                menu.put(
                        "menu_id",
                        rs.getInt("menu_id")
                );

                menu.put(
                        "day_of_week",
                        rs.getString("day_of_week")
                );

                menu.put(
                        "session",
                        rs.getString("session")
                );

                menu.put(
                        "menu_name",
                        rs.getString("menu_name")
                );

                menu.put(
                        "remarks",
                        rs.getString("remarks")
                );

                menu.put(
                        "active",
                        rs.getInt("active")
                );


                menus.add(menu);
            }


            request.setAttribute(
                    "menus",
                    menus
            );


        } catch (Exception e) {

            e.printStackTrace();

            request.setAttribute(
                    "error",
                    "Unable to load menus: "
                            + e.getMessage()
            );
        }
    }
}