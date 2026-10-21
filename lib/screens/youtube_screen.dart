import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubeScreen extends StatefulWidget {
  const YoutubeScreen({super.key});

  @override
  State<YoutubeScreen> createState() => _YoutubeScreenState();
}

class _YoutubeScreenState extends State<YoutubeScreen> {
  final TextEditingController _urlController = TextEditingController();
  YoutubePlayerController? _controller;
  String? _errorMsg;

  @override
  void dispose() {
    _urlController.dispose();
    _controller?.close();
    super.dispose();
  }

  void _loadVideo() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMsg = 'Vui lòng nhập URL YouTube');
      return;
    }

    final videoId = _extractVideoId(url);
    if (videoId == null) {
      setState(() {
        _errorMsg = 'URL không hợp lệ. Vui lòng nhập link YouTube hợp lệ (VD: https://www.youtube.com/watch?v=...)';
        _controller?.close();
        _controller = null;
      });
      return;
    }

    setState(() {
      _errorMsg = null;
      _controller?.close();
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          showControls: true,
        ),
      );
    });
  }

  String? _extractVideoId(String url) {
    if (url.isEmpty) return null;
    final regExp = RegExp(
      r'(?:youtube\.com/(?:[^/]+/.+/|(?:v|e(?:mbed)?)/|.*[?&]v=)|youtu\.be/|youtube\.com/shorts/)([^"&?/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
    } catch (_) {}
    return null;
  }

  void _loadSample(String url) {
    _urlController.text = url;
    _loadVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem Video YouTube'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Nhập link YouTube',
                      hintText: 'https://www.youtube.com/watch?v=...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadVideo,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Phát'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Mẫu: ', style: TextStyle(color: Colors.grey)),
                ActionChip(
                  label: const Text('Video Mẫu 1'),
                  onPressed: () => _loadSample('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
                ),
                ActionChip(
                  label: const Text('Video Mẫu 2'),
                  onPressed: () => _loadSample('https://youtu.be/jNQXAC9IVRw'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_errorMsg != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black12,
                  child: _controller != null
                      ? YoutubePlayer(controller: _controller!)
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'Dán đường dẫn YouTube lên thanh tìm kiếm để xem video',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
