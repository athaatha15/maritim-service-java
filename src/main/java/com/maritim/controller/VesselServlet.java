
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
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/admin/vessels")
public class VesselServlet extends HttpServlet {

    private boolean isAdmin(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session != null
                && "ADMIN".equals(session.getAttribute("role"));
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request)) {
            response.sendRedirect(
                    request.getContextPath() + "/login.jsp");
            return;
        }

        List<Map<String, Object>> vessels = new ArrayList<>();

        String sql = "SELECT id, vessel_name, vessel_type, capacity, " +
                "location, daily_rate, description, image_url, " +
                "image_path, status, created_at " +
                "FROM vessels ORDER BY id DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> vessel = new LinkedHashMap<>();

                vessel.put("id", rs.getInt("id"));
                vessel.put("name", rs.getString("vessel_name"));
                vessel.put("type", rs.getString("vessel_type"));
                vessel.put("capacity", rs.getString("capacity"));
                vessel.put("location", rs.getString("location"));
                vessel.put("rate", rs.getBigDecimal("daily_rate"));
                vessel.put("description", rs.getString("description"));
                vessel.put("imageUrl", rs.getString("image_url"));
                vessel.put("imagePath", rs.getString("image_path"));
                vessel.put("status", rs.getString("status"));
                vessel.put("createdAt", rs.getTimestamp("created_at"));

                vessels.add(vessel);
            }

            request.setAttribute("vessels", vessels);

        } catch (SQLException e) {
            throw new ServletException(
                    "Gagal mengambil data vessel dari database.", e);
        }

        request.getRequestDispatcher("/admin/vessels.jsp")
                .forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Akses hanya untuk admin.");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");

        try (Connection conn = DatabaseConnection.getConnection()) {

            if ("add".equals(action)) {
                String name = request.getParameter("vessel_name");
                String type = request.getParameter("vessel_type");
                String capacity = request.getParameter("capacity");
                String location = request.getParameter("location");
                String rateText = request.getParameter("daily_rate");
                String description = request.getParameter("description");
                String imageUrl = request.getParameter("image_url");
                String imagePath = request.getParameter("image_path");
                String status = request.getParameter("status");

                if (isBlank(name) || isBlank(type)
                        || isBlank(rateText)) {
                    redirect(request, response, "invalid");
                    return;
                }

                BigDecimal rate = new BigDecimal(rateText);

                if (rate.compareTo(BigDecimal.ZERO) < 0) {
                    redirect(request, response, "invalid");
                    return;
                }

                if (!"Available".equals(status)
                        && !"Unavailable".equals(status)) {
                    status = "Available";
                }

                String sql = "INSERT INTO vessels " +
                        "(vessel_name, vessel_type, capacity, location, " +
                        "daily_rate, description, image_url, image_path, status) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, name.trim());
                    ps.setString(2, type.trim());
                    ps.setString(3, emptyToNull(capacity));
                    ps.setString(4, emptyToNull(location));
                    ps.setBigDecimal(5, rate);
                    ps.setString(6, emptyToNull(description));
                    ps.setString(7, emptyToNull(imageUrl));
                    ps.setString(8, emptyToNull(imagePath));
                    ps.setString(9, status);
                    ps.executeUpdate();
                }

                redirect(request, response, "added");
                return;
            }

            if ("edit".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));

                String name = request.getParameter("vessel_name");
                String type = request.getParameter("vessel_type");
                String capacity = request.getParameter("capacity");
                String location = request.getParameter("location");
                String rateText = request.getParameter("daily_rate");
                String description = request.getParameter("description");
                String imageUrl = request.getParameter("image_url");
                String imagePath = request.getParameter("image_path");
                String status = request.getParameter("status");

                if (id <= 0 || isBlank(name) || isBlank(type)
                        || isBlank(rateText)) {
                    redirect(request, response, "invalid");
                    return;
                }

                BigDecimal rate = new BigDecimal(rateText);

                if (rate.compareTo(BigDecimal.ZERO) < 0) {
                    redirect(request, response, "invalid");
                    return;
                }

                if (!"Available".equals(status)
                        && !"Unavailable".equals(status)) {
                    redirect(request, response, "invalid");
                    return;
                }

                String sql = "UPDATE vessels SET vessel_name=?, vessel_type=?, " +
                        "capacity=?, location=?, daily_rate=?, description=?, " +
                        "image_url=?, image_path=?, status=? WHERE id=?";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, name.trim());
                    ps.setString(2, type.trim());
                    ps.setString(3, emptyToNull(capacity));
                    ps.setString(4, emptyToNull(location));
                    ps.setBigDecimal(5, rate);
                    ps.setString(6, emptyToNull(description));
                    ps.setString(7, emptyToNull(imageUrl));
                    ps.setString(8, emptyToNull(imagePath));
                    ps.setString(9, status);
                    ps.setInt(10, id);

                    if (ps.executeUpdate() == 0) {
                        redirect(request, response, "notfound");
                        return;
                    }
                }

                redirect(request, response, "updated");
                return;
            }

            if ("toggle".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));

                String sql = "UPDATE vessels SET status = " +
                        "CASE WHEN status = 'Available' " +
                        "THEN 'Unavailable' ELSE 'Available' END " +
                        "WHERE id = ?";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, id);

                    if (ps.executeUpdate() == 0) {
                        redirect(request, response, "notfound");
                        return;
                    }
                }

                redirect(request, response, "updated");
                return;
            }

            redirect(request, response, "invalid");

        } catch (NumberFormatException e) {
            redirect(request, response, "invalid");
        } catch (SQLException e) {
            throw new ServletException(
                    "Gagal menyimpan perubahan vessel.", e);
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String emptyToNull(String value) {
        return isBlank(value) ? null : value.trim();
    }

    private void redirect(HttpServletRequest request,
                          HttpServletResponse response,
                          String result) throws IOException {
        response.sendRedirect(
                request.getContextPath() + "/admin/vessels?result=" + result);
    }
}
