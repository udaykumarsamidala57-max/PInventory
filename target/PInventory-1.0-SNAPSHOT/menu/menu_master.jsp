<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%@ page import="java.util.List"%>
<%@ page import="java.util.Map"%>

<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<title>Menu Master</title>

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<style>

/* =========================================================
   BASE
   ========================================================= */

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    background: #f4f6f8;
    font-family: Arial, Helvetica, sans-serif;
    color: #172b4d;
}


/* =========================================================
   CONTAINER
   ========================================================= */

.container {
    width: 100%;
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}


/* =========================================================
   HEADER
   ========================================================= */

.page-header {
    background: #ffffff;
    border-radius: 8px;
    padding: 16px 20px;
    margin-bottom: 15px;
    border: 1px solid #e1e5e9;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.page-title {
    margin: 0;
    font-size: 22px;
    font-weight: 600;
}

.page-subtitle {
    margin-top: 4px;
    color: #6b778c;
    font-size: 13px;
}


/* =========================================================
   CARD
   ========================================================= */

.card {
    background: #ffffff;
    border-radius: 8px;
    border: 1px solid #e1e5e9;
    margin-bottom: 15px;
}

.card-header {
    padding: 14px 18px;
    border-bottom: 1px solid #e5e8eb;
    font-size: 15px;
    font-weight: 600;
}

.card-body {
    padding: 18px;
}


/* =========================================================
   MESSAGE
   ========================================================= */

.message {
    padding: 11px 14px;
    border-radius: 6px;
    margin-bottom: 15px;
    font-size: 14px;
}

.success {
    background: #eaf7ed;
    color: #216e39;
    border: 1px solid #b7dfc2;
}

.error {
    background: #fff1f0;
    color: #ba0517;
    border: 1px solid #f1b8b5;
}


/* =========================================================
   FORM
   ========================================================= */

.form-grid {
    display: grid;
    grid-template-columns:
        1fr
        1fr
        1.5fr
        2fr
        auto;

    gap: 12px;
    align-items: end;
}

.form-group {
    min-width: 0;
}

.form-label {
    display: block;
    font-size: 12px;
    font-weight: 600;
    margin-bottom: 5px;
    color: #44546a;
}

.form-control {
    width: 100%;
    height: 38px;
    padding: 0 10px;
    border: 1px solid #c9d1d9;
    border-radius: 5px;
    background: #ffffff;
    color: #172b4d;
    font-size: 14px;
}

.form-control:focus {
    outline: none;
    border-color: #0176d3;
    box-shadow: 0 0 0 1px #0176d3;
}


/* =========================================================
   BUTTONS
   ========================================================= */

.btn {
    height: 38px;
    border: none;
    border-radius: 5px;
    padding: 0 16px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    white-space: nowrap;
}

.btn-primary {
    background: #0176d3;
    color: #ffffff;
}

.btn-primary:hover {
    background: #0b5cab;
}

.btn-success {
    background: #2e844a;
    color: #ffffff;
}

.btn-secondary {
    background: #747474;
    color: #ffffff;
}

.btn-edit {
    background: #eaf4ff;
    color: #0176d3;
    height: 32px;
    padding: 0 11px;
}

.btn-delete {
    background: #fff0f0;
    color: #ba0517;
    height: 32px;
    padding: 0 11px;
}


/* =========================================================
   TABLE
   ========================================================= */

.table-wrapper {
    width: 100%;
    overflow-x: auto;
}

.menu-table {
    width: 100%;
    border-collapse: collapse;
    min-width: 750px;
}

.menu-table th {
    background: #f7f8fa;
    color: #44546a;
    text-align: left;
    font-size: 12px;
    font-weight: 600;
    padding: 11px 12px;
    border-bottom: 1px solid #d8dde6;
    white-space: nowrap;
}

.menu-table td {
    padding: 10px 12px;
    font-size: 13px;
    border-bottom: 1px solid #e8eaed;
    vertical-align: middle;
}

.menu-table tr:hover {
    background: #fafbfc;
}

.menu-name {
    font-weight: 600;
    color: #172b4d;
}


/* =========================================================
   DAY / SESSION
   ========================================================= */

.day-badge {
    font-weight: 600;
}

.session-badge {
    display: inline-block;
    padding: 4px 8px;
    border-radius: 4px;
    background: #eef4ff;
    color: #245ea9;
    font-size: 11px;
    font-weight: 600;
}


/* =========================================================
   STATUS
   ========================================================= */

.status-active {
    color: #2e844a;
    font-weight: 600;
    font-size: 12px;
}

.status-inactive {
    color: #ba0517;
    font-weight: 600;
    font-size: 12px;
}


/* =========================================================
   ACTIONS
   ========================================================= */

.actions {
    display: flex;
    gap: 6px;
    align-items: center;
}

.delete-form {
    margin: 0;
}


/* =========================================================
   EMPTY
   ========================================================= */

.empty {
    text-align: center;
    padding: 35px 15px !important;
    color: #6b778c;
}


/* =========================================================
   RESPONSIVE
   ========================================================= */

@media (max-width: 900px) {

    .form-grid {
        grid-template-columns: 1fr 1fr;
    }

    .form-group:last-child {
        grid-column: 1 / -1;
    }

}


@media (max-width: 600px) {

    .container {
        padding: 10px;
    }

    .page-header {
        padding: 14px;
    }

    .page-title {
        font-size: 19px;
    }

    .card-body {
        padding: 12px;
    }

    .form-grid {
        grid-template-columns: 1fr;
        gap: 10px;
    }

    .form-group:last-child {
        grid-column: auto;
    }

    .btn {
        width: 100%;
    }

}

</style>

</head>


<body>


<div class="container">


    <!-- =====================================================
         PAGE HEADER
         ===================================================== -->

    <div class="page-header">

        <div>

            <h1 class="page-title">
                Menu Master
            </h1>

            <div class="page-subtitle">
                Manage day-wise and session-wise dining menus
            </div>

        </div>

    </div>


    <!-- =====================================================
         SUCCESS MESSAGE
         ===================================================== -->

    <%
        String success = request.getParameter("success");

        if ("1".equals(success)) {
    %>

        <div class="message success">
            Menu saved successfully.
        </div>

    <%
        }
    %>


    <!-- =====================================================
         ERROR MESSAGE
         ===================================================== -->

    <%
        String error =
                (String) request.getAttribute("error");

        if (error != null && !error.trim().isEmpty()) {
    %>

        <div class="message error">
            <%= error %>
        </div>

    <%
        }
    %>


    <!-- =====================================================
         CHECK EDIT MODE
         ===================================================== -->

    <%
        Object menuIdObj =
                request.getAttribute("menu_id");

        boolean editMode =
                menuIdObj != null;

        String menuId =
                editMode
                ? String.valueOf(menuIdObj)
                : "";

        String selectedDay =
                request.getAttribute("day_of_week") != null
                ? String.valueOf(
                        request.getAttribute("day_of_week"))
                : "";

        String selectedSession =
                request.getAttribute("session") != null
                ? String.valueOf(
                        request.getAttribute("session"))
                : "";

        String menuName =
                request.getAttribute("menu_name") != null
                ? String.valueOf(
                        request.getAttribute("menu_name"))
                : "";

        String remarks =
                request.getAttribute("remarks") != null
                ? String.valueOf(
                        request.getAttribute("remarks"))
                : "";

        int active =
                request.getAttribute("active") != null
                ? Integer.parseInt(
                        String.valueOf(
                                request.getAttribute("active")))
                : 1;
    %>


    <!-- =====================================================
         ADD / EDIT FORM
         ===================================================== -->

    <div class="card">

        <div class="card-header">

            <%= editMode
                    ? "Edit Menu"
                    : "Add Menu" %>

        </div>


        <div class="card-body">

            <form method="post"
                  action="<%=request.getContextPath()%>/MenuMasterServlet">


                <!-- ACTION -->

                <input type="hidden"
                       name="action"
                       value="<%=editMode ? "update" : "save"%>">


                <!-- MENU ID -->

                <% if (editMode) { %>

                    <input type="hidden"
                           name="menu_id"
                           value="<%=menuId%>">

                <% } %>


                <div class="form-grid">


                    <!-- DAY -->

                    <div class="form-group">

                        <label class="form-label">
                            Day
                        </label>

                        <select name="day_of_week"
                                class="form-control"
                                required>

                            <option value="">
                                Select Day
                            </option>

                            <%
                                String[] days = {
                                    "MONDAY",
                                    "TUESDAY",
                                    "WEDNESDAY",
                                    "THURSDAY",
                                    "FRIDAY",
                                    "SATURDAY",
                                    "SUNDAY"
                                };

                                for (String day : days) {
                            %>

                                <option value="<%=day%>"
                                    <%=day.equals(selectedDay)
                                            ? "selected"
                                            : ""%>>
                                    <%=day%>
                                </option>

                            <%
                                }
                            %>

                        </select>

                    </div>


                    <!-- SESSION -->

                    <div class="form-group">

                        <label class="form-label">
                            Session
                        </label>

                        <select name="session"
                                class="form-control"
                                required>

                            <option value="">
                                Select Session
                            </option>

                            <option value="BREAKFAST"
                                <%="BREAKFAST".equals(selectedSession)
                                        ? "selected"
                                        : ""%>>
                                BREAKFAST
                            </option>

                            <option value="LUNCH"
                                <%="LUNCH".equals(selectedSession)
                                        ? "selected"
                                        : ""%>>
                                LUNCH
                            </option>

                            <option value="SNACKS"
                                <%="SNACKS".equals(selectedSession)
                                        ? "selected"
                                        : ""%>>
                                SNACKS
                            </option>

                            <option value="DINNER"
                                <%="DINNER".equals(selectedSession)
                                        ? "selected"
                                        : ""%>>
                                DINNER
                            </option>

                        </select>

                    </div>


                    <!-- MENU NAME -->

                    <div class="form-group">

                        <label class="form-label">
                            Menu Name
                        </label>

                        <input type="text"
                               name="menu_name"
                               class="form-control"
                               placeholder="Eg: IDLY"
                               maxlength="100"
                               value="<%=menuName%>"
                               required>

                    </div>


                    <!-- REMARKS -->

                    <div class="form-group">

                        <label class="form-label">
                            Remarks
                        </label>

                        <input type="text"
                               name="remarks"
                               class="form-control"
                               placeholder="Optional"
                               maxlength="255"
                               value="<%=remarks%>">

                    </div>


                    <!-- BUTTON -->

                    <div class="form-group">


                        <% if (editMode) { %>


                            <div style="display:flex; gap:6px;">

                                <button type="submit"
                                        class="btn btn-success">

                                    Update

                                </button>


                                <a href="<%=request.getContextPath()%>/MenuMasterServlet"
                                   class="btn btn-secondary">

                                    Cancel

                                </a>

                            </div>


                        <% } else { %>


                            <button type="submit"
                                    class="btn btn-primary">

                                + Add Menu

                            </button>


                        <% } %>


                    </div>

                </div>

            </form>

        </div>

    </div>


    <!-- =====================================================
         MENU LIST
         ===================================================== -->

    <div class="card">

        <div class="card-header">

            Menu List

        </div>


        <div class="card-body"
             style="padding:0;">


            <div class="table-wrapper">


                <table class="menu-table">


                    <thead>

                        <tr>

                            <th>
                                ID
                            </th>

                            <th>
                                DAY
                            </th>

                            <th>
                                SESSION
                            </th>

                            <th>
                                MENU
                            </th>

                            <th>
                                REMARKS
                            </th>

                            <th>
                                STATUS
                            </th>

                            <th>
                                ACTION
                            </th>

                        </tr>

                    </thead>


                    <tbody>


                    <%
                        List<Map<String,Object>> menus =
                                (List<Map<String,Object>>)
                                request.getAttribute("menus");


                        if (menus != null
                                && !menus.isEmpty()) {


                            for (Map<String,Object> menu
                                    : menus) {


                                Object id =
                                        menu.get("menu_id");

                                Object day =
                                        menu.get("day_of_week");

                                Object sessionValue =
                                        menu.get("session");

                                Object name =
                                        menu.get("menu_name");

                                Object remark =
                                        menu.get("remarks");

                                Object status =
                                        menu.get("active");

                    %>


                        <tr>


                            <!-- ID -->

                            <td>
                                <%=id%>
                            </td>


                            <!-- DAY -->

                            <td>

                                <span class="day-badge">
                                    <%=day%>
                                </span>

                            </td>


                            <!-- SESSION -->

                            <td>

                                <span class="session-badge">
                                    <%=sessionValue%>
                                </span>

                            </td>


                            <!-- MENU -->

                            <td>

                                <span class="menu-name">
                                    <%=name%>
                                </span>

                            </td>


                            <!-- REMARKS -->

                            <td>

                                <%=remark != null
                                        ? remark
                                        : ""%>

                            </td>


                            <!-- STATUS -->

                            <td>


                                <%
                                    int statusValue =
                                            status != null
                                            ? Integer.parseInt(
                                                    status.toString())
                                            : 0;

                                    if (statusValue == 1) {
                                %>

                                    <span class="status-active">
                                        ACTIVE
                                    </span>

                                <%
                                    } else {
                                %>

                                    <span class="status-inactive">
                                        INACTIVE
                                    </span>

                                <%
                                    }
                                %>


                            </td>


                            <!-- ACTION -->

                            <td>


                                <div class="actions">


                                    <!-- EDIT -->

                                    <a href="<%=request.getContextPath()%>/MenuMasterServlet?action=edit&menu_id=<%=id%>"
                                       class="btn btn-edit">

                                        Edit

                                    </a>


                                    <!-- DELETE -->

                                    <form method="post"
                                          action="<%=request.getContextPath()%>/MenuMasterServlet"
                                          class="delete-form"
                                          onsubmit="return confirm('Are you sure you want to delete this menu?');">


                                        <input type="hidden"
                                               name="action"
                                               value="delete">


                                        <input type="hidden"
                                               name="menu_id"
                                               value="<%=id%>">


                                        <button type="submit"
                                                class="btn btn-delete">

                                            Delete

                                        </button>


                                    </form>


                                </div>


                            </td>


                        </tr>


                    <%
                            }

                        } else {
                    %>


                        <tr>

                            <td colspan="7"
                                class="empty">

                                No menu records found.

                            </td>

                        </tr>


                    <%
                        }
                    %>


                    </tbody>


                </table>


            </div>


        </div>

    </div>


</div>


</body>

</html>