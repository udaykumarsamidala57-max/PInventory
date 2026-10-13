<%@ page import="java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
Integer total = (Integer) request.getAttribute("total");
Integer day = (Integer) request.getAttribute("day");
Integer res = (Integer) request.getAttribute("res");
Integer semi = (Integer) request.getAttribute("semi");
Map<String, int[]> dashboardMatrix = (Map<String, int[]>) request.getAttribute("dashboardMatrix");
Map<String, int[]> capacityMap = (Map<String, int[]>) request.getAttribute("capacityMap");

String[] classOrder = {"Nursery","LKG","UKG","Class 1","Class 2","Class 3","Class 4","Class 5","Class 6","Class 7","Class 8","Class 9","Class 10"};
%>

<!DOCTYPE html>
<html>
<head>
    <title>Admission Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        body { font-family: 'Poppins', sans-serif; background: #f8fafc; padding: 20px; }
        .container { max-width: 1400px; margin: auto; }
        h2 { text-align: center; color: #1e3a8a; font-weight: 800; }
        .cards { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin: 30px 0; }
        .card { padding: 20px; border-radius: 15px; color: white; position: relative; }
        .card i { position: absolute; right: 15px; top: 15px; font-size: 40px; opacity: 0.3; }
        .card.total { background: #434E78; }
        .card.day { background: #607B8F; }
        .card.res { background: #F7E396; }
        .card.semi { background: #E97F4A; }

        .table-box { background: white; padding: 20px; border-radius: 15px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); margin-bottom: 30px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th { background: #0f2a4d; border: 1px solid; padding: 10px; color: white; font-size: 13px; }
        td { border: 1px solid #e2e8f0; padding: 8px; text-align: center; font-weight: 600; }
        .neg { color: red; background: #fff1f2; }
        .grand { background: #0f2a4d; color: white; }
    </style>
</head>
<body>

<jsp:include page="common_header.jsp" />

<div class="container">
    <h2>Sandur Residential School - Admission Dashboard 2026-27</h2>

    <div class="cards">
        <div class="card total"><i class="fa-solid fa-users"></i><h1><%= total %></h1><p>Enquiries</p></div>
        <div class="card day"><i class="fa-solid fa-sun"></i><h1><%= day %></h1><p>Day Scholars</p></div>
        <div class="card res"><i style="color:black" class="fa-solid fa-bed"></i><h1 style="color:black"><%= res %></h1><p style="color:black">Residential</p></div>
        <div class="card semi"><i class="fa-solid fa-bus"></i><h1><%= semi %></h1><p>Semi Res</p></div>
    </div>

    <div class="table-box">
        <h3>Class-wise Vacancy</h3>

        <table>
            <thead>
                <tr>
                    <th rowspan="2">Class</th>
                    <th colspan="3">Day Scholar</th>
                    <th colspan="6">Boarding (Residential)</th>
                    <th colspan="3">Boarding Total</th>
                    <th rowspan="2">Total<br>Cap</th>
                    <th rowspan="2">Total<br>Pres</th>
                    <th rowspan="2">Total<br>Vac</th>
                </tr>
                <tr>
                    <th>Cap</th><th>Pres</th><th>Vac</th>
                    <th>Cap G</th><th>Pres G</th><th>Vac G</th>
                    <th>Cap B</th><th>Pres B</th><th>Vac B</th>
                    <th>Cap</th><th>Pres</th><th>Vac</th>
                </tr>
            </thead>

            <tbody>
            <%
            int tDC=0,tDP=0,tDV=0;
            int tCGR=0,tPGR=0,tVGR=0;
            int tCBR=0,tPBR=0,tVBR=0;
            int tBRC=0,tBRP=0,tBRV=0;
            int tTC=0,tTP=0,tTV=0;

            for(String cls : classOrder) {

                int[] cap = capacityMap.getOrDefault(cls, new int[]{0,0,0,0});
                int[] ps  = dashboardMatrix.getOrDefault(cls, new int[]{0,0,0,0,0,0,0});

                int dCap = cap[0], gCap = cap[1], bCap = cap[2], totCap = cap[3];
                int dPres = ps[0] + ps[3];
                int gPres = ps[1], bPres = ps[2];

                int dVac = dCap - dPres;
                int gVac = gCap - gPres;
                int bVac = bCap - bPres;

                int brCap = gCap + bCap;
                int brPres = gPres + bPres;
                int brVac = brCap - brPres;

                int totPres = dPres + brPres;
                int totVac = totCap - totPres;

                tDC+=dCap; tDP+=dPres; tDV+=dVac;
                tCGR+=gCap; tPGR+=gPres; tVGR+=gVac;
                tCBR+=bCap; tPBR+=bPres; tVBR+=bVac;
                tBRC+=brCap; tBRP+=brPres; tBRV+=brVac;
                tTC+=totCap; tTP+=totPres; tTV+=totVac;
            %>
                <tr>
                    <td style="text-align:left;"><%= cls %></td>

                    <td><%= dCap %></td>
                    <td><%= dPres %></td>
                    <td class="<%= dVac<0?"neg":"" %>"><%= dVac %></td>

                    <td style="background:#fff7ed;"><%= gCap %></td>
                    <td style="background:#fff7ed;"><%= gPres %></td>
                    <td style="background:#fff7ed;" class="<%= gVac<0?"neg":"" %>"><%= gVac %></td>

                    <td style="background:#f0f9ff;"><%= bCap %></td>
                    <td style="background:#f0f9ff;"><%= bPres %></td>
                    <td style="background:#f0f9ff;" class="<%= bVac<0?"neg":"" %>"><%= bVac %></td>

                    <td style="background:#ecfeff;"><%= brCap %></td>
                    <td style="background:#ecfeff;"><%= brPres %></td>
                    <td style="background:#ecfeff;" class="<%= brVac<0?"neg":"" %>"><%= brVac %></td>

                    <td style="background:#f1f5f9;"><%= totCap %></td>
                    <td style="background:#f1f5f9;"><%= totPres %></td>
                    <td style="background:#f1f5f9;" class="<%= totVac<0?"neg":"" %>"><%= totVac %></td>
                </tr>
            <% } %>

                <tr class="grand">
                    <td>GRAND TOTAL</td>
                    <td><%= tDC %></td><td><%= tDP %></td><td><%= tDV %></td>
                    <td><%= tCGR %></td><td><%= tPGR %></td><td><%= tVGR %></td>
                    <td><%= tCBR %></td><td><%= tPBR %></td><td><%= tVBR %></td>
                    <td><%= tBRC %></td><td><%= tBRP %></td><td><%= tBRV %></td>
                    <td><%= tTC %></td><td><%= tTP %></td><td><%= tTV %></td>
                </tr>
            </tbody>
        </table>
    </div>
</div>
</body>
</html>
