# Kế Hoạch Triển Khai: Gửi Mã OTP Qua Gmail & Quên Mật Khẩu

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Triển khai gửi mã OTP xác thực thực tế qua hộp thư Gmail (khi Đăng ký tài khoản và Quên mật khẩu) trên Backend Node.js Express, đồng thời xây dựng màn hình Quên Mật Khẩu 2 bước trên ứng dụng Flutter.

**Architecture:** Sử dụng `nodemailer` với kết nối Gmail SMTP và cấu hình thông qua `.env`. Tích hợp cơ chế fallback an toàn (log console + preview) đảm bảo không bị gián đoạn demo. Mở rộng controller auth phía backend và xây dựng màn hình `ForgotPasswordScreen` chuẩn Material 3 trên Flutter.

**Tech Stack:** Node.js Express, `nodemailer`, bcryptjs, Flutter 3 (Dart), Provider, SQLite.

---

### Task 1: Cài đặt Nodemailer & Xây dựng `emailService.js`

**Files:**
- Modify: `buinguyenchihau_api/package.json`
- Create: `buinguyenchihau_api/.env`
- Create: `buinguyenchihau_api/src/services/emailService.js`
- Test: `buinguyenchihau_api/test/email_test.js`

**Step 1: Cài đặt package `nodemailer`**
Run: `npm install nodemailer` trong thư mục `buinguyenchihau_api`.

**Step 2: Tạo file `.env` mẫu**
Chứa `GMAIL_USER` và `GMAIL_APP_PASSWORD`.

**Step 3: Viết module `emailService.js`**
Hàm `sendOtpEmail({ toEmail, otpCode, title, description })` với template HTML đẹp, logo PRIME và mã OTP to rõ. Bọc trong try-catch, tự động fallback nếu chưa có App Password.

**Step 4: Kiểm thử module gửi email**
Run: `node test/email_test.js` để kiểm tra khả năng tạo transporter và template.

---

### Task 2: Backend API Quên Mật Khẩu & Tích Hợp Gửi Email Đăng Ký

**Files:**
- Modify: `buinguyenchihau_api/src/utils/otp.js`
- Modify: `buinguyenchihau_api/src/controllers/authController.js`
- Modify: `buinguyenchihau_api/src/routes/authRoutes.js`
- Test: `buinguyenchihau_api/test/forgot_password_test.js`

**Step 1: Viết test case `forgot_password_test.js`**
Test gọi `POST /api/auth/forgot-password` và `POST /api/auth/reset-password`.

**Step 2: Cập nhật `authController.js`**
- Trong `register`: Gọi `emailService.sendOtpEmail` gửi OTP đăng ký về Gmail.
- Thêm hàm `forgotPassword(req, res)`: Kiểm tra email, sinh OTP loại `reset_password`, gọi `emailService.sendOtpEmail`.
- Thêm hàm `resetPassword(req, res)`: Xác thực OTP loại `reset_password`, hash mật khẩu mới và update `users`.

**Step 3: Cập nhật route `authRoutes.js`**
- `router.post('/forgot-password', authController.forgotPassword);`
- `router.post('/reset-password', authController.resetPassword);`

**Step 4: Chạy test và restart backend**
Chạy `node test/forgot_password_test.js` và xác nhận PASS.

---

### Task 3: Flutter Client API & State Management

**Files:**
- Modify: `lib/config/api_constants.dart`
- Modify: `lib/services/api_service.dart`
- Modify: `lib/providers/auth_provider.dart`

**Step 1: Thêm endpoint vào `api_constants.dart`**
- `static String get forgotPassword => '$baseUrl/auth/forgot-password';`
- `static String get resetPassword => '$baseUrl/auth/reset-password';`

**Step 2: Thêm hàm vào `api_service.dart`**
- `Future<Map<String, dynamic>> forgotPassword(String email)`
- `Future<Map<String, dynamic>> resetPassword({required String email, required String otpCode, required String newPassword})`

**Step 3: Thêm method vào `auth_provider.dart`**
- Quản lý `isLoading`, `errorMessage`, `otpPreview`.

---

### Task 4: Giao diện Flutter Quên Mật Khẩu (`ForgotPasswordScreen`)

**Files:**
- Create: `lib/screens/auth/forgot_password_screen.dart`
- Modify: `lib/screens/auth/login_screen.dart`

**Step 1: Xây dựng màn hình `ForgotPasswordScreen`**
- Quy trình 2 bước:
  - Trạng thái 1: Nhập email + Nút "Gửi mã xác thực qua Gmail".
  - Trạng thái 2: Nhập OTP + Mật khẩu mới + Xác nhận mật khẩu + Khung demo OTP trợ giúp + Nút "Đổi mật khẩu".
- Thiết kế responsive, chống tràn chữ với `Expanded`/`Flexible`/`Wrap`.

**Step 2: Thêm liên kết trên `login_screen.dart`**
- Đặt nút *"Quên mật khẩu?"* dưới ô nhập mật khẩu để mở `ForgotPasswordScreen`.

---

### Task 5: Xác Minh Toàn Diện & Khởi Động Lại Server

**Step 1: Khởi động lại backend server**
Cập nhật tiến trình chạy nền của `node src/server.js`.

**Step 2: Chạy kiểm tra tĩnh `flutter analyze`**
Xác nhận `No issues found!`.

**Step 3: Cập nhật `docs/plans/task.md`**
Đánh dấu hoàn thành toàn bộ các mục đã lên kế hoạch.
