
package com.maritim.controller;

import com.maritim.dao.DatabaseConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.UUID;

@WebServlet("/booking")
public class BookingServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null ||
                session.getAttribute("customerId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        request.setAttribute("customerName",
                session.getAttribute("customerName"));

        String sql = "SELECT id, vessel_name, vessel_type, capacity, " +
                "location, daily_rate FROM vessels " +
                "WHERE status = 'Available' ORDER BY id";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            java.util.List<java.util.Map<String, Object>> vessels =
                    new java.util.ArrayList<>();

            while (rs.next()) {
                java.util.Map<String, Object> vessel =
                        new java.util.LinkedHashMap<>();

                vessel.put("id", rs.getLong("id"));
                vessel.put("name", rs.getString("vessel_name"));
                vessel.put("type", rs.getString("vessel_type"));
                vessel.put("capacity", rs.getString("capacity"));
                vessel.put("location", rs.getString("location"));
                vessel.put("rate", rs.getBigDecimal("daily_rate"));

                vessels.add(vessel);
            }

            request.setAttribute("vessels", vessels);
            request.getRequestDispatcher(
                    "/WEB-INF/views/booking.jsp")
                    .forward(request, response);

        } catch (SQLException e) {
            throw new ServletException(
                    "Gagal mengambil daftar kapal.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (session == null ||
                !(session.getAttribute("customerId") instanceof Number)) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        long customerId =
                ((Number) session.getAttribute("customerId")).longValue();

        String vesselText = request.getParameter("vesselId");
        String origin = request.getParameter("origin");
        String destination = request.getParameter("destination");
        String dateText = request.getParameter("startDate");
        String durationText = request.getParameter("durationDays");
        String requirements = request.getParameter("requirements");

        if (vesselText == null || origin == null ||
                destination == null || dateText == null ||
                durationText == null ||
                vesselText.isBlank() || origin.isBlank() ||
                destination.isBlank() || dateText.isBlank() ||
                durationText.isBlank()) {
            response.sendError(400, "Semua data wajib diisi.");
            return;
        }

        origin = origin.trim();
        destination = destination.trim();

        if (origin.length() > 90 || destination.length() > 90 ||
                origin.equalsIgnoreCase(destination)) {
            response.sendError(400,
                    "Lokasi tidak valid. Asal dan tujuan harus berbeda.");
            return;
        }

        long vesselId;
        int duration;
        LocalDate startDate;

        try {
            vesselId = Long.parseLong(vesselText);
            duration = Integer.parseInt(durationText);
            startDate = LocalDate.parse(dateText);
        } catch (Exception e) {
            response.sendError(400, "Data kapal, tanggal, atau durasi tidak valid.");
            return;
        }

        if (vesselId <= 0 || duration < 1 || duration > 365 ||
                startDate.isBefore(LocalDate.now())) {
            response.sendError(400,
                    "Tanggal tidak boleh di masa lalu dan durasi harus 1–365 hari.");
            return;
        }

        String requestCode = "MRM-" +
                UUID.randomUUID().toString()
                        .replace("-", "")
                        .substring(0, 12).toUpperCase();

        String location = origin + " -> " + destination;

        if (location.length() > 200) {
            response.sendError(400, "Gabungan lokasi terlalu panjang.");
            return;
        }

        String insertSql =
                "INSERT INTO charter_requests " +
                "(request_code, customer_id, vessel_id, operation_location, " +
                "start_date, duration_days, requirements, status) " +
                "SELECT ?, ?, v.id, ?, ?, ?, ?, 'Pending' " +
                "FROM vessels v WHERE v.id = ? AND v.status = 'Available'";

        try (Connection conn = DatabaseConnection.getConnection()) {

            conn.setAutoCommit(false);

            try {
                // Pastikan customer_id benar-benar ada di tabel customers.
                try (PreparedStatement customerCheck = conn.prepareStatement(
                        "SELECT id FROM customers WHERE id = ?")) {
                    customerCheck.setLong(1, customerId);

                    try (ResultSet rs = customerCheck.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            response.sendError(409,
                                    "Data pelanggan belum tersinkron. Silakan hubungi administrator.");
                            return;
                        }
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                    ps.setString(1, requestCode);
                    ps.setLong(2, customerId);
                    ps.setString(3, location);
                    ps.setDate(4, Date.valueOf(startDate));
                    ps.setInt(5, duration);
                    ps.setString(6,
                            requirements == null || requirements.isBlank()
                                    ? null : requirements.trim());
                    ps.setLong(7, vesselId);

                    int inserted = ps.executeUpdate();

                    if (inserted != 1) {
                        conn.rollback();
                        response.sendError(409,
                                "Kapal tidak ditemukan atau tidak tersedia.");
                        return;
                    }
                }

                conn.commit();

            } catch (Exception e) {
                conn.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new ServletException("Gagal menyimpan booking.", e);
        }

        response.sendRedirect(request.getContextPath() +
                "/booking/confirmation?code=" + requestCode);
    }
}

