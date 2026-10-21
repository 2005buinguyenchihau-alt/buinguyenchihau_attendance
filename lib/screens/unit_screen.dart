import 'package:flutter/material.dart';

class UnitScreen extends StatefulWidget {
  final double? initialValue;

  const UnitScreen({super.key, this.initialValue});

  @override
  State<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _fromUnit = 'm';
  String _toUnit = 'cm';
  String _result = '';
  String? _errorText;

  final Map<String, String> _unitNames = {
    'mm': 'Milimét (mm)',
    'cm': 'Xentimét (cm)',
    'm': 'Mét (m)',
    'km': 'Kilômét (km)',
    'inch': 'Inch (in)',
    'feet': 'Feet (ft)',
  };

  final Map<String, double> _toMeterRates = {
    'mm': 0.001,
    'cm': 0.01,
    'm': 1.0,
    'km': 1000.0,
    'inch': 0.0254,
    'feet': 0.3048,
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _inputController.text = widget.initialValue.toString();
      _convert(showSuccessNotification: false);
    }
  }

  void _convert({bool showSuccessNotification = true}) {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      _showNotification('Vui lòng nhập giá trị độ dài!', isError: true);
      setState(() {
        _errorText = 'Vui lòng nhập giá trị';
        _result = '';
      });
      return;
    }

    final inputValue = double.tryParse(input);
    if (inputValue == null) {
      _showNotification('Giá trị không hợp lệ. Vui lòng nhập dạng số!', isError: true);
      setState(() {
        _errorText = 'Giá trị phải là một số';
        _result = '';
      });
      return;
    }

    if (inputValue < 0) {
      _showNotification('Độ dài không thể là số âm (< 0)!', isError: true);
      setState(() {
        _errorText = 'Độ dài không được âm';
        _result = '';
      });
      return;
    }

    double valueInMeters = inputValue * _toMeterRates[_fromUnit]!;
    double outValue = valueInMeters / _toMeterRates[_toUnit]!;

    final formattedResult = '${outValue.toStringAsFixed(4)} $_toUnit';

    setState(() {
      _errorText = null;
      _result = formattedResult;
    });

    if (showSuccessNotification) {
      _showNotification('Chuyển đổi thành công: $inputValue $_fromUnit = $formattedResult', isError: false);
    }
  }

  void _showNotification(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
    });
    if (_inputController.text.isNotEmpty) {
      _convert(showSuccessNotification: false);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyển Đổi Đơn Vị Độ Dài'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _inputController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _convert(showSuccessNotification: false),
              decoration: InputDecoration(
                labelText: 'Nhập giá trị độ dài',
                hintText: 'Ví dụ: 10',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.straighten),
                errorText: _errorText,
                suffixIcon: _inputController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _inputController.clear();
                          setState(() {
                            _result = '';
                            _errorText = null;
                          });
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _fromUnit,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Từ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                    items: _unitNames.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _fromUnit = val);
                        _convert(showSuccessNotification: false);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 28, color: Colors.orange),
                  onPressed: _swapUnits,
                  tooltip: 'Đảo ngược',
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _toUnit,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sang',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                    items: _unitNames.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _toUnit = val);
                        _convert(showSuccessNotification: false);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _convert(showSuccessNotification: true),
              icon: const Icon(Icons.calculate),
              label: const Text('Tính toán & Thông báo', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            if (_result.isNotEmpty)
              Card(
                elevation: 3,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Kết Quả Chuyển Đổi',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
