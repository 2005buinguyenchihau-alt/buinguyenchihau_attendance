import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/class_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'check_in_screen.dart';
import 'history_screen.dart';
import 'location_share_dialog.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final ApiService _api = ApiService();
  List<CourseClassModel> _classes = [];
  Map<String, dynamic>? _dashboardStats;
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
      final stats = await _api.getStudentDashboard();
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _dashboardStats = stats['data'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSubmitAbsenceDialog() async {
    if (_classes.isEmpty) return;
    int selectedClassId = _classes.first.id;
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Nộp Đơn Xin Phép Vắng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedClassId,
                decoration: const InputDecoration(labelText: 'Chọn môn học'),
                items: _classes
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.className, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedClassId = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Lý do xin phép vắng',
                  hintText: 'VD: Bị ốm, tham gia kỳ thi chứng chỉ...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gửi Đơn'),
            ),
          ],
        ),
      ),
    );

    if (result == true && reasonController.text.isNotEmpty) {
      final res = await _api.submitAbsenceRequest(
        classId: selectedClassId,
        reason: reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Đã gửi đơn xin nghỉ thành công!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final activeSessions = _dashboardStats?['activeSessions'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cổng Sinh Viên PRIME'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Lịch sử điểm danh',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            tooltip: 'Đăng xuất',
            onPressed: () => auth.logout(),
          ),
        ],
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
                    // Card Thông Tin Sinh Viên
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppTheme.shieldGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: const Icon(Icons.school, size: 36, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sinh viên:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(
                                  user?.fullName ?? 'Bùi Nguyễn Chí Hậu',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'MSSV: ${user?.code ?? "2005BUI01"} • PRIME Team',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Action: "ĐIỂM DANH NGAY" Lớn
                    InkWell(
                      onTap: () async {
                        final done = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => const CheckInScreen()),
                        );
                        if (done == true) _loadData();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 44, color: Colors.white),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⚡ ĐIỂM DANH NGAY',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Quét QR 5s + Định vị GPS + Face Match',
                                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Utility: "Chia sẻ vị trí GPS" & "Gửi đơn nghỉ" (Chức năng Thuyết trình 5.b)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              LocationShareDialog.show(
                                context,
                                studentName: user?.fullName ?? 'Sinh viên Hậu',
                                studentCode: user?.code ?? '2005BUI01',
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.25)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share_location_rounded, color: AppTheme.secondary, size: 20),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Chia Sẻ Vị Trí GPS',
                                      style: TextStyle(
                                        color: AppTheme.secondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _showSubmitAbsenceDialog,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.note_alt_outlined, color: AppTheme.primary, size: 20),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Đơn Xin Nghỉ',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Active Sessions Banner (Nếu có ca học đang mở điểm danh)
                    if (activeSessions.isNotEmpty) ...[
                      const Text(
                        'Ca Học Đang Mở Điểm Danh',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      ...activeSessions.map((s) {
                        final bool hasAttended = s['has_attended'] > 0;
                        return Card(
                          color: hasAttended ? Colors.green.shade50 : Colors.amber.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: hasAttended ? Colors.green.shade200 : Colors.amber.shade400),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Icon(
                              hasAttended ? Icons.check_circle : Icons.sensors_rounded,
                              color: hasAttended ? AppTheme.success : AppTheme.accent,
                              size: 32,
                            ),
                            title: Text(
                              s['class_name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${s['session_name']} • ${s['room_name']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: hasAttended
                                ? const Chip(
                                    label: Text('Đã có mặt', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    backgroundColor: AppTheme.success,
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInScreen())),
                                    child: const Text('Quét QR', style: TextStyle(fontSize: 12)),
                                  ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Danh sách Lớp Học Phần Của Sinh Viên
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Môn Học Đã Đăng Ký',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showSubmitAbsenceDialog,
                          icon: const Icon(Icons.note_add_outlined, size: 16),
                          label: const Text('Xin nghỉ phép'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_classes.isEmpty)
                      const Center(child: Text('Bạn chưa tham gia lớp học nào.'))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _classes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = _classes[index];
                          final rate = c.attendanceRate;

                          return Card(
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
                                          color: AppTheme.secondary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          c.classCode,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Chuyên cần: ${rate.toInt()}%',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: rate >= 80 ? AppTheme.success : AppTheme.danger,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    c.className,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'GV: ${c.lecturerName ?? "ThS. Bùi Nguyễn Chí Hậu"} • ${c.roomName}',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: rate / 100.0,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      rate >= 80 ? AppTheme.success : AppTheme.danger,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    minHeight: 6,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
