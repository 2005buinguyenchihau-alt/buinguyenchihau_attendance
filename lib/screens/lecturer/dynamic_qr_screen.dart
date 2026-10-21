import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import 'live_monitor_screen.dart';

class DynamicQrScreen extends StatefulWidget {
  final int sessionId;
  final String sessionName;
  final String roomName;
  final double allowedRadius;

  const DynamicQrScreen({
    super.key,
    required this.sessionId,
    required this.sessionName,
    required this.roomName,
    this.allowedRadius = 50.0,
  });

  @override
  State<DynamicQrScreen> createState() => _DynamicQrScreenState();
}

class _DynamicQrScreenState extends State<DynamicQrScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  String? _qrToken;
  Timer? _refreshTimer;
  Timer? _tickTimer;
  int _secondsLeft = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQrToken();
    // Đếm ngược 5 giây một lần
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 5;
          _fetchQrToken();
        }
      });
    });
  }

  Future<void> _fetchQrToken() async {
    try {
      final res = await _api.getCurrentQr(widget.sessionId);
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _qrToken = res['data']['token'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dynamic QR: $e');
    }
  }

  Future<void> _handleCloseSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kết thúc ca điểm danh?'),
        content: const Text('Sau khi đóng, sinh viên sẽ không thể quét mã để điểm danh nữa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đóng Ca'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _api.closeSession(widget.sessionId);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã QR Điểm Danh Động (TOTP)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar_rounded, color: AppTheme.secondary),
            tooltip: 'Live Radar Check-in',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveMonitorScreen(
                    sessionId: widget.sessionId,
                    sessionName: widget.sessionName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thông tin phòng & Ca
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      widget.sessionName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.meeting_room_rounded, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(widget.roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 16),
                        const Icon(Icons.radar_rounded, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('Bán kính: ${widget.allowedRadius.toInt()}m', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // dynamic QR Display with Countdown
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Badge bảo vệ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 16, color: AppTheme.secondary),
                            SizedBox(width: 6),
                            Text(
                              'AI TRIPLE-SHIELD ANTI-PROXY',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // QR Code Container
                      _isLoading || _qrToken == null
                          ? const SizedBox(
                              width: 250,
                              height: 250,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200, width: 2),
                              ),
                              child: QrImageView(
                                data: _qrToken!,
                                version: QrVersions.auto,
                                size: 240.0,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: AppTheme.primary,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),

                      // Countdown progress indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _secondsLeft / 5.0,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _secondsLeft <= 2 ? AppTheme.accent : AppTheme.secondary,
                                ),
                              ),
                              Text(
                                '$_secondsLeft s',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _secondsLeft <= 2 ? AppTheme.accent : AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tự động đổi mã sau 5s',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Ngăn chặn chụp màn hình gửi Zalo',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Button chuyển qua Live Radar Monitor
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveMonitorScreen(
                        sessionId: widget.sessionId,
                        sessionName: widget.sessionName,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.radar_rounded),
                label: const Text('Xem Radar Sinh Viên Check-in Trực Tiếp', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _handleCloseSession,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Đóng Ca Điểm Danh Này'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
