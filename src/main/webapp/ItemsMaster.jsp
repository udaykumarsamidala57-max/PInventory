<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="javax.servlet.http.HttpSession" %>
<%@ page import="com.bean.DBUtil" %>

<%
    // ---------------- SESSION & ROLE CHECK ----------------
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String role = (String) sess.getAttribute("role");
    String dept = (String) sess.getAttribute("department");
    if (!"admin".equalsIgnoreCase(role) && !"Global".equalsIgnoreCase(role) && !"Finance".equalsIgnoreCase(dept)) {
        out.println("<h3 style='color:red;text-align:center;'>Access Denied! You are not authorized.</h3>");
        return;
    }

    // ---------------- DATABASE CONFIG ----------------


    // ---------------- FETCH PARAMETERS ----------------
    String action = request.getParameter("action");
    String selectedCategory = request.getParameter("category");
    String message = "";

    // ---------------- CATEGORY & SUBCATEGORY LISTS ----------------
    List<String> categories = new ArrayList<>();
    List<String> subcategories = new ArrayList<>();

    try (Connection con = DBUtil.getConnection()) {

        // Load all active categories
        PreparedStatement psCat = con.prepareStatement("SELECT DISTINCT Category FROM category WHERE status='Active'");
        ResultSet rsCat = psCat.executeQuery();
        while (rsCat.next()) {
            categories.add(rsCat.getString("Category"));
        }
        rsCat.close();
        psCat.close();

        // If category selected, load subcategories
        if (selectedCategory != null && !selectedCategory.isEmpty()) {
            PreparedStatement psSub = con.prepareStatement("SELECT DISTINCT Sub_Category FROM category WHERE Category=? AND status='Active'");
            psSub.setString(1, selectedCategory);
            ResultSet rsSub = psSub.executeQuery();
            while (rsSub.next()) {
                subcategories.add(rsSub.getString("Sub_Category"));
            }
            rsSub.close();
            psSub.close();
        }

        // ---------------- SAVE ITEM (ON SUBMIT) ----------------
        if ("save".equalsIgnoreCase(action)) {
            String category = request.getParameter("category");
            String subCategory = request.getParameter("subcategory");
            String itemName = request.getParameter("itemName");
            String uom = request.getParameter("uom");
            String desc = request.getParameter("desc");
            String rem = request.getParameter("rem");

            if (category != null && subCategory != null && itemName != null && !itemName.trim().isEmpty()) {
                PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO item_master (Category, Sub_Category, Item_name, UOM, Desci, Remarks) VALUES (?, ?, ?, ?, ?, ?)"
                );
                ps.setString(1, category);
                ps.setString(2, subCategory);
                ps.setString(3, itemName.toUpperCase());
                ps.setString(4, uom);
                ps.setString(5, desc);
                ps.setString(6, rem);

                int rows = ps.executeUpdate();
                if (rows > 0) {
                    message = "Item saved successfully!";
                } else {
                    message = " Failed to save item.";
                }
                ps.close();
            } else {
                message = "⚠️ Please fill all required fields.";
            }
        }

    } catch (Exception e) {
        message = "⚠️ Error: " + e.getMessage();
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Items Master</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f4f6f9;
            margin: 0;
            padding: 0;
        }
        h2 {
            text-align: center;
            margin-top: 20px;
            color: #333;
        }
        .form-container {
            width: 500px;
            margin: 20px auto;
            background: #fff;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0px 4px 12px rgba(0,0,0,0.1);
        }
        label {
            display: block;
            font-weight: bold;
            margin: 10px 0 5px;
        }
        select, input[type="text"] {
            width: 100%;
            padding: 8px;
            border-radius: 6px;
            border: 1px solid #ccc;
            margin-bottom: 15px;
            font-size: 14px;
        }
        input[type="submit"] {
            width: 100%;
            padding: 10px;
            background: #007BFF;
            border: none;
            color: white;
            font-size: 16px;
            border-radius: 6px;
            cursor: pointer;
        }
        input[type="submit"]:hover {
            background: #0056b3;
        }
        .msg {
            text-align: center;
            color: green;
            font-weight: bold;
        }
    </style>
</head>
<body>
<jsp:include page="header.jsp" />
<h2>Items Master Form</h2>

<div class="msg"><%= message %></div>

<!-- Category Selection -->
<div class="form-container">
    <form method="get" action="ItemsMaster.jsp">
        <label>Category:</label>
        <select name="category" onchange="this.form.submit()">
            <option value="">--Select--</option>
            <%
                for (String cat : categories) {
                    String sel = (cat.equals(selectedCategory)) ? "selected" : "";
            %>
                <option value="<%=cat%>" <%=sel%>><%=cat%></option>
            <% } %>
        </select>
    </form>
</div>

<!-- Add Item Form -->
<div class="form-container">
    <form method="post" action="ItemsMaster.jsp">
        <input type="hidden" name="category" value="<%=selectedCategory != null ? selectedCategory : ""%>">
        <input type="hidden" name="action" value="save">

        <label>SubCategory:</label>
        <select name="subcategory" required>
            <option value="">--Select--</option>
            <% for (String sc : subcategories) { %>
                <option value="<%=sc%>"><%=sc%></option>
            <% } %>
        </select>

        <label>Item Name:</label>
        <input type="text" name="itemName" required>

        <label>UOM:</label>
        <select name="uom" required>
            <option value="">-- Select UOM --</option>
            <option value="Kg">Kg</option>
            <option value="Gram">Gram</option>
            <option value="Litre">Litre</option>
            <option value="Millilitre">Millilitre</option>
            <option value="Piece">Piece</option>
            <option value="Box">Box</option>
            <option value="Packet">Packet</option>
            <option value="Dozen">Dozen</option>
            <option value="Mtrs">Mtrs</option>
            <option value="Nos">Nos</option>
        </select>

        <label>Description:</label>
        <input type="text" name="desc">

        <label>Remarks:</label>
        <input type="text" name="rem">

        <input type="submit" value="Save Item">
    </form>
</div>

</body>
</html>
