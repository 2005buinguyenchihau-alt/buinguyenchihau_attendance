# Hệ Thống Điểm Danh Sinh Viên Thông Minh (PRIME - Bùi Nguyễn Chí Hậu) Implementation Plan

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Xây dựng ứng dụng di động Flutter và WebAPI Node.js (`buinguyenchihau_api`, `buinguyenchihau_db`) phục vụ điểm danh sinh viên với đăng ký/đăng nhập OTP, phân quyền 3 cấp (Admin, Giảng viên, Sinh viên), đầy đủ CRUD, 3 tính năng nâng cao (QR động xoay 5s, định vị GPS Geofence, nhận diện khuôn mặt) và tính năng độc quyền "AI Triple-Shield Anti-Fraud".

**Architecture:** Monorepo gồm `buinguyenchihau_api/` (Express RESTful API + SQLite DB `buinguyenchihau_db.sqlite`) và `lib/` (Flutter Mobile App `buinguyenchihau_attendance` hỗ trợ đa nền tảng). Giao tiếp qua REST API & WebSockets.

**Tech Stack:** 
- Mobile: Flutter, Provider / StateNotifier, `mobile_scanner`, `geolocator`, `camera`, `local_auth`, `http`, Material 3.
- Backend: Node.js, Express, `better-sqlite3` / `sqlite3`, `jsonwebtoken`, `bcryptjs`, `cors`, `uuid`.
- Database: `buinguyenchihau_db` (SQLite relational database).

---

### Task 1: Thiết lập Git Remote cho Repository GitHub
**Files:**
- Modify: `.git/config`
- Modify: `README.md`

**Step 1:** Cấu hình remote `origin` tới GitHub của Bùi Nguyễn Chí Hậu (`2005buinguyenchihau-alt`).
```bash
git remote add origin https://github.com/2005buinguyenchihau-alt/buinguyenchihau_attendance.git
git remote -v
```
**Step 2:** Cập nhật `README.md` với thông tin sinh viên Bùi Nguyễn Chí Hậu, đề tài và hướng dẫn chạy nhanh.
**Step 3:** Commit:
```bash
git add README.md
git commit -m "docs: update README with project overview and student info"
```

---

### Task 2: Xây dựng Backend WebAPI `buinguyenchihau_api` & Database `buinguyenchihau_db`
**Files:**
- Create: `buinguyenchihau_api/package.json`
- Create: `buinguyenchihau_api/src/config/database.js`
- Create: `buinguyenchihau_api/src/server.js`
- Create: `buinguyenchihau_api/src/utils/otp.js`
- Create: `buinguyenchihau_api/src/utils/geofence.js`

**Step 1:** Khởi tạo `buinguyenchihau_api/package.json` với Express, sqlite3 / better-sqlite3, cors, bcryptjs, jsonwebtoken.
**Step 2:** Tạo `buinguyenchihau_api/src/config/database.js` tự động khởi tạo các bảng: `users`, `otp_codes`, `classes`, `class_students`, `attendance_sessions`, `attendances`, `absence_requests`, và seed dữ liệu mẫu (Admin, Giảng viên Hậu, Sinh viên Hậu).
**Step 3:** Tạo `buinguyenchihau_api/src/utils/geofence.js` (tính khoảng cách Haversine giữa tọa độ GPS của SV và phòng học).
**Step 4:** Chạy kiểm tra khởi động server:
```bash
cd buinguyenchihau_api
npm install
node src/server.js
```
Expected: Server chạy trên cổng 5000, in ra `[buinguyenchihau_api] Server running on port 5000 and buinguyenchihau_db initialized successfully`.
**Step 5:** Commit:
```bash
git add buinguyenchihau_api/
git commit -m "feat(api): initialize buinguyenchihau_api and buinguyenchihau_db schema"
```

---

### Task 3: Triển khai Authentication & OTP Endpoints trong WebAPI
**Files:**
- Create: `buinguyenchihau_api/src/middlewares/auth.js`
- Create: `buinguyenchihau_api/src/controllers/authController.js`
- Create: `buinguyenchihau_api/src/routes/authRoutes.js`

**Step 1:** Viết middleware kiểm tra JWT Token và phân quyền (Roles: `admin`, `lecturer`, `student`).
**Step 2:** Viết API `POST /api/auth/register` (tạo user, sinh OTP 6 số lưu vào `otp_codes`).
**Step 3:** Viết API `POST /api/auth/verify-otp` (kích hoạt tài khoản hoặc xác thực 2FA).
**Step 4:** Viết API `POST /api/auth/login` (kiểm tra username/password, tạo OTP và trả token/role).
**Step 5:** Kiểm thử các API bằng lệnh curl / test script.
**Step 6:** Commit:
```bash
git add buinguyenchihau_api/src/
git commit -m "feat(api): implement email registration, login, and 2FA OTP verification"
```

---

### Task 4: Triển khai CRUD Endpoints và Quản Lý Điểm Danh trong WebAPI
**Files:**
- Create: `buinguyenchihau_api/src/controllers/classController.js`
- Create: `buinguyenchihau_api/src/controllers/attendanceController.js`
- Create: `buinguyenchihau_api/src/controllers/requestController.js`
- Create: `buinguyenchihau_api/src/routes/apiRoutes.js`

**Step 1:** Viết CRUD Lớp học / Môn học / Thời khóa biểu (`GET, POST, PUT, DELETE /api/classes`).
**Step 2:** Viết CRUD Người dùng cho Admin (`GET, POST, PUT, DELETE /api/users`).
**Step 3:** Viết API Tạo ca điểm danh và sinh Dynamic TOTP QR Token (`POST /api/attendance/session/start`, `GET /api/attendance/session/:id/current-qr`).
**Step 4:** Viết API Điểm danh 3 lớp bảo mật (`POST /api/attendance/check-in`):
- Nhận: `session_id`, `qr_token`, `latitude`, `longitude`, `face_data`.
- Validate QR token còn hạn 5s không.
- Validate cự ly GPS so với tọa độ lớp học ($\le$ `allowed_radius`).
- Lưu bản ghi điểm danh và broadcast/lưu vào DB.
**Step 5:** Viết CRUD Đơn xin vắng / Điểm danh bù (`POST /api/requests`, `GET /api/requests`, `PUT /api/requests/:id/review`).
**Step 6:** Commit:
```bash
git add buinguyenchihau_api/src/
git commit -m "feat(api): implement CRUD classes, users, attendance sessions, and requests"
```

---

### Task 5: Cấu hình Flutter App `buinguyenchihau_attendance`
**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/build.gradle` (nếu cần cho permission)
- Modify: `android/app/src/main/AndroidManifest.xml` (Camera, Location permissions)
- Create: `lib/config/api_constants.dart`
- Create: `lib/config/theme.dart`

**Step 1:** Cập nhật `pubspec.yaml` với: `provider`, `http`, `intl`, `qr_flutter`, `mobile_scanner`, `geolocator`, `local_auth`, `camera`.
**Step 2:** Khai báo quyền Camera và GPS trong `AndroidManifest.xml`.
**Step 3:** Tạo `lib/config/theme.dart` với Material 3 phong cách hiện đại (Màu chủ đạo: Indigo / Teal học đường sang trọng, hỗ trợ Dark / Light mode).
**Step 4:** Tạo `lib/config/api_constants.dart` chứa Base URL kết nối đến `buinguyenchihau_api`.
**Step 5:** Chạy `flutter pub get` để kiểm tra tải packages.
**Step 6:** Commit:
```bash
git add pubspec.yaml android/ lib/config/
git commit -m "feat(flutter): setup dependencies, permissions, and theme for buinguyenchihau_attendance"
```

---

### Task 6: Xây dựng Models & Services trong Flutter
**Files:**
- Create: `lib/models/user_model.dart`
- Create: `lib/models/class_model.dart`
- Create: `lib/models/attendance_model.dart`
- Create: `lib/models/request_model.dart`
- Create: `lib/services/api_service.dart`
- Create: `lib/services/location_service.dart`
- Create: `lib/services/biometric_service.dart`
- Create: `lib/providers/auth_provider.dart`

**Step 1:** Xây dựng các Data Models ánh xạ chuẩn xác với các bảng trong `buinguyenchihau_db`.
**Step 2:** Xây dựng `ApiService` đóng gói các hàm gọi API đăng ký, đăng nhập, OTP, CRUD và điểm danh.
**Step 3:** Xây dựng `LocationService` lấy tọa độ GPS chính xác và tính khoảng cách tới phòng học.
**Step 4:** Xây dựng `BiometricService` hỗ trợ xác thực vân tay / Face Unlock.
**Step 5:** Xây dựng `AuthProvider` quản lý state đăng nhập, vai trò hiện tại và token.
**Step 6:** Commit:
```bash
git add lib/models/ lib/services/ lib/providers/
git commit -m "feat(flutter): create data models, core services, and auth provider"
```

---

### Task 7: Xây dựng Giao diện Xác thực (Đăng Ký, Đăng Nhập, OTP & Face Register)
**Files:**
- Create: `lib/screens/auth/login_screen.dart`
- Create: `lib/screens/auth/register_screen.dart`
- Create: `lib/screens/auth/otp_verify_screen.dart`
- Create: `lib/screens/auth/face_register_screen.dart`
- Modify: `lib/main.dart`

**Step 1:** Màn hình Đăng nhập (Email/Username + Password, nút đăng nhập nhanh bằng Vân tay/Biometrics).
**Step 2:** Màn hình Đăng ký tài khoản (chọn vai trò Giảng viên hoặc Sinh viên, gửi mã OTP).
**Step 3:** Màn hình Nhập mã OTP 6 số (giao diện PIN code đẹp mắt kèm đếm ngược 60s).
**Step 4:** Màn hình Đăng ký Khuôn mặt mẫu (chụp ảnh selfie mẫu để dùng đối chiếu điểm danh).
**Step 5:** Điều hướng thông minh theo phân quyền (Role Router) trong `main.dart`.
**Step 6:** Commit:
```bash
git add lib/screens/auth/ lib/main.dart
git commit -m "feat(flutter): build login, registration, OTP 2FA, and face registration screens"
```

---

### Task 8: Xây dựng Giao diện & Tính năng Giảng Viên (Staff/Lecturer Portal)
**Files:**
- Create: `lib/screens/lecturer/lecturer_dashboard.dart`
- Create: `lib/screens/lecturer/create_session_screen.dart`
- Create: `lib/screens/lecturer/dynamic_qr_screen.dart`
- Create: `lib/screens/lecturer/live_attendance_monitor_screen.dart`
- Create: `lib/screens/lecturer/absence_review_screen.dart`

**Step 1:** `lecturer_dashboard.dart`: Danh sách lớp học phần đang phụ trách, thống kê nhanh số buổi đã dạy.
**Step 2:** `create_session_screen.dart`: Tạo phiên điểm danh mới (chọn lớp, nhập tiêu đề, phòng học, thời gian mở).
**Step 3:** `dynamic_qr_screen.dart`: **Tính năng nâng cao (e)** - Màn hình máy chiếu hiển thị **Mã QR động tự động xoay sau mỗi 5s** với thanh tiến trình tròn đếm ngược.
**Step 4:** `live_attendance_monitor_screen.dart`: **Tính năng độc quyền** - Màn hình Radar theo dõi sinh viên vừa check-in thời gian thực, hiển thị khoảng cách GPS thực tế và ảnh selfie của sinh viên.
**Step 5:** `absence_review_screen.dart`: Duyệt đơn xin phép nghỉ kèm xem ảnh minh chứng bệnh án/lý do.
**Step 6:** Commit:
```bash
git add lib/screens/lecturer/
git commit -m "feat(flutter): implement lecturer portal with dynamic rotating QR and live monitor"
```

---

### Task 9: Xây dựng Giao diện & Tính năng Sinh Viên (Student Portal)
**Files:**
- Create: `lib/screens/student/student_dashboard.dart`
- Create: `lib/screens/student/check_in_flow_screen.dart`
- Create: `lib/screens/student/attendance_history_screen.dart`
- Create: `lib/screens/student/submit_absence_screen.dart`

**Step 1:** `student_dashboard.dart`: Lịch học trong ngày, thẻ tỷ lệ chuyên cần (%) có biểu đồ trực quan, nút "⚡ ĐIỂM DANH NGAY".
**Step 2:** `check_in_flow_screen.dart`: **Quy trình 3 lớp AI Smart Shield**:
  - *Lớp 1 (QR Scanner):* Camera quét mã QR động.
  - *Lớp 2 (GPS Geofence):* Kiểm tra tọa độ GPS, hiển thị khoảng cách đến lớp (ví dụ: "Cách phòng học 12m - Hợp lệ").
  - *Lớp 3 (Selfie Match):* Chụp selfie xác thực khuôn mặt sinh viên.
**Step 3:** `attendance_history_screen.dart`: Lịch sử điểm danh chi tiết từng buổi học (Có mặt, Đi trễ, Vắng).
**Step 4:** `submit_absence_screen.dart`: Nộp đơn xin vắng / xin điểm danh bù kèm tải ảnh minh chứng.
**Step 5:** Commit:
```bash
git add lib/screens/student/
git commit -m "feat(flutter): implement student portal with 3-shield check-in flow and history"
```

---

### Task 10: Xây dựng Giao diện Quản Trị Viên (Admin Portal)
**Files:**
- Create: `lib/screens/admin/admin_dashboard.dart`
- Create: `lib/screens/admin/user_management_screen.dart`
- Create: `lib/screens/admin/class_management_screen.dart`
- Create: `lib/screens/admin/system_config_screen.dart`

**Step 1:** `admin_dashboard.dart`: Thống kê tổng số sinh viên, giảng viên, lớp học và phiên điểm danh trong toàn trường.
**Step 2:** `user_management_screen.dart`: CRUD người dùng (thêm/sửa/khóa tài khoản, phân quyền Giảng viên/Sinh viên).
**Step 3:** `class_management_screen.dart`: CRUD lớp học, phân công giảng viên dạy, thêm sinh viên vào lớp.
**Step 4:** `system_config_screen.dart`: Cấu hình tọa độ GPS khuôn viên trường/phòng học và bán kính cho phép.
**Step 5:** Commit:
```bash
git add lib/screens/admin/
git commit -m "feat(flutter): implement admin portal for user, class, and system management"
```

---

### Task 11: Kiểm thử Toàn diện & Hướng dẫn Đẩy lên GitHub Remote
**Files:**
- Modify: `docs/plans/task.md`
- Test: Kiểm tra chạy đồng thời `buinguyenchihau_api` và Flutter App.

**Step 1:** Khởi động WebAPI và kiểm tra API hoạt động: `npm test` hoặc curl test.
**Step 2:** Chạy Flutter analyze: `flutter analyze`.
**Step 3:** Thực hiện push lên repository GitHub của bạn (`2005buinguyenchihau-alt`):
```bash
git push -u origin main
```
**Step 4:** Cập nhật trạng thái hoàn thành trong `docs/plans/task.md`.
