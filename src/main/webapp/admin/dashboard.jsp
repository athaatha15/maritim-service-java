
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="com.maritim.dao.DatabaseConnection" %>
<%@ page import="javax.servlet.http.HttpSession" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page import="java.util.Locale" %>

<%!
    private String escapeHtml(Object value) {
        if (value == null) return "-";

        String text = String.valueOf(value);
        return text.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace("\"", "&quot;")
                   .replace("'", "&#39;");
    }

    private String formatMoney(NumberFormat currency, BigDecimal amount) {
        return currency.format(
            amount == null ? BigDecimal.ZERO : amount
        );
    }
%>

<%
    HttpSession adminSession = request.getSession(false);

    if (adminSession == null ||
        !"ADMIN".equals(adminSession.getAttribute("role"))) {
        response.sendError(403, "Halaman ini hanya untuk Admin.");
        return;
    }

    String message = request.getParameter("updated");
    String completed = request.getParameter("completed");
    String error = request.getParameter("error");

    NumberFormat currency =
        NumberFormat.getCurrencyInstance(Locale.forLanguageTag("id-ID"));

    long totalBookings = 0;
    long pendingBookings = 0;
    long approvedBookings = 0;
    long rejectedBookings = 0;
    long totalVessels = 0;
    long availableVessels = 0;

    BigDecimal totalCharter = BigDecimal.ZERO;
    BigDecimal dpCollected = BigDecimal.ZERO;
    BigDecimal outstandingBalance = BigDecimal.ZERO;

    String statsSql =
        "SELECT COUNT(*) AS total_bookings, " +
        "COALESCE(SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END), 0) AS pending_bookings, " +
        "COALESCE(SUM(CASE WHEN status = 'Approved' THEN 1 ELSE 0 END), 0) AS approved_bookings, " +
        "COALESCE(SUM(CASE WHEN status = 'Rejected' THEN 1 ELSE 0 END), 0) AS rejected_bookings, " +
        "COALESCE(SUM(CASE WHEN status IN ('Approved', 'Completed') THEN total_amount ELSE 0 END), 0) AS total_charter, " +
        "COALESCE(SUM(CASE WHEN payment_status IN ('DP Paid', 'Paid') THEN dp_amount ELSE 0 END), 0) AS dp_collected, " +
        "COALESCE(SUM(CASE WHEN status IN ('Approved', 'Completed') AND payment_status <> 'Paid' THEN remaining_amount ELSE 0 END), 0) AS outstanding_balance " +
        "FROM charter_requests";

    try (Connection statsConn = DatabaseConnection.getConnection();
         PreparedStatement statsPs = statsConn.prepareStatement(statsSql);
         ResultSet statsRs = statsPs.executeQuery()) {

        if (statsRs.next()) {
            totalBookings = statsRs.getLong("total_bookings");
            pendingBookings = statsRs.getLong("pending_bookings");
            approvedBookings = statsRs.getLong("approved_bookings");
            rejectedBookings = statsRs.getLong("rejected_bookings");

            totalCharter = statsRs.getBigDecimal("total_charter");
            dpCollected = statsRs.getBigDecimal("dp_collected");
            outstandingBalance = statsRs.getBigDecimal("outstanding_balance");
        }

    } catch (SQLException e) {
        application.log("Gagal mengambil statistik Admin", e);
    }

    try (Connection vesselConn = DatabaseConnection.getConnection();
         PreparedStatement vesselPs = vesselConn.prepareStatement(
             "SELECT COUNT(*) AS total_vessels, " +
             "COALESCE(SUM(CASE WHEN status = 'Available' THEN 1 ELSE 0 END), 0) AS available_vessels " +
             "FROM vessels");
         ResultSet vesselRs = vesselPs.executeQuery()) {

        if (vesselRs.next()) {
            totalVessels = vesselRs.getLong("total_vessels");
            availableVessels = vesselRs.getLong("available_vessels");
        }

    } catch (SQLException e) {
        application.log("Gagal mengambil statistik vessel", e);
    }

    String sql =
        "SELECT cr.id, cr.request_code, c.name AS customer_name, " +
        "c.company, c.email, c.phone, v.vessel_name, v.vessel_type, " +
        "cr.operation_location, cr.start_date, cr.duration_days, " +
        "cr.requirements, cr.status, cr.admin_notes, cr.created_at, " +
        "cr.total_amount, cr.dp_amount, cr.remaining_amount, " +
        "cr.payment_status, cr.payment_reference " +
        "FROM charter_requests cr " +
        "JOIN customers c ON cr.customer_id = c.id " +
        "JOIN vessels v ON cr.vessel_id = v.id " +
        "ORDER BY CASE WHEN cr.status = 'Pending' THEN 0 ELSE 1 END, " +
        "cr.created_at DESC";
%>

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>Admin Dashboard | Maritim Indonesia</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f1f5f9;
            color: #1e293b;
        }

        header {
            background: #102b46;
            color: white;
            padding: 20px 5%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
        }

        header h2 {
            margin: 0;
            font-size: 21px;
        }

        .header-actions {
            display: flex;
            gap: 10px;
            align-items: center;
            flex-wrap: wrap;
        }

        .logout {
            color: white;
            text-decoration: none;
            border: 1px solid #94a3b8;
            padding: 9px 14px;
            border-radius: 6px;
        }

        .logout:hover {
            background: #1e4264;
        }

        main {
            max-width: 1500px;
            margin: 30px auto;
            padding: 0 20px;
        }

        .page-title {
            margin-bottom: 22px;
        }

        .page-title h1 {
            margin-bottom: 8px;
        }

        .page-title p {
            color: #64748b;
            line-height: 1.6;
            margin-top: 0;
        }

        .management-menu {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-top: 18px;
        }

        .management-link {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 13px 20px;
            background: #0e7490;
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: bold;
            box-shadow: 0 3px 8px #00000015;
            transition: background 0.2s, transform 0.2s;
        }

        .management-link:hover {
            background: #155e75;
            transform: translateY(-1px);
        }

        .management-link .arrow {
            font-size: 18px;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }

        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 12px;
            border-left: 4px solid #2563eb;
            box-shadow: 0 3px 12px #0000000d;
            min-width: 0;
        }

        .stat-card.pending {
            border-left-color: #d97706;
        }

        .stat-card.approved {
            border-left-color: #15803d;
        }

        .stat-card.rejected {
            border-left-color: #b91c1c;
        }

        .stat-card.finance {
            border-left-color: #0f766e;
        }

        .stat-card.vessel {
            border-left-color: #0891b2;
        }

        .stat-label {
            color: #64748b;
            font-size: 13px;
            margin-bottom: 12px;
        }

        .stat-value {
            font-size: 25px;
            font-weight: bold;
            line-height: 1.4;
            overflow-wrap: anywhere;
        }

        .stat-detail {
            margin-top: 8px;
            font-size: 12px;
            color: #64748b;
            line-height: 1.5;
        }

        .panel {
            background: white;
            padding: 22px;
            border-radius: 12px;
            box-shadow: 0 3px 12px #0000000d;
            margin-bottom: 24px;
        }

        .panel h2 {
            margin-top: 0;
        }

        .notice {
            padding: 12px;
            margin-bottom: 18px;
            background: #dcfce7;
            color: #166534;
            border-radius: 7px;
        }

        .notice.error {
            background: #fee2e2;
            color: #991b1b;
        }

        .table-wrap {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 1250px;
        }

        th, td {
            padding: 12px;
            border-bottom: 1px solid #e2e8f0;
            text-align: left;
            vertical-align: top;
            font-size: 14px;
            line-height: 1.6;
        }

        th {
            background: #eaf0f6;
            color: #102b46;
            white-space: nowrap;
        }

        tbody tr:hover {
            background: #f8fafc;
        }

        .status {
            display: inline-block;
            padding: 5px 9px;
            border-radius: 20px;
            font-weight: bold;
            font-size: 12px;
            white-space: nowrap;
        }

        .pending-status {
            background: #fef3c7;
            color: #92400e;
        }

        .approved-status {
            background: #dcfce7;
            color: #166534;
        }

        .rejected-status {
            background: #fee2e2;
            color: #991b1b;
        }

        .completed-status {
            background: #dbeafe;
            color: #1d4ed8;
        }

        .other-status {
            background: #e2e8f0;
            color: #334155;
        }

        textarea {
            width: 180px;
            min-height: 60px;
            padding: 8px;
            margin-bottom: 6px;
            border: 1px solid #cbd5e1;
            border-radius: 5px;
            font-family: inherit;
            resize: vertical;
        }

        button {
            border: 0;
            padding: 9px 12px;
            border-radius: 5px;
            color: white;
            cursor: pointer;
            margin: 2px 0;
            font-weight: bold;
        }

        button:hover {
            opacity: 0.88;
        }

        .approve {
            background: #15803d;
        }

        .reject {
            background: #b91c1c;
        }

        .complete {
            background: #1d4ed8;
        }

        .muted {
            color: #64748b;
        }

        .empty-state {
            padding: 24px;
            text-align: center;
            color: #64748b;
        }

        footer {
            text-align: center;
            color: #64748b;
            padding: 25px;
            font-size: 13px;
        }

        @media (max-width: 1100px) {
            .stats-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 600px) {
            header {
                padding: 16px;
                flex-wrap: wrap;
            }

            header h2 {
                font-size: 16px;
            }

            main {
                padding: 0 10px;
                margin-top: 20px;
            }

            .stats-grid {
                grid-template-columns: 1fr;
            }

            .panel {
                padding: 12px;
            }

            .stat-value {
                font-size: 23px;
            }

            .management-link {
                width: 100%;
                justify-content: space-between;
            }
        }
    </style>
</head>

<body>

<header>
    <h2>Maritim Indonesia | Admin</h2>

    <div class="header-actions">
        <a class="logout"
           href="<%= request.getContextPath() %>/logout">
            Logout
        </a>
    </div>
</header>

<main>

    <section class="page-title">
        <h1>Dashboard Admin</h1>

        <p>
            Ringkasan booking charter kapal, pembayaran, dan pengelolaan armada
            Maritim Indonesia.
        </p>

        <div class="management-menu">
            <a class="management-link"
               href="<%= request.getContextPath() %>/admin/vessels">
                <span>🚢 Manajemen Vessel</span>
                <span class="arrow">→</span>
            </a>
        </div>
    </section>

    <% if ("1".equals(message)) { %>
        <div class="notice">
            Status booking berhasil diperbarui.
        </div>
    <% } %>

    <% if ("1".equals(completed)) { %>
        <div class="notice">
            Perjalanan berhasil diselesaikan. Customer sekarang dapat
            melunasi sisa tagihan.
        </div>
    <% } %>

    <% if (error != null) { %>
        <div class="notice error">
            <% if ("invalid_status".equals(error)) { %>
                Booking belum memenuhi syarat untuk diselesaikan.
                Pastikan status booking Approved dan DP Paid.
            <% } else if ("not_found".equals(error)) { %>
                Booking tidak ditemukan.
            <% } else if ("invalid_id".equals(error)) { %>
                ID booking tidak valid.
            <% } else if ("update_failed".equals(error)) { %>
                Status booking gagal diperbarui. Silakan coba lagi.
            <% } else { %>
                Terjadi kesalahan saat memproses booking.
            <% } %>
        </div>
    <% } %>

    <section class="stats-grid">

        <div class="stat-card">
            <div class="stat-label">Total Booking</div>
            <div class="stat-value"><%= totalBookings %></div>
            <div class="stat-detail">Seluruh permintaan charter</div>
        </div>

        <div class="stat-card pending">
            <div class="stat-label">Menunggu Persetujuan</div>
            <div class="stat-value"><%= pendingBookings %></div>
            <div class="stat-detail">Booking berstatus Pending</div>
        </div>

        <div class="stat-card approved">
            <div class="stat-label">Booking Disetujui</div>
            <div class="stat-value"><%= approvedBookings %></div>
            <div class="stat-detail">Booking berstatus Approved</div>
        </div>

        <div class="stat-card rejected">
            <div class="stat-label">Booking Ditolak</div>
            <div class="stat-value"><%= rejectedBookings %></div>
            <div class="stat-detail">Booking berstatus Rejected</div>
        </div>

        <div class="stat-card finance">
            <div class="stat-label">Total Nilai Charter</div>
            <div class="stat-value">
                <%= formatMoney(currency, totalCharter) %>
            </div>
            <div class="stat-detail">
                Total booking yang disetujui atau selesai
            </div>
        </div>

        <div class="stat-card finance">
            <div class="stat-label">DP Tercatat</div>
            <div class="stat-value">
                <%= formatMoney(currency, dpCollected) %>
            </div>
            <div class="stat-detail">
                DP pada booking DP Paid atau Paid
            </div>
        </div>

        <div class="stat-card pending">
            <div class="stat-label">Sisa Tagihan</div>
            <div class="stat-value">
                <%= formatMoney(currency, outstandingBalance) %>
            </div>
            <div class="stat-detail">
                Sisa tagihan yang belum lunas
            </div>
        </div>

        <div class="stat-card vessel">
            <div class="stat-label">Total Vessel</div>
            <div class="stat-value"><%= totalVessels %></div>
            <div class="stat-detail">
                <%= availableVessels %> kapal tersedia
            </div>
        </div>

    </section>

    <section class="panel">
        <h2>Booking Approval</h2>
        <p>Kelola permintaan charter kapal dari Customer.</p>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Kode Booking</th>
                        <th>Customer</th>
                        <th>Kapal</th>
                        <th>Jadwal</th>
                        <th>Lokasi &amp; Kebutuhan</th>
                        <th>Status Booking</th>
                        <th>Informasi Pembayaran</th>
                        <th>Catatan Admin</th>
                        <th>Tindakan</th>
                    </tr>
                </thead>

                <tbody>
                <%
                    try (Connection conn = DatabaseConnection.getConnection();
                         PreparedStatement ps = conn.prepareStatement(sql);
                         ResultSet rs = ps.executeQuery()) {

                        boolean hasData = false;

                        while (rs.next()) {
                            hasData = true;

                            long bookingId = rs.getLong("id");
                            String status = rs.getString("status");
                            String paymentStatus = rs.getString("payment_status");

                            String statusClass =
                                "Pending".equalsIgnoreCase(status)
                                    ? "pending-status"
                                    : "Approved".equalsIgnoreCase(status)
                                        ? "approved-status"
                                        : "Rejected".equalsIgnoreCase(status)
                                            ? "rejected-status"
                                            : "Completed".equalsIgnoreCase(status)
                                                ? "completed-status"
                                                : "other-status";
                %>

                    <tr>
                        <td>
                            <strong>
                                <%= escapeHtml(rs.getString("request_code")) %>
                            </strong>
                            <br>
                            <small>ID: <%= bookingId %></small>
                        </td>

                        <td>
                            <strong>
                                <%= escapeHtml(rs.getString("customer_name")) %>
                            </strong>
                            <br>
                            <%= escapeHtml(rs.getString("company")) %>
                            <br>
                            <%= escapeHtml(rs.getString("email")) %>
                            <br>
                            <%= escapeHtml(rs.getString("phone")) %>
                        </td>

                        <td>
                            <strong>
                                <%= escapeHtml(rs.getString("vessel_name")) %>
                            </strong>
                            <br>
                            <%= escapeHtml(rs.getString("vessel_type")) %>
                        </td>

                        <td>
                            <%= rs.getDate("start_date") %>
                            <br>
                            Durasi: <%= rs.getInt("duration_days") %> hari
                        </td>

                        <td>
                            <%= escapeHtml(rs.getString("operation_location")) %>
                            <br>
                            <small>
                                <%= escapeHtml(rs.getString("requirements")) %>
                            </small>
                        </td>

                        <td>
                            <span class="status <%= statusClass %>">
                                <%= escapeHtml(status) %>
                            </span>
                        </td>

                        <td>
                            <strong>Total Charter:</strong><br>
                            <%= formatMoney(currency, rs.getBigDecimal("total_amount")) %>

                            <br><br>

                            <strong>DP (50%):</strong><br>
                            <%= formatMoney(currency, rs.getBigDecimal("dp_amount")) %>

                            <br><br>

                            <strong>Sisa Tagihan:</strong><br>
                            <%= formatMoney(currency, rs.getBigDecimal("remaining_amount")) %>

                            <br><br>

                            <strong>Status Pembayaran:</strong><br>
                            <span class="status other-status">
                                <%= escapeHtml(paymentStatus) %>
                            </span>

                            <% if (rs.getString("payment_reference") != null) { %>
                                <br><br>
                                <strong>Referensi:</strong><br>
                                <small>
                                    <%= escapeHtml(rs.getString("payment_reference")) %>
                                </small>
                            <% } %>
                        </td>

                        <td>
                            <%= escapeHtml(rs.getString("admin_notes")) %>
                        </td>

                        <td>
                            <% if ("Pending".equalsIgnoreCase(status)) { %>

                                <form method="post"
                                      action="<%= request.getContextPath() %>/admin/booking-approval"
                                      onsubmit="return confirm('Yakin memproses booking ini?');">

                                    <input type="hidden"
                                           name="id"
                                           value="<%= bookingId %>">

                                    <textarea name="admin_notes"
                                              maxlength="5000"
                                              placeholder="Catatan Admin (opsional)"></textarea>

                                    <button class="approve"
                                            type="submit"
                                            name="action"
                                            value="approve">
                                        Approve
                                    </button>

                                    <button class="reject"
                                            type="submit"
                                            name="action"
                                            value="reject">
                                        Reject
                                    </button>
                                </form>

                            <% } else if (
                                "Approved".equalsIgnoreCase(status)
                                && "DP Paid".equalsIgnoreCase(paymentStatus)) { %>

                                <form method="post"
                                      action="<%= request.getContextPath() %>/admin/complete-charter"
                                      onsubmit="return confirm('Selesaikan perjalanan charter ini? Customer akan dapat melunasi sisa tagihan.');">

                                    <input type="hidden"
                                           name="booking_id"
                                           value="<%= bookingId %>">

                                    <button class="complete" type="submit">
                                        Selesaikan Perjalanan
                                    </button>
                                </form>

                            <% } else if (
                                "Completed".equalsIgnoreCase(status)
                                && "DP Paid".equalsIgnoreCase(paymentStatus)) { %>

                                <span class="status completed-status">
                                    Menunggu Pelunasan
                                </span>

                            <% } else if (
                                "Completed".equalsIgnoreCase(status)
                                && "Paid".equalsIgnoreCase(paymentStatus)) { %>

                                <span class="status approved-status">
                                    Selesai &amp; Lunas
                                </span>

                            <% } else { %>

                                <span class="muted">Tidak ada tindakan</span>

                            <% } %>
                        </td>
                    </tr>

                <%
                        }

                        if (!hasData) {
                %>

                    <tr>
                        <td colspan="9" class="empty-state">
                            Belum ada data booking.
                        </td>
                    </tr>

                <%
                        }

                    } catch (SQLException e) {
                        application.log(
                            "Gagal mengambil data booking Admin", e);
                %>

                    <tr>
                        <td colspan="9" class="empty-state">
                            Data booking gagal dimuat. Periksa koneksi
                            database dan log Tomcat.
                        </td>
                    </tr>

                <%
                    }
                %>
                </tbody>
            </table>
        </div>
    </section>

</main>

<footer>
    Maritim Indonesia &copy; 2026 — Admin Dashboard
</footer>

</body>
</html>
