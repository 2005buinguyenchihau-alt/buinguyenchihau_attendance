import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Đường dẫn Server Vercel Cloud (chạy 24/7 trực tiếp trên máy chủ đám mây Vercel):
  // Hoặc dùng Cloudflare Tunnel: 'https://memory-only-boolean-communist.trycloudflare.com'
  static String? publicUrl = 'https://temporary-quick-indigo-83rinlq.vercel.app';

  // IP của máy tính chạy server Backend (cùng mạng WiFi với điện thoại thật)
  // Nếu chạy trên máy ảo Android Emulator thì đổi thành '10.0.2.2'
  static String customHost = '192.168.1.12';

  static String get baseUrl {
    if (publicUrl != null && publicUrl!.isNotEmpty) {
      return '$publicUrl/api';
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    return 'http://$customHost:5000/api';
  }

  // Endpoints
  static String get register => '$baseUrl/auth/register';
  static String get verifyRegisterOtp => '$baseUrl/auth/verify-register-otp';
  static String get login => '$baseUrl/auth/login';
  static String get verifyLoginOtp => '$baseUrl/auth/verify-login-otp';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get resetPassword => '$baseUrl/auth/reset-password';
  static String get profile => '$baseUrl/auth/profile';
  static String get faceRegister => '$baseUrl/auth/face-register';
  static String get faceLogin => '$baseUrl/auth/face-login';

  static String get classes => '$baseUrl/classes';
  static String get studentClasses => '$baseUrl/student/classes';
  static String get lecturerClasses => '$baseUrl/lecturer/classes';

  static String get startSession => '$baseUrl/attendance/session/start';
  static String currentQr(int sessionId) => '$baseUrl/attendance/session/$sessionId/current-qr';
  static String closeSession(int sessionId) => '$baseUrl/attendance/session/$sessionId/close';
  static String liveRecords(int sessionId) => '$baseUrl/attendance/session/$sessionId/live-records';

  static String get checkIn => '$baseUrl/attendance/check-in';
  static String get studentHistory => '$baseUrl/student/attendance-history';
  static String get studentDashboard => '$baseUrl/student/dashboard-stats';

  static String get requests => '$baseUrl/requests';
  static String get studentRequests => '$baseUrl/student/requests';
  static String get lecturerRequests => '$baseUrl/lecturer/requests';
  static String reviewRequest(int id) => '$baseUrl/requests/$id/review';

  static String get adminStats => '$baseUrl/admin/stats';
  static String get adminUsers => '$baseUrl/admin/users';
}
