# Thiết kế Ứng dụng Đa tiện ích (Multi-Utility App)

## 1. Tổng quan & Kiến trúc
- **Nền tảng:** Flutter (Material 3).
- **Quản lý trạng thái:** `setState` và `ValueNotifier` kết hợp `IndexedStack` để bảo toàn trạng thái tab.
- **Thư mục dự án:**
  - `lib/screens/`: Chứa các UI chia theo màn hình.
  - `lib/services/`: Chứa các service dùng chung (Voice, Báo thức).
  - `lib/widgets/`: Các thành phần tái sử dụng.
- **Theme:** Sử dụng màu nhấn là Cam ấm (Warm Orange). Ngôn ngữ chính (text, cảnh báo, lỗi) 100% tiếng Việt.

## 2. Navigation & Cấu trúc Tab
Dùng `NavigationBar` với 4 mục:
1. **Trang chủ (Dashboard):** Hiển thị Header, Voice Control FAB, Lưới 5 tiện ích.
2. **Dịch MLKit:** Công cụ nhận diện chữ qua ảnh và dịch đa ngôn ngữ.
3. **Cá nhân:** Trang profile mẫu (có gọi điện, mở YouTube qua `url_launcher`).
4. **Thành viên:** Trang giới thiệu qua `PageView` với dữ liệu thành viên mẫu.

## 3. Chi tiết 5 Tiện ích (Dashboard)
1. **Chuyển đổi nhiệt độ:** Hỗ trợ C, F, K. Có validation input và Kelvin < 0.
2. **Chuyển đổi đơn vị:** Đổi độ dài (mm, cm, m, km, inch, feet). Validation âm/trống.
3. **YouTube Player:** Nhận diện và parse ID từ nhiều định dạng URL. Sử dụng `youtube_player_iframe`. Xử lý dispose controller an toàn.
4. **Báo thức:** Sử dụng `flutter_local_notifications` để lên lịch (đáp ứng đúng requirement chạy ngầm, không dùng Timer). Hỗ trợ đặt nhãn, list báo thức, phát âm.
5. **Bấm giờ / Đếm ngược:** Sử dụng `Timer` nội bộ, có tab riêng. Đếm ngược xong phát chuông qua `audioplayers`. Dispose Timer an toàn.

## 4. Các Service Dùng Chung
- **Voice Control Service (`speech_to_text`):** Nhận diện lệnh tiếng Việt như "đặt báo thức", "chạy đếm ngược", "mở youtube",... Phân tích chuỗi số/thời gian.
- **ML Kit OCR & Translation:** `google_mlkit_text_recognition`, `google_mlkit_translation`, kết hợp `image_picker`. Cần check & download model, hiển thị loading state rõ ràng.
- Xử lý quyền: `permission_handler` (nếu cần thiết cho camera, mic) hoặc phụ thuộc cấu hình plugin.

## 5. Kiểm thử & Cấu hình
- Config Android/iOS permission cho mic, internet, camera, notification.
- Update `pubspec.yaml` với tất cả dependency cần thiết.
- Test: Cập nhật unit test và widget test ở mức cơ bản cho tính năng chính (converter, parsing lệnh thoại nếu có).
