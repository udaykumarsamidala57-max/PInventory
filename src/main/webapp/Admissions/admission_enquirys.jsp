<%@ page import="javax.sql.rowset.CachedRowSet" %>
<%@ page import="javax.servlet.http.HttpSession" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.regex.*" %>
<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<!DOCTYPE html>

<%
   HttpSession sess = request.getSession(false);
   if (sess == null || sess.getAttribute("username") == null) {
      response.sendRedirect("login.jsp");
       return;
   }

   String role = (String) sess.getAttribute("role");
   String User = (String) sess.getAttribute("username");

   CachedRowSet rs = (CachedRowSet)request.getAttribute("list");
   List<Map<String, Object>> dataList = new ArrayList<>();
   
   if (rs != null) {
       rs.beforeFirst();
       java.sql.ResultSetMetaData metaData = rs.getMetaData();
       int columnCount = metaData.getColumnCount();
       while (rs.next()) {
           Map<String, Object> row = new HashMap<>();
           for (int i = 1; i <= columnCount; i++) {
               row.put(metaData.getColumnName(i), rs.getObject(i));
           }
           dataList.add(row);
       }

       Collections.sort(dataList, new Comparator<Map<String, Object>>() {
           @Override
           public int compare(Map<String, Object> m1, Map<String, Object> m2) {
               Object obj1 = m1.get("application_no");
               Object obj2 = m2.get("application_no");
               
               String s1 = (obj1 == null) ? "" : obj1.toString().trim();
               String s2 = (obj2 == null) ? "" : obj2.toString().trim();
               
               if (s1.isEmpty() && !s2.isEmpty()) return 1;
               if (!s1.isEmpty() && s2.isEmpty()) return -1;
               if (s1.isEmpty() && s2.isEmpty()) return 0;

               // Natural Sort Logic: Character then Number
               return compareNatural(s1, s2);
           }

           private int compareNatural(String s1, String s2) {
               Pattern p = Pattern.compile("(\\d+)|(\\D+)");
               Matcher m1 = p.matcher(s1);
               Matcher m2 = p.matcher(s2);

               while (m1.find() && m2.find()) {
                   String part1 = m1.group();
                   String part2 = m2.group();
                   int result;

                   if (Character.isDigit(part1.charAt(0)) && Character.isDigit(part2.charAt(0))) {
                       long n1 = Long.parseLong(part1);
                       long n2 = Long.parseLong(part2);
                       result = Long.compare(n1, n2);
                   } else {
                       result = part1.compareToIgnoreCase(part2);
                   }

                   if (result != 0) return result;
               }
               return s1.length() - s2.length();
           }
       });
   }
%>

<html>
<head>
<title>Admission Enquiry Register</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">

<style>
*{ box-sizing: border-box; font-family: Inter, Segoe UI, Arial, sans-serif; }
body{ margin: 0; height: 100vh; display: flex; flex-direction: column; background: radial-gradient(circle at 10% 10%, #dbeafe 0%, transparent 40%), radial-gradient(circle at 90% 20%, #fef3c7 0%, transparent 40%), linear-gradient(135deg,#eef2ff,#f8fafc); overflow: hidden; }
.summary-bar{ display: flex; gap: 14px; flex-wrap: wrap; width: 100%; margin: 14px; }
.summary-card{ flex: 1; min-width: 170px; padding: 14px 18px; border-radius: 16px; color: #ffffff; box-shadow: 0 10px 24px rgba(0,0,0,0.18); transition: 0.25s ease; }
.summary-card:hover{ transform: translateY(-4px) scale(1.03); }
.summary-title{ font-size: 13px; font-weight: 600; opacity: 0.9; }
.summary-value{ font-size: 28px; font-weight: 800; margin-top: 6px; }
.sum-total{ background: linear-gradient(135deg,#2563eb,#1e40af); }
.sum-visible{ background: linear-gradient(135deg,#0ea5e9,#0369a1); }
.sum-day{ background: linear-gradient(135deg,#22c55e,#15803d); }
.btn{ border: none; padding: 10px 18px; border-radius: 14px; cursor: pointer; font-size: 14px; font-weight: 600; color: #ffffff; transition: 0.25s ease; box-shadow: 0 6px 16px rgba(0,0,0,0.25); }
.btn:hover{ transform: translateY(-2px); }
.btn.green{ background: linear-gradient(135deg,#22c55e,#15803d); }
.btn.red{ background: linear-gradient(135deg,#ef4444,#b91c1c); }
.btn.blue{ background: linear-gradient(135deg,#2563eb,#1e40af); }
.btn.gray{ background: linear-gradient(135deg,#64748b,#475569); }
.filters{ margin: 14px; padding: 14px 16px; display: flex; gap: 12px; flex-wrap: wrap; background: rgba(255,255,255,0.9); backdrop-filter: blur(10px); border-radius: 18px; box-shadow: 0 10px 24px rgba(0,0,0,0.12); flex-shrink: 0; }
.filters input, .filters select{ padding: 9px 12px; border-radius: 12px; border: 1px solid #c7d2fe; font-size: 14px; outline: none; }
.filters input:focus, .filters select:focus{ border-color: #4338ca; box-shadow: 0 0 6px rgba(67,56,202,0.4); }
.table-wrap{ padding: 0 14px 14px 14px; overflow: auto; flex-grow: 1; }
table{ width: 100%; border-collapse: separate; border-spacing: 0; background: #ffffff; font-size: 14px; }
table thead th{ position: sticky; top: 0; background: #0f2a4d; color: #ffffff; padding: 12px 10px; font-weight: 700; border: 1px solid #0b1f3a; text-align: left; white-space: nowrap; z-index: 10; }
table tbody td{ padding: 8px 10px; border: 1px solid #000000; color: #000000; vertical-align: middle; }
table tbody td:first-child{ text-align: center; width: 60px; }
table tbody td:nth-child(2), table tbody td:nth-child(5){ font-weight: 600; }
table tbody tr:hover{ background: #f1f5f9; }
.badge-day{ background: #dcfce7; color: #166534; padding: 4px 12px; border-radius: 20px; font-weight: 700; }
.badge-res{ background: #fee2e2; color: #7f1d1d; padding: 4px 12px; border-radius: 20px; font-weight: 700; }
.modal-overlay{ position: fixed; inset: 0; background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; z-index: 9999; }
.modal-box{ background: #ffffff; padding: 24px; border-radius: 20px; width: 700px; max-width: 95%; box-shadow: 0 24px 60px rgba(0,0,0,0.45); animation: pop 0.25s ease; }
@keyframes pop{ from{ transform: scale(0.85); opacity: 0; } to{ transform: scale(1); opacity: 1; } }
.modal-header{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.close-btn{ background: #ef4444; color: #ffffff; border: none; padding: 6px 14px; border-radius: 10px; cursor: pointer; }
.form-grid{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
.form-grid div{ display: flex; flex-direction: column; }
.form-grid label{ font-size: 13px; font-weight: 600; margin-bottom: 4px; color: #1e293b; }
.form-grid input{ padding: 9px 12px; border-radius: 12px; border: 1px solid #c7d2fe; font-size: 14px; outline: none; transition: 0.2s ease; }
.form-grid input:focus{ border-color: #4338ca; box-shadow: 0 0 6px rgba(67,56,202,0.4); }
.empty-app-row { background-color: #fff9db !important; }
@media(max-width: 900px){ .form-grid{ grid-template-columns: 1fr 1fr; } }
@media(max-width: 600px){ .form-grid{ grid-template-columns: 1fr; } }
</style>

<script>
function calculateAges() {
    let cells = document.querySelectorAll(".age-cell");
    let asOnDate = new Date(2026, 4, 31);
    asOnDate.setHours(0,0,0,0);
    cells.forEach(cell => {
        let dob = cell.dataset.dob;
        if (!dob || dob === "null") return;
        let birth = new Date(dob);
        birth.setHours(0,0,0,0);
        let y = 0, m = 0;
        let temp = new Date(birth);
        while (true) { let next = new Date(temp); next.setFullYear(next.getFullYear() + 1); if (next <= asOnDate) { y++; temp = next; } else break; }
        while (true) { let next = new Date(temp); next.setMonth(next.getMonth() + 1); if (next <= asOnDate) { m++; temp = next; } else break; }
        let d = Math.floor((asOnDate - temp) / (1000 * 60 * 60 * 24));
        cell.innerText = y + "Y " + m + "M " + d + "D";
    });
}

function applyFilters(){
    let search = document.getElementById("filterSearch").value.toLowerCase();
    let cls = document.getElementById("filterClass").value.toLowerCase();
    let type = document.getElementById("filterType").value.toLowerCase();
    let rows = document.querySelectorAll(".data-row");
    let total = 0, visible = 0, day = 0, res = 0;
    rows.forEach(row=>{
        total++;
        let text = row.innerText.toLowerCase();
        let classCol = row.children[5].innerText.toLowerCase();
        let typeCol = row.children[6].innerText.toLowerCase();
        let show = true;
        if(search && !text.includes(search)) show = false;
        if(cls && classCol !== cls) show = false;
        if(type && !typeCol.includes(type)) show = false;
        if(show){ row.style.display=""; visible++; if(typeCol.includes("day")) day++; else res++; } else { row.style.display="none"; }
    });
    document.getElementById("countTotal").innerText = total;
    document.getElementById("countVisible").innerText = visible;
    document.getElementById("countDay").innerText = day;
    document.getElementById("countRes").innerText = res;
}

function downloadExcel() {
    const table = document.getElementById('enquiryTable');
    let csv = [];
    const rows = table.querySelectorAll('tr');
    rows.forEach(row => {
        let cols = row.querySelectorAll('th, td');
        let rowData = [];
        cols.forEach(cell => { let text = cell.innerText.replace(/\n/g, ' ').replace(/"/g, '""').trim(); rowData.push('"' + text + '"'); });
        csv.push(rowData.join(','));
    });
    const blob = new Blob([csv.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'enquiryTable.csv';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}

function printHallTicket(appNo, id){
    let safeAppNo = (appNo && appNo !== "null") ? appNo.trim() : "";
    let url = "HallTicket.jsp?enquiry_id=" + id + "&application_no=" + encodeURIComponent(safeAppNo);
    window.open(url, "_blank");
}

function openEditModal(id){ document.getElementById("editModal"+id).style.display="flex"; }
function closeEditModal(id){ document.getElementById("editModal"+id).style.display="none"; }

function saveEditForm(id){
    let form = document.getElementById("editForm"+id);
    let formData = new FormData(form);
    let params = new URLSearchParams(formData);
    fetch("admission", { method: "POST", body: params, headers: { 'Content-Type': 'application/x-www-form-urlencoded' } })
    .then(r => r.text()).then(res => { if(res.trim() === "OK") { alert("Updated successfully!"); location.reload(); } else { alert("Error: " + res); } })
    .catch(e => console.error("Error:", e));
    return false;
}

function deleteRecord(id){
    if(!confirm("Delete this record?")) return;
    fetch("admission?action=delete&id="+id).then(r=>r.text()).then(res=>{ document.getElementById("row"+id).remove(); applyFilters(); alert("Deleted successfully!"); });
}

function approveRecord(id){
    fetch("admission?action=approve&id="+id).then(r=>r.text()).then(res=>{ document.getElementById("approveCell"+id).innerHTML = '<span style="color:#15803d;font-weight:900;">Approved</span>'; alert("Approved successfully!"); });
}

window.onload = function(){ calculateAges(); applyFilters(); }
</script>
</head>

<body>
<jsp:include page="common_header.jsp" />

<div class="filters">
    <b>Total:</b> <span id="countTotal">0</span>
    <b>Visible:</b> <span id="countVisible">0</span>
    <b>Dayscholar:</b> <span id="countDay">0</span>
    <b>Residential:</b> <span id="countRes">0</span>
    <input type="text" id="filterSearch" placeholder="Search..." onkeyup="applyFilters()">
    <select id="filterClass" onchange="applyFilters()">
        <option value="">All Classes</option>
        <option>Nursery</option><option>LKG</option><option>UKG</option>
        <option>Class 1</option><option>Class 2</option><option>Class 3</option>
        <option>Class 4</option><option>Class 5</option><option>Class 6</option>
        <option>Class 7</option><option>Class 8</option><option>Class 9</option>
    </select>
    <select id="filterType" onchange="applyFilters()">
        <option value="">All Types</option>
        <option>Dayscholar</option><option>Residential</option>
    </select>
    <button class="btn blue" onclick="downloadExcel()"> Export Excel</button>
</div>

<div class="table-wrap">
<table id="enquiryTable">
<thead>
    <tr>
    <th>ID</th><th>Student</th><th>Gender</th><th>DOB</th><th>Age</th>
    <th>Class</th><th>Type</th><th>Father</th><th>F Occ</th><th>F Org</th>
    <th>F Mobile</th><th>Mother</th><th>M Occ</th><th>M Org</th>
    <th>M Mobile</th><th>Place</th><th>Segment</th><th>Exam Date</th><th>App No</th><th>Edit</th><th>Print</th><th>Approve</th>
    </tr>
</thead>
<tbody>
<%
if(dataList != null){
    for(Map<String, Object> rowMap : dataList){
        int id = (Integer)rowMap.get("enquiry_id");
        String appNo = (String)rowMap.get("application_no");
        String dob = String.valueOf(rowMap.get("date_of_birth"));
        String type = String.valueOf(rowMap.get("admission_type"));
        boolean isNoApp = (appNo == null || appNo.trim().isEmpty());
%>
<tr class="data-row <%= isNoApp ? "empty-app-row" : "" %>" id="row<%=id%>">
    <td><%=id%></td>
    <td><%=rowMap.get("student_name")%></td>
    <td><%=rowMap.get("gender")%></td>
    <td><%=dob%></td>
    <td class="age-cell" data-dob="<%=dob%>"></td>
    <td><%=rowMap.get("class_of_admission")%></td>
    <td>
        <% if(type.toLowerCase().contains("day")){ %>
        <span class="badge-day">Dayscholar</span>
        <% } else { %>
        <span class="badge-res">Residential</span>
        <% } %>
    </td>
    <td><%=rowMap.get("father_name")%></td>
    <td><%=rowMap.get("father_occupation")%></td>
    <td><%=rowMap.get("father_organization")%></td>
    <td><%=rowMap.get("father_mobile_no")%></td>
    <td><%=rowMap.get("mother_name")%></td>
    <td><%=rowMap.get("mother_occupation")%></td>
    <td><%=rowMap.get("mother_organization")%></td>
    <td><%=rowMap.get("mother_mobile_no")%></td>
    <td><%=rowMap.get("place_from")%></td>
    <td><%=rowMap.get("segment")%></td>
    <td><%=rowMap.get("exam_date")%></td>
    <td><%= isNoApp ? "<b style='color:red;'>Not Attended</b>" : appNo %></td>
    <td>
        <button class="btn blue" onclick="openEditModal(<%=id%>)">Edit</button>
        <% if("Global".equalsIgnoreCase(role)){ %>
        <button class="btn red" onclick="deleteRecord(<%=id%>)">Delete</button>
        <% } %>
    </td>
   <td>
   <button class="btn gray" onclick="printHallTicket('<%=appNo%>', <%=id%>)">Print</button>
   </td>
    <td id="approveCell<%=id%>">
        <% if("Global".equalsIgnoreCase(role)){
            String approved = (String)rowMap.get("approved");
            if(approved==null || !"Approved".equalsIgnoreCase(approved)){ %>
            <button onclick="approveRecord(<%=id%>)" class="btn gray">Approve</button>
        <% } else { %>
            <span style="color:#15803d;font-weight:900;">Approved</span>
        <% } } %>
    </td>
</tr>
<% } } %>
</tbody>
</table>
</div>

<%
if(dataList != null){
    for(Map<String, Object> rowMap : dataList){
        int id = (Integer)rowMap.get("enquiry_id");
%>
<div id="editModal<%=id%>" class="modal-overlay" style="display:none;">
<div class="modal-box">
    <div class="modal-header">
        <h3>Edit Enquiry #<%=id%></h3>
        <button class="close-btn" onclick="closeEditModal(<%=id%>)">Close</button>
    </div>
    <form id="editForm<%=id%>" method="post" onsubmit="return saveEditForm(<%=id%>)">
        <input type="hidden" name="action" value="update">
        <input type="hidden" name="enquiry_id" value="<%=id%>">
        <div class="form-grid">
            <div><label>Student Name</label><input type="text" name="student_name" value="<%=rowMap.get("student_name")%>"></div>
            <div><label>Gender</label><input type="text" name="gender" value="<%=rowMap.get("gender")%>"></div>
            <div><label>Date of Birth</label><input type="date" name="date_of_birth" value="<%=rowMap.get("date_of_birth")%>"></div>
            <div><label>Class</label><input type="text" name="class_of_admission" value="<%=rowMap.get("class_of_admission")%>"></div>
            <div><label>Admission Type</label><input type="text" name="admission_type" value="<%=rowMap.get("admission_type")%>"></div>
            <div><label>Father Name</label><input type="text" name="father_name" value="<%=rowMap.get("father_name")%>"></div>
            <div><label>Father Occupation</label><input type="text" name="father_occupation" value="<%=rowMap.get("father_occupation")%>"></div>
            <div><label>Father Organization</label><input type="text" name="father_organization" value="<%=rowMap.get("father_organization")%>"></div>
            <div><label>Father Mobile</label><input type="text" name="father_mobile_no" value="<%=rowMap.get("father_mobile_no")%>"></div>
            <div><label>Mother Name</label><input type="text" name="mother_name" value="<%=rowMap.get("mother_name")%>"></div>
            <div><label>Mother Occupation</label><input type="text" name="mother_occupation" value="<%=rowMap.get("mother_occupation")%>"></div>
            <div><label>Mother Organization</label><input type="text" name="mother_organization" value="<%=rowMap.get("mother_organization")%>"></div>
            <div><label>Mother Mobile</label><input type="text" name="mother_mobile_no" value="<%=rowMap.get("mother_mobile_no")%>"></div>
            <div><label>Place From</label><input type="text" name="place_from" value="<%=rowMap.get("place_from")%>"></div>
            <div><label>Segment</label><input type="text" name="segment" value="<%=rowMap.get("segment")%>"></div>
            <div><label>Exam Date</label><input type="date" name="exam_date" value="<%= rowMap.get("exam_date") == null ? "" : rowMap.get("exam_date") %>"></div>
            <div><label>General Remarks</label><input type="text" name="general_remarks" value="<%= rowMap.get("general_remarks") == null ? "" : rowMap.get("general_remarks") %>"></div>
            <div><label>Entrance Remarks</label><input type="text" name="entrance_remarks" value="<%= rowMap.get("entrance_remarks") == null ? "" : rowMap.get("entrance_remarks") %>"></div>
            <div><label>Application No</label><input type="text" name="application_no" value="<%= rowMap.get("application_no") == null ? "" : rowMap.get("application_no") %>"></div>
        </div>
        <br>
        <button class="btn gray" type="submit">Save Changes</button>
        <button class="btn gray" type="button" onclick="closeEditModal(<%=id%>)">Cancel</button>
    </form>
</div>
</div>
<% } } %>
</body>
</html>