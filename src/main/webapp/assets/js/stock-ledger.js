/*
 * Stock ledger drill-down pop-up.
 * Used by Stock Report (/stock-report) and Stock Ledger Report (/stock-ledger).
 *
 * Any element with class "ledger-link" + data-item="<item id>" + data-type="ALL|OPENING|RECEIPT|ISSUE"
 * opens the pop-up. Page config (set before this script):
 *   window.STOCK_LEDGER = { ctx: '/PInventory', fromDate: 'yyyy-MM-dd' or '', toDate: 'yyyy-MM-dd' or '' }
 * Blank dates = all dates.
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
        OPENING: 'Opening Balance – Transactions before From Date',
        RECEIPT: 'Receipts (Inward)',
        ISSUE:   'Issues (Outward)',
        ALL:     'Item Stock Ledger'
    };

    var overlay, titleEl, subEl, sumEl, bodyEl, fromIn, toIn, filterMsg, reqSeq = 0;
    // What the pop-up is currently showing (dates may be changed inside the pop-up)
    var cur = { itemId: null, type: null, from: '', to: '' };
    var ISO = /^\d{4}-\d{2}-\d{2}$/;

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
        allBtn.appendChild(document.createTextNode(' All Dates'));
        allBtn.addEventListener('click', function () {
            fromIn.value = '';
            toIn.value = '';
            filterMsg.textContent = '';
            load(cur.itemId, cur.type === 'OPENING' ? 'ALL' : cur.type, '', '');
        });

        filterMsg = el('span', 'ldg-filter-msg');

        [fromIn, toIn].forEach(function (inp) {
            inp.addEventListener('keydown', function (e) { if (e.key === 'Enter') applyDates(); });
        });

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
        filterMsg.textContent = '';
        fromIn.value = FROM;
        toIn.value = TO;
        load(itemId, type, FROM, TO);
    }

    // Apply the From/To dates typed in the pop-up
    function applyDates() {
        var f = fromIn.value, t = toIn.value;
        if (!f && !t) { filterMsg.textContent = ''; load(cur.itemId, cur.type === 'OPENING' ? 'ALL' : cur.type, '', ''); return; }
        if (!ISO.test(f) || !ISO.test(t)) { filterMsg.textContent = 'Select both From and To dates.'; return; }
        if (f > t) { filterMsg.textContent = 'From Date cannot be after To Date.'; return; }
        filterMsg.textContent = '';
        // "Opening balance" view has no range; with a chosen range show the full ledger for it
        load(cur.itemId, cur.type === 'OPENING' ? 'ALL' : cur.type, f, t);
    }

    function load(itemId, type, from, to) {
        cur = { itemId: itemId, type: type, from: from, to: to };
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
                  '&toDate=' + encodeURIComponent(to);

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
        var period = d.allDates ? 'All dates'
                   : (t === 'OPENING' ? 'Before ' + d.fromDate : d.fromDate + ' to ' + d.toDate);
        subEl.textContent = d.itemName + '  |  ' + (d.category || '') +
                            (d.subCategory ? ' / ' + d.subCategory : '') + '  |  ' + period;

        clear(sumEl);
        if (t === 'ALL' && !d.allDates) sumEl.appendChild(chip('Opening:', fmt(d.opening)));
        if (t !== 'ISSUE') sumEl.appendChild(chip('Total Inward:', fmt(d.totalIn)));
        if (t !== 'RECEIPT') sumEl.appendChild(chip('Total Outward:', fmt(d.totalOut)));
        if (t === 'ALL') sumEl.appendChild(chip('Closing Balance:', fmt(d.closing)));
        if (t === 'OPENING') sumEl.appendChild(chip('Opening Balance:', fmt(d.closing)));
        sumEl.appendChild(chip('Entries:', String(d.rows.length)));

        clear(bodyEl);
        if (d.truncated) {
            bodyEl.appendChild(el('div', 'ldg-msg err',
                'Showing first ' + d.rows.length + ' entries only. Narrow the date range to see all.'));
        }
        if (!d.rows.length) {
            bodyEl.appendChild(el('div', 'ldg-msg', 'No transactions found.'));
            return;
        }

        var showIn = t !== 'ISSUE', showOut = t !== 'RECEIPT', showBal = (t === 'ALL' || t === 'OPENING');
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
