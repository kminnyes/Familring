import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트

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