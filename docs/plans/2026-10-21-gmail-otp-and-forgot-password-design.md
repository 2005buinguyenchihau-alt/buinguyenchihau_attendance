# Thiết Kế: Gửi Mã OTP Qua Gmail & Tính Năng Quên Mật Khẩu (PRIME Attendance)

**Ngày lập**: 2026-10-21  
**Tác giả**: Bùi Nguyễn Chí Hậu  
**Hệ thống**: PRIME Attendance (Flutter + Node.js Express WebAPI + SQLite)

---

## 1. Mục Tiêu & Yêu Cầu

1. **Gửi mã OTP thật về hộp thư Gmail**:
   - Khi người dùng đăng ký tài khoản mới: mã OTP kích hoạt tài khoản được gửi trực tiếp vào Gmail của người dùng.
   - Khi người dùng yêu cầu khôi phục mật khẩu (Quên mật khẩu): mã OTP xác thực được gửi trực tiếp vào Gmail.
2. **Cơ chế Fallback thông minh**:
   - Tự động phát hiện cấu hình `GMAIL_USER` và `GMAIL_APP_PASSWORD` trong file `.env`.
   - Nếu chưa điền App Password hoặc mạng lỗi, server vẫn lưu mã OTP vào SQLite database, ghi log ra console và trả về `otpPreview` để đảm bảo buổi thuyết trình/chấm điểm không bao giờ bị tắc nghẽn.
3. **Quy trình Quên Mật Khẩu (2 bước tinh gọn)**:
   - Bước 1: Nhập Email đã đăng ký -> Bấm nhận mã OTP qua Gmail.
   - Bước 2: Nhập mã OTP 6 số + Mật khẩu mới + Xác nhận mật khẩu mới -> Bấm cập nhật mật khẩu.

---

## 2. Thiết Kế Kiến Trúc Backend (`buinguyenchihau_api`)

### 2.1. Thư viện & Cấu hình
- Thư viện: `nodemailer`
- File cấu hình môi trường: `.env`
  ```env
  PORT=5000
  GMAIL_USER=your_email@gmail.com
  GMAIL_APP_PASSWORD=your_16_char_app_password
  ```

### 2.2. Dịch vụ Email (`src/services/emailService.js`)
- Tạo transporter kết nối SMTP Gmail (`service: 'gmail'`).
- Hàm `sendOtpEmail({ toEmail, otpCode, subject, title, description })`:
  - Tạo email HTML chuyên nghiệp, đồng bộ thương hiệu PRIME Attendance.
  - Hiển thị mã số OTP 6 chữ số lớn, nổi bật.
  - Cảnh báo hiệu lực trong vòng 5 phút và lưu ý không chia sẻ mã.
  - Xử lý lỗi `try...catch` để không làm crash API nếu việc gửi email gặp sự cố.

### 2.3. Endpoints API (`/api/auth`)
1. `POST /api/auth/register`:
   - Sinh OTP, gọi `emailService.sendOtpEmail` gửi về email đăng ký.
2. `POST /api/auth/verify-register-otp`:
   - Xác thực OTP, tạo tài khoản trong database `users`.
3. `POST /api/auth/forgot-password`:
   - Nhận `{ email }`.
   - Kiểm tra email có trong bảng `users` không.
   - Sinh mã OTP loại `reset_password`.
   - Gửi email OTP khôi phục mật khẩu về Gmail.
4. `POST /api/auth/reset-password`:
   - Nhận `{ email, otp_code, new_password }`.
   - Xác thực mã OTP loại `reset_password`.
   - Hash mật khẩu mới bằng `bcryptjs`.
   - Cập nhật `password_hash` trong bảng `users`.

---

## 3. Thiết Kế Giao Diện Flutter (`hau_flutter`)

### 3.1. Màn hình Đăng Nhập (`login_screen.dart`)
- Thêm nút liên kết *"Quên mật khẩu?"* bên dưới ô nhập mật khẩu để dẫn sang màn hình quên mật khẩu.

### 3.2. Màn hình Quên Mật Khẩu (`forgot_password_screen.dart`)
- Giao diện 2 bước mượt mà:
  - **Trạng thái 1 (Nhập Email)**: Ô nhập email + Nút *"Gửi mã xác thực qua Gmail"*.
  - **Trạng thái 2 (Nhập OTP & Mật khẩu mới)**:
    - Hiển thị email đã nhận mã + nút gửi lại mã (Resend).
    - Ô nhập mã OTP 6 số.
    - Ô nhập mật khẩu mới & ô xác nhận mật khẩu mới (có nút ẩn/hiện mật khẩu).
    - Khung demo OTP trợ giúp (nếu server trả về `otpPreview`).
    - Nút *"Xác nhận đổi mật khẩu"*.
  - Đổi mật khẩu thành công: Thông báo SnackBar và điều hướng về màn hình đăng nhập.

### 3.3. Tích hợp Service & Provider
- `ApiService`:
  - `forgotPassword(String email)` -> `POST /api/auth/forgot-password`
  - `resetPassword(String email, String otpCode, String newPassword)` -> `POST /api/auth/reset-password`
- `AuthProvider`:
  - Bổ sung `forgotPassword` và `resetPassword` để quản lý trạng thái loading và thông báo lỗi.

---

## 4. Kế Hoạch Xác Minh & Kiểm Thử
1. Chạy lệnh cài đặt `nodemailer` và khởi tạo transporter.
2. Kiểm tra API `forgot-password` và `reset-password` với SQLite.
3. Kiểm tra gửi email với tài khoản Gmail thật (khi có App Password) và cơ chế fallback.
4. Chạy `flutter analyze` xác nhận không có lỗi code.
5. Kiểm tra flow toàn diện trên app: Đăng ký nhận OTP -> Đăng nhập -> Quên mật khẩu -> Đặt mật khẩu mới -> Đăng nhập bằng mật khẩu mới.
