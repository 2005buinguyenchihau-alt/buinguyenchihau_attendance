import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/app_theme.dart';
import '../../services/location_service.dart';

class LocationShareDialog extends StatefulWidget {
  final String studentName;
  final String studentCode;

  const LocationShareDialog({
    super.key,
    required this.studentName,
    required this.studentCode,
  });

  static Future<void> show(BuildContext context, {required String studentName, required String studentCode}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationShareDialog(studentName: studentName, studentCode: studentCode),
    );
  }

  @override
  State<LocationShareDialog> createState() => _LocationShareDialogState();
}

class _LocationShareDialogState extends State<LocationShareDialog> {
  final LocationService _locationService = LocationService();
  Position? _position;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isShared = false;

  // Tọa độ phòng học mẫu PRIME Lab A302
  static const double classLat = 10.8415;
  static const double classLon = 106.8099;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final pos = await _locationService.getCurrentPosition();
    if (!mounted) return;

    if (pos != null) {
      setState(() {
        _position = pos;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể lấy tọa độ GPS. Vui lòng bật vị trí trên điện thoại.';
      });
    }
  }

  void _copyLocationLink() {
    if (_position == null) return;
    final lat = _position!.latitude.toStringAsFixed(6);
    final lon = _position!.longitude.toStringAsFixed(6);
    final link = 'https://www.google.com/maps?q=$lat,$lon';

    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.copy_all_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Đã sao chép link Google Maps tọa độ vào Clipboard!'),
          ],
        ),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _shareToClassRadar() {
    setState(() => _isShared = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.satellite_alt_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Đã đồng bộ vị trí GPS của ${widget.studentName} với radar Giảng viên!'),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double distance = 0;
    bool isInside = false;

    if (_position != null) {
      distance = _locationService.calculateDistance(
        _position!.latitude,
        _position!.longitude,
        classLat,
        classLon,
      );
      isInside = distance <= 50.0;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thanh kéo modal
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_location_rounded, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chia Sẻ Vị Trí GPS Thời Gian Thực',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Chức năng thuyết trình 5.b • Định vị vệ tinh',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nội dung tọa độ
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang kết nối vệ tinh GPS...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.location_off_rounded, color: AppTheme.danger, size: 36),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _fetchLocation, child: const Text('Thử lại')),
                ],
              ),
            )
          else if (_position != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded, size: 18, color: AppTheme.secondary),
                      const SizedBox(width: 8),
                      const Text('Tọa độ hiện tại:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Spacer(),
                      Text(
                        '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.meeting_room_outlined, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      const Text('Phòng học đối chiếu:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      const Spacer(),
                      const Text('Lab A302 (PRIME)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.social_distance_rounded, size: 18, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      const Text('Khoảng cách thực tế:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      const Spacer(),
                      Text(
                        '$distance m',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isInside ? AppTheme.success : AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isInside ? AppTheme.success.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isInside ? Icons.check_circle_rounded : Icons.warning_rounded,
                          size: 14,
                          color: isInside ? AppTheme.success : AppTheme.danger,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isInside ? 'Hợp lệ: Đang ở trong khuôn viên lớp học (<= 50m)' : 'Chưa hợp lệ: Cách phòng học quá 50m',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isInside ? AppTheme.success : AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Nút Chia sẻ vị trí lên radar lớp học
            ElevatedButton.icon(
              onPressed: _isShared ? null : _shareToClassRadar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(_isShared ? Icons.done_all_rounded : Icons.radar_rounded),
              label: Text(
                _isShared ? 'Đã Chia Sẻ Lên Radar Lớp Học' : 'Chia Sẻ Tọa Độ Đến Giảng Viên',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 10),

            // Nút Sao chép link Google Maps
            OutlinedButton.icon(
              onPressed: _copyLocationLink,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: AppTheme.secondary),
              ),
              icon: const Icon(Icons.map_rounded, color: AppTheme.secondary, size: 20),
              label: const Text(
                'Sao Chép Link Google Maps Vị Trí',
                style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
