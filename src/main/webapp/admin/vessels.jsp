
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List,java.util.Map,java.text.NumberFormat,java.util.Locale" %>

<%
    Object role = session.getAttribute("role");

    if (role == null || !"ADMIN".equals(role.toString())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    List<Map<String, Object>> vessels =
        (List<Map<String, Object>>) request.getAttribute("vessels");

    NumberFormat rupiah = NumberFormat.getCurrencyInstance(
        new Locale("id", "ID")
    );

    String result = request.getParameter("result");
%>

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Manajemen Vessel | Maritim Indonesia</title>

    <style>
        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f1f5f9;
            color: #172033;
        }

        header {
            background: #102b46;
            color: white;
            padding: 22px 5%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 15px;
            flex-wrap: wrap;
        }

        header h1 { margin: 0; font-size: 23px; }

        header a {
            color: white;
            text-decoration: none;
            border: 1px solid #ffffff66;
            padding: 10px 14px;
            border-radius: 7px;
        }

        main {
            width: 92%;
            max-width: 1250px;
            margin: 30px auto;
        }

        .intro {
            background: linear-gradient(120deg, #102b46, #176b87);
            color: white;
            padding: 26px;
            border-radius: 12px;
            margin-bottom: 24px;
        }

        .intro h2 { margin-top: 0; }

        .panel {
            background: white;
            padding: 24px;
            border-radius: 12px;
            margin-bottom: 25px;
            box-shadow: 0 4px 15px #102b4610;
        }

        .panel h2 {
            margin-top: 0;
            color: #102b46;
        }

        .form-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 16px;
        }

        .field {
            display: flex;
            flex-direction: column;
            gap: 7px;
        }

        .field.full { grid-column: 1 / -1; }

        label {
            font-size: 13px;
            font-weight: bold;
        }

        input, select, textarea {
            width: 100%;
            padding: 11px;
            border: 1px solid #cbd5e1;
            border-radius: 7px;
            font: inherit;
            background: white;
        }

        textarea {
            min-height: 85px;
            resize: vertical;
        }

        button, .btn {
            border: 0;
            border-radius: 7px;
            padding: 10px 14px;
            cursor: pointer;
            font-weight: bold;
            text-decoration: none;
            display: inline-block;
            font-size: 13px;
        }

        .primary { background: #0e7490; color: white; }
        .edit { background: #dbeafe; color: #1d4ed8; }
        .toggle { background: #ffedd5; color: #9a3412; }

        .notice {
            padding: 13px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            background: #dcfce7;
            color: #166534;
        }

        .error { background: #fee2e2; color: #991b1b; }

        .table-wrap { overflow-x: auto; }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 850px;
        }

        th, td {
            text-align: left;
            padding: 13px 12px;
            border-bottom: 1px solid #e2e8f0;
            vertical-align: top;
        }

        th {
            background: #102b46;
            color: white;
            font-size: 13px;
        }

        td { font-size: 13px; }

        .status {
            display: inline-block;
            padding: 5px 9px;
            border-radius: 20px;
            background: #dcfce7;
            color: #166534;
            font-size: 12px;
            font-weight: bold;
        }

        .unavailable {
            background: #fee2e2;
            color: #991b1b;
        }

        .actions {
            display: flex;
            flex-wrap: wrap;
            gap: 7px;
        }

        .edit-form {
            display: none;
            min-width: 290px;
            max-width: 420px;
            padding: 15px;
            background: #f8fafc;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            margin-top: 10px;
        }

        .edit-form.open { display: block; }
        .edit-form .field { margin-bottom: 11px; }

        footer {
            text-align: center;
            padding: 25px;
            color: #64748b;
        }

        @media (max-width: 650px) {
            .form-grid { grid-template-columns: 1fr; }
            .field.full { grid-column: auto; }
            .panel { padding: 16px; }
            header h1 { font-size: 19px; }
        }
    </style>
</head>

<body>

<header>
    <h1>MARITIM INDONESIA | ADMIN</h1>
    <a href="<%= request.getContextPath() %>/admin/dashboard.jsp">
        ← Dashboard
    </a>
</header>

<main>

    <section class="intro">
        <h2>Manajemen Vessel</h2>
        <p>Kelola armada, tarif sewa, kapasitas, lokasi, dan ketersediaan kapal langsung dari website.</p>
    </section>

    <% if ("added".equals(result) || "updated".equals(result)) { %>
        <div class="notice">
            Data vessel berhasil <%= "added".equals(result) ? "ditambahkan" : "diperbarui" %>.
        </div>
    <% } else if ("invalid".equals(result) || "notfound".equals(result)) { %>
        <div class="notice error">
            Data tidak valid atau vessel tidak ditemukan. Periksa kembali isianmu.
        </div>
    <% } %>

    <section class="panel">
        <h2>+ Tambah Vessel Baru</h2>

        <form method="post" action="<%= request.getContextPath() %>/admin/vessels">
            <input type="hidden" name="action" value="add">

            <div class="form-grid">

                <div class="field">
                    <label>Nama Vessel *</label>
                    <input name="vessel_name" required maxlength="200"
                           placeholder="Contoh: TB Marine Two">
                </div>

                <div class="field">
                    <label>Tipe Vessel *</label>
                    <input name="vessel_type" required maxlength="150"
                           placeholder="Contoh: Tug Boat">
                </div>

                <div class="field">
                    <label>Kapasitas / Spesifikasi</label>
                    <input name="capacity" placeholder="Contoh: 500 ton">
                </div>

                <div class="field">
                    <label>Lokasi</label>
                    <input name="location" placeholder="Lokasi kapal">
                </div>

                <div class="field">
                    <label>Tarif per Hari (Rp) *</label>
                    <input name="daily_rate" type="number" min="0"
                           step="0.01" required placeholder="15000000">
                </div>

                <div class="field">
                    <label>Status</label>
                    <select name="status">
                        <option value="Available">Available</option>
                        <option value="Unavailable">Unavailable</option>
                    </select>
                </div>

                <div class="field full">
                    <label>Deskripsi</label>
                    <textarea name="description"
                              placeholder="Deskripsi dan fungsi kapal"></textarea>
                </div>

                <div class="field">
                    <label>URL Gambar</label>
                    <input name="image_url" type="url"
                           placeholder="https://...">
                </div>

                <div class="field">
                    <label>Path Gambar (opsional)</label>
                    <input name="image_path" placeholder="Path gambar jika ada">
                </div>

            </div>

            <p>
                <button type="submit" class="primary">Simpan Vessel</button>
            </p>
        </form>
    </section>

    <section class="panel">
        <h2>Daftar Vessel</h2>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Vessel</th>
                        <th>Kapasitas</th>
                        <th>Lokasi</th>
                        <th>Tarif / Hari</th>
                        <th>Status</th>
                        <th>Kelola</th>
                    </tr>
                </thead>

                <tbody>
                <% if (vessels != null && !vessels.isEmpty()) {
                    for (Map<String, Object> v : vessels) {
                        String status = String.valueOf(v.get("status"));
                        int id = ((Number) v.get("id")).intValue();
                %>
                    <tr>
                        <td><%= id %></td>

                        <td>
                            <strong><%= v.get("name") == null ? "-" : v.get("name") %></strong><br>
                            <%= v.get("type") == null ? "-" : v.get("type") %><br>
                            <small><%= v.get("description") == null ? "" : v.get("description") %></small>
                        </td>

                        <td><%= v.get("capacity") == null ? "-" : v.get("capacity") %></td>
                        <td><%= v.get("location") == null ? "-" : v.get("location") %></td>
                        <td>
                            <strong>
                            <%= v.get("rate") == null ? "-" :
                                rupiah.format(v.get("rate")) %>
                            </strong>
                        </td>

                        <td>
                            <span class="status <%= "Available".equals(status) ? "" : "unavailable" %>">
                                <%= status %>
                            </span>
                        </td>

                        <td>
                            <div class="actions">
                                <button type="button" class="edit"
                                    onclick="toggleEdit(<%= id %>)">
                                    Edit
                                </button>

                                <form method="post"
                                      action="<%= request.getContextPath() %>/admin/vessels"
                                      onsubmit="return confirm('Ubah status vessel ini?')">
                                    <input type="hidden" name="action" value="toggle">
                                    <input type="hidden" name="id" value="<%= id %>">
                                    <button class="toggle" type="submit">
                                        Ubah Status
                                    </button>
                                </form>
                            </div>

                            <div id="edit-<%= id %>" class="edit-form">
                                <strong>Edit Vessel #<%= id %></strong>

                                <form method="post"
                                      action="<%= request.getContextPath() %>/admin/vessels">
                                    <input type="hidden" name="action" value="edit">
                                    <input type="hidden" name="id" value="<%= id %>">

                                    <div class="field">
                                        <label>Nama Vessel</label>
                                        <input name="vessel_name" required
                                            value="<%= v.get("name") == null ? "" : v.get("name") %>">
                                    </div>

                                    <div class="field">
                                        <label>Tipe Vessel</label>
                                        <input name="vessel_type" required
                                            value="<%= v.get("type") == null ? "" : v.get("type") %>">
                                    </div>

                                    <div class="field">
                                        <label>Kapasitas</label>
                                        <input name="capacity"
                                            value="<%= v.get("capacity") == null ? "" : v.get("capacity") %>">
                                    </div>

                                    <div class="field">
                                        <label>Lokasi</label>
                                        <input name="location"
                                            value="<%= v.get("location") == null ? "" : v.get("location") %>">
                                    </div>

                                    <div class="field">
                                        <label>Tarif per Hari (Rp)</label>
                                        <input name="daily_rate" type="number"
                                            min="0" step="0.01" required
                                            value="<%= v.get("rate") == null ? "0" : v.get("rate") %>">
                                    </div>

                                    <div class="field">
                                        <label>Deskripsi</label>
                                        <textarea name="description"><%= v.get("description") == null ? "" : v.get("description") %></textarea>
                                    </div>

                                    <div class="field">
                                        <label>URL Gambar</label>
                                        <input name="image_url"
                                            value="<%= v.get("imageUrl") == null ? "" : v.get("imageUrl") %>">
                                    </div>

                                    <div class="field">
                                        <label>Path Gambar</label>
                                        <input name="image_path"
                                            value="<%= v.get("imagePath") == null ? "" : v.get("imagePath") %>">
                                    </div>

                                    <div class="field">
                                        <label>Status</label>
                                        <select name="status">
                                            <option value="Available"
                                                <%= "Available".equals(status) ? "selected" : "" %>>
                                                Available
                                            </option>
                                            <option value="Unavailable"
                                                <%= "Unavailable".equals(status) ? "selected" : "" %>>
                                                Unavailable
                                            </option>
                                        </select>
                                    </div>

                                    <button class="primary" type="submit">
                                        Simpan Perubahan
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <%  }
                   } else { %>
                    <tr>
                        <td colspan="7">Belum ada data vessel.</td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </section>

</main>

<footer>Maritim Indonesia — Vessel Management</footer>

<script>
    function toggleEdit(id) {
        const form = document.getElementById("edit-" + id);
        form.classList.toggle("open");
    }
</script>

</body>
</html>
