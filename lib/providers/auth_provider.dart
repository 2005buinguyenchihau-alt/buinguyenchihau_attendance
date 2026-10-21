import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  // Trạng thái chờ xác thực OTP
  bool _waitingForOtp = false;
  String? _pendingEmail;
  String? _otpPreview;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null && _token != null;
  bool get waitingForOtp => _waitingForOtp;
  String? get pendingEmail => _pendingEmail;
  String? get otpPreview => _otpPreview;

  bool get isAdmin => _user?.isAdmin == true;
  bool get isLecturer => _user?.isLecturer == true;
  bool get isStudent => _user?.isStudent == true;

  // 1. Đăng ký bước 1: gửi thông tin và nhận OTP
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String code,
    required String role,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final res = await _api.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        code: code,
        role: role,
      );

      if (res['success'] == true) {
        _waitingForOtp = true;
        _pendingEmail = email;
        _otpPreview = res['data']?['otpPreview']?.toString();
        _setLoading(false);
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Đăng ký thất bại';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối máy chủ: $e';
      _setLoading(false);
      return false;
    }
  }

  // 2. Kích hoạt OTP đăng ký
  Future<bool> verifyRegisterOtp(String otpCode) async {
    if (_pendingEmail == null) return false;
    _setLoading(true);
    _errorMessage = null;

    try {
      final res = await _api.verifyRegisterOtp(email: _pendingEmail!, otpCode: otpCode);
      if (res['success'] == true) {
        _user = _api.currentUser;
        _token = _api.token;
        _waitingForOtp = false;
        _pendingEmail = null;
        _otpPreview = null;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Xác thực OTP thất bại';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: $e';
      _setLoading(false);
      return false;
    }
  }

  // 3. Đăng nhập bước 1: Username/Password -> Yêu cầu OTP 2FA
  Future<bool> login(String usernameOrEmail, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final res = await _api.login(usernameOrEmail: usernameOrEmail, password: password);
      if (res['success'] == true) {
        _waitingForOtp = true;
        _pendingEmail = res['data']?['email'];
        _otpPreview = res['data']?['otpPreview']?.toString();
        _setLoading(false);
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Đăng nhập không thành công';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: $e';
      _setLoading(false);
      return false;
    }
  }

  // 4. Xác thực OTP đăng nhập bước 2
  Future<bool> verifyLoginOtp(String otpCode) async {
    if (_pendingEmail == null) return false;
    _setLoading(true);
    _errorMessage = null;

    try {
      final res = await _api.verifyLoginOtp(email: _pendingEmail!, otpCode: otpCode);
      if (res['success'] == true) {
        _user = _api.currentUser;
        _token = _api.token;
        _waitingForOtp = false;
        _pendingEmail = null;
        _otpPreview = null;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Mã OTP không đúng hoặc hết hạn';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: $e';
      _setLoading(false);
      return false;
    }
  }

  // Đăng xuất
  void logout() {
    _api.clearSession();
    _user = null;
    _token = null;
    _waitingForOtp = false;
    _pendingEmail = null;
    _otpPreview = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
