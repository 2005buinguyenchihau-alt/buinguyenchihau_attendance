import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmScreen extends StatefulWidget {
  final TimeOfDay? initialTime;
  final String? initialLabel;

  const AlarmScreen({
    super.key,
    this.initialTime,
    this.initialLabel,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class AlarmItem {
  final int id;
  final TimeOfDay time;
  final String label;
  bool isEnabled;

  AlarmItem(this.id, this.time, this.label, this.isEnabled);
}

class _AlarmScreenState extends State<AlarmScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final List<AlarmItem> _alarms = [];
  int _nextAlarmId = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTime != null) {
        _addNewAlarmFromVoice(
          widget.initialTime!,
          widget.initialLabel ?? 'Báo thức (Giọng nói)',
        );
      }
    });
  }

  void _addNewAlarmFromVoice(TimeOfDay time, String label) {
    final newAlarm = AlarmItem(_nextAlarmId++, time, label, true);
    setState(() {
      _alarms.add(newAlarm);
    });
    _scheduleAlarm(newAlarm);

    if (mounted) {
      final timeFormatted = time.format(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đặt báo thức lúc $timeFormatted qua giọng nói'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _scheduleAlarm(AlarmItem alarm) async {
    final now = DateTime.now();
    DateTime scheduleTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    if (scheduleTime.isBefore(now)) {
      scheduleTime = scheduleTime.add(const Duration(days: 1));
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: alarm.id,
        scheduledDate: tz.TZDateTime.from(scheduleTime, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel_id',
            'Alarm Channel',
            channelDescription: 'Kênh thông báo cho báo thức',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 'Báo thức: ${alarm.label}',
        body: 'Đã đến giờ báo thức của bạn!',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Lỗi hẹn giờ báo thức: $e');
    }
  }

  Future<void> _cancelAlarm(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Lỗi hủy báo thức: $e');
    }
  }

  void _addAlarm() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'CHỌN GIỜ BÁO THỨC',
    );

    if (pickedTime != null) {
      if (!mounted) return;

      final TextEditingController labelCtrl =
          TextEditingController(text: 'Báo thức mới');

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nhãn báo thức'),
          content: TextField(
            controller: labelCtrl,
            decoration: const InputDecoration(hintText: 'Nhập nhãn...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      final newAlarm = AlarmItem(
        _nextAlarmId++,
        pickedTime,
        labelCtrl.text.isEmpty ? 'Báo thức mới' : labelCtrl.text,
        true,
      );

      setState(() {
        _alarms.add(newAlarm);
      });

      _scheduleAlarm(newAlarm);
    }
  }

  void _toggleAlarm(AlarmItem alarm, bool val) {
    setState(() {
      alarm.isEnabled = val;
    });
    if (val) {
      _scheduleAlarm(alarm);
    } else {
      _cancelAlarm(alarm.id);
    }
  }

  void _deleteAlarm(AlarmItem alarm) {
    setState(() {
      _alarms.remove(alarm);
    });
    _cancelAlarm(alarm.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo thức'),
        centerTitle: true,
      ),
      body: _alarms.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Chưa có báo thức nào', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _alarms.length,
              separatorBuilder: (context, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      alarm.time.format(context),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(alarm.label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: alarm.isEnabled,
                          onChanged: (val) => _toggleAlarm(alarm, val),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteAlarm(alarm),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        child: const Icon(Icons.add_alarm),
      ),
    );
  }
}
