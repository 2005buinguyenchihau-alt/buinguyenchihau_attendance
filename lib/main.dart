import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/lecturer/lecturer_dashboard.dart';
import 'screens/student/student_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const PrimeAttendanceApp(),
    ),
  );
}

class PrimeAttendanceApp extends StatelessWidget {
  const PrimeAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRIME Attendance - Bùi Nguyễn Chí Hậu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleRouter(),
    );
  }
}

/// Điều hướng tự động dựa trên quyền (Role Router)
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    final user = auth.user;

    if (user?.isAdmin == true) {
      return const AdminDashboard();
    } else if (user?.isLecturer == true) {
      return const LecturerDashboard();
    } else {
      return const StudentDashboard();
    }
  }
}
