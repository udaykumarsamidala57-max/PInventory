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
    --slds-text-muted: #514f4d;
    --slds-border: #c9c9c9;
    --slds-bg-page: #f3f3f3;
    --slds-bg-card: #ffffff;
    --slds-bg-strip: #fafaf9;
    --slds-success: #2e844a;
    --slds-success-border: #a7f3d0;
    --slds-success-bg: #eefbee;
    --slds-warning: #b45309;
    --slds-warning-border: #fde68a;
    --slds-warning-bg: #fef3c7;
}

body {
    font-family: 'Poppins', sans-serif;
    background-color: var(--slds-bg-page);
    margin: 0;
    padding: 0;
    color: var(--slds-text-main);
    -webkit-tap-highlight-color: transparent;
}

.main-content {
    width: 100%;
    max-width: 100%;
    margin: 0 auto;
    padding: 20px;
}

/* Master Salesforce Card Container */
.master-card {
    background: var(--slds-bg-card);
    border-radius: 4px;
    padding: 24px;
    width: 100%;
    border: 1px solid var(--slds-border);
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
    overflow: visible; 
}

/* Header Context Section */
.header-area {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    margin-bottom: 24px;
    border-bottom: 1px solid #e5e5e5;
    padding-bottom: 16px;
    flex-wrap: wrap;
}

.header-left-group {
    display: flex;
    align-items: center;
    gap: 12px;
}

.icon-box {
    width: 40px;
    height: 40px;
    border-radius: 4px;
    background: var(--slds-brand);
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 18px;
}

h2 {
    margin: 0;
    font-size: 20px;
    color: var(--slds-brand);
    font-weight: 700;
}

.meta {
    color: var(--slds-text-muted);
    font-size: 13px;
    margin-top: 2px;
}

/* Salesforce Dynamic Control Bar Grid */
.filter-bar {
    background: var(--slds-bg-strip);
    border: 1px solid var(--slds-border);
    border-radius: 4px;
    padding: 16px;
    margin-bottom: 8px;
    display: flex;
    flex-wrap: wrap;
    gap: 14px;
    align-items: flex-end;
}

.filter-group {
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.filter-bar label {
    font-size: 11px;
    font-weight: 700;
    color: var(--slds-text-muted);
    text-transform: uppercase;
    letter-spacing: 0.5px;
    white-space: nowrap;
}

.filter-bar .input {
    height: 36px;
    padding: 0 12px;
    border: 1px solid #aeaeae;
    border-radius: 4px;
    font-family: inherit;
    font-size: 13px;
    background: #ffffff;
    outline: none;
    min-width: 160px;
}

.filter-bar .input:focus {
    border-color: var(--slds-brand);
    box-shadow: 0 0 0 2px rgba(1,118,211,0.15);
}

/* Button UI Components */
.btn {
    height: 36px;
    padding: 0 16px;
    border: 1px solid var(--slds-brand);
    background: var(--slds-brand);
    color: white;
    border-radius: 4px;
    cursor: pointer;
    font-size: 13px;
    font-weight: 600;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    transition: all 0.1s ease;
    white-space: nowrap;
}

.btn:hover { background: var(--slds-brand-hover); border-color: var(--slds-brand-hover); }

.btn.secondary {
    background: #ffffff;
    border-color: var(--slds-border);
    color: var(--slds-text-main);
}
.btn.secondary:hover { background: #f4f6f9; border-color: #747472; }

.btn.success {
    background: var(--slds-success);
    border-color: var(--slds-success);
}
.btn.success:hover { background: #1b5e30; border-color: #1b5e30; }

.btn.small { height: 32px; padding: 0 12px; font-size: 12px; }

/* GRN Block Card Enclosure */
.container {
    border: 1px solid var(--slds-border);
    border-radius: 4px;
    background: var(--slds-bg-card);
    margin-bottom: 24px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    overflow: visible;
    padding: 0;
}
.container:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.08); }

/* Block Strip Header Row */
.title {
    background: var(--slds-bg-strip);
    border-bottom: 1px solid var(--slds-border);
    padding: 14px 20px;
    display: flex;
    flex-wrap: wrap;
    gap: 20px;
    align-items: center;
    justify-content: space-between;
}

.title-left {
    font-size: 15px;
    font-weight: 700;
    color: var(--slds-brand);
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 12px;
}

.controls-right {
    display: flex;
    gap: 8px;
    align-items: center;
}

/* Contextual Metadata Information Grid */
.info-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 16px;
    padding: 16px 20px;
    background: #ffffff;
    border-bottom: 1px solid #e5e5e5;
}

.info-card {
    background: #ffffff;
    padding: 10px 12px;
    border-radius: 4px;
    border: 1px solid #e5e5e5;
    font-size: 13px;
}

.info-card strong {
    display: block;
    font-size: 11px;
    text-transform: uppercase;
    color: var(--slds-text-muted);
    letter-spacing: 0.5px;
    margin-bottom: 4px;
}

.info-card-text {
    color: var(--slds-text-main);
    font-weight: 500;
}

/* Master Nested Table Data Grid */
.items-container {
    padding: 16px 20px;
    background: #fafaf9;
}

.items-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
    table-layout: auto;
    background: #ffffff;
    border: 1px solid var(--slds-border);
    border-radius: 4px;
}

.items-table th {
    background: var(--slds-bg-strip);
    color: var(--slds-text-muted);
    padding: 12px 10px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-bottom: 2px solid var(--slds-border);
    font-size: 11px;
    text-align: left;
}

.items-table td {
    padding: 12px 10px;
    border-bottom: 1px solid #e5e5e5;
    color: var(--slds-text-main);
    vertical-align: middle;
}

.items-table tbody tr:last-child td { border-bottom: none; }
.items-table tbody tr:hover { background-color: #f8fafc; }

.items-table td.cell-qordered,
.items-table td.cell-qreceived,
.items-table td.cell-qaccepted,
.items-table td.cell-qrejected {
    text-align: center;
    font-weight: 500;
}

.items-table td.cell-qaccepted { color: var(--slds-success); font-weight: 600; }
.items-table td.cell-qrejected { color: #c23934; font-weight: 600; }

/* Standard Status Badge System */
.status-badge {
    font-size: 11px;
    padding: 2px 10px;
    border-radius: 12px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
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

/* Structural Laptop Protections & Mobile Layout Refactor */
@media (max-width: 1024px) {
    .master-card { padding: 16px; }
    
    .filter-bar {
        flex-direction: column;
        align-items: stretch;
        gap: 12px;
        padding: 12px;
    }

    .filter-group { width: 100%; }
    .filter-bar .input, .btn { width: 100%; height: 40px; }
    
    .title { padding: 12px 16px; gap: 14px; }
    .title-left { width: 100%; }
    .controls-right { width: 100%; justify-content: flex-start; }
    .info-grid { padding: 12px 16px; }

    /* Convert inner grid items list on handheld layouts */
    .items-container { padding: 12px 16px; }
    
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
        border-bottom: 1px solid var(--slds-border);
        padding: 10px 0;
        background: #ffffff;
    }
    .items-table tr:last-child { border-bottom: none; }

    .items-table td,
    .items-table td.cell-qordered,
    .items-table td.cell-qreceived,
    .items-table td.cell-qaccepted,
    .items-table td.cell-qrejected {
        text-align: right;
        padding: 8px 16px;
        position: relative;
        border: none;
        border-bottom: 1px solid #f3f3f3;
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
                    <div class="meta">Filter, Expand, & Export Central Goods Receipt Register Records</div>
                </div>
            </div>
            <div style="font-size:13px; color:var(--slds-text-muted); font-weight: 500;">
                Visible Records: <b id="visible_count" style="color:var(--slds-brand); font-size:15px;">0</b>
            </div>
        </div>

        <div class="filter-bar">
            <div class="filter-group" style="flex:1; min-width:200px;">
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
            out.println("<p style='color:#c23934; font-weight:600; padding:10px;'>"+request.getAttribute("error")+"</p>");
            return;
        }
        List<Map<String,Object>> allGRNs=(List<Map<String,Object>>)request.getAttribute("all_grns");
        if(allGRNs==null || allGRNs.isEmpty()){
            out.println("<p style='padding:20px; text-align:center; color:var(--slds-text-muted); font-weight:600;'>No GRN records found within the system data container.</p>");
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
                    <span style="color:var(--slds-text-main);">GRN <b style="color:var(--slds-brand);"><%=grnNo%></b></span>
                    <span style="color: var(--slds-text-muted); font-weight:500; font-size:13px;"><i class="fa fa-calendar"></i> <%=grnDate%></span>
                    <span class="status-badge <%=status.equalsIgnoreCase("completed")?"status-completed":"status-pending"%>">
                        <%=status.substring(0,1).toUpperCase()+status.substring(1)%>
                    </span>
                    <div style="font-size:13px; color:var(--slds-text-muted); font-weight:400; width:100%;">
                        <i class="fa fa-building" style="margin-right:2px;"></i> <%=vendor%> &nbsp;|&nbsp; PO: <b style="color:var(--slds-text-main);"><%=poId%></b>
                    </div>
                </div>
                <div class="controls-right">
                    <button class="btn small secondary" onclick="toggleItems('<%=index%>')">
                        <i class="fa fa-eye"></i> Show / Hide Items
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
                <div class="info-card"><strong>GRN Remarks / Notes</strong><div class="info-card-text"><%=remarks.isEmpty() ? "-" : remarks%></div></div>
            </div>

            <div id="items_<%=index%>" class="items-container" style="display:none">
                <table class="items-table">
                    <thead>
                        <tr>
                            <th style="width:40%;">Item Description</th>
                            <th style="width:10%; text-align:center;">Qty Ordered</th>
                            <th style="width:10%; text-align:center;">Qty Received</th>
                            <th style="width:10%; text-align:center;">Qty Accepted</th>
                            <th style="width:10%; text-align:center;">Qty Rejected</th>
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
                            <td data-label="Item Description" class="cell-desc" style="font-weight:600;"><%=desc%></td>
                            <td data-label="Qty Ordered" class="cell-qordered"><%=qordered%></td>
                            <td data-label="Qty Received" class="cell-qreceived"><%=qreceived%></td>
                            <td data-label="Qty Accepted" class="cell-qaccepted"><%=qaccepted%></td>
                            <td data-label="Qty Rejected" class="cell-qrejected"><%=qrejected%></td>
                            <td data-label="Remarks" class="cell-remarks"><%=iremarks.isEmpty() ? "-" : iremarks%></td>
                        </tr>
                    <%
                        }
                    } else {
                    %>
                        <tr><td colspan="6" style="text-align:center; color:var(--slds-text-muted); padding:16px;">No structural line items cataloged inside this voucher segment.</td></tr>
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