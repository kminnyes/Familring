import 'package:flutter/material.dart';
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트

class FontSizeSettingsScreen extends StatefulWidget {
  @override
  _FontSizeSettingsScreenState createState() => _FontSizeSettingsScreenState();
}

class _FontSizeSettingsScreenState extends State<FontSizeSettingsScreen> {
  double _currentFontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadFontSize();  // 글씨 크기 로드
  }

  // 저장된 글씨 크기를 불러오는 함수
  void _loadFontSize() async {
    double savedFontSize = await getSavedFontSize(); // 유틸리티 함수로 글씨 크기 불러오기
    setState(() {
      _currentFontSize = savedFontSize;
    });
  }

  // 글씨 크기 저장
  void _saveFontSize(double fontSize) async {
    await saveFontSize(fontSize);  // SharedPreferences에 저장
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('글씨 크기가 저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('글씨 크기 변경'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '글씨 크기',
              style: TextStyle(fontSize: 18),
            ),
            Slider(
              value: _currentFontSize,
              min: 10.0,
              max: 30.0,
              divisions: 10,
              label: _currentFontSize.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentFontSize = value;
                });
              },
              onChangeEnd: (double value) {
                _saveFontSize(value);  // 글씨 크기를 저장
              },
            ),
            SizedBox(height: 20),
            Text(
              '예시 텍스트',
              style: TextStyle(fontSize: _currentFontSize),
            ),
          ],
        ),
      ),
    );
  }
}