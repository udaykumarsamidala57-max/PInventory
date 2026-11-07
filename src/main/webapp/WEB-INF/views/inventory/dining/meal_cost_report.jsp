<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) { response.sendRedirect("login.jsp"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Meal Cost per Head</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --primary: #1e3a8a; --text: #0f172a; --muted: #475569; --line: #cbd5e1; --border: #94a3b8; --warn: #8a5a00; }
        body { background: #f1f5f9; font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; color: var(--text); margin: 0; }
        .main-content { width: 90%; max-width: 1500px; margin: 24px auto; }
        .card { background: #fff; border: 2px solid var(--border); border-radius: 8px; box-shadow: 0 4px 12px rgba(15,23,42,.08); padding: 22px; }
        .head { display: flex; flex-wrap: wrap; gap: 12px; align-items: flex-end; justify-content: space-between; border-bottom: 2px solid var(--text); padding-bottom: 12px; margin-bottom: 16px; }
        h2 { margin: 0; font-size: 21px; text-transform: uppercase; letter-spacing: .5px; }
        .sub { margin: 4px 0 0; font-size: 12.5px; color: var(--muted); }
        form.filters { display: flex; flex-wrap: wrap; gap: 10px; align-items: flex-end; }
        form.filters label { display: flex; flex-direction: column; gap: 3px; font-size: 11.5px; font-weight: 700; text-transform: uppercase; }
        form.filters input { height: 36px; padding: 4px 8px; border: 1px solid var(--border); border-radius: 4px; font: inherit; }
        .btn { height: 36px; padding: 0 16px; background: var(--primary); color: #fff; border: 0; border-radius: 4px; font-weight: 700; cursor: pointer; }
        .btn-plain { background: #fff; color: var(--primary); border: 1px solid var(--primary); }
        .tiles { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 12px; margin-bottom: 16px; }
        .tile { border: 1px solid var(--line); border-radius: 6px; padding: 10px 14px; background: #f8fafc; }
        .tile span { display: block; font-size: 11px; text-transform: uppercase; color: var(--muted); font-weight: 700; letter-spacing: .4px; }
        .tile strong { font-size: 19px; }
        .alert { padding: 9px 12px; border-radius: 6px; border: 1px solid #f3d59b; background: #fff8eb; color: var(--warn); font-size: 13px; margin-bottom: 12px; }
        .table-wrap { overflow-x: auto; border: 1px solid var(--border); border-radius: 6px; }
        table { width: 100%; border-collapse: collapse; font-size: 13px; }
        th { background: var(--primary); color: #fff; font-size: 11.5px; text-transform: uppercase; letter-spacing: .4px; padding: 9px 10px; text-align: left; white-space: nowrap; }
        td { padding: 7px 10px; border-bottom: 1px solid var(--line); white-space: nowrap; }
        .num { text-align: right; font-variant-numeric: tabular-nums; }
        tr.day-total td { background: #e8eef9; font-weight: 700; border-bottom: 2px solid var(--border); }
        .missing { color: #b91c1c; font-weight: 600; }
        .note { font-size: 12px; color: var(--muted); margin-top: 10px; line-height: 1.5; }
        @media print { .filters, .noprint { display: none !important; } .main-content { width: 100%; } .card { border: 0; box-shadow: none; } th { background: #ddd; color: #000; } }
    </style>
</head>
<body>
<jsp:include page="/WEB-INF/views/layout/header.jsp" />
<div class="main-content">
  <div class="card">
    <div class="head">
      <div><h2>Meal Cost per Head</h2>
        <p class="sub">Dining Hall &middot; <c:out value="${fromText}"/> to <c:out value="${toText}"/> &middot; cost per head = session meal cost &divide; strength</p></div>
      <form class="filters" method="get" action="meal-cost">
        <label>From<input type="date" name="from" value="<c:out value='${from}'/>" required></label>
        <label>To<input type="date" name="to" value="<c:out value='${to}'/>" required></label>
        <button class="btn" type="submit">Show</button>
        <button class="btn btn-plain noprint" type="button" onclick="window.print()">Print</button>
      </form>
    </div>

    <c:if test="${not empty error}"><div class="alert"><c:out value="${error}"/></div></c:if>

    <div class="tiles">
      <div class="tile"><span>Total meal cost</span><strong><c:out value="${periodCost}"/></strong></div>
      <div class="tile"><span>Days</span><strong><c:out value="${dayCount}"/></strong></div>
      <div class="tile"><span>Average cost per head per day</span><strong><c:out value="${avgPerHeadPerDay}"/></strong></div>
    </div>

    <div class="table-wrap">
      <table>
        <thead><tr>
          <th>Date</th><th>Session</th><th class="num">Boarding</th><th class="num">Day Boarding</th><th class="num">Dayscholars</th>
          <th class="num">Staff</th><th class="num">Total Strength</th><th class="num">Issues</th><th class="num">Meal Cost</th><th class="num">Cost per Head</th>
        </tr></thead>
        <tbody>
        <c:if test="${empty days}"><tr><td colspan="10" style="text-align:center;color:#475569;padding:18px">No Dining Hall consumption or strength in this period.</td></tr></c:if>
        <c:forEach var="d" items="${days}">
          <c:forEach var="s" items="${d.sessions}" varStatus="st">
            <tr>
              <td><c:if test="${st.first}"><strong><c:out value="${d.date}"/></strong> <span style="color:#475569"><c:out value="${d.day}"/></span></c:if></td>
              <td><c:out value="${s.session}"/></td>
              <td class="num"><c:out value="${s.boarding}"/></td>
              <td class="num"><c:out value="${s.dayBoarding}"/></td>
              <td class="num"><c:out value="${s.dayScholars}"/></td>
              <td class="num"><c:out value="${s.staff}"/></td>
              <td class="num"><strong><c:out value="${s.total}"/></strong></td>
              <td class="num"><c:out value="${s.issues}"/></td>
              <td class="num"><c:out value="${s.cost}"/></td>
              <td class="num ${s.missing ? 'missing' : ''}"><strong><c:out value="${s.perHead}"/></strong></td>
            </tr>
          </c:forEach>
          <tr class="day-total">
            <td colspan="8"><c:out value="${d.date}"/> &mdash; day total<c:if test="${d.incomplete}"> <span class="missing">(a session has no strength)</span></c:if></td>
            <td class="num"><c:out value="${d.cost}"/></td>
            <td class="num"><c:out value="${d.perHead}"/></td>
          </tr>
        </c:forEach>
        </tbody>
      </table>
    </div>
    <p class="note">
      <strong>Meal cost</strong> = value of all Dining Hall issues of that date and session (unit price incl. GST from the Item Cost master).
      <strong>Cost per head</strong> = meal cost &divide; total strength of that session.
      <strong>Day cost per head</strong> = sum of the sessions' cost per head (what one person's meals cost that day); Adjustment entries are counted in the day's
      cost but not in the cost per head. Strength is entered on the DH Consumption Entry form, once per date and session.
    </p>
  </div>
</div>
</body>
</html>
