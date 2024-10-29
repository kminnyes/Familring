import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트
import 'package:shared_preferences/shared_preferences.dart';


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
      var response = await http.post(url, body: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String token = responseData['access'];  // JWT 토큰 추출

        await saveToken(token);  // SharedPreferences에 토큰 저장 (import한 함수 사용)

        // 로그인 성공 후 닉네임 초기화
        await initializeNickname(token);

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

  // 닉네임 초기화 함수
  Future<void> initializeNickname(String token) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/profile/'), // Django 서버 URL
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      String nickname = data['nickname'];

      // 닉네임을 SharedPreferences에 저장 --> 다른 화면에서도 닉네임 정보 복사해와 쓸 수 있도록 -> DB까지 가면 시간이 너무 오래걸림
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', nickname);

      print('Nickname saved to SharedPreferences: $nickname');
    } else {
      print('Failed to load nickname from server');
    }
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