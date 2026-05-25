<%@page import="java.util.*"%>

<%

ArrayList<HashMap<String,Object>> departments =
(ArrayList<HashMap<String,Object>>)request.getAttribute("departments");

ArrayList<HashMap<String,Object>> complaints =
(ArrayList<HashMap<String,Object>>)request.getAttribute("complaints");

ArrayList<HashMap<String,Object>> incharges =
(ArrayList<HashMap<String,Object>>)request.getAttribute("incharges");

%>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<title>MASTER SETUP</title>

<style>

body{
    margin:0;
    font-family:Segoe UI, sans-serif;
    background:#f4f6f9;
    color:#16325c;
    font-size:13px;
}

/* HEADER */

.header{
    background:#0176d3;
    color:white;
    padding:14px 24px;
    font-size:20px;
    font-weight:600;
}

/* CONTAINER */

.container{
    padding:20px;
}

/* GRID */

.grid{
    display:grid;
    grid-template-columns:1fr 1fr;
    gap:16px;
}

/* CARD */

.card{
    background:white;
    border-radius:8px;
    padding:20px;
    border:1px solid #d8dde6;
    box-shadow:0 1px 3px rgba(0,0,0,0.05);
}

.card h2{
    margin:0 0 16px;
    color:#16325c;
    font-size:17px;
    font-weight:600;
}

/* LABEL */

label{
    display:block;
    margin-bottom:5px;
    font-size:13px;
    font-weight:600;
    color:#444;
}

/* INPUTS */

input,
select,
textarea{
    width:100%;
    padding:10px 12px;
    margin-bottom:12px;
    border:1px solid #d8dde6;
    border-radius:5px;
    box-sizing:border-box;
    font-size:13px;
    background:white;
}

input:focus,
select:focus,
textarea:focus{
    outline:none;
    border-color:#0176d3;
    box-shadow:0 0 0 1px #0176d3;
}

/* BUTTON */

button{
    background:#0176d3;
    color:white;
    border:none;
    padding:10px 18px;
    border-radius:5px;
    cursor:pointer;
    font-size:13px;
    font-weight:600;
}

button:hover{
    background:#015fb2;
}

/* TABLE SECTION */

.table-card{
    margin-top:20px;
}

.table-wrapper{
    overflow-x:auto;
}

table{
    width:100%;
    border-collapse:collapse;
    background:white;
    border:1px solid #d8dde6;
}

th{
    background:#f3f3f3;
    color:#16325c;
    padding:10px;
    text-align:left;
    font-size:13px;
    font-weight:600;
    border-bottom:1px solid #d8dde6;
}

td{
    padding:10px;
    border-bottom:1px solid #ecebea;
    font-size:13px;
}

tr:hover{
    background:#f7fbff;
}

/* BADGE */

.badge{
    background:#e8f3ff;
    color:#0176d3;
    padding:4px 10px;
    border-radius:12px;
    font-size:11px;
    font-weight:600;
}

/* ACTION BUTTONS */

.btn-edit{
    background:#f4b942;
    color:white;
    padding:6px 12px;
    border-radius:4px;
    font-size:12px;
    text-decoration:none;
}

.btn-delete{
    background:#d9534f;
    color:white;
    padding:6px 12px;
    border-radius:4px;
    font-size:12px;
    text-decoration:none;
}

.btn-edit:hover{
    background:#e0a12f;
}

.btn-delete:hover{
    background:#c9302c;
}

/* RESPONSIVE */

@media(max-width:768px){

    .grid{
        grid-template-columns:1fr;
    }

    .container{
        padding:12px;
    }

    .card{
        padding:15px;
    }
}

</style>

</head>

<body>
<%@ include file="../header.jsp" %>


<div class="container">

    <div class="grid">

        <!-- ==================================== -->
        <!-- CREATE DEPARTMENT -->
        <!-- ==================================== -->

        <div class="card">

            <h2>CREATE DEPARTMENT</h2>

            <form action="<%=request.getContextPath()%>/MasterServlet"
                  method="post">

                <input type="hidden"
                       name="action"
                       value="addDepartment">

                <input type="text"
                       name="department_name"
                       placeholder="ENTER DEPARTMENT NAME"
                       required>

                <select name="incharge_id" required>

                    <option value="">
                        SELECT INCHARGE
                    </option>

                    <%

                    for(HashMap<String,Object> i : incharges){

                    %>

                    <option value="<%=i.get("id")%>">

                        <%=i.get("incharge_name")%>

                    </option>

                    <%
                    }
                    %>

                </select>

                <button type="submit">

                    SAVE DEPARTMENT

                </button>

            </form>

        </div>

        <!-- ==================================== -->
        <!-- CREATE COMPLAINT TYPE -->
        <!-- ==================================== -->

        <div class="card">

            <h2>CREATE COMPLAINT TYPE</h2>

            <form action="<%=request.getContextPath()%>/MasterServlet"
                  method="post">

                <input type="hidden"
                       name="action"
                       value="addComplaintType">

                <select name="department_id" required>

                    <option value="">
                        SELECT DEPARTMENT
                    </option>

                    <%

                    for(HashMap<String,Object> d : departments){

                    %>

                    <option value="<%=d.get("id")%>">

                        <%=d.get("department_name")%>

                    </option>

                    <%
                    }
                    %>

                </select>

                <input type="text"
                       name="complaint_name"
                       placeholder="ENTER COMPLAINT TYPE"
                       required>

                <button type="submit">

                    SAVE COMPLAINT TYPE

                </button>

            </form>

        </div>

    </div>

    <!-- ==================================== -->
    <!-- DEPARTMENT TABLE -->
    <!-- ==================================== -->

    <div class="card table-card">

        <h2>DEPARTMENTS</h2>

        <table>

            <tr>

                <th>ID</th>
                <th>DEPARTMENT</th>
                <th>INCHARGE</th>

            </tr>

            <%

            for(HashMap<String,Object> d : departments){

            %>

            <tr>

                <td><%=d.get("id")%></td>

                <td>

                    <span class="badge">

                        <%=d.get("department_name")%>

                    </span>

                </td>

                <td><%=d.get("incharge_name")%></td>

            </tr>

            <%
            }
            %>

        </table>

    </div>

    <!-- ==================================== -->
    <!-- COMPLAINT TYPES -->
    <!-- ==================================== -->

    <div class="card table-card">

        <h2>COMPLAINT TYPES</h2>

        <table>

            <tr>

                <th>ID</th>
                <th>DEPARTMENT</th>
                <th>COMPLAINT TYPE</th>

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