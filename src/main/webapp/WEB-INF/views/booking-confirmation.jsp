
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Date" %>
<%
    if (session.getAttribute("customerId") == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    String context = request.getContextPath();
    String bookingCode = (String) request.getAttribute("bookingCode");
    String vesselName = (String) request.getAttribute("vesselName");
    String location = (String) request.getAttribute("location");
    Date startDate = (Date) request.getAttribute("startDate");
    Integer duration = (Integer) request.getAttribute("duration");
    String status = (String) request.getAttribute("status");
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Konfirmasi Booking | Maritim Indonesia</title>
    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0;
            padding: 30px 16px;
            font-family: Arial, sans-serif;
            background: #f2f5fa;
            color: #18304b;
        }
        .card {
            max-width: 650px;
            margin: 30px auto;
            background: white;
            padding: 35px;
            border-radius: 15px;
            box-shadow: 0 8px 30px rgba(16,45,79,.09);
        }
        .check {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            background: #dcfce7;
            color: #15803d;
            display: grid;
            place-items: center;
            font-size: 32px;
        }
        h1 { color: #102d4f; }
        .code {
            padding: 18px;
            background: #eff6ff;
            border-radius: 9px;
            font-size: 23px;
            font-weight: bold;
            overflow-wrap: anywhere;
        }
        .detail {
            display: flex;
            justify-content: space-between;
            gap: 18px;
            padding: 14px 0;
            border-bottom: 1px solid #e2e8f0;
        }
        .detail span:first-child { color: #64748b; }
        .detail span:last-child {
            text-align: right;
            font-weight: bold;
        }
        .status {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            background: #fef3c7;
            color: #92400e;
        }
        a.button {
            display: block;
            text-align: center;
            margin-top: 25px;
            padding: 14px;
            border-radius: 8px;
            color: white;
            background: #102d4f;
            text-decoration: none;
            font-weight: bold;
        }
        @media(max-width: 480px) {
            .card { padding: 22px; }
            .detail { flex-direction: column; gap: 6px; }
            .detail span:last-child { text-align: left; }
        }
    </style>
</head>
<body>
<div class="card">
    <div class="check">&#10003;</div>
    <h1>Permintaan Booking Terkirim!</h1>
    <p>Permintaan kamu sudah tercatat. Simpan nomor booking berikut untuk referensi.</p>

    <p>Nomor Booking</p>
    <div class="code"><%= bookingCode %></div>

    <div class="detail">
        <span>Kapal</span>
        <span><%= vesselName %></span>
    </div>
    <div class="detail">
        <span>Rute</span>
        <span><%= location %></span>
    </div>
    <div class="detail">
        <span>Tanggal Mulai</span>
        <span><%= startDate %></span>
    </div>
    <div class="detail">
        <span>Durasi</span>
        <span><%= duration %> hari</span>
    </div>
    <div class="detail">
        <span>Status</span>
        <span><span class="status"><%= status %></span></span>
    </div>

    <a class="button" href="<%= context %>/customer/dashboard.jsp">
        Kembali ke Dashboard
    </a>
</div>
</body>
</html>

