import 'package:flutter/material.dart';
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트

class FontSizeProvider with ChangeNotifier {
  double _fontSize = 16.0;

  double get fontSize => _fontSize;

  Future<void> loadFontSize() async {
    double savedFontSize = await getSavedFontSize(); // 저장된 크기 불러오기
    _fontSize = savedFontSize;
    notifyListeners();
  }

  Future<void> updateFontSize(double newSize) async {
    _fontSize = newSize;
    notifyListeners();
    await saveFontSize(newSize); // 저장
  }
}
