import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'temperature_screen.dart';
import 'unit_screen.dart';
import 'youtube_screen.dart';
import 'alarm_screen.dart';
import 'timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeechInitialized = false;
  bool _commandProcessed = false;
  String _voiceStatus = 'Chạm vào micro để ra lệnh (vd: "đặt báo thức 7 giờ")';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      _commandProcessed = false;

      // 1. Chỉ khởi tạo một lần duy nhất để tránh load lâu
      if (!_isSpeechInitialized) {
        if (mounted) setState(() => _voiceStatus = 'Đang kết nối Micro...');
        _isSpeechInitialized = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              if (mounted) setState(() => _isListening = false);
            }
          },
          onError: (errorNotification) {
            if (mounted) {
              setState(() {
                _isListening = false;
                _voiceStatus = 'Lỗi nhận diện: ${errorNotification.errorMsg}';
              });
            }
          },
        );
      }

      if (_isSpeechInitialized) {
        if (mounted) {
          setState(() {
            _isListening = true;
            _voiceStatus = 'Đang nghe... (Nói lệnh của bạn)';
          });
        }
        
        _speech.listen(
          localeId: 'vi_VN',
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: true,
            listenMode: stt.ListenMode.confirmation, // Giúp nhận diện lệnh ngắn nhanh hơn
          ),
          onResult: (val) {
            if (mounted) {
              setState(() {
                _voiceStatus = 'Đã nghe: "${val.recognizedWords}"';
              });

              // 2. Tối ưu: Không đợi hasConfidenceRating mà dùng Debounce (chờ 1.2s không nói thêm)
              // hoặc xử lý ngay nếu là kết quả cuối cùng (finalResult)
              _debounceTimer?.cancel();

              if (val.finalResult) {
                _processCommand(val.recognizedWords.toLowerCase());
              } else {
                _debounceTimer = Timer(const Duration(milliseconds: 1200), () {
                  if (_isListening) {
                    _processCommand(val.recognizedWords.toLowerCase());
                  }
                });
              }
            }
          },
        );
      } else {
        if (mounted) {
          setState(() {
            _isListening = false;
            _voiceStatus = 'Không thể sử dụng Microphone. Vui lòng cấp quyền.';
          });
        }
      }
    } else {
      _debounceTimer?.cancel();
      _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _processCommand(String command) {
    if (_commandProcessed) return;

    Widget? targetScreen;

    if (command.contains('báo thức') || command.contains('alarm') || command.contains('đặt giờ')) {
      TimeOfDay? time;
      final timeRegex1 = RegExp(r'(\d{1,2})\s*(?:giờ|h)\s*(\d{1,2})?');
      final timeRegex2 = RegExp(r'(\d{1,2}):(\d{2})');

      final match2 = timeRegex2.firstMatch(command);
      final match1 = timeRegex1.firstMatch(command);

      if (match2 != null) {
        final h = int.tryParse(match2.group(1) ?? '');
        final m = int.tryParse(match2.group(2) ?? '');
        if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
          time = TimeOfDay(hour: h, minute: m);
        }
      } else if (match1 != null) {
        final h = int.tryParse(match1.group(1) ?? '');
        final m = int.tryParse(match1.group(2) ?? '') ?? 0;
        if (h != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
          time = TimeOfDay(hour: h, minute: m);
        }
      }

      targetScreen = AlarmScreen(
        initialTime: time,
        initialLabel: 'Báo thức (Giọng nói)',
      );
    } else if (command.contains('đếm ngược') || command.contains('bấm giờ') || command.contains('timer') || command.contains('hẹn giờ')) {
      int? seconds;
      final minMatch = RegExp(r'(\d+)\s*phút').firstMatch(command);
      final secMatch = RegExp(r'(\d+)\s*giây').firstMatch(command);

      int totalSecs = 0;
      if (minMatch != null) {
        totalSecs += (int.tryParse(minMatch.group(1) ?? '0') ?? 0) * 60;
      }
      if (secMatch != null) {
        totalSecs += int.tryParse(secMatch.group(1) ?? '0') ?? 0;
      }

      if (totalSecs > 0) {
        seconds = totalSecs;
      }

      targetScreen = TimerScreen(
        initialTab: (command.contains('đếm ngược') || totalSecs > 0) ? 1 : 0,
        initialCountdownSeconds: seconds,
      );
    } else if (command.contains('nhiệt độ')) {
      targetScreen = const TemperatureScreen();
    } else if (command.contains('chuyển đổi') || command.contains('đơn vị')) {
      targetScreen = const UnitScreen();
    } else if (command.contains('youtube') || command.contains('video')) {
      targetScreen = const YoutubeScreen();
    }

    if (targetScreen != null) {
      _commandProcessed = true;
      _debounceTimer?.cancel();
      _speech.stop();
      if (mounted) setState(() => _isListening = false);
      Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilities = [
      _UtilityItem('Nhiệt độ', 'Chuyển đổi C, F, K', Icons.thermostat, const TemperatureScreen()),
      _UtilityItem('Đơn vị', 'Đổi độ dài mm, cm, m, km...', Icons.straighten, const UnitScreen()),
      _UtilityItem('YouTube', 'Phát video từ URL', Icons.play_circle_filled, const YoutubeScreen()),
      _UtilityItem('Báo thức', 'Hẹn giờ báo thức có âm thanh', Icons.alarm, const AlarmScreen()),
      _UtilityItem('Bấm giờ', 'Đồng hồ bấm giờ & Đếm ngược', Icons.timer, const TimerScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đa Tiện Ích', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isListening ? Colors.orange.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isListening ? Colors.orange : Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(Icons.record_voice_over, color: _isListening ? Colors.orange : Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _voiceStatus,
                      style: TextStyle(color: _isListening ? Colors.orange.shade800 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: utilities.length,
                itemBuilder: (context, index) {
                  final item = utilities[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => item.screen));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.icon, size: 48, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 12),
                            Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                item.description,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _listen,
        icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : null),
        label: Text(_isListening ? 'Đang nghe...' : 'Giọng nói'),
        backgroundColor: _isListening ? Colors.orange.shade100 : null,
      ),
    );
  }
}

class _UtilityItem {
  final String title;
  final String description;
  final IconData icon;
  final Widget screen;

  _UtilityItem(this.title, this.description, this.icon, this.screen);
}
