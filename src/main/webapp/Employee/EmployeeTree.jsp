<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
    font-family: 'Poppins', 'Inter', Arial, sans-serif;
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
   TIER 4+ VERTICAL REPORTING CHAIN 
   ======================================================== */
.vertical-group-container {
    width: 100%;
    display: block !important;
}

.tree ul.vertical-tier {
    display: flex !important;
    flex-direction: column !important;
    align-items: center !important;
    padding-top: 15px !important;
    position: relative;
    gap: 10px;
}

/* Clean central backbone line for vertical cards */
.tree ul.vertical-tier::before {
    content: '';
    position: absolute;
    top: 0;
    left: 50%;
    width: 0;
    height: 100%;
    border-left: 2px solid #cbd5e1;
    transform: translateX(-50%);
}

.tree ul.vertical-tier > li.compact-vertical-tier:last-child::after {
    content: '';
    position: absolute;
    left: 50%;
    bottom: -20px;
    width: 4px;
    height: 40px;
    background: #fff;
    transform: translateX(-50%);
    z-index: 2;
}

.tree ul.vertical-tier > li.compact-vertical-tier {
    position: relative;
    display: block !important;
    padding: 4px 0 !important;
    margin: 0 !important;
}

/* Completely remove stray connector styles from inheriting inside vertical list */
.tree ul.vertical-tier > li.compact-vertical-tier::before,
.tree ul.vertical-tier > li.compact-vertical-tier::after {
    display: none !important;
}

/* Horizontal line attaching central line to the side card */
.tree ul.vertical-tier > li.compact-vertical-tier .emp::before {
    content: '';
    position: absolute;
    left: -16px;
    top: 50%;
    width: 16px;
    border-top: 2px solid #cbd5e1;
    transform: translateY(-50%);
}

/* Compact Sidebar list card details */
.tree ul.vertical-tier > li.compact-vertical-tier .emp {
    width: 200px !important;
    min-height: 46px;
    display: flex !important;
    flex-direction: row !important;
    align-items: center !important;
    text-align: left !important;
    padding: 6px 10px !important;
    border-left: 3px solid #4f6ef7 !important;
    border-radius: 8px !important;
    background: #fff !important;
    position: relative;
}

.tree ul.vertical-tier > li.compact-vertical-tier .emp-img-container {
    width: 32px !important;
    height: 32px !important;
    margin: 0 10px 0 0 !important;
    flex-shrink: 0;
    border: 2px solid #4f6ef7 !important;
}

.tree ul.vertical-tier > li.compact-vertical-tier .emp-details-wrapper {
    display: flex;
    flex-direction: column;
    justify-content: center;
    overflow: hidden;
}

.tree ul.vertical-tier > li.compact-vertical-tier .emp-name {
    font-size: 12px !important;
    font-weight: 700;
    margin-bottom: 1px;
}

.tree ul.vertical-tier > li.compact-vertical-tier .emp-desg {
    font-size: 10px !important;
    color: #2563eb;
    margin-bottom: 1px;
}

.tree ul.vertical-tier > li.compact-vertical-tier .emp-id {
    font-size: 9px !important;
    color: #64748b;
}

.tree ul.vertical-tier ul {
    display: flex !important;
    flex-direction: column !important;
    align-items: center !important;
    padding-top: 10px !important;
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
    cursor: pointer; 
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

.emp.tier2-card{
    width:160px;
    padding:12px 8px;
}
.emp.tier2-card .emp-img-container{
    width:58px;
    height:58px;
    margin-bottom:9px;
}
.emp.tier2-card .emp-name{ font-size:13px; }
.emp.tier2-card .emp-desg{ font-size:11px; }
.emp.tier2-card .emp-id{ font-size:10px; }

.emp.tier3-card{
    width:140px;
    padding:10px 6px;
}
.emp.tier3-card .emp-img-container{
    width:50px;
    height:50px;
    margin-bottom:8px;
}
.emp.tier3-card .emp-name{ font-size:12px; }
.emp.tier3-card .emp-desg{ font-size:10px; }
.emp.tier3-card .emp-id{ font-size:9px; }

/* ==========================================================
   MODAL / POPUP CSS CODES
   ========================================================== */
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(15, 23, 42, 0.6); 
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
    font-size: 22px;
    font-weight: 700;
    color: #1e293b;
    margin-bottom: 6px;
}

.modal-desg {
    font-size: 14px;
    color: #3b82f6;
    font-weight: 600;
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

/* ==========================================================
   MULTI-NODE DEPARTMENT WRAPPER SYSTEM
   ========================================================== */
.dept-group-wrapper{
    display:flex !important;
    flex-direction:column !important;
    align-items:center;
    min-width:max-content;
}

.department-header{
    display:block;
    width:100%;
    min-width:300px;
    margin:0 auto 15px auto;
    padding:8px 15px;
    background:#f0fdf4;
    color:#166534;
    border:1px solid #bbf7d0;
    border-radius:8px;
    font-size:16px;
    font-weight:700;
    text-transform:uppercase;
    letter-spacing:.5px;
    text-align:center;
    box-shadow:0 2px 8px rgba(0,0,0,.08);
}

.inner-tier-container {
    display: flex !important;
    flex-direction: row !important;
    justify-content: center !important;
    padding-top: 0 !important;
    margin: 0 !important;
    gap: 16px;
}

.inner-tier-container::before {
    display: none !important;
}

.inner-tier-container > li {
    padding-top: 5px !important;
}

/* Separator Badge CSS */
.tier-separator{
    width:100%;
    margin:20px 0;
    text-align:center;
    position: relative;
    z-index: 5;
}

.tier-separator::before,
.tier-separator::after{
    display:none !important;
}

.tier-separator span{
    display:inline-block;
    padding:6px 14px;
    background:#f8fafc;
    border:1px solid #cbd5e1;
    border-radius:20px;
    font-size:11px;
    font-weight:700;
    color:#475569;
    text-transform:uppercase;
    letter-spacing:.5px;
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
    const defaultAvatar = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%2394a3b8'><path d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z'/></svg>";

    function sanitizeImages() {
        const images = document.querySelectorAll('.emp img');
        images.forEach(img => {
            let currentSrc = img.getAttribute('src');
            if(!currentSrc || currentSrc.trim() === "" || currentSrc.endsWith("?id=0") || currentSrc.endsWith("id=null")) {
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
    }
    sanitizeImages();

    const modal = document.getElementById('employeeModal');
    const closeModalBtn = document.getElementById('closeModalBtn');
    const modalImg = document.getElementById('modalImg');
    const modalName = document.getElementById('modalName');
    const modalDesg = document.getElementById('modalDesg');
    const modalId = document.getElementById('modalId');

    document.querySelector('.tree').addEventListener('click', function(e) {
        const empCard = e.target.closest('.emp');
        if (empCard) {
            const imgEl = empCard.querySelector('img');
            const nameEl = empCard.querySelector('.emp-name');
            const desgEl = empCard.querySelector('.emp-desg');
            const idEl = empCard.querySelector('.emp-id');

            modalImg.src = (imgEl && imgEl.src) ? imgEl.src : defaultAvatar;
            modalName.textContent = nameEl ? nameEl.textContent : 'N/A';
            modalDesg.textContent = desgEl ? desgEl.textContent : 'N/A';
            modalId.textContent = idEl ? idEl.textContent : 'ID: N/A';

            modal.classList.add('active');
        }
    });

    closeModalBtn.addEventListener('click', function() {
        modal.classList.remove('active');
    });

    modal.addEventListener('click', function(e) {
        if (e.target === modal) {
            modal.classList.remove('active');
        }
    });

    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && modal.classList.contains('active')) {
            modal.classList.remove('active');
        }
    });
});
</script>

</body>
</html>