import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트
import 'dart:convert';
import 'font_size_settings_screen.dart'; // 글씨 크기 설정 페이지 import
import 'family_management_screen.dart';  // 가족 관리 페이지 import
import 'welcome_screen.dart';  // 회원탈퇴 후 이동할 WelcomeScreen import


class MyPageScreen extends StatefulWidget {
  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String nickname = ''; // 초기 닉네임 (기본값)

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // 닉네임 초기 데이터 로드
  }

  Future<void> _loadProfileData() async {
    String? token = await getAccessToken();
    if (token == null) {
      print('No token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/profile/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        nickname = data['nickname']; // 닉네임 업데이트
      });

      // SharedPreferences에 닉네임 저장
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', nickname);

      // 닉네임이 SharedPreferences에 제대로 저장되었는지 확인하는 출력
      print('Nickname saved to SharedPreferences: $nickname');
    } else {
      print('Failed to load profile data');
    }
  }

  // 회원탈퇴 API 호출
  Future<void> _deleteAccount() async {
    String? token = await getAccessToken();
    if (token == null) {
      print('No token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.delete(
      Uri.parse('http://127.0.0.1:8000/api/delete_account/'), // 회원탈퇴 API URL
      headers: headers,
    );

    if (response.statusCode == 204) {
      print('회원 탈퇴 성공');
      // 탈퇴 성공 후 토큰 삭제 및 WelcomeScreen으로 이동
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('auth_token'); // 저장된 토큰 삭제
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()), // WelcomeScreen으로 이동
            (route) => false, // 이전 페이지 스택 삭제
      );
    } else {
      print('회원 탈퇴 실패');
    }
  }

  // 회원탈퇴 확인 팝업
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("회원탈퇴"),
          content: Text("정말 회원탈퇴를 하시겠습니까?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 팝업 닫기
              },
              child: Text("아니오"),
            ),
            TextButton(
              onPressed: () {
                _deleteAccount(); // 회원탈퇴 API 호출
                Navigator.of(context).pop(); // 팝업 닫기
              },
              child: Text("예"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString('refresh_token');
    String? accessToken = prefs.getString('access_token');

    if (refreshToken == null || accessToken == null) {
      print('No refresh or access token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken', // Authorization 헤더에 access_token 추가
    };

    final body = jsonEncode({"refresh": refreshToken});

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/logout/'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 205) {
      print('로그아웃 성공');
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
            (route) => false,
      );
    } else {
      print('로그아웃 실패');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Image.asset('images/familring_user_icon1.png' ,
              width: 100, // 이미지 너비
              height: 100, // 이미지 높이
              fit: BoxFit.contain,
            ),
            SizedBox(height: 10),
            Text(
              '$nickname 님', // 닉네임 표시
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            ListTile(
              title: Text('내 프로필 편집'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final updatedNickname = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfileScreen(nickname: nickname)), // nickname 전달
                );

                if (updatedNickname != null) {
                  setState(() {
                    nickname = updatedNickname; // 닉네임 업데이트
                  });

                  //업데이트된 닉네임을 SharedPreferences에 저장
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('nickname', nickname);
                }
              },
            ),
            ListTile(
              title: Text('글씨 크기 변경'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FontSizeSettingsScreen()),
                );
              },
            ),
            ListTile(
              title: Text('가족 추가하기'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FamilyManagementScreen()),
                );
              },
            ),
            ListTile(
              title: Text('회원 탈퇴'),
              trailing: Icon(Icons.delete),
              onTap: () {
                _showDeleteAccountDialog(); // 탈퇴 팝업 표시
              },
            ),
            ListTile(
              title: Text('로그아웃'),
              trailing: Icon(Icons.logout),
              onTap: () {
                _logout(); // 로그아웃 함수 호출
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 프로필 수정 화면
class EditProfileScreen extends StatefulWidget {
  final String nickname;

  EditProfileScreen({required this.nickname}); // nickname을 생성자에 추가

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.nickname);
  }

  Future<void> _updateProfile() async {
    String? token = await getAccessToken();
    if (token == null) {
      print('No token found');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({'nickname': _nicknameController.text});

    try {
      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/profile/update/'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, _nicknameController.text); // 수정된 닉네임 전달
      } else {
        print('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(labelText: '닉네임'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
