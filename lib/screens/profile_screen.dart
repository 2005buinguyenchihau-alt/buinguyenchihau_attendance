import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Không thể mở $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 64,
                backgroundColor: Colors.orange,
                child: Icon(Icons.person, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tên hiển thị mẫu',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lập trình viên Flutter',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _launchUrl('tel:+84123456789'),
                icon: const Icon(Icons.phone),
                label: const Text('Gọi điện thoại mẫu'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _launchUrl('https://youtube.com'),
                icon: const Icon(Icons.play_arrow, color: Colors.red),
                label: const Text('Mở YouTube'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(200, 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
