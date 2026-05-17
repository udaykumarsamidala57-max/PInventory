<%@page import="java.sql.*"%>
<%@page import="com.bean.DBUtil4"%>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<title>Asset Category Management</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/Asset/css/addCategory.css">

</head>

<body>

<div class="container">

    <!-- PAGE TITLE -->

    <div class="page-title">
        Asset Category Management
    </div>

    <!-- SUCCESS / ERROR MESSAGES -->

    <%

    String msg = request.getParameter("msg");

    if("added".equals(msg)){
    %>

        <div class="success">
            Category Added Successfully
        </div>

    <%
    }

    else if("updated".equals(msg)){
    %>

        <div class="success">
            Category Updated Successfully
        </div>

    <%
    }

    else if("deleted".equals(msg)){
    %>

        <div class="success">
            Category Deleted Successfully
        </div>

    <%
    }

    else if("failed".equals(msg)
        || "updatefailed".equals(msg)
        || "deletefailed".equals(msg)
        || "error".equals(msg)){
    %>

        <div class="error">
            Something went wrong
        </div>

    <%
    }
    %>

    <!-- ADD CATEGORY FORM -->

    <form action="<%=request.getContextPath()%>/CategoryController"
          method="post">

        <input type="hidden"
               name="action"
               value="add">

        <div class="form-grid">

            <!-- CATEGORY -->

            <div class="form-group">

                <label>Category Name</label>

                <input type="text"
                       name="category_name"
                       placeholder="Enter Category Name"
                       required>

            </div>

            <!-- SUB CATEGORY -->

            <div class="form-group">

                <label>Subcategory Name</label>

                <input type="text"
                       name="subcategory_name"
                       placeholder="Enter Subcategory Name">

            </div>

        </div>

        <!-- DESCRIPTION -->

        <div class="form-group"
             style="margin-top:15px;">

            <label>Description</label>

            <textarea name="description"
                      placeholder="Enter Description"></textarea>

        </div>

        <!-- SAVE BUTTON -->

        <button type="submit"
                class="save-btn">

            Save Category

        </button>

    </form>

    <!-- TABLE TITLE -->

    <div class="table-title">

        Category List

    </div>

    <!-- TABLE -->

    <div class="table-wrapper">

        <table>

            <tr>

                <th>ID</th>
                <th>Category</th>
                <th>Subcategory</th>
                <th>Description</th>
                <th>Action</th>

            </tr>

            <%

            try{

                Connection con = DBUtil4.getConnection();

                String sql =
                        "SELECT * FROM asset_categories "
                      + "ORDER BY category_id DESC";

                PreparedStatement ps =
                        con.prepareStatement(sql);

                ResultSet rs = ps.executeQuery();

                while(rs.next()){

            %>

            <tr>

                <form action="<%=request.getContextPath()%>/CategoryController"
                      method="post">

                    <!-- ID -->

                    <td>

                        <%=rs.getInt("category_id")%>

                        <input type="hidden"
                               name="category_id"
                               value="<%=rs.getInt("category_id")%>">

                    </td>

                    <!-- CATEGORY -->

                    <td>

                        <input type="text"
                               name="category_name"
                               class="table-input"
                               value="<%=rs.getString("category_name")%>"
                               required>

                    </td>

                    <!-- SUBCATEGORY -->

                    <td>

                        <input type="text"
                               name="subcategory_name"
                               class="table-input"
                               value="<%=rs.getString("subcategory_name")%>">

                    </td>

                    <!-- DESCRIPTION -->

                    <td>

                        <input type="text"
                               name="description"
                               class="table-input"
                               value="<%=rs.getString("description")%>">

                    </td>

                    <!-- ACTION -->

                    <td>

                        <!-- UPDATE -->

                        <button type="submit"
                                name="action"
                                value="update"
                                class="action-btn update-btn">

                            Update

                        </button>

                        <!-- DELETE -->

                        <button type="submit"
                                name="action"
                                value="delete"
                                class="action-btn delete-btn"
                                onclick="return confirm('Delete this category?')">

                            Delete

                        </button>

                    </td>

                </form>

            </tr>

            <%
                }

            }catch(Exception e){

                e.printStackTrace();
            }
            %>

        </table>

    </div>

</div>

</body>
</html>