<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String user = (String) sess.getAttribute("username");
    String role = (String) sess.getAttribute("role");
    String dept = (String) sess.getAttribute("department");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dining Hall Consumption Form</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="CSS/Form.css">
    <link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />

    <style>
        :root {
            --primary: #1e3a8a;
            --primary-hover: #1e40af;
            --surface-bg: #f1f5f9;
            --card-bg: #ffffff;
            --text-dark: #0f172a;
            --text-muted: #475569;
            --border-dark: #94a3b8;
            --border-light: #cbd5e1;
            --success-badge: #15803d;
            --success-bg: #dcfce7;
            --danger-badge: #b91c1c;
            --danger-bg: #fee2e2;
        }

        body {
            background-color: var(--surface-bg);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            color: var(--text-dark);
            margin: 0;
            padding: 0;
            line-height: 1.4;
        }

        .main-content {
            max-width: 1360px;
            margin: 24px auto;
            padding: 0 16px;
        }

        .card {
            background: var(--card-bg);
            border: 2px solid var(--border-dark);
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);
            padding: 24px;
        }

        .page-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 2px solid var(--text-dark);
            padding-bottom: 12px;
            margin-bottom: 20px;
        }

        .page-header .title-area {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .page-header .icon-box {
            width: 40px;
            height: 40px;
            background-color: var(--primary);
            color: #ffffff;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
        }

        .page-header h2 {
            margin: 0;
            font-size: 22px;
            font-weight: 700;
            color: var(--text-dark);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .page-header .subtitle {
            font-size: 13px;
            color: var(--text-muted);
            margin: 0;
            font-weight: 500;
        }

        .form-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px;
            background-color: #f8fafc;
            border: 1px solid var(--border-dark);
            padding: 16px;
            border-radius: 6px;
            margin-bottom: 20px;
        }

        @media (max-width: 1024px) { .form-grid { grid-template-columns: repeat(2, 1fr); } }
        @media (max-width: 640px) { .form-grid { grid-template-columns: 1fr; } }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .form-group label {
            font-size: 12px;
            font-weight: 700;
            color: var(--text-dark);
            text-transform: uppercase;
            letter-spacing: 0.4px;
        }

        .form-control-static {
            font-size: 14px;
            font-weight: 700;
            color: var(--text-dark);
            padding: 6px 10px;
            background-color: #e2e8f0;
            border: 1px solid var(--border-dark);
            border-radius: 4px;
            height: 38px;
            box-sizing: border-box;
            display: flex;
            align-items: center;
        }

        input[type="text"], input[type="date"], input[type="number"], select {
            height: 38px;
            padding: 6px 10px;
            font-size: 14px;
            font-weight: 500;
            font-family: inherit;
            color: var(--text-dark);
            background-color: #ffffff;
            border: 1px solid var(--border-dark);
            border-radius: 4px;
            box-sizing: border-box;
            width: 100%;
        }

        input:focus, select:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 2px rgba(30, 58, 138, 0.25);
        }

        input[readonly] {
            background-color: #e2e8f0;
            color: var(--text-dark);
            font-weight: 700;
            cursor: not-allowed;
        }

        .select2-container { width: 100% !important; }
        .select2-container .select2-selection--single {
            height: 38px;
            border: 1px solid var(--border-dark);
            border-radius: 4px;
            padding: 4px 8px;
        }
        .select2-container--default .select2-selection--single .select2-selection__rendered {
            line-height: 28px;
            font-size: 14px;
            font-weight: 500;
            color: var(--text-dark);
            padding-left: 0;
        }
        .select2-container--default .select2-selection--single .select2-selection__arrow { height: 36px; }

        .table-wrapper {
            border: 1px solid var(--border-dark);
            border-radius: 6px;
            overflow: hidden;
            margin-bottom: 20px;
        }

        #itemsTable {
            width: 100%;
            border-collapse: collapse;
            background: #ffffff;
        }

        #itemsTable th {
            background-color: var(--primary);
            color: #ffffff;
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 10px 12px;
            text-align: left;
            border-right: 1px solid rgba(255, 255, 255, 0.15);
        }

        #itemsTable td {
            padding: 8px 10px;
            border-bottom: 1px solid var(--border-light);
            vertical-align: middle;
            font-size: 13px;
        }

        #itemsTable tbody tr:nth-child(even) { background-color: #f8fafc; }
        #itemsTable tbody tr:hover { background-color: #f1f5f9; }

        .uom { text-align: center !important; font-weight: 600; color: var(--text-dark); }
        .stock { text-align: center !important; }

        .stock-available {
            color: var(--success-badge);
            background-color: var(--success-bg);
            padding: 2px 8px;
            border-radius: 4px;
            font-weight: 700;
            font-size: 12px;
            display: inline-block;
            border: 1px solid #86efac;
        }

        .stock-unavailable {
            color: var(--danger-badge);
            background-color: var(--danger-bg);
            padding: 2px 8px;
            border-radius: 4px;
            font-weight: 700;
            font-size: 12px;
            display: inline-block;
            border: 1px solid #fca5a5;
        }

        .qty:disabled {
            background-color: #fee2e2;
            border-color: #fca5a5;
            cursor: not-allowed;
        }

        .button-area {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding-top: 16px;
            border-top: 2px solid var(--border-dark);
        }

        .btn-brand {
            background-color: var(--primary);
            color: #ffffff;
            border: 1px solid var(--primary);
            padding: 10px 20px;
            font-size: 14px;
            font-weight: 700;
            border-radius: 4px;
            cursor: pointer;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .btn-brand:hover { background-color: var(--primary-hover); }

        .btn-neutral {
            background-color: #ffffff;
            color: var(--primary);
            border: 2px solid var(--primary);
            padding: 8px 16px;
            font-size: 13px;
            font-weight: 700;
            border-radius: 4px;
            cursor: pointer;
            text-transform: uppercase;
        }

        .btn-neutral:hover {
            background-color: var(--primary);
            color: #ffffff;
        }

        .btn-destructive {
            background-color: #ffffff;
            color: var(--danger-badge);
            border: 1px solid var(--danger-badge);
            padding: 4px 10px;
            font-size: 12px;
            font-weight: 700;
            border-radius: 4px;
            cursor: pointer;
        }

        .btn-destructive:hover {
            background-color: var(--danger-badge);
            color: #ffffff;
        }

        /* ---------- compact layout: more lines on screen for big issues ---------- */
        .main-content { max-width: none; width: 97%; margin: 10px auto; padding: 0; }
        .card { padding: 12px 14px; border-width: 1px; }
        .page-header { padding-bottom: 6px; margin-bottom: 10px; border-bottom-width: 1px; }
        .page-header .icon-box { width: 30px; height: 30px; font-size: 16px; }
        .page-header h2 { font-size: 17px; }
        .form-grid { grid-template-columns: repeat(5, 1fr); gap: 8px; padding: 8px 10px; margin-bottom: 10px; }
        @media (max-width: 1024px) { .form-grid { grid-template-columns: repeat(3, 1fr); } }
        @media (max-width: 640px) { .form-grid { grid-template-columns: 1fr 1fr; } }
        .form-group { gap: 2px; }
        .form-group label { font-size: 10.5px; }
        input[type="text"], input[type="date"], input[type="number"], select, .form-control-static { height: 30px; padding: 3px 7px; font-size: 13px; }
        .select2-container .select2-selection--single { height: 30px; padding: 0 6px; }
        .select2-container--default .select2-selection--single .select2-selection__rendered { line-height: 28px; font-size: 13px; }
        .select2-container--default .select2-selection--single .select2-selection__arrow { height: 28px; }
        .select2-results__option { padding: 4px 8px; font-size: 13px; }
        .table-wrapper { max-height: 62vh; overflow: auto; margin-bottom: 8px; }
        #itemsTable th { position: sticky; top: 0; z-index: 2; padding: 6px 7px; font-size: 11px; }
        #itemsTable td { padding: 2px 5px; font-size: 12.5px; }
        #itemsTable td.rowno { width: 34px; text-align: right; color: var(--text-muted); font-variant-numeric: tabular-nums; }
        #itemsTable tr.row-error td { background: #fff1f2 !important; }
        .stock-available, .stock-unavailable { padding: 1px 6px; font-size: 11.5px; }
        .btn-destructive { padding: 2px 8px; font-size: 13px; line-height: 1.2; }
        .button-area { padding-top: 8px; border-top-width: 1px; gap: 8px; flex-wrap: wrap; }
        .button-area .left { display: flex; gap: 6px; align-items: center; flex-wrap: wrap; }
        .btn-neutral { padding: 5px 12px; font-size: 12px; }
        .btn-brand { padding: 7px 18px; font-size: 13px; }
        .line-summary { font-size: 12.5px; color: var(--text-muted); }
        .line-summary strong { color: var(--text-dark); }
        .dh-msg { margin-bottom: 8px !important; padding: 7px 12px !important; }
    </style>
</head>

<body>

<jsp:include page="/WEB-INF/views/layout/header.jsp" />

<div class="main-content">
    <div class="card">
        <div class="page-header">
            <div class="title-area">
                <div class="icon-box">📦</div>
                <div>
                    <h2>Dining Hall Consumption</h2>
                   
                </div>
            </div>
        </div>

        <%
            String dhOk  = (String) sess.getAttribute("diningSuccess");
            String dhErr = (String) sess.getAttribute("diningError");
            sess.removeAttribute("diningSuccess");
            sess.removeAttribute("diningError");
            if (dhOk != null || dhErr != null) {
                String dhMsg = (dhOk != null ? dhOk : dhErr).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
        %>
        <div class="dh-msg <%= dhOk != null ? "dh-ok" : "dh-err" %>" role="alert">
            <strong><%= dhOk != null ? "Saved" : "Not saved" %></strong> &ndash; <%= dhMsg %>
        </div>
        <style>
            .dh-msg { margin: 0 0 14px; padding: 10px 14px; border-radius: 6px; font-size: 13.5px; line-height: 1.45; border: 1px solid; }
            .dh-ok  { background: #f0f9f4; border-color: #b7e0c8; color: #1f6b43; }
            .dh-err { background: #fff8eb; border-color: #f3d59b; color: #8a5a00; }
        </style>
        <% } %>

        <form action="dining-hall" method="post" id="diningForm">
            <div class="form-grid">
                <div class="form-group">
                    <label for="issueno">Issue No</label>
                    <input type="text" id="issueno" name="issueno" value="${nextIssueNo}" readonly>
                </div>

                <div class="form-group">
                    <label>Department</label>
                    <input type="hidden" name="department" value="Dining Hall">
                    <div class="form-control-static">Dining Hall</div>
                </div>

                <div class="form-group">
                    <label for="issued_to">Issued To</label>
                    <input type="text" id="issued_to" name="issued_to" placeholder="Recipient Name" required>
                </div>

                <div class="form-group">
                    <label for="session">Session</label>
                    <select name="session" id="session" required>
                        <option value="">-- Select Session --</option>
                        <option value="Morning Drink">Morning Drink</option>
                        <option value="Break Fast">Break Fast</option>
                        <option value="Lunch">Lunch</option>
                        <option value="Snacks">Snacks</option>
                        <option value="Dinner">Dinner</option>
                        <option value="Staff Tea">Staff Tea</option>
                        <option value="Special Event">Special Event</option>
                        <% if ("Global".equalsIgnoreCase(role)) { %>
                            <option value="Adjustment">Adjustment</option>
                        <% } %>
                    </select>
                </div>

                <div class="form-group">
                    <label for="issue_date">Issue Date</label>
                    <input type="date" name="issue_date" id="issue_date" required
                           min="${minDate}" max="${maxDate}" value="${maxDate}">
                </div>
            </div>

            <!-- Strength of this session: shared by every issue of the same date + session; used for the meal cost per head -->
            <div class="strength-box">
                <div class="strength-head">
                    <strong>Strength (people served in this session)</strong>
                    <span id="strengthNote" class="strength-note">Choose the session and date; a strength already saved for them is filled in.</span>
                </div>
                <div class="strength-grid">
                    <div class="form-group"><label for="boarding_students">Boarding Students</label>
                        <input type="number" id="boarding_students" name="boarding_students" class="strength" min="0" max="100000" step="1" inputmode="numeric" value="0"></div>
                    <div class="form-group"><label for="day_boarding_students">Day Boarding Students</label>
                        <input type="number" id="day_boarding_students" name="day_boarding_students" class="strength" min="0" max="100000" step="1" inputmode="numeric" value="0"></div>
                    <div class="form-group"><label for="day_scholars">Dayscholars</label>
                        <input type="number" id="day_scholars" name="day_scholars" class="strength" min="0" max="100000" step="1" inputmode="numeric" value="0"></div>
                    <div class="form-group"><label for="staff_count">Staff</label>
                        <input type="number" id="staff_count" name="staff_count" class="strength" min="0" max="100000" step="1" inputmode="numeric" value="0"></div>
                    <div class="form-group"><label>Total Strength</label>
                        <div class="form-control-static" id="strengthTotal">0</div></div>
                </div>
            </div>
            <style>
                .strength-box { border: 1px solid var(--border-dark); border-radius: 6px; padding: 7px 10px; margin-bottom: 10px; background: #f8fafc; }
                .strength-head { display: flex; flex-wrap: wrap; gap: 4px 12px; align-items: baseline; margin-bottom: 5px; }
                .strength-head strong { font-size: 13px; text-transform: uppercase; letter-spacing: .4px; }
                .strength-note { font-size: 12px; color: var(--text-muted); }
                .strength-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px; }
                @media (max-width: 1024px) { .strength-grid { grid-template-columns: repeat(3, 1fr); } }
                @media (max-width: 640px) { .strength-grid { grid-template-columns: repeat(2, 1fr); } }
            </style>

            <div class="table-wrapper">
                <table id="itemsTable">
                    <thead>
                        <tr>
                            <th style="width: 3%; text-align: right;">#</th>
                            <th style="width: 13%;">Category (optional)</th>
                            <th style="width: 13%;">SubCategory (optional)</th>
                            <th style="width: 30%;">Item (type to search all items)</th>
                            <th style="width: 6%; text-align: center;">UOM</th>
                            <th style="width: 8%; text-align: center;">Stock</th>
                            <th style="width: 9%;">Qty Issued</th>
                            <th style="width: 15%;">Remarks</th>
                            <th style="width: 3%; text-align: center;"></th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>

            <div class="button-area">
                <div class="left">
                    <button type="button" id="addItemBtn" class="btn-neutral">+ Add Line</button>
                    <button type="button" id="add10Btn" class="btn-neutral">+ Add 10 Lines</button>
                    <button type="button" id="clearEmptyBtn" class="btn-neutral">Remove Empty Lines</button>
                    <span class="line-summary" id="lineSummary">0 lines</span>
                </div>
                <button type="submit" class="btn-brand">Confirm Consumption</button>
            </div>
        </form>
    </div>
</div>

<script type="application/json" id="diningMaster"><c:out value="${masterJson}" escapeXml="false"/></script>
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>

<script>
document.addEventListener("DOMContentLoaded", function () {

    // Issue date default (today, India time), min and max (10 days back) come from the server

    const master = JSON.parse(document.getElementById("diningMaster").textContent);
    const categories = master.categories;      // [{name, departmentName}]
    const subcategories = master.subcategories; // [{name, categoryName}]
    const items = master.items;                 // [{id, name, UOM, category, subcategory, stock}]
    const itemById = new Map(items.map(i => [String(i.id), i]));

    // ---------- Strength: total, and the strength already saved for this date + session
    const strengthInputs = Array.from(document.querySelectorAll(".strength"));
    const strengthTotal = document.getElementById("strengthTotal");
    const strengthNote = document.getElementById("strengthNote");
    function updateStrengthTotal() {
        let t = 0;
        strengthInputs.forEach(i => { const n = parseInt(i.value, 10); if (!isNaN(n) && n > 0) t += n; });
        strengthTotal.textContent = t.toLocaleString("en-IN");
        return t;
    }
    strengthInputs.forEach(i => i.addEventListener("input", updateStrengthTotal));
    function loadStrength() {
        const date = document.getElementById("issue_date").value;
        const session = document.getElementById("session").value;
        if (!date || !session) return;
        fetch("dining-hall?action=strength&date=" + encodeURIComponent(date) + "&session=" + encodeURIComponent(session),
              { credentials: "same-origin", headers: { "Accept": "application/json" } })
            .then(r => r.ok ? r.json() : null)
            .then(d => {
                if (!d) return;
                if (d.error) { strengthNote.textContent = d.error; return; }
                if (d.found) {
                    document.getElementById("boarding_students").value = d.boarding;
                    document.getElementById("day_boarding_students").value = d.dayBoarding;
                    document.getElementById("day_scholars").value = d.dayScholars;
                    document.getElementById("staff_count").value = d.staff;
                    strengthNote.textContent = "Strength already saved for this session (issued so far " + d.costSoFar + "). Change it only if it is wrong; the change is logged.";
                } else {
                    strengthInputs.forEach(i => i.value = 0);
                    strengthNote.textContent = "No strength saved yet for this session and date. Enter it below.";
                }
                updateStrengthTotal();
            })
            .catch(() => { strengthNote.textContent = "Could not load the saved strength; enter it below."; });
    }
    document.getElementById("session").addEventListener("change", loadStrength);
    document.getElementById("issue_date").addEventListener("change", loadStrength);

    // ---------- Item lines (built for big issues: search all items directly, many lines, no page lag)
    const tbody = document.querySelector("#itemsTable tbody");
    const uniqueCats = [...new Set(categories.map(c => c.name))];
    const esc = v => String(v == null ? "" : v);

    document.getElementById("addItemBtn").addEventListener("click", () => addRow(true));
    document.getElementById("add10Btn").addEventListener("click", () => { for (let i = 0; i < 10; i++) addRow(i === 0); });
    document.getElementById("clearEmptyBtn").addEventListener("click", () => {
        tbody.querySelectorAll("tr").forEach(tr => {
            if (!tr.querySelector(".item").value && !tr.querySelector(".qty").value) removeRow(tr);
        });
        if (!tbody.children.length) addRow(false);
    });

    function addRow(focus) {
        const tr = document.createElement("tr");
        tr.innerHTML = `
            <td class="rowno"></td>
            <td><select class="cat"><option value="">All</option></select></td>
            <td><select class="subcat"><option value="">All</option></select></td>
            <td><select class="item" name="item_id"><option value=""></option></select></td>
            <td class="uom"></td>
            <td class="stock"></td>
            <td><input type="number" name="qty_issued" class="qty" min="0" step="any"></td>
            <td><input type="text" name="remarks" class="remarks" maxlength="250"></td>
            <td style="text-align: center;"><button type="button" class="btn-destructive removeBtn" title="Remove line" aria-label="Remove line">&times;</button></td>`;
        tbody.appendChild(tr);

        const catSel = tr.querySelector(".cat"), subSel = tr.querySelector(".subcat"), itemSel = tr.querySelector(".item");
        const uomCell = tr.querySelector(".uom"), stockCell = tr.querySelector(".stock"), qtyInput = tr.querySelector(".qty");
        uniqueCats.forEach(name => catSel.add(new Option(name, name)));

        // The item list is searched in memory and only the first 60 matches are drawn, so 100s of lines stay fast.
        $(itemSel).select2({
            placeholder: "Type item name...",
            allowClear: true,
            width: "100%",
            minimumInputLength: 0,
            ajax: {
                delay: 120,
                data: params => ({ term: params.term || "" }),
                transport: function (params, success) {
                    const q = String((params.data && params.data.term) || "").trim().toLowerCase();
                    const used = usedItemIds(tr);
                    const res = [];
                    for (const it of items) {
                        if (catSel.value && it.category !== catSel.value) continue;
                        if (subSel.value && it.subcategory !== subSel.value) continue;
                        if (q && esc(it.name).toLowerCase().indexOf(q) < 0) continue;
                        const st = parseFloat(it.stock || "0");
                        res.push({ id: String(it.id), text: esc(it.name), disabled: used.has(String(it.id)),
                                   hint: esc(it.category) + " / " + esc(it.subcategory) + " - stock " + (st > 0 ? st : "nil") + " " + esc(it.UOM) });
                        if (res.length >= 60) break;
                    }
                    success({ results: res });
                    return { abort: function () {} };
                },
                processResults: data => data
            },
            templateResult: r => {
                if (!r.id) return r.text;
                const box = document.createElement("div");
                const b = document.createElement("div"); b.textContent = r.text;
                const sm = document.createElement("div"); sm.textContent = r.hint + (r.disabled ? " (already in another line)" : "");
                sm.style.cssText = "font-size:11px;color:#64748b";
                box.append(b, sm);
                return box;
            }
        });

        catSel.addEventListener("change", () => {
            subSel.innerHTML = '<option value="">All</option>';
            subcategories.filter(x => x.categoryName === catSel.value).forEach(x => subSel.add(new Option(x.name, x.name)));
        });

        $(itemSel).on("change", function () {
            const it = itemById.get(itemSel.value);
            tr.classList.remove("row-error");
            if (!it) { uomCell.textContent = ""; stockCell.textContent = ""; stockCell.className = "stock"; qtyInput.disabled = false; updateSummary(); return; }
            // picking an item fills its category / subcategory
            if (catSel.value !== it.category) { catSel.value = it.category; catSel.dispatchEvent(new Event("change")); }
            subSel.value = it.subcategory;
            uomCell.textContent = it.UOM || "";
            const stock = parseFloat(it.stock || "0");
            if (stock > 0) {
                stockCell.textContent = stock;
                stockCell.className = "stock stock-available";
                qtyInput.disabled = false;
                qtyInput.max = stock;
                setTimeout(() => qtyInput.focus(), 0);   // after Select2 has closed
            } else {
                stockCell.textContent = "Out of Stock";
                stockCell.className = "stock stock-unavailable";
                qtyInput.value = "";
                qtyInput.disabled = true;
                tr.classList.add("row-error");
            }
            updateSummary();
        });

        qtyInput.addEventListener("input", () => {
            const it = itemById.get(itemSel.value);
            const qty = parseFloat(qtyInput.value || "0");
            const over = it && qty > parseFloat(it.stock || "0");
            tr.classList.toggle("row-error", qty < 0 || !!over);
            qtyInput.title = over ? "More than the stock (" + it.stock + ")" : "";
            updateSummary();
        });
        // Enter in Qty or Remarks: go to the next line (a new one is added at the end)
        [qtyInput, tr.querySelector(".remarks")].forEach(el => el.addEventListener("keydown", e => {
            if (e.key !== "Enter") return;
            e.preventDefault();
            let next = tr.nextElementSibling;
            if (!next) { addRow(false); next = tr.nextElementSibling; }
            $(next.querySelector(".item")).select2("open");
        }));

        tr.querySelector(".removeBtn").addEventListener("click", () => { removeRow(tr); if (!tbody.children.length) addRow(false); });
        renumber();
        updateSummary();
        if (focus) $(itemSel).select2("open");
    }

    function removeRow(tr) {
        $(tr.querySelector(".item")).select2("destroy");
        tr.remove();
        renumber();
        updateSummary();
    }

    function usedItemIds(except) {
        const set = new Set();
        tbody.querySelectorAll("tr").forEach(tr => { if (tr !== except) { const v = tr.querySelector(".item").value; if (v) set.add(v); } });
        return set;
    }

    function renumber() {
        let n = 0;
        tbody.querySelectorAll("tr").forEach(tr => { tr.querySelector(".rowno").textContent = ++n; });
    }

    function updateSummary() {
        let lines = 0, filled = 0, problems = 0;
        tbody.querySelectorAll("tr").forEach(tr => {
            lines++;
            if (tr.querySelector(".item").value && parseFloat(tr.querySelector(".qty").value || "0") > 0) filled++;
            if (tr.classList.contains("row-error")) problems++;
        });
        document.getElementById("lineSummary").innerHTML = "<strong>" + filled + "</strong> of " + lines + " line(s) filled"
            + (problems ? " &middot; <span style='color:#b91c1c'>" + problems + " to check</span>" : "");
    }

    for (let i = 0; i < 5; i++) addRow(false);   // start with 5 empty lines

    document.getElementById("diningForm").addEventListener("submit", function (event) {
        let filled = 0, invalid = 0;
        document.querySelectorAll("#itemsTable tbody tr").forEach(tr => {
            const itemId = tr.querySelector(".item").value;
            const qtyText = tr.querySelector(".qty").value;
            if (!itemId && !qtyText) { tr.classList.remove("row-error"); return; }     // empty line: skipped
            const it = itemById.get(itemId);
            const qty = parseFloat(qtyText || "0");
            const bad = !it || isNaN(qty) || qty <= 0 || qty > parseFloat(it.stock || "0");
            tr.classList.toggle("row-error", bad);
            if (bad) invalid++; else filled++;
        });
        if (invalid) {
            alert("⚠️ " + invalid + " line(s) are marked in red: choose the item and a quantity within the stock, or clear the line.");
            event.preventDefault();
            return;
        }
        if (!filled) {
            alert("⚠️ Please fill at least one line item.");
            event.preventDefault();
            return;
        }
        if (document.getElementById("session").value !== "Adjustment" && updateStrengthTotal() <= 0) {
            alert("⚠️ Please enter the strength (Boarding, Day Boarding, Dayscholars, Staff) for this session.");
            event.preventDefault();
            return;
        }

        // empty lines are not sent
        document.querySelectorAll("#itemsTable tbody tr").forEach(tr => {
            if (!tr.querySelector(".item").value && !tr.querySelector(".qty").value) {
                tr.querySelectorAll("select, input").forEach(el => el.disabled = true);
            }
        });

        if (!confirm("Confirm submission of " + filled + " item line(s) for this Dining Hall consumption?")) {
            event.preventDefault();
            document.querySelectorAll("#itemsTable tbody tr").forEach(tr => {
                if (!tr.querySelector(".item").value && !tr.querySelector(".qty").value) {
                    tr.querySelectorAll("select, input").forEach(el => el.disabled = false);
                }
            });
        }
    });
});
</script>

</body>
</html>