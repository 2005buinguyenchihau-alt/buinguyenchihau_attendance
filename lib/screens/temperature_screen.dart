import 'package:flutter/material.dart';

class TemperatureScreen extends StatefulWidget {
  final double? initialValue;

  const TemperatureScreen({super.key, this.initialValue});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _fromUnit = 'Celsius (°C)';
  String _toUnit = 'Fahrenheit (°F)';
  String _result = '';
  String? _errorText;

  final Map<String, String> _unitLabels = {
    'Celsius (°C)': '°C',
    'Fahrenheit (°F)': '°F',
    'Kelvin (K)': 'K',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _inputController.text = widget.initialValue.toString();
      _convert();
    }
  }

  void _convert({bool showSuccessNotification = true}) {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      _showNotification('Vui lòng nhập giá trị nhiệt độ!', isError: true);
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

    if (_fromUnit == 'Kelvin (K)' && inputValue < 0) {
      _showNotification('Nhiệt độ Kelvin không thể là số âm (< 0K)!', isError: true);
      setState(() {
        _errorText = 'Kelvin không được âm';
        _result = '';
      });
      return;
    }

    double celsiusValue;
    if (_fromUnit == 'Celsius (°C)') {
      celsiusValue = inputValue;
    } else if (_fromUnit == 'Fahrenheit (°F)') {
      celsiusValue = (inputValue - 32) * 5 / 9;
    } else {
      celsiusValue = inputValue - 273.15;
    }

    if (celsiusValue < -273.15) {
      _showNotification('Nhiệt độ dưới độ 0 tuyệt đối (-273.15°C) là không hợp lệ!', isError: true);
      setState(() {
        _errorText = 'Dưới độ 0 tuyệt đối';
        _result = '';
      });
      return;
    }

    double outValue;
    if (_toUnit == 'Celsius (°C)') {
      outValue = celsiusValue;
    } else if (_toUnit == 'Fahrenheit (°F)') {
      outValue = celsiusValue * 9 / 5 + 32;
    } else {
      outValue = celsiusValue + 273.15;
    }

    final fromSymbol = _unitLabels[_fromUnit] ?? '';
    final toSymbol = _unitLabels[_toUnit] ?? '';
    final formattedResult = '${outValue.toStringAsFixed(2)} $toSymbol';

    setState(() {
      _errorText = null;
      _result = formattedResult;
    });

    if (showSuccessNotification) {
      _showNotification('Chuyển đổi thành công: $inputValue $fromSymbol = $formattedResult', isError: false);
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
        title: const Text('Chuyển Đổi Nhiệt Độ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _inputController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              onChanged: (_) => _convert(showSuccessNotification: false),
              decoration: InputDecoration(
                labelText: 'Nhập giá trị nhiệt độ',
                hintText: 'Ví dụ: 37',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.thermostat),
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
                      labelText: 'Từ đơn vị',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                    items: _unitLabels.keys
                        .map((u) => DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))))
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
                      labelText: 'Sang đơn vị',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                    items: _unitLabels.keys
                        .map((u) => DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))))
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
