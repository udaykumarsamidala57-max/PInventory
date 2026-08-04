<%@ page import="java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
<title>GRN Details</title>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
* { box-sizing: border-box; }
:root {
    /* SAP Fiori Color Tokens (Horizon/Quartz Mix) */
    --sap-background: #f4f6f7;
    --sap-shell-color: #354a5f;
    --sap-text-main: #32363a;
    --sap-text-muted: #6a6d70;
    --sap-border-color: #e5e5e5;
    --sap-border-dark: #b0b5b9;
    --sap-card-bg: #ffffff;
    --sap-strip-bg: #fafafa;
    
    /* SAP Semantic Functional Tokens */
    --sap-primary: #0a6ed1;
    --sap-primary-hover: #085caf;
    --sap-success: #107e3e;
    --sap-success-bg: #f0fdf4;
    --sap-success-border: rgba(16, 126, 62, 0.2);
    --sap-warning: #b75c00;
    --sap-warning-bg: #fff8f0;
    --sap-warning-border: rgba(183, 92, 0, 0.2);
    --sap-critical: #bb0000;
    
    --sap-radius: 0.25rem; /* Standard SAP compact borders */
    --sap-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.05);
}

body {
    font-family: "72", "72full", Arial, Helvetica, sans-serif;
    background-color: var(--sap-background);
    margin: 0;
    padding: 0;
    color: var(--sap-text-main);
    -webkit-font-smoothing: antialiased;
}

.main-content {
    width: 100%;
    max-width: 1600px;
    margin: 0 auto;
    padding: 2rem;
}

/* SAP Shell Page Header Title Bar */
.sap-fiori-page-header {
    background: var(--sap-card-bg);
    padding: 1.25rem 2rem;
    border-bottom: 1px solid var(--sap-border-color);
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 20px;
    flex-wrap: wrap;
    box-shadow: 0 1px 3px rgba(0,0,0,0.03);
}

.sap-header-left {
    display: flex;
    align-items: center;
    gap: 14px;
}

.sap-icon-wrapper {
    font-size: 1.5rem;
    color: var(--sap-shell-color);
}

h2 {
    margin: 0;
    font-size: 1.35rem;
    font-weight: 400;
    color: var(--sap-text-main);
}

.meta {
    color: var(--sap-text-muted);
    font-size: 0.825rem;
    margin-top: 2px;
}

.sap-counter-badge {
    font-size: 0.875rem;
    font-weight: 500;
    color: var(--sap-text-muted);
    background: var(--sap-background);
    padding: 0.35rem 0.85rem;
    border-radius: 1rem;
    border: 1px solid var(--sap-border-color);
}

.sap-counter-badge b {
    color: var(--sap-primary);
    font-weight: 700;
}

/* SAP Smart Filter Bar Control Row */
.sap-filter-bar {
    background: var(--sap-card-bg);
    border: 1px solid var(--sap-border-color);
    border-radius: var(--sap-radius);
    padding: 1.25rem;
    margin: 1.5rem 0;
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    align-items: flex-end;
    box-shadow: var(--sap-shadow);
}

.sap-filter-group {
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
}

.sap-filter-bar label {
    font-size: 0.75rem;
    font-weight: 600;
    color: var(--sap-text-muted);
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.sap-filter-bar .input {
    height: 2rem;
    padding: 0 0.5rem;
    border: 1px solid var(--sap-border-dark);
    border-radius: var(--sap-radius);
    font-family: inherit;
    font-size: 0.875rem;
    background: #ffffff;
    color: var(--sap-text-main);
    outline: none;
    min-width: 220px;
}

.sap-filter-bar .input:focus {
    border-color: var(--sap-primary);
}

/* SAP Form Action Controls Framework */
.sap-btn {
    height: 2rem;
    padding: 0 1rem;
    border: 1px solid transparent;
    border-radius: var(--sap-radius);
    cursor: pointer;
    font-size: 0.85rem;
    font-weight: 500;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    transition: background-color 0.1s, border-color 0.1s;
    white-space: nowrap;
}

.sap-btn-primary {
    background-color: var(--sap-primary);
    color: #ffffff;
}
.sap-btn-primary:hover {
    background-color: var(--sap-primary-hover);
}

.sap-btn-transparent {
    background-color: transparent;
    border-color: var(--sap-primary);
    color: var(--sap-primary);
}
.sap-btn-transparent:hover {
    background-color: rgba(10, 110, 209, 0.05);
}

.sap-btn-ghost {
    background-color: transparent;
    border-color: var(--sap-border-dark);
    color: var(--sap-text-main);
}
.sap-btn-ghost:hover {
    background-color: var(--sap-background);
    border-color: #747472;
}

.sap-btn-success {
    background-color: transparent;
    border-color: var(--sap-success);
    color: var(--sap-success);
}
.sap-btn-success:hover {
    background-color: var(--sap-success-bg);
}

/* SAP Object Page Dynamic List Block Container */
.sap-object-container {
    border: 1px solid var(--sap-border-color);
    border-radius: var(--sap-radius);
    background: var(--sap-card-bg);
    margin-bottom: 1.5rem;
    box-shadow: var(--sap-shadow);
    overflow: hidden;
}

/* SAP Card Component Section Row */
.sap-card-header {
    background: var(--sap-strip-bg);
    border-bottom: 1px solid var(--sap-border-color);
    padding: 1rem 1.5rem;
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    align-items: center;
    justify-content: space-between;
}

.sap-card-header-left {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 12px;
}

.sap-grn-id {
    font-size: 1.1rem;
    font-weight: 700;
    color: var(--sap-shell-color);
}

.sap-grn-id b {
    color: var(--sap-primary);
}

.sap-date-indicator {
    color: var(--sap-text-muted);
    font-weight: 500;
    font-size: 0.85rem;
    display: inline-flex;
    align-items: center;
    gap: 4px;
    background: var(--sap-background);
    padding: 0.2rem 0.5rem;
    border-radius: 2px;
}

.sap-subline-entity {
    font-size: 0.85rem;
    color: var(--sap-text-muted);
    width: 100%;
    margin-top: 4px;
    display: flex;
    align-items: center;
    gap: 6px;
}

.sap-subline-entity b {
    color: var(--sap-text-main);
    font-weight: 600;
}

.sap-card-header-actions {
    display: flex;
    gap: 8px;
    align-items: center;
}

/* SAP Object Block Layout Grid Details */
.sap-info-matrix {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    gap: 1.25rem;
    padding: 1rem 1.5rem;
    background: #ffffff;
    border-bottom: 1px solid var(--sap-border-color);
}

.sap-info-cell {
    font-size: 0.875rem;
}

.sap-info-cell strong {
    display: block;
    font-size: 0.75rem;
    text-transform: uppercase;
    color: var(--sap-text-muted);
    letter-spacing: 0.5px;
    margin-bottom: 4px;
    font-weight: 600;
}

.sap-info-cell-value {
    color: var(--sap-text-main);
    font-weight: 600;
}

/* SAP Responsive Standard Layout Table View */
.sap-table-view {
    padding: 1rem 1.5rem;
    background: #ffffff;
}

.sap-fiori-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.875rem;
    background: #ffffff;
    border: 1px solid var(--sap-border-color);
}

.sap-fiori-table th {
    background: var(--sap-strip-bg);
    color: var(--sap-text-muted);
    padding: 0.75rem 1rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-bottom: 2px solid var(--sap-border-color);
    font-size: 0.75rem;
    text-align: left;
}

.sap-fiori-table td {
    padding: 0.85rem 1rem;
    border-bottom: 1px solid var(--sap-border-color);
    color: var(--sap-text-main);
    vertical-align: middle;
}

.sap-fiori-table tbody tr:last-child td { border-bottom: none; }
.sap-fiori-table tbody tr:hover { background-color: #f7f9fa; }

.sap-fiori-table td.cell-qordered,
.sap-fiori-table td.cell-qreceived,
.sap-fiori-table td.cell-qaccepted,
.sap-fiori-table td.cell-qrejected {
    text-align: center;
    font-weight: 600;
}

.sap-fiori-table td.cell-qaccepted { color: var(--sap-success); }
.sap-fiori-table td.cell-qrejected { color: var(--sap-critical); }

/* SAP Functional Status Badges */
.sap-status-badge {
    font-size: 0.75rem;
    padding: 0.2rem 0.6rem;
    border-radius: 0.75rem;
    font-weight: 600;
    display: inline-block;
    border: 1px solid transparent;
}
.status-completed {
    background: var(--sap-success-bg);
    color: var(--sap-success);
    border-color: var(--sap-success-border);
}
.status-pending {
    background: var(--sap-warning-bg);
    color: var(--sap-warning);
    border-color: var(--sap-warning-border);
}

.hidden { display: none !important; }

/* SAP Adaptive Micro-Layout Media Handlers */
@media (max-width: 1024px) {
    .main-content { padding: 1rem; }
    
    .sap-filter-bar {
        flex-direction: column;
        align-items: stretch;
        gap: 0.85rem;
        padding: 1rem;
    }

    .sap-filter-group { width: 100%; }
    .sap-filter-bar .input, .sap-btn { width: 100%; }
    
    .sap-card-header { padding: 1rem; gap: 0.85rem; }
    .sap-card-header-left { width: 100%; }
    .sap-card-header-actions { width: 100%; }
    .sap-info-matrix { padding: 1rem; gap: 0.85rem; }

    .sap-table-view { padding: 1rem; }
    
    .sap-fiori-table, 
    .sap-fiori-table thead, 
    .sap-fiori-table tbody, 
    .sap-fiori-table th, 
    .sap-fiori-table td, 
    .sap-fiori-table tr {
        display: block;
        width: 100%;
    }

    .sap-fiori-table thead tr { display: none; }

    .sap-fiori-table tr {
        border: 1px solid var(--sap-border-color);
        border-radius: var(--sap-radius);
        margin-bottom: 0.75rem;
        padding: 0.5rem 0;
    }
    .sap-fiori-table tr:last-child { margin-bottom: 0; }

    .sap-fiori-table td,
    .sap-fiori-table td.cell-qordered,
    .sap-fiori-table td.cell-qreceived,
    .sap-fiori-table td.cell-qaccepted,
    .sap-fiori-table td.cell-qrejected {
        text-align: right;
        padding: 0.6rem 1rem;
        position: relative;
        border: none;
        border-bottom: 1px solid var(--sap-background);
        font-size: 0.85rem;
    }
    .sap-fiori-table td:last-child { border-bottom: none; }

    .sap-fiori-table td:before {
        content: attr(data-label);
        position: absolute;
        left: 1rem;
        width: 45%;
        font-weight: 600;
        text-align: left;
        color: var(--sap-text-muted);
        white-space: nowrap;
        font-size: 0.75rem;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
}
</style>

<script>
function parseDate(s) { 
    if (!s) return null; 
    if (s instanceof Date) return s; 
    s = String(s).trim(); 
    var dashCount = (s.match(/-/g) || []).length; 
    var slashCount = (s.match(/\//g) || []).length; 
    if (dashCount === 2 && /^\d{2}-\d{2}-\d{4}$/.test(s)) { 
        var parts = s.split("-"); 
        s = parts[2]+"-"+parts[1]+"-"+parts[0]; 
    } else if (slashCount === 2 && /^\d{2}\/\d{2}\/\d{4}$/.test(s)) { 
        var parts = s.split("/"); 
        s = parts[2]+"-"+parts[1]+"-"+parts[0]; 
    } 
    var d = new Date(s); 
    return isNaN(d.getTime())?null:d; 
}

function filterGRNs() { 
    var poInput=document.getElementById('filter_po').value.trim().toLowerCase(); 
    var fromDateVal=document.getElementById('filter_from').value; 
    var toDateVal=document.getElementById('filter_to').value; 
    var fromDate=fromDateVal?new Date(fromDateVal):null; 
    var toDate=toDateVal?new Date(toDateVal):null; 
    if(toDate) toDate.setHours(23,59,59,999); 
    var cards=document.querySelectorAll('.grn-card'); 
    cards.forEach(function(card){ 
        var po=(card.getAttribute('data-po')||'').toLowerCase(); 
        var dateStr=card.getAttribute('data-date')||''; 
        var grnDate=parseDate(dateStr); 
        var poMatch=!poInput || po.indexOf(poInput)!==-1; 
        var dateMatch=true; 
        if(fromDate && grnDate) dateMatch=grnDate>=fromDate; 
        if(toDate && grnDate) dateMatch=dateMatch && (grnDate<=toDate); 
        if((fromDate && !grnDate)||(toDate && !grnDate)) dateMatch=false; 
        if(poMatch && dateMatch) card.classList.remove('hidden'); 
        else card.classList.add('hidden'); 
    }); 
    document.getElementById('visible_count').innerText=document.querySelectorAll('.grn-card:not(.hidden)').length; 
}

function toggleItems(id){
    var section=document.getElementById('items_'+id); 
    if(!section)return; 
    section.style.display=(section.style.display==='none'||section.style.display==='')?'block':'none';
}

function expandAll(){document.querySelectorAll('.grn-card:not(.hidden) .sap-table-view').forEach(c=>c.style.display='block');}
function collapseAll(){document.querySelectorAll('.grn-card .sap-table-view').forEach(c=>c.style.display='none');}
function csvSafe(s){if(s===null||s===undefined)return'';var str=String(s);if(str.indexOf('"')!==-1) str=str.replace(/"/g,'""'); if(str.search(/("|,|\n)/g)!==-1) str='"'+str+'"'; return str;}

function downloadCSV(){ 
    var rows=[]; 
    rows.push(['GRN No','GRN Date','Vendor Name','Vendor GSTIN','Address','PO Number','Invoice No','Invoice Date','Received By','GRN Remarks','Item Description','Qty Ordered','Qty Received','Qty Accepted','Qty Rejected','Item Remarks'].join(',')); 
    var visibleCards=document.querySelectorAll('.grn-card:not(.hidden)'); 
    if(visibleCards.length===0){ alert('No visible GRNs to download.'); return;} 
    visibleCards.forEach(function(card){ 
        var meta={ 
            grnNo:card.getAttribute('data-grn')||'', 
            grnDate:card.getAttribute('data-date')||'', 
            vendor:card.getAttribute('data-vendor')||'', 
            gstin:card.getAttribute('data-gstin')||'', 
            address:card.getAttribute('data-address')||'', 
            po:card.getAttribute('data-po')||'', 
            invoiceNo:card.getAttribute('data-invoice')||'', 
            invoiceDate:card.getAttribute('data-invdate')||'', 
            receivedBy:card.getAttribute('data-receivedby')||'', 
            grnRemarks:card.getAttribute('data-remarks')||'' 
        }; 
        var itemRows=card.querySelectorAll('.sap-fiori-table tbody tr.item-row'); 
        if(itemRows.length===0){ 
            rows.push([csvSafe(meta.grnNo),csvSafe(meta.grnDate),csvSafe(meta.vendor),csvSafe(meta.gstin),csvSafe(meta.address),csvSafe(meta.po),csvSafe(meta.invoiceNo),csvSafe(meta.invoiceDate),csvSafe(meta.receivedBy),csvSafe(meta.grnRemarks),'','','','','',''].join(',')); 
        }else{ 
            itemRows.forEach(function(ir){ 
                rows.push([
                    csvSafe(meta.grnNo),csvSafe(meta.grnDate),csvSafe(meta.vendor),csvSafe(meta.gstin),csvSafe(meta.address),csvSafe(meta.po),csvSafe(meta.invoiceNo),csvSafe(meta.invoiceDate),csvSafe(meta.receivedBy),csvSafe(meta.grnRemarks),
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
    var csvContent=rows.join('\n'); 
    var blob=new Blob([csvContent], {type:'text/csv;charset=utf-8;'}); 
    var url=URL.createObjectURL(blob); 
    var a=document.createElement('a'); 
    a.href=url; 
    var ts=new Date(); 
    a.download='GRN_export_'+ts.getFullYear()+('0'+(ts.getMonth()+1)).slice(-2)+('0'+ts.getDate()).slice(-2)+'_'+('0'+ts.getHours()).slice(-2)+('0'+ts.getMinutes()).slice(-2)+'.csv'; 
    document.body.appendChild(a); 
    a.click(); 
    document.body.removeChild(a); 
    URL.revokeObjectURL(url);
}

document.addEventListener('DOMContentLoaded', function(){ 
    document.getElementById('filter_po').addEventListener('input',filterGRNs); 
    document.getElementById('filter_from').addEventListener('change',filterGRNs); 
    document.getElementById('filter_to').addEventListener('change',filterGRNs); 
    document.getElementById('btn_expand_all').addEventListener('click',expandAll); 
    document.getElementById('btn_collapse_all').addEventListener('click',collapseAll); 
    document.getElementById('btn_download_csv').addEventListener('click',downloadCSV); 
    filterGRNs();
});

function printGRN(grnNo){
    if(!grnNo){
        alert("Invalid GRN Number");
        return;
    }
    window.open("PrintGRN.jsp?grnNo=" + encodeURIComponent(grnNo), "_blank");
}
</script>
</head>

<body>
<%@ include file="header.jsp" %>

<div class="sap-fiori-page-header">
    <div class="sap-header-left">
        <div class="sap-icon-wrapper"><i class="fa-solid fa-boxes-packing"></i></div>
        <div>
            <h2>All GRN Details</h2>
            <div class="meta">Goods Receipt Register Records</div>
        </div>
    </div>
    <div class="sap-counter-badge">
        Visible Records: <b id="visible_count">0</b>
    </div>
</div>

<div class="main-content">

    <div class="sap-filter-bar">
        <div class="sap-filter-group" style="flex:1; min-width:220px;">
            <label>Search PO Number</label>
            <input id="filter_po" class="input" type="text" placeholder="Enter PO ID...">
        </div>
        <div class="sap-filter-group">
            <label>From Date</label>
            <input id="filter_from" class="input" type="date">
        </div>
        <div class="sap-filter-group">
            <label>To Date</label>
            <input id="filter_to" class="input" type="date">
        </div>
        
        <button id="btn_expand_all" class="sap-btn sap-btn-transparent"><i class="fa fa-angles-down"></i> Expand All</button>
        <button id="btn_collapse_all" class="sap-btn sap-btn-ghost"><i class="fa fa-angles-up"></i> Collapse All</button>
        <button id="btn_download_csv" class="sap-btn sap-btn-success"><i class="fa fa-file-excel"></i> Download CSV</button>
    </div>

    <%
    if(request.getAttribute("error") != null){
        out.println("<p style='color:var(--sap-critical); font-weight:600; padding:12px; background:#fff5f5; border-radius:var(--sap-radius); border:1px solid rgba(187,0,0,0.15); font-size:0.875rem;'>"+request.getAttribute("error")+"</p>");
        return;
    }
    List<Map<String,Object>> allGRNs=(List<Map<String,Object>>)request.getAttribute("all_grns");
    if(allGRNs==null || allGRNs.isEmpty()){
        out.println("<p style='padding:40px; text-align:center; color:var(--sap-text-muted); font-weight:500; font-size:0.875rem;'>No GRN records found within the system data container.</p>");
        return;
    }
    int index=1;
    for(Map<String,Object> grn:allGRNs){
        String grnNo=grn.get("grn_no")==null?"":grn.get("grn_no").toString();
        String grnDate=grn.get("grn_date")==null?"":grn.get("grn_date").toString();
        String vendor=grn.get("vendor_name")==null?"":grn.get("vendor_name").toString();
        String gstin=grn.get("vendor_gstin")==null?"":grn.get("vendor_gstin").toString();
        String address=grn.get("vendor_address")==null?"":grn.get("vendor_address").toString();
        String poNumber = grn.get("po_number")==null?"":grn.get("po_number").toString();
        String invoiceNo=grn.get("invoice_no")==null?"":grn.get("invoice_no").toString();
        String invoiceDate=grn.get("invoice_date")==null?"":grn.get("invoice_date").toString();
        String receivedBy=grn.get("received_by")==null?"":grn.get("received_by").toString();
        String remarks=grn.get("remarks")==null?"":grn.get("remarks").toString();
        String status=grn.get("status")==null?"completed":grn.get("status").toString();
    %>

    <div class="sap-object-container grn-card" data-grn="<%=grnNo%>" data-date="<%=grnDate%>" data-vendor="<%=vendor%>" data-gstin="<%=gstin%>" data-address="<%=address%>" data-po="<%=poNumber%>" data-invoice="<%=invoiceNo%>" data-invdate="<%=invoiceDate%>" data-receivedby="<%=receivedBy%>" data-remarks="<%=remarks%>">
        
        <div class="sap-card-header">
            <div class="sap-card-header-left">
                <div class="sap-grn-id">GRN <b><%=grnNo%></b></div>
                <div class="sap-date-indicator"><i class="fa fa-calendar"></i> <%=grnDate%></div>
                <span class="sap-status-badge <%=status.equalsIgnoreCase("completed")?"status-completed":"status-pending"%>">
                    <%=status.substring(0,1).toUpperCase()+status.substring(1)%>
                </span>
                <div class="sap-subline-entity">
                    <i class="fa fa-building" style="color: var(--sap-text-muted);"></i> <%=vendor%> &nbsp;•&nbsp; PO ID: <b><%=poNumber%></b>
                </div>
            </div>
            <div class="sap-card-header-actions">
                <button class="sap-btn sap-btn-ghost" onclick="toggleItems('<%=index%>')">
                    <i class="fa fa-eye"></i> Items
                </button>
                <button class="sap-btn sap-btn-primary" onclick="printGRN('<%=grnNo%>')">
                    <i class="fa fa-print"></i> Print
                </button>
            </div>
        </div>

        <div class="sap-info-matrix">
            <div class="sap-info-cell"><strong>Invoice Reference</strong><div class="sap-info-cell-value"><%=invoiceNo%> (<%=invoiceDate%>)</div></div>
            <div class="sap-info-cell"><strong>Vendor GSTIN</strong><div class="sap-info-cell-value"><%=gstin%></div></div>
            <div class="sap-info-cell"><strong>Received By Staff</strong><div class="sap-info-cell-value"><%=receivedBy%></div></div>
            <div class="sap-info-cell"><strong>GRN Remarks / Notes</strong><div class="sap-info-cell-value" style="font-weight:400; color:var(--sap-text-muted);"><%=remarks.isEmpty() ? "-" : remarks%></div></div>
        </div>

        <div id="items_<%=index%>" class="sap-table-view" style="display:none">
            <table class="sap-fiori-table">
                <thead>
                    <tr>
                        <th style="width:35%;">Item Description</th>
                        <th style="width:11%; text-align:center;">Qty Ordered</th>
                        <th style="width:11%; text-align:center;">Qty Received</th>
                        <th style="width:11%; text-align:center;">Qty Accepted</th>
                        <th style="width:11%; text-align:center;">Qty Rejected</th>
                        <th style="width:21%;">Remarks</th>
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
                        <td data-label="Item Description" class="cell-desc" style="font-weight:600;"><%=desc%></td>
                        <td data-label="Qty Ordered" class="cell-qordered"><%=qordered%></td>
                        <td data-label="Qty Received" class="cell-qreceived"><%=qreceived%></td>
                        <td data-label="Qty Accepted" class="cell-qaccepted"><%=qaccepted%></td>
                        <td data-label="Qty Rejected" class="cell-qrejected"><%=qrejected%></td>
                        <td data-label="Remarks" class="cell-remarks" style="color: var(--sap-text-muted);"><%=iremarks.isEmpty() ? "-" : iremarks%></td>
                    </tr>
                <%
                    }
                } else {
                %>
                    <tr><td colspan="6" style="text-align:center; color:var(--sap-text-muted); padding:20px; font-weight:500;">No structural line items cataloged inside this voucher segment.</td></tr>
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

</div>
</body>
</html>