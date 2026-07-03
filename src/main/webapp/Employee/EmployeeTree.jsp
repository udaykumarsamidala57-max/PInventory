<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Employee Organization Chart</title>

<style>
*{
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body{
    font-family: Arial, sans-serif;
    background: #f5f7fa;
    padding: 30px;
    color: #333;
}

h2 {
    text-align: center;
    margin-bottom: 30px;
    color: #2c3e50;
    font-size: 24px;
}

.tree-container{
    width: 100%;
    overflow: auto;
    padding: 40px 20px;
    background: #ffffff;
    border-radius: 12px;
    box-shadow: 0 4px 15px rgba(0,0,0,0.05);
}

.tree{
    display: table;
    margin: 0 auto;
}

.tree ul{
    padding-top: 20px;
    position: relative;
    display: flex;
    justify-content: center;
}

.tree li{
    list-style: none;
    text-align: center;
    position: relative;
    padding: 20px 10px 0 10px;
}

/* ========================================================
   STANDARD HORIZONTAL CONNECTORS (TIERS 1-3)
   ======================================================== */
.tree li::before,
.tree li::after{
    content: '';
    position: absolute;
    top: 0;
    right: 50%;
    width: 50%;
    height: 20px;
    border-top: 2px solid #cbd5e1;
}

.tree li::after{
    right: auto;
    left: 50%;
    border-left: 2px solid #cbd5e1;
}

.tree li:only-child::before,
.tree li:only-child::after{
    display: none;
}

.tree li:only-child{
    padding-top: 0;
}

.tree li:first-child::before,
.tree li:last-child::after{
    border: none;
}

.tree li:last-child::before{
    border-right: 2px solid #cbd5e1;
    border-radius: 0 5px 0 0;
}

.tree li:first-child::after{
    border-radius: 5px 0 0 0;
}

.tree ul ul::before{
    content: '';
    position: absolute;
    top: 0;
    left: 50%;
    border-left: 2px solid #cbd5e1;
    width: 0;
    height: 20px;
    transform: translateX(-50%);
}

/* ========================================================
   COMPACT VERTICAL LISTING OVERRIDES (TIER 4+)
   ======================================================== */

/* Switch container from horizontal flex row to a vertical list block */
.tree li.compact-vertical-tier > ul {
    flex-direction: column;
    align-items: center;
    padding-top: 10px;
}

/* Remove horizontal connector bars completely for Tier 4 list nodes */
.tree li.compact-vertical-tier > ul > li::before,
.tree li.compact-vertical-tier > ul > li::after {
    border: none !important;
}

/* Main single tracking line going straight down through the center of the list */
.tree li.compact-vertical-tier > ul::before {
    left: 50%;
    top: 0;
    height: 100%;
    border-left: 2px solid #cbd5e1;
    transform: translateX(-50%);
}

/* Spacing layout for the vertical list items */
.tree li.compact-vertical-tier > ul > li {
    padding: 6px 0;
    display: block;
    width: auto;
}

/* Transform the Card itself into a tiny, space-saving row banner */
.tree li.compact-vertical-tier > ul > li .emp {
    display: flex;
    align-items: center;
    flex-direction: row;
    width: 240px;                  /* Slightly wider bounding layout */
    padding: 6px 12px;             /* Tight padding to fit more cards */
    text-align: left;
    border-left: 4px solid #3b82f6; /* Decorative indicator strip */
}

/* Minimize Avatar Container inside Tier 4 List */
.tree li.compact-vertical-tier > ul > li .emp-img-container {
    width: 32px;
    height: 32px;
    margin: 0 12px 0 0; /* Shifted next to details instead of top centered */
    border: 1.5px solid #3b82f6;
}

/* Align text fields cleanly inside row layout */
.tree li.compact-vertical-tier > ul > li .emp-details-wrapper {
    display: flex;
    flex-direction: column;
    justify-content: center;
    overflow: hidden;
}

/* Shrink text sizes for micro presentation */
.tree li.compact-vertical-tier > ul > li .emp-name {
    font-size: 13px;
    margin-bottom: 1px;
}

.tree li.compact-vertical-tier > ul > li .emp-desg {
    font-size: 11px;
    margin-bottom: 0px;
}

.tree li.compact-vertical-tier > ul > li .emp-id {
    font-size: 10px;
}

/* ========================================================
   STANDARD EMPLOYEE CARD STYLING (TIERS 1-3)
   ======================================================== */
.emp{
    display: inline-block;
    width: 180px;
    background: #fff;
    border: 1px solid #e2e8f0;
    border-radius: 10px;
    padding: 15px 10px;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    position: relative;
    z-index: 10;
    transition: all 0.3s ease;
    cursor: pointer; /* Added to indicate clickability */
}

.emp:hover {
    transform: translateY(-3px);
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
    border-color: #3b82f6;
}

.emp-img-container {
    width: 65px;
    height: 65px;
    margin: 0 auto 10px auto;
    position: relative;
    border-radius: 50%;
    overflow: hidden;
    border: 3px solid #3b82f6;
    background-color: #f0f4f8; 
}

.emp img{
    display: block;
    width: 100%;
    height: 100%;
    object-fit: cover; 
}

.emp-details-wrapper {
    width: 100%;
}

.emp-name{
    font-size: 14px;
    font-weight: 700;
    color: #1e293b;
    margin-bottom: 4px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.emp-desg{
    font-size: 12px;
    color: #3b82f6;
    font-weight: 600;
    margin-bottom: 2px;
}

.emp-id{
    font-size: 11px;
    color: #64748b;
}

/* Responsive Scaling */
@media(max-width: 768px){
    .emp{
        width: 140px;
        padding: 10px 5px;
    }

    .emp-img-container {
        width: 50px;
        height: 50px;
    }
    
    .emp-name {
        font-size: 12px;
    }
    
    .emp-desg {
        font-size: 11px;
    }
}
/* Tier 3 - Horizontal but smaller */

.emp.tier3-card{
    width:140px;
    padding:10px 6px;
}

.emp.tier3-card .emp-img-container{
    width:50px;
    height:50px;
    margin-bottom:8px;
}

.emp.tier3-card .emp-name{
    font-size:12px;
}

.emp.tier3-card .emp-desg{
    font-size:10px;
}

.emp.tier3-card .emp-id{
    font-size:9px;
}
/* Tier 2 - Medium Size */

.emp.tier2-card{
    width:160px;
    padding:12px 8px;
}

.emp.tier2-card .emp-img-container{
    width:58px;
    height:58px;
    margin-bottom:9px;
}

.emp.tier2-card .emp-name{
    font-size:13px;
}

.emp.tier2-card .emp-desg{
    font-size:11px;
}

.emp.tier2-card .emp-id{
    font-size:10px;
}
/* Tier 4+ employees display vertically */

.compact-vertical-tier > ul{
    display:block !important;
    padding-top:15px;
}

.compact-vertical-tier > ul > li{
    display:block;
    padding:8px 0;
    margin:0 auto;
}

/* ==========================================================
   TIER 4+ EMPLOYEES - COMPACT VERTICAL LIST
   ========================================================== */

/* Parent UL becomes vertical */
.vertical-tier{
    display:flex !important;
    flex-direction:column !important;
    align-items:center;
    gap:6px;
    padding-top:15px;
    position:relative;
}

/* Center vertical line */
.vertical-tier::before{
    content:'';
    position:absolute;
    left:50%;
    top:0;
    bottom:0;
    border-left:2px solid #cbd5e1;
    transform:translateX(-50%);
}

/* Child LI */
.vertical-tier > li{
    display:block !important;
    padding:4px 0 !important;
    margin:0 !important;
    width:auto;
    position:relative;
}

/* Remove default tree horizontal connectors */
.vertical-tier > li::before,
.vertical-tier > li::after{
    display:none !important;
}

/* Small connector from line to card */
.vertical-tier > li .emp::before{
    content:'';
    position:absolute;
    left:-12px;
    top:50%;
    width:12px;
    border-top:2px solid #cbd5e1;
    transform:translateY(-50%);
}

/* Compact employee card */
.vertical-tier > li .emp{
    width:180px !important;
    min-height:48px;
    display:flex;
    align-items:center;
    text-align:left;
    padding:6px 10px;
    border-left:4px solid #3b82f6;
    border-radius:8px;
    background:#fff;
    position:relative;
}

/* Small photo */
.vertical-tier > li .emp-img-container{
    width:35px !important;
    height:35px !important;
    margin:0 10px 0 0 !important;
    flex-shrink:0;
    border:2px solid #3b82f6;
}

/* Details section */
.vertical-tier > li .emp-details-wrapper{
    display:flex;
    flex-direction:column;
    justify-content:center;
    overflow:hidden;
}

/* Smaller text */
.vertical-tier > li .emp-name{
    font-size:12px;
    font-weight:700;
    margin-bottom:1px;
    white-space:nowrap;
    overflow:hidden;
    text-overflow:ellipsis;
}

.vertical-tier > li .emp-desg{
    font-size:10px;
    margin-bottom:1px;
    color:#2563eb;
}

.vertical-tier > li .emp-id{
    font-size:9px;
    color:#64748b;
}

/* Remove nested horizontal tree layout */
.vertical-tier ul{
    display:flex !important;
    flex-direction:column !important;
    align-items:center;
    padding-top:8px;
}

.vertical-tier ul::before{
    left:50%;
    border-left:2px solid #cbd5e1;
}

/* ==========================================================
   MODAL / POPUP CSS CODES
   ========================================================== */
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(15, 23, 42, 0.6); /* Blurred translucent dark mask */
    backdrop-filter: blur(4px);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 9999;
    opacity: 0;
    pointer-events: none;
    transition: opacity 0.3s ease;
}

.modal-overlay.active {
    opacity: 1;
    pointer-events: auto;
}

.modal-card {
    background: #ffffff;
    width: 460px;
    padding: 30px 24px;
    border-radius: 16px;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.15), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    text-align: center;
    position: relative;
    transform: scale(0.9);
    transition: transform 0.3s ease;
}

.modal-overlay.active .modal-card {
    transform: scale(1);
}

.modal-close-btn {
    position: absolute;
    top: 14px;
    right: 16px;
    background: none;
    border: none;
    font-size: 24px;
    color: #94a3b8;
    cursor: pointer;
    transition: color 0.2s;
    line-height: 1;
}

.modal-close-btn:hover {
    color: #475569;
}

.modal-img-container {
    width: 200px;
    height: 200px;
    margin: 0 auto 20px auto;
    border-radius: 50%;
    overflow: hidden;
    border: 4px solid #3b82f6;
    box-shadow: 0 4px 10px rgba(59, 130, 246, 0.25);
}

.modal-img-container img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.modal-name {
    font-size: 40px;
    font-weight: 1200;
    color: #1e293b;
    margin-bottom: 6px;
}

.modal-desg {
    font-size: 14px;
    color: #3b82f6;
    font-weight: 1000;
    margin-bottom: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.modal-divider {
    height: 1px;
    background: #e2e8f0;
    margin: 15px 0;
}

.modal-id {
    font-size: 13px;
    color: #64748b;
}

</style>

</head>
<body>

<h2>Employee Organization Chart</h2>

<div class="tree-container">
    <div class="tree">
        <% 
            if (request.getAttribute("treeHtml") != null && !request.getAttribute("treeHtml").toString().trim().isEmpty()) { 
        %>
            <%= request.getAttribute("treeHtml") %>
        <% 
            } else { 
        %>
            <div style="text-align: center; color: #64748b; font-style: italic; padding: 20px;">
                No Employees Found to build the structure.
            </div>
        <% 
            } 
        %>
    </div>
</div>

<div class="modal-overlay" id="employeeModal">
    <div class="modal-card">
        <button class="modal-close-btn" id="closeModalBtn">&times;</button>
        <div class="modal-img-container">
            <img id="modalImg" src="" alt="Employee Profile">
        </div>
        <div class="modal-name" id="modalName">Employee Name</div>
        <div class="modal-desg" id="modalDesg">Designation</div>
        <div class="modal-divider"></div>
        <div class="modal-id" id="modalId">Employee ID: 0000</div>
    </div>
</div>

<script>
document.addEventListener("DOMContentLoaded", function() {
    const images = document.querySelectorAll('.emp img');
    
    // Default fallback SVG profile container image
    const defaultAvatar = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%2394a3b8'><path d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z'/></svg>";

    images.forEach(img => {
        if(!img.getAttribute('src') || img.getAttribute('src').trim() === "" || img.getAttribute('src').endsWith("?id=0")) {
            img.src = defaultAvatar;
            if(img.parentElement) {
                img.parentElement.style.borderColor = '#cbd5e1';
            }
        }

        img.onerror = function() {
            this.src = defaultAvatar; 
            if(this.parentElement) {
                this.parentElement.style.borderColor = '#cbd5e1'; 
            }
        };
    });

    // ==========================================================
    // POPUP MODAL JAVASCRIPT LOGIC
    // ==========================================================
    const modal = document.getElementById('employeeModal');
    const closeModalBtn = document.getElementById('closeModalBtn');
    
    const modalImg = document.getElementById('modalImg');
    const modalName = document.getElementById('modalName');
    const modalDesg = document.getElementById('modalDesg');
    const modalId = document.getElementById('modalId');

    // Event Delegation: Listens to any click inside the tree view component
    document.querySelector('.tree').addEventListener('click', function(e) {
        // Find if the click or any of its parents is an active ".emp" node element card
        const empCard = e.target.closest('.emp');
        
        if (empCard) {
            // Extract textual and graphic information safely from inside the targeted card
            const imgEl = empCard.querySelector('img');
            const nameEl = empCard.querySelector('.emp-name');
            const desgEl = empCard.querySelector('.emp-desg');
            const idEl = empCard.querySelector('.emp-id');

            // Apply fields directly into the matching Popup components
            modalImg.src = imgEl ? imgEl.src : defaultAvatar;
            modalName.textContent = nameEl ? nameEl.textContent : 'N/A';
            modalDesg.textContent = desgEl ? desgEl.textContent : 'N/A';
            modalId.textContent = idEl ? idEl.textContent : 'ID: N/A';

            // Show popup layout view window frame safely
            modal.classList.add('active');
        }
    });

    // Close functionality when hitting the 'X' button
    closeModalBtn.addEventListener('click', function() {
        modal.classList.remove('active');
    });

    // Close functionality when clicking outside the White Card box on the overlay background mask
    modal.addEventListener('click', function(e) {
        if (e.target === modal) {
            modal.classList.remove('active');
        }
    });

    // Accessibility: Allows exiting out using standard physical computer keyboard 'Escape' button
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && modal.classList.contains('active')) {
            modal.classList.remove('active');
        }
    });
});
</script>

</body>
</html>