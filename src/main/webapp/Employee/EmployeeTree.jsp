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

/* Tier 4 staff vertical layout */

.vertical-tier{
    display:block !important;
    padding-top:15px;
    position:relative;
}

.vertical-tier > li{
    display:block;
    width:100%;
    margin:8px auto;
    padding-top:10px;
}

/* Remove horizontal lines */
.vertical-tier > li::before,
.vertical-tier > li::after{
    display:none;
}

/* Draw single vertical line */
.vertical-tier::before{
    content:'';
    position:absolute;
    left:50%;
    top:0;
    bottom:0;
    border-left:2px solid #cbd5e1;
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

<script>
document.addEventListener("DOMContentLoaded", function() {
    const images = document.querySelectorAll('.emp img');
    
    // A clean, high-resolution SVG profile user placeholder embedded directly into the script
    const defaultAvatar = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%2394a3b8'><path d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z'/></svg>";

    images.forEach(img => {
        // Handle immediate issues if src attributes evaluate to empty strings
        if(!img.getAttribute('src') || img.getAttribute('src').trim() === "" || img.getAttribute('src').endsWith("?id=0")) {
            img.src = defaultAvatar;
            if(img.parentElement) {
                img.parentElement.style.borderColor = '#cbd5e1';
            }
        }

        // Catches database loading issues or 404 stream dropouts
        img.onerror = function() {
            this.src = defaultAvatar; 
            if(this.parentElement) {
                this.parentElement.style.borderColor = '#cbd5e1'; 
            }
        };
    });
});
</script>

</body>
</html>