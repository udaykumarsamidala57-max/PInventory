<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.bean.DBUtil3" %>
<%
   HttpSession sess = request.getSession(false);
   if (sess == null || sess.getAttribute("username") == null) {
      response.sendRedirect("login.jsp");
       return;
   }
   String role = (String) sess.getAttribute("role");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Admission Review | Sandur Residential School</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #4f46e5; --success: #10b981; --danger: #ef4444; --bg: #f8fafc;
            --card-bg: #ffffff; --header-dark: #0f172a; --text-main: #1e293b;
            --text-muted: #64748b; --border-subtle: #e2e8f0; --border-heavy: #cbd5e1;
            --gold-primary: #fbbf24; --gold-border: #d4af37; --gold-glow: rgba(212, 175, 55, 0.3);
        }
        * { box-sizing: border-box; font-family: 'Plus Jakarta Sans', sans-serif; }
        body { margin: 0; background-color: var(--bg); color: var(--text-main); padding: 30px; position: relative; }
        .container { max-width: 1400px; margin: 0 auto; }
        .page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; }
        
        /* Floating Bubble Style */
        .approved-bubble {
            position: fixed; bottom: 40px; right: 40px; 
            background: var(--header-dark); color: white;
            padding: 15px 25px; border-radius: 50px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.2);
            z-index: 1000; display: flex; align-items: center; gap: 12px;
            border: 2px solid var(--success); transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }
        .approved-bubble:hover { transform: scale(1.05); }
        .approved-bubble .count { font-size: 24px; font-weight: 800; color: var(--success); }
        .approved-bubble .label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; line-height: 1.2; }

        .search-bar {
            background: white; padding: 20px 24px; border-radius: 16px; border: 1px solid var(--border-heavy); 
            display: flex; gap: 24px; align-items: center; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05); margin-bottom: 30px;
        }
        .filter-item { display: flex; flex-direction: column; gap: 8px; }
        .filter-item label { font-size: 11px; font-weight: 800; color: var(--text-muted); text-transform: uppercase; }
        select, input[type="date"], input[type="text"] {
            border: 1.5px solid var(--border-subtle); border-radius: 10px; padding: 10px 14px;
            font-size: 14px; color: var(--text-main); outline: none; background: #fcfcfc;
        }

        .card-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(420px, 1fr)); gap: 24px; }
        
        .student-card {
            background: var(--card-bg); border-radius: 16px; 
            border: 2px solid var(--gold-border); border-top: 8px solid var(--gold-border);
            box-shadow: 0 10px 30px -5px var(--gold-glow);
            background: linear-gradient(to bottom, #ffffff, #fffdf5);
            transition: 0.3s cubic-bezier(0.4, 0, 0.2, 1); 
            position: relative; overflow: hidden; display: flex; flex-direction: column;
        }

        .student-card:hover { transform: translateY(-5px); }

        .stamp-container { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%) rotate(-25deg); pointer-events: none; z-index: 10; display: none; }
        .card-selected .select-stamp { display: block; }
        .card-rejected .reject-stamp { display: block; }
        .stamp { font-size: 42px; font-weight: 900; padding: 10px 25px; border-radius: 10px; text-transform: uppercase; letter-spacing: 4px; opacity: 0.2; border: 6px solid; }
        .select-stamp .stamp { color: var(--success); border-color: var(--success); }
        .reject-stamp .stamp { color: var(--danger); border-color: var(--danger); }
        
        .rank-badge { 
            position: absolute; top: 12px; right: 12px; 
            background: #fbbf24; color: #78350f; 
            padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 800; 
            box-shadow: 0 2px 10px rgba(251, 191, 36, 0.5); z-index: 5;
        }

        .card-body { padding: 20px; position: relative; z-index: 2; }
        .student-name { font-size: 20px; font-weight: 800; margin: 0 0 12px 0; color: var(--header-dark); text-transform: capitalize; }
        
        .tag-row { display: flex; gap: 8px; margin-bottom: 16px; flex-wrap: wrap; }
        .tag { font-size: 14px; font-weight: 800; padding: 4px 10px; border-radius: 6px; text-transform: uppercase; }
        .tag-segment { background: #fffbeb; color: #92400e; }
        .tag-type { background: #f0fdf4; color: #166534; }
        .tag-age { background: #eef2ff; color: #4338ca; border: 1.5px solid #c7d2fe; }
        .tag-dob { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; }
        
        .parent-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 18px; padding: 12px; background: rgba(255,255,255,0.6); border-radius: 12px; border: 1px solid #f1f5f9; }
        .parent-box h4 { margin: 0 0 6px 0; font-size: 10px; text-transform: uppercase; color: var(--text-muted); border-bottom: 1px solid #e2e8f0; padding-bottom: 2px; }
        .p-detail { font-size: 14px; margin-bottom: 2px; font-weight: 700; display: block; text-transform: capitalize; }
        .p-sub { font-size: 14px; color: var(--text-muted); font-weight: 500; display: block; line-height: 1.4; }
        
        .marks-container { border: 1px solid #e2e8f0; border-radius: 12px; padding: 12px; display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 16px; background: #fff; }
        .mark-item { font-size: 14px; display: flex; justify-content: space-between; font-weight: 600; }
        .mark-item b { color: var(--primary); }
        
        .card-footer { padding: 16px 20px; display: flex; justify-content: space-between; border-top: 1px solid #f1f5f9; background: rgba(255,255,255,0.8); margin-top: auto;}
        .percentage { font-size: 24px; font-weight: 900; color: var(--success); }
        
        .action-area { padding: 0 20px 20px 20px; display: flex; gap: 12px; position: relative; z-index: 20; }
        .btn { flex: 1; padding: 10px; border-radius: 10px; font-size: 11px; font-weight: 700; cursor: pointer; border: none; text-transform: uppercase; transition: 0.2s; }
        .btn-approve { background: var(--header-dark); color: white; }
        .btn-reject { background: #fff; color: var(--danger); border: 1.5px solid #fee2e2; }
        
        .card-selected { border-color: var(--success) !important; border-top-color: var(--success) !important; }
        .card-rejected { border-color: var(--danger) !important; border-top-color: var(--danger) !important; }
        .no-data { grid-column: 1/-1; text-align: center; padding: 100px; color: var(--text-muted); font-weight: 600; }
    </style>
</head>
<body>
<jsp:include page="common_header.jsp" />

<div class="approved-bubble" id="approvedBubble">
    <div class="count" id="approvedCount">0</div>
    <div class="label">Students<br>Approved</div>
</div>

<div class="container">
    <div class="page-header"><h1>Admission Merit Board</h1></div>
    <div class="search-bar">
        <div class="filter-item" style="flex: 1;">
            <label><input type="checkbox" id="all_dates_check" onchange="toggleDateFilter()"> All Dates</label>
            <input type="date" id="exam_date" onchange="loadData()" value="<%= java.time.LocalDate.now() %>">
        </div>
        <div class="filter-item" style="flex: 1;">
            <label>Grade</label>
            <select id="class_id" onchange="loadData()">
                <option value="">Select Grade</option>
                <% try(Connection con = DBUtil3.getConnection(); Statement st = con.createStatement(); ResultSet rs = st.executeQuery("SELECT class_id, class_name FROM classes")) {
                    while(rs.next()){ %><option value="<%=rs.getInt("class_id")%>"><%=rs.getString("class_name")%></option><% }
                } catch(Exception e) {} %>
            </select>
        </div>
        <div class="filter-item" style="flex: 2;"><label>Search</label><input type="text" id="searchBox" placeholder="Search name or ID..." onkeyup="filterCards()"></div>
    </div>
    <div id="dataArea" class="card-grid"></div>
</div>

<script>
function toggleDateFilter() {
    document.getElementById("exam_date").disabled = document.getElementById("all_dates_check").checked;
    loadData();
}

function formatDate(dateStr) {
    if(!dateStr || dateStr === "") return "N/A";
    try {
        const d = new Date(dateStr);
        return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
    } catch(e) { return dateStr; }
}

function getAgeString(dobString) {
    if(!dobString || dobString === "") return "N/A";
    try {
        const birthDate = new Date(dobString);
        const targetDate = new Date(2026, 4, 31); 

        let years = targetDate.getFullYear() - birthDate.getFullYear();
        let months = targetDate.getMonth() - birthDate.getMonth();
        let days = targetDate.getDate() - birthDate.getDate();

        if (days < 0) {
            months--;
            const lastDayOfMonth = new Date(targetDate.getFullYear(), targetDate.getMonth(), 0).getDate();
            days += lastDayOfMonth;
        }
        if (months < 0) {
            years--;
            months += 12;
        }
        return `\${years}Y \${months}M \${days}D`;
    } catch(e) { return "N/A"; }
}

// Logic to update the floating count
function updateApprovedCount() {
    const cards = document.querySelectorAll('.student-card');
    let count = 0;
    cards.forEach(card => {
        // Only count if the card is visible AND has the selected class
        if (card.style.display !== 'none' && card.classList.contains('card-selected')) {
            count++;
        }
    });
    document.getElementById('approvedCount').innerText = count;
}

async function loadData() {
    const classId = document.getElementById("class_id").value;
    const isAll = document.getElementById("all_dates_check").checked;
    const examDate = isAll ? "All" : document.getElementById("exam_date").value;
    
    if(!classId) {
        document.getElementById("dataArea").innerHTML = '<div class="no-data">Please select a grade to view data.</div>';
        document.getElementById('approvedCount').innerText = "0";
        return;
    }

    try {
        const res = await fetch(`UpdateAdmissionStatus?class_id=\${classId}&exam_date=\${examDate}`);
        const data = await res.json();
        
        const processed = data.students.map(s => {
            let total = 0, max = 0;
            data.exams.forEach(e => { 
                total += (s.marks[e.id] || 0); 
                max += e.max; 
            });
            return { ...s, totalScore: total, maxPossible: max, percentage: max > 0 ? (total/max)*100 : 0 };
        }).sort((a, b) => b.percentage - a.percentage);

        renderCards(data.exams, processed);
        updateApprovedCount(); // Update count after load
    } catch (e) { 
        console.error(e); 
        document.getElementById("dataArea").innerHTML = '<div class="no-data">Error loading data. Check console.</div>';
    }
}

function renderCards(exams, students) {
    const container = document.getElementById("dataArea");
    if(!students || students.length === 0) { 
        container.innerHTML = '<div class="no-data">No students found for this selection.</div>'; 
        return; 
    }
    
    container.innerHTML = students.map((s, i) => {
        const sel = s.status === 'Selected';
        const rej = s.status === 'Rejected';
        const age = getAgeString(s.dob);
        const formattedDob = formatDate(s.dob);

        return `
            <div class="student-card \${sel?'card-selected':''} \${rej?'card-rejected':''}" data-search="\${s.name.toLowerCase()} \${s.appNo}" data-status="\${s.status}">
                <div class="stamp-container select-stamp"><div class="stamp">SELECTED</div></div>
                <div class="stamp-container reject-stamp"><div class="stamp">REJECTED</div></div>
                <div class="rank-badge">#\${i+1}</div>
                <div class="card-body">
                    <h3 class="student-name">\${s.name}</h3>
                    <div style="font-size:11px; margin-bottom:10px; color:var(--text-muted)">ID: \${s.appNo} | \${s.place}</div>
                    
                    <div class="tag-row">
                        <span class="tag tag-segment">\${s.segment}</span>
                        <span class="tag tag-type">\${s.admission_type}</span>
                        <span class="tag tag-dob">DOB: \${formattedDob}</span>
                        <span class="tag tag-age">Age: \${age}</span>
                    </div>

                    <div class="parent-grid">
                        <div class="parent-box">
                            <h4>Father</h4>
                            <span class="p-detail">\${s.father}</span>
                            <span class="p-sub">Mob: \${s.fMobile}</span>
                            <span class="p-sub">Org: \${s.fOrg}</span>
                        </div>
                        <div class="parent-box">
                            <h4>Mother</h4>
                            <span class="p-detail">\${s.mother}</span>
                            <span class="p-sub">Mob: \${s.mMobile}</span>
                            <span class="p-sub">Org: \${s.mOrg}</span>
                        </div>
                    </div>
                    
                    <div class="marks-container">
                        \${exams.map(e => `
                            <div class="mark-item">\${e.name} <b>\${s.marks[e.id] || 0}</b></div>
                        `).join('')}
                    </div>
                </div>

                <div class="card-footer">
                    <div>
                        <div style="font-size:9px; font-weight:800; color:var(--text-muted)">TOTAL SCORE</div>
                        <div style="font-weight:800; color:var(--header-dark)">\${s.totalScore} / \${s.maxPossible}</div>
                    </div>
                    <span class="percentage">\${s.percentage.toFixed(1)}%</span>
                </div>

                <% if("Global".equalsIgnoreCase(role)){%>
                <div class="action-area">
                    <button class="btn btn-approve" onclick="updateStatus(\${s.id}, 'Selected')">
                        \${sel ? '✓ Selected' : 'Approve'}
                    </button>
                    <button class="btn btn-reject" onclick="updateStatus(\${s.id}, 'Rejected')">
                        \${rej ? 'Rejected' : 'Reject'}
                    </button>
                </div>
                <% } %>
            </div>`;
    }).join('');
}

async function updateStatus(id, status) {
    const params = new URLSearchParams({ enquiry_id: id, status: status });
    try {
        const res = await fetch('UpdateAdmissionStatus', { method: 'POST', body: params });
        const text = await res.text();
        if(text === "Success") {
            loadData();
        }
    } catch(e) { alert("Failed to update status"); }
}

function filterCards() {
    const q = document.getElementById("searchBox").value.toLowerCase();
    document.querySelectorAll('.student-card').forEach(c => {
        c.style.display = c.dataset.search.includes(q) ? "flex" : "none";
    });
    updateApprovedCount(); // Update count while searching
}
</script>
</body>
</html>