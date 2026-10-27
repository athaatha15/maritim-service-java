<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    if (session.getAttribute("customerId") == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    String context = request.getContextPath();

    String customerName = (String) session.getAttribute("customerName");
    if (customerName == null || customerName.trim().isEmpty()) {
        customerName = "Pelanggan";
    }
%>

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Dashboard Pelanggan | Maritim Indonesia</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: Arial, Helvetica, sans-serif;
            background: #f2f5f9;
            color: #172b4d;
        }

        header {
            background: #092b52;
            color: white;
            padding: 20px 7%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 20px;
            flex-wrap: wrap;
        }

        .brand {
            font-size: 20px;
            font-weight: bold;
            letter-spacing: 1px;
        }

        nav {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }

        nav a {
            color: white;
            text-decoration: none;
            padding: 10px 13px;
            border-radius: 7px;
            font-size: 14px;
        }

        nav a:hover {
            background: rgba(255, 255, 255, 0.14);
        }

        nav .logout {
            background: #c93636;
        }

        nav .logout:hover {
            background: #a92525;
        }

        .hero {
            background: linear-gradient(120deg, #092b52, #1267a5);
            color: white;
            padding: 55px 7%;
        }

        .hero h1 {
            margin: 0 0 12px;
            font-size: 32px;
        }

        .hero p {
            margin: 0;
            line-height: 1.7;
            color: #e3edf8;
        }

        main {
            max-width: 1200px;
            margin: 35px auto;
            padding: 0 22px;
        }

        .section-title {
            margin-bottom: 8px;
            color: #092b52;
        }

        .section-description {
            color: #68788e;
            line-height: 1.6;
            margin-bottom: 25px;
        }

        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 22px;
        }

        .dashboard-card {
            background: white;
            padding: 28px;
            border-radius: 14px;
            box-shadow: 0 5px 22px rgba(15, 39, 68, 0.07);
            border: 1px solid #e7edf4;
            display: flex;
            flex-direction: column;
            align-items: flex-start;
        }

        .card-icon {
            width: 52px;
            height: 52px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 12px;
            background: #e3efff;
            color: #0b5da8;
            font-size: 25px;
            margin-bottom: 18px;
        }

        .dashboard-card h3 {
            color: #092b52;
            margin: 0 0 10px;
            font-size: 20px;
        }

        .dashboard-card p {
            color: #68788e;
            line-height: 1.7;
            margin: 0 0 22px;
            flex-grow: 1;
        }

        .btn {
            display: inline-block;
            text-decoration: none;
            text-align: center;
            background: #0b65b1;
            color: white;
            padding: 12px 18px;
            border-radius: 8px;
            font-weight: bold;
            font-size: 14px;
            transition: background 0.2s ease;
        }

        .btn:hover {
            background: #084b85;
        }

        .btn-history {
            background: #087f70;
        }

        .btn-history:hover {
            background: #066456;
        }

        .btn-fleet {
            background: #475569;
        }

        .btn-fleet:hover {
            background: #334155;
        }

        .btn-contact {
            background: #a34f16;
        }

        .btn-contact:hover {
            background: #813d10;
        }

        .quick-info {
            margin-top: 28px;
            padding: 24px;
            border-radius: 12px;
            background: #e6f1fc;
            border-left: 5px solid #0b65b1;
            line-height: 1.7;
        }

        .quick-info strong {
            color: #092b52;
        }

        footer {
            margin-top: 45px;
            padding: 25px 20px;
            text-align: center;
            color: #75839a;
            background: white;
            font-size: 13px;
        }

        @media (max-width: 700px) {
            header {
                padding: 18px 5%;
            }

            nav {
                width: 100%;
            }

            nav a {
                padding: 9px 10px;
            }

            .hero {
                padding: 38px 5%;
            }

            .hero h1 {
                font-size: 26px;
            }

            main {
                padding: 0 16px;
            }

            .dashboard-grid {
                grid-template-columns: 1fr;
            }

            .dashboard-card {
                padding: 23px;
            }
        }
    </style>
</head>

<body>

<header>
    <div class="brand">MARITIM INDONESIA</div>

    <nav>
        <a href="<%= context %>/customer/dashboard.jsp">Dashboard</a>
        <a href="<%= context %>/booking">Booking Kapal</a>
        <a href="<%= context %>/booking/history">Riwayat Booking</a>
        <a href="<%= context %>/#fleet">Fleet</a>
        <a href="<%= context %>/#contact">Contact</a>
        <a href="<%= context %>/logout" class="logout">Logout</a>
    </nav>
</header>

<section class="hero">
    <h1>Selamat Datang, <%= customerName %>!</h1>
    <p>
        Dashboard pelanggan Maritim Indonesia.<br>
        Kelola permintaan charter kapal dan pantau status booking
        kamu melalui satu halaman.
    </p>
</section>

<main>
    <h2 class="section-title">Dashboard Pelanggan</h2>

    <p class="section-description">
        Pilih menu di bawah ini untuk melanjutkan aktivitas kamu.
    </p>

    <div class="dashboard-grid">

<section class="dashboard-card">
    <div class="card-icon">&#128179;</div>
    <h3>Pembayaran Charter</h3>
    <p>
        Pantau nominal DP 50%, status pembayaran,
        dan sisa tagihan charter kapal. Pembayaran
        yang tersedia saat ini merupakan simulasi.
    </p>
    <a class="btn" href="<%= context %>/booking/history">
        Lihat Pembayaran
    </a>
</section>

        <section class="dashboard-card">
            <div class="card-icon">&#9875;</div>
            <h3>Booking Kapal</h3>
            <p>
                Ajukan permintaan charter kapal dengan memilih armada,
                menentukan lokasi operasi, tanggal mulai, durasi,
                dan kebutuhan operasional.
            </p>
            <a class="btn" href="<%= context %>/booking">
                Buat Booking
            </a>
        </section>

        <section class="dashboard-card">
            <div class="card-icon">&#128203;</div>
            <h3>Riwayat Booking</h3>
            <p>
                Lihat daftar permintaan charter yang pernah kamu buat,
                kode booking, kapal yang dipilih, tanggal mulai,
                durasi, serta status permintaan.
            </p>
            <a class="btn btn-history"
               href="<%= context %>/booking/history">
                Lihat Riwayat Booking
            </a>
        </section>

        <section class="dashboard-card">
            <div class="card-icon">&#128674;</div>
            <h3>Informasi Armada</h3>
            <p>
                Lihat informasi armada kapal dan kembali ke halaman
                utama untuk menjelajahi layanan Maritim Indonesia.
            </p>
            <a class="btn btn-fleet" href="<%= context %>/#fleet">
                Lihat Armada
            </a>
        </section>

        <section class="dashboard-card">
            <div class="card-icon">&#9993;</div>
            <h3>Hubungi Kami</h3>
            <p>
                Kunjungi bagian kontak di halaman utama untuk
                mendapatkan informasi lebih lanjut mengenai
                layanan charter kapal.
            </p>
            <a class="btn btn-contact" href="<%= context %>/#contact">
                Informasi Kontak
            </a>
        </section>

    </div>

    <section class="quick-info">
        <strong>Informasi Status Booking</strong><br>
        Setelah mengirim permintaan charter, kamu dapat membuka
        menu <strong>Riwayat Booking</strong> untuk melihat status
        yang tersimpan di sistem. Status persetujuan dan pembayaran
        akan mengikuti proses yang tersedia di aplikasi.
    </section>
</main>

<footer>
    &copy; 2026 Maritim Indonesia | Shipping Solutions
</footer>

</body>
</html>

