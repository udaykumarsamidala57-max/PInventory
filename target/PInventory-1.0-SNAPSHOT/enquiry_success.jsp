<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Enquiry Submitted</title>

<style>
body {
    margin: 0;
    padding: 0;
    height: 100vh;
    font-family: 'Segoe UI', Arial, sans-serif;
    background: linear-gradient(135deg, #667eea, #764ba2);
    display: flex;
    align-items: center;
    justify-content: center;
}


.success-card {
    background: rgba(255,255,255,0.18);
    backdrop-filter: blur(12px);
    padding: 50px 60px;
    border-radius: 18px;
    box-shadow: 0 20px 40px rgba(0,0,0,0.2);
    text-align: center;
    color: #fff;
    animation: fadeSlide 0.8s ease;
}


.check-wrap {
    width: 110px;
    height: 110px;
    border-radius: 50%;
    border: 4px solid rgba(255,255,255,0.4);
    margin: 0 auto 25px;
    display: flex;
    align-items: center;
    justify-content: center;
    animation: ring 1s ease;
}

.checkmark {
    width: 55px;
    height: 30px;
    border-left: 6px solid #00ffb3;
    border-bottom: 6px solid #00ffb3;
    transform: rotate(-45deg);
    animation: tick 0.5s ease 0.8s forwards;
    opacity: 0;
}

h1 {
    margin: 0 0 10px;
    font-size: 28px;
    font-weight: 600;
}

p {
    margin: 6px 0;
    opacity: 0.9;
}


.btn {
    margin-top: 30px;
    padding: 12px 28px;
    border: none;
    border-radius: 30px;
    background: linear-gradient(135deg, #00ffb3, #00c6ff);
    color: #003333;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s;
}

.btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 10px 20px rgba(0,0,0,0.25);
}


@keyframes fadeSlide {
    from { opacity: 0; transform: translateY(20px) scale(0.95); }
    to { opacity: 1; transform: translateY(0) scale(1); }
}

@keyframes ring {
    from { transform: scale(0.5); opacity: 0; }
    to { transform: scale(1); opacity: 1; }
}

@keyframes tick {
    to { opacity: 1; }
}
</style>

</head>
<body>

<div class="success-card">
    <div class="check-wrap">
        <div class="checkmark"></div>
    </div>

    <h1>Enquiry Submitted!</h1>
    <p>Your admission enquiry has been saved successfully.</p>
    <p>Our team will contact you soon.</p>

   
</div>

<script>
function goBack() {
    window.location.href = "Enquiry.jsp";
}
</script>

</body>
</html>
