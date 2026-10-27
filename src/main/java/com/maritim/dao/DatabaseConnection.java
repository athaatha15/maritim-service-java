
package com.maritim.dao;

import java.io.FileInputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class DatabaseConnection {

    private static final String URL =
        "jdbc:mysql://127.0.0.1:3306/maritim_indonesia?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";

    private static final String USER = "athaatha15";

    private static final String CONFIG =
        System.getProperty("user.home") + "/.maritim-db.properties";

    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("Driver MySQL tidak ditemukan.", e);
        }

        Properties properties = new Properties();

        try (FileInputStream input = new FileInputStream(CONFIG)) {
            properties.load(input);
        } catch (IOException e) {
            throw new SQLException(
                "File konfigurasi database tidak bisa dibaca.", e);
        }

        String password = properties.getProperty("DB_PASSWORD");

        if (password == null || password.isBlank()
                || password.equals("PASSWORD_MYSQL_KAMU")) {
            throw new SQLException(
                "DB_PASSWORD belum diisi dengan password MySQL yang benar.");
        }

        return DriverManager.getConnection(URL, USER, password.trim());
    }
}

