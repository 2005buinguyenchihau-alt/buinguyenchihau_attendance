# Multi-Utility App Implementation Plan

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Xây dựng ứng dụng Flutter đa tiện ích (Nhiệt độ, Độ dài, YouTube, Báo thức, Đếm giờ) với giao diện Tiếng Việt, Voice Control và ML Kit.

**Architecture:** Sử dụng setState/ValueNotifier, cấu trúc 4 tab chính, các Service (Voice, Alarm, MLKit) hoạt động độc lập và gắn vào UI thông qua các instance. Sử dụng `flutter_local_notifications` cho báo thức.

**Tech Stack:** Flutter, Material 3, `google_mlkit_translation`, `google_mlkit_text_recognition`, `image_picker`, `speech_to_text`, `audioplayers`, `youtube_player_iframe`, `url_launcher`, `intl`, `flutter_local_notifications`.

---

### Task 1: Thiết lập thư mục, dependencies và Main App (Navigation)

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`
- Create: `lib/screens/home_screen.dart`
- Create: `lib/screens/translation_screen.dart`
- Create: `lib/screens/profile_screen.dart`
- Create: `lib/screens/members_screen.dart`

**Step 1: Cập nhật dependencies**
Thêm các package vào `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  google_mlkit_translation: ^0.13.0
  google_mlkit_text_recognition: ^0.14.0
  image_picker: ^1.1.2
  speech_to_text: ^7.0.0
  audioplayers: ^6.1.0
  youtube_player_iframe: ^5.1.2
  url_launcher: ^6.3.1
  intl: ^0.19.0
  flutter_local_notifications: ^17.2.1
```

**Step 2: Cập nhật main.dart và tạo 4 màn hình rỗng**
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/translation_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/members_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initialSettings);
  runApp(const MultiUtilityApp());
}

class MultiUtilityApp extends StatelessWidget {
  const MultiUtilityApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đa Tiện Ích',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});
  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    HomeScreen(),
    TranslationScreen(),
    ProfileScreen(),
    MembersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.translate), label: 'Dịch MLKit'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Cá nhân'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Thành viên'),
        ],
      ),
    );
  }
}
```

**Step 3: Chạy ứng dụng kiểm tra cơ bản**
Run: `flutter run`
Expected: Ứng dụng chạy lên với thanh điều hướng ở dưới và 4 tab trống.

### Task 2: Cấu hình Dashboard và Grid tiện ích

**Files:**
- Modify: `lib/screens/home_screen.dart`

**Step 1: Xây dựng Dashboard UI**
Tạo GridView với 5 mục và nút Voice nổi. Tạm thời navigation đến các trang trống (sẽ tạo ở Task 3).
(Chi tiết code sẽ được triển khai trong quá trình code).

### Task 3: Triển khai các Tiện Ích
Sẽ triển khai lần lượt: Temperature, Unit, YouTube, Alarm, Timer. Từng chức năng sẽ tạo file riêng trong `lib/screens/`.

### Task 4: Triển khai Voice Control, Translation, Members & Profile
Sẽ triển khai tiếp theo sau khi hoàn thành các core module.
