<%@ page import="java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
<title>GRN Details</title>
<meta name="viewport" content="width=device-width, initial-scale=1">

<style>

:root {
    --bg: #f0f4f8;
    --card1: #ffffff;
    --card2: #e3f2fd;
    --accent: #3f51b5; 
    --accent-light: #7986cb;
    --accent-dark: #283593;
    --muted: #555555;
    --border: #cfd8dc;
    --success: #43a047;
    --danger: #e53935;
    --warning: #ff9800;
    --hover-shadow: rgba(0,0,0,0.15);
}

body {
    font-family: "Roboto", "Segoe UI", Arial, sans-serif;
    background: var(--bg);
    margin: 16px;
    color: #111827;
}


.header-row {
    display:flex;
    gap:12px;
    align-items:center;
    margin-bottom:16px;
    flex-wrap:wrap;
}
h2 { margin:0 0 6px 0; font-weight:700; color: var(--accent-dark); text-shadow: 1px 1px 2px rgba(0,0,0,0.1);}
.meta { color: var(--muted); font-size:13px; }
.controls {
    display:flex;
    gap:10px;
    align-items:center;
    flex-wrap:wrap;
}
.input, .btn {
    padding:8px 12px;
    border-radius:8px;
    border:1px solid var(--border);
    font-size:14px;
}
.input {
    background:#fff;
}
.input::placeholder { color: var(--muted); }
.btn {
    cursor:pointer;
    border:none;
    font-weight:600;
    transition: all 0.3s ease;
    box-shadow:0 2px 6px var(--hover-shadow);
}
.btn:hover { transform:translateY(-1px); box-shadow:0 4px 12px var(--hover-shadow);}
.btn.primary { background: linear-gradient(45deg,#3f51b5,#7986cb); color:#fff;}
.btn.secondary { background:#fff; color:var(--accent); border:1px solid var(--accent);}
.btn.success { background: linear-gradient(45deg,#43a047,#66bb6a); color:#fff;}
.small { padding:6px 10px; font-size:13px; }


.container {
    padding:20px;
    margin-bottom:20px;
    border-radius:16px;
    border:1px solid var(--border);
    box-shadow:0 4px 12px var(--hover-shadow);
    transition: all 0.3s ease;
    background: var(--card1);
}
.container:nth-child(even) { background: var(--card2);}
.container:hover { box-shadow:0 8px 20px var(--hover-shadow); transform: translateY(-2px);}
.title {
    display:flex;
    justify-content:space-between;
    align-items:center;
    margin-bottom:12px;
}
.title-left { font-weight:600; color: var(--accent-dark); font-size:16px; }
.controls-right { display:flex; gap:8px; align-items:center; }
.toggle-btn {
    background:transparent;
    color: var(--accent-dark);
    border:none;
    font-weight:600;
    cursor:pointer;
    padding:6px 10px;
    transition:0.2s;
}
.toggle-btn:hover { color: var(--accent-light); }


.info-grid {
    display:grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap:12px;
    margin-bottom:12px;
}
.info-card {
    background: linear-gradient(135deg,#f5f5f5,#e3f2fd);
    padding:12px;
    border-radius:12px;
    border:1px solid #c5cae9;
    font-size:13px;
    transition: all 0.2s ease;
    box-shadow: 0 2px 6px rgba(0,0,0,0.05);
}
.info-card:hover { background: linear-gradient(135deg,#e8f0fe,#bbdefb); transform:translateY(-2px); }


.items-table {
    width:100%;
    border-collapse:collapse;
    margin-top:10px;
    font-size:14px;
    border-radius:12px;
    overflow:hidden;
}
.items-table th, .items-table td {
    text-align:left;
    padding:10px 12px;
    border-bottom:1px solid #cfd8dc;
}
.items-table th { background: linear-gradient(45deg,#7986cb,#3f51b5); color:#fff; font-weight:600; }
.items-table tbody tr:nth-child(odd) { background:#f0f4f8; }
.items-table tbody tr:nth-child(even) { background:#e8f0fe; }
.items-table tbody tr:hover { background:#d1c4e9; transform: scale(1.002); transition: all 0.2s ease; }


.items-table td.cell-qordered,
.items-table td.cell-qreceived,
.items-table td.cell-qaccepted,
.items-table td.cell-qrejected { text-align:center; }


@media (max-width:700px){
    .items-table th, .items-table td { padding:6px 6px; font-size:13px; }
    .header-row { flex-direction:column; align-items:flex-start; }
}
.hidden { display:none !important; }


.status-badge {
    display:inline-block;
    padding:4px 8px;
    font-size:12px;
    border-radius:8px;
    color:#fff;
    margin-left:8px;
    font-weight:600;
}
.status-completed { background: var(--success);}
.status-pending { background: var(--warning);}
</style>

<script>
// JS Functions remain same as your previous code
function parseDate(s) { if (!s) return null; if (s instanceof Date) return s; s = String(s).trim(); var dashCount = (s.match(/-/g) || []).length; var slashCount = (s.match(/\//g) || []).length; if (dashCount === 2 && /^\d{2}-\d{2}-\d{4}$/.test(s)) { var parts = s.split("-"); s = parts[2]+"-"+parts[1]+"-"+parts[0]; } else if (slashCount === 2 && /^\d{2}\/\d{2}\/\d{4}$/.test(s)) { var parts = s.split("/"); s = parts[2]+"-"+parts[1]+"-"+parts[0]; } var d = new Date(s); return isNaN(d.getTime())?null:d; }
function filterGRNs() { var poInput=document.getElementById('filter_po').value.trim().toLowerCase(); var fromDateVal=document.getElementById('filter_from').value; var toDateVal=document.getElementById('filter_to').value; var fromDate=fromDateVal?new Date(fromDateVal):null; var toDate=toDateVal?new Date(toDateVal):null; if(toDate) toDate.setHours(23,59,59,999); var cards=document.querySelectorAll('.grn-card'); cards.forEach(function(card){ var po=(card.getAttribute('data-po')||'').toLowerCase(); var dateStr=card.getAttribute('data-date')||''; var grnDate=parseDate(dateStr); var poMatch=!poInput || po.indexOf(poInput)!==-1; var dateMatch=true; if(fromDate && grnDate) dateMatch=grnDate>=fromDate; if(toDate && grnDate) dateMatch=dateMatch && (grnDate<=toDate); if((fromDate && !grnDate)||(toDate && !grnDate)) dateMatch=false; if(poMatch && dateMatch) card.classList.remove('hidden'); else card.classList.add('hidden'); }); document.getElementById('visible_count').innerText=document.querySelectorAll('.grn-card:not(.hidden)').length; }
function toggleItems(id){var section=document.getElementById('items_'+id); if(!section)return; section.style.display=(section.style.display==='none'||section.style.display==='')?'block':'none';}
function expandAll(){document.querySelectorAll('.grn-card:not(.hidden) .items-container').forEach(c=>c.style.display='block');}
function collapseAll(){document.querySelectorAll('.grn-card .items-container').forEach(c=>c.style.display='none');}
function csvSafe(s){if(s===null||s===undefined)return'';var str=String(s);if(str.indexOf('"')!==-1) str=str.replace(/"/g,'""'); if(str.search(/("|,|\n)/g)!==-1) str='"'+str+'"'; return str;}
function downloadCSV(){ var rows=[]; rows.push(['GRN No','GRN Date','Vendor Name','Vendor GSTIN','Address','PO Number','Invoice No','Invoice Date','Received By','GRN Remarks','Item Description','Qty Ordered','Qty Received','Qty Accepted','Qty Rejected','Item Remarks'].join(',')); var visibleCards=document.querySelectorAll('.grn-card:not(.hidden)'); if(visibleCards.length===0){ alert('No visible GRNs to download.'); return;} visibleCards.forEach(function(card){ var meta={ grnNo:card.getAttribute('data-grn')||'', grnDate:card.getAttribute('data-date')||'', vendor:card.getAttribute('data-vendor')||'', gstin:card.getAttribute('data-gstin')||'', address:card.getAttribute('data-address')||'', po:card.getAttribute('data-po')||'', invoiceNo:card.getAttribute('data-invoice')||'', invoiceDate:card.getAttribute('data-invdate')||'', receivedBy:card.getAttribute('data-receivedby')||'', grnRemarks:card.getAttribute('data-remarks')||'' }; var itemRows=card.querySelectorAll('.items-table tbody tr.item-row'); if(itemRows.length===0){ rows.push([csvSafe(meta.grnNo),csvSafe(meta.grnDate),csvSafe(meta.vendor),csvSafe(meta.gstin),csvSafe(meta.address),csvSafe(meta.po),csvSafe(meta.invoiceNo),csvSafe(meta.invoiceDate),csvSafe(meta.receivedBy),csvSafe(meta.grnRemarks),'','','','','',''].join(',')); }else{ itemRows.forEach(function(ir){ rows.push([csvSafe(meta.grnNo),csvSafe(meta.grnDate),csvSafe(meta.vendor),csvSafe(meta.gstin),csvSafe(meta.address),csvSafe(meta.po),csvSafe(meta.invoiceNo),csvSafe(meta.invoiceDate),csvSafe(meta.receivedBy),csvSafe(meta.grnRemarks),csvSafe(ir.getAttribute('data-desc')||ir.querySelector('.cell-desc')?.innerText||''),csvSafe(ir.getAttribute('data-qordered')||ir.querySelector('.cell-qordered')?.innerText||''),csvSafe(ir.getAttribute('data-qreceived')||ir.querySelector('.cell-qreceived')?.innerText||''),csvSafe(ir.getAttribute('data-qaccepted')||ir.querySelector('.cell-qaccepted')?.innerText||''),csvSafe(ir.getAttribute('data-qrejected')||ir.querySelector('.cell-qrejected')?.innerText||''),csvSafe(ir.getAttribute('data-remarks')||ir.querySelector('.cell-remarks')?.innerText||'')].join(',')); }); } }); var csvContent=rows.join('\n'); var blob=new Blob([csvContent], {type:'text/csv;charset=utf-8;'}); var url=URL.createObjectURL(blob); var a=document.createElement('a'); a.href=url; var ts=new Date(); a.download='GRN_export_'+ts.getFullYear()+('0'+(ts.getMonth()+1)).slice(-2)+('0'+ts.getDate()).slice(-2)+'_'+('0'+ts.getHours()).slice(-2)+('0'+ts.getMinutes()).slice(-2)+'.csv'; document.body.appendChild(a); a.click(); document.body.removeChild(a); URL.revokeObjectURL(url);}
document.addEventListener('DOMContentLoaded', function(){ document.getElementById('filter_po').addEventListener('input',filterGRNs); document.getElementById('filter_from').addEventListener('change',filterGRNs); document.getElementById('filter_to').addEventListener('change',filterGRNs); document.getElementById('btn_expand_all').addEventListener('click',expandAll); document.getElementById('btn_collapse_all').addEventListener('click',collapseAll); document.getElementById('btn_download_csv').addEventListener('click',downloadCSV); filterGRNs();});
function printGRN(grnNo){
    if(!grnNo){
        alert("Invalid GRN Number");
        return;
    }
    window.open(
        "PrintGRN.jsp?grnNo=" + encodeURIComponent(grnNo),
        "_blank"
    );
}
</script>
</head>

<body>
<%@ include file="header.jsp" %>

<div class="header-row">
    <div>
        <h2>All GRN Details</h2>
        <div class="meta">Filter & Export GRNs</div>
    </div>
    <div class="controls" style="margin-left:auto;">
        <input id="filter_po" class="input" type="text" placeholder="Search PO Number">
        <label style="font-size:13px; color:var(--muted);">From</label>
        <input id="filter_from" class="input" type="date">
        <label style="font-size:13px; color:var(--muted);">To</label>
        <input id="filter_to" class="input" type="date">
        <button id="btn_expand_all" class="btn small primary">Expand All</button>
        <button id="btn_collapse_all" class="btn small secondary">Collapse All</button>
        <button id="btn_download_csv" class="btn small success">Download CSV</button>
    </div>
</div>

<p style="margin:6px 0 12px 0; color:var(--muted);">Visible GRNs: <b id="visible_count">0</b></p>

<%
if(request.getAttribute("error") != null){
    out.println("<p style='color:red'><b>"+request.getAttribute("error")+"</b></p>");
    return;
}
List<Map<String,Object>> allGRNs=(List<Map<String,Object>>)request.getAttribute("all_grns");
if(allGRNs==null || allGRNs.isEmpty()){
    out.println("<p>No GRN records found</p>");
    return;
}
int index=1;
for(Map<String,Object> grn:allGRNs){
    String grnNo=grn.get("grn_no")==null?"":grn.get("grn_no").toString();
    String grnDate=grn.get("grn_date")==null?"":grn.get("grn_date").toString();
    String vendor=grn.get("vendor_name")==null?"":grn.get("vendor_name").toString();
    String gstin=grn.get("vendor_gstin")==null?"":grn.get("vendor_gstin").toString();
    String address=grn.get("vendor_address")==null?"":grn.get("vendor_address").toString();
    String poId=grn.get("po_id")==null?"":grn.get("po_id").toString();
    String invoiceNo=grn.get("invoice_no")==null?"":grn.get("invoice_no").toString();
    String invoiceDate=grn.get("invoice_date")==null?"":grn.get("invoice_date").toString();
    String receivedBy=grn.get("received_by")==null?"":grn.get("received_by").toString();
    String remarks=grn.get("remarks")==null?"":grn.get("remarks").toString();
    String status=grn.get("status")==null?"completed":grn.get("status").toString(); // optional status field
%>

<div class="container grn-card" data-grn="<%=grnNo%>" data-date="<%=grnDate%>" data-vendor="<%=vendor%>" data-gstin="<%=gstin%>" data-address="<%=address%>" data-po="<%=poId%>" data-invoice="<%=invoiceNo%>" data-invdate="<%=invoiceDate%>" data-receivedby="<%=receivedBy%>" data-remarks="<%=remarks%>">
    <div class="title">
        <div class="title-left">
            <span>GRN: <%=grnNo%></span>
            <span style="margin-left:12px; color:var(--muted); font-weight:500; font-size:13px;">Date: <%=grnDate%></span>
            <!-- Status badge -->
            <span class="status-badge <%=status.equalsIgnoreCase("completed")?"status-completed":"status-pending"%>"><%=status.substring(0,1).toUpperCase()+status.substring(1)%></span>
            <div style="font-size:13px; color:var(--muted); margin-top:4px;"><%=vendor%> | PO: <b><%=poId%></b></div>
        </div>
       <div class="controls-right">
    <button class="toggle-btn" onclick="toggleItems('<%=index%>')">
        Show / Hide Items
    </button>

    <button class="btn small primary"
            onclick="printGRN('<%=grnNo%>')">
        🖨 Print
    </button>
</div>
    </div>

    <div class="info-grid">
        <div class="info-card"><strong>Invoice</strong><div style="color:var(--muted); margin-top:4px;"><%=invoiceNo%> (<%=invoiceDate%>)</div></div>
        <div class="info-card"><strong>GSTIN</strong><div style="color:var(--muted); margin-top:4px;"><%=gstin%></div></div>
        <div class="info-card"><strong>Received By</strong><div style="color:var(--muted); margin-top:4px;"><%=receivedBy%></div></div>
        <div class="info-card"><strong>Remarks</strong><div style="color:var(--muted); margin-top:4px;"><%=remarks%></div></div>
    </div>

    <div id="items_<%=index%>" class="items-container" style="display:none">
        <table class="items-table">
            <thead>
                <tr>
                    <th style="width:40%;">Item Description</th>
                    <th style="width:10%;">Qty Ordered</th>
                    <th style="width:10%;">Qty Received</th>
                    <th style="width:10%;">Qty Accepted</th>
                    <th style="width:10%;">Qty Rejected</th>
                    <th style="width:20%;">Remarks</th>
                </tr>
            </thead>
            <tbody>
            <%
            List<Map<String,Object>> items=(List<Map<String,Object>>)grn.get("items");
            if(items!=null && !items.isEmpty()){
                for(Map<String,Object> item:items){
                    String desc=item.get("item_description")==null?"":item.get("item_description").toString();
                    String qordered=item.get("qty_ordered")==null?"":item.get("qty_ordered").toString();
                    String qreceived=item.get("qty_received")==null?"":item.get("qty_received").toString();
                    String qaccepted=item.get("qty_accepted")==null?"":item.get("qty_accepted").toString();
                    String qrejected=item.get("qty_rejected")==null?"":item.get("qty_rejected").toString();
                    String iremarks=item.get("remarks")==null?"":item.get("remarks").toString();
            %>
                <tr class="item-row" data-desc="<%=desc.replaceAll("\"","''")%>" data-qordered="<%=qordered%>" data-qreceived="<%=qreceived%>" data-qaccepted="<%=qaccepted%>" data-qrejected="<%=qrejected%>" data-remarks="<%=iremarks.replaceAll("\"","''")%>">
                    <td class="cell-desc"><%=desc%></td>
                    <td class="cell-qordered"><%=qordered%></td>
                    <td class="cell-qreceived"><%=qreceived%></td>
                    <td class="cell-qaccepted"><%=qaccepted%></td>
                    <td class="cell-qrejected"><%=qrejected%></td>
                    <td class="cell-remarks"><%=iremarks%></td>
                </tr>
            <%
                }
            } else {
            %>
                <tr><td colspan="6" style="text-align:center; color:var(--muted);">No items found</td></tr>
            <%
            }
            %>
            </tbody>
        </table>
    </div>
</div>

<%
index++;
}
%>

</body>
</html>
