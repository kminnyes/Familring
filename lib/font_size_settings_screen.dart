import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider 패키지 import
import 'font_size_provider.dart'; // FontSizeProvider import

class FontSizeSettingsScreen extends StatefulWidget {
  @override
  _FontSizeSettingsScreenState createState() => _FontSizeSettingsScreenState();
}

class _FontSizeSettingsScreenState extends State<FontSizeSettingsScreen> {
  double _currentFontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadFontSize(); // 글씨 크기 로드
  }

  // 저장된 글씨 크기를 불러오는 함수
  void _loadFontSize() {
    // Provider에서 현재 설정된 글씨 크기를 가져옴
    final fontSizeProvider = Provider.of<FontSizeProvider>(context, listen: false);
    setState(() {
      _currentFontSize = fontSizeProvider.fontSize;
    });
  }

  // 글씨 크기 저장 및 Provider 업데이트
  void _saveFontSize(double fontSize) {
    // Provider에서 글씨 크기 업데이트
    final fontSizeProvider = Provider.of<FontSizeProvider>(context, listen: false);
    fontSizeProvider.updateFontSize(fontSize);

    // 스낵바로 저장 완료 알림
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
            Consumer<FontSizeProvider>(
              builder: (context, fontSizeProvider, child) {
                return Slider(
                  value: fontSizeProvider.fontSize,
                  min: 10.0,
                  max: 30.0,
                  divisions: 10,
                  label: fontSizeProvider.fontSize.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _currentFontSize = value;
                    });
                    fontSizeProvider.updateFontSize(value); // Provider 업데이트
                  },
                );
              },
            ),
            SizedBox(height: 20),
            Consumer<FontSizeProvider>(
              builder: (context, fontSizeProvider, child) {
                return Text(
                  '예시 텍스트',
                  style: TextStyle(fontSize: fontSizeProvider.fontSize),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
