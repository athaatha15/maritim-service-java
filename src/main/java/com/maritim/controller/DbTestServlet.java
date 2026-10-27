package com.maritim.controller;

import com.maritim.dao.DatabaseConnection;

import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/db-test")
public class DbTestServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");

        try (java.io.PrintWriter out = response.getWriter()) {
            out.println("<!DOCTYPE html>");
            out.println("<html><head><title>Database Test</title></head><body>");
            out.println("<h1>Database Connection Test</h1>");

            try (Connection connection = DatabaseConnection.getConnection()) {
                out.println("<p style='color:green;'>Koneksi MySQL berhasil.</p>");
                out.println("<p>Database: "
                        + connection.getCatalog() + "</p>");

                try (Statement statement = connection.createStatement();
                     ResultSet result = statement.executeQuery(
                             "SELECT COUNT(*) FROM vessels")) {

                    if (result.next()) {
                        out.println("<p>Jumlah data kapal: "
                                + result.getInt(1) + "</p>");
                    }
                }

            } catch (Exception e) {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                out.println("<p style='color:red;'>Koneksi atau pembacaan data gagal.</p>");
                out.println("<p>Jenis error: "
                        + e.getClass().getSimpleName() + "</p>");
                out.println("<p>Pesan: "
                        + escapeHtml(e.getMessage()) + "</p>");
                getServletContext().log("Database test gagal", e);
            }

            out.println("</body></html>");
        }
    }

    private String escapeHtml(String value) {
        if (value == null) {
            return "Tidak ada detail error.";
        }

        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
}
