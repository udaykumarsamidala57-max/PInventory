<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<% request.setAttribute("canDelete", com.website.bean.WebsiteDB.canDelete(session)); %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><c:choose><c:when test="${not empty activePage}">${fn:escapeXml(activePage.title)} &middot; Page Builder</c:when><c:otherwise>Page Builder</c:otherwise></c:choose></title>
    <link rel="stylesheet" href="<c:url value='/website/css/builder.css'/>">
</head>
<body>

<!-- icon set (used with <svg><use href="#i-name"/></svg>) -->
<svg width="0" height="0" style="position:absolute" aria-hidden="true">
    <defs>
        <symbol id="i-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></symbol>
        <symbol id="i-edit" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"/></symbol>
        <symbol id="i-trash" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6M10 11v6M14 11v6"/></symbol>
        <symbol id="i-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 6 6 6-6 6"/></symbol>
        <symbol id="i-down" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></symbol>
        <symbol id="i-search" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></symbol>
        <symbol id="i-image" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="m21 16-5-5-9 9"/></symbol>
        <symbol id="i-video" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="6" width="13" height="12" rx="2"/><path d="m16 10 5-3v10l-5-3"/></symbol>
        <symbol id="i-page" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9Z"/><path d="M14 3v6h6"/></symbol>
        <symbol id="i-folder" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z"/></symbol>
        <symbol id="i-home" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="m3 11 9-7 9 7"/><path d="M5 10v10h14V10"/></symbol>
        <symbol id="i-layers" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="m12 3 9 5-9 5-9-5Z"/><path d="m3 13 9 5 9-5"/></symbol>
        <symbol id="i-ext" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 4h6v6M20 4l-9 9M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/></symbol>
        <symbol id="i-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="m5 12 5 5 9-10"/></symbol>
        <symbol id="i-x" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></symbol>
        <symbol id="i-upload" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 16V4M7 9l5-5 5 5"/><path d="M4 16v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3"/></symbol>
        <symbol id="i-collapse" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m7 15 5-5 5 5"/></symbol>
        <!-- section type icons -->
        <symbol id="t-hero" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="2"/><path d="m8 12-2 0M18 12h-2M10 16h4"/></symbol>
        <symbol id="t-text" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M4 6h16M4 10h16M4 14h10M4 18h12"/></symbol>
        <symbol id="t-box" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="16" rx="1"/><path d="M7 9h10M7 13h10M7 17h6"/></symbol>
        <symbol id="t-photo" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="11" rx="1"/><path d="M3 18h18M3 21h12"/></symbol>
        <symbol id="t-side" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="1"/><path d="M15 3v18M5 7h7M5 11h7M5 15h5"/></symbol>
        <symbol id="t-cards" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="6" height="14" rx="1"/><rect x="9" y="5" width="6" height="14" rx="1"/><rect x="16" y="5" width="6" height="14" rx="1"/></symbol>
        <symbol id="t-grid" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="8" height="8" rx="1"/><rect x="13" y="3" width="8" height="8" rx="1"/><rect x="3" y="13" width="8" height="8" rx="1"/><rect x="13" y="13" width="8" height="8" rx="1"/></symbol>
        <symbol id="t-panels" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="11" height="16" rx="1"/><rect x="15" y="4" width="3" height="16" rx="1"/><rect x="20" y="4" width="2" height="16" rx="1"/></symbol>
        <symbol id="t-person" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></symbol>
        <symbol id="t-accordion" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="5" rx="1"/><rect x="3" y="10" width="18" height="11" rx="1"/><path d="m16 5 1 1 1-1"/></symbol>
        <symbol id="t-director" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="12" height="10" rx="1"/><path d="m7 8 3 2-3 2Z"/><path d="M17 6h5M17 10h5M17 14h4M2 19h20"/></symbol>
        <symbol id="t-news" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h13v16H6a2 2 0 0 1-2-2Z"/><path d="M17 8h3v10a2 2 0 0 1-2 2M8 8h5M8 12h5M8 16h3"/></symbol>
        <symbol id="t-event" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M8 3v4M16 3v4M3 10h18"/></symbol>
        <symbol id="t-jobs" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5h6v2M3 13h18"/></symbol>
        <symbol id="t-block" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/></symbol>
    </defs>
</svg>

<jsp:include page="/WEB-INF/views/layout/header.jsp" />
<link rel="stylesheet" href="${pageContext.request.contextPath}/website/css/erp-shell.css?v=20261020a">

<%-- ===== numbers used below: next free order numbers ===== --%>
<c:set var="nextSectionSeq" value="1" />
<c:set var="mediaTotal" value="0" />
<c:if test="${not empty activePage}">
    <c:forEach var="s" items="${activePage.sections}">
        <c:if test="${s.sequenceOrder >= nextSectionSeq}"><c:set var="nextSectionSeq" value="${s.sequenceOrder + 1}" /></c:if>
        <c:set var="mediaTotal" value="${mediaTotal + fn:length(s.images)}" />
    </c:forEach>
</c:if>
<c:set var="pageCount" value="${fn:length(pages)}" />

<div class="pb-app ${(empty activePage or empty activePage.sections) ? 'no-outline' : ''}">

    <!-- ================= PAGES (left) ================= -->
    <aside class="pb-side">
        <div class="pb-side-head">
            <div class="pb-side-title">
                <h2>Pages <span class="pb-count">${pageCount}</span></h2>
                <button type="button" class="pb-btn primary sm" data-open="createPageModal">
                    <svg><use href="#i-plus"/></svg> New page
                </button>
            </div>
            <label class="pb-search">
                <svg><use href="#i-search"/></svg>
                <input type="search" id="pageSearch" placeholder="Search pages..." autocomplete="off">
            </label>
        </div>

        <div class="pb-tree-label"><span>Main menu</span><span>Sub</span></div>
        <ul class="pb-tree" id="pageTree">
            <c:forEach var="p" items="${pages}">
                <c:if test="${empty p.parentId}">
                    <c:set var="subCount" value="0" />
                    <c:forEach var="chk" items="${pages}">
                        <c:if test="${chk.parentId == p.id}"><c:set var="subCount" value="${subCount + 1}" /></c:if>
                    </c:forEach>

                    <li class="pb-tree-item" data-search="${fn:escapeXml(fn:toLowerCase(p.title))} ${fn:escapeXml(fn:toLowerCase(p.slug))}">
                        <div class="pb-node ${activePage.id == p.id ? 'active' : ''}">
                            <button type="button" class="pb-twisty ${subCount > 0 ? '' : 'blank'}" data-group="${p.id}" aria-label="Show sub-pages">
                                <svg><use href="#i-chev"/></svg>
                            </button>
                            <a class="pb-node-link" href="pages?action=view&id=${p.id}" title="${fn:escapeXml(p.title)} &#10;/${fn:escapeXml(p.slug)}">
                                <span class="pb-node-ico">
                                    <c:choose>
                                        <c:when test="${fn:toLowerCase(p.slug) == 'home'}"><svg><use href="#i-home"/></svg></c:when>
                                        <c:when test="${subCount > 0}"><svg><use href="#i-folder"/></svg></c:when>
                                        <c:otherwise><svg><use href="#i-page"/></svg></c:otherwise>
                                    </c:choose>
                                </span>
                                <span class="pb-node-text">
                                    <span class="pb-node-title">${fn:escapeXml(p.title)}</span>
                                    <span class="pb-node-slug">/${fn:escapeXml(p.slug)}</span>
                                </span>
                                <c:if test="${subCount > 0}"><span class="pb-node-count">${subCount}</span></c:if>
                            </a>
                            <div class="pb-node-actions">
                                <button type="button" class="pb-icon-btn btn-edit-page" title="Edit page details"
                                        data-id="${p.id}" data-title="${fn:escapeXml(p.title)}"
                                        data-slug="${fn:escapeXml(p.slug)}" data-parent-id="${p.parentId}">
                                    <svg><use href="#i-edit"/></svg>
                                </button>
                                <c:if test="${canDelete}"><a href="pages?action=delete&id=${p.id}" class="pb-icon-btn danger js-confirm" title="Delete page"
                                   data-confirm="Delete the page &quot;${fn:escapeXml(p.title)}&quot; and all its sections? This cannot be undone."
                                   data-flash="Page deleted">
                                    <svg><use href="#i-trash"/></svg>
                                </a></c:if>
                            </div>
                        </div>

                        <c:if test="${subCount > 0}">
                            <ul class="pb-children pb-hidden" id="group-${p.id}">
                                <c:forEach var="sub" items="${pages}">
                                    <c:if test="${sub.parentId == p.id}">
                                        <li class="pb-tree-item" data-search="${fn:escapeXml(fn:toLowerCase(sub.title))} ${fn:escapeXml(fn:toLowerCase(sub.slug))}">
                                            <div class="pb-node ${activePage.id == sub.id ? 'active' : ''}">
                                                <span class="pb-twisty blank"></span>
                                                <a class="pb-node-link" href="pages?action=view&id=${sub.id}" title="${fn:escapeXml(sub.title)} &#10;/${fn:escapeXml(sub.slug)}">
                                                    <span class="pb-node-ico"><svg><use href="#i-page"/></svg></span>
                                                    <span class="pb-node-text">
                                                        <span class="pb-node-title">${fn:escapeXml(sub.title)}</span>
                                                        <span class="pb-node-slug">/${fn:escapeXml(sub.slug)}</span>
                                                    </span>
                                                </a>
                                                <div class="pb-node-actions">
                                                    <button type="button" class="pb-icon-btn btn-edit-page" title="Edit page details"
                                                            data-id="${sub.id}" data-title="${fn:escapeXml(sub.title)}"
                                                            data-slug="${fn:escapeXml(sub.slug)}" data-parent-id="${sub.parentId}">
                                                        <svg><use href="#i-edit"/></svg>
                                                    </button>
                                                    <c:if test="${canDelete}"><a href="pages?action=delete&id=${sub.id}" class="pb-icon-btn danger js-confirm" title="Delete page"
                                                       data-confirm="Delete the page &quot;${fn:escapeXml(sub.title)}&quot; and all its sections? This cannot be undone."
                                                       data-flash="Page deleted">
                                                        <svg><use href="#i-trash"/></svg>
                                                    </a></c:if>
                                                </div>
                                            </div>
                                        </li>
                                    </c:if>
                                </c:forEach>
                            </ul>
                        </c:if>
                    </li>
                </c:if>
            </c:forEach>
            <li class="pb-tree-empty pb-hidden" id="treeNoMatch">No pages match your search.</li>
            <c:if test="${pageCount == 0}">
                <li class="pb-tree-empty">No pages yet. Create your first page.</li>
            </c:if>
        </ul>
    </aside>

    <!-- ================= EDITOR (middle) ================= -->
    <main class="pb-main">
        <c:choose>
            <c:when test="${not empty activePage}">

                <c:set var="parentTitle" value="" />
                <c:forEach var="pp" items="${pages}">
                    <c:if test="${pp.id == activePage.parentId}"><c:set var="parentTitle" value="${pp.title}" /><c:set var="parentPageId" value="${pp.id}" /></c:if>
                </c:forEach>

                <div class="pb-pagebar" id="page-overview">
                    <div class="pb-crumbs">
                        <a href="pages">Pages</a>
                        <c:if test="${not empty parentTitle}">
                            <svg><use href="#i-chev"/></svg>
                            <a href="pages?action=view&id=${parentPageId}">${fn:escapeXml(parentTitle)}</a>
                        </c:if>
                        <svg><use href="#i-chev"/></svg>
                        <span>${fn:escapeXml(activePage.title)}</span>
                    </div>
                    <div class="pb-pagebar-row">
                        <div class="pb-page-title">
                            <span class="pb-page-ico"><svg><use href="#i-page"/></svg></span>
                            <div class="pb-page-head-text">
                                <span class="pb-object">Page<c:if test="${not empty parentTitle}"> &middot; under ${fn:escapeXml(parentTitle)}</c:if></span>
                                <h1>${fn:escapeXml(activePage.title)}</h1>
                            </div>
                            <span class="pb-chip mono js-copy" title="Click to copy" data-copy="${fn:escapeXml(activePage.slug)}">/${fn:escapeXml(activePage.slug)}</span>
                            <c:choose>
                                <c:when test="${not empty activePage.parentId}"><span class="pb-chip sub">Sub-page</span></c:when>
                                <c:otherwise><span class="pb-chip top">Menu page</span></c:otherwise>
                            </c:choose>
                        </div>
                        <div class="pb-actions">
                            <c:if test="${fn:toUpperCase(sessionScope.branch) == 'SRS'}">
                                <a class="pb-btn" target="_blank" rel="noopener"
                                   href="https://sandurschool-production.up.railway.app/homepage?slug=${fn:escapeXml(activePage.slug)}">
                                    <svg><use href="#i-ext"/></svg> View on website
                                </a>
                            </c:if>
                            <button type="button" class="pb-btn btn-edit-page"
                                    data-id="${activePage.id}" data-title="${fn:escapeXml(activePage.title)}"
                                    data-slug="${fn:escapeXml(activePage.slug)}" data-parent-id="${activePage.parentId}">
                                <svg><use href="#i-edit"/></svg> Page details
                            </button>
                            <button type="button" class="pb-btn primary" data-open="addSectionModal">
                                <svg><use href="#i-plus"/></svg> Add section
                            </button>
                        </div>
                    </div>
                    <div class="pb-meta">
                        <span>Sections<b>${fn:length(activePage.sections)}</b></span>
                        <span>Photos &amp; videos<b>${mediaTotal}</b></span>
                        <span>Web address<b>/${fn:escapeXml(activePage.slug)}</b></span>
                        <span>Menu position<b><c:choose><c:when test="${not empty parentTitle}">Under ${fn:escapeXml(parentTitle)}</c:when><c:otherwise>Main menu</c:otherwise></c:choose></b></span>
                        <c:if test="${not empty activePage.sections}">
                            <a href="#" class="js-toggle-all" style="margin-left:auto;color:var(--pb-accent-ink);font-weight:600">Collapse all</a>
                        </c:if>
                    </div>
                </div>

                <c:if test="${empty activePage.sections}">
                    <div class="pb-empty">
                        <div class="pb-empty-icon"><svg><use href="#i-layers"/></svg></div>
                        <h2>This page has no sections yet</h2>
                        <p>Sections are the building blocks of a page &mdash; a banner, text, photo cards, a person profile and so on.</p>
                        <button type="button" class="pb-btn primary" data-open="addSectionModal"><svg><use href="#i-plus"/></svg> Add the first section</button>
                    </div>
                </c:if>

                <c:forEach var="sec" items="${activePage.sections}">
                    <c:set var="nextImgSeq" value="1" />
                    <c:forEach var="im" items="${sec.images}">
                        <c:if test="${im.sequenceOrder >= nextImgSeq}"><c:set var="nextImgSeq" value="${im.sequenceOrder + 1}" /></c:if>
                    </c:forEach>

                    <section class="pb-section" id="section-${sec.id}" data-section="${sec.id}">
                        <div class="pb-section-head">
                            <span class="pb-order" title="Order on the page">${sec.sequenceOrder}</span>
                            <div class="pb-section-name">
                                <div class="pb-type js-type" data-type="${fn:escapeXml(sec.sectionType)}">${fn:escapeXml(sec.sectionType)}</div>
                                <h3>
                                    <c:choose>
                                        <c:when test="${not empty sec.title}">${fn:escapeXml(sec.title)}</c:when>
                                        <c:otherwise><span class="untitled">Untitled section</span></c:otherwise>
                                    </c:choose>
                                </h3>
                            </div>
                            <div class="pb-section-tools">
                                <button type="button" class="pb-icon-btn btn-edit-section" title="Edit section"
                                        data-id="${sec.id}" data-type="${fn:escapeXml(sec.sectionType)}"
                                        data-seq="${sec.sequenceOrder}" data-title="${fn:escapeXml(sec.title)}">
                                    <svg><use href="#i-edit"/></svg>
                                </button>
                                <c:if test="${canDelete}"><a href="pages?action=deleteSection&sectionId=${sec.id}&pageId=${activePage.id}"
                                   class="pb-icon-btn danger js-confirm" title="Delete section"
                                   data-confirm="Delete this section and all its photos? This cannot be undone."
                                   data-flash="Section deleted">
                                    <svg><use href="#i-trash"/></svg>
                                </a></c:if>
                                <button type="button" class="pb-icon-btn pb-collapse" title="Collapse / expand">
                                    <svg><use href="#i-down"/></svg>
                                </button>
                            </div>
                        </div>

                        <div class="pb-section-body">
                            <div class="pb-hidden" id="section-content-data-${sec.id}">${fn:escapeXml(sec.content)}</div>

                            <div class="pb-label"><span>Text</span></div>
                            <c:choose>
                                <c:when test="${not empty sec.content}">
                                    <div class="pb-text js-clamp">${fn:escapeXml(sec.content)}</div>
                                </c:when>
                                <c:otherwise>
                                    <div class="pb-text empty">No text for this section.</div>
                                </c:otherwise>
                            </c:choose>

                            <div class="pb-label">
                                <span>Photos &amp; videos &middot; ${fn:length(sec.images)}</span>
                            </div>
                            <div class="pb-media">
                                <c:forEach var="img" items="${sec.images}">
                                    <div class="pb-asset">
                                        <div class="pb-thumb">
                                            <c:choose>
                                                <c:when test="${fn:startsWith(img.imageType, 'video/')}">
                                                    <video preload="metadata" muted>
                                                        <source src="pages?action=renderImage&imageId=${img.id}" type="${fn:escapeXml(img.imageType)}">
                                                    </video>
                                                    <span class="pb-badge"><svg><use href="#i-video"/></svg>${img.sequenceOrder}</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <img src="pages?action=renderImage&imageId=${img.id}" alt="${fn:escapeXml(img.altText)}" loading="lazy">
                                                    <span class="pb-badge">${img.sequenceOrder}</span>
                                                </c:otherwise>
                                            </c:choose>
                                            <div class="pb-thumb-tools">
                                                <button type="button" class="pb-icon-btn btn-edit-image" title="Edit"
                                                        data-id="${img.id}" data-seq="${img.sequenceOrder}"
                                                        data-alt="${fn:escapeXml(img.altText)}"
                                                        data-h1="${fn:escapeXml(img.heading1)}" data-h2="${fn:escapeXml(img.heading2)}"
                                                        data-video="${fn:startsWith(img.imageType, 'video/')}"
                                                        data-src="pages?action=renderImage&imageId=${img.id}"
                                                        data-section="${sec.id}">
                                                    <svg><use href="#i-edit"/></svg>
                                                </button>
                                                <c:if test="${canDelete}"><a href="pages?action=deleteImage&imageId=${img.id}&pageId=${activePage.id}"
                                                   class="pb-icon-btn danger js-confirm" title="Delete"
                                                   data-confirm="Delete this photo / video?" data-flash="Photo deleted" data-target="section-${sec.id}">
                                                    <svg><use href="#i-trash"/></svg>
                                                </a></c:if>
                                            </div>
                                        </div>
                                        <div class="pb-caption">
                                            <c:choose>
                                                <c:when test="${not empty img.heading1}"><b>${fn:escapeXml(img.heading1)}</b></c:when>
                                                <c:otherwise><b class="none">No heading</b></c:otherwise>
                                            </c:choose>
                                            <c:choose>
                                                <c:when test="${not empty img.heading2}"><span>${fn:escapeXml(img.heading2)}</span></c:when>
                                                <c:when test="${not empty img.altText}"><span>${fn:escapeXml(img.altText)}</span></c:when>
                                            </c:choose>
                                        </div>
                                    </div>
                                </c:forEach>

                                <button type="button" class="pb-add-tile js-upload"
                                        data-section="${sec.id}" data-seq="${nextImgSeq}"
                                        data-section-title="${fn:escapeXml(sec.title)}">
                                    <svg><use href="#i-upload"/></svg>
                                    Add photo / video
                                </button>
                            </div>
                        </div>
                    </section>
                </c:forEach>

                <c:if test="${not empty activePage.sections}">
                    <button type="button" class="pb-add-section-bar" data-open="addSectionModal">
                        <svg><use href="#i-plus"/></svg> Add another section
                    </button>
                </c:if>

            </c:when>
            <c:otherwise>
                <div class="pb-empty">
                    <div class="pb-empty-icon"><svg><use href="#i-page"/></svg></div>
                    <h2>Choose a page to edit</h2>
                    <p>Pick a page from the list on the left, or create a new one. Each page is built from sections you can add, edit and reorder.</p>
                    <button type="button" class="pb-btn primary" data-open="createPageModal"><svg><use href="#i-plus"/></svg> Create a page</button>
                </div>
            </c:otherwise>
        </c:choose>
    </main>

    <!-- ================= OUTLINE (right) ================= -->
    <c:if test="${not empty activePage and not empty activePage.sections}">
        <nav class="pb-outline" aria-label="Page outline">
            <h4>On this page</h4>
            <ol>
                <c:forEach var="sec" items="${activePage.sections}">
                    <li>
                        <a href="#section-${sec.id}" data-outline="section-${sec.id}">
                            <i>${sec.sequenceOrder}</i>
                            <span>
                                <c:choose>
                                    <c:when test="${not empty sec.title}">${fn:escapeXml(sec.title)}</c:when>
                                    <c:otherwise>Untitled</c:otherwise>
                                </c:choose>
                                <small class="js-type-name" data-type="${fn:escapeXml(sec.sectionType)}">${fn:escapeXml(sec.sectionType)}</small>
                            </span>
                        </a>
                    </li>
                </c:forEach>
            </ol>
        </nav>
    </c:if>
</div>

<!-- ================= DIALOGS ================= -->

<!-- New page -->
<div class="pb-modal" id="createPageModal" role="dialog" aria-modal="true">
    <div class="pb-dialog">
        <form action="pages" method="post" data-flash="Page created">
            <input type="hidden" name="action" value="createPage">
            <div class="pb-dialog-head">
                <div><h3>New page</h3><p>It appears in the website menu, or under another page.</p></div>
                <button type="button" class="pb-icon-btn" data-close><svg><use href="#i-x"/></svg></button>
            </div>
            <div class="pb-dialog-body">
                <div class="pb-field">
                    <label for="title">Page title</label>
                    <input class="pb-input" type="text" id="title" name="title" required placeholder="e.g. Admissions">
                </div>
                <div class="pb-field">
                    <label for="slug">Web address <small>(filled in for you)</small></label>
                    <div class="pb-prefix"><span>/</span><input class="pb-input" type="text" id="slug" name="slug" required placeholder="admissions"></div>
                </div>
                <div class="pb-field">
                    <label for="parentId">Show it under</label>
                    <select class="pb-input" id="parentId" name="parentId">
                        <option value="">Top of the menu (main page)</option>
                        <c:forEach var="p" items="${pages}">
                            <c:if test="${empty p.parentId}">
                                <option value="${p.id}">${fn:escapeXml(p.title)}</option>
                            </c:if>
                        </c:forEach>
                    </select>
                </div>
            </div>
            <div class="pb-dialog-foot">
                <button type="button" class="pb-btn" data-close>Cancel</button>
                <button type="submit" class="pb-btn primary">Create page</button>
            </div>
        </form>
    </div>
</div>

<!-- Edit page -->
<div class="pb-modal" id="editPageModal" role="dialog" aria-modal="true">
    <div class="pb-dialog">
        <form action="pages" method="post" data-flash="Page details saved">
            <input type="hidden" name="action" value="updatePage">
            <input type="hidden" name="id" id="editPageId">
            <div class="pb-dialog-head">
                <div><h3>Page details</h3><p>Title, web address and where it sits in the menu.</p></div>
                <button type="button" class="pb-icon-btn" data-close><svg><use href="#i-x"/></svg></button>
            </div>
            <div class="pb-dialog-body">
                <div class="pb-field">
                    <label for="editPageTitle">Page title</label>
                    <input class="pb-input" type="text" id="editPageTitle" name="title" required>
                </div>
                <div class="pb-field">
                    <label for="editPageSlug">Web address</label>
                    <div class="pb-prefix"><span>/</span><input class="pb-input" type="text" id="editPageSlug" name="slug" required></div>
                    <div class="pb-hint">Changing this changes the page's link on the website.</div>
                </div>
                <div class="pb-field">
                    <label for="editParentId">Show it under</label>
                    <select class="pb-input" id="editParentId" name="parentId">
                        <option value="">Top of the menu (main page)</option>
                        <c:forEach var="p" items="${pages}">
                            <option value="${p.id}">${fn:escapeXml(p.title)} (/${fn:escapeXml(p.slug)})</option>
                        </c:forEach>
                    </select>
                </div>
            </div>
            <div class="pb-dialog-foot">
                <button type="button" class="pb-btn" data-close>Cancel</button>
                <button type="submit" class="pb-btn primary">Save changes</button>
            </div>
        </form>
    </div>
</div>

<c:if test="${not empty activePage}">

<!-- Add section -->
<div class="pb-modal" id="addSectionModal" role="dialog" aria-modal="true">
    <div class="pb-dialog wide">
        <form action="pages" method="post" data-flash="Section added" data-scroll="end">
            <input type="hidden" name="action" value="addSection">
            <input type="hidden" name="pageId" value="${activePage.id}">
            <div class="pb-dialog-head">
                <div><h3>Add a section</h3><p>Choose a design, then give it a title and text. Photos are added after.</p></div>
                <button type="button" class="pb-icon-btn" data-close><svg><use href="#i-x"/></svg></button>
            </div>
            <div class="pb-dialog-body">
                <div class="pb-field">
                    <label>Design</label>
                    <div class="pb-types js-types" data-name="sectionType"></div>
                </div>
                <div class="pb-row order">
                    <div class="pb-field">
                        <label>Section title</label>
                        <input class="pb-input" type="text" name="title" placeholder="e.g. Our campus">
                    </div>
                    <div class="pb-field">
                        <label>Order</label>
                        <input class="pb-input" type="number" name="sequenceOrder" value="${nextSectionSeq}" min="1" required>
                    </div>
                </div>
                <div class="pb-field">
                    <label>Text <small>(optional &middot; HTML allowed)</small></label>
                    <textarea class="pb-input" name="content" rows="6" placeholder="Write the section's text..."></textarea>
                </div>
            </div>
            <div class="pb-dialog-foot">
                <button type="button" class="pb-btn" data-close>Cancel</button>
                <button type="submit" class="pb-btn primary">Add section</button>
            </div>
        </form>
    </div>
</div>

<!-- Edit section -->
<div class="pb-modal" id="editSectionModal" role="dialog" aria-modal="true">
    <div class="pb-dialog wide">
        <form action="pages" method="post" data-flash="Section saved">
            <input type="hidden" name="action" value="updateSection">
            <input type="hidden" name="sectionId" id="editSectionId">
            <input type="hidden" name="pageId" value="${activePage.id}">
            <div class="pb-dialog-head">
                <div><h3>Edit section</h3><p>Change the design, order, title or text.</p></div>
                <button type="button" class="pb-icon-btn" data-close><svg><use href="#i-x"/></svg></button>
            </div>
            <div class="pb-dialog-body">
                <div class="pb-field">
                    <label>Design</label>
                    <div class="pb-types js-types" data-name="sectionType" id="editSectionTypes"></div>
                </div>
                <div class="pb-row order">
                    <div class="pb-field">
                        <label for="editSectionTitle">Section title</label>
                        <input class="pb-input" type="text" id="editSectionTitle" name="title">
                    </div>
                    <div class="pb-field">
                        <label for="editSectionSeq">Order</label>
                        <input class="pb-input" type="number" id="editSectionSeq" name="sequenceOrder" min="1" required>
                    </div>
                </div>
                <div class="pb-field">
                    <label for="editSectionContent">Text <small>(HTML allowed)</small></label>
                    <textarea class="pb-input" id="editSectionContent" name="content" rows="10"></textarea>
                </div>
            </div>
            <div class="pb-dialog-foot">
                <button type="button" class="pb-btn" data-close>Cancel</button>
                <button type="submit" class="pb-btn primary">Save section</button>
            </div>
        </form>
    </div>
</div>

<!-- Upload photo / video -->
<div class="pb-modal" id="uploadModal" role="dialog" aria-modal="true">
    <div class="pb-dialog">
        <form action="pages?action=uploadImage" method="post" enctype="multipart/form-data" data-flash="Photo added">
            <input type="hidden" name="pageId" value="${activePage.id}">
            <input type="hidden" name="sectionId" id="uploadSectionId">
            <div class="pb-dialog-head">
                <div><h3>Add photo or video</h3><p id="uploadSubtitle">To this section.</p></div>
                <button type="button" class="pb-icon-btn" data-close><svg><use href="#i-x"/></svg></button>
            </div>
            <div class="pb-dialog-body">
                <div class="pb-field">
                    <label class="pb-drop js-drop">
                        <input type="file" name="imageFile" accept="image/*,video/*" required>
                        <span class="pb-drop-preview"><svg><use href="#i-image"/></svg></span>
                        <span><b>Choose a file or drop it here</b><small>JPG, PNG, WebP or MP4 &middot; up to 200 MB</small></span>
                    </label>
                </div>
                <div class="pb-row">
                    <div class="pb-field">
                        <label>Heading 1 <small>(title)</small></label>
                        <input class="pb-input" type="text" name="heading1" placeholder="Main heading">
                    </div>
                    <div class="pb-field">
                        <label>Heading 2 <small>(subtitle)</small></label>
                        <input class="pb-input" type="text" name="heading2" placeholder="Sub heading">
                    </div>
                </div>
                <div class="pb-row order">
                    <div class="pb-field">
                        <label for="uploadAltText">Description</label>
                        <textarea class="pb-input" id="uploadAltText" name="altText" rows="3" placeholder="Short description (also read aloud for blind visitors)"></textarea>
                    </div>
                    <div class="pb-field">
                        <label>Order</label>
                        <input class="pb-input" type="number" name="sequenceOrder" id="uploadSeq" value="1" min="1" required>
                    </div>
                </div>
            </div>
            <div class="pb-dialog-foot">
                <button type="button" class="pb-btn" data-close>Cancel</button>
                <button type="submit" class="pb-btn primary js-busy"><svg><use href="#i-upload"/></svg> Upload</button>
            </div>
        </form>
    </div>
</div>

<!-- Edit photo / video -->
<div class="pb-modal" id="editImageModal" role="dialog" aria-modal="true">
    <div class="pb-dialog">
        <form action="pages?action=updateImage" method="post" enctype="multipart/form-data" data-flash="Photo saved">
            <input type="hidden" name="action" value="updateImage">
            <input type="hidden" name="imageId" id="editImageId">
            <input type="hidden" name="pageId" value="${activePage.id}">
            <div class="pb-dialog-head">
                <div><h3>Edit photo / video</h3><p>Change its text and order, or replace the file.</p></div>
                <button type="button" class="pb-icon-btn" data-close><svg><use href="#i-x"/></svg></button>
            </div>
            <div class="pb-dialog-body">
                <div class="pb-current">
                    <span class="pb-drop-preview" id="editImagePreview"></span>
                    <span><b>Current file</b><small>Choose a new file below only if you want to replace it.</small></span>
                </div>
                <div class="pb-row">
                    <div class="pb-field">
                        <label for="editImageH1">Heading 1 <small>(title)</small></label>
                        <input class="pb-input" type="text" id="editImageH1" name="heading1">
                    </div>
                    <div class="pb-field">
                        <label for="editImageH2">Heading 2 <small>(subtitle)</small></label>
                        <input class="pb-input" type="text" id="editImageH2" name="heading2">
                    </div>
                </div>
                <div class="pb-row order">
                    <div class="pb-field">
                        <label for="editImageAlt">Description</label>
                        <textarea class="pb-input" id="editImageAlt" name="altText" rows="3"></textarea>
                    </div>
                    <div class="pb-field">
                        <label for="editImageSeq">Order</label>
                        <input class="pb-input" type="number" id="editImageSeq" name="sequenceOrder" min="1" required>
                    </div>
                </div>
                <div class="pb-field">
                    <label class="pb-drop js-drop">
                        <input type="file" name="imageFile" accept="image/*,video/*">
                        <span class="pb-drop-preview"><svg><use href="#i-upload"/></svg></span>
                        <span><b>Replace file <small style="display:inline">(optional)</small></b><small>Leave empty to keep the current one</small></span>
                    </label>
                </div>
            </div>
            <div class="pb-dialog-foot">
                <button type="button" class="pb-btn" data-close>Cancel</button>
                <button type="submit" class="pb-btn primary js-busy">Save</button>
            </div>
        </form>
    </div>
</div>

</c:if>

<script src="<c:url value='/website/js/builder.js'/>"></script>

</body>
</html>
