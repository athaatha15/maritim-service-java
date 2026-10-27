
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
import java.util.UUID;

@WebServlet("/customer/simulated-payment")
public class SimulatedPaymentServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        String contextPath = request.getContextPath();
        HttpSession session = request.getSession(false);

        if (session == null
                || !"CUSTOMER".equals(session.getAttribute("accountType"))
                || !(session.getAttribute("customerId") instanceof Number)) {

            response.sendRedirect(contextPath + "/login");
            return;
        }

        long customerAccountId =
                ((Number) session.getAttribute("customerId")).longValue();

        long bookingId;
        String paymentType = request.getParameter("payment_type");

        if (paymentType == null || paymentType.trim().isEmpty()) {
            paymentType = "DP";
        }

        paymentType = paymentType.trim().toUpperCase();

        if (!"DP".equals(paymentType)
                && !"FINAL".equals(paymentType)) {
            response.sendRedirect(
                    contextPath + "/booking/history?payment=invalid");
            return;
        }

        try {
            bookingId = Long.parseLong(
                    request.getParameter("booking_id"));

            if (bookingId <= 0) {
                throw new NumberFormatException();
            }
        } catch (NumberFormatException e) {
            response.sendRedirect(
                    contextPath + "/booking/history?payment=invalid");
            return;
        }

        Connection conn = null;

        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            String selectSql =
                    "SELECT cr.status, cr.payment_status " +
                            "FROM charter_requests cr " +
                            "JOIN customers c ON c.id = cr.customer_id " +
                            "JOIN customer_accounts ca " +
                            "ON LOWER(TRIM(c.email)) = LOWER(TRIM(ca.email)) " +
                            "WHERE cr.id = ? " +
                            "AND ca.id = ? " +
                            "AND ca.employee_number IS NULL " +
                            "FOR UPDATE";

            String bookingStatus;
            String paymentStatus;

            try (PreparedStatement ps =
                         conn.prepareStatement(selectSql)) {

                ps.setLong(1, bookingId);
                ps.setLong(2, customerAccountId);

                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        response.sendRedirect(
                                contextPath
                                        + "/booking/history?payment=not_found");
                        return;
                    }

                    bookingStatus = rs.getString("status");
                    paymentStatus = rs.getString("payment_status");
                }
            }

            String newPaymentStatus;
            String referencePrefix;
            String updateSql;

            if ("DP".equals(paymentType)) {

                if (!"Approved".equalsIgnoreCase(bookingStatus)
                        || !"Unpaid".equalsIgnoreCase(paymentStatus)) {

                    conn.rollback();
                    response.sendRedirect(
                            contextPath
                                    + "/booking/history?payment=invalid_status");
                    return;
                }

                newPaymentStatus = "DP Paid";
                referencePrefix = "SIM-DP-";

                updateSql =
                        "UPDATE charter_requests " +
                                "SET payment_status = 'DP Paid', " +
                                "payment_gateway = 'SIMULATION', " +
                                "payment_reference = ?, " +
                                "dp_paid_at = CURRENT_TIMESTAMP, " +
                                "updated_at = CURRENT_TIMESTAMP " +
                                "WHERE id = ? " +
                                "AND status = 'Approved' " +
                                "AND payment_status = 'Unpaid'";

            } else {

                // Pelunasan hanya setelah perjalanan selesai oleh Admin.
                if (!"Completed".equalsIgnoreCase(bookingStatus)
                        || !"DP Paid".equalsIgnoreCase(paymentStatus)) {

                    conn.rollback();
                    response.sendRedirect(
                            contextPath
                                    + "/booking/history?payment=invalid_status");
                    return;
                }

                newPaymentStatus = "Paid";
                referencePrefix = "SIM-FINAL-";

                updateSql =
                        "UPDATE charter_requests " +
                                "SET payment_status = 'Paid', " +
                                "payment_gateway = 'SIMULATION', " +
                                "payment_reference = ?, " +
                                "settled_at = CURRENT_TIMESTAMP, " +
                                "updated_at = CURRENT_TIMESTAMP " +
                                "WHERE id = ? " +
                                "AND status = 'Completed' " +
                                "AND payment_status = 'DP Paid'";
            }

            String paymentReference =
                    referencePrefix
                            + UUID.randomUUID()
                            .toString()
                            .replace("-", "")
                            .substring(0, 12)
                            .toUpperCase();

            try (PreparedStatement ps =
                         conn.prepareStatement(updateSql)) {

                ps.setString(1, paymentReference);
                ps.setLong(2, bookingId);

                if (ps.executeUpdate() != 1) {
                    conn.rollback();
                    response.sendRedirect(
                            contextPath
                                    + "/booking/history?payment=update_failed");
                    return;
                }
            }

            conn.commit();

            if ("Paid".equals(newPaymentStatus)) {
                response.sendRedirect(
                        contextPath + "/booking/history?payment=settled");
            } else {
                response.sendRedirect(
                        contextPath + "/booking/history?payment=success");
            }

        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ignored) {
                    // Abaikan error rollback.
                }
            }

            throw new ServletException(
                    "Simulasi pembayaran gagal diproses.", e);

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
