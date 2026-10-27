
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

@WebServlet("/booking/confirmation")
public class BookingConfirmationServlet extends HttpServlet {

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

        String code = request.getParameter("code");

        if (code == null || !code.matches("MRM-[A-F0-9]{12}")) {
            response.sendError(400, "Nomor booking tidak valid.");
            return;
        }

        long customerId =
            ((Number) session.getAttribute("customerId")).longValue();

        String sql =
            "SELECT cr.request_code, cr.operation_location, " +
            "cr.start_date, cr.duration_days, cr.status, v.vessel_name " +
            "FROM charter_requests cr " +
            "JOIN vessels v ON cr.vessel_id = v.id " +
            "WHERE cr.request_code = ? AND cr.customer_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, code);
            ps.setLong(2, customerId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    response.sendError(404, "Booking tidak ditemukan.");
                    return;
                }

                request.setAttribute("bookingCode",
                    rs.getString("request_code"));
                request.setAttribute("location",
                    rs.getString("operation_location"));
                request.setAttribute("startDate",
                    rs.getDate("start_date"));
                request.setAttribute("duration",
                    rs.getInt("duration_days"));
                request.setAttribute("status",
                    rs.getString("status"));
                request.setAttribute("vesselName",
                    rs.getString("vessel_name"));
            }

            request.getRequestDispatcher(
                "/WEB-INF/views/booking-confirmation.jsp")
                .forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                "Gagal mengambil detail booking.", e);
        }
    }
}

