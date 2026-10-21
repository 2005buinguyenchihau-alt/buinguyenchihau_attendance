import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Step 1: Nhập email | Step 2: Nhập OTP & Đặt mật khẩu mới
  int _currentStep = 1;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  String? _otpPreview;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Bước 1: Gửi yêu cầu OTP về Gmail
  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ email hợp lệ')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final result = await auth.forgotPassword(email);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _currentStep = 2;
        _otpPreview = result['otpPreview'];
        _otpController.clear(); // Để trống để người dùng mở Gmail lấy mã và tự gõ vào
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Mã OTP đã được gửi về Gmail!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gửi yêu cầu thất bại'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  // Bước 2: Đặt lại mật khẩu mới với OTP
  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số mã OTP')),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu mới phải có ít nhất 6 ký tự')),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final result = await auth.resetPassword(
      email: email,
      otpCode: otp,
      newPassword: newPass,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Đặt lại mật khẩu thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context); // Quay về trang đăng nhập
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Đặt lại mật khẩu thất bại'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên Mật Khẩu'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _currentStep == 1 ? Icons.mark_email_unread_rounded : Icons.lock_reset_rounded,
                    size: 42,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _currentStep == 1 ? 'Khôi Phục Mật Khẩu' : 'Đặt Lại Mật Khẩu Mới',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentStep == 1
                    ? 'Nhập địa chỉ email tài khoản đã đăng ký.\nMã OTP xác thực sẽ được gửi trực tiếp đến Gmail của bạn.'
                    : 'Nhập mã OTP vừa nhận trong Gmail và mật khẩu mới cho tài khoản:\n${_emailController.text}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // ================= STEP 1: NHẬP EMAIL =================
              if (_currentStep == 1) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ Email',
                    hintText: 'ví dụ: sinhvien@prime.edu.vn',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleSendOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send_rounded, size: 20),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Gửi Mã Xác Nhận Về Gmail',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ],

              // ================= STEP 2: NHẬP OTP & ĐẶT MẬT KHẨU MỚI =================
              if (_currentStep == 2) ...[
                // Banner trợ giúp cho demo nếu có otpPreview
                if (_otpPreview != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.key_rounded, color: Colors.amber),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MÃ OTP DEMO HỆ THỐNG:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown),
                              ),
                              Text(
                                _otpPreview!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _otpController.text = _otpPreview!;
                            });
                          },
                          child: const Text('Điền mã'),
                        ),
                      ],
                    ),
                  ),

                // Ô nhập mã OTP 6 số
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 10),
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'Mã xác nhận OTP (6 số)',
                    hintText: '------',
                    hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 10),
                    prefixIcon: const Icon(Icons.lock_clock_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Ô nhập Mật khẩu mới
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPass,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    hintText: 'Ít nhất 6 ký tự',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPass ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ô nhập Xác nhận mật khẩu mới
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPass,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 20),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Lưu Mật Khẩu Mới & Đăng Nhập',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),

                // Gửi lại mã OTP
                TextButton.icon(
                  onPressed: auth.isLoading ? null : _handleSendOtp,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Gửi lại mã OTP về Gmail'),
                ),
              ],

              const SizedBox(height: 16),

              // Nút quay lại đăng nhập
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    if (_currentStep == 2) {
                      setState(() => _currentStep = 1);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(_currentStep == 2 ? 'Quay lại bước nhập email' : 'Quay lại trang Đăng nhập'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
