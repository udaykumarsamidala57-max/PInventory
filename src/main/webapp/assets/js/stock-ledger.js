/*
 * Stock ledger drill-down pop-up.
 * Used by Stock Report (/stock-report) and Stock Ledger Report (/stock-ledger).
 *
 * Any element with class "ledger-link" + data-item="<item id>" + data-type="ALL|OPENING|RECEIPT|ISSUE"
 * opens the pop-up. Page config (set before this script):
 *   window.STOCK_LEDGER = { ctx: '/PInventory', fromDate: 'yyyy-MM-dd' or '', toDate: 'yyyy-MM-dd' or '' }
 *
 * The ledger covers ONE FINANCIAL YEAR (1 April .. 31 March; the current year ends today). The pop-up
 * opens with the opening balance as on the From date and lists entries from there.
 * Normal users: current year only. Global role / Finance department also get a "Financial Year"
 * dropdown for previous years. The server (StockLedgerDAO) enforces both rules.
 *
 * All data from the server is written with textContent (never innerHTML) to prevent XSS.
 */
(function () {
    'use strict';

    var CFG = window.STOCK_LEDGER || {};
    var CTX = CFG.ctx || '';
    var FROM = CFG.fromDate || '';
    var TO = CFG.toDate || '';

    var TITLES = {
        RECEIPT: 'Receipts (Inward)',
        ISSUE:   'Issues (Outward)',
        ALL:     'Item Stock Ledger'
    };

    var overlay, titleEl, subEl, sumEl, bodyEl, fromIn, toIn, filterMsg, fyLbl, fySel, reqSeq = 0;
    // What the pop-up is currently showing (dates and year may be changed inside the pop-up)
    var cur = { itemId: null, type: null, from: '', to: '', fy: '' };
    var ISO = /^\d{4}-\d{2}-\d{2}$/;

    // ---- Current academic year: 1 April .. today (the server sends the exact limits too) ----
    function iso(d) {
        return d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2);
    }
    var MAX_DATE = iso(new Date());
    /** Financial year (start year) a yyyy-MM-dd date belongs to. */
    function fyOf(isoDate) {
        var y = parseInt(isoDate.substring(0, 4), 10), m = parseInt(isoDate.substring(5, 7), 10);
        return m >= 4 ? y : y - 1;
    }
    var MIN_DATE = fyOf(MAX_DATE) + '-04-01';
    function dmy(isoDate) {
        return isoDate ? isoDate.substring(8, 10) + '-' + isoDate.substring(5, 7) + '-' + isoDate.substring(0, 4) : '';
    }
    /** Keeps a period inside 1 April .. today. Blank = whole year. */
    function clampRange(f, t) {
        if (!ISO.test(f || '')) f = MIN_DATE;
        if (!ISO.test(t || '')) t = MAX_DATE;
        if (f < MIN_DATE) f = MIN_DATE;
        if (t > MAX_DATE) t = MAX_DATE;
        if (f > t) { f = MIN_DATE; t = MAX_DATE; }
        return [f, t];
    }
    function setLimits() {
        [fromIn, toIn].forEach(function (inp) { inp.min = MIN_DATE; inp.max = MAX_DATE; });
    }

    // Indian number format: 1,23,456.78 ; negatives in brackets
    function fmt(n) {
        n = Number(n) || 0;
        var s = Math.abs(n).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        return n < 0 ? '(' + s + ')' : s;
    }

    function el(tag, cls, text) {
        var e = document.createElement(tag);
        if (cls) e.className = cls;
        if (text !== undefined && text !== null) e.textContent = text;
        return e;
    }

    function chip(label, value) {
        var c = el('span', 'ldg-chip', label);
        c.appendChild(el('b', null, value));
        return c;
    }

    function clear(node) { while (node.firstChild) node.removeChild(node.firstChild); }

    function message(text, isErr) {
        clear(bodyEl);
        clear(sumEl);
        bodyEl.appendChild(el('div', 'ldg-msg' + (isErr ? ' err' : ''), text));
    }

    function build() {
        if (overlay) return;
        overlay = el('div', 'ldg-overlay');
        overlay.setAttribute('aria-hidden', 'true');

        var modal = el('div', 'ldg-modal');
        modal.setAttribute('role', 'dialog');
        modal.setAttribute('aria-modal', 'true');
        modal.setAttribute('aria-labelledby', 'ldgTitle');

        var head = el('div', 'ldg-head');
        var hText = el('div');
        titleEl = el('h3', null, 'Stock Ledger');
        titleEl.id = 'ldgTitle';
        subEl = el('div', 'ldg-sub');
        hText.appendChild(titleEl);
        hText.appendChild(subEl);

        var closeBtn = el('button', 'ldg-close');
        closeBtn.type = 'button';
        closeBtn.title = 'Close (Esc)';
        closeBtn.appendChild(el('i', 'fa fa-times'));
        closeBtn.addEventListener('click', close);

        head.appendChild(hText);
        head.appendChild(closeBtn);

        // ---- Date filter bar (filter this item's ledger between dates) ----
        var bar = el('div', 'ldg-filter');
        var fLbl = el('label', null, 'From');
        fromIn = el('input');
        fromIn.type = 'date';
        fLbl.appendChild(fromIn);
        var tLbl = el('label', null, 'To');
        toIn = el('input');
        toIn.type = 'date';
        tLbl.appendChild(toIn);

        var applyBtn = el('button', 'ldg-btn ldg-btn-primary');
        applyBtn.type = 'button';
        applyBtn.appendChild(el('i', 'fa fa-filter'));
        applyBtn.appendChild(document.createTextNode(' Apply'));
        applyBtn.addEventListener('click', applyDates);

        var allBtn = el('button', 'ldg-btn');
        allBtn.type = 'button';
        allBtn.appendChild(el('i', 'fa fa-calendar'));
        allBtn.appendChild(document.createTextNode(' Full Year'));
        allBtn.title = 'Whole financial year (1 April onwards)';
        allBtn.addEventListener('click', function () {
            filterMsg.textContent = '';
            load(cur.itemId, cur.type, '', '', cur.fy);   // whole of the year being viewed
        });

        // Financial Year dropdown: shown only when the server says this user may choose a year
        fyLbl = el('label', null, 'Financial Year');
        fySel = el('select');
        fyLbl.appendChild(fySel);
        fyLbl.style.display = 'none';
        fySel.addEventListener('change', function () {
            filterMsg.textContent = '';
            load(cur.itemId, cur.type, '', '', fySel.value);   // whole selected year
        });

        filterMsg = el('span', 'ldg-filter-msg');

        [fromIn, toIn].forEach(function (inp) {
            inp.addEventListener('keydown', function (e) { if (e.key === 'Enter') applyDates(); });
        });

        bar.appendChild(fyLbl);
        bar.appendChild(fLbl);
        bar.appendChild(tLbl);
        bar.appendChild(applyBtn);
        bar.appendChild(allBtn);
        bar.appendChild(filterMsg);

        sumEl = el('div', 'ldg-summary');
        bodyEl = el('div', 'ldg-body');

        modal.appendChild(head);
        modal.appendChild(bar);
        modal.appendChild(sumEl);
        modal.appendChild(bodyEl);
        overlay.appendChild(modal);
        document.body.appendChild(overlay);

        overlay.addEventListener('click', function (e) { if (e.target === overlay) close(); });
    }

    function open(itemId, type) {
        build();
        setLimits();
        // Opening-balance clicks show the ledger from the From date (opening as on that date)
        if (type === 'OPENING') type = 'ALL';
        filterMsg.textContent = '';
        // Year of the report's From date; the server falls back to the current year if not allowed
        var fy = ISO.test(FROM) ? String(fyOf(FROM)) : '';
        var r = clampRange(FROM, TO);
        fromIn.value = ISO.test(FROM) ? FROM : r[0];
        toIn.value = ISO.test(TO) ? TO : r[1];
        load(itemId, type, ISO.test(FROM) ? FROM : '', ISO.test(TO) ? TO : '', fy);
    }

    // Apply the From/To dates typed in the pop-up
    function applyDates() {
        var f = fromIn.value, t = toIn.value;
        if (!ISO.test(f) || !ISO.test(t)) { filterMsg.textContent = 'Select both From and To dates.'; return; }
        if (f < MIN_DATE) { filterMsg.textContent = 'From Date cannot be before ' + dmy(MIN_DATE) + ' (start of this financial year).'; return; }
        if (t > MAX_DATE) { filterMsg.textContent = 'To Date cannot be after ' + dmy(MAX_DATE) + '.'; return; }
        if (f > t) { filterMsg.textContent = 'From Date cannot be after To Date.'; return; }
        filterMsg.textContent = '';
        load(cur.itemId, cur.type, f, t, cur.fy);
    }

    function load(itemId, type, from, to, fy) {
        cur = { itemId: itemId, type: type, from: from, to: to, fy: fy || '' };
        titleEl.textContent = TITLES[type] || 'Stock Ledger';
        subEl.textContent = 'Loading…';
        message('Loading ledger…', false);
        overlay.classList.add('open');
        overlay.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';

        var seq = ++reqSeq;
        var url = CTX + '/stock-ledger-detail?itemId=' + encodeURIComponent(itemId) +
                  '&type=' + encodeURIComponent(type) +
                  '&fromDate=' + encodeURIComponent(from) +
                  '&toDate=' + encodeURIComponent(to) +
                  '&fy=' + encodeURIComponent(cur.fy);

        fetch(url, { credentials: 'same-origin', headers: { 'Accept': 'application/json' } })
            .then(function (r) {
                return r.json()
                    .catch(function () { return { error: 'Unexpected server response. Please log in again.' }; })
                    .then(function (d) {
                        if (!r.ok && !d.error) d.error = 'Request failed (' + r.status + ').';
                        return d;
                    });
            })
            .then(function (d) { if (seq === reqSeq) render(d); })
            .catch(function () { if (seq === reqSeq) message('Network error. Please try again.', true); });
    }

    function render(d) {
        if (d.error) { subEl.textContent = ''; message(d.error, true); return; }

        var t = d.type;
        // Use the server's limits and the dates it actually used (it never goes before 1 April)
        if (ISO.test(d.minDate || '')) MIN_DATE = d.minDate;
        if (ISO.test(d.maxDate || '')) MAX_DATE = d.maxDate;
        setLimits();
        if (ISO.test(d.fromIso || '')) fromIn.value = d.fromIso;
        if (ISO.test(d.toIso || '')) toIn.value = d.toIso;
        cur.fy = String(d.fy || '');
        fillYears(d);
        if (d.clamped) filterMsg.textContent = 'Showing FY ' + d.fyLabel + ' only (' + dmy(MIN_DATE) + ' to ' + dmy(MAX_DATE) + ').';
        var period = 'FY ' + d.fyLabel + '  |  ' + d.fromDate + ' to ' + d.toDate;
        subEl.textContent = d.itemName + '  |  ' + (d.category || '') +
                            (d.subCategory ? ' / ' + d.subCategory : '') + '  |  ' + period;

        clear(sumEl);
        if (t === 'ALL') sumEl.appendChild(chip('Opening as on ' + d.fromDate + ':', fmt(d.opening)));
        if (t !== 'ISSUE') sumEl.appendChild(chip('Total Inward:', fmt(d.totalIn)));
        if (t !== 'RECEIPT') sumEl.appendChild(chip('Total Outward:', fmt(d.totalOut)));
        if (t === 'ALL') sumEl.appendChild(chip('Closing Balance:', fmt(d.closing)));
        sumEl.appendChild(chip('Entries:', String(d.rows.length)));

        clear(bodyEl);
        if (d.truncated) {
            bodyEl.appendChild(el('div', 'ldg-msg err',
                'Showing first ' + d.rows.length + ' entries only. Narrow the date range to see all.'));
        }
        if (!d.rows.length && t !== 'ALL') {
            bodyEl.appendChild(el('div', 'ldg-msg', 'No transactions found.'));
            return;
        }

        var showIn = t !== 'ISSUE', showOut = t !== 'RECEIPT', showBal = (t === 'ALL');
        var table = el('table', 'ldg-table');
        var thead = el('thead'), hr = el('tr');
        ['#', 'Date', 'Type', 'Ref No', 'Vendor / Department', 'Remarks'].forEach(function (h) {
            hr.appendChild(el('th', null, h));
        });
        if (showIn) hr.appendChild(el('th', 'num', 'Inward Qty'));
        if (showOut) hr.appendChild(el('th', 'num', 'Outward Qty'));
        if (showBal) hr.appendChild(el('th', 'num', 'Balance'));
        thead.appendChild(hr);
        table.appendChild(thead);

        var cols = 6 + (showIn ? 1 : 0) + (showOut ? 1 : 0) + (showBal ? 1 : 0);
        var tb = el('tbody');

        if (t === 'ALL' && !d.allDates) {
            var or = el('tr', 'ldg-open');
            var oc = el('td', null, 'Opening Balance as on ' + d.fromDate);
            oc.colSpan = cols - 1;
            or.appendChild(oc);
            or.appendChild(el('td', 'num', fmt(d.opening)));
            tb.appendChild(or);
        }

        d.rows.forEach(function (r, i) {
            var tr = el('tr');
            tr.appendChild(el('td', null, String(i + 1)));
            tr.appendChild(el('td', 'nowrap', r.date));
            var tc = el('td');
            tc.appendChild(el('span', 'ldg-badge ' + (r.type === 'Receipt' ? 'r' : 'i'), r.type));
            tr.appendChild(tc);
            tr.appendChild(el('td', null, r.refNo || '-'));
            tr.appendChild(el('td', null, r.party || '-'));
            tr.appendChild(el('td', null, r.remarks || ''));
            if (showIn) tr.appendChild(el('td', 'num ldg-in', r.inQty ? fmt(r.inQty) : ''));
            if (showOut) tr.appendChild(el('td', 'num ldg-out', r.outQty ? fmt(r.outQty) : ''));
            if (showBal) tr.appendChild(el('td', 'num', fmt(r.balance)));
            tb.appendChild(tr);
        });
        table.appendChild(tb);

        var tf = el('tfoot'), fr = el('tr');
        var lc = el('td', null, 'Total');
        lc.colSpan = 6;
        fr.appendChild(lc);
        if (showIn) fr.appendChild(el('td', 'num ldg-in', fmt(d.totalIn)));
        if (showOut) fr.appendChild(el('td', 'num ldg-out', fmt(d.totalOut)));
        if (showBal) fr.appendChild(el('td', 'num', fmt(d.closing)));
        tf.appendChild(fr);
        table.appendChild(tf);

        var wrap = el('div', 'ldg-scroll');
        wrap.appendChild(table);
        bodyEl.appendChild(wrap);
    }

    /** Financial Year dropdown for Global / Finance users (list comes from the server). */
    function fillYears(d) {
        var years = d.years || [];
        if (!d.canChooseYear || years.length < 2) { fyLbl.style.display = 'none'; return; }
        if (fySel.options.length !== years.length) {
            clear(fySel);
            years.forEach(function (y) {
                var o = el('option', null, 'FY ' + y.label);
                o.value = String(y.fy);
                fySel.appendChild(o);
            });
        }
        fySel.value = String(d.fy);
        fyLbl.style.display = '';
    }

    function close() {
        reqSeq++;
        if (!overlay) return;
        overlay.classList.remove('open');
        overlay.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
    }

    document.addEventListener('click', function (e) {
        var a = e.target.closest ? e.target.closest('.ledger-link') : null;
        if (!a) return;
        e.preventDefault();
        var id = a.getAttribute('data-item');
        var type = a.getAttribute('data-type');
        if (!/^\d+$/.test(id || '')) return;
        open(id, type);
    });

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && overlay && overlay.classList.contains('open')) close();
    });
})();
