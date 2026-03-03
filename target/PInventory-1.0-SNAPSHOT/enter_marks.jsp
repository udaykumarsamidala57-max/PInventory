<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.bean.DBUtil3" %>
<%@ page import="javax.servlet.http.HttpSession" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String user = (String) sess.getAttribute("username");
    String dept = (String) sess.getAttribute("department");
    if (!"Academics".equalsIgnoreCase(dept) && !"Global".equalsIgnoreCase(dept)) {
        out.println("<h3 style='color:red;text-align:center;margin-top:30px;'>Access Denied! You are not authorized to view this page.</h3>");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
<title>Enter Exam Marks</title>

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">
<script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>

<style>
    * { box-sizing: border-box; font-family: 'Poppins', sans-serif; }
    body { margin: 0; background: linear-gradient(to right, #eef2f7, #f8fafc); }

    .container {
        max-width: 1800px;
        margin: 25px auto;
        background: #fff;
        padding: 25px 30px;
        border-radius: 14px;
        box-shadow: 0 8px 30px rgba(0,0,0,0.08);
    }

    .page-title { font-size: 22px; font-weight: 600; color: #2c3e50; margin-bottom: 20px; }

    .filter-bar { display: flex; gap: 20px; align-items: center; flex-wrap: wrap; margin-bottom: 20px; }
    label { font-weight: 500; color: #34495e; }

    select, input[type="date"] {
        padding: 8px 12px; border-radius: 6px; border: 1px solid #ccd6e0;
        background: #f8fafc; font-size: 14px;
    }

    .table-wrapper { overflow-x: auto; border-radius: 10px; margin-top: 10px; border: 1px solid #eee; }

    .marksTable { width: 100%; border-collapse: collapse; min-width: 900px; }
    .marksTable th { background: #0f2a4d; color: white; padding: 12px; font-weight: 500; position: sticky; top: 0; }
    .marksTable td { padding: 8px; border-bottom: 1px solid #e5e9f2; text-align: center; }

    .markInput { width: 65px; padding: 6px; border-radius: 5px; border: 1px solid #ccd6e0; text-align: center; }
    .markInput.changed, .remarksBox.changed { background: #fff3cd !important; border-color: #f39c12; }
    
    .totalBox, .percentBox { width: 85px; font-weight: 600; background: #ecf0f1; border: none; text-align: center; padding: 6px; border-radius: 4px; }
    .remarksBox { width: 220px; border-radius: 6px; border: 1px solid #ccd6e0; padding: 6px; }

    .btn-group { margin-top: 20px; display: flex; gap: 15px; }
    .action-btn {
        padding: 12px 28px; border-radius: 8px; border: none;
        color: white; font-size: 15px; font-weight: 500; cursor: pointer; transition: 0.2s;
        display: flex; align-items: center; gap: 8px;
    }
    .bg-blue { background: linear-gradient(45deg, #3498db, #2c80b4); }
    .bg-green { background: linear-gradient(45deg, #27ae60, #1e8449); }
    .action-btn:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
</style>

<script>
function exportToExcel() {
    const table = document.querySelector("#dataArea table");
    if (!table) { alert("Please load data first!"); return; }
    const ws_data = [];
    const rows = table.querySelectorAll("tr");
    rows.forEach((row) => {
        const rowData = [];
        const cells = row.querySelectorAll("th, td");
        cells.forEach((cell) => {
            const input = cell.querySelector("input");
            rowData.push(input ? input.value : cell.innerText.trim());
        });
        ws_data.push(rowData);
    });
    const wb = XLSX.utils.book_new();
    const ws = XLSX.utils.aoa_to_sheet(ws_data);
    XLSX.utils.book_append_sheet(wb, ws, "Marks");
    XLSX.writeFile(wb, "Marks_Report.xlsx");
}

function fixTable() {
    var table = document.querySelector("#dataArea table");
    if (!table) return;
    
    // Ensure <thead> exists
    if (!table.tHead) {
        var thead = document.createElement("thead");
        thead.appendChild(table.rows[0]);
        table.insertBefore(thead, table.firstChild);
    }

    var headerRow = table.tHead.rows[0];
    if (headerRow.cells[headerRow.cells.length - 1].innerText.trim() !== "Percentage") {
        var th = document.createElement("th"); th.innerText = "Percentage";
        headerRow.appendChild(th);
    }

    var rows = table.tBodies[0].rows;
    for (var i = 0; i < rows.length; i++) {
        if (!rows[i].querySelector(".percentBox")) {
            var td = document.createElement("td");
            td.innerHTML = '<input type="text" class="percentBox" readonly>';
            rows[i].appendChild(td);
        }
    }
}

function loadStudentsAndExams() {
    var classId = document.getElementById("class_id").value;
    var examDate = document.getElementById("exam_date").value;
    if(!classId || !examDate) return;
    document.getElementById("exam_date_hidden").value = examDate;
    
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "LoadStudentsAndExamsServlet?class_id=" + classId + "&exam_date=" + examDate, true);
    xhr.onload = function() {
        document.getElementById("dataArea").innerHTML = this.responseText;
        fixTable();
        hookChangeTracking();
        calculateAllRows();
    };
    xhr.send();
}

function hookChangeTracking() {
    var inputs = document.querySelectorAll(".markInput, .remarksBox");
    inputs.forEach(inp => {
        inp.setAttribute("data-old", inp.value);
        inp.addEventListener("input", function() {
            this.classList.toggle("changed", this.value !== this.getAttribute("data-old"));
            if(this.classList.contains("markInput")) calculateRow(this);
        });
    });
}

function calculateRow(input) {
    var row = input.closest("tr");
    var markInputs = row.querySelectorAll(".markInput");
    var total = 0, maxTotal = 0;
    var headers = document.querySelector("#dataArea table thead tr").cells;
    
    markInputs.forEach(inp => {
        total += parseFloat(inp.value) || 0;
        var headerText = headers[inp.parentElement.cellIndex].innerText;
        var match = headerText.match(/\((\d+)\)/);
        if(match) maxTotal += parseFloat(match[1]);
    });

    row.querySelector(".totalBox").value = total;
    if(maxTotal > 0) row.querySelector(".percentBox").value = ((total/maxTotal)*100).toFixed(2) + "%";
}

function calculateAllRows() {
    document.querySelectorAll(".markInput").forEach(calculateRow);
}

function beforeSubmit() {
    var changed = document.querySelectorAll(".changed");
    if (changed.length === 0) {
        alert("⚠️ No changes detected to save!");
        return false;
    }
    return true;
}
</script>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="container">
    <div class="page-title">📘 Exam Marks Entry</div>

    <form method="post" action="SaveMarksServlet" onsubmit="return beforeSubmit()">
        
        <div class="filter-bar">
            <div>
                <label>Exam Date</label><br>
                <input type="date" id="exam_date" onchange="loadStudentsAndExams()" value="<%= java.time.LocalDate.now() %>">
                <input type="hidden" name="exam_date_hidden" id="exam_date_hidden" value="<%= java.time.LocalDate.now() %>">
            </div>
            <div>
                <label>Class</label><br>
                <select name="class_id" id="class_id" onchange="loadStudentsAndExams()">
                    <option value="">-- Select Class --</option>
                    <%
                    try(Connection con = DBUtil3.getConnection(); Statement st = con.createStatement(); 
                        ResultSet rs = st.executeQuery("SELECT class_id, class_name FROM classes ORDER BY class_name")) {
                        while(rs.next()){
                    %>
                        <option value="<%=rs.getInt("class_id")%>"><%=rs.getString("class_name")%></option>
                    <% }} catch(Exception e) {} %>
                </select>
            </div>
        </div>

        <div class="table-wrapper">
            <div id="dataArea">
                <p style="padding:20px; color:#999; text-align:center;">Select Class and Date to load students...</p>
            </div>
        </div>

        <div class="btn-group">
            <button type="submit" class="action-btn bg-blue">💾 Save Marks</button>
            <button type="button" class="action-btn bg-green" onclick="exportToExcel()">📊 Download Excel</button>
        </div>

    </form>
    </div>

<% if("success".equals(request.getParameter("msg"))) { %>
    <script>alert("✅ Marks saved successfully!");</script>
<% } else if("error".equals(request.getParameter("msg"))) { %>
    <script>alert("❌ Error saving marks. Please check logs.");</script>
<% } %>

</body>
</html>