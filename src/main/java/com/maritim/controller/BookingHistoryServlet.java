
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
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/booking/history")
public class BookingHistoryServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null ||
                !(session.getAttribute("customerId") instanceof Number)) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        long customerId =
                ((Number) session.getAttribute("customerId")).longValue();

        List<Map<String, Object>> bookings = new ArrayList<>();

        String sql =
                "SELECT cr.id, cr.request_code, cr.operation_location, " +
                        "cr.start_date, cr.duration_days, cr.status, cr.created_at, " +
                        "cr.total_amount, cr.dp_amount, cr.remaining_amount, " +
                        "cr.payment_status, cr.payment_reference, " +
                        "v.vessel_name " +
                        "FROM charter_requests cr " +
                        "JOIN vessels v ON cr.vessel_id = v.id " +
                        "WHERE cr.customer_id = ? " +
                        "ORDER BY cr.created_at DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setLong(1, customerId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> booking = new HashMap<>();

                    booking.put("id", rs.getLong("id"));
                    booking.put("code", rs.getString("request_code"));
                    booking.put("location",
                            rs.getString("operation_location"));
                    booking.put("startDate", rs.getDate("start_date"));
                    booking.put("duration", rs.getInt("duration_days"));
                    booking.put("status", rs.getString("status"));
                    booking.put("createdAt",
                            rs.getTimestamp("created_at"));
                    booking.put("vessel", rs.getString("vessel_name"));

                    // Informasi pembayaran
                    booking.put("totalAmount",
                            rs.getBigDecimal("total_amount"));
                    booking.put("dpAmount",
                            rs.getBigDecimal("dp_amount"));
                    booking.put("remainingAmount",
                            rs.getBigDecimal("remaining_amount"));
                    booking.put("paymentStatus",
                            rs.getString("payment_status"));
                    booking.put("paymentReference",
                            rs.getString("payment_reference"));

                    bookings.add(booking);
                }
            }

        } catch (Exception e) {
            getServletContext().log(
                    "Gagal mengambil riwayat booking Customer", e);

            throw new ServletException(
                    "Gagal mengambil riwayat booking.", e);
        }

        request.setAttribute("bookings", bookings);

        request.getRequestDispatcher(
                        "/WEB-INF/views/booking-history.jsp")
                .forward(request, response);
    }
}
