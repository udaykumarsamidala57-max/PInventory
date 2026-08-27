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
    padding:16px 32px;
    font-size:22px;
    font-weight:600;
    letter-spacing: 0.5px;
}

/* CONTAINER */

.container{
    max-width: 1400px;
    margin: 0 auto;
    padding: 32px 24px;
}

/* SECTION HEADER */
.section-title {
    font-size: 18px;
    font-weight: 600;
    color: #16325c;
    margin: 0 0 20px 0;
    padding-bottom: 8px;
    border-bottom: 2px solid #d8dde6;
}

/* GRID SETUP (FORMS) */

.form-grid{
    display:grid;
    grid-template-columns: 1fr 1fr;
    gap:24px;
    margin-bottom: 32px;
}

/* CARD */

.card{
    background:white;
    border-radius:8px;
    padding:24px;
    border:1px solid #d8dde6;
    box-shadow: 0 2px 4px rgba(0,0,0,0.04);
}

.card h2{
    margin:0 0 20px 0;
    color:#16325c;
    font-size:15px;
    font-weight:600;
    letter-spacing: 0.5px;
}

/* LABEL */

label{
    display:block;
    margin-bottom:6px;
    font-size:13px;
    font-weight:600;
    color:#444;
}

/* INPUTS */

input,
select,
textarea{
    width:100%;
    padding:11px 14px;
    margin-bottom:16px;
    border:1px solid #d8dde6;
    border-radius:6px;
    box-sizing:border-box;
    font-size:13px;
    background:white;
    transition: all 0.2s ease;
}

input:focus,
select:focus,
textarea:focus{
    outline:none;
    border-color:#0176d3;
    box-shadow:0 0 0 3px rgba(1, 118, 211, 0.15);
}

/* BUTTON */

button{
    background:#0176d3;
    color:white;
    border:none;
    padding:12px 24px;
    border-radius:6px;
    cursor:pointer;
    font-size:13px;
    font-weight:600;
    transition: background 0.2s;
}

button:hover{
    background:#015fb2;
}

/* TABLE SECTION (OCCUPIES FULL WIDTH COMFORTABLY) */

.table-card{
    margin-top:32px;
    width: 100%;
    box-sizing: border-box;
}

.table-wrapper{
    overflow-x:auto;
    border-radius: 6px;
    border: 1px solid #d8dde6;
    margin-bottom: 16px;
}

table{
    width:100%;
    border-collapse:collapse;
    background:white;
}

th{
    background:#f8f9fa;
    color:#16325c;
    padding:14px 18px;
    text-align:left;
    font-size:13px;
    font-weight:600;
    border-bottom:2px solid #d8dde6;
}

td{
    padding:14px 18px;
    border-bottom:1px solid #ecebea;
    font-size:13px;
    color: #333;
}

tr:last-child td {
    border-bottom: none;
}

tr:hover{
    background:#f7fbff;
}

/* BADGE */

.badge{
    background:#e8f3ff;
    color:#0176d3;
    padding:6px 12px;
    border-radius:14px;
    font-size:12px;
    font-weight:600;
    display: inline-block;
}

/* GROUP SEPARATOR DESIGN */
.dept-group-title {
    margin: 28px 0 12px 0;
    color: #0176d3;
    font-size: 15px;
    font-weight: 600;
    letter-spacing: 0.5px;
    padding-left: 4px;
    border-left: 4px solid #0176d3;
}

/* RESPONSIVE */

@media(max-width:992px){
    .form-grid{
        grid-template-columns: 1fr;
    }
    
    .container{
        padding: 16px;
    }
}

</style>

</head>

<body>
<%@ include file="../header.jsp" %>


<div class="container">

    <h1 class="section-title">DEPARTMENT, INCHARGE AND COMPLAINT TYPE CONFIGURATION</h1>
    
    <div class="form-grid">

        <div class="card">

            <h2>CREATE DEPARTMENT</h2>

            <form action="<%=request.getContextPath()%>/MasterServlet"
                  method="post">

                <input type="hidden"
                       name="action"
                       value="addDepartment">

                <label>Department Name</label>
                <input type="text"
                       name="department_name"
                       placeholder="e.g. IT DEPARTMENT"
                       required>

                <label>Assigned Incharge</label>
                <select name="incharge_id" required>

                    <option value="">
                        SELECT INCHARGE
                    </option>

                    <%
                    if(incharges != null) {
                        for(HashMap<String,Object> i : incharges){
                    %>
                    <option value="<%=i.get("id")%>">
                        <%=i.get("incharge_name")%>
                    </option>
                    <%
                        }
                    }
                    %>

                </select>

                <button type="submit">
                    SAVE DEPARTMENT
                </button>

            </form>

        </div>

        <div class="card">

            <h2>CREATE COMPLAINT TYPE</h2>

            <form action="<%=request.getContextPath()%>/MasterServlet"
                  method="post">

                <input type="hidden"
                       name="action"
                       value="addComplaintType">

                <label>Target Department</label>
                <select name="department_id" required>

                    <option value="">
                        SELECT DEPARTMENT
                    </option>

                    <%
                    if(departments != null) {
                        for(HashMap<String,Object> d : departments){
                    %>
                    <option value="<%=d.get("id")%>">
                        <%=d.get("department_name")%>
                    </option>
                    <%
                        }
                    }
                    %>

                </select>

                <label>Complaint Classification Name</label>
                <input type="text"
                       name="complaint_name"
                       placeholder="e.g. Hardware Malfunction"
                       required>

                <button type="submit">
                    SAVE COMPLAINT TYPE
                </button>

            </form>

        </div>

    </div>

    <h1 class="section-title" style="margin-top: 40px;">REGISTERED RECORDS</h1>

    <div class="card table-card">

        <h2>DEPARTMENTS OVERVIEW</h2>

        <div class="table-wrapper">
            <table>

                <tr>
                    <th style="width: 10%;">SYSTEM ID</th>
                    <th style="width: 50%;">DEPARTMENT LOGICAL NAME</th>
                    <th style="width: 40%;">HEAD INCHARGE ASSIGNED</th>
                </tr>

                <%
                if(departments != null && !departments.isEmpty()) {
                    for(HashMap<String,Object> d : departments){
                %>
                <tr>
                    <td><strong>#<%=d.get("id")%></strong></td>
                    <td>
                        <span class="badge">
                            <%=d.get("department_name")%>
                        </span>
                    </td>
                    <td><%=d.get("incharge_name")%></td>
                </tr>
                <%
                    }
                } else {
                %>
                <tr>
                    <td colspan="3" style="text-align: center; color: #777; padding: 24px;">No department registries allocated yet.</td>
                </tr>
                <%
                }
                %>

            </table>
        </div>

    </div>

    <div class="card table-card">

        <h2>COMPLAINT CLASSIFICATIONS</h2>

        <% 
        if (complaints != null && !complaints.isEmpty()) {
            String currentDept = null; 
            boolean isTableOpen = false;

            for(HashMap<String,Object> c : complaints){
                String deptName = (String) c.get("department_name");
                
                if(deptName != null && !deptName.equals(currentDept)) { 
                    if(isTableOpen) { 
                        %>
                        </table></div>
                        <% 
                    }
                    currentDept = deptName;
                    isTableOpen = true;
        %>
                    <div class="dept-group-title">
                        <%= currentDept.toUpperCase() %>
                    </div>
                    
                    <div class="table-wrapper">
                    <table>
                        <tr>
                            <th style="width: 15%;">COMPLAINT ID</th>
                            <th>REGISTERED COMPLAINT TYPE</th>
                        </tr>
        <% 
                } 
        %>
                        <tr>
                            <td><strong>#<%=c.get("id")%></strong></td>
                            <td><%=c.get("complaint_name")%></td>
                        </tr>
        <% 
            } 
            
            if(isTableOpen) { 
                %>
                </table></div>
                <% 
            }
        } else {
        %>
            <div style="border: 1px dashed #d8dde6; border-radius: 6px; padding: 32px; text-align: center; color: #666; margin-top: 15px;">
                <p style="margin: 0; font-style: italic; font-size: 14px;">No configured complaint parameters detected.</p>
            </div>
        <%
        }
        %>

    </div>

</div>

</body>
</html>