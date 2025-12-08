<%@ page import="java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
<title>GRN Details</title>

<meta name="viewport" content="width=device-width, initial-scale=1">

<style>
/* Material UI inspired Indigo/Purple theme */
:root{
    --bg: #f3f4f6;
    --card: #ffffff;
    --accent: #5c6bc0; /* Indigo */
    --accent-light: #7986cb;
    --accent-dark: #3f51b5;
    --muted: #6b7280;
    --border: #e0e0e0;
    --success: #43a047;
    --hover-shadow: rgba(63,81,181,0.2);
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
h2 { margin:0 0 6px 0; font-weight:600; color: var(--accent-dark); }

.controls {
    display:flex;
    gap:10px;
    align-items:center;
    flex-wrap:wrap;
}
.input, .btn {
    padding:8px 10px;
    border-radius:6px;
    border:1px solid var(--border);
    background: #fff;
    font-size:14px;
}
.input[type="date"] { padding:7px 8px; }
.input::placeholder { color: var(--muted); }

.btn {
    cursor:pointer;
    background: var(--accent);
    color: #fff;
    border: none;
    box-shadow: none;
    transition: 0.2s;
}
.btn:hover { background: var(--accent-dark); }
.btn.secondary {
    background: #fff;
    color: var(--accent);
    border: 1px solid var(--accent);
}
.small {
    padding:6px 8px;
    font-size:13px;
    border-radius:6px;
}

.container {
    background: var(--card);
    padding:16px;
    margin-bottom:16px;
    border-radius:10px;
    border:1px solid var(--border);
    box-shadow: 0 1px 3px var(--hover-shadow);
    transition: 0.2s;
}
.container:hover {
    box-shadow: 0 4px 10px var(--hover-shadow);
}
.title {
    display:flex;
    justify-content:space-between;
    align-items:center;
    margin-bottom:12px;
}
.title-left { font-weight:600; color: var(--accent-dark); font-size:16px; }
.meta { color: var(--muted); font-size:13px; }

.info-grid {
    display:grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap:8px;
    margin-bottom:12px;
}
.info-card {
    background:#f8f9fa;
    padding:10px;
    border-radius:6px;
    border:1px solid #e8eaf6;
    font-size:13px;
    transition: 0.2s;
}
.info-card:hover { background:#eef1fa; }

.items-table {
    width:100%;
    border-collapse:collapse;
}
.items-table th, .items-table td {
    text-align:left;
    padding:8px 10px;
    border-bottom:1px solid #e0e0e0;
    font-size:14px;
}
.items-table th { background:#e8eaf6; font-weight:600; }

.toggle-btn {
    background:transparent;
    color: var(--accent);
    border:none;
    font-weight:600;
    cursor:pointer;
    padding:6px 8px;
    transition:0.2s;
}
.toggle-btn:hover { color: var(--accent-dark); }

.controls-right { margin-left:auto; display:flex; gap:8px; align-items:center; }

/* responsive */
@media (max-width:700px){
    .info-table th, .info-table td, .items-table th, .items-table td { padding:6px 6px; font-size:13px; }
    .header-row { flex-direction:column; align-items:flex-start; }
}
.hidden { display:none !important; }
</style>

<script>
/* JS functions: filtering, expand/collapse, CSV download */

function parseDate(s) {
    if (!s) return null;
    if (s instanceof Date) return s;
    s = String(s).trim();
    var dashCount = (s.match(/-/g) || []).length;
    var slashCount = (s.match(/\//g) || []).length;
    if (dashCount === 2 && /^\d{2}-\d{2}-\d{4}$/.test(s)) {
        var parts = s.split("-");
        s = parts[2] + "-" + parts[1] + "-" + parts[0];
    } else if (slashCount === 2 && /^\d{2}\/\d{2}\/\d{4}$/.test(s)) {
        var parts = s.split("/");
        s = parts[2] + "-" + parts[1] + "-" + parts[0];
    }
    var d = new Date(s);
    return isNaN(d.getTime()) ? null : d;
}

function filterGRNs() {
    var poInput = document.getElementById('filter_po').value.trim().toLowerCase();
    var fromDateVal = document.getElementById('filter_from').value;
    var toDateVal = document.getElementById('filter_to').value;
    var fromDate = fromDateVal ? new Date(fromDateVal) : null;
    var toDate = toDateVal ? new Date(toDateVal) : null;
    if (toDate) toDate.setHours(23,59,59,999);

    var cards = document.querySelectorAll('.grn-card');
    cards.forEach(function(card) {
        var po = (card.getAttribute('data-po') || '').toLowerCase();
        var dateStr = card.getAttribute('data-date') || '';
        var grnDate = parseDate(dateStr);
        var poMatch = !poInput || po.indexOf(poInput) !== -1;
        var dateMatch = true;
        if (fromDate && grnDate) dateMatch = grnDate >= fromDate;
        if (toDate && grnDate) dateMatch = dateMatch && (grnDate <= toDate);
        if ((fromDate && !grnDate) || (toDate && !grnDate)) dateMatch = false;
        if (poMatch && dateMatch) card.classList.remove('hidden');
        else card.classList.add('hidden');
    });
    var visible = document.querySelectorAll('.grn-card:not(.hidden)').length;
    document.getElementById('visible_count').innerText = visible;
}

function toggleItems(id) {
    var section = document.getElementById('items_' + id);
    if (!section) return;
    section.style.display = (section.style.display === 'none' || section.style.display === '') ? 'block' : 'none';
}

function expandAll() {
    document.querySelectorAll('.grn-card:not(.hidden) .items-container').forEach(c=>c.style.display='block');
}
function collapseAll() {
    document.querySelectorAll('.grn-card .items-container').forEach(c=>c.style.display='none');
}

function csvSafe(s){
    if (s===null||s===undefined) return '';
    var str=String(s);
    if(str.indexOf('"')!==-1) str=str.replace(/"/g,'""');
    if(str.search(/("|,|\n)/g)!==-1) str='"'+str+'"';
    return str;
}

function downloadCSV() {
    var rows = [];
    rows.push(['GRN No','GRN Date','Vendor Name','Vendor GSTIN','Address','PO Number','Invoice No','Invoice Date','Received By','GRN Remarks','Item Description','Qty Ordered','Qty Received','Qty Accepted','Qty Rejected','Item Remarks'].join(','));
    var visibleCards = document.querySelectorAll('.grn-card:not(.hidden)');
    if (visibleCards.length === 0) { alert('No visible GRNs to download.'); return; }
    visibleCards.forEach(function(card){
        var meta = {
            grnNo: card.getAttribute('data-grn')||'',
            grnDate: card.getAttribute('data-date')||'',
            vendor: card.getAttribute('data-vendor')||'',
            gstin: card.getAttribute('data-gstin')||'',
            address: card.getAttribute('data-address')||'',
            po: card.getAttribute('data-po')||'',
            invoiceNo: card.getAttribute('data-invoice')||'',
            invoiceDate: card.getAttribute('data-invdate')||'',
            receivedBy: card.getAttribute('data-receivedby')||'',
            grnRemarks: card.getAttribute('data-remarks')||''
        };
        var itemRows = card.querySelectorAll('.items-table tbody tr.item-row');
        if(itemRows.length===0){
            rows.push([
                csvSafe(meta.grnNo),csvSafe(meta.grnDate),csvSafe(meta.vendor),csvSafe(meta.gstin),
                csvSafe(meta.address),csvSafe(meta.po),csvSafe(meta.invoiceNo),csvSafe(meta.invoiceDate),
                csvSafe(meta.receivedBy),csvSafe(meta.grnRemarks),'','','','','',''
            ].join(','));
        }else{
            itemRows.forEach(function(ir){
                rows.push([
                    csvSafe(meta.grnNo),csvSafe(meta.grnDate),csvSafe(meta.vendor),csvSafe(meta.gstin),
                    csvSafe(meta.address),csvSafe(meta.po),csvSafe(meta.invoiceNo),csvSafe(meta.invoiceDate),
                    csvSafe(meta.receivedBy),csvSafe(meta.grnRemarks),
                    csvSafe(ir.getAttribute('data-desc')||ir.querySelector('.cell-desc')?.innerText||''),
                    csvSafe(ir.getAttribute('data-qordered')||ir.querySelector('.cell-qordered')?.innerText||''),
                    csvSafe(ir.getAttribute('data-qreceived')||ir.querySelector('.cell-qreceived')?.innerText||''),
                    csvSafe(ir.getAttribute('data-qaccepted')||ir.querySelector('.cell-qaccepted')?.innerText||''),
                    csvSafe(ir.getAttribute('data-qrejected')||ir.querySelector('.cell-qrejected')?.innerText||''),
                    csvSafe(ir.getAttribute('data-remarks')||ir.querySelector('.cell-remarks')?.innerText||'')
                ].join(','));
            });
        }
    });
    var csvContent = rows.join('\n');
    var blob = new Blob([csvContent], {type:'text/csv;charset=utf-8;'});
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    var ts = new Date();
    a.download='GRN_export_'+ts.getFullYear()+('0'+(ts.getMonth()+1)).slice(-2)+('0'+ts.getDate()).slice(-2)+'_'+('0'+ts.getHours()).slice(-2)+('0'+ts.getMinutes()).slice(-2)+'.csv';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('filter_po').addEventListener('input', filterGRNs);
    document.getElementById('filter_from').addEventListener('change', filterGRNs);
    document.getElementById('filter_to').addEventListener('change', filterGRNs);
    document.getElementById('btn_expand_all').addEventListener('click', expandAll);
    document.getElementById('btn_collapse_all').addEventListener('click', collapseAll);
    document.getElementById('btn_download_csv').addEventListener('click', downloadCSV);
    filterGRNs();
});
</script>

</head>
<body>
<%@ include file="header.jsp" %>
<div class="header-row">
    <div>
        <h2>All GRN Details</h2>
        <div class="meta">Material Indigo/Purple UI | Filter & Export GRNs</div>
    </div>

    <div class="controls" style="margin-left:auto;">
        <input id="filter_po" class="input" type="text" placeholder="Search PO Number">
        <label style="font-size:13px; color:var(--muted);">From</label>
        <input id="filter_from" class="input" type="date">
        <label style="font-size:13px; color:var(--muted);">To</label>
        <input id="filter_to" class="input" type="date">
        <button id="btn_expand_all" class="btn small" style="background:#5c6bc0;">Expand All</button>
        <button id="btn_collapse_all" class="btn small secondary">Collapse All</button>
        <button id="btn_download_csv" class="btn small" style="background:#43a047;">Download CSV</button>
    </div>
</div>

<p style="margin:6px 0 12px 0; color:var(--muted);">Visible GRNs: <b id="visible_count">0</b></p>

<%
if (request.getAttribute("error") != null) {
    out.println("<p style='color:red'><b>" + request.getAttribute("error") + "</b></p>");
    return;
}

List<Map<String, Object>> allGRNs = (List<Map<String, Object>>) request.getAttribute("all_grns");
if (allGRNs == null || allGRNs.isEmpty()) {
    out.println("<p>No GRN records found</p>");
    return;
}

int index = 1;
for (Map<String, Object> grn : allGRNs) {
    String grnNo = grn.get("grn_no") == null ? "" : grn.get("grn_no").toString();
    String grnDate = grn.get("grn_date") == null ? "" : grn.get("grn_date").toString();
    String vendor = grn.get("vendor_name") == null ? "" : grn.get("vendor_name").toString();
    String gstin = grn.get("vendor_gstin") == null ? "" : grn.get("vendor_gstin").toString();
    String address = grn.get("vendor_address") == null ? "" : grn.get("vendor_address").toString();
    String poId = grn.get("po_id") == null ? "" : grn.get("po_id").toString();
    String invoiceNo = grn.get("invoice_no") == null ? "" : grn.get("invoice_no").toString();
    String invoiceDate = grn.get("invoice_date") == null ? "" : grn.get("invoice_date").toString();
    String receivedBy = grn.get("received_by") == null ? "" : grn.get("received_by").toString();
    String remarks = grn.get("remarks") == null ? "" : grn.get("remarks").toString();
%>

<div class="container grn-card"
     data-grn="<%= grnNo %>"
     data-date="<%= grnDate %>"
     data-vendor="<%= vendor %>"
     data-gstin="<%= gstin %>"
     data-address="<%= address %>"
     data-po="<%= poId %>"
     data-invoice="<%= invoiceNo %>"
     data-invdate="<%= invoiceDate %>"
     data-receivedby="<%= receivedBy %>"
     data-remarks="<%= remarks %>">

    <div class="title">
        <div class="title-left">
            <span>GRN: <%= grnNo %></span>
            <span style="margin-left:12px; color:var(--muted); font-weight:500; font-size:13px;">Date: <%= grnDate %></span>
            <div style="font-size:13px; color:var(--muted); margin-top:4px;"><%= vendor %> <span style="margin-left:8px;">| PO: <b><%= poId %></b></span></div>
        </div>
        <div class="controls-right">
            <button class="toggle-btn" onclick="toggleItems('<%= index %>')">Show / Hide Items</button>
        </div>
    </div>

    <div class="info-grid">
        <div class="info-card"><strong>Invoice</strong><div style="color:var(--muted); margin-top:4px;"><%= invoiceNo %> (<%= invoiceDate %>)</div></div>
        <div class="info-card"><strong>GSTIN</strong><div style="color:var(--muted); margin-top:4px;"><%= gstin %></div></div>
        <div class="info-card"><strong>Received By</strong><div style="color:var(--muted); margin-top:4px;"><%= receivedBy %></div></div>
        <div class="info-card"><strong>Remarks</strong><div style="color:var(--muted); margin-top:4px;"><%= remarks %></div></div>
    </div>

    <div id="items_<%= index %>" class="items-container" style="display:none">
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
        List<Map<String, Object>> items = (List<Map<String, Object>>) grn.get("items");
        if (items != null && !items.isEmpty()) {
            for (Map<String, Object> item : items) {
                String desc = item.get("item_description") == null ? "" : item.get("item_description").toString();
                String qordered = item.get("qty_ordered") == null ? "" : item.get("qty_ordered").toString();
                String qreceived = item.get("qty_received") == null ? "" : item.get("qty_received").toString();
                String qaccepted = item.get("qty_accepted") == null ? "" : item.get("qty_accepted").toString();
                String qrejected = item.get("qty_rejected") == null ? "" : item.get("qty_rejected").toString();
                String iremarks = item.get("remarks") == null ? "" : item.get("remarks").toString();
        %>
            <tr class="item-row"
                data-desc="<%= desc.replaceAll("\"","''") %>"
                data-qordered="<%= qordered %>"
                data-qreceived="<%= qreceived %>"
                data-qaccepted="<%= qaccepted %>"
                data-qrejected="<%= qrejected %>"
                data-remarks="<%= iremarks.replaceAll("\"","''") %>">
                <td class="cell-desc"><%= desc %></td>
                <td class="cell-qordered"><%= qordered %></td>
                <td class="cell-qreceived"><%= qreceived %></td>
                <td class="cell-qaccepted"><%= qaccepted %></td>
                <td class="cell-qrejected"><%= qrejected %></td>
                <td class="cell-remarks"><%= iremarks %></td>
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
