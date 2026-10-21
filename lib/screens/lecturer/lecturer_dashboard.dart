import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/class_model.dart';
import '../../models/request_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'dynamic_qr_screen.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  final ApiService _api = ApiService();
  List<CourseClassModel> _classes = [];
  List<AbsenceRequestModel> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final classes = await _api.getClasses();
      final requests = await _api.getRequests();
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showStartSessionDialog(CourseClassModel courseClass) async {
    final titleController = TextEditingController(text: 'Buổi học ngày ${DateTime.now().day}/${DateTime.now().month}');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mở Ca Điểm Danh: ${courseClass.classCode}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Môn: ${courseClass.className}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Phòng học: ${courseClass.roomName} (Bán kính: ${courseClass.allowedRadius.toInt()}m)'),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề buổi học',
                hintText: 'VD: Buổi 1: Tổng quan',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Phát Mã QR Động'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final res = await _api.startSession(courseClass.id, titleController.text.trim());
      if (!mounted) return;
      if (res['success'] == true) {
        final session = res['data'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DynamicQrScreen(
              sessionId: session['id'],
              sessionName: session['session_name'],
              roomName: courseClass.roomName,
              allowedRadius: courseClass.allowedRadius,
            ),
          ),
        );
      }
    }
  }

  Future<void> _showCreateClassDialog() async {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final roomController = TextEditingController(text: 'Phòng Lab A302');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo Lớp Học Phần Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Mã lớp (VD: PRIME201)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên môn học'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(labelText: 'Phòng học & Vị trí'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo Lớp')),
        ],
      ),
    );

    if (result == true) {
      await _api.createClass(
        classCode: codeController.text.trim(),
        className: nameController.text.trim(),
        roomName: roomController.text.trim(),
      );
      _loadData();
    }
  }

  Future<void> _reviewRequest(int requestId, String status) async {
    await _api.reviewRequest(requestId, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(status == 'approved' ? 'Đã duyệt đơn!' : 'Đã từ chối đơn!')),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cổng Thông Tin Giảng Viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            tooltip: 'Đăng xuất',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClassDialog,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo Lớp Mới'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Giảng viên Header Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: const Icon(Icons.person, size: 36, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Giảng viên phụ trách:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(
                                  user?.fullName ?? 'ThS. Bùi Nguyễn Chí Hậu',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mã số: ${user?.code ?? "GV200501"} • PRIME Team',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Stats Bar
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            title: 'Lớp Giảng Dạy',
                            value: '${_classes.length}',
                            icon: Icons.class_outlined,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatBox(
                            title: 'Đơn Xin Nghỉ',
                            value: '${_requests.where((r) => r.status == 'pending').length}',
                            icon: Icons.assignment_late_outlined,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Danh sách Lớp Giảng Dạy
                    const Text(
                      'Danh Sách Lớp Học Phần',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    if (_classes.isEmpty)
                      const Center(child: Text('Chưa có lớp nào. Hãy bấm nút Tạo Lớp Mới ở góc dưới.'))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _classes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = _classes[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          c.classCode,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.people_alt_outlined, size: 16, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text('${c.studentCount ?? 0} sinh viên', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(c.className, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(c.roomName, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    onPressed: () => _showStartSessionDialog(c),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.secondary,
                                      minimumSize: const Size(double.infinity, 44),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                                    label: const Text('Mở Ca Điểm Danh & Chiếu QR'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 28),

                    // Đơn xin phép vắng cần duyệt
                    if (_requests.isNotEmpty) ...[
                      const Text(
                        'Đơn Xin Nghỉ Phép Cần Duyệt',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final req = _requests[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${req.studentName} (${req.studentCode})', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(req.statusDisplay, style: TextStyle(color: req.status == 'approved' ? AppTheme.success : AppTheme.warning, fontWeight: FontWeight.w600, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Lớp: ${req.classCode} • Lý do: ${req.reason}', style: const TextStyle(fontSize: 13)),
                                  if (req.status == 'pending') ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(onPressed: () => _reviewRequest(req.id, 'rejected'), child: const Text('Từ chối', style: TextStyle(color: AppTheme.danger))),
                                        const SizedBox(width: 8),
                                        ElevatedButton(onPressed: () => _reviewRequest(req.id, 'approved'), child: const Text('Chấp thuận')),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
