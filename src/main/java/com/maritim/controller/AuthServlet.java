
package com.maritim.controller;

import com.maritim.dao.DatabaseConnection;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.security.spec.KeySpec;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Base64;

@WebServlet(urlPatterns = {"/register", "/login", "/logout"})
public class AuthServlet extends HttpServlet {

    private static final int ITERATIONS = 210000;
    private static final int KEY_LENGTH = 256;

    private String hashPassword(String password, byte[] salt)
            throws Exception {

        KeySpec spec = new PBEKeySpec(
                password.toCharArray(), salt, ITERATIONS, KEY_LENGTH);

        SecretKeyFactory factory =
                SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");

        return Base64.getEncoder().encodeToString(
                factory.generateSecret(spec).getEncoded());
    }

    private byte[] generateSalt() {
        byte[] salt = new byte[16];
        new SecureRandom().nextBytes(salt);
        return salt;
    }

    private boolean verifyPassword(
            String password, String saltText, String expectedHash)
            throws Exception {

        byte[] salt = Base64.getDecoder().decode(saltText);
        String actualHash = hashPassword(password, salt);

        return MessageDigest.isEqual(
                expectedHash.getBytes(StandardCharsets.UTF_8),
                actualHash.getBytes(StandardCharsets.UTF_8));
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        String path = request.getServletPath();

        if ("/logout".equals(path)) {
            HttpSession session = request.getSession(false);

            if (session != null) {
                session.invalidate();
            }

            response.sendRedirect(
                    request.getContextPath() + "/login?logout=1");
            return;
        }

        if ("/register".equals(path) || "/login".equals(path)) {
            request.getRequestDispatcher(
                            "/WEB-INF/views" +
                                    ("/register".equals(path)
                                            ? "/register.jsp" : "/login.jsp"))
                    .forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String path = request.getServletPath();

        try {
            if ("/register".equals(path)) {
                register(request, response);
            } else if ("/login".equals(path)) {
                String loginType = request.getParameter("login_type");

                if ("employee".equals(loginType)) {
                    loginEmployee(request, response);
                } else {
                    loginCustomer(request, response);
                }
            } else {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (Exception e) {
            getServletContext().log("Proses autentikasi gagal", e);
            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Terjadi kesalahan pada proses akun. Periksa log Tomcat.");
        }
    }

    private void register(HttpServletRequest request,
                          HttpServletResponse response)
            throws Exception {

        String name = request.getParameter("full_name");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String password = request.getParameter("password");

        if (name == null || email == null || phone == null
                || password == null
                || name.isBlank() || email.isBlank()
                || phone.isBlank() || password.length() < 8
                || password.length() > 200) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Lengkapi semua data. Password minimal 8 karakter.");
            return;
        }

        name = name.trim();
        email = email.trim().toLowerCase();
        phone = phone.trim();

        if (name.length() > 100 || email.length() > 150
                || phone.length() > 30
                || !email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Data nama, email, atau telepon tidak valid.");
            return;
        }

        byte[] salt = generateSalt();
        String saltText = Base64.getEncoder().encodeToString(salt);
        String passwordHash = hashPassword(password, salt);

        String sql = "INSERT INTO customer_accounts " +
                "(full_name, email, phone, password_hash, password_salt) " +
                "VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, name);
            ps.setString(2, email);
            ps.setString(3, phone);
            ps.setString(4, passwordHash);
            ps.setString(5, saltText);

            ps.executeUpdate();

        } catch (SQLException e) {
            if ("23000".equals(e.getSQLState())) {
                response.sendError(
                        HttpServletResponse.SC_CONFLICT,
                        "Email sudah terdaftar. Silakan login.");
                return;
            }

            throw e;
        }

        response.sendRedirect(
                request.getContextPath() + "/login?registered=1");
    }

    private void loginCustomer(HttpServletRequest request,
                               HttpServletResponse response)
            throws Exception {

        String email = request.getParameter("email");
        String password = request.getParameter("password");

        if (email == null || password == null
                || email.isBlank() || password.isEmpty()) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Email dan password wajib diisi.");
            return;
        }

        String sql = "SELECT id, full_name, email, password_hash, " +
                "password_salt FROM customer_accounts WHERE email = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, email.trim().toLowerCase());

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && verifyPassword(
                        password,
                        rs.getString("password_salt"),
                        rs.getString("password_hash"))) {

                    HttpSession oldSession = request.getSession(false);

                    if (oldSession != null) {
                        oldSession.invalidate();
                    }

                    HttpSession session = request.getSession(true);
                    session.setAttribute("customerId", rs.getInt("id"));
                    session.setAttribute(
                            "customerName", rs.getString("full_name"));
                    session.setAttribute(
                            "customerEmail", rs.getString("email"));
                    session.setAttribute("accountType", "CUSTOMER");
                    session.setMaxInactiveInterval(30 * 60);

                    response.sendRedirect(
                            request.getContextPath()
                                    + "/customer/dashboard.jsp");
                    return;
                }
            }
        }

        response.sendError(
                HttpServletResponse.SC_UNAUTHORIZED,
                "Email atau password salah.");
    }

    private void loginEmployee(HttpServletRequest request,
                               HttpServletResponse response)
            throws Exception {

        String employeeNumber = request.getParameter("employee_number");
        String password = request.getParameter("password");

        if (employeeNumber == null || password == null
                || employeeNumber.isBlank() || password.isEmpty()) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Nomor pegawai dan password wajib diisi.");
            return;
        }

        String sql = "SELECT id, employee_number, full_name, " +
                "password_hash, password_salt, role " +
                "FROM employee_accounts WHERE employee_number = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, employeeNumber.trim());

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && verifyPassword(
                        password,
                        rs.getString("password_salt"),
                        rs.getString("password_hash"))) {

                    String role = rs.getString("role");

                    if (!"ADMIN".equals(role)
                            && !"EMPLOYEE".equals(role)) {
                        response.sendError(
                                HttpServletResponse.SC_FORBIDDEN,
                                "Role akun tidak valid.");
                        return;
                    }

                    HttpSession oldSession = request.getSession(false);

                    if (oldSession != null) {
                        oldSession.invalidate();
                    }

                    HttpSession session = request.getSession(true);
                    session.setAttribute("employeeId", rs.getLong("id"));
                    session.setAttribute(
                            "employeeNumber", rs.getString("employee_number"));
                    session.setAttribute(
                            "employeeName", rs.getString("full_name"));
                    session.setAttribute("role", role);
                    session.setAttribute("accountType", "EMPLOYEE");
                    session.setMaxInactiveInterval(30 * 60);

                    if ("ADMIN".equals(role)) {
                        response.sendRedirect(
                                request.getContextPath()
                                        + "/admin/dashboard.jsp");
                    } else {
                        response.sendRedirect(
                                request.getContextPath()
                                        + "/employee/dashboard.jsp");
                    }

                    return;
                }
            }
        }

        response.sendError(
                HttpServletResponse.SC_UNAUTHORIZED,
                "Nomor pegawai atau password salah.");
    }
}
