import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'otp_verify_screen.dart';
import 'forgot_password_screen.dart';
import 'face_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'sinhvien.hau');
  final _passwordController = TextEditingController(text: 'Sv@123456');
  bool _obscurePassword = true;

  void _fillSampleAccount(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đăng nhập và mật khẩu')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(username, password);

    if (!mounted) return;

    if (success && auth.waitingForOtp) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            email: auth.pendingEmail ?? '',
            isRegister: false,
            otpPreview: auth.otpPreview,
          ),
        ),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // App Logo & Header
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: AppTheme.shieldGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'PRIME ATTENDANCE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hệ thống Điểm danh Sinh viên Thông minh\nTác giả: Bùi Nguyễn Chí Hậu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Test Accounts Quick Buttons (Tiện ích cho thuyết trình)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flash_on_rounded, size: 16, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tài khoản mẫu thuyết trình (Bấm để điền nhanh):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.school, size: 14),
                          label: const Text('Sinh viên Hậu', style: TextStyle(fontSize: 12)),
                          onPressed: () => _fillSampleAccount('sinhvien.hau', 'Sv@123456'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.person, size: 14),
                          label: const Text('Giảng viên Hậu', style: TextStyle(fontSize: 12)),
                          onPressed: () => _fillSampleAccount('giangvien.hau', 'Gv@123456'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.admin_panel_settings, size: 14),
                          label: const Text('Admin Hậu', style: TextStyle(fontSize: 12)),
                          onPressed: () => _fillSampleAccount('admin', 'Admin@123'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Username input
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập hoặc Email',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Password input
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Quên mật khẩu link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final enteredUserOrEmail = _usernameController.text.trim();
                    final initialEmail = enteredUserOrEmail.contains('@') ? enteredUserOrEmail : null;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(initialEmail: initialEmail),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button (Step 1 -> Triggers OTP)
              ElevatedButton(
                onPressed: auth.isLoading ? null : _handleLogin,
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
                          Icon(Icons.lock_open_rounded, size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Đăng Nhập (Xác thực OTP)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              // Nút Đăng nhập bằng Khuôn mặt (Chức năng Thuyết trình 5.a)
              OutlinedButton.icon(
                onPressed: () {
                  final entered = _usernameController.text.trim();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FaceLoginScreen(
                        prefilledAccount: entered.isNotEmpty ? entered : null,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  side: const BorderSide(color: AppTheme.secondary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: AppTheme.secondary.withValues(alpha: 0.05),
                ),
                icon: const Icon(Icons.face_retouching_natural_rounded, color: AppTheme.secondary, size: 22),
                label: const Flexible(
                  child: Text(
                    'Đăng Nhập Bằng Khuôn Mặt (Face ID)',
                    style: TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Register Button Link
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Chưa có tài khoản? ', style: TextStyle(color: AppTheme.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text(
                      'Đăng ký ngay',
                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Features overview footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _FeatureBadge(icon: Icons.qr_code_2_rounded, text: 'QR Động 5s'),
                    _FeatureBadge(icon: Icons.location_on_rounded, text: 'GPS Geofence'),
                    _FeatureBadge(icon: Icons.face_retouching_natural_rounded, text: 'Face AI Match'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.secondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      ],
    );
  }
}
