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
  String? _nickname;

  @override
  void initState() {
    super.initState();
    //_loadNickname(); // 화면 로드 시 닉네임을 불러옵니다.
  }


  // 닉네임 불러오기
  /*Future<void> _loadNickname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nickname = prefs.getString('nickname');
    });
  }*/

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

        // 토큰 및 사용자 정보 저장
        await saveUserInfo(accessToken, refreshToken, userId);

        // 로그인 성공 후 family_id 가져오기
        await _getFamilyId(accessToken); // 여기서 accessToken 전달

        // 로그인 성공 후 닉네임 초기화
        await initializeNickname(accessToken);
        //await _loadNickname();

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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', nickname);
      print('Nickname saved to SharedPreferences: $nickname');
    } else {
      print('Failed to load nickname from server');
    }
  }

  // 토큰 및 사용자 정보 저장 함수
  Future<void> saveUserInfo(
      String accessToken,
      String refreshToken,
      int userId,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setInt('user_id', userId);

    print('User ID saved: $userId');
  }


  // family_id를 가져오는 함수
  Future<void> _getFamilyId(String token) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/family_list/'),  // 수정된 엔드포인트
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      int? familyId = data['family_id'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (familyId != null) {
        await prefs.setInt('family_id', familyId);
        print('Family ID 저장됨: $familyId');
      } else {
        print('family_id를 찾을 수 없음');
      }
    } else {
      print('family_list에서 family_id를 가져오는 데 실패');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(-22, 0),
                child: Center(
                  child: Image.asset(
                    'images/login_icon.png',  // 로고 이미지 경로
                    width: 220,
                    height: 170,
                  ),
                ),
              ),
              SizedBox(height: 40),

              // 닉네임 표시
              if (_nickname != null)
                Text(
                  '닉네임: $_nickname',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              SizedBox(height: 20),

              // 아이디 입력 필드
              _buildTextField(_usernameController, '아이디를 입력해주세요', width: 300, height: 50),
              SizedBox(height: 16),

              // 비밀번호 입력 필드
              _buildTextField(_passwordController, '비밀번호를 입력해주세요', isPassword: true, width: 300, height: 50),
              SizedBox(height: 30),

              // 로그인 버튼
              SizedBox(
                width: 300,
                height: 50,
                child: ElevatedButton(
                  onPressed: _login,
                  child: Text(
                    '로그인',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 253, 200, 82),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // 오류 메시지
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isPassword = false, double width = 300, double height = 50}) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
    );
  }
}
