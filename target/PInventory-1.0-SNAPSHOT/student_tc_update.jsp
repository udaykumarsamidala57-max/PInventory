<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil3" %>
<!DOCTYPE html>
<html>
<head>
<title>Student TC Status Management</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<style>
*{ box-sizing:border-box; font-family:Inter,Segoe UI,Arial; }

body{
    margin:0;
    min-height:100vh;
    background:
        radial-gradient(circle at 10% 10%, #dbeafe 0%, transparent 40%),
        radial-gradient(circle at 90% 20%, #fef3c7 0%, transparent 40%),
        linear-gradient(135deg,#eef2ff,#f8fafc);
}

.app{ display:flex; flex-direction:column; height:100vh; }


.toolbar{
    position:sticky; top:0; z-index:1000;
    background: linear-gradient(135deg,#1e3a8a,#4338ca);
    padding:14px 22px;
    display:flex; flex-wrap:wrap;
    justify-content:space-between; align-items:center;
    gap:10px;
    box-shadow:0 10px 30px rgba(0,0,0,0.25);
    color:white;
}
.toolbar h2{ margin:0; font-size:20px; font-weight:700; }

.btn{
    border:none; padding:8px 14px; border-radius:10px;
    cursor:pointer; font-weight:600; font-size:13px;
    color:white;
    background: linear-gradient(135deg,#2563eb,#1d4ed8);
}
.btn.red{ background:linear-gradient(135deg,#ef4444,#dc2626); }
.btn.green{ background:linear-gradient(135deg,#22c55e,#16a34a); }


.filters{
    margin:12px;
    padding:12px;
    display:flex; gap:10px; flex-wrap:wrap;
    background:white;
    border-radius:14px;
    box-shadow:0 6px 16px rgba(0,0,0,0.12);
}
.filters input, .filters select{
    padding:8px 12px;
    border-radius:10px;
    border:1px solid #c7d2fe;
    font-size:14px;
}


.table-wrap{ flex:1; overflow:auto; padding:0 12px 12px 12px; }

table{
    width:100%;
    min-width:900px;
    border-collapse:separate;
    border-spacing:0;
    background:white;
    border-radius:16px;
    overflow:hidden;
    box-shadow:0 10px 25px rgba(0,0,0,0.12);
}

thead th{
    position:sticky;
    top:0;
    background: #0f2a4d;
    color:white;
    z-index:100;
    font-weight:700;
}

th,td{
    padding:10px;
    border-bottom:1px solid #e5e7eb;
    text-align:center;
    font-size:13.5px;
    white-space:nowrap;
}

tr:nth-child(even){ background:#f8fafc; }
tr:hover{ background:#eef2ff; }


.badge-tc{
    background:#fee2e2; color:#7f1d1d;
    padding:5px 12px; border-radius:20px; font-weight:700;
}


select{
    padding:6px 10px;
    border-radius:8px;
    border:1px solid #c7d2fe;
    font-weight:600;
}

/* Mobile */
@media(max-width:768px){
    .toolbar h2{ font-size:16px; }
    .btn{ font-size:12px; padding:7px 10px; }
}
</style>

<script>
function updateTCStatus(sno, newStatus) {

    let url = "<%=request.getContextPath()%>/UpdateTCStatusServlet";

    let xhr = new XMLHttpRequest();
    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function () {
        if (xhr.readyState == 4 && xhr.status == 200) {

            let res = xhr.responseText.trim();

            if(res === "SUCCESS"){
                alert("TC Status Updated Successfully");
                location.reload();
            }
            else if(res === "SESSION_EXPIRED"){
                alert("Session expired. Please login again.");
                window.location.href = "login.jsp";
            }
            else if(res === "ACCESS_DENIED"){
                alert("You don't have permission.");
            }
            else{
                alert("Server Response: " + res);
            }
        }
    };

    xhr.send("sno=" + encodeURIComponent(sno) + "&tcstatus=" + encodeURIComponent(newStatus));
}


function applyFilters(){
    let search = document.getElementById("searchBox").value.toLowerCase();
    let cls = document.getElementById("classFilter").value.toLowerCase();

    let rows = document.querySelectorAll("#studentTable tbody tr");

    rows.forEach(r=>{
        let text = r.innerText.toLowerCase();
        let classCell = r.querySelector(".cls").innerText.toLowerCase();

        let ok = true;

        if(search !== "" && !text.includes(search)) ok = false;
        if(cls !== "" && classCell !== cls) ok = false;

        r.style.display = ok ? "" : "none";
    });
}


function downloadExcel(){
    let table = document.getElementById("studentTable");
    let rows = table.querySelectorAll("tr");

    let csv = [];

    rows.forEach(row=>{
        if(row.style.display === "none") return;

        let cols = row.querySelectorAll("th, td");
        let rowData = [];

        cols.forEach(col=>{
            let text = col.innerText.replace(/"/g, '""');
            rowData.push('"' + text + '"');
        });

        csv.push(rowData.join(","));
    });

    let csvFile = new Blob([csv.join("\n")], { type: "text/csv" });
    let downloadLink = document.createElement("a");

    downloadLink.download = "TC_Student_List.csv";
    downloadLink.href = window.URL.createObjectURL(csvFile);
    downloadLink.style.display = "none";

    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
}
</script>

</head>
<body>

<%@ include file="header.jsp" %>


<div class="filters">
    <input type="text" id="searchBox" placeholder="🔍 Search Name / Admission / Mobile..." onkeyup="applyFilters()">

    <select id="classFilter" onchange="applyFilters()">
        <option value="">All Classes</option>
        <%
            Connection con1=null; PreparedStatement ps1=null; ResultSet rs1=null;
            try{
                con1 = DBUtil3.getConnection();
                ps1 = con1.prepareStatement("SELECT DISTINCT class FROM student_master ORDER BY class");
                rs1 = ps1.executeQuery();
                while(rs1.next()){
        %>
            <option value="<%=rs1.getString(1)%>"><%=rs1.getString(1)%></option>
        <%
                }
            }catch(Exception e){}
            finally{
                try{ if(rs1!=null) rs1.close(); }catch(Exception e){}
                try{ if(ps1!=null) ps1.close(); }catch(Exception e){}
                try{ if(con1!=null) con1.close(); }catch(Exception e){}
            }
        %>
    </select>

  
    <button class="btn green" onclick="downloadExcel()">⬇ Export Excel</button>
</div>


<div class="table-wrap">
<table id="studentTable">
<thead>
<tr>
    <th>SNo</th>
    <th>Admission No</th>
    <th>Name</th>
    <th>Class</th>
    <th>Section</th>
    <th>Category</th>
    <th>Father Name</th>
    <th>Mobile</th>
    <th>TC Status</th>
</tr>
</thead>
<tbody>

<%
    Connection con=null; PreparedStatement ps=null; ResultSet rs=null;
    try {
        con = DBUtil3.getConnection();
        ps = con.prepareStatement("SELECT * FROM student_master");
        rs = ps.executeQuery();

        while(rs.next()) {
            String status = rs.getString("TC_Status");
            boolean showDropdown = (status == null || status.trim().equals("") || "Active".equalsIgnoreCase(status));
%>
<tr>
    <td><%= rs.getInt("sno") %></td>
    <td><%= rs.getString("admission_no") %></td>
    <td><%= rs.getString("student_name") %></td>
    <td class="cls"><%= rs.getString("class") %></td>
    <td><%= rs.getString("section") %></td>
    <td><%= rs.getString("category") %></td>
    <td><%= rs.getString("father_name") %></td>
    <td><%= rs.getString("father_mobile_no") %></td>
    <td>

    <% if(showDropdown) { %>
        <select onchange="updateTCStatus(<%=rs.getInt("sno")%>, this.value)">
            <option value="Active" <%= (status==null || status.trim().equals("") || "Active".equalsIgnoreCase(status))?"selected":"" %>>Active</option>
            <option value="TC Applied">TC Applied</option>
            <option value="Passed Out">Passed Out</option>
        </select>
    <% } else { %>
        <span class="badge-tc"><%= status %></span>
    <% } %>

    </td>
</tr>
<%
        }
    } catch(Exception e) {
        out.println("<tr><td colspan='9' style='color:red;'>Error: "+e.getMessage()+"</td></tr>");
    } finally {
        try { if(rs != null) rs.close(); } catch(Exception e) {}
        try { if(ps != null) ps.close(); } catch(Exception e) {}
        try { if(con != null) con.close(); } catch(Exception e) {}
    }
%>

</tbody>
</table>
</div>

</body>
</html>
