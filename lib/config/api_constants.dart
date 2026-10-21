import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Thay đổi IP này nếu chạy trên thiết bị thật kết nối chung mạng WiFi với máy tính
  static String customHost = 'localhost';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 trỏ về localhost máy host của Android Emulator
      // Nếu dùng điện thoại thật, có thể đổi thành IP LAN qua cài đặt
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  // Endpoints
  static String get register => '$baseUrl/auth/register';
  static String get verifyRegisterOtp => '$baseUrl/auth/verify-register-otp';
  static String get login => '$baseUrl/auth/login';
  static String get verifyLoginOtp => '$baseUrl/auth/verify-login-otp';
  static String get profile => '$baseUrl/auth/profile';
  static String get faceRegister => '$baseUrl/auth/face-register';

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
