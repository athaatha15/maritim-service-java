
package com.maritim.controller;

import com.maritim.dao.DatabaseConnection;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.Base64;
import java.util.Scanner;

public class CreateEmployeeAccount {

    private static final int ITERATIONS = 210000;
    private static final int KEY_LENGTH = 256;

    private static byte[] generateSalt() {
        byte[] salt = new byte[16];
        new SecureRandom().nextBytes(salt);
        return salt;
    }

    private static String hashPassword(String password, byte[] salt)
            throws Exception {

        PBEKeySpec spec = new PBEKeySpec(
                password.toCharArray(),
                salt,
                ITERATIONS,
                KEY_LENGTH
        );

        try {
            SecretKeyFactory factory =
                    SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");

            return Base64.getEncoder().encodeToString(
                    factory.generateSecret(spec).getEncoded()
            );
        } finally {
            spec.clearPassword();
        }
    }

    public static void main(String[] args) {
        try (Scanner scanner = new Scanner(System.in)) {

            System.out.print("Nomor karyawan: ");
            String employeeNumber = scanner.nextLine().trim();

            System.out.print("Nama Admin: ");
            String fullName = scanner.nextLine().trim();

            System.out.print("Password (minimal 8 karakter): ");
            String password = scanner.nextLine();

            if (employeeNumber.isBlank()
                    || fullName.isBlank()
                    || password.length() < 8
                    || password.length() > 200) {
                System.out.println("Data tidak valid.");
                return;
            }

            byte[] salt = generateSalt();
            String saltText = Base64.getEncoder().encodeToString(salt);
            String passwordHash = hashPassword(password, salt);

            String sql = "INSERT INTO employee_accounts "
                    + "(employee_number, full_name, password_hash, "
                    + "password_salt, role) VALUES (?, ?, ?, ?, 'ADMIN')";

            try (Connection conn = DatabaseConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {

                ps.setString(1, employeeNumber);
                ps.setString(2, fullName);
                ps.setString(3, passwordHash);
                ps.setString(4, saltText);

                ps.executeUpdate();

                System.out.println("Akun Admin berhasil dibuat.");
            }

        } catch (Exception e) {
            System.err.println("Gagal membuat akun Admin: " + e.getMessage());
        }
    }
}
