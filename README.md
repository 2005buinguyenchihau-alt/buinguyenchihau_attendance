# PRIME Attendance System - Ứng Dụng Điểm Danh Sinh Viên Thông Minh

- **Sinh viên thực hiện:** Bùi Nguyễn Chí Hậu
- **Mã số / GitHub:** [2005buinguyenchihau-alt](https://github.com/2005buinguyenchihau-alt)
- **Nhóm:** PRIME
- **Đề tài:** 3. App điểm danh cho sinh viên
- **Thành phần hệ thống:**
  - **Flutter Mobile App:** `buinguyenchihau_attendance`
  - **Backend WebAPI:** `buinguyenchihau_api` (Node.js Express RESTful API)
  - **Cơ sở dữ liệu:** `buinguyenchihau_db` (SQLite chuẩn quan hệ)

---

## 🌟 Các Chức Năng Chính

### 1. Xác thực & Phân quyền
- Đăng ký tài khoản qua Email có gửi mã OTP 6 số.
- Đăng nhập 2 lớp (Mật khẩu + Xác thực OTP 2FA) hoặc qua Sinh trắc học (Vân tay / FaceID).
- Phân quyền 3 cấp (Role-based Navigation):
  - 👑 **Admin:** Quản lý tài khoản (CRUD User), Lớp học (CRUD Class), cấu hình GPS Geofence phòng học.
  - 👨‍🏫 **Giảng viên (Staff):** Mở ca điểm danh, chiếu mã QR động xoay sau 5s, theo dõi Radar sinh viên check-in thời gian thực, duyệt đơn xin vắng.
  - 🎓 **Sinh viên:** Quét QR, kiểm tra khoảng cách GPS phòng học, chụp selfie xác thực khuôn mặt, xem lịch sử và tỷ lệ chuyên cần.

### 2. Bộ 3 Tính Năng Thuyết Trình Nâng Cao (3.5đ)
- **(e) Quét mã QR Động xoay chu kỳ 5s (Dynamic Rotating TOTP QR):** Tự động đổi mã sau mỗi 5 giây, vô hiệu hóa việc chụp màn hình gửi Zalo cho bạn ở nhà điểm danh hộ.
- **(b) Định vị GPS & Hàng rào địa lý (GPS Geofencing):** Thuật toán Haversine đo khoảng cách thiết bị của sinh viên tới tọa độ phòng học ($\le 50$m mới hợp lệ).
- **(a) Xác thực Sinh trắc học & Khuôn mặt (Face Recognition & Biometrics):** Tích hợp Face Selfie Verification chống mang nhiều máy và đăng nhập vân tay.

### 3. Tính Năng Mới Lạ Độc Quyền (1đ)
- 🛡️ **"AI Smart Shield Anti-Proxy"**: Cơ chế bảo vệ 3 tầng đồng thời ($\text{Dynamic QR 5s} + \text{GPS Geofence} + \text{AI Selfie Match}$) kết hợp **Live Radar Monitor** cho Giảng viên.

---

## 🚀 Hướng Dẫn Khởi Chạy Dự Án

### 1. Chạy Backend WebAPI (`buinguyenchihau_api`)
```bash
cd buinguyenchihau_api
npm install
npm start
```
- Server sẽ chạy tại: `http://localhost:5000`
- Cơ sở dữ liệu SQLite `buinguyenchihau_db.sqlite` sẽ tự động khởi tạo và seed dữ liệu mẫu đầy đủ.

### 2. Chạy Ứng dụng Di Động Flutter (`buinguyenchihau_attendance`)
```bash
flutter pub get
flutter run
```
Hỗ trợ chạy trên Android, Windows Desktop hoặc Chrome Web.

### 3. Tài Khoản Để Kiểm Thử (Seed Data)
| Vai trò | Họ tên | Tên đăng nhập | Email | Mật khẩu | Cơ chế OTP |
|---|---|---|---|---|---|
| Quản trị viên | Bùi Nguyễn Chí Hậu (Admin) | `admin` | `admin@prime.edu.vn` | `Admin@123` | Mã OTP hiển thị trên màn hình |
| Giảng viên | ThS. Bùi Nguyễn Chí Hậu | `giangvien.hau` | `gv.hau@prime.edu.vn` | `Gv@123456` | Mã OTP hiển thị trên màn hình |
| Sinh viên | Bùi Nguyễn Chí Hậu (SV) | `sinhvien.hau` | `2005buinguyenchihau@gmail.com` | `Sv@123456` | Gửi mã OTP thực tế về Gmail |
| Sinh viên | Trần Minh Nghĩa | `sinhvien.nghia` | `nghia@prime.edu.vn` | `Sv@123456` | Mã OTP hiển thị trên màn hình |
| Sinh viên | Nguyễn Tường Vy | `sinhvien.vy` | `vy@prime.edu.vn` | `Sv@123456` | Mã OTP hiển thị trên màn hình |
