import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  Map<String, dynamic>? _stats;
  List<UserModel> _users = [];
  List<CourseClassModel> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final statsRes = await _api.getAdminStats();
      final usersRes = await _api.getAdminUsers();
      final classesRes = await _api.getClasses();

      if (!mounted) return;
      setState(() {
        _stats = statsRes['data'];
        _users = usersRes;
        _classes = classesRes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateUserDialog() async {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'Prime@123');
    String role = 'student';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Thêm Người Dùng Mới (Admin)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Vai trò'),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                    DropdownMenuItem(value: 'lecturer', child: Text('Giảng viên')),
                    DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => role = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ và tên')),
                const SizedBox(height: 10),
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'MSSV hoặc Mã CB')),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 10),
                TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Tên đăng nhập')),
                const SizedBox(height: 10),
                TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Mật khẩu khởi tạo')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo User')),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final res = await _api.register(
        username: usernameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        fullName: nameCtrl.text.trim(),
        code: codeCtrl.text.trim(),
        role: role,
      );
      if (res['data']?['otpPreview'] != null) {
        // Tự động verify luôn cho Admin
        await _api.verifyRegisterOtp(email: emailCtrl.text.trim(), otpCode: res['data']['otpPreview']);
      }
      _loadAdminData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Quản Trị Hệ Thống (Admin)'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Người dùng'),
            Tab(icon: Icon(Icons.school_rounded), text: 'Lớp học'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            tooltip: 'Đăng xuất',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Thêm Người Dùng'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: TỔNG QUAN HỆ THỐNG
                RefreshIndicator(
                  onRefresh: _loadAdminData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Admin Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF334155)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.admin_panel_settings, size: 32, color: Colors.amber),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Quản trị viên tối cao:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text(
                                      user?.fullName ?? 'Bùi Nguyễn Chí Hậu (Admin)',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text('PRIME Multi-Role System', style: TextStyle(color: Colors.amber, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Thống kê Metrics Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            _AdminMetricCard(
                              title: 'Tổng Sinh Viên',
                              value: '${_stats?['totalStudents'] ?? 0}',
                              icon: Icons.school_rounded,
                              color: AppTheme.primary,
                            ),
                            _AdminMetricCard(
                              title: 'Tổng Giảng Viên',
                              value: '${_stats?['totalLecturers'] ?? 0}',
                              icon: Icons.badge_rounded,
                              color: AppTheme.secondary,
                            ),
                            _AdminMetricCard(
                              title: 'Lớp Học Phần',
                              value: '${_stats?['totalClasses'] ?? 0}',
                              icon: Icons.class_rounded,
                              color: AppTheme.warning,
                            ),
                            _AdminMetricCard(
                              title: 'Lượt Điểm Danh',
                              value: '${_stats?['totalAttendances'] ?? 0}',
                              icon: Icons.how_to_reg_rounded,
                              color: AppTheme.success,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // TAB 2: QUẢN LÝ NGƯỜI DÙNG
                RefreshIndicator(
                  onRefresh: _loadAdminData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final u = _users[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: u.isAdmin
                                ? Colors.amber.shade100
                                : u.isLecturer
                                    ? AppTheme.primary.withValues(alpha: 0.1)
                                    : AppTheme.secondary.withValues(alpha: 0.1),
                            child: Icon(
                              u.isAdmin
                                  ? Icons.admin_panel_settings
                                  : u.isLecturer
                                      ? Icons.person
                                      : Icons.school,
                              color: u.isAdmin ? Colors.amber.shade800 : AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${u.roleDisplayName} • ${u.email}\nMã: ${u.code}'),
                          trailing: Chip(
                            label: Text(u.role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // TAB 3: QUẢN LÝ LỚP HỌC
                RefreshIndicator(
                  onRefresh: _loadAdminData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _classes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = _classes[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            child: Text(c.classCode.substring(0, c.classCode.length > 3 ? 3 : c.classCode.length), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ),
                          title: Text(c.className, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('GV: ${c.lecturerName ?? "ThS. Bùi Nguyễn Chí Hậu"}\nPhòng: ${c.roomName} (Bán kính ${c.allowedRadius.toInt()}m)'),
                          trailing: Text('${c.studentCount ?? 0} SV', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminMetricCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 22),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
