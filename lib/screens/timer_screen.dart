import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class TimerScreen extends StatelessWidget {
  final int initialTab;
  final int? initialCountdownSeconds;

  const TimerScreen({
    super.key,
    this.initialTab = 0,
    this.initialCountdownSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bấm giờ & Đếm ngược'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bấm giờ'),
              Tab(text: 'Đếm ngược'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const StopwatchTab(),
            CountdownTab(initialSeconds: initialCountdownSeconds),
          ],
        ),
      ),
    );
  }
}

class StopwatchTab extends StatefulWidget {
  const StopwatchTab({super.key});

  @override
  State<StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<StopwatchTab> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<String> _laps = [];

  void _start() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (Timer t) {
      if (mounted) setState(() {});
    });
  }

  void _pause() {
    _stopwatch.stop();
    _timer?.cancel();
    if (mounted) setState(() {});
  }

  void _reset() {
    _stopwatch.reset();
    _laps.clear();
    if (mounted) setState(() {});
  }

  void _lap() {
    if (_stopwatch.isRunning) {
      setState(() {
        _laps.insert(0, _formatTime(_stopwatch.elapsedMilliseconds));
      });
    }
  }

  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();

    String mStr = (minutes % 60).toString().padLeft(2, '0');
    String sStr = (seconds % 60).toString().padLeft(2, '0');
    String hStr = (hundreds % 100).toString().padLeft(2, '0');

    return "$mStr:$sStr.$hStr";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 36),
        Text(
          _formatTime(_stopwatch.elapsedMilliseconds),
          style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _stopwatch.isRunning ? _pause : _start,
              icon: Icon(_stopwatch.isRunning ? Icons.pause : Icons.play_arrow),
              label: Text(_stopwatch.isRunning ? 'Tạm dừng' : 'Bắt đầu'),
            ),
            ElevatedButton.icon(
              onPressed: _stopwatch.isRunning ? _lap : _reset,
              icon: Icon(_stopwatch.isRunning ? Icons.flag : Icons.refresh),
              label: Text(_stopwatch.isRunning ? 'Ghi vòng' : 'Đặt lại'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _laps.isEmpty
              ? const Center(
                  child: Text('Chưa có vòng nào được ghi', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  itemCount: _laps.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Vòng ${_laps.length - index}'),
                      trailing: Text(_laps[index], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class CountdownTab extends StatefulWidget {
  final int? initialSeconds;

  const CountdownTab({super.key, this.initialSeconds});

  @override
  State<CountdownTab> createState() => _CountdownTabState();
}

class _CountdownTabState extends State<CountdownTab> {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialSeconds ?? 60;
    _remainingSeconds = _totalSeconds;

    if (widget.initialSeconds != null && widget.initialSeconds! > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _start();
      });
    }
  }

  void _start() {
    if (_remainingSeconds > 0) {
      setState(() => _isRunning = true);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          _playAlarm();
        }
      });
    }
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _playAlarm() async {
    try {
      await _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg'));
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.alarm_on, color: Colors.red),
            SizedBox(width: 8),
            Text('Hết giờ!'),
          ],
        ),
        content: const Text('Thời gian đếm ngược đã kết thúc.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              _audioPlayer.stop();
              Navigator.pop(context);
            },
            child: const Text('Dừng chuông'),
          ),
        ],
      ),
    );
  }

  void _setDuration(int seconds) {
    if (!_isRunning) {
      setState(() {
        _totalSeconds = seconds;
        _remainingSeconds = seconds;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDisplay(int totalSecs) {
    int m = totalSecs ~/ 60;
    int s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 36),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: _totalSeconds == 0 ? 0 : _remainingSeconds / _totalSeconds,
                strokeWidth: 10,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            Text(
              _formatDisplay(_remainingSeconds),
              style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!_isRunning)
          Wrap(
            spacing: 8,
            children: [
              ActionChip(label: const Text('+1 phút'), onPressed: () => _setDuration(_remainingSeconds + 60)),
              ActionChip(label: const Text('+5 phút'), onPressed: () => _setDuration(_remainingSeconds + 300)),
              ActionChip(label: const Text('1 phút'), onPressed: () => _setDuration(60)),
              ActionChip(label: const Text('5 phút'), onPressed: () => _setDuration(300)),
            ],
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _isRunning ? _pause : _start,
              icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
              label: Text(_isRunning ? 'Tạm dừng' : 'Bắt đầu'),
            ),
            ElevatedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Đặt lại'),
            ),
          ],
        )
      ],
    );
  }
}
