import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import '../models/request_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  UserModel? _currentUser;

  String? get token => _token;
  UserModel? get currentUser => _currentUser;

  void setSession(String token, UserModel user) {
    _token = token;
    _currentUser = user;
  }

  void clearSession() {
    _token = null;
    _currentUser = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // 1. Auth: Đăng ký
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String code,
    required String role,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.register),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'code': code,
        'role': role,
      }),
    );
    return jsonDecode(res.body);
  }

  // 2. Auth: Kích hoạt OTP Đăng ký
  Future<Map<String, dynamic>> verifyRegisterOtp({
    required String email,
    required String otpCode,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.verifyRegisterOtp),
      headers: _headers,
      body: jsonEncode({'email': email, 'otp_code': otpCode}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] != null) {
      _token = data['data']['token'];
      _currentUser = UserModel.fromJson(data['data']['user']);
    }
    return data;
  }

  // 3. Auth: Đăng nhập (Yêu cầu OTP 2FA)
  Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.login),
      headers: _headers,
      body: jsonEncode({'usernameOrEmail': usernameOrEmail, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // 4. Auth: Xác thực OTP Đăng nhập
  Future<Map<String, dynamic>> verifyLoginOtp({
    required String email,
    required String otpCode,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.verifyLoginOtp),
      headers: _headers,
      body: jsonEncode({'email': email, 'otp_code': otpCode}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] != null) {
      _token = data['data']['token'];
      _currentUser = UserModel.fromJson(data['data']['user']);
    }
    return data;
  }

  // 5. Cập nhật khuôn mặt mẫu
  Future<Map<String, dynamic>> registerFace(String faceData, {String? avatar}) async {
    final res = await http.post(
      Uri.parse(ApiConstants.faceRegister),
      headers: _headers,
      body: jsonEncode({'face_data': faceData, 'avatar': avatar}),
    );
    return jsonDecode(res.body);
  }

  // 6. Lớp học: Lấy danh sách lớp
  Future<List<CourseClassModel>> getClasses() async {
    final endpoint = _currentUser?.isLecturer == true
        ? ApiConstants.lecturerClasses
        : _currentUser?.isStudent == true
            ? ApiConstants.studentClasses
            : ApiConstants.classes;

    final res = await http.get(Uri.parse(endpoint), headers: _headers);
    final json = jsonDecode(res.body);
    if (json['success'] == true && json['data'] is List) {
      return (json['data'] as List).map((e) => CourseClassModel.fromJson(e)).toList();
    }
    return [];
  }

  // 7. Tạo lớp mới
  Future<Map<String, dynamic>> createClass({
    required String classCode,
    required String className,
    required String roomName,
    double latitude = 10.8415,
    double longitude = 106.8099,
    double allowedRadius = 50.0,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.classes),
      headers: _headers,
      body: jsonEncode({
        'class_code': classCode,
        'class_name': className,
        'room_name': roomName,
        'latitude': latitude,
        'longitude': longitude,
        'allowed_radius': allowedRadius,
      }),
    );
    return jsonDecode(res.body);
  }

  // 8. Mở Ca Điểm Danh (Giảng viên)
  Future<Map<String, dynamic>> startSession(int classId, String sessionName) async {
    final res = await http.post(
      Uri.parse(ApiConstants.startSession),
      headers: _headers,
      body: jsonEncode({'class_id': classId, 'session_name': sessionName}),
    );
    return jsonDecode(res.body);
  }

  // 9. Lấy Dynamic QR Token 5s
  Future<Map<String, dynamic>> getCurrentQr(int sessionId) async {
    final res = await http.get(Uri.parse(ApiConstants.currentQr(sessionId)), headers: _headers);
    return jsonDecode(res.body);
  }

  // 10. Đóng ca điểm danh
  Future<Map<String, dynamic>> closeSession(int sessionId) async {
    final res = await http.post(Uri.parse(ApiConstants.closeSession(sessionId)), headers: _headers);
    return jsonDecode(res.body);
  }

  // 11. Giảng viên xem Live Records
  Future<List<AttendanceRecordModel>> getLiveRecords(int sessionId) async {
    final res = await http.get(Uri.parse(ApiConstants.liveRecords(sessionId)), headers: _headers);
    final json = jsonDecode(res.body);
    if (json['success'] == true && json['data'] is List) {
      return (json['data'] as List).map((e) => AttendanceRecordModel.fromJson(e)).toList();
    }
    return [];
  }

  // 12. Sinh viên Điểm danh 3 lớp chống gian lận
  Future<Map<String, dynamic>> checkIn({
    required String qrToken,
    double? latitude,
    double? longitude,
    String? faceImage,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.checkIn),
      headers: _headers,
      body: jsonEncode({
        'qr_token': qrToken,
        'latitude': latitude,
        'longitude': longitude,
        'face_image': faceImage,
      }),
    );
    return jsonDecode(res.body);
  }

  // 13. Lịch sử điểm danh của sinh viên
  Future<List<AttendanceRecordModel>> getStudentHistory() async {
    final res = await http.get(Uri.parse(ApiConstants.studentHistory), headers: _headers);
    final json = jsonDecode(res.body);
    if (json['success'] == true && json['data'] is List) {
      return (json['data'] as List).map((e) => AttendanceRecordModel.fromJson(e)).toList();
    }
    return [];
  }

  // 14. Thống kê Dashboard sinh viên
  Future<Map<String, dynamic>> getStudentDashboard() async {
    final res = await http.get(Uri.parse(ApiConstants.studentDashboard), headers: _headers);
    return jsonDecode(res.body);
  }

  // 15. Nộp đơn xin nghỉ phép
  Future<Map<String, dynamic>> submitAbsenceRequest({
    required int classId,
    required String reason,
    String? proofImage,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.requests),
      headers: _headers,
      body: jsonEncode({
        'class_id': classId,
        'reason': reason,
        'proof_image': proofImage,
      }),
    );
    return jsonDecode(res.body);
  }

  // 16. Lấy danh sách đơn xin nghỉ
  Future<List<AbsenceRequestModel>> getRequests() async {
    final endpoint = _currentUser?.isLecturer == true ? ApiConstants.lecturerRequests : ApiConstants.studentRequests;
    final res = await http.get(Uri.parse(endpoint), headers: _headers);
    final json = jsonDecode(res.body);
    if (json['success'] == true && json['data'] is List) {
      return (json['data'] as List).map((e) => AbsenceRequestModel.fromJson(e)).toList();
    }
    return [];
  }

  // 17. Phê duyệt đơn xin nghỉ
  Future<Map<String, dynamic>> reviewRequest(int requestId, String status) async {
    final res = await http.put(
      Uri.parse(ApiConstants.reviewRequest(requestId)),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(res.body);
  }

  // 18. Admin Thống kê & Users
  Future<Map<String, dynamic>> getAdminStats() async {
    final res = await http.get(Uri.parse(ApiConstants.adminStats), headers: _headers);
    return jsonDecode(res.body);
  }

  Future<List<UserModel>> getAdminUsers() async {
    final res = await http.get(Uri.parse(ApiConstants.adminUsers), headers: _headers);
    final json = jsonDecode(res.body);
    if (json['success'] == true && json['data'] is List) {
      return (json['data'] as List).map((e) => UserModel.fromJson(e)).toList();
    }
    return [];
  }
}
