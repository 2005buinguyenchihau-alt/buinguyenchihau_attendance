import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  final bool isRegister;
  final String? otpPreview;

  const OtpVerifyScreen({
    super.key,
    required this.email,
    required this.isRegister,
    this.otpPreview,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Để trống ô nhập mã để người dùng mở Gmail và nhập mã xác thực
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số mã OTP')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    bool success = false;

    if (widget.isRegister) {
      success = await auth.verifyRegisterOtp(code);
    } else {
      success = await auth.verifyLoginOtp(code);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isRegister ? 'Kích hoạt tài khoản thành công!' : 'Đăng nhập thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
      // Quay về main screen (AuthProvider isAuthenticated sẽ tự động chuyển trang)
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác Thực Mã OTP 2FA'),
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
                  child: const Icon(Icons.mark_email_read_rounded, size: 40, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nhập Mã OTP Xác Thực',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã OTP 6 số đã được gửi tới địa chỉ:\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Banner trợ giúp cho thuyết trình / demo
              if (widget.otpPreview != null)
                Container(
                  padding: const EdgeInsets.all(14),
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
                              widget.otpPreview!,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _otpController.text = widget.otpPreview!;
                          });
                        },
                        child: const Text('Điền mã'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // OTP Input field
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 12),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: auth.isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primary,
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Xác Thực & Hoàn Tất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
