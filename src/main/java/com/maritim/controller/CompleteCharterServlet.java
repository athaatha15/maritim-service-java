
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
import java.sql.SQLException;

@WebServlet("/admin/complete-charter")
public class CompleteCharterServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null
                || !"ADMIN".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        long bookingId;

        try {
            bookingId = Long.parseLong(
                    request.getParameter("booking_id"));

            if (bookingId <= 0) {
                throw new NumberFormatException();
            }
        } catch (NumberFormatException e) {
            response.sendRedirect(
                    request.getContextPath()
                            + "/admin/dashboard.jsp?error=invalid_id");
            return;
        }

        Connection conn = null;

        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            String selectSql =
                    "SELECT status, payment_status " +
                            "FROM charter_requests WHERE id = ? FOR UPDATE";

            String currentStatus;
            String paymentStatus;

            try (PreparedStatement ps =
                         conn.prepareStatement(selectSql)) {

                ps.setLong(1, bookingId);

                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        response.sendRedirect(
                                request.getContextPath()
                                        + "/admin/dashboard.jsp?error=not_found");
                        return;
                    }

                    currentStatus = rs.getString("status");
                    paymentStatus = rs.getString("payment_status");
                }
            }

            if (!"Approved".equalsIgnoreCase(currentStatus)
                    || !"DP Paid".equalsIgnoreCase(paymentStatus)) {

                conn.rollback();
                response.sendRedirect(
                        request.getContextPath()
                                + "/admin/dashboard.jsp?error=invalid_status");
                return;
            }

            String updateSql =
                    "UPDATE charter_requests " +
                            "SET status = 'Completed', " +
                            "updated_at = CURRENT_TIMESTAMP " +
                            "WHERE id = ? " +
                            "AND status = 'Approved' " +
                            "AND payment_status = 'DP Paid'";

            try (PreparedStatement ps =
                         conn.prepareStatement(updateSql)) {

                ps.setLong(1, bookingId);

                if (ps.executeUpdate() != 1) {
                    conn.rollback();
                    response.sendRedirect(
                            request.getContextPath()
                                    + "/admin/dashboard.jsp?error=update_failed");
                    return;
                }
            }

            conn.commit();

            response.sendRedirect(
                    request.getContextPath()
                            + "/admin/dashboard.jsp?completed=1");

        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ignored) {
                    // Abaikan error rollback.
                }
            }

            throw new ServletException(
                    "Gagal menyelesaikan perjalanan charter.", e);

        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) {
                    // Abaikan error saat menutup koneksi.
                }
            }
        }
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        response.sendError(
                HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                "Gunakan metode POST.");
    }
}
