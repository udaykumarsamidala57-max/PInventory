<%@ page import="java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
<title>GRN Details</title>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
* { box-sizing: border-box; }
:root {
    --slds-brand: #0176d3;
    --slds-brand-hover: #015a9e;
    --slds-text-main: #181818;
    --slds-text-muted: #5a6065;
    --slds-border: #e1e4e8;
    --slds-border-dark: #aeaeae;
    --slds-bg-page: #f3f4f6;
    --slds-bg-card: #ffffff;
    --slds-bg-strip: #f8f9fa;
    --slds-success: #1a7f37;
    --slds-success-border: #acf2bd;
    --slds-success-bg: #dafbe1;
    --slds-warning: #9a6700;
    --slds-warning-border: #f9e2af;
    --slds-warning-bg: #fef5e7;
    --radius-sm: 6px;
    --radius-md: 8px;
    --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.05), 0 1px 2px rgba(0, 0, 0, 0.03);
    --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
    --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.02);
}

body {
    font-family: 'Poppins', sans-serif;
    background-color: var(--slds-bg-page);
    margin: 0;
    padding: 0;
    color: var(--slds-text-main);
    -webkit-tap-highlight-color: transparent;
    letter-spacing: -0.01em;
}

.main-content {
    width: 100%;
    max-width: 1400px;
    margin: 0 auto;
    padding: 24px;
}

/* Master Card Container */
.master-card {
    background: var(--slds-bg-card);
    border-radius: var(--radius-md);
    padding: 28px;
    width: 100%;
    border: 1px solid var(--slds-border);
    box-shadow: var(--shadow-md);
}

/* Header Section */
.header-area {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 20px;
    margin-bottom: 24px;
    padding-bottom: 20px;
    border-bottom: 1px solid var(--slds-border);
    flex-wrap: wrap;
}

.header-left-group {
    display: flex;
    align-items: center;
    gap: 16px;
}

.icon-box {
    width: 46px;
    height: 46px;
    border-radius: var(--radius-sm);
    background: linear-gradient(135deg, var(--slds-brand), var(--slds-brand-hover));
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 20px;
    box-shadow: 0 2px 4px rgba(1, 118, 211, 0.2);
}

h2 {
    margin: 0;
    font-size: 22px;
    color: var(--slds-text-main);
    font-weight: 700;
    letter-spacing: -0.02em;
}

.meta {
    color: var(--slds-text-muted);
    font-size: 13px;
    margin-top: 3px;
}

.record-counter-badge {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    background: var(--slds-bg-page);
    padding: 6px 14px;
    border-radius: 20px;
    border: 1px solid var(--slds-border);
    font-size: 13px;
    font-weight: 500;
    color: var(--slds-text-muted);
}

.record-counter-badge b {
    color: var(--slds-brand);
    font-size: 16px;
}

/* Dynamic Filter Bar Row Layout */
.filter-bar {
    background: var(--slds-bg-strip);
    border: 1px solid var(--slds-border);
    border-radius: var(--radius-md);
    padding: 20px;
    margin-bottom: 24px;
    display: flex;
    flex-wrap: wrap;
    gap: 16px;
    align-items: flex-end;
}

.filter-group {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.filter-bar label {
    font-size: 11px;
    font-weight: 700;
    color: var(--slds-text-muted);
    text-transform: uppercase;
    letter-spacing: 0.8px;
}

.filter-bar .input {
    height: 38px;
    padding: 0 14px;
    border: 1px solid var(--slds-border-dark);
    border-radius: var(--radius-sm);
    font-family: inherit;
    font-size: 13px;
    background: #ffffff;
    color: var(--slds-text-main);
    outline: none;
    min-width: 220px;
    transition: all 0.15s ease;
}

.filter-bar .input:focus {
    border-color: var(--slds-brand);
    box-shadow: 0 0 0 3px rgba(1, 118, 211, 0.15);
}

/* Button Elements */
.btn {
    height: 38px;
    padding: 0 18px;
    border: 1px solid var(--slds-brand);
    background: var(--slds-brand);
    color: white;
    border-radius: var(--radius-sm);
    cursor: pointer;
    font-size: 13px;
    font-weight: 600;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    transition: all 0.15s ease;
    white-space: nowrap;
}

.btn:hover { 
    background: var(--slds-brand-hover); 
    border-color: var(--slds-brand-hover);
    transform: translateY(-1px);
}
.btn:active { transform: translateY(0); }

.btn.secondary {
    background: #ffffff;
    border-color: var(--slds-border-dark);
    color: var(--slds-text-main);
}
.btn.secondary:hover { 
    background: var(--slds-bg-strip); 
    border-color: #747472; 
}

.btn.success {
    background: var(--slds-success);
    border-color: var(--slds-success);
}
.btn.success:hover { 
    background: #146229; 
    border-color: #146229; 
}

.btn.small { 
    height: 34px; 
    padding: 0 14px; 
    font-size: 12px; 
    border-radius: var(--radius-sm);
}

/* GRN Block Card Enclosure */
.container {
    border: 1px solid var(--slds-border);
    border-radius: var(--radius-md);
    background: var(--slds-bg-card);
    margin-bottom: 20px;
    box-shadow: var(--shadow-sm);
    transition: all 0.2s ease;
    overflow: hidden;
}
.container:hover { 
    box-shadow: var(--shadow-lg);
    border-color: #ccd1d9;
}

/* Card Header Strip Row */
.title {
    background: #ffffff;
    border-bottom: 1px solid var(--slds-border);
    padding: 18px 24px;
    display: flex;
    flex-wrap: wrap;
    gap: 16px;
    align-items: center;
    justify-content: space-between;
}

.title-left {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 14px;
}

.grn-label {
    font-size: 16px;
    font-weight: 700;
    color: var(--slds-text-main);
}

.grn-label b {
    color: var(--slds-brand);
}

.date-badge {
    color: var(--slds-text-muted);
    font-weight: 500;
    font-size: 13px;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    background: var(--slds-bg-page);
    padding: 3px 10px;
    border-radius: 4px;
}

.vendor-subline {
    font-size: 13px;
    color: var(--slds-text-muted);
    font-weight: 400;
    width: 100%;
    margin-top: 4px;
    display: flex;
    align-items: center;
    gap: 6px;
}

.vendor-subline b {
    color: var(--slds-text-main);
    font-weight: 600;
}

.controls-right {
    display: flex;
    gap: 10px;
    align-items: center;
}

/* Metadata Info Grid */
.info-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    gap: 16px;
    padding: 20px 24px;
    background: var(--slds-bg-strip);
    border-bottom: 1px solid var(--slds-border);
}

.info-card {
    background: #ffffff;
    padding: 12px 16px;
    border-radius: var(--radius-sm);
    border: 1px solid var(--slds-border);
    font-size: 13px;
    box-shadow: inset 0 1px 2px rgba(0,0,0,0.01);
}

.info-card strong {
    display: block;
    font-size: 10px;
    text-transform: uppercase;
    color: var(--slds-text-muted);
    letter-spacing: 0.8px;
    margin-bottom: 6px;
    font-weight: 700;
}

.info-card-text {
    color: var(--slds-text-main);
    font-weight: 600;
}

/* Table Data Container Component */
.items-container {
    padding: 20px 24px;
    background: #ffffff;
}

.items-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
    table-layout: auto;
    background: #ffffff;
    border: 1px solid var(--slds-border);
    border-radius: var(--radius-sm);
    overflow: hidden;
}

.items-table th {
    background: var(--slds-bg-strip);
    color: var(--slds-text-muted);
    padding: 14px 16px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.8px;
    border-bottom: 2px solid var(--slds-border);
    font-size: 11px;
    text-align: left;
}

.items-table td {
    padding: 14px 16px;
    border-bottom: 1px solid var(--slds-border);
    color: var(--slds-text-main);
    vertical-align: middle;
}

.items-table tbody tr:last-child td { border-bottom: none; }
.items-table tbody tr:hover { background-color: #fafdff; }

.items-table td.cell-qordered,
.items-table td.cell-qreceived,
.items-table td.cell-qaccepted,
.items-table td.cell-qrejected {
    text-align: center;
    font-weight: 600;
}

.items-table td.cell-qaccepted { color: var(--slds-success); }
.items-table td.cell-qrejected { color: #d9381e; }

/* Status Badges */
.status-badge {
    font-size: 11px;
    padding: 3px 12px;
    border-radius: 12px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.8px;
    display: inline-block;
    border: 1px solid transparent;
}
.status-completed {
    background: var(--slds-success-bg);
    color: var(--slds-success);
    border-color: var(--slds-success-border);
}
.status-pending {
    background: var(--slds-warning-bg);
    color: var(--slds-warning);
    border-color: var(--slds-warning-border);
}

.hidden { display: none !important; }

/* Handheld Layout Refactor Rules */
@media (max-width: 1024px) {
    .master-card { padding: 16px; }
    
    .filter-bar {
        flex-direction: column;
        align-items: stretch;
        gap: 12px;
        padding: 16px;
    }

    .filter-group { width: 100%; }
    .filter-bar .input, .btn { width: 100%; height: 42px; }
    
    .title { padding: 16px; gap: 14px; }
    .title-left { width: 100%; }
    .controls-right { width: 100%; justify-content: flex-start; }
    .info-grid { padding: 16px; gap: 12px; }

    .items-container { padding: 16px; }
    
    .items-table, 
    .items-table thead, 
    .items-table tbody, 
    .items-table th, 
    .items-table td, 
    .items-table tr {
        display: block;
        width: 100%;
    }

    .items-table thead tr { display: none; }

    .items-table tr {
        border: 1px solid var(--slds-border);
        border-radius: var(--radius-sm);
        margin-bottom: 12px;
        padding: 8px 0;
        box-shadow: var(--shadow-sm);
    }
    .items-table tr:last-child { margin-bottom: 0; }

    .items-table td,
    .items-table td.cell-qordered,
    .items-table td.cell-qreceived,
    .items-table td.cell-qaccepted,
    .items-table td.cell-qrejected {
        text-align: right;
        padding: 10px 16px;
        position: relative;
        border: none;
        border-bottom: 1px solid #f3f4f6;
        font-size: 13px;
    }
    .items-table td:last-child { border-bottom: none; }

    .items-table td:before {
        content: attr(data-label);
        position: absolute;
        left: 16px;
        width: 45%;
        font-weight: 700;
        text-align: left;
        color: var(--slds-text-muted);
        white-space: nowrap;
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.6px;
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

function expandAll(){document.querySelectorAll('.grn-card:not(.hidden) .items-container').forEach(c=>c.style.display='block');}
function collapseAll(){document.querySelectorAll('.grn-card .items-container').forEach(c=>c.style.display='none');}
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
        var itemRows=card.querySelectorAll('.items-table tbody tr.item-row'); 
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

<div class="main-content">
    <div class="master-card">
        
        <div class="header-area">
            <div class="header-left-group">
                <div class="icon-box"><i class="fa fa-file-invoice"></i></div>
                <div>
                    <h2>All GRN Details</h2>
                    <div class="meta">Goods Receipt Register Records</div>
                </div>
            </div>
            <div class="record-counter-badge">
                Visible Records: <b id="visible_count">0</b>
            </div>
        </div>

        <div class="filter-bar">
            <div class="filter-group" style="flex:1; min-width:220px;">
                <label>Search PO Number</label>
                <input id="filter_po" class="input" type="text" placeholder="Enter PO ID...">
            </div>
            <div class="filter-group">
                <label>From Date</label>
                <input id="filter_from" class="input" type="date">
            </div>
            <div class="filter-group">
                <label>To Date</label>
                <input id="filter_to" class="input" type="date">
            </div>
            
            <button id="btn_expand_all" class="btn small primary"><i class="fa fa-angles-down"></i> Expand All</button>
            <button id="btn_collapse_all" class="btn small secondary"><i class="fa fa-angles-up"></i> Collapse All</button>
            <button id="btn_download_csv" class="btn small success"><i class="fa fa-file-excel"></i> Download CSV</button>
        </div>

        <%
        if(request.getAttribute("error") != null){
            out.println("<p style='color:#d9381e; font-weight:600; padding:12px; background:#fdedec; border-radius:var(--radius-sm); border:1px solid #fadbd8;'>"+request.getAttribute("error")+"</p>");
            return;
        }
        List<Map<String,Object>> allGRNs=(List<Map<String,Object>>)request.getAttribute("all_grns");
        if(allGRNs==null || allGRNs.isEmpty()){
            out.println("<p style='padding:40px; text-align:center; color:var(--slds-text-muted); font-weight:600; font-size:14px;'>No GRN records found within the system data container.</p>");
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
            String status=grn.get("status")==null?"completed":grn.get("status").toString();
        %>

        <div class="container grn-card" data-grn="<%=grnNo%>" data-date="<%=grnDate%>" data-vendor="<%=vendor%>" data-gstin="<%=gstin%>" data-address="<%=address%>" data-po="<%=poId%>" data-invoice="<%=invoiceNo%>" data-invdate="<%=invoiceDate%>" data-receivedby="<%=receivedBy%>" data-remarks="<%=remarks%>">
            
            <div class="title">
                <div class="title-left">
                    <div class="grn-label">GRN <b><%=grnNo%></b></div>
                    <div class="date-badge"><i class="fa fa-calendar"></i> <%=grnDate%></div>
                    <span class="status-badge <%=status.equalsIgnoreCase("completed")?"status-completed":"status-pending"%>">
                        <%=status.substring(0,1).toUpperCase()+status.substring(1)%>
                    </span>
                    <div class="vendor-subline">
                        <i class="fa fa-building" style="color: var(--slds-text-muted);"></i> <%=vendor%> &nbsp;•&nbsp; PO ID: <b><%=poId%></b>
                    </div>
                </div>
                <div class="controls-right">
                    <button class="btn small secondary" onclick="toggleItems('<%=index%>')">
                        <i class="fa fa-eye"></i> Items
                    </button>
                    <button class="btn small primary" onclick="printGRN('<%=grnNo%>')">
                        <i class="fa fa-print"></i> Print
                    </button>
                </div>
            </div>

            <div class="info-grid">
                <div class="info-card"><strong>Invoice Reference</strong><div class="info-card-text"><%=invoiceNo%> (<%=invoiceDate%>)</div></div>
                <div class="info-card"><strong>Vendor GSTIN</strong><div class="info-card-text"><%=gstin%></div></div>
                <div class="info-card"><strong>Received By Staff</strong><div class="info-card-text"><%=receivedBy%></div></div>
                <div class="info-card"><strong>GRN Remarks / Notes</strong><div class="info-card-text" style="font-weight:400; color:var(--slds-text-muted);"><%=remarks.isEmpty() ? "-" : remarks%></div></div>
            </div>

            <div id="items_<%=index%>" class="items-container" style="display:none">
                <table class="items-table">
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
                            <td data-label="Remarks" class="cell-remarks" style="color: var(--slds-text-muted);"><%=iremarks.isEmpty() ? "-" : iremarks%></td>
                        </tr>
                    <%
                        }
                    } else {
                    %>
                        <tr><td colspan="6" style="text-align:center; color:var(--slds-text-muted); padding:20px; font-weight:500;">No structural line items cataloged inside this voucher segment.</td></tr>
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
</div>
</body>
</html>