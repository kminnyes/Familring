import 'package:shared_preferences/shared_preferences.dart';

// access_token과 refresh_token 저장
Future<void> saveTokens(String accessToken, String refreshToken) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('access_token', accessToken);
  await prefs.setString('refresh_token', refreshToken);
}

// access_token 불러오기
Future<String?> getAccessToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('access_token');
}

// refresh_token 불러오기
Future<String?> getRefreshToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('refresh_token');
}

// 저장된 토큰 삭제 (로그아웃 또는 회원탈퇴 시 사용)
Future<void> clearTokens() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('refresh_token');
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

// 저장된 토큰 호출해서 사용하기
Future<String?> getToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('access_token');
}
