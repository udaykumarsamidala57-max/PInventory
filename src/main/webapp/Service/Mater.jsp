<%@page import="java.util.*"%>

<%

ArrayList<HashMap<String,Object>> departments =
(ArrayList<HashMap<String,Object>>)request.getAttribute("departments");

ArrayList<HashMap<String,Object>> complaints =
(ArrayList<HashMap<String,Object>>)request.getAttribute("complaints");

%>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<title>Master Setup</title>

<style>

body{
    font-family:Arial;
    background:#f5f5f5;
    margin:0;
    padding:20px;
}

.container{
    width:95%;
    margin:auto;
}

.flex{
    display:flex;
    gap:20px;
    flex-wrap:wrap;
}

.box{
    width:48%;
}

.card{
    background:#fff;
    padding:20px;
    border-radius:8px;
    margin-bottom:20px;
    box-shadow:0px 0px 5px #ccc;
}

h2{
    margin-top:0;
}

input,
select,
button{

    width:100%;
    padding:10px;
    margin-top:10px;
    box-sizing:border-box;
}

button{

    background:#007bff;
    color:white;
    border:none;
    border-radius:5px;
    cursor:pointer;
}

table{

    width:100%;
    border-collapse:collapse;
    margin-top:15px;
}

table,
th,
td{

    border:1px solid #ccc;
}

th{

    background:#007bff;
    color:white;
}

th,
td{

    padding:10px;
    text-align:left;
}

</style>

</head>

<body>

<div class="container">

    <div class="flex">

        <!-- ========================= -->
        <!-- ADD DEPARTMENT -->
        <!-- ========================= -->

        <div class="card box">

            <h2>Create Department</h2>

            <form action="../MasterServlet" method="post">

                <input type="hidden"
                       name="action"
                       value="addDepartment">

                <input type="text"
                       name="department_name"
                       placeholder="Department Name"
                       required>

                <input type="number"
                       name="incharge_user_id"
                       placeholder="Incharge User ID"
                       required>

                <button type="submit">

                    Save Department

                </button>

            </form>

        </div>

        <!-- ========================= -->
        <!-- ADD COMPLAINT -->
        <!-- ========================= -->

        <div class="card box">

            <h2>Create Complaint Type</h2>

            <form action="../MasterServlet" method="post">

                <input type="hidden"
                       name="action"
                       value="addComplaintType">

                <select name="department_id" required>

                    <option value="">
                        Select Department
                    </option>

                    <%

                    for(HashMap<String,Object> dept : departments){

                    %>

                    <option value="<%=dept.get("id")%>">

                        <%=dept.get("department_name")%>

                    </option>

                    <%
                    }
                    %>

                </select>

                <input type="text"
                       name="complaint_name"
                       placeholder="Complaint Type"
                       required>

                <button type="submit">

                    Save Complaint Type

                </button>

            </form>

        </div>

    </div>

    <!-- ========================= -->
    <!-- DEPARTMENT TABLE -->
    <!-- ========================= -->

    <div class="card">

        <h2>Department List</h2>

        <table>

            <tr>

                <th>ID</th>
                <th>Department</th>
                <th>Incharge User ID</th>

            </tr>

            <%

            for(HashMap<String,Object> dept : departments){

            %>

            <tr>

                <td><%=dept.get("id")%></td>

                <td><%=dept.get("department_name")%></td>

                <td><%=dept.get("incharge_user_id")%></td>

            </tr>

            <%
            }
            %>

        </table>

    </div>

    <!-- ========================= -->
    <!-- COMPLAINT TABLE -->
    <!-- ========================= -->

    <div class="card">

        <h2>Complaint Type List</h2>

        <table>

            <tr>

                <th>ID</th>
                <th>Department</th>
                <th>Complaint Type</th>

            </tr>

            <%

            for(HashMap<String,Object> c : complaints){

            %>

            <tr>

                <td><%=c.get("id")%></td>

                <td><%=c.get("department_name")%></td>

                <td><%=c.get("complaint_name")%></td>

            </tr>

            <%
            }
            %>

        </table>

    </div>

</div>

</body>
</html>