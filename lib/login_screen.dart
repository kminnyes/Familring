import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  // 로그인 함수
  void _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    try {
      var url = Uri.parse('http://127.0.0.1:8000/api/login/');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String accessToken = responseData['access'];
        String refreshToken = responseData['refresh'];
        int userId = responseData['user_id'];
        int? familyId = responseData['family_id'];
        String nickname = responseData['username'];

        // 토큰 및 사용자 정보 저장
        await saveUserInfo(accessToken, refreshToken, userId, familyId, nickname);

        // 저장된 데이터 확인
        await checkStoredUserInfo();

        setState(() {
          _errorMessage = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 성공')),
        );

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        var responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = '없는 정보입니다: ${responseData['error']}';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
      });
    }
  }

  // 토큰 및 사용자 정보 저장 함수
  Future<void> saveUserInfo(
      String accessToken,
      String refreshToken,
      int userId,
      int? familyId,
      String nickname,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setInt('user_id', userId);
    await prefs.setString('nickname', nickname);
    if (familyId != null) {
      await prefs.setInt('family_id', familyId);
    }
  }

  // SharedPreferences 확인 함수
  Future<void> checkStoredUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? storedUserId = prefs.getInt('user_id');
    int? storedFamilyId = prefs.getInt('family_id');
    String? storedNickname = prefs.getString('nickname');

    print('Stored user_id: $storedUserId');
    print('Stored family_id: ${storedFamilyId ?? "No family_id"}');
    print('Stored nickname: $storedNickname');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: '아이디를 입력해주세요'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: '비밀번호를 입력해주세요'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('로그인'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
