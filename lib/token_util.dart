import 'package:shared_preferences/shared_preferences.dart';

// 토큰 저장
Future<void> saveToken(String token) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

// 저장된 토큰 불러오기
Future<String?> getToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

// 글씨 크기를 SharedPreferences에 저장
Future<void> saveFontSize(double fontSize) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('fontSize', fontSize);
}

// 저장된 글씨 크기를 SharedPreferences에서 불러오기
Future<double> getSavedFontSize() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('fontSize') ?? 16.0; // 기본 글씨 크기는 16.0
}