
<%@ page import="java.util.List,java.util.Map" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page import="java.util.Locale" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%!
    private String escapeHtml(Object value) {
        if (value == null) return "";
        return String.valueOf(value)
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#39;");
    }

    private String statusClass(String status) {
        if (status == null) return "pending";

        switch (status.toLowerCase(Locale.ROOT)) {
            case "approved":
                return "approved";
            case "rejected":
                return "rejected";
            case "waiting for payment":
                return "payment";
            case "dp paid":
                return "paid";
            case "paid":
                return "paid";
            case "completed":
                return "completed";
            default:
                return "pending";
        }
    }

    private String formatCurrency(NumberFormat currency, Object amount) {
        if (amount instanceof Number) {
            return currency.format(amount);
        }
        return currency.format(0);
    }
%>

<%
    if (session.getAttribute("customerId") == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    List<Map<String, Object>> bookings =
        (List<Map<String, Object>>) request.getAttribute("bookings");

    SimpleDateFormat dateFormat =
        new SimpleDateFormat("dd MMM yyyy", new Locale("id", "ID"));

    NumberFormat currency =
        NumberFormat.getCurrencyInstance(new Locale("id", "ID"));

    String context = request.getContextPath();
    String paymentMessage = request.getParameter("payment");
%>

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Riwayat Booking | Maritim Indonesia</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f2f5f9;
            color: #172b4d;
        }

        header {
            background: #092b52;
            color: white;
            padding: 22px 7%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 16px;
            flex-wrap: wrap;
        }

        header a {
            color: white;
            text-decoration: none;
            margin-left: 18px;
        }

        header a:hover {
            text-decoration: underline;
        }

        main {
            max-width: 1100px;
            margin: 42px auto;
            padding: 0 20px;
        }

        .intro {
            margin-bottom: 26px;
        }

        .intro h1 {
            margin-bottom: 8px;
            color: #092b52;
        }

        .intro p {
            color: #617087;
            line-height: 1.6;
        }

        .notice {
            padding: 14px 16px;
            margin-bottom: 22px;
            border-radius: 9px;
            line-height: 1.6;
        }

        .notice-success {
            background: #d9f7e7;
            color: #176b43;
        }

        .notice-error {
            background: #ffe1e1;
            color: #a32020;
        }

        .booking-card {
            background: white;
            padding: 24px;
            margin-bottom: 22px;
            border-radius: 14px;
            box-shadow: 0 5px 20px rgba(15, 39, 68, .06);
            border: 1px solid #e7edf4;
        }

        .card-top {
            display: flex;
            justify-content: space-between;
            gap: 15px;
            flex-wrap: wrap;
            align-items: center;
        }

        .code {
            color: #617087;
            font-size: 13px;
            margin-bottom: 5px;
        }

        .card-top h2 {
            margin: 10px 0 0;
            color: #092b52;
        }

        .status {
            display: inline-block;
            padding: 7px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            background: #fff0cf;
            color: #885900;
        }

        .approved,
        .paid {
            background: #d9f7e7;
            color: #176b43;
        }

        .rejected {
            background: #ffe1e1;
            color: #a32020;
        }

        .payment {
            background: #dcecff;
            color: #174c91;
        }

        .completed {
            background: #e7e2ff;
            color: #5033a0;
        }

        .details {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 18px;
            margin-top: 22px;
        }

        .label {
            font-size: 12px;
            color: #75839a;
            margin-bottom: 7px;
        }

        .value {
            font-weight: bold;
            overflow-wrap: anywhere;
        }

        .payment-box {
            margin-top: 24px;
            padding: 20px;
            background: #f8fafc;
            border: 1px solid #dbe5ef;
            border-radius: 10px;
        }

        .payment-box h3 {
            margin: 0 0 12px;
            color: #092b52;
        }

        .payment-row {
            display: flex;
            justify-content: space-between;
            gap: 15px;
            padding: 12px 0;
            border-bottom: 1px solid #e2e8f0;
        }

        .payment-row > span:first-child {
            color: #617087;
        }

        .payment-row strong {
            text-align: right;
            overflow-wrap: anywhere;
        }

        .payment-note {
            margin: 14px 0 0;
            font-size: 13px;
            color: #617087;
            line-height: 1.6;
        }

        .payment-success {
            color: #176b43;
            line-height: 1.6;
        }

        .btn {
            display: inline-block;
            padding: 12px 18px;
            background: #0b65b1;
            color: white;
            text-decoration: none;
            border: 0;
            border-radius: 8px;
            margin-top: 18px;
            font-weight: bold;
            cursor: pointer;
            font-size: 14px;
        }

        .btn:hover {
            background: #084b85;
        }

        .btn-payment {
            background: #087f70;
        }

        .btn-payment:hover {
            background: #066456;
        }

        .empty {
            background: white;
            padding: 45px 20px;
            text-align: center;
            border-radius: 14px;
        }

        footer {
            text-align: center;
            color: #75839a;
            padding: 25px;
        }

        @media (max-width: 650px) {
            .details {
                grid-template-columns: 1fr;
            }

            header a {
                margin-left: 0;
            }

            nav {
                display: flex;
                gap: 12px;
                flex-wrap: wrap;
            }

            .booking-card {
                padding: 18px;
            }

            .payment-row {
                flex-wrap: wrap;
            }

            .payment-row strong {
                text-align: left;
            }
        }
    </style>
</head>

<body>

<header>
    <strong>MARITIM INDONESIA</strong>

    <nav>
        <a href="<%= context %>/customer/dashboard.jsp">Dashboard</a>
        <a href="<%= context %>/booking">Booking Kapal</a>
        <a href="<%= context %>/booking/history">Riwayat Booking</a>
        <a href="<%= context %>/logout">Logout</a>
    </nav>
</header>

<main>
    <section class="intro">
        <h1>Riwayat Booking</h1>
        <p>
            Pantau permintaan charter kapal dan informasi pembayaran kamu.
        </p>
    </section>

    <% if ("success".equals(paymentMessage)) { %>
        <div class="notice notice-success">
            Simulasi pembayaran DP berhasil diproses.
            Tidak ada uang sungguhan yang ditransfer.
        </div>

    <% } else if ("settled".equals(paymentMessage)) { %>
        <div class="notice notice-success">
            Simulasi pelunasan berhasil diproses.
            Status pembayaran telah lunas dan perjalanan tercatat selesai.
            Tidak ada uang sungguhan yang ditransfer.
        </div>

    <% } else if ("error".equals(paymentMessage)
            || "invalid_status".equals(paymentMessage)
            || "update_failed".equals(paymentMessage)
            || "invalid".equals(paymentMessage)) { %>
        <div class="notice notice-error">
            Pembayaran belum berhasil diproses.
            Periksa status booking kamu dan coba kembali.
        </div>

    <% } else if ("not_found".equals(paymentMessage)) { %>
        <div class="notice notice-error">
            Booking tidak ditemukan atau bukan milik akun Customer ini.
        </div>
    <% } %>

    <% if (bookings == null || bookings.isEmpty()) { %>

        <section class="empty">
            <h2>Belum Ada Booking</h2>
            <p>Pesanan kapal yang kamu buat akan muncul di halaman ini.</p>

            <a class="btn" href="<%= context %>/booking">
                Booking Kapal Sekarang
            </a>
        </section>

    <% } else { %>

        <% for (Map<String, Object> booking : bookings) {

            Object statusValue = booking.get("status");
            String status = statusValue == null
                ? "Pending" : String.valueOf(statusValue);

            Object paymentValue = booking.get("paymentStatus");
            String paymentStatus = paymentValue == null
                ? "Unpaid" : String.valueOf(paymentValue);

            Object startDate = booking.get("startDate");
        %>

        <article class="booking-card">

            <div class="card-top">
                <div>
                    <div class="code">Kode booking</div>

                    <strong>
                        <%= escapeHtml(booking.get("code")) %>
                    </strong>

                    <h2>
                        <%= escapeHtml(booking.get("vessel")) %>
                    </h2>
                </div>

                <span class="status <%= statusClass(status) %>">
                    <%= escapeHtml(status) %>
                </span>
            </div>

            <div class="details">
                <div>
                    <div class="label">Lokasi Operasi</div>
                    <div class="value">
                        <%= escapeHtml(booking.get("location")) %>
                    </div>
                </div>

                <div>
                    <div class="label">Tanggal Mulai</div>
                    <div class="value">
                        <% if (startDate instanceof java.util.Date) { %>
                            <%= escapeHtml(dateFormat.format(startDate)) %>
                        <% } else { %>
                            -
                        <% } %>
                    </div>
                </div>

                <div>
                    <div class="label">Durasi</div>
                    <div class="value">
                        <%= escapeHtml(booking.get("duration")) %> hari
                    </div>
                </div>
            </div>

            <section class="payment-box">
                <h3>Informasi Pembayaran</h3>

                <div class="payment-row">
                    <span>Total Charter</span>
                    <strong>
                        <%= formatCurrency(currency, booking.get("totalAmount")) %>
                    </strong>
                </div>

                <div class="payment-row">
                    <span>DP (50%)</span>
                    <strong>
                        <%= formatCurrency(currency, booking.get("dpAmount")) %>
                    </strong>
                </div>

                <div class="payment-row">
                    <span>Sisa Tagihan</span>
                    <strong>
                        <%= formatCurrency(currency, booking.get("remainingAmount")) %>
                    </strong>
                </div>

                <div class="payment-row">
                    <span>Status Pembayaran</span>
                    <strong>
                        <span class="status <%= statusClass(paymentStatus) %>">
                            <%= escapeHtml(paymentStatus) %>
                        </span>
                    </strong>
                </div>

                <% if ("Approved".equalsIgnoreCase(status)
                        && "Unpaid".equalsIgnoreCase(paymentStatus)) { %>

                    <form method="post"
                          action="<%= context %>/customer/simulated-payment"
                          onsubmit="return confirm('Ini hanya simulasi pembayaran DP 50%. Lanjutkan?');">

                        <input type="hidden"
                               name="booking_id"
                               value="<%= booking.get("id") %>">

                        <input type="hidden"
                               name="payment_type"
                               value="DP">

                        <button class="btn btn-payment" type="submit">
                            Bayar DP (Simulasi)
                        </button>
                    </form>

                    <p class="payment-note">
                        DP sebesar 50% dibayar setelah booking disetujui Admin.
                        Tidak ada transaksi uang sungguhan.
                    </p>

                <% } else if ("Approved".equalsIgnoreCase(status)
                        && "DP Paid".equalsIgnoreCase(paymentStatus)) { %>

                    <p class="payment-success">
                        DP sudah dibayar melalui simulasi. Menunggu Admin
                        menyelesaikan perjalanan charter sebelum pelunasan.
                    </p>

                <% } else if ("Completed".equalsIgnoreCase(status)
                        && "DP Paid".equalsIgnoreCase(paymentStatus)) { %>

                    <p class="payment-note">
                        Perjalanan charter telah selesai.
                        Silakan lunasi sisa tagihan.
                    </p>

                    <form method="post"
                          action="<%= context %>/customer/simulated-payment"
                          onsubmit="return confirm('Lanjutkan simulasi pelunasan sisa tagihan? Tidak ada uang sungguhan yang ditransfer.');">

                        <input type="hidden"
                               name="booking_id"
                               value="<%= booking.get("id") %>">

                        <input type="hidden"
                               name="payment_type"
                               value="FINAL">

                        <button class="btn btn-payment" type="submit">
                            Lunasi Sisa Tagihan
                        </button>
                    </form>

                    <p class="payment-note">
                        Pelunasan akan mengubah status pembayaran menjadi Paid.
                    </p>

                <% } else if ("Completed".equalsIgnoreCase(status)
                        && "Paid".equalsIgnoreCase(paymentStatus)) { %>

                    <p class="payment-success">
                        Perjalanan selesai dan pembayaran telah lunas.
                    </p>

                    <% if (booking.get("paymentReference") != null) { %>
                        <p class="payment-note">
                            Referensi simulasi:
                            <%= escapeHtml(booking.get("paymentReference")) %>
                        </p>
                    <% } %>

                <% } else if ("DP Paid".equalsIgnoreCase(paymentStatus)) { %>

                    <p class="payment-success">
                        DP sudah dibayar melalui simulasi.
                    </p>

                    <% if (booking.get("paymentReference") != null) { %>
                        <p class="payment-note">
                            Referensi simulasi:
                            <%= escapeHtml(booking.get("paymentReference")) %>
                        </p>
                    <% } %>

                <% } else if ("Paid".equalsIgnoreCase(paymentStatus)) { %>

                    <p class="payment-success">
                        Pembayaran telah lunas.
                    </p>

                <% } else if ("Rejected".equalsIgnoreCase(status)) { %>

                    <p class="payment-note">
                        Booking ditolak. Pembayaran tidak tersedia.
                    </p>

                <% } else if (!"Approved".equalsIgnoreCase(status)) { %>

                    <p class="payment-note">
                        Pembayaran DP tersedia setelah booking disetujui Admin.
                    </p>

                <% } %>

            </section>
        </article>

        <% } %>
    <% } %>

</main>

<footer>
    &copy; 2026 Maritim Indonesia | Shipping Solutions
</footer>

</body>
</html>
