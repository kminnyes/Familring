import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트

class EditProfileScreen extends StatefulWidget {
  final String nickname;

  EditProfileScreen({required this.nickname});

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
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = await getToken();

    if (token == null) {
      print('No token found??');
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