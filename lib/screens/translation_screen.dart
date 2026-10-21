import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _translatedText = '';
  bool _isTranslating = false;
  bool _isListening = false;
  bool _isSpeechInitialized = false;

  TranslateLanguage _sourceLang = TranslateLanguage.vietnamese;
  TranslateLanguage _targetLang = TranslateLanguage.english;

  final Map<TranslateLanguage, String> _langNames = {
    TranslateLanguage.vietnamese: 'Tiếng Việt',
    TranslateLanguage.english: 'Tiếng Anh',
    TranslateLanguage.japanese: 'Tiếng Nhật',
    TranslateLanguage.korean: 'Tiếng Hàn',
    TranslateLanguage.french: 'Tiếng Pháp',
    TranslateLanguage.chinese: 'Tiếng Trung',
  };

  final stt.SpeechToText _speech = stt.SpeechToText();
  final ImagePicker _picker = ImagePicker();

  OnDeviceTranslator? _translator;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ModelManager _modelManager = OnDeviceTranslatorModelManager();
  
  Timer? _debounceTranslate;
  Timer? _debounceSpeech;

  @override
  void initState() {
    super.initState();
    _initTranslator();
  }

  @override
  void dispose() {
    _debounceTranslate?.cancel();
    _debounceSpeech?.cancel();
    _inputController.dispose();
    _translator?.close();
    _textRecognizer.close();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initTranslator() async {
    _translator?.close();
    _translator = OnDeviceTranslator(
      sourceLanguage: _sourceLang,
      targetLanguage: _targetLang,
    );
  }

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      if (mounted) setState(() => _translatedText = '');
      return;
    }

    setState(() {
      _isTranslating = true;
      if (_translatedText.isEmpty) _translatedText = 'Đang dịch...';
    });

    try {
      if (_translator == null) {
        await _initTranslator();
      }

      final result = await _translator!.translateText(text);
      if (mounted) {
        setState(() {
          _translatedText = result;
          _isTranslating = false;
        });
      }
    } catch (e) {
      // Nếu lỗi do chưa có model, thì thông báo đang tải model
      if (e.toString().contains('not downloaded')) {
        if (mounted) setState(() => _translatedText = 'Đang tải gói ngôn ngữ. Quá trình này diễn ra 1 lần duy nhất, vui lòng chờ...');
        
        final bool sourceDownloaded = await _modelManager.isModelDownloaded(_sourceLang.bcpCode);
        final bool targetDownloaded = await _modelManager.isModelDownloaded(_targetLang.bcpCode);

        if (!sourceDownloaded) await _modelManager.downloadModel(_sourceLang.bcpCode);
        if (!targetDownloaded) await _modelManager.downloadModel(_targetLang.bcpCode);
        
        // Tải xong, thử dịch lại
        if (mounted) _translate();
      } else {
        if (mounted) {
          setState(() {
            _translatedText = 'Lỗi dịch thuật: $e';
            _isTranslating = false;
          });
        }
      }
    }
  }

  void _onTextChanged(String text) {
    if (_debounceTranslate?.isActive ?? false) _debounceTranslate!.cancel();
    _debounceTranslate = Timer(const Duration(milliseconds: 600), () {
      _translate();
    });
  }

  void _swapLanguage() {
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
      _translatedText = '';
    });
    _initTranslator().then((_) {
      if (_inputController.text.isNotEmpty) {
        _translate();
      }
    });
  }

  Future<void> _listen() async {
    if (!_isListening) {
      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              if (mounted) setState(() => _isListening = false);
            }
          },
          onError: (error) {
            if (mounted) setState(() => _isListening = false);
          },
        );
      }

      if (_isSpeechInitialized) {
        if (mounted) setState(() => _isListening = true);
        
        _speech.listen(
          localeId: 'vi_VN',
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: true,
            listenMode: stt.ListenMode.dictation,
          ),
          onResult: (val) {
            if (mounted) {
              setState(() {
                _inputController.text = val.recognizedWords;
              });

              _debounceSpeech?.cancel();
              if (val.finalResult) {
                _translate();
              } else {
                _debounceSpeech = Timer(const Duration(milliseconds: 1000), () {
                  if (_isListening) {
                    _translate();
                  }
                });
              }
            }
          },
        );
      } else {

      }
    } else {
      _debounceSpeech?.cancel();
      _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _isTranslating = true;
      _translatedText = 'Đang nhận diện chữ...';
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        setState(() {
          _translatedText = 'Không tìm thấy chữ trong ảnh';
          _isTranslating = false;
        });
        return;
      }

      setState(() {
        _inputController.text = recognizedText.text;
      });
      
      _translate();
    } catch (e) {
      setState(() {
        _translatedText = 'Lỗi nhận diện chữ: $e';
        _isTranslating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dịch ML Kit', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButtonFormField<TranslateLanguage>(
                    value: _sourceLang,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: _langNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _sourceLang = v);
                        _initTranslator().then((_) => _translate());
                      }
                    },
                  ),
                ),
                IconButton(icon: const Icon(Icons.swap_horiz, size: 32, color: Colors.orange), onPressed: _swapLanguage),
                Expanded(
                  child: DropdownButtonFormField<TranslateLanguage>(
                    value: _targetLang,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: _langNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _targetLang = v);
                        _initTranslator().then((_) => _translate());
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập văn bản cần dịch...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.grey),
                  onPressed: _listen,
                  tooltip: 'Dịch bằng giọng nói',
                ),
              ),
              onChanged: _onTextChanged,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Chụp ảnh'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('Thư viện'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Text(
                        _translatedText,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    if (_isTranslating)
                      const Positioned(
                        top: 0, right: 0,
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
