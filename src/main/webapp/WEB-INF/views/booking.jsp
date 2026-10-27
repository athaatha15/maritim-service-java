
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="java.math.BigDecimal" %>
<%
    if (session.getAttribute("customerId") == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    List<Map<String, Object>> vessels =
        (List<Map<String, Object>>) request.getAttribute("vessels");

    String customerName = (String) session.getAttribute("customerName");
    String context = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Kapal | Maritim Indonesia</title>
    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f2f5fa;
            color: #18304b;
        }
        header {
            background: #102d4f;
            color: white;
            padding: 20px 7%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 16px;
            flex-wrap: wrap;
        }
        header a { color: white; text-decoration: none; }
        main { max-width: 900px; margin: 35px auto; padding: 0 18px; }
        .panel {
            background: white;
            padding: 30px;
            border-radius: 14px;
            box-shadow: 0 8px 30px rgba(16,45,79,.08);
        }
        h1 { margin-top: 0; color: #102d4f; }
        .intro { color: #64748b; line-height: 1.6; }
        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 18px;
        }
        .field { margin-top: 18px; }
        .full { grid-column: 1 / -1; }
        label {
            display: block;
            font-weight: bold;
            margin-bottom: 8px;
        }
        input, select, textarea {
            width: 100%;
            padding: 12px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font: inherit;
            background: white;
        }
        textarea { min-height: 100px; resize: vertical; }
        input:focus, select:focus, textarea:focus {
            outline: 2px solid #7db7f0;
            border-color: #2563eb;
        }
        .hint { color: #64748b; font-size: 13px; margin-top: 6px; }
        button {
            width: 100%;
            margin-top: 24px;
            padding: 15px;
            border: 0;
            border-radius: 8px;
            background: #e64b3c;
            color: white;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
        }
        button:hover { background: #c9382c; }
        .back { display: inline-block; margin-top: 20px; color: #175da8; }
        .empty {
            padding: 16px;
            border-radius: 8px;
            background: #fff4e5;
            color: #854d0e;
        }
        @media(max-width: 600px) {
            .grid { grid-template-columns: 1fr; }
            .full { grid-column: auto; }
            .panel { padding: 22px; }
        }
    </style>
</head>
<body>
<header>
    <strong>MARITIM INDONESIA</strong>
    <div>
        Halo, <%= customerName == null ? "Pelanggan" : customerName %>
        &nbsp; | &nbsp;
        <a href="<%= context %>/customer/dashboard.jsp">Dashboard</a>
    </div>
</header>

<main>
    <section class="panel">
        <h1>Form Pemesanan Kapal</h1>
        <p class="intro">
            Lengkapi detail perjalanan dan pilih kapal yang sesuai.
            Pemesanan akan tercatat dengan status Pending setelah dikirim.
        </p>

        <% if (vessels == null || vessels.isEmpty()) { %>
            <div class="empty">
                Saat ini tidak ada kapal berstatus Available.
            </div>
        <% } else { %>
        <form method="post" action="<%= context %>/booking">
            <div class="grid">
                <div class="field full">
                    <label for="vesselId">Pilih Kapal *</label>
                    <select id="vesselId" name="vesselId" required>
                        <option value="">-- Pilih kapal --</option>
                        <% for (Map<String, Object> vessel : vessels) {
                            Object id = vessel.get("id");
                            String name = String.valueOf(vessel.get("name"));
                            String type = String.valueOf(vessel.get("type"));
                            Object rate = vessel.get("rate");
                        %>
                        <option value="<%= id %>">
                            <%= name %> — <%= type %>
                            <% if (rate != null) { %>
                                (Rp <%= String.format("%,.0f",
                                    ((BigDecimal) rate).doubleValue()) %>/hari)
                            <% } %>
                        </option>
                        <% } %>
                    </select>
                </div>

                <div class="field">
                    <label for="origin">Lokasi Asal *</label>
                    <input id="origin" name="origin" type="text"
                           maxlength="90" placeholder="Contoh: Jakarta"
                           required>
                </div>

                <div class="field">
                    <label for="destination">Lokasi Tujuan *</label>
                    <input id="destination" name="destination" type="text"
                           maxlength="90" placeholder="Contoh: Balikpapan"
                           required>
                </div>

                <div class="field">
                    <label for="startDate">Tanggal Mulai *</label>
                    <input id="startDate" name="startDate" type="date"
                           required>
                </div>

                <div class="field">
                    <label for="durationDays">Durasi Sewa (hari) *</label>
                    <input id="durationDays" name="durationDays"
                           type="number" min="1" max="365"
                           value="1" required>
                </div>

                <div class="field full">
                    <label for="requirements">Kebutuhan Tambahan</label>
                    <textarea id="requirements" name="requirements"
                              maxlength="3000"
                              placeholder="Contoh: kebutuhan kru, jenis muatan, atau catatan lainnya"></textarea>
                    <div class="hint">Opsional, maksimal 3.000 karakter.</div>
                </div>
            </div>

            <button type="submit">Kirim Permintaan Booking</button>
        </form>
        <% } %>

        <a class="back" href="<%= context %>/customer/dashboard.jsp">
            &larr; Kembali ke Dashboard
        </a>
    </section>
</main>

<script>
    const dateInput = document.getElementById("startDate");
    if (dateInput) {
        const now = new Date();
        const localDate = new Date(
            now.getTime() - now.getTimezoneOffset() * 60000
        ).toISOString().slice(0, 10);
        dateInput.min = localDate;
    }
</script>
</body>
</html>

