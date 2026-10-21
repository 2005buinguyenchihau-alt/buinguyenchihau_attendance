import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';

class LiveMonitorScreen extends StatefulWidget {
  final int sessionId;
  final String sessionName;

  const LiveMonitorScreen({
    super.key,
    required this.sessionId,
    required this.sessionName,
  });

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen> {
  final ApiService _api = ApiService();
  List<AttendanceRecordModel> _records = [];
  Timer? _pollingTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveRecords();
    // Tự động làm mới danh sách sau mỗi 3 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchLiveRecords(silent: true);
    });
  }

  Future<void> _fetchLiveRecords({bool silent = false}) async {
    try {
      final records = await _api.getLiveRecords(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _records = records;
        if (!silent) _isLoading = false;
      });
    } catch (e) {
      if (!silent) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Radar Điểm Danh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchLiveRecords(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Thống kê Live
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.shieldGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radar_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sessionName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Live 3s thời gian thực',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_records.length} SV',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Live Feed List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _records.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text('Chưa có sinh viên nào điểm danh', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                              const SizedBox(height: 4),
                              const Text('Danh sách sẽ tự động nhảy lên khi sinh viên quét QR', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _records.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final r = _records[index];
                            final time = DateTime.tryParse(r.checkInTime);
                            final timeStr = time != null
                                ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}'
                                : r.checkInTime;

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    (r.studentName != null && r.studentName!.isNotEmpty) ? r.studentName![0] : 'SV',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.studentName ?? 'Sinh viên',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.success.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        timeStr,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text('MSSV: ${r.studentCode ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: AppTheme.secondary),
                                          const SizedBox(width: 2),
                                          Text(
                                            r.distanceMeters != null ? '${r.distanceMeters}m' : 'Trong lớp',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondary),
                                          ),
                                        ],
                                      ),
                                      const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.face_retouching_natural, size: 14, color: AppTheme.primary),
                                          SizedBox(width: 2),
                                          Text('Face Verified', style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
