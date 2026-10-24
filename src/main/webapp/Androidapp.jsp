<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#142c70">
  <meta name="description" content="Download the Office Central ERP Android app.">
  <title>Download Office Central ERP for Android</title>
  <style>
    :root{font-family:Inter,"Segoe UI",Arial,sans-serif;color:#18345a;background:#f3f6fb;font-synthesis:none;text-rendering:optimizeLegibility}
    *{box-sizing:border-box}
    body{min-height:100vh;margin:0;display:grid;place-items:center;padding:24px;background:radial-gradient(ellipse at 15% 8%,#e6efff 0,transparent 36%),radial-gradient(ellipse at 90% 85%,#e6f7f5 0,transparent 34%),#f5f7fb}
    .card{width:min(100%,480px);padding:38px 34px 32px;border:1px solid #e2e9f2;border-radius:24px;background:#fff;box-shadow:0 24px 70px rgba(16,42,83,.12);text-align:center}
    .logo{display:block;width:min(100%,205px);height:auto;margin:0 auto 22px;animation:float 3s ease-in-out infinite}
    .eyebrow{margin:0 0 9px;color:#74849a;font-size:12px;font-weight:800;letter-spacing:.14em;text-transform:uppercase}
    h1{margin:0;color:#172f52;font-size:clamp(25px,6vw,32px);line-height:1.2;letter-spacing:-.035em}
    .intro{margin:12px auto 26px;max-width:340px;color:#6c7d93;font-size:15px;line-height:1.65}
    .download{display:flex;align-items:center;justify-content:center;gap:10px;min-height:54px;padding:14px 22px;border-radius:13px;background:#285fa6;color:#fff;text-decoration:none;font-size:15px;font-weight:750;box-shadow:0 8px 18px rgba(40,95,166,.2);transition:transform .18s ease,background .18s ease,box-shadow .18s ease}
    .download:hover{transform:translateY(-2px);background:#214f8c;box-shadow:0 11px 24px rgba(40,95,166,.25)}
    .download:focus-visible{outline:3px solid #ff8615;outline-offset:3px}
    .android{width:21px;height:21px;color:#12a66a;animation:bob 1.8s ease-in-out infinite}
    .helper{margin:18px 0 0;color:#8290a3;font-size:12px;line-height:1.5}
    .footer{margin-top:27px;padding-top:18px;border-top:1px solid #edf0f4;color:#8592a3;font-size:12px}
    @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-5px)}}
    @keyframes bob{0%,100%{transform:translateY(0)}50%{transform:translateY(-3px)}}
    @media(max-width:480px){body{padding:16px}.card{padding:32px 22px 26px;border-radius:20px}}
    @media(prefers-reduced-motion:reduce){*,*::before,*::after{animation:none!important;transition:none!important}}
  </style>
</head>
<body>
  <main class="card">
    <svg class="logo" viewBox="0 0 520 210" role="img" aria-label="OFC Office Central logo" xmlns="http://www.w3.org/2000/svg">
      <g font-family="Arial,Helvetica,sans-serif" font-weight="700" text-anchor="middle">
        <circle cx="120" cy="75" r="70" fill="#142c70"/><circle cx="260" cy="75" r="70" fill="#ff8615"/><circle cx="400" cy="75" r="70" fill="#0ba99d"/>
        <text x="120" y="100" fill="#fff" font-size="82">O</text><text x="260" y="101" fill="#fff" font-size="88">F</text><text x="400" y="100" fill="#fff" font-size="82">C</text>
        <text x="260" y="190" fill="#142c70" font-size="46" letter-spacing="-2">Office Central</text>
      </g>
    </svg>
    <p class="eyebrow">OFFICE CENTRAL ERP</p>
    <h1>Take work with you</h1>
    <p class="intro">Get the official Android app and access your work wherever you are.</p>
    <a class="download" href="<%= request.getContextPath() %>/mobile-app/pinventory.apk" download="OFC-ERP.apk">
      <svg class="android" viewBox="0 0 24 24" aria-hidden="true"><g fill="currentColor"><path d="M6 9a6 6 0 0 1 12 0H6Z"/><circle cx="9" cy="6.6" r=".65" fill="#fff"/><circle cx="15" cy="6.6" r=".65" fill="#fff"/><rect x="7" y="10" width="10" height="7" rx="1.4"/><rect x="4.5" y="10.5" width="2" height="6" rx="1"/><rect x="17.5" y="10.5" width="2" height="6" rx="1"/><rect x="8" y="16" width="2.4" height="4" rx="1.1"/><rect x="13.6" y="16" width="2.4" height="4" rx="1.1"/></g><path d="M8.5 4.5 7.2 2.8M15.5 4.5l1.3-1.7" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round"/></svg>
      Download for Android
    </a>
    <p class="helper">No sign-in required to download. Sign in with your ERP account after installing.</p>
    <div class="footer">Official OFC ERP Android app</div>
  </main>
</body>
</html>