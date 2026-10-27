<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register | Maritim Indonesia</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/style.css">
</head>
<body class="auth-page">
    <main class="auth-layout">
        <section class="auth-visual">
            <a class="auth-brand" href="${pageContext.request.contextPath}/">
                <span class="auth-logo">MI</span>
                <span>MARITIM <b>INDONESIA</b>
                    <small>MARINE SERVICES &amp; CHARTER</small>
                </span>
            </a>

            <div class="auth-visual-content">
                <span class="auth-kicker">START YOUR JOURNEY</span>
                <h1>Solusi maritim, lebih mudah dalam genggaman.</h1>
                <p>Buat akun pelanggan untuk memulai perjalanan Anda bersama layanan Maritim Indonesia.</p>
            </div>

            <div class="auth-visual-footer">
                CONNECTING ISLANDS, DELIVERING EXCELLENCE.
            </div>
        </section>

        <section class="auth-panel">
            <div class="auth-form-wrap">
                <a class="auth-back" href="${pageContext.request.contextPath}/">
                    ← Kembali ke Beranda
                </a>

                <div class="auth-heading">
                    <span class="auth-kicker">CUSTOMER PORTAL</span>
                    <h2>Buat akun baru</h2>
                    <p>Lengkapi data berikut untuk mendaftar.</p>
                </div>

                <form class="auth-form" method="post"
                      action="${pageContext.request.contextPath}/register">
                    <label for="full_name">Nama lengkap</label>
                    <input id="full_name" name="full_name" type="text"
                           placeholder="Nama lengkap Anda"
                           autocomplete="name" maxlength="100" required>

                    <label for="email">Alamat email</label>
                    <input id="email" name="email" type="email"
                           placeholder="nama@email.com"
                           autocomplete="email" maxlength="150" required>

                    <label for="phone">Nomor telepon</label>
                    <input id="phone" name="phone" type="tel"
                           placeholder="Contoh: 081234567890"
                           autocomplete="tel" maxlength="30" required>

                    <label for="password">Password</label>
                    <input id="password" name="password" type="password"
                           placeholder="Buat password (minimal 8 karakter)"
                           autocomplete="new-password" minlength="8" required>

                    <button class="auth-submit" type="submit">Buat Akun →</button>
                </form>

                <p class="auth-switch">
                    Sudah punya akun?
                    <a href="${pageContext.request.contextPath}/login">Login di sini</a>
                </p>
            </div>
        </section>
    </main>
</body>
</html>
