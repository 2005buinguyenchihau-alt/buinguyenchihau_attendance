# Thiết Kế Hệ Thống Điểm Danh Sinh Viên Thông Minh (PRIME Attendance System)

- **Sinh viên thực hiện:** Bùi Nguyễn Chí Hậu
- **Nhóm:** PRIME
- **GitHub:** [2005buinguyenchihau-alt](https://github.com/2005buinguyenchihau-alt)
- **Đề tài:** 3. App điểm danh cho sinh viên
- **Quy chuẩn đặt tên bắt buộc (Chống 0đ):**
  - Tên Project Mobile: `buinguyenchihau_attendance`
  - Tên WebAPI Backend: `buinguyenchihau_api`
  - Tên Cơ sở dữ liệu: `buinguyenchihau_db` (SQLite/PostgreSQL)

---

## 1. Mục Tiêu & Yêu Cầu Chấm Điểm
1. **Đăng ký tài khoản qua Email:** Xác thực mã OTP 6 số, phân chia vai trò sinh viên / giảng viên.
2. **Đăng nhập 3 yếu tố:** Tên đăng nhập + Mật khẩu + Mã OTP 2FA (hỗ trợ sinh trắc học vân tay / FaceID).
3. **Phân quyền 3 cấp (Role-based Access Control):**
   - **Admin:** Quản trị toàn diện (CRUD tài khoản, phân quyền giảng viên, môn học, lớp học, cấu hình tọa độ trường học).
   - **Giảng viên (Staff):** Quản lý lớp dạy, tạo ca điểm danh, hiển thị QR code xoay tự động (5s), xem sinh viên điểm danh realtime, duyệt đơn xin vắng.
   - **Sinh viên (Client):** Xem thời khóa biểu, quét QR điểm danh kèm định vị GPS và xác thực khuôn mặt selfie, theo dõi chuyên cần, nộp đơn xin vắng có minh chứng.
4. **Các chức năng CRUD hoàn chỉnh (5.5đ):**
   - CRUD Lớp học / Môn học / Lịch học
   - CRUD Người dùng / Sinh viên / Giảng viên
   - CRUD Phiên điểm danh / Báo cáo điểm danh / Đơn xin phép vắng
5. **3 Tính năng nâng cao đã thuyết trình (3.5đ):**
   - **(e) Quét mã QR động xoay chu kỳ 5s (Dynamic Rotating QR Code & TOTP):** Ngăn chặn chụp màn hình gửi qua Zalo/Facebook.
   - **(b) Kiểm tra vị trí GPS & Hàng rào địa lý (GPS Geofencing):** Chỉ cho phép điểm danh trong bán kính quy định (ví dụ: 50m quanh phòng học).
   - **(a) Xác thực sinh trắc học & Khuôn mặt (Face Recognition & Biometrics):** Chụp selfie đối chiếu khuôn mặt khi điểm danh và hỗ trợ đăng nhập vân tay/FaceID.
6. **Tính năng mới lạ độc quyền (1đ):**
   - **"AI Triple-Shield Anti-Fraud Attendance System"**: Cơ chế bảo vệ 3 tầng đồng thời ($\text{QR 5s} + \text{GPS Geofence} + \text{Face Match}$), kèm Live Radar Monitor cho giảng viên thấy ngay cự ly GPS và ảnh selfie của sinh viên vừa check-in.
7. **Giao diện & Độ tương thích (1đ):** Material 3 hiện đại, tông màu học đường sang trọng, dễ chạy trên mọi máy tính của thành viên nhóm PRIME.

---

## 2. Kiến Trúc Hệ Thống

```
hau_flutter/
├── buinguyenchihau_api/            # Backend WebAPI Node.js (Express + SQLite)
│   ├── src/
│   │   ├── config/                 # DB connection (buinguyenchihau_db) & JWT Secret
│   │   ├── controllers/            # Auth, User, Class, Attendance, Request Controllers
│   │   ├── middlewares/            # Role validation, Token validation
│   │   ├── routes/                 # Express API endpoints
│   │   ├── utils/                  # OTP generator, TOTP hash, Geofence distance
│   │   └── server.js               # WebAPI entrypoint (Port 5000)
│   ├── buinguyenchihau_db.sqlite   # File CSDL SQLite chuẩn quan hệ
│   └── package.json
├── lib/                            # Ứng dụng di động Flutter
│   ├── config/                     # Colors, Themes, API Constants
│   ├── models/                     # User, CourseClass, Session, AttendanceRecord
│   ├── providers/                  # AuthProvider, AttendanceProvider, ClassProvider
│   ├── services/                   # ApiService, LocationService, BiometricService, CameraService
│   ├── screens/
│   │   ├── auth/                   # Login, Register, OtpVerification
│   │   ├── admin/                  # AdminDashboard, ManageUsers, ManageClasses
│   │   ├── lecturer/               # LecturerDashboard, CreateSession, DynamicQrPresenter
│   │   └── student/                # StudentDashboard, ScanQrScreen, FaceCaptureScreen, HistoryScreen
│   ├── widgets/                    # CustomAppBar, StatCard, DynamicQrView, LiveFeedItem
│   └── main.dart                   # Entry point
```

---

## 3. Thiết Kế Cơ Sở Dữ Liệu (`buinguyenchihau_db`)

- **`users`**:
  - `id` (INTEGER PRIMARY KEY)
  - `username` (VARCHAR UNIQUE)
  - `email` (VARCHAR UNIQUE)
  - `password_hash` (TEXT)
  - `full_name` (VARCHAR)
  - `code` (VARCHAR) -- Mã sinh viên hoặc Mã cán bộ
  - `role` (VARCHAR: `admin`, `lecturer`, `student`)
  - `avatar` (TEXT)
  - `face_data` (TEXT) -- Dữ liệu khuôn mặt đã đăng ký
  - `created_at` (DATETIME)

- **`otp_codes`**:
  - `id` (INTEGER PRIMARY KEY)
  - `email` (VARCHAR)
  - `otp_code` (VARCHAR)
  - `type` (VARCHAR: `register`, `login`)
  - `expires_at` (DATETIME)
  - `is_used` (BOOLEAN)

- **`classes`**:
  - `id` (INTEGER PRIMARY KEY)
  - `class_code` (VARCHAR UNIQUE)
  - `class_name` (VARCHAR)
  - `lecturer_id` (INTEGER REFERENCES users(id))
  - `room_name` (VARCHAR)
  - `latitude` (REAL)
  - `longitude` (REAL)
  - `allowed_radius` (REAL DEFAULT 50.0)

- **`class_students`**:
  - `id` (INTEGER PRIMARY KEY)
  - `class_id` (INTEGER REFERENCES classes(id))
  - `student_id` (INTEGER REFERENCES users(id))

- **`attendance_sessions`**:
  - `id` (INTEGER PRIMARY KEY)
  - `class_id` (INTEGER REFERENCES classes(id))
  - `session_name` (VARCHAR)
  - `totp_secret` (VARCHAR)
  - `start_time` (DATETIME)
  - `end_time` (DATETIME)
  - `status` (VARCHAR: `active`, `closed`)

- **`attendances`**:
  - `id` (INTEGER PRIMARY KEY)
  - `session_id` (INTEGER REFERENCES attendance_sessions(id))
  - `student_id` (INTEGER REFERENCES users(id))
  - `check_in_time` (DATETIME)
  - `latitude` (REAL)
  - `longitude` (REAL)
  - `distance_meters` (REAL)
  - `face_image` (TEXT)
  - `status` (VARCHAR: `present`, `late`, `fraud_suspect`, `absent`)

- **`absence_requests`**:
  - `id` (INTEGER PRIMARY KEY)
  - `class_id` (INTEGER REFERENCES classes(id))
  - `student_id` (INTEGER REFERENCES users(id))
  - `reason` (TEXT)
  - `proof_image` (TEXT)
  - `status` (VARCHAR: `pending`, `approved`, `rejected`)
  - `created_at` (DATETIME)

---

## 4. Đặc Tả Luồng Nghiệp Vụ

### 4.1. Đăng ký & Đăng nhập OTP
1. Sinh viên/Giảng viên đăng ký với Email trường, Họ tên, Mã số, Mật khẩu.
2. WebAPI tạo mã OTP 6 số ngẫu nhiên, lưu vào bảng `otp_codes` (hết hạn sau 5 phút).
3. Người dùng nhập mã OTP để kích hoạt tài khoản.
4. Đăng nhập yêu cầu Tên đăng nhập + Mật khẩu + Mã OTP 2FA.

### 4.2. Phiên Điểm Danh Bằng Mã QR Động (Dynamic Rotating QR)
1. Giảng viên bấm "Mở Ca Điểm Danh" trên ứng dụng/web.
2. Màn hình giảng viên hiển thị QR Code động:
   - Mỗi 5 giây sinh ra 1 payload: `{"session_id": X, "timestamp": T, "hash": HMAC(secret, T)}`.
   - QR tự động refresh mượt mà kèm thanh đếm ngược 5 giây.

### 4.3. Quy Trình Điểm Danh Sinh Viên 3 Lớp Chống Gian Lận (AI Smart Shield)
1. Sinh viên bấm "Điểm Danh Ngay" trên Dashboard.
2. **Bước 1 (Quét QR):** Camera quét mã QR trên màn hình giảng viên. Hệ thống kiểm tra mã có còn trong hạn 5s không.
3. **Bước 2 (Kiểm tra GPS Geofence):** App đo tọa độ GPS hiện tại qua `geolocator`. So sánh với tọa độ phòng học theo công thức Haversine:
   $$d = 2R \cdot \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta \varphi}{2}\right) + \cos(\varphi_1)\cos(\varphi_2)\sin^2\left(\frac{\Delta \lambda}{2}\right)}\right)$$
   Nếu $d > 50\text{m}$, từ chối điểm danh.
4. **Bước 3 (Xác thực Selfie Khuôn mặt):** Mở camera trước chụp 1 bức ảnh selfie nhanh. Đối chiếu khuôn mặt và lưu lại bằng chứng check-in.
5. Gửi bản ghi lên `buinguyenchihau_api`. Màn hình giảng viên lập tức xuất hiện thông báo sinh viên vừa điểm danh thành công kèm cự ly GPS và ảnh chụp.

---

## 5. Chiến Lược Kiểm Thử & Chạy Dự Án
- **Khởi chạy WebAPI:**
  ```bash
  cd buinguyenchihau_api
  npm install
  npm start
  ```
  WebAPI tự khởi tạo cơ sở dữ liệu `buinguyenchihau_db.sqlite` kèm dữ liệu mẫu sẵn có (Admin, Giảng viên, Sinh viên, Lớp học).
- **Khởi chạy Flutter App:**
  ```bash
  flutter pub get
  flutter run
  ```
  Hỗ trợ chạy trên Windows / Android / Chrome Web.
