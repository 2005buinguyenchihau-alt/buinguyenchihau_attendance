import 'package:flutter/material.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final members = [
      {'name': 'Phạm Lê Huy Hoàng', 'role': 'Trưởng nhóm', 'desc': 'Quản lý dự án, thiết kế kiến trúc'},
      {'name': 'Bùi Nguyễn Chí Hậu', 'role': 'Lập trình viên', 'desc': 'Phát triển giao diện, tính năng'},
      {'name': 'Ngô Nguyễn Thanh Phúc', 'role': 'Lập trình viên', 'desc': 'Phát triển giao diện, tính năng'},
      {'name': 'Từ Minh Hiển', 'role': 'Tester', 'desc': 'Kiểm thử, đảm bảo chất lượng ứng dụng'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Thành viên', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: PageView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      member['name']![0],
                      style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    member['name']!,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    member['role']!,
                    style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      member['desc']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
