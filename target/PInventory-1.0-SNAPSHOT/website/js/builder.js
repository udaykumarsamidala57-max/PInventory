/* =========================================================
   PAGE BUILDER - behaviour
   Dialogs, design picker, page search, collapsing sections,
   "saved" messages and returning to the same place after saving.
   ========================================================= */
(function () {
    'use strict';

    // ---------- section designs (value saved = the code the website reads) ----------
    var TYPES = [
        { v: 'HERO',           n: 'Banner slider',      d: 'Large photo slideshow at the top of a page', i: 't-hero' },
        { v: 'DESC',           n: 'Text with photos',   d: 'Headings, text and pictures',                 i: 't-text' },
        { v: 'DESC2',          n: 'Text box',           d: 'Title and text in a framed box',              i: 't-box' },
        { v: 'DESC3',          n: 'Photo with text',    d: 'Picture with a text card; also a page banner', i: 't-photo' },
        { v: 'SIDE_DESIGN',    n: 'Side panel',         d: 'Picture and short text in the right column',  i: 't-side' },
        { v: 'DISTINCT',       n: 'Photo cards',        d: 'Cards that show text when pointed at',        i: 't-cards' },
        { v: 'DISTINCT2',      n: 'Card grid',          d: 'Grid of cards with pop-up details',           i: 't-grid' },
        { v: 'DISTINCT3',      n: 'Expanding panels',   d: 'Cards that widen when pointed at',            i: 't-panels' },
        { v: 'PERSON_DETAILS', n: 'Person profile',     d: 'Photo, name, role and biography',             i: 't-person' },
        { v: 'ACCORDION',      n: 'Accordion item',     d: 'A row that opens to show its text',           i: 't-accordion' },
        { v: 'DIRECTOR',       n: "Director's message", d: 'Video or photo with welcome text',            i: 't-director' },
        { v: 'LATEST_NEWS',    n: 'Latest news',        d: 'Shows the newest news automatically',         i: 't-news' },
        { v: 'UP_EVENT',       n: 'Upcoming events',    d: 'Shows upcoming events automatically',         i: 't-event' },
        { v: 'RECRUITMENT',    n: 'Job vacancies',      d: 'Shows current job openings',                  i: 't-jobs' }
    ];
    var ALIASES = { 'LATEST-NEWS': 'LATEST_NEWS', 'UP-EVENT': 'UP_EVENT', 'RECRUIT': 'RECRUITMENT', 'PERSON-DETAILS': 'PERSON_DETAILS' };

    function norm(v) {
        var u = String(v || '').trim().toUpperCase();
        return ALIASES[u] || u;
    }
    function typeOf(v) {
        var u = norm(v);
        for (var i = 0; i < TYPES.length; i++) if (TYPES[i].v === u) return TYPES[i];
        return null;
    }
    function esc(s) {
        return String(s).replace(/[&<>"']/g, function (c) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
        });
    }
    function icon(id) { return '<svg><use href="#' + id + '"/></svg>'; }

    var store = {
        get: function (k) { try { return window.localStorage.getItem(k); } catch (e) { return null; } },
        set: function (k, v) { try { window.localStorage.setItem(k, v); } catch (e) { } },
        sget: function (k) { try { return window.sessionStorage.getItem(k); } catch (e) { return null; } },
        sset: function (k, v) { try { window.sessionStorage.setItem(k, v); } catch (e) { } },
        sdel: function (k) { try { window.sessionStorage.removeItem(k); } catch (e) { } }
    };

    // ---------- friendly design names on section cards and outline ----------
    document.querySelectorAll('.js-type').forEach(function (el) {
        var t = typeOf(el.getAttribute('data-type'));
        el.innerHTML = t ? icon(t.i) + esc(t.n) : icon('t-block') + esc(el.textContent.trim() || 'Section');
    });
    document.querySelectorAll('.js-type-name').forEach(function (el) {
        var t = typeOf(el.getAttribute('data-type'));
        if (t) el.textContent = t.n;
    });

    // ---------- design picker (tiles) ----------
    function buildTypes(box, selected) {
        var name = box.getAttribute('data-name') || 'sectionType';
        var sel = norm(selected) || 'DESC';
        var list = TYPES.slice();
        if (selected && !typeOf(selected)) {
            // a design not in the list: keep it so saving never changes it by accident
            list.unshift({ v: String(selected).trim(), n: String(selected).trim(), d: 'Current design', i: 't-block' });
            sel = String(selected).trim();
        }
        box.innerHTML = list.map(function (t) {
            var checked = (norm(t.v) === norm(sel)) ? ' checked' : '';
            return '<label class="pb-type-tile"><input type="radio" name="' + name + '" value="' + esc(t.v) + '"' + checked + ' required>' +
                '<span class="tile"><span class="ico">' + icon(t.i) + '</span><span><b>' + esc(t.n) + '</b><small>' + esc(t.d) + '</small></span></span></label>';
        }).join('');
    }
    document.querySelectorAll('.js-types').forEach(function (box) {
        if (box.id !== 'editSectionTypes') buildTypes(box, 'DESC');
    });

    // ---------- dialogs ----------
    var lastFocus = null;
    function openModal(id) {
        var m = document.getElementById(id);
        if (!m) return;
        lastFocus = document.activeElement;
        m.classList.add('open');
        document.body.style.overflow = 'hidden';
        setTimeout(function () {
            var f = m.querySelector('input:not([type=hidden]):not([type=radio]):not([type=file]), textarea, select');
            if (f) f.focus();
        }, 60);
    }
    function closeModal(m) {
        if (typeof m === 'string') m = document.getElementById(m);
        if (!m) return;
        m.classList.remove('open');
        if (!document.querySelector('.pb-modal.open')) document.body.style.overflow = '';
        if (lastFocus && lastFocus.focus) lastFocus.focus();
    }
    window.openModal = openModal;
    window.closeModal = closeModal;

    document.addEventListener('click', function (e) {
        var opener = e.target.closest('[data-open]');
        if (opener) { e.preventDefault(); openModal(opener.getAttribute('data-open')); return; }
        var closer = e.target.closest('[data-close]');
        if (closer) { closeModal(closer.closest('.pb-modal')); return; }
        if (e.target.classList && e.target.classList.contains('pb-modal')) closeModal(e.target);
    });
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            var open = document.querySelectorAll('.pb-modal.open');
            if (open.length) closeModal(open[open.length - 1]);
        }
    });

    // ---------- fill dialogs ----------
    function setVal(id, v) { var el = document.getElementById(id); if (el) el.value = v == null ? '' : v; }

    document.querySelectorAll('.btn-edit-page').forEach(function (b) {
        b.addEventListener('click', function () {
            setVal('editPageId', b.getAttribute('data-id'));
            setVal('editPageTitle', b.getAttribute('data-title'));
            setVal('editPageSlug', b.getAttribute('data-slug'));
            setVal('editParentId', b.getAttribute('data-parent-id') || '');
            // a page cannot sit under itself
            var sel = document.getElementById('editParentId');
            if (sel) Array.prototype.forEach.call(sel.options, function (o) {
                o.disabled = (o.value && o.value === b.getAttribute('data-id'));
            });
            openModal('editPageModal');
        });
    });

    document.querySelectorAll('.btn-edit-section').forEach(function (b) {
        b.addEventListener('click', function () {
            var id = b.getAttribute('data-id');
            var contentEl = document.getElementById('section-content-data-' + id);
            setVal('editSectionId', id);
            setVal('editSectionSeq', b.getAttribute('data-seq'));
            setVal('editSectionTitle', b.getAttribute('data-title'));
            setVal('editSectionContent', contentEl ? contentEl.textContent : '');
            buildTypes(document.getElementById('editSectionTypes'), b.getAttribute('data-type'));
            var form = document.querySelector('#editSectionModal form');
            if (form) form.setAttribute('data-target', 'section-' + id);
            openModal('editSectionModal');
        });
    });

    document.querySelectorAll('.js-upload').forEach(function (b) {
        b.addEventListener('click', function () {
            var id = b.getAttribute('data-section');
            setVal('uploadSectionId', id);
            setVal('uploadSeq', b.getAttribute('data-seq') || '1');
            var t = b.getAttribute('data-section-title');
            var sub = document.getElementById('uploadSubtitle');
            if (sub) sub.textContent = t ? 'To the section "' + t + '".' : 'To this section.';
            var form = document.querySelector('#uploadModal form');
            if (form) { form.reset(); form.setAttribute('data-target', 'section-' + id); resetDrops(form); }
            setVal('uploadSectionId', id);
            setVal('uploadSeq', b.getAttribute('data-seq') || '1');
            openModal('uploadModal');
        });
    });

    document.querySelectorAll('.btn-edit-image').forEach(function (b) {
        b.addEventListener('click', function () {
            setVal('editImageId', b.getAttribute('data-id'));
            setVal('editImageSeq', b.getAttribute('data-seq'));
            setVal('editImageAlt', b.getAttribute('data-alt'));
            setVal('editImageH1', b.getAttribute('data-h1'));
            setVal('editImageH2', b.getAttribute('data-h2'));
            var prev = document.getElementById('editImagePreview');
            if (prev) {
                var src = b.getAttribute('data-src');
                prev.innerHTML = b.getAttribute('data-video') === 'true'
                    ? '<video src="' + esc(src) + '" muted preload="metadata"></video>'
                    : '<img src="' + esc(src) + '" alt="">';
            }
            var form = document.querySelector('#editImageModal form');
            if (form) { resetDrops(form); form.setAttribute('data-target', 'section-' + b.getAttribute('data-section')); }
            openModal('editImageModal');
        });
    });

    // ---------- file chooser with preview ----------
    function resetDrops(scope) {
        scope.querySelectorAll('.js-drop').forEach(function (d) {
            var input = d.querySelector('input[type=file]');
            if (input) input.value = '';
            var p = d.querySelector('.pb-drop-preview');
            if (p && p.getAttribute('data-empty')) p.innerHTML = p.getAttribute('data-empty');
            var b = d.querySelector('b');
            if (b && b.getAttribute('data-empty')) b.innerHTML = b.getAttribute('data-empty');
        });
    }
    document.querySelectorAll('.js-drop').forEach(function (d) {
        var input = d.querySelector('input[type=file]');
        var prev = d.querySelector('.pb-drop-preview');
        var label = d.querySelector('b');
        if (prev) prev.setAttribute('data-empty', prev.innerHTML);
        if (label) label.setAttribute('data-empty', label.innerHTML);
        ['dragenter', 'dragover'].forEach(function (ev) { d.addEventListener(ev, function () { d.classList.add('over'); }); });
        ['dragleave', 'drop'].forEach(function (ev) { d.addEventListener(ev, function () { d.classList.remove('over'); }); });
        input.addEventListener('change', function () {
            var f = input.files && input.files[0];
            if (!f) return;
            var url = URL.createObjectURL(f);
            if (prev) prev.innerHTML = f.type.indexOf('video/') === 0
                ? '<video src="' + url + '" muted></video>' : '<img src="' + url + '" alt="">';
            if (label) label.textContent = f.name + ' · ' + (f.size > 1048576 ? (f.size / 1048576).toFixed(1) + ' MB' : Math.round(f.size / 1024) + ' KB');
        });
    });

    // ---------- web address from the title (new page) ----------
    var t = document.getElementById('title'), s = document.getElementById('slug');
    if (t && s) {
        var touched = false;
        s.addEventListener('input', function () { touched = true; });
        t.addEventListener('input', function () {
            if (touched) return;
            s.value = t.value.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
        });
    }

    // ---------- page list: open groups, search ----------
    function setOpen(btn, open) {
        var g = document.getElementById('group-' + btn.getAttribute('data-group'));
        if (!g) return;
        g.classList.toggle('pb-hidden', !open);
        btn.classList.toggle('open', open);
        store.set('pb-group-' + btn.getAttribute('data-group'), open ? '1' : '0');
    }
    document.querySelectorAll('.pb-twisty[data-group]').forEach(function (btn) {
        if (btn.classList.contains('blank')) return;
        var g = document.getElementById('group-' + btn.getAttribute('data-group'));
        var hasActive = g && g.querySelector('.pb-node.active');
        setOpen(btn, !!hasActive || store.get('pb-group-' + btn.getAttribute('data-group')) === '1');
        btn.addEventListener('click', function () { setOpen(btn, btn.classList.contains('open') ? false : true); });
    });
    var activeNode = document.querySelector('.pb-node.active');
    if (activeNode && activeNode.scrollIntoView) activeNode.scrollIntoView({ block: 'nearest' });

    var search = document.getElementById('pageSearch');
    if (search) search.addEventListener('input', function () {
        var q = search.value.trim().toLowerCase();
        var any = false;
        document.querySelectorAll('#pageTree > .pb-tree-item').forEach(function (root) {
            var rootHit = (root.getAttribute('data-search') || '').indexOf(q) !== -1;
            var childHit = false;
            root.querySelectorAll('.pb-children > .pb-tree-item').forEach(function (ch) {
                var hit = !q || rootHit || (ch.getAttribute('data-search') || '').indexOf(q) !== -1;
                ch.classList.toggle('pb-hidden', !hit);
                if (q && (ch.getAttribute('data-search') || '').indexOf(q) !== -1) childHit = true;
            });
            var show = !q || rootHit || childHit;
            root.classList.toggle('pb-hidden', !show);
            if (show) any = true;
            var grp = root.querySelector('.pb-children');
            var tw = root.querySelector('.pb-twisty[data-group]');
            if (grp && q && childHit) { grp.classList.remove('pb-hidden'); if (tw) tw.classList.add('open'); }
        });
        var none = document.getElementById('treeNoMatch');
        if (none) none.classList.toggle('pb-hidden', any || !q);
    });

    // ---------- copy web address ----------
    document.querySelectorAll('.js-copy').forEach(function (c) {
        c.addEventListener('click', function () {
            var v = '/' + c.getAttribute('data-copy');
            if (navigator.clipboard) navigator.clipboard.writeText(v).then(function () { toast('Copied ' + v); });
        });
    });

    // ---------- long text: show more ----------
    document.querySelectorAll('.js-clamp').forEach(function (el) {
        if (el.scrollHeight <= 130) return;
        el.classList.add('clamp');
        var more = document.createElement('button');
        more.type = 'button';
        more.className = 'pb-more';
        more.textContent = 'Show more';
        more.addEventListener('click', function () {
            var c = el.classList.toggle('clamp');
            more.textContent = c ? 'Show more' : 'Show less';
        });
        el.parentNode.insertBefore(more, el.nextSibling);
    });

    // ---------- collapse sections (remembered) ----------
    var sections = Array.prototype.slice.call(document.querySelectorAll('.pb-section'));
    sections.forEach(function (sec) {
        var key = 'pb-sec-' + sec.getAttribute('data-section');
        if (store.get(key) === '1') sec.classList.add('collapsed');
        var btn = sec.querySelector('.pb-collapse');
        if (btn) btn.addEventListener('click', function () {
            var c = sec.classList.toggle('collapsed');
            store.set(key, c ? '1' : '0');
            updateToggleAll();
        });
    });
    var toggleAll = document.querySelector('.js-toggle-all');
    function updateToggleAll() {
        if (!toggleAll) return;
        var allCollapsed = sections.length && sections.every(function (s) { return s.classList.contains('collapsed'); });
        toggleAll.textContent = allCollapsed ? 'Expand all' : 'Collapse all';
    }
    if (toggleAll) {
        updateToggleAll();
        toggleAll.addEventListener('click', function (e) {
            e.preventDefault();
            var collapse = toggleAll.textContent.indexOf('Collapse') === 0;
            sections.forEach(function (sec) {
                sec.classList.toggle('collapsed', collapse);
                store.set('pb-sec-' + sec.getAttribute('data-section'), collapse ? '1' : '0');
            });
            updateToggleAll();
        });
    }

    // ---------- outline: highlight the section in view ----------
    var links = document.querySelectorAll('[data-outline]');
    if (links.length && 'IntersectionObserver' in window) {
        var io = new IntersectionObserver(function (entries) {
            entries.forEach(function (en) {
                if (!en.isIntersecting) return;
                links.forEach(function (a) { a.classList.toggle('current', a.getAttribute('data-outline') === en.target.id); });
            });
        }, { rootMargin: '-160px 0px -60% 0px' });
        sections.forEach(function (s) { io.observe(s); });
    }
    links.forEach(function (a) {
        a.addEventListener('click', function () {
            var sec = document.getElementById(a.getAttribute('data-outline'));
            if (sec && sec.classList.contains('collapsed')) sec.classList.remove('collapsed');
        });
    });

    // ---------- confirm before deleting ----------
    document.querySelectorAll('.js-confirm').forEach(function (a) {
        a.addEventListener('click', function (e) {
            if (!window.confirm(a.getAttribute('data-confirm') || 'Are you sure?')) { e.preventDefault(); return; }
            remember(a.getAttribute('data-flash'), a.getAttribute('data-target'));
        });
    });

    // ---------- saving: busy button, message and place after reload ----------
    function remember(msg, target) {
        store.sset('pb-flash', JSON.stringify({ msg: msg || 'Saved', target: target || '', y: window.scrollY }));
    }
    document.querySelectorAll('form[data-flash]').forEach(function (f) {
        f.addEventListener('submit', function () {
            var target = f.getAttribute('data-target') || (f.getAttribute('data-scroll') === 'end' ? 'end' : '');
            remember(f.getAttribute('data-flash'), target);
            var btn = f.querySelector('button[type=submit]');
            if (btn) {
                btn.disabled = true;
                btn.textContent = btn.classList.contains('js-busy') ? 'Uploading…' : 'Saving…';
            }
        });
    });

    function toast(msg) {
        var el = document.createElement('div');
        el.className = 'pb-toast';
        el.innerHTML = icon('i-check') + '<span>' + esc(msg) + '</span>';
        document.body.appendChild(el);
        setTimeout(function () { el.style.transition = 'opacity .3s'; el.style.opacity = '0'; }, 2600);
        setTimeout(function () { el.remove(); }, 3000);
    }

    var flash = store.sget('pb-flash');
    if (flash) {
        store.sdel('pb-flash');
        try {
            var f = JSON.parse(flash);
            toast(f.msg);
            var target = null;
            if (f.target === 'end') target = sections[sections.length - 1];
            else if (f.target) target = document.getElementById(f.target);
            if (target) {
                target.classList.remove('collapsed');
                setTimeout(function () {
                    target.scrollIntoView({ block: 'start' });
                    target.classList.add('flash');
                    setTimeout(function () { target.classList.remove('flash'); }, 1800);
                }, 50);
            } else if (f.y) {
                window.scrollTo(0, f.y);
            }
        } catch (e) { }
    }
})();
