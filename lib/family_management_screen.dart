import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트
import 'dart:convert';

class FamilyManagementScreen extends StatefulWidget {
  @override
  _FamilyManagementScreenState createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  List<dynamic> _allUsers = []; // 모든 사용자 목록
  List<dynamic> _filteredUsers = []; // 검색 결과로 필터링된 사용자 목록
  String searchQuery = ''; // 검색어
  dynamic _pendingFamilyRequest; // 진행중인 가족 초대 요청 정보

  @override
  void initState() {
    super.initState();
    _loadUsers(); // 모든 사용자 불러오기
    _checkPendingFamilyRequest(); // 진행중인 가족 초대 요청 확인
  }

  Future<void> _loadUsers() async {
    String? token = await getToken();
    if (token == null) {
      print('No token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/users/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        _allUsers = data; // 모든 사용자 저장
        _filteredUsers = data; // 초기에는 전체 사용자 보여주기
      });
    } else {
      print('Failed to load users');
    }
  }

  // 진행중인 가족 초대 요청 확인 함수
  Future<void> _checkPendingFamilyRequest() async {
    String? token = await getToken();
    if (token == null) {
      print('No token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/family/pending/'), // 진행중인 가족 요청 확인 API
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      // 메시지가 '진행중인 가족 초대 요청이 없습니다.'일 경우 팝업을 띄우지 않음
      if (data != null && data['message'] != '진행중인 가족 초대 요청이 없습니다.') {
        setState(() {
          _pendingFamilyRequest = data;
        });
        _showPendingRequestDialog(); // 진행 중인 요청 팝업 표시
      } else {
        print('No pending family request'); // 요청이 없으면 넘어감
      }
    } else {
      print('Failed to check pending family request');
    }
  }

  // 사용자를 검색하는 함수
  void _searchUser(String query) {
    setState(() {
      searchQuery = query;
      if (searchQuery.isEmpty) {
        _filteredUsers = _allUsers; // 검색어가 없으면 전체 사용자 표시
      } else {
        _filteredUsers = _allUsers.where((user) {
          final userName = user['username'].toLowerCase();
          return userName.contains(searchQuery.toLowerCase());
        }).toList(); // 검색 결과로 필터링
      }
    });
  }

  // 가족 초대하기 요청 함수
  Future<void> _sendFamilyInvitation(String toUserId) async {
    String? token = await getToken();
    if (token == null) {
      print('No token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/family/invite/'),
      headers: headers,
      body: jsonEncode({'to_user_id': toUserId}),
    );

    if (response.statusCode == 201) {
      print('초대 요청이 전송되었습니다.');
    } else {
      print('초대 요청 실패');
    }
  }

  // 가족 초대 요청 승인/거절 처리 함수
  Future<void> _respondToFamilyRequest(String action) async {
    String? token = await getToken();
    if (token == null) {
      print('No token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/family/invitation/respond/'), // 초대 응답 API
      headers: headers,
      body: jsonEncode({'request_id': _pendingFamilyRequest['id'], 'action': action}),
    );

    if (response.statusCode == 200) {
      print('가족 초대 요청 처리 완료');
    } else {
      print('가족 초대 요청 처리 실패');
    }
  }

  // 가족 초대 요청 팝업
  void _showPendingRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('가족 초대 요청'),
          content: Text('${_pendingFamilyRequest['family']['family_name']} 가족에 가입하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _respondToFamilyRequest('승인'); // 승인 요청
                Navigator.of(context).pop();
              },
              child: Text('승인'),
            ),
            TextButton(
              onPressed: () {
                _respondToFamilyRequest('거절'); // 거절 요청
                Navigator.of(context).pop();
              },
              child: Text('거절'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('가족 관리')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: '사용자 검색'),
              onChanged: _searchUser, // 입력할 때마다 검색
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return ListTile(
                    title: Text(user['username']),
                    subtitle: Text(user['nickname'] ?? ''), // 닉네임이 있을 경우 표시
                    trailing: IconButton(
                      icon: Icon(Icons.person_add),
                      onPressed: () {
                        _sendFamilyInvitation(user['id'].toString()); // 가족 초대 요청
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}