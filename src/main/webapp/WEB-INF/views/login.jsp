<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login | Maritim Indonesia</title>
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
                <span class="auth-kicker">YOUR MARITIME PARTNER</span>
                <h1>Selamat datang kembali.</h1>
                <p>Masuk ke akun Anda untuk melanjutkan layanan dan charter kapal bersama Maritim Indonesia.</p>
            </div>

            <div class="auth-visual-footer">
                RELIABLE CONNECTIONS. EXCEPTIONAL SERVICE.
            </div>
        </section>

        <section class="auth-panel">
            <div class="auth-form-wrap">
                <a class="auth-back" href="${pageContext.request.contextPath}/">
                    ← Kembali ke Beranda
                </a>

                <div class="auth-heading">
                    <span class="auth-kicker">ACCOUNT PORTAL</span>
                    <h2>Login akun</h2>
                    <p>Pilih jenis akun dan masukkan detail login Anda.</p>
                </div>

                <% if ("1".equals(request.getParameter("logout"))) { %>
                    <div class="auth-notice">Anda telah berhasil keluar dari akun.</div>
                <% } %>

                <% if ("1".equals(request.getParameter("registered"))) { %>
                    <div class="auth-notice">Pendaftaran berhasil. Silakan login.</div>
                <% } %>

                <% if ("1".equals(request.getParameter("error"))) { %>
                    <div class="auth-notice">Login gagal. Periksa kembali informasi akun Anda.</div>
                <% } %>

                <form class="auth-form" method="post"
                      action="${pageContext.request.contextPath}/login">

                    <label for="login_type">Jenis akun</label>
                    <select id="login_type" name="login_type" required
                            onchange="changeLoginFields()"
                            style="width:100%; padding:14px; margin-bottom:18px;">
                        <option value="customer">Customer</option>
                        <option value="employee">Employee / Admin</option>
                    </select>

                    <div id="customerFields">
                        <label for="email">Alamat email</label>
                        <input id="email" name="email" type="email"
                               placeholder="nama@email.com"
                               autocomplete="email">

                    </div>

                    <div id="employeeFields" style="display:none;">
                        <label for="employee_number">Nomor karyawan</label>
                        <input id="employee_number" name="employee_number"
                               type="text" placeholder="Masukkan nomor karyawan"
                               autocomplete="username" disabled>
                    </div>

                    <label for="password">Password</label>
                    <input id="password" name="password" type="password"
                           placeholder="Masukkan password"
                           autocomplete="current-password" required>

                    <button class="auth-submit" type="submit">Login ke Akun →</button>
                </form>

                <p class="auth-switch" id="registerLink">
                    Belum punya akun?
                    <a href="${pageContext.request.contextPath}/register">Daftar sekarang</a>
                </p>

                <p class="auth-security">
                    🔒 Informasi akun Anda diproses melalui sistem autentikasi.
                </p>
            </div>
        </section>
    </main>

    <script>
        function changeLoginFields() {
            const loginType = document.getElementById("login_type").value;
            const customerFields = document.getElementById("customerFields");
            const employeeFields = document.getElementById("employeeFields");
            const email = document.getElementById("email");
            const employeeNumber = document.getElementById("employee_number");
            const registerLink = document.getElementById("registerLink");

            if (loginType === "employee") {
                customerFields.style.display = "none";
                employeeFields.style.display = "block";

                email.required = false;
                email.disabled = true;

                employeeNumber.required = true;
                employeeNumber.disabled = false;

                registerLink.style.display = "none";
            } else {
                customerFields.style.display = "block";
                employeeFields.style.display = "none";

                email.required = true;
                email.disabled = false;

                employeeNumber.required = false;
                employeeNumber.disabled = true;

                registerLink.style.display = "block";
            }
        }
    </script>
</body>
</html>
