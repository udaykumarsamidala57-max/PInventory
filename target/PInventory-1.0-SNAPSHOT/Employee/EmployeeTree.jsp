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
    display: table; /* Ensures the tree centers properly and respects inner elements */
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

/* Connectors using pseudo elements */
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

/* Employee Card Styling */
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
    transform: translateY(-5px);
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
    border-color: #3b82f6;
}

/* Fixed Image Container to prevent collapsing */
.emp-img-container {
    width: 65px;
    height: 65px;
    margin: 0 auto 10px auto;
    position: relative;
}

.emp img{
    display: block;
    width: 100%;
    height: 100%;
    border-radius: 50%;
    object-fit: cover; /* Prevents stretching */
    border: 3px solid #3b82f6;
    background-color: #f0f4f8; /* Placeholder color while loading */
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
    images.forEach(img => {
        img.onerror = function() {
            // Replaces broken image paths with a reliable UI placeholder
            this.src = 'https://cdn-images.mailchimp.com/icons/social-block/color-link-128.png'; 
            this.style.borderColor = '#cbd5e1'; 
        };
    });
});
</script>

</body>
</html>