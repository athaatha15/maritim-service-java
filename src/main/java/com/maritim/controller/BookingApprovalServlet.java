
package com.maritim.controller;

import com.maritim.dao.DatabaseConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet("/admin/booking-approval")
public class BookingApprovalServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (session == null
                || !"ADMIN".equals(session.getAttribute("role"))) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Akses hanya untuk Admin.");
            return;
        }

        String idText = request.getParameter("id");
        String action = request.getParameter("action");
        String notes = request.getParameter("admin_notes");

        if (idText == null || action == null
                || !("approve".equals(action)
                || "reject".equals(action))) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Data approval tidak valid.");
            return;
        }

        long id;

        try {
            id = Long.parseLong(idText);
            if (id <= 0) {
                throw new NumberFormatException();
            }
        } catch (NumberFormatException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "ID booking tidak valid.");
            return;
        }

        if (notes != null && notes.length() > 5000) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Catatan Admin terlalu panjang.");
            return;
        }

        String cleanNotes =
                notes == null || notes.isBlank()
                        ? null : notes.trim();

        try (Connection conn = DatabaseConnection.getConnection()) {

            conn.setAutoCommit(false);

            try {
                if ("approve".equals(action)) {

                    String selectSql =
                            "SELECT cr.duration_days, v.daily_rate " +
                                    "FROM charter_requests cr " +
                                    "JOIN vessels v ON v.id = cr.vessel_id " +
                                    "WHERE cr.id = ? AND cr.status = 'Pending' " +
                                    "FOR UPDATE";

                    BigDecimal total;
                    int duration;

                    try (PreparedStatement ps =
                                 conn.prepareStatement(selectSql)) {
                        ps.setLong(1, id);

                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) {
                                conn.rollback();
                                response.sendError(
                                        HttpServletResponse.SC_CONFLICT,
                                        "Booking tidak ditemukan atau bukan Pending.");
                                return;
                            }

                            duration = rs.getInt("duration_days");
                            BigDecimal dailyRate =
                                    rs.getBigDecimal("daily_rate");

                            if (duration <= 0 || dailyRate == null
                                    || dailyRate.compareTo(BigDecimal.ZERO) < 0) {
                                conn.rollback();
                                response.sendError(
                                        HttpServletResponse.SC_BAD_REQUEST,
                                        "Durasi atau tarif kapal tidak valid.");
                                return;
                            }

                            total = dailyRate
                                    .multiply(BigDecimal.valueOf(duration))
                                    .setScale(2, java.math.RoundingMode.HALF_UP);
                        }
                    }

                    BigDecimal dp = total
                            .multiply(new BigDecimal("0.50"))
                            .setScale(2, java.math.RoundingMode.HALF_UP);

                    BigDecimal remaining = total.subtract(dp);

                    String updateSql =
                            "UPDATE charter_requests " +
                                    "SET status = 'Approved', admin_notes = ?, " +
                                    "total_amount = ?, dp_amount = ?, " +
                                    "remaining_amount = ?, payment_status = 'Unpaid' " +
                                    "WHERE id = ? AND status = 'Pending'";

                    try (PreparedStatement ps =
                                 conn.prepareStatement(updateSql)) {
                        ps.setString(1, cleanNotes);
                        ps.setBigDecimal(2, total);
                        ps.setBigDecimal(3, dp);
                        ps.setBigDecimal(4, remaining);
                        ps.setLong(5, id);

                        if (ps.executeUpdate() != 1) {
                            conn.rollback();
                            response.sendError(
                                    HttpServletResponse.SC_CONFLICT,
                                    "Booking sudah diproses.");
                            return;
                        }
                    }

                } else {

                    String updateSql =
                            "UPDATE charter_requests " +
                                    "SET status = 'Rejected', admin_notes = ? " +
                                    "WHERE id = ? AND status = 'Pending'";

                    try (PreparedStatement ps =
                                 conn.prepareStatement(updateSql)) {
                        ps.setString(1, cleanNotes);
                        ps.setLong(2, id);

                        if (ps.executeUpdate() != 1) {
                            conn.rollback();
                            response.sendError(
                                    HttpServletResponse.SC_CONFLICT,
                                    "Booking tidak ditemukan atau bukan Pending.");
                            return;
                        }
                    }
                }

                conn.commit();

            } catch (SQLException | RuntimeException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }

        } catch (SQLException e) {
            getServletContext().log(
                    "Gagal memproses approval booking", e);
            throw new ServletException(
                    "Gagal memperbarui status booking.", e);
        }

        response.sendRedirect(
                request.getContextPath()
                        + "/admin/dashboard.jsp?updated=1");
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null
                || !"ADMIN".equals(session.getAttribute("role"))) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Akses hanya untuk Admin.");
            return;
        }

        response.sendError(
                HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                "Gunakan form Admin Dashboard untuk memproses approval.");
    }
}
